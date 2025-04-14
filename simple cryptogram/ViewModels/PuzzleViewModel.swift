import Foundation
import Combine
import SwiftUI

@MainActor
class PuzzleViewModel: ObservableObject {
    @Published private(set) var cells: [CryptogramCell] = []
    @Published private(set) var selectedCellIndex: Int?
    @Published private(set) var isComplete: Bool = false
    @Published private(set) var mistakeCount: Int = 0
    @Published private(set) var startTime: Date?
    @Published private(set) var endTime: Date?
    @Published private(set) var isPaused: Bool = false
    @Published private(set) var currentPuzzle: Puzzle?
    @Published private(set) var hintCount: Int = 0
    
    // Add letter mapping to track and enforce cryptogram rules
    private var letterMapping: [String: String] = [:]
    private var letterUsage: [String: String] = [:]
    
    @AppStorage("encodingType") private var encodingType = "Letters"
    private let databaseService: DatabaseService
    private var cancellables = Set<AnyCancellable>()
    private var pauseStartTime: Date?
    
    // Computed properties
    var completionTime: TimeInterval? {
        guard let start = startTime, let end = endTime else { return nil }
        return end.timeIntervalSince(start)
    }
    
    var nonSymbolCells: [CryptogramCell] {
        cells.filter { !$0.isSymbol }
    }
    
    var progressPercentage: Double {
        let filledCells = nonSymbolCells.filter { !$0.isEmpty }.count
        return Double(filledCells) / Double(nonSymbolCells.count)
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
        selectedCellIndex = nil
        isComplete = false
        mistakeCount = 0
        startTime = nil
        endTime = nil
        isPaused = false
        hintCount = 0
        pauseStartTime = nil
        
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
        selectedCellIndex = index
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
            
            // Only count a mistake once per entry and only for newly entered incorrect letters
            if !isCorrect && !uppercaseLetter.isEmpty && wasEmpty {
                mistakeCount += 1
                
                // Check if we've reached maximum mistakes
                if mistakeCount >= 3 {
                    endTime = Date()
                    isComplete = true
                }
                
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
            
            inputWasCorrect = true
        }
        
        // Check for puzzle completion after any modification
        checkPuzzleCompletion()
        
        return inputWasCorrect
    }
    
    // Refactor existing methods to use the unified cell modification approach
    func inputLetter(_ letter: String, at index: Int) {
        if startTime == nil {
            startTime = Date() // Start timer on first input
        }
        
        if modifyCells(at: index, operation: .input(letter)) {
            moveToNextCell()
        }
    }

    func handleDelete(at index: Int? = nil) {
        let targetIndex = index ?? selectedCellIndex ?? -1
        if targetIndex >= 0 {
            modifyCells(at: targetIndex, operation: .delete)
        }
    }

    func revealCell(at index: Int? = nil) {
        // Use provided index or the selectedCellIndex, with fallback to finding first unrevealed cell
        let targetIndex: Int
        
        if let idx = index, idx >= 0 && idx < cells.count && !cells[idx].isSymbol && !cells[idx].isRevealed {
            targetIndex = idx
        } else if let selected = selectedCellIndex, 
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
        
        if startTime == nil {
            startTime = Date() // Start timer on first revealed cell
        }
        
        hintCount += 1
        modifyCells(at: targetIndex, operation: .reveal)
        selectNextUnrevealedCell(after: targetIndex)
    }
    
    func reset() {
        for i in 0..<cells.count {
            cells[i].userInput = ""
            cells[i].isRevealed = false
            cells[i].isError = false
        }
        
        // Reset letter mappings
        letterMapping = [:]
        letterUsage = [:]
        
        mistakeCount = 0
        startTime = nil
        endTime = nil
        isComplete = false
        hintCount = 0
    }
    
    func togglePause() {
        isPaused.toggle()
        
        if isPaused {
            // Save the time when paused
            pauseStartTime = Date()
        } else if let pauseStart = pauseStartTime, let start = startTime {
            // Adjust the start time by the pause duration
            let pauseDuration = Date().timeIntervalSince(pauseStart)
            startTime = start.addingTimeInterval(pauseDuration)
            pauseStartTime = nil
        }
    }
    
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
    
    func moveToNextCell() {
        guard let currentIndex = selectedCellIndex else { return }
        
        // Find the next non-symbol cell
        var nextIndex = currentIndex + 1
        while nextIndex < cells.count {
            if !cells[nextIndex].isSymbol && cells[nextIndex].userInput.isEmpty {
                selectedCellIndex = nextIndex
                return
            }
            nextIndex += 1
        }
    }
    
    func moveToAdjacentCell(direction: Int) {
        guard let currentIndex = selectedCellIndex else { return }
        
        // Calculate the target index
        let targetIndex = currentIndex + direction
        
        // Check if the target index is valid
        if targetIndex >= 0 && targetIndex < cells.count {
            // Skip symbol cells
            if !cells[targetIndex].isSymbol {
                selectedCellIndex = targetIndex
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
            selectedCellIndex = next
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
        
        if allCorrect && !isComplete {
            isComplete = true
            endTime = Date()
            
            // Save score or statistics here if needed
        }
    }
}


