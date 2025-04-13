import Foundation
import Combine
import SwiftUI

@MainActor
class PuzzleViewModel: ObservableObject {
    @Published private(set) var state: PuzzleState
    @Published private(set) var currentPuzzle: Puzzle?
    @Published private(set) var errorIndices: Set<Int> = []
    @Published private(set) var isPaused: Bool = false
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
            if let puzzle = databaseService.fetchRandomPuzzle() {
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
        
        // Ensure letter is uppercase
        let uppercaseLetter = Character(String(letter).uppercased())
        
        // Get the correct letter for this position
        let correctLetter = puzzle.solution[puzzle.solution.index(puzzle.solution.startIndex, offsetBy: index)]
        
        // Check if the letter is already revealed by hints (should always be accepted)
        let encodedChar = puzzle.encodedText[puzzle.encodedText.index(puzzle.encodedText.startIndex, offsetBy: index)]
        let isRevealed = state.revealedLetters.contains(encodedChar)
        
        if uppercaseLetter == correctLetter || isRevealed {
            // Accept correct input (ensuring uppercase)
            state.inputLetter(uppercaseLetter, at: index)
            
            // Update letter mapping
            state.letterMapping[encodedChar] = uppercaseLetter
            
            // Move to next cell automatically
            moveToNextCell()
            
            // Check for completion
            checkCompletion()
        } else {
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
        
        // Get all unrevealed letters from the puzzle
        var unrevealedLetters: [Character: [Int]] = [:]
        
        for (index, char) in puzzle.encodedText.enumerated() {
            // Only consider alphabetic characters that haven't been revealed yet
            if char.isLetter && !state.revealedLetters.contains(char) {
                // Store all occurrences of each unrevealed letter
                if unrevealedLetters[char] == nil {
                    unrevealedLetters[char] = [index]
                } else {
                    unrevealedLetters[char]?.append(index)
                }
            }
        }
        
        // If no unrevealed letters, return
        if unrevealedLetters.isEmpty {
            return
        }
        
        // Pick a random unrevealed letter
        let randomIndex = Int.random(in: 0..<unrevealedLetters.count)
        let randomLetter = Array(unrevealedLetters.keys)[randomIndex]
        
        // Get a random occurrence of this letter
        let occurrences = unrevealedLetters[randomLetter]!
        let randomOccurrenceIndex = occurrences[Int.random(in: 0..<occurrences.count)]
        
        // Get the correct solution letter for this position
        let correctLetter = puzzle.solution[puzzle.solution.index(puzzle.solution.startIndex, offsetBy: randomOccurrenceIndex)]
        
        // Mark this letter as revealed with its specific index
        state.revealLetter(randomLetter, at: randomOccurrenceIndex)
        
        // Fill in ONLY the randomly selected occurrence, ensuring uppercase
        state.userInput[randomOccurrenceIndex] = String(correctLetter).uppercased()
        
        // Update the letter mapping
        state.letterMapping[randomLetter] = correctLetter
        
        // If there's a selected cell, move to the next one
        if state.selectedCellIndex != nil {
            moveToNextCell()
        }
        
        // Check for completion
        checkCompletion()
        
        // Print for debugging
        print("Hint revealed: \(randomLetter) -> \(correctLetter) at position \(randomOccurrenceIndex), hint count: \(state.hintCount)")
    }
    
    func checkCompletion() {
        guard let puzzle = currentPuzzle else { return }
        
        let userSolution = state.userInput.joined()
        if userSolution == puzzle.solution {
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
        let previousErrorCount = errorIndices.count
        
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
            if char.isLetter {
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
            if char.isLetter {
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
        if let puzzle = databaseService.fetchRandomPuzzle(excludingCurrent: currentPuzzle) {
            startNewPuzzle(puzzle: puzzle)
        }
    }
    
    // Add this new method for handling game over
    private func handleGameOver() {
        // Set game state to failed
        state.markFailed()
        
        // Optional: Show some visual indication or alert that game is over
        isPaused = true
    }
}


