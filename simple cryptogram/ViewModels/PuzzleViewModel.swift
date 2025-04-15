import Foundation
import Combine
import SwiftUI
import UIKit

// Add WordGroup struct definition
struct WordGroup: Identifiable {
    let id = UUID()
    let indices: [Int]
    let includesSpace: Bool
}

@MainActor
class PuzzleViewModel: ObservableObject {
    @Published private(set) var cells: [CryptogramCell] = []
    @Published private(set) var session: PuzzleSession = PuzzleSession()
    @Published private(set) var currentPuzzle: Puzzle?
    @Published var isWiggling = false // Animation state for completion celebrations
    
    // Add letter mapping to track and enforce cryptogram rules
    private var letterMapping: [String: String] = [:]
    private var letterUsage: [String: String] = [:]
    
    @AppStorage("encodingType") private var encodingType = "Letters"
    private let databaseService: DatabaseService
    private var cancellables = Set<AnyCancellable>()
    
    // Computed properties
    var selectedCellIndex: Int? {
        session.selectedCellIndex
    }
    
    var isComplete: Bool {
        session.isComplete
    }
    
    var isFailed: Bool {
        session.isFailed
    }
    
    var mistakeCount: Int {
        session.mistakeCount
    }
    
    var startTime: Date? {
        session.startTime
    }
    
    var endTime: Date? {
        session.endTime
    }
    
    var isPaused: Bool {
        session.isPaused
    }
    
    var hintCount: Int {
        session.hintCount
    }
    
    var completionTime: TimeInterval? {
        session.completionTime
    }
    
    var nonSymbolCells: [CryptogramCell] {
        cells.filter { !$0.isSymbol }
    }
    
    var progressPercentage: Double {
        let filledCells = nonSymbolCells.filter { !$0.isEmpty }.count
        return Double(filledCells) / Double(nonSymbolCells.count)
    }
    
    // Add wordGroups computed property
    var wordGroups: [WordGroup] {
        var groups: [WordGroup] = []
        var currentWordIndices: [Int] = []
        
        for index in cells.indices {
            let cell = cells[index]
            
            if cell.isSymbol && cell.encodedChar == " " {
                // End current word
                if !currentWordIndices.isEmpty {
                    groups.append(WordGroup(indices: currentWordIndices, includesSpace: true))
                    currentWordIndices = []
                }
            } else {
                // Add to current word
                currentWordIndices.append(index)
            }
        }
        
        // Add last word if not empty
        if !currentWordIndices.isEmpty {
            groups.append(WordGroup(indices: currentWordIndices, includesSpace: false))
        }
        
        return groups
    }
    
    init(initialPuzzle: Puzzle? = nil) {
        print("=== PuzzleViewModel Initialization ===")
        self.databaseService = DatabaseService.shared
        
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
    }
    
    // MARK: - Public Methods
    
    func startNewPuzzle(puzzle: Puzzle) {
        currentPuzzle = puzzle
        cells = puzzle.createCells(encodingType: encodingType)
        session = PuzzleSession()
        
        // --- Add Difficulty-based reveal logic --- 
        let difficulty = UserSettings.currentMode
        if difficulty == .normal {
            let solution = puzzle.solution.uppercased()
            let uniqueLetters = Set(solution.filter { $0.isLetter })

            if !uniqueLetters.isEmpty {
                let revealPercentage = 0.20 // 20% reveal
                let numToReveal = max(1, Int(ceil(Double(uniqueLetters.count) * revealPercentage)))
                let lettersToReveal = uniqueLetters.shuffled().prefix(numToReveal)
                
                var revealedIndices = Set<Int>() // Track revealed indices to ensure one per letter

                for letter in lettersToReveal {
                    let letterString = String(letter)
                    // Find indices for this letter that haven't been revealed yet
                    let matchingIndices = cells.indices.filter { 
                        cells[$0].solutionChar == letter && !revealedIndices.contains($0) && !cells[$0].isRevealed
                    }

                    if let indexToReveal = matchingIndices.randomElement() {
                        // Mark the cell as revealed
                        cells[indexToReveal].userInput = letterString
                        cells[indexToReveal].isRevealed = true
                        cells[indexToReveal].isError = false // Ensure no error state
                        cells[indexToReveal].isPreFilled = true // Mark as pre-filled for Normal mode
                        
                        // Track the index to prevent revealing the same cell for another letter if counts overlap
                        revealedIndices.insert(indexToReveal)
                    }
                }
                // Convert Character sequence to String for printing
                print("Normal mode: Revealed \(revealedIndices.count) cells for letters: \(lettersToReveal.map { String($0) }.joined())")
            }
        }
        // --- End Difficulty Logic ---

        // Clear letter mappings when starting a new puzzle
        letterMapping = [:]
        letterUsage = [:]
        
        print("New puzzle started with \(cells.count) cells")
        
        // Debug: Log cell information to help diagnose space issues
        #if DEBUG
        print("=== Cell Debug Information ===")
        for (index, cell) in cells.enumerated() {
            let cellType = cell.isSymbol ? "Symbol" : "Letter"
            let solutionInfo = cell.solutionChar != nil ? "Solution: \(cell.solutionChar!)" : "No solution"
            print("Cell \(index): '\(cell.encodedChar)' (\(cellType)) - \(solutionInfo)")
        }
        print("=== End Cell Debug ===")
        #endif
    }
    
    func selectCell(at index: Int) {
        guard index >= 0 && index < cells.count else { return }
        session.selectedCellIndex = index
        
        // Add subtle haptic feedback for cell selection
        DispatchQueue.main.async {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred(intensity: 0.5) // Reduced intensity for less intrusive feedback
        }
    }
    
    // Define operation types for cell modifications
    enum CellOperation {
        case input(String)
        case delete
        case reveal
    }
    
    // Unified cell modification system that only updates the specific cell
    private func modifyCells(at index: Int, operation: CellOperation) -> Bool {
        guard index >= 0 && index < cells.count, !cells[index].isSymbol else { return false }
        
        let targetCell = cells[index]
        let encodedChar = targetCell.encodedChar
        var inputWasCorrect = false
        
        switch operation {
        case .input(let letter):
            // Input operations need to check for conflicts and update mappings
            let uppercaseLetter = letter.uppercased()
            
            // Reset all wasJustFilled flags first
            for i in 0..<cells.count {
                cells[i].wasJustFilled = false
            }
            
            // Apply only to the target cell
            let wasEmpty = cells[index].userInput.isEmpty
            cells[index].userInput = uppercaseLetter
            cells[index].wasJustFilled = true
            
            // Check if this input is correct
            let isCorrect = String(cells[index].solutionChar ?? " ") == uppercaseLetter
            cells[index].isError = !isCorrect && !uppercaseLetter.isEmpty
            
            // Add haptic feedback for letter input - different for correct vs incorrect
            DispatchQueue.main.async {
                if isCorrect {
                    // Light feedback for correct letter
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
                } else if !uppercaseLetter.isEmpty {
                    // Medium feedback for incorrect letter
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                }
            }
            
            // Only count a mistake once per entry and only for newly entered incorrect letters
            if !isCorrect && !uppercaseLetter.isEmpty && wasEmpty {
                session.incrementMistakes()
                
                // For incorrect letters, remove them after a brief delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                    guard let self = self else { return }
                    
                    // Clear the cell after showing the error briefly
                    if index < self.cells.count {
                        self.cells[index].userInput = ""
                        self.cells[index].isError = false
                    }
                }
            }
            
            inputWasCorrect = isCorrect
            
        case .delete:
            // Clear only the target cell
            cells[index].userInput = ""
            cells[index].isError = false
            
        case .reveal:
            guard let solutionChar = targetCell.solutionChar else { 
                print("DEBUG: Tried to reveal a cell without a solution character at index \(index)")
                return false 
            }
            let solutionString = String(solutionChar)
            
            print("DEBUG: Revealing cell at index \(index) with encoded char '\(encodedChar)' and solution '\(solutionString)'")
            
            // Reveal only the target cell
            cells[index].userInput = solutionString
            cells[index].isError = false
            cells[index].isRevealed = true
            cells[index].isPreFilled = false // Hints are not pre-filled
            
            // Record this reveal in the session
            session.revealCell(at: index)
            
            // Add haptic feedback for revealing a letter (hint)
            DispatchQueue.main.async {
                let generator = UISelectionFeedbackGenerator()
                generator.selectionChanged()
            }
            
            inputWasCorrect = true
        }
        
        // Check for puzzle completion after any modification
        checkPuzzleCompletion()
        
        return inputWasCorrect
    }
    
    // Refactor existing methods to use the unified cell modification approach
    func inputLetter(_ letter: String, at index: Int) {
        if session.startTime == nil {
            session.startTime = Date() // Start timer on first input
        }
        
        if modifyCells(at: index, operation: .input(letter)) {
            moveToNextCell()
        }
    }

    func handleDelete(at index: Int? = nil) {
        let targetIndex = index ?? session.selectedCellIndex ?? -1
        if targetIndex >= 0 {
            _ = modifyCells(at: targetIndex, operation: .delete)
        }
    }

    func revealCell(at index: Int? = nil) {
        // Use provided index or the selectedCellIndex, with fallback to finding first unrevealed cell
        let targetIndex: Int
        
        if let idx = index, idx >= 0 && idx < cells.count && !cells[idx].isSymbol && !cells[idx].isRevealed {
            targetIndex = idx
        } else if let selected = session.selectedCellIndex, 
                  selected >= 0 && selected < cells.count && 
                  !cells[selected].isSymbol && 
                  !cells[selected].isRevealed {
            targetIndex = selected
        } else {
            // Find first unrevealed, non-symbol cell
            if let firstUnrevealedIndex = cells.indices.first(where: { 
                !cells[$0].isSymbol && !cells[$0].isRevealed && cells[$0].userInput.isEmpty
            }) {
                targetIndex = firstUnrevealedIndex
            } else {
                // No unrevealed cells left
                return
            }
        }
        
        if session.startTime == nil {
            session.startTime = Date() // Start timer on first revealed cell
        }
        
        _ = modifyCells(at: targetIndex, operation: .reveal)
        selectNextUnrevealedCell(after: targetIndex)
    }
    
    func reset() {
        // Reset all cells
        for i in 0..<cells.count {
            cells[i].userInput = ""
            cells[i].isRevealed = false
            cells[i].isError = false
            cells[i].isPreFilled = false // Ensure pre-filled is also reset
        }
        
        // Reset letter mappings
        letterMapping = [:]
        letterUsage = [:]
        
        // Reset session data
        session.reset()
    }
    
    func togglePause() {
        session.togglePause()
    }
    
    func refreshPuzzleWithCurrentSettings() {
        guard let currentPuzzle = currentPuzzle else {
            // If current puzzle is not valid, fetch a new random one
            if let puzzle = databaseService.fetchRandomPuzzle(encodingType: encodingType) {
                startNewPuzzle(puzzle: puzzle)
            }
            return
        }
        
        // Extract the first part of the UUID string and try to convert to Int
        // Or just fetch a random puzzle regardless of the current one
        if let puzzle = databaseService.fetchRandomPuzzle(current: currentPuzzle, encodingType: encodingType) {
            startNewPuzzle(puzzle: puzzle)
        }
    }
    
    func moveToNextCell() {
        guard let currentIndex = session.selectedCellIndex else { return }
        
        // Find the next non-symbol cell
        var nextIndex = currentIndex + 1
        while nextIndex < cells.count {
            if !cells[nextIndex].isSymbol && cells[nextIndex].userInput.isEmpty {
                session.selectedCellIndex = nextIndex
                return
            }
            nextIndex += 1
        }
    }
    
    func moveToAdjacentCell(direction: Int) {
        // If no cell is selected, select the first non-symbol cell before proceeding
        if session.selectedCellIndex == nil {
            if let firstNonSymbolIndex = cells.indices.first(where: { !cells[$0].isSymbol }) {
                session.selectedCellIndex = firstNonSymbolIndex
                return
            } else {
                return // If no non-symbol cells exist at all, exit
            }
        }
        
        guard let currentIndex = session.selectedCellIndex else { return }
        
        // Calculate the target index
        let targetIndex = currentIndex + direction
        
        // Check if the target index is valid
        if targetIndex >= 0 && targetIndex < cells.count {
            // Skip symbol cells
            if !cells[targetIndex].isSymbol {
                session.selectedCellIndex = targetIndex
            } else {
                // If we hit a symbol cell, continue in the same direction
                moveToAdjacentCell(direction: direction > 0 ? direction + 1 : direction - 1)
            }
        }
    }
    
    private func selectNextUnrevealedCell(after index: Int) {
        let nextIndex = cells.indices.first { idx in
            idx > index && !cells[idx].isSymbol && !cells[idx].isRevealed && cells[idx].userInput.isEmpty
        }
        
        if let next = nextIndex {
            session.selectedCellIndex = next
        }
    }
    
    // MARK: - Private Methods
    
    private func checkPuzzleCompletion() {
        // Count how many non-symbol cells we have with correct inputs
        let correctCount = nonSymbolCells.filter { $0.isCorrect }.count
        // Count total number of non-symbol cells
        let totalCount = nonSymbolCells.count
        
        // Debug log
        print("Puzzle completion check: \(correctCount)/\(totalCount) cells correct")
        
        // The puzzle is complete when all non-symbol cells have correct inputs
        let allCorrect = correctCount == totalCount
        
        if allCorrect && !session.isComplete {
            session.markComplete()
            
            // Save score or statistics here if needed
        }
        
        // Also check if the game is failed due to mistake count
        if session.mistakeCount >= 3 && !session.isFailed {
            print("Game over: Too many mistakes!")
            session.markFailed()
            
            // Add haptic feedback for failure
            DispatchQueue.main.async {
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.error)
            }
        }
    }
    
    // MARK: - Completion Animations
    
    func triggerCompletionWiggle() {
        // Trigger wiggle animation in cells
        isWiggling = true
        
        // Reset wiggle after animation completes
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
            self?.isWiggling = false
        }
    }
}


