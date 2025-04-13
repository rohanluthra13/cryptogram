import Foundation
import Combine
import SwiftUI

@MainActor
class PuzzleViewModel: ObservableObject {
    @Published private(set) var state: PuzzleState
    @Published private(set) var currentPuzzle: Puzzle?
    @Published private(set) var errorIndices: Set<Int> = []
    @Published private(set) var isPaused: Bool = false
    @AppStorage("encodingType") private var encodingType = "Letters"
    private let databaseService: DatabaseService
    private var cancellables = Set<AnyCancellable>()
    private var pauseStartTime: Date?
    private var hasStarted: Bool = false
    
    init(initialPuzzle: Puzzle? = nil) {
        print("=== PuzzleViewModel Initialization ===")
        self.databaseService = DatabaseService.shared
        self.state = PuzzleState()
        
        if let puzzle = initialPuzzle {
            print("Using provided puzzle")
            self.currentPuzzle = puzzle
            startNewPuzzle(puzzle: puzzle)
        } else {
            print("Attempting to load random puzzle from database")
            // Try to load a random puzzle from the database
            if let puzzle = databaseService.fetchRandomPuzzle(encodingType: encodingType) {
                print("Successfully loaded puzzle from database")
                self.currentPuzzle = puzzle
                startNewPuzzle(puzzle: puzzle)
            } else {
                print("Failed to load puzzle from database, using fallback")
                // Fallback to a default puzzle if database is not available
                self.currentPuzzle = Puzzle(
                    encodedText: "THE QUICK BROWN FOX JUMPS OVER THE LAZY DOG",
                    solution: "THE QUICK BROWN FOX JUMPS OVER THE LAZY DOG",
                    hint: "A pangram containing every letter of the alphabet"
                )
                startNewPuzzle(puzzle: self.currentPuzzle!)
            }
        }
        
        setupBindings()
    }
    
    private func setupBindings() {
        $state
            .sink { [weak self] newState in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public Interface
    
    func refreshPuzzleWithCurrentSettings() {
        guard let currentPuzzle = currentPuzzle,
              let id = Int(currentPuzzle.id.uuidString) else {
            // If current puzzle is not valid, fetch a new random one
            if let puzzle = databaseService.fetchRandomPuzzle(encodingType: encodingType) {
                startNewPuzzle(puzzle: puzzle)
            }
            return
        }
        
        // Reload the same puzzle with new encoding
        if let puzzle = databaseService.fetchPuzzleById(id, encodingType: encodingType) {
            startNewPuzzle(puzzle: puzzle)
        }
    }
    
    func startNewPuzzle(puzzle: Puzzle) {
        currentPuzzle = puzzle
        state = PuzzleState(
            userInput: Array(repeating: "", count: puzzle.encodedText.count),
            letterMapping: [:],
            selectedCellIndex: nil,
            mistakeCount: 0,
            revealedLetters: [],
            isComplete: false,
            startTime: Date.distantFuture,
            endTime: nil,
            hintCount: 0
        )
        errorIndices = []
        hasStarted = false
        isPaused = false
        pauseStartTime = nil
    }
    
    func selectCell(at index: Int) {
        state.selectCell(at: index)
    }
    
    func handleLetterInput(_ letter: Character) {
        guard let index = state.selectedCellIndex, let puzzle = currentPuzzle else { return }
        
        // Start timer on first input attempt if not already started
        if !hasStarted {
            hasStarted = true
            state.startTime = Date()
        }
        
        // Always ensure we're using uppercase for all letter comparisons
        let inputChar = letter.isLetter ? Character(String(letter).uppercased()) : letter
        
        // Get the encoded character at this position
        let encodedChar = puzzle.encodedText[puzzle.encodedText.index(puzzle.encodedText.startIndex, offsetBy: index)]
        
        // Get the correct character for this position - ensure it's uppercase for consistent comparison
        let correctCharString = String(puzzle.solution[puzzle.solution.index(puzzle.solution.startIndex, offsetBy: index)])
        let correctChar = Character(correctCharString.uppercased())
        
        // Debug logging to help diagnose the issue
        print("Input validation - Index: \(index), Input: \(inputChar), Encoded: \(encodedChar), Correct: \(correctChar)")
        print("Revealed letters: \(state.revealedLetters)")
        print("Letter mapping: \(state.letterMapping)")
        
        // Check if the character is already revealed by hints
        let isRevealed = state.revealedLetters.contains(encodedChar)
        
        // Check if we already have a mapping for this encoded character
        let existingMapping = state.letterMapping[encodedChar]
        
        // For proper comparison, ensure the existing mapping is also uppercase
        let normalizedMapping = existingMapping?.isLetter ?? false ? Character(String(existingMapping!).uppercased()) : existingMapping
        
        // Check if this letter is the correct solution 
        let isCorrectLetter = inputChar == correctChar
        
        // Check if input matches existing mapping (using normalized mapping)
        let matchesExistingMapping = normalizedMapping == inputChar
        
        // Debug validation conditions
        print("isRevealed: \(isRevealed), isCorrectLetter: \(isCorrectLetter), matchesExistingMapping: \(matchesExistingMapping), normalizedMapping: \(String(describing: normalizedMapping))")
        
        // Accept the input if:
        // 1. It matches the correct character for this position, OR
        // 2. The position is revealed by a hint, OR
        // 3. The encoded character has a mapping and the input matches that mapping
        if isCorrectLetter || isRevealed || (normalizedMapping != nil && matchesExistingMapping) {
            print("✅ Input accepted")
            
            // Accept input
            state.inputLetter(inputChar, at: index)
            
            // If this mapping doesn't exist yet, create it
            if state.letterMapping[encodedChar] == nil {
                state.letterMapping[encodedChar] = inputChar
                print("Creating new mapping: \(encodedChar) -> \(inputChar)")
            }
            
            // Move to next cell automatically
            moveToNextCell()
            
            // Check for completion
            checkCompletion()
        } else {
            print("❌ Input rejected")
            
            // Reject incorrect input and count as mistake
            state.incrementMistakeCount()
            
            // Check if game over (3 mistakes max)
            if state.mistakeCount >= 3 {
                handleGameOver()
            }
        }
    }
    
    func handleDelete() {
        guard let index = state.selectedCellIndex else { return }
        state.userInput[index] = ""
        errorIndices.remove(index)
    }
    
    func revealHint() {
        guard let puzzle = currentPuzzle else { return }
        
        // Start timer on first hint if not already started
        if !hasStarted {
            hasStarted = true
            state.startTime = Date()
        }
        
        // Get all unrevealed letters/numbers from the puzzle
        var unrevealedCharacters: [Character: [Int]] = [:]
        
        for (index, char) in puzzle.encodedText.enumerated() {
            // Consider both alphabetic characters and numbers that haven't been revealed yet
            if (char.isLetter || char.isNumber) && !state.revealedLetters.contains(char) {
                // Store all occurrences of each unrevealed character
                if unrevealedCharacters[char] == nil {
                    unrevealedCharacters[char] = [index]
                } else {
                    unrevealedCharacters[char]?.append(index)
                }
            }
        }
        
        // If no unrevealed characters, return
        if unrevealedCharacters.isEmpty {
            return
        }
        
        // Pick a random unrevealed character
        let randomIndex = Int.random(in: 0..<unrevealedCharacters.count)
        let randomChar = Array(unrevealedCharacters.keys)[randomIndex]
        
        // Get all occurrences of this character
        let occurrences = unrevealedCharacters[randomChar]!
        let randomOccurrenceIndex = occurrences[Int.random(in: 0..<occurrences.count)]
        
        // Get the correct solution letter for this position and ensure it's uppercase
        let correctLetterStr = String(puzzle.solution[puzzle.solution.index(puzzle.solution.startIndex, offsetBy: randomOccurrenceIndex)])
        let correctLetter = Character(correctLetterStr.uppercased())
        
        // Mark this character as revealed with its specific index
        state.revealLetter(randomChar, at: randomOccurrenceIndex)
        
        // Fill in ONLY the randomly selected occurrence
        state.userInput[randomOccurrenceIndex] = String(correctLetter)
        
        // Update the letter mapping - this is crucial for consistent validation
        state.letterMapping[randomChar] = correctLetter
        
        // Debug logging
        print("Hint revealed: \(randomChar) -> \(correctLetter) at position \(randomOccurrenceIndex)")
        print("Updated letter mapping: \(state.letterMapping)")
        
        // If there's a selected cell, move to the next one
        if state.selectedCellIndex != nil {
            moveToNextCell()
        }
        
        // Check for completion
        checkCompletion()
    }
    
    func checkCompletion() {
        guard let puzzle = currentPuzzle else { return }
        
        // Convert both to uppercase for comparison
        let userSolution = state.userInput.joined().uppercased()
        let correctSolution = puzzle.solution.uppercased()
        
        print("Checking completion - User solution: \(userSolution)")
        print("Correct solution: \(correctSolution)")
        
        if userSolution == correctSolution {
            print("✅ Puzzle completed!")
            state.markComplete()
        }
    }
    
    func reset() {
        state.reset()
        errorIndices = []
    }
    
    // MARK: - Private Helpers
    
    private func validateInput() {
        guard let puzzle = currentPuzzle else { return }
        
        // Save previous error count to determine if we need to increment mistake count
        let _ = errorIndices.count
        
        var newErrorIndices = Set<Int>()
        for (index, (_, user)) in zip(puzzle.encodedText, state.userInput).enumerated() {
            if !user.isEmpty {
                let correctLetter = puzzle.solution[puzzle.solution.index(puzzle.solution.startIndex, offsetBy: index)]
                if Character(user) != correctLetter {
                    newErrorIndices.insert(index)
                }
            }
        }
        
        // Only increment mistake count if we have new errors that weren't there before
        if !newErrorIndices.isEmpty && newErrorIndices != errorIndices {
            state.incrementMistakeCount()
        }
        
        errorIndices = newErrorIndices
    }
    
    private func saveProgress() {
        // Implementation will be added in Phase 2
    }
    
    // MARK: - Navigation Bar Actions
    
    func moveToPreviousCell() {
        guard let currentIndex = state.selectedCellIndex,
              let puzzle = currentPuzzle else { return }
        
        // Find the previous valid cell (skipping spaces and punctuation)
        var nextIndex = currentIndex - 1
        while nextIndex >= 0 {
            let char = puzzle.encodedText[puzzle.encodedText.index(puzzle.encodedText.startIndex, offsetBy: nextIndex)]
            if char.isLetter || char.isNumber {
                state.selectCell(at: nextIndex)
                break
            }
            nextIndex -= 1
        }
    }
    
    func moveToNextCell() {
        guard let currentIndex = state.selectedCellIndex,
              let puzzle = currentPuzzle else { return }
        
        // Find the next valid cell (skipping spaces and punctuation)
        var nextIndex = currentIndex + 1
        while nextIndex < puzzle.encodedText.count {
            let char = puzzle.encodedText[puzzle.encodedText.index(puzzle.encodedText.startIndex, offsetBy: nextIndex)]
            if char.isLetter || char.isNumber {
                state.selectCell(at: nextIndex)
                break
            }
            nextIndex += 1
        }
    }
    
    func togglePause() {
        if isPaused {
            // Resume the timer by adjusting the start time
            if let pauseTime = pauseStartTime {
                let pauseDuration = Date().timeIntervalSince(pauseTime)
                state.startTime = state.startTime.addingTimeInterval(pauseDuration)
                pauseStartTime = nil
            }
        } else {
            // Only pause if the game has actually started
            if hasStarted {
                // Pause the timer by recording current time
                pauseStartTime = Date()
            }
        }
        
        isPaused = !isPaused
    }
    
    func loadNextPuzzle() {
        guard let currPuzzle = currentPuzzle else { return }
        
        if let newPuzzle = databaseService.fetchRandomPuzzle(current: currPuzzle, encodingType: encodingType) {
            startNewPuzzle(puzzle: newPuzzle)
        }
    }
    
    func resetCurrentPuzzle() {
        if let puzzle = currentPuzzle {
            startNewPuzzle(puzzle: puzzle)
        }
    }
    
    // Add this new method for handling game over
    private func handleGameOver() {
        // Set game state to failed
        state.markFailed()
        
        // No longer setting isPaused to true
    }
}


