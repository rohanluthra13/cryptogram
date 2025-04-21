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
    @Published var completedLetters: Set<String> = [] // Set of encoded letters that are completed (all cells filled, normal mode only)
    @Published var cellsToAnimate: Set<UUID> = [] // Set of cell IDs to animate completion for
    @Published var hasUserEngaged: Bool = false // Track if the user has interacted with the puzzle yet
    @Published var showCompletedHighlights: Bool = true // Toggle for displaying completed‑letter highlights
    
    // Add letter mapping to track and enforce cryptogram rules
    private var letterMapping: [String: String] = [:]
    private var letterUsage: [String: String] = [:]
    
    @AppStorage("encodingType") private var encodingType = "Letters"
    private let databaseService: DatabaseService
    private var cancellables = Set<AnyCancellable>()
    
    // --- Progress Tracking Store ---
    private let progressStore: PuzzleProgressStore

    // MARK: - Author Info
    @Published var currentAuthor: Author?
    private var lastAuthorName: String?

    /// Load author info if name changed
    func loadAuthorIfNeeded(name: String) {
        guard name != lastAuthorName else { return }
        lastAuthorName = name
        Task {
            let author = await databaseService.fetchAuthor(byName: name)
            currentAuthor = author
        }
    }
    
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
    
    // --- Stats for Current Puzzle ---
    var completionCountForCurrentPuzzle: Int {
        guard let puzzle = currentPuzzle else { return 0 }
        return progressStore.attempts(for: puzzle.id, encodingType: encodingType).filter { $0.completedAt != nil }.count
    }
    var failureCountForCurrentPuzzle: Int {
        guard let puzzle = currentPuzzle else { return 0 }
        return progressStore.attempts(for: puzzle.id, encodingType: encodingType).filter { $0.failedAt != nil }.count
    }
    var bestTimeForCurrentPuzzle: TimeInterval? {
        guard let puzzle = currentPuzzle else { return nil }
        return progressStore.bestCompletionTime(for: puzzle.id, encodingType: encodingType)
    }
    
    // --- Global Stats ---
    var totalAttempts: Int {
        progressStore.allAttempts().count
    }
    var totalCompletions: Int {
        progressStore.allAttempts().filter { $0.completedAt != nil }.count
    }
    var totalFailures: Int {
        progressStore.allAttempts().filter { $0.failedAt != nil }.count
    }
    var globalBestTime: TimeInterval? {
        progressStore.allAttempts().compactMap { $0.completionTime }.min()
    }
    
    // MARK: - Aggregate User Stats
    /// Percentage of successful completions over total attempts
    var winRatePercentage: Int {
        let attempts = totalAttempts
        guard attempts > 0 else { return 0 }
        return Int(Double(totalCompletions) / Double(attempts) * 100)
    }
    
    /// Average completion time over all successful attempts
    var averageTime: TimeInterval? {
        let times = progressStore.allAttempts().compactMap { $0.completionTime }
        guard !times.isEmpty else { return nil }
        return times.reduce(0, +) / Double(times.count)
    }
    
    init(initialPuzzle: Puzzle? = nil, progressStore: PuzzleProgressStore? = nil) {
        print("=== PuzzleViewModel Initialization ===")
        self.databaseService = DatabaseService.shared
        // Use injected store or default to LocalPuzzleProgressStore
        if let store = progressStore {
            self.progressStore = store
        } else if let db = DatabaseService.shared.db {
            self.progressStore = LocalPuzzleProgressStore(database: db)
        } else {
            fatalError("Database connection not initialized for progress tracking!")
        }
        
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
        
        // Setup observers for settings changes
        setupNotificationObservers()
    }
    
    private func setupNotificationObservers() {
        // Listen for difficulty selection changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleDifficultySelectionChanged),
            name: SettingsViewModel.difficultySelectionChangedNotification,
            object: nil
        )
    }
    
    @objc private func handleDifficultySelectionChanged() {
        // Only reload if we're on the main menu or just starting
        // Don't interrupt an active game
        if session.isComplete || !session.hasStarted {
            loadNewPuzzle()
        }
    }
    
    // MARK: - Public Methods
    
    func startNewPuzzle(puzzle: Puzzle) {
        completedLetters = [] // Reset completed letters
        currentPuzzle = puzzle
        cells = puzzle.createCells(encodingType: encodingType)
        session = PuzzleSession()
        session = session
        
        // Animate all completed cells on puzzle load
        cellsToAnimate = Set(cells.filter { completedLetters.contains($0.encodedChar) }.map { $0.id })
        
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
        session = session
        
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
        print("[DEBUG] modifyCells called with index: \(index), operation: \(operation)")
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
                print("[DEBUG] Detected mistake at cell index \(index). Calling incrementMistakes().")
                print("[DEBUG] Before incrementMistakes, session.mistakeCount = \(session.mistakeCount)")
                session.incrementMistakes()
                print("[DEBUG] After incrementMistakes, session.mistakeCount = \(session.mistakeCount)")
                session = session // Ensure UI updates after mutation
                
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
            session = session
            
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
        print("[DEBUG] inputLetter called with letter: \(letter), index: \(index)")
        if session.startTime == nil {
            session.startTime = Date() // Start timer on first input
            session = session
        }
        
        guard index >= 0 && index < cells.count, !cells[index].isSymbol else { return }
        let cell = cells[index]
        // Only allow correct input
        if let solution = cell.solutionChar, letter.uppercased() == String(solution).uppercased() {
            cells[index].userInput = letter.uppercased()
            cells[index].wasJustFilled = true
            cells[index].isError = false
        } else {
            // Incorrect input: trigger error animation
            cells[index].isError = true
        }
        updateCompletedLetters()
        if modifyCells(at: index, operation: .input(letter)) {
            moveToNextCell()
        }
    }

    func handleDelete(at index: Int? = nil) {
        let targetIndex = index ?? session.selectedCellIndex ?? -1
        if targetIndex >= 0 {
            _ = modifyCells(at: targetIndex, operation: .delete)
            updateCompletedLetters()
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
            session = session
        }
        
        _ = modifyCells(at: targetIndex, operation: .reveal)
        selectNextUnrevealedCell(after: targetIndex)
    }
    
    func reset() {
        completedLetters = [] // Reset completed letters
        session = PuzzleSession()
        session = session
        for i in cells.indices {
            cells[i].userInput = ""
            cells[i].isError = false
            cells[i].wasJustFilled = false
            cells[i].isRevealed = false
            // Don't reset isPreFilled, as that's determined by mode
        }
        updateCompletedLetters() // Ensure completedLetters is up-to-date for pre-filled cells
        
        // Animate all completed cells on reset
        cellsToAnimate = Set(cells.filter { completedLetters.contains($0.encodedChar) }.map { $0.id })
        
        // --- Add Difficulty-based reveal logic --- 
        let difficulty = UserSettings.currentMode
        if difficulty == .normal {
            let solution = currentPuzzle?.solution.uppercased() ?? ""
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
    }
    
    func togglePause() {
        session.togglePause()
        session = session
    }
    
    func refreshPuzzleWithCurrentSettings() {
        // Exclude puzzles already completed by user
        let completedIDs = Set(progressStore.allAttempts().filter { $0.completedAt != nil }.map { $0.puzzleID })
        var nextPuzzle: Puzzle?
        let maxTries = 10
        var tries = 0
        repeat {
            if let candidate = databaseService.fetchRandomPuzzle(current: currentPuzzle, encodingType: encodingType) {
                if !completedIDs.contains(candidate.id) {
                    nextPuzzle = candidate
                    break
                }
            } else {
                break
            }
            tries += 1
        } while tries < maxTries
        // If no new unique puzzle found, allow any
        if nextPuzzle == nil {
            nextPuzzle = databaseService.fetchRandomPuzzle(encodingType: encodingType)
        }
        if let puzzle = nextPuzzle {
            startNewPuzzle(puzzle: puzzle)
        }
    }

    func loadNewPuzzle() {
        completedLetters = [] // Reset completed letters
        print("Loading new puzzle...")
        let selectedDifficulties = UserSettings.selectedDifficulties
        // Exclude puzzles already completed by user
        let completedIDs = Set(progressStore.allAttempts().filter { $0.completedAt != nil }.map { $0.puzzleID })
        var nextPuzzle: Puzzle?
        let maxTries = 10
        var tries = 0
        repeat {
            if let candidate = databaseService.fetchRandomPuzzle(
                current: currentPuzzle,
                encodingType: encodingType,
                selectedDifficulties: selectedDifficulties
            ) {
                if !completedIDs.contains(candidate.id) {
                    nextPuzzle = candidate
                    break
                }
            } else {
                break
            }
            tries += 1
        } while tries < maxTries
        // If no new unique puzzle found, allow any
        if nextPuzzle == nil {
            nextPuzzle = databaseService.fetchRandomPuzzle(
                encodingType: encodingType,
                selectedDifficulties: selectedDifficulties
            )
        }
        // Load or fallback
        if let puzzle = nextPuzzle {
            startNewPuzzle(puzzle: puzzle)
        } else {
            print("Error: Failed to load a new puzzle")
        }
        updateCompletedLetters() // Ensure state for pre-filled cells
        // Animate any completed cells
        cellsToAnimate = Set(cells.filter { completedLetters.contains($0.encodedChar) }.map { $0.id })
    }
    
    func moveToNextCell() {
        guard let currentIndex = session.selectedCellIndex else { return }
        
        // Find the next non-symbol cell
        var nextIndex = currentIndex + 1
        while nextIndex < cells.count {
            if !cells[nextIndex].isSymbol && cells[nextIndex].userInput.isEmpty {
                session.selectedCellIndex = nextIndex
                session = session
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
                session = session
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
                session = session
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
            session = session
        }
    }
    
    // MARK: - Private Methods
    
    // --- Completion/Attempt Logging ---
    func logPuzzleCompletion(timeTaken: TimeInterval) {
        guard let puzzle = currentPuzzle else { return }
        let attempt = PuzzleAttempt(
            attemptID: UUID(),
            puzzleID: puzzle.id,
            encodingType: encodingType,
            completedAt: Date(),
            failedAt: nil,
            completionTime: timeTaken,
            mode: UserSettings.currentMode.rawValue,
            hintCount: session.hintCount,
            mistakeCount: session.mistakeCount
        )
        progressStore.logAttempt(attempt)
    }

    func logPuzzleFailure() {
        guard let puzzle = currentPuzzle else { return }
        let attempt = PuzzleAttempt(
            attemptID: UUID(),
            puzzleID: puzzle.id,
            encodingType: encodingType,
            completedAt: nil,
            failedAt: Date(),
            completionTime: nil,
            mode: UserSettings.currentMode.rawValue,
            hintCount: session.hintCount,
            mistakeCount: session.mistakeCount
        )
        progressStore.logAttempt(attempt)
    }

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
            session = session
            // --- Log completion attempt ---
            if let start = session.startTime, let end = session.endTime {
                logPuzzleCompletion(timeTaken: end.timeIntervalSince(start))
            } else {
                logPuzzleCompletion(timeTaken: 0)
            }
        }
        
        // Also check if the game is failed due to mistake count
        if session.mistakeCount >= 3 && !session.isFailed {
            print("Game over: Too many mistakes!")
            session.markFailed()
            session = session
            // --- Log failed attempt ---
            logPuzzleFailure()
            // Add haptic feedback for failure
            DispatchQueue.main.async {
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.error)
            }
        }
    }
    
    private func updateCompletedLetters() {
        guard UserSettings.currentMode == .normal else {
            completedLetters = []
            return
        }
        // Find all unique encoded letters (excluding symbols)
        let allLetters = Set(cells.filter { !$0.isSymbol }.map { $0.encodedChar })
        var newCompleted: Set<String> = []
        for letter in allLetters {
            let letterCells = cells.filter { $0.encodedChar == letter && !$0.isSymbol }
            if letterCells.allSatisfy({ !$0.userInput.isEmpty }) {
                newCompleted.insert(letter)
            }
        }
        // Haptic feedback for any new completions
        let added = newCompleted.subtracting(completedLetters)
        if !added.isEmpty {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
        }
        completedLetters = newCompleted
        
        // Animate only newly completed cells on user input
        let newCellIDs = cells.filter { added.contains($0.encodedChar) }.map { $0.id }
        if !newCellIDs.isEmpty {
            cellsToAnimate.formUnion(newCellIDs)
        }
    }
    
    // Called by PuzzleCell when its animation completes
    func markCellAnimationComplete(_ cellID: UUID) {
        cellsToAnimate.remove(cellID)
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
    
    func userEngaged() {
        guard !hasUserEngaged else { return }
        print("[DEBUG] userEngaged() called")
        hasUserEngaged = true
        // Animate all pre-filled or revealed cells on first engagement
        let preCompletedCellIDs = cells.filter { $0.isPreFilled || $0.isRevealed }.map { $0.id }
        print("[DEBUG] Pre-filled/revealed cell IDs to animate: \(preCompletedCellIDs)")
        cellsToAnimate.formUnion(preCompletedCellIDs)
        print("[DEBUG] cellsToAnimate after engagement: \(cellsToAnimate)")
    }
    
    // --- Global Stats Reset ---
    func resetAllProgress() {
        progressStore.clearAllProgress()
    }
}
