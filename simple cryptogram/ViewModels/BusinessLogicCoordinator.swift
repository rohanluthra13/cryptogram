import Foundation
import Combine
import SwiftUI

/// Coordinates business logic between managers without UI concerns
/// Replaces the bloated PuzzleViewModel with clean separation of concerns
@MainActor
class BusinessLogicCoordinator: ObservableObject {
    // MARK: - Core Managers
    @Published private(set) var gameState: GameStateManager
    @Published private(set) var progressManager: PuzzleProgressManager
    @Published private(set) var dailyManager: DailyPuzzleManager
    @Published private(set) var authorService: AuthorService
    
    private let inputHandler: InputHandler
    private let hintManager: HintManager
    private let statisticsManager: StatisticsManager
    private let databaseService: DatabaseService
    private let puzzleSelectionManager: PuzzleSelectionManager
    
    // MARK: - Business State
    @Published var isLoadingPuzzle: Bool = false
    @Published var currentError: DatabaseError? {
        didSet {
            if let error = currentError {
                if ErrorRecoveryService.shared.attemptRecovery(from: error) {
                    currentError = nil
                }
            }
        }
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Settings Access
    private var encodingType: String {
        return AppSettings.shared.encodingType
    }
    
    private var selectedDifficulties: [String] {
        return AppSettings.shared.selectedDifficulties
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
        
        setupObservers()
        progressManager.startMonitoring(gameState: gameState)
        
        if let puzzle = initialPuzzle {
            gameState.startNewPuzzle(puzzle)
        }
        
        setupNotificationObservers()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Game State Access (Read-Only)
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
    
    // MARK: - Daily Puzzle Access
    var isDailyPuzzle: Bool { dailyManager.isDailyPuzzle }
    var isDailyPuzzleCompletedPublished: Bool { dailyManager.isDailyPuzzleCompletedPublished }
    var isDailyPuzzleCompleted: Bool { dailyManager.checkDailyPuzzleCompleted(puzzle: currentPuzzle) }
    var isTodaysDailyPuzzleCompleted: Bool { dailyManager.isTodaysDailyPuzzleCompleted() }
    var currentDailyPuzzleDate: Date? { dailyManager.currentPuzzleDate }
    var isCompletedDailyPuzzle: Bool { isDailyPuzzle && isComplete && session.endTime != nil }
    
    // MARK: - Author Access
    var currentAuthor: Author? { authorService.currentAuthor }
    
    // MARK: - Statistics Access
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
    
    // MARK: - Business Logic Methods
    
    /// Start a new puzzle session
    func startNewPuzzle(puzzle: Puzzle, skipAnimationInit: Bool = false) {
        gameState.startNewPuzzle(puzzle, skipAnimationInit: skipAnimationInit)
        authorService.loadAuthorIfNeeded(name: puzzle.hint)
    }
    
    /// Handle user input
    func inputLetter(_ letter: String, at index: Int) {
        inputHandler.inputLetter(letter, at: index)
        handleUserAction()
    }
    
    /// Handle cell selection
    func selectCell(at index: Int) {
        inputHandler.selectCell(at: index)
    }
    
    /// Handle delete action
    func handleDelete(at index: Int? = nil) {
        inputHandler.handleDelete(at: index)
        handleUserAction()
    }
    
    /// Reveal a cell (hint)
    func revealCell(at index: Int? = nil) {
        hintManager.revealCell(at: index)
        handleUserAction()
    }
    
    /// Reset the puzzle
    func reset() {
        gameState.resetPuzzle()
        handleUserAction()
    }
    
    /// Continue after game failure
    func continueAfterFailure() {
        gameState.clearFailureState()
        handleUserAction()
    }
    
    /// Toggle pause state
    func togglePause() {
        gameState.togglePause()
    }
    
    /// Navigate to next empty cell
    func moveToNextCell() {
        inputHandler.moveToNextCell()
    }
    
    /// Move to adjacent cell
    func moveToAdjacentCell(direction: Int) {
        inputHandler.moveToAdjacentCell(direction: direction)
    }
    
    /// Trigger completion wiggle animation
    func triggerCompletionWiggle() {
        gameState.triggerCompletionWiggle()
    }
    
    /// Mark user as engaged
    func userEngaged() {
        gameState.userEngaged()
        handleUserAction()
    }
    
    /// Mark cell animation as complete
    func markCellAnimationComplete(_ cellId: UUID) {
        gameState.markCellAnimationComplete(cellId)
    }
    
    /// Load a new random puzzle
    func loadNewPuzzle() async {
        dailyManager.resetDailyPuzzleState()
        await loadPuzzleWithDifficulty()
        handleUserAction()
    }
    
    /// Load puzzle with current settings and exclusions
    func refreshPuzzleWithCurrentSettings() async {
        dailyManager.resetDailyPuzzleState()
        await loadPuzzleWithExclusions()
    }
    
    /// Load daily puzzle for a specific date
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
            Task {
                await loadNewPuzzle()
            }
        }
    }
    
    /// Reset all progress statistics
    func resetAllProgress() {
        statisticsManager.resetAllStatistics()
    }
    
    // MARK: - Private Methods
    
    private func setupObservers() {
        // Forward objectWillChange from gameState
        gameState.objectWillChange
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
        
        // Forward objectWillChange from dailyManager
        dailyManager.objectWillChange
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
        
        // Observe progress manager errors
        progressManager.$currentError
            .compactMap { $0 }
            .sink { [weak self] error in
                self?.currentError = error
            }
            .store(in: &cancellables)
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
            Task {
                await loadNewPuzzle()
            }
        }
    }
    
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