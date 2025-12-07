import Foundation
import Observation
import SwiftUI
import UIKit

// Keep WordGroup struct for backward compatibility
struct WordGroup: Identifiable {
    let id = UUID()
    let indices: [Int]
    let includesSpace: Bool
}

@MainActor
@Observable
final class PuzzleViewModel {
    // MARK: - Managers
    private(set) var gameState: GameStateManager
    private(set) var progressManager: PuzzleProgressManager
    private(set) var dailyManager: DailyPuzzleManager
    private(set) var authorService: AuthorService

    private let inputHandler: InputHandler
    private let hintManager: HintManager
    private let statisticsManager: StatisticsManager
    private let databaseService: DatabaseService
    private let puzzleSelectionManager: PuzzleSelectionManager

    // Computed property for encodingType
    private var encodingType: String {
        return AppSettings.shared.encodingType
    }

    // Computed property for selectedDifficulties
    private var selectedDifficulties: [String] {
        return AppSettings.shared.selectedDifficulties
    }

    // MARK: - Loading State
    var isLoadingPuzzle: Bool = false

    // MARK: - Error Handling
    var currentError: DatabaseError? {
        didSet {
            if let error = currentError {
                if ErrorRecoveryService.shared.attemptRecovery(from: error) {
                    currentError = nil
                }
            }
        }
    }
    
    // MARK: - Computed Properties for Backward Compatibility
    var cells: [CryptogramCell] { gameState.cells }
    var session: PuzzleSession { gameState.session }
    var currentPuzzle: Puzzle? { gameState.currentPuzzle }
    var isWiggling: Bool { gameState.isWiggling }
    var completedLetters: Set<String> { gameState.completedLetters }
    var hasUserEngaged: Bool { gameState.hasUserEngaged }
    var showCompletedHighlights: Bool { gameState.showCompletedHighlights }
    
    var selectedCellIndex: Int? { gameState.selectedCellIndex }
    var isComplete: Bool { gameState.isComplete }
    var isFailed: Bool { gameState.isFailed }
    var mistakeCount: Int { gameState.mistakeCount }
    var startTime: Date? { gameState.startTime }
    var endTime: Date? { gameState.endTime }
    var isPaused: Bool { gameState.isPaused }
    var hintCount: Int { gameState.hintCount }
    var completionTime: TimeInterval? { gameState.completionTime }
    var nonSymbolCells: [CryptogramCell] { gameState.nonSymbolCells }
    var progressPercentage: Double { gameState.progressPercentage }
    var wordGroups: [WordGroup] { gameState.wordGroups }
    var cellsToAnimate: [UUID] { gameState.cellsToAnimate }

    // Keyboard optimization mappings (pre-computed for performance)
    var solutionToEncodedMap: [Character: Set<String>] { gameState.solutionToEncodedMap }
    var lettersInPuzzle: Set<Character> { gameState.lettersInPuzzle }
    
    // Daily puzzle properties
    var isDailyPuzzle: Bool { dailyManager.isDailyPuzzle }
    var isDailyPuzzleCompletedPublished: Bool { dailyManager.isDailyPuzzleCompletedPublished }
    var isDailyPuzzleCompleted: Bool { dailyManager.checkDailyPuzzleCompleted(puzzle: currentPuzzle) }
    var isTodaysDailyPuzzleCompleted: Bool { dailyManager.isTodaysDailyPuzzleCompleted() }
    var currentDailyPuzzleDate: Date? { dailyManager.currentPuzzleDate }
    var dailyCompletionVersion: Int { dailyManager.completionVersion }
    
    // Author properties (delegated to AuthorService)
    var currentAuthor: Author? { authorService.currentAuthor }
    
    // Statistics properties
    var completionCountForCurrentPuzzle: Int {
        guard let puzzle = currentPuzzle else { return 0 }
        return statisticsManager.completionCount(for: puzzle.id, encodingType: encodingType)
    }
    
    var failureCountForCurrentPuzzle: Int {
        guard let puzzle = currentPuzzle else { return 0 }
        return statisticsManager.failureCount(for: puzzle.id, encodingType: encodingType)
    }
    
    var bestTimeForCurrentPuzzle: TimeInterval? {
        guard let puzzle = currentPuzzle else { return nil }
        return statisticsManager.bestTime(for: puzzle.id, encodingType: encodingType)
    }
    
    var totalAttempts: Int { statisticsManager.totalAttempts }
    var totalCompletions: Int { statisticsManager.totalCompletions }
    var totalFailures: Int { statisticsManager.totalFailures }
    var globalBestTime: TimeInterval? { statisticsManager.globalBestTime }
    var winRatePercentage: Int { statisticsManager.winRatePercentage }
    var averageTime: TimeInterval? { statisticsManager.averageTime }
    
    var isCompletedDailyPuzzle: Bool {
        return isDailyPuzzle && isComplete && session.endTime != nil
    }
    
    // MARK: - Initialization
    init(initialPuzzle: Puzzle? = nil, progressStore: PuzzleProgressStore? = nil) {
        self.databaseService = DatabaseService.shared
        
        // Initialize managers in proper order
        let gameStateManager = GameStateManager(databaseService: databaseService)
        let progressManager = PuzzleProgressManager(progressStore: progressStore)
        let inputHandler = InputHandler(gameState: gameStateManager)
        let hintManager = HintManager(gameState: gameStateManager, inputHandler: inputHandler)
        
        self.gameState = gameStateManager
        self.progressManager = progressManager
        self.inputHandler = inputHandler
        self.hintManager = hintManager
        self.statisticsManager = StatisticsManager(progressManager: progressManager)
        self.dailyManager = DailyPuzzleManager(databaseService: databaseService)
        self.authorService = AuthorService(databaseService: databaseService)
        self.puzzleSelectionManager = PuzzleSelectionManager(
            databaseService: databaseService,
            progressManager: progressManager,
            statisticsManager: statisticsManager
        )
        
        // Setup observers
        setupObservers()
        
        // Start progress monitoring
        progressManager.startMonitoring(gameState: gameState)
        
        // Load initial puzzle
        if let puzzle = initialPuzzle {
            gameState.startNewPuzzle(puzzle)
        } else {
            loadInitialPuzzle()
        }
        
        setupNotificationObservers()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Setup
    private func setupObservers() {
        // With @Observable, view updates happen automatically
        // No need for manual objectWillChange forwarding
        // Error handling will be done directly through computed properties or manual checks
    }
    
    private func setupNotificationObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleDifficultySelectionChanged),
            name: SettingsViewModel.difficultySelectionChangedNotification,
            object: nil
        )
    }
    
    @objc private func handleDifficultySelectionChanged() {
        if gameState.session.isComplete || !gameState.session.hasStarted {
            loadNewPuzzle()
        }
    }
    
    // MARK: - Public Methods
    func startNewPuzzle(puzzle: Puzzle, skipAnimationInit: Bool = false) {
        gameState.startNewPuzzle(puzzle, skipAnimationInit: skipAnimationInit)
        authorService.loadAuthorIfNeeded(name: puzzle.hint)
    }
    
    func selectCell(at index: Int) {
        inputHandler.selectCell(at: index)
    }
    
    func inputLetter(_ letter: String, at index: Int) {
        inputHandler.inputLetter(letter, at: index)
        handleUserAction()
    }
    
    func handleDelete(at index: Int? = nil) {
        inputHandler.handleDelete(at: index)
        handleUserAction()
    }
    
    func revealCell(at index: Int? = nil) {
        hintManager.revealCell(at: index)
        handleUserAction()
    }
    
    func reset() {
        gameState.resetPuzzle()
        handleUserAction()
    }
    
    func continueAfterFailure() {
        gameState.clearFailureState()
        handleUserAction()
    }
    
    func togglePause() {
        gameState.togglePause()
    }

    func pause() {
        gameState.pause()
    }

    func resume() {
        gameState.resume()
    }
    
    func refreshPuzzleWithCurrentSettings() {
        dailyManager.resetDailyPuzzleState()
        Task {
            await loadPuzzleWithExclusions()
        }
    }
    
    func loadNewPuzzle() {
        dailyManager.resetDailyPuzzleState()
        Task {
            await loadPuzzleWithDifficulty()
        }
        handleUserAction()
    }

    /// Async version that waits for puzzle to load before returning
    func loadNewPuzzleAsync() async {
        dailyManager.resetDailyPuzzleState()
        await loadPuzzleWithDifficulty()
        handleUserAction()
    }
    
    func moveToNextCell() {
        inputHandler.moveToNextCell()
    }
    
    func moveToAdjacentCell(direction: Int) {
        inputHandler.moveToAdjacentCell(direction: direction)
    }
    
    func triggerCompletionWiggle() {
        gameState.triggerCompletionWiggle()
    }
    
    func userEngaged() {
        gameState.userEngaged()
        handleUserAction()
    }
    
    func markCellAnimationComplete(_ cellId: UUID) {
        gameState.markCellAnimationComplete(cellId)
    }
    
    func resetAllProgress() {
        statisticsManager.resetAllStatistics()
    }
    
    func loadDailyPuzzle() {
        loadDailyPuzzle(for: Date())
    }
    
    func loadDailyPuzzle(for date: Date) {
        isLoadingPuzzle = true
        do {
            let (puzzle, progress) = try dailyManager.loadDailyPuzzle(for: date)
            
            if let progress = progress {
                // Restore from saved progress
                gameState.startNewPuzzle(puzzle, skipAnimationInit: true)
                var cells = gameState.cells
                var session = gameState.session
                dailyManager.restoreDailyProgress(to: &cells, session: &session, from: progress)
                // Update game state with restored values
                gameState.cells = cells
                gameState.session = session
                gameState.updateCompletedLetters()
            } else {
                // Fresh daily puzzle
                gameState.startNewPuzzle(puzzle, skipAnimationInit: false)
            }
            
            authorService.loadAuthorIfNeeded(name: puzzle.hint)
            isLoadingPuzzle = false
        } catch {
            isLoadingPuzzle = false
            currentError = error as? DatabaseError ?? DatabaseError.connectionFailed
            dailyManager.resetDailyPuzzleState()
            loadNewPuzzle()
        }
    }
    
    
    // MARK: - Private Methods
    private func handleUserAction() {
        if dailyManager.isDailyPuzzle {
            saveDailyPuzzleProgress()
        }
    }

    private func saveDailyPuzzleProgress() {
        guard let puzzle = currentPuzzle else { return }
        dailyManager.saveDailyPuzzleProgress(
            puzzle: puzzle,
            cells: gameState.cells,
            session: gameState.session
        )
    }

    /// Explicitly save daily puzzle progress on completion.
    /// Call this when completion is detected to ensure the completion state is persisted.
    func saveCompletionIfDaily() {
        if dailyManager.isDailyPuzzle {
            saveDailyPuzzleProgress()
        }
    }

    /// Flush any pending debounced daily puzzle saves. Call when app goes to background.
    func flushPendingDailySave() {
        dailyManager.flushPendingSave()
    }
    
    private func loadInitialPuzzle() {
        Task {
            await loadPuzzleWithDifficulty()
        }
    }
    
    private func loadPuzzleWithExclusions() async {
        do {
            isLoadingPuzzle = true
            let puzzle = try await puzzleSelectionManager.loadRandomPuzzle(
                encodingType: encodingType,
                difficulties: selectedDifficulties,
                excludeCompleted: true
            )
            gameState.startNewPuzzle(puzzle)
            authorService.loadAuthorIfNeeded(name: puzzle.hint)
        } catch {
            currentError = error as? DatabaseError ?? DatabaseError.connectionFailed
        }
        isLoadingPuzzle = false
    }
    
    private func loadPuzzleWithDifficulty() async {
        do {
            isLoadingPuzzle = true
            let puzzle = try await puzzleSelectionManager.loadRandomPuzzle(
                encodingType: encodingType,
                difficulties: selectedDifficulties,
                excludeCompleted: false
            )
            gameState.startNewPuzzle(puzzle)
            authorService.loadAuthorIfNeeded(name: puzzle.hint)
        } catch {
            currentError = error as? DatabaseError ?? DatabaseError.connectionFailed
        }
        isLoadingPuzzle = false
    }
    
}

