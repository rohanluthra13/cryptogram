import Foundation
import SwiftUI

@MainActor
class GameStateManager: ObservableObject {
    // MARK: - Published Properties
    @Published var cells: [CryptogramCell] = []
    @Published private(set) var currentPuzzle: Puzzle?
    @Published var session: PuzzleSession = PuzzleSession()
    @Published var isWiggling = false
    @Published var completedLetters: Set<String> = []
    @Published var hasUserEngaged: Bool = false
    @Published var showCompletedHighlights: Bool = false
    
    // MARK: - Private Properties
    private let databaseService: DatabaseService
    private var letterMapping: [String: String] = [:]
    private var letterUsage: [String: String] = [:]
    
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
        
        if !skipAnimationInit {
            applyDifficultyPrefills()
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
        objectWillChange.send()
    }
    
    func incrementMistakes() {
        session.incrementMistakes()
        objectWillChange.send()
        
        if session.mistakeCount >= 3 && !session.isFailed && !session.hasContinuedAfterFailure {
            // Delay game over overlay to allow mistake animation to complete
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
                self?.markFailed()
            }
        }
    }
    
    func incrementHints() {
        session.revealCell(at: 0) // Session tracks hint count
        objectWillChange.send()
    }
    
    func togglePause() {
        session.togglePause()
        objectWillChange.send()
    }
    
    func startTimer() {
        if session.startTime == nil {
            session.startTime = Date()
            objectWillChange.send()
        }
    }
    
    func triggerCompletionWiggle() {
        isWiggling = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
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
        // Always update completed letters (previously normal mode behavior)
        
        let allLetters = Set(cells.filter { !$0.isSymbol }.map { $0.encodedChar })
        var newCompleted: Set<String> = []
        
        for letter in allLetters {
            let letterCells = cells.filter { $0.encodedChar == letter && !$0.isSymbol }
            if letterCells.allSatisfy({ !$0.userInput.isEmpty }) {
                newCompleted.insert(letter)
            }
        }
        
        completedLetters = newCompleted
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
        objectWillChange.send()
    }
    
    private func markFailed() {
        session.markFailed()
        objectWillChange.send()
    }
    
    func clearFailureState() {
        session.clearFailureState()
        objectWillChange.send()
    }
    
    func markSessionAsLogged() {
        session.setWasLogged(true)
        objectWillChange.send()
    }
}