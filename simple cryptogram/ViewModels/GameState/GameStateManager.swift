import Foundation
import SwiftUI
import Observation

@MainActor
@Observable
final class GameStateManager {
    // MARK: - Properties
    var cells: [CryptogramCell] = []
    private(set) var currentPuzzle: Puzzle?
    var session: PuzzleSession = PuzzleSession()
    var isWiggling = false
    var completedLetters: Set<String> = []
    var hasUserEngaged: Bool = false
    var showCompletedHighlights: Bool = false
    
    // MARK: - Private Properties
    private let databaseService: DatabaseService
    private var letterMapping: [String: String] = [:]
    private var letterUsage: [String: String] = [:]

    // MARK: - Keyboard Optimization (pre-computed mappings)
    /// Maps each solution letter to its encoded characters (for number encoding mode)
    private(set) var solutionToEncodedMap: [Character: Set<String>] = [:]
    /// Set of letters that appear in the puzzle solution
    private(set) var lettersInPuzzle: Set<Character> = []
    
    // Computed property for encodingType
    private var encodingType: String {
        return AppSettings.shared.encodingType
    }
    
    // MARK: - Computed Properties
    var selectedCellIndex: Int? {
        session.selectedCellIndex
    }
    
    var hasStarted: Bool {
        session.hasStarted
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
        let totalNonSymbol = nonSymbolCells.count
        guard totalNonSymbol > 0 else { return 0.0 }
        
        let filledCells = nonSymbolCells.filter { !$0.userInput.isEmpty }.count
        return Double(filledCells) / Double(totalNonSymbol)
    }
    
    var wordGroups: [WordGroup] {
        var groups: [WordGroup] = []
        var currentWordIndices: [Int] = []
        
        for index in cells.indices {
            let cell = cells[index]
            
            if cell.isSymbol && cell.encodedChar == " " {
                if !currentWordIndices.isEmpty {
                    groups.append(WordGroup(indices: currentWordIndices, includesSpace: true))
                    currentWordIndices = []
                }
            } else {
                currentWordIndices.append(index)
            }
        }
        
        if !currentWordIndices.isEmpty {
            groups.append(WordGroup(indices: currentWordIndices, includesSpace: false))
        }
        
        return groups
    }
    
    var cellsToAnimate: [UUID] {
        cells.filter { $0.wasJustFilled }.map { $0.id }
    }
    
    // MARK: - Initialization
    init(databaseService: DatabaseService = .shared) {
        self.databaseService = databaseService
    }
    
    // MARK: - Public Methods
    func startNewPuzzle(_ puzzle: Puzzle, skipAnimationInit: Bool = false) {
        completedLetters = []
        currentPuzzle = puzzle
        cells = puzzle.createCells(encodingType: encodingType)
        session = PuzzleSession()

        letterMapping = [:]
        letterUsage = [:]

        // Pre-compute keyboard mappings for performance
        updateKeyboardMappings()

        if !skipAnimationInit {
            applyDifficultyPrefills()
        }
        
        // Select the first editable cell by default
        if let firstEditableIndex = cells.indices.first(where: { index in
            let cell = cells[index]
            return !cell.isSymbol && !cell.isRevealed && !cell.isPreFilled
        }) {
            selectCell(at: firstEditableIndex)
        }
    }
    
    func resetPuzzle() {
        completedLetters = []
        session = PuzzleSession()
        hasUserEngaged = false
        
        for i in cells.indices {
            cells[i].userInput = ""
            cells[i].isError = false
            cells[i].wasJustFilled = false
            cells[i].isRevealed = false
        }
        
        applyDifficultyPrefills()
        updateCompletedLetters()
        
        // Select the first editable cell by default
        if let firstEditableIndex = cells.indices.first(where: { index in
            let cell = cells[index]
            return !cell.isSymbol && !cell.isRevealed && !cell.isPreFilled
        }) {
            selectCell(at: firstEditableIndex)
        }
    }
    
    func updateCell(at index: Int, with input: String, isRevealed: Bool = false, isError: Bool = false) {
        guard index >= 0 && index < cells.count else { return }
        
        cells[index].userInput = input
        cells[index].isRevealed = isRevealed
        cells[index].isError = isError
        
        if !input.isEmpty {
            cells[index].wasJustFilled = true
        }
        
        updateCompletedLetters()
        checkPuzzleCompletion()
    }
    
    func clearCell(at index: Int) {
        guard index >= 0 && index < cells.count else { return }
        
        cells[index].userInput = ""
        cells[index].isError = false
        cells[index].wasJustFilled = false
        
        updateCompletedLetters()
    }
    
    func markCellRevealed(at index: Int) {
        guard index >= 0 && index < cells.count else { return }
        cells[index].isRevealed = true
        cells[index].isPreFilled = false
    }
    
    func selectCell(at index: Int) {
        guard index >= 0 && index < cells.count else { return }

        // Don't select symbol cells
        guard !cells[index].isSymbol else { return }

        session.selectedCellIndex = index
    }
    
    func incrementMistakes() {
        session.incrementMistakes()

        if session.mistakeCount >= 3 && !session.isFailed && !session.hasContinuedAfterFailure {
            // Delay game over overlay to allow mistake animation to complete
            Task { [weak self] in
                try? await Task.sleep(for: .seconds(0.6))
                guard !Task.isCancelled else { return }
                self?.markFailed()
            }
        }
    }

    func incrementHints() {
        session.revealCell(at: 0) // Session tracks hint count
    }

    func togglePause() {
        session.togglePause()
    }

    func pause() {
        guard hasStarted && !isPaused else { return }
        togglePause()
    }

    func resume() {
        guard hasStarted && isPaused else { return }
        togglePause()
    }

    func startTimer() {
        if session.startTime == nil {
            session.startTime = Date()
        }
    }
    
    func triggerCompletionWiggle() {
        isWiggling = true

        Task { [weak self] in
            try? await Task.sleep(for: .seconds(0.6))
            guard !Task.isCancelled else { return }
            self?.isWiggling = false
        }
    }
    
    func markCellAnimationComplete(_ cellId: UUID) {
        if let idx = cells.firstIndex(where: { $0.id == cellId }) {
            cells[idx].wasJustFilled = false
        }
    }
    
    func userEngaged() {
        guard !hasUserEngaged else { return }
        hasUserEngaged = true
    }
    
    func resetAllWasJustFilled() {
        for i in 0..<cells.count {
            cells[i].wasJustFilled = false
        }
    }
    
    // MARK: - Private Methods
    private func updateKeyboardMappings() {
        var solutionMap: [Character: Set<String>] = [:]
        var puzzleLetters: Set<Character> = []

        for cell in cells where !cell.isSymbol {
            if let solution = cell.solutionChar {
                solutionMap[solution, default: []].insert(cell.encodedChar)
                puzzleLetters.insert(solution)
            }
        }

        solutionToEncodedMap = solutionMap
        lettersInPuzzle = puzzleLetters
    }

    private func applyDifficultyPrefills() {
        // Always apply prefills (previously normal mode behavior)
        guard let solution = currentPuzzle?.solution.uppercased() else { return }
        
        let uniqueLetters = Set(solution.filter { $0.isLetter })
        
        if !uniqueLetters.isEmpty {
            let revealPercentage = 0.20
            let numToReveal = max(1, Int(ceil(Double(uniqueLetters.count) * revealPercentage)))
            let lettersToReveal = uniqueLetters.shuffled().prefix(numToReveal)
            var revealedIndices = Set<Int>()
            
            for letter in lettersToReveal {
                let letterString = String(letter)
                let matchingIndices = cells.indices.filter {
                    cells[$0].solutionChar == letter && 
                    !revealedIndices.contains($0) && 
                    !cells[$0].isRevealed
                }
                
                if let indexToReveal = matchingIndices.randomElement() {
                    cells[indexToReveal].userInput = letterString
                    cells[indexToReveal].isRevealed = true
                    cells[indexToReveal].isError = false
                    cells[indexToReveal].isPreFilled = true
                    revealedIndices.insert(indexToReveal)
                }
            }
        }
    }
    
    func updateCompletedLetters() {
        // Single-pass O(n) algorithm instead of O(n*m)
        var letterHasEmpty: [String: Bool] = [:]

        for cell in cells where !cell.isSymbol {
            let letter = cell.encodedChar
            if letterHasEmpty[letter] == nil {
                letterHasEmpty[letter] = cell.userInput.isEmpty
            } else if cell.userInput.isEmpty {
                letterHasEmpty[letter] = true
            }
        }

        completedLetters = Set(letterHasEmpty.filter { !$0.value }.keys)
    }
    
    private func checkPuzzleCompletion() {
        let correctCount = nonSymbolCells.filter { $0.isCorrect }.count
        let totalCount = nonSymbolCells.count
        
        let allCorrect = correctCount == totalCount
        
        if allCorrect && !session.isComplete {
            markComplete()
        }
    }
    
    private func markComplete() {
        session.markComplete()
    }

    private func markFailed() {
        session.markFailed()
    }

    func clearFailureState() {
        session.clearFailureState()
    }

    func markSessionAsLogged() {
        session.setWasLogged(true)
    }
}