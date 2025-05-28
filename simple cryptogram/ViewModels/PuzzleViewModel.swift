import Foundation
import Combine
import SwiftUI
import UIKit

// Keep WordGroup struct for backward compatibility
struct WordGroup: Identifiable {
    let id = UUID()
    let indices: [Int]
    let includesSpace: Bool
}

@MainActor
class PuzzleViewModel: ObservableObject {
    // MARK: - Managers
    @Published private(set) var gameState: GameStateManager
    @Published private(set) var progressManager: PuzzleProgressManager
    @Published private(set) var dailyManager: DailyPuzzleManager
    
    private let inputHandler: InputHandler
    private let hintManager: HintManager
    private let statisticsManager: StatisticsManager
    private let databaseService: DatabaseService
    
    // Computed property for encodingType
    private var encodingType: String {
        return AppSettings.shared?.encodingType ?? "Letters"
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Author Info (keeping in ViewModel for now)
    @Published var currentAuthor: Author?
    @Published var isLoadingPuzzle: Bool = false
    private var lastAuthorName: String?
    
    // MARK: - Error Handling
    @Published var currentError: DatabaseError? {
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
    
    // Daily puzzle properties
    var isDailyPuzzle: Bool { dailyManager.isDailyPuzzle }
    var isDailyPuzzleCompletedPublished: Bool { dailyManager.isDailyPuzzleCompletedPublished }
    var isDailyPuzzleCompleted: Bool { dailyManager.checkDailyPuzzleCompleted(puzzle: currentPuzzle) }
    var isTodaysDailyPuzzleCompleted: Bool { dailyManager.isTodaysDailyPuzzleCompleted() }
    var currentDailyPuzzleDate: Date? { dailyManager.currentPuzzleDate }
    
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
        
        // Setup observers
        setupObservers()
        
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
        // Forward objectWillChange from gameState to trigger view updates
        gameState.objectWillChange
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
        
        // Forward objectWillChange from dailyManager for daily puzzle UI updates
        dailyManager.objectWillChange
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
        
        // Observe game state changes
        gameState.$session
            .sink { [weak self] session in
                self?.handleSessionChange(session)
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
            loadNewPuzzle()
        }
    }
    
    // MARK: - Public Methods
    func startNewPuzzle(puzzle: Puzzle, skipAnimationInit: Bool = false) {
        gameState.startNewPuzzle(puzzle, skipAnimationInit: skipAnimationInit)
        loadAuthorIfNeeded(name: puzzle.hint ?? "")
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
    
    func refreshPuzzleWithCurrentSettings() {
        dailyManager.resetDailyPuzzleState()
        loadNewPuzzleWithExclusions()
    }
    
    func loadNewPuzzle() {
        dailyManager.resetDailyPuzzleState()
        loadNewPuzzleWithDifficulty()
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
            
            loadAuthorIfNeeded(name: puzzle.hint ?? "")
            isLoadingPuzzle = false
        } catch {
            isLoadingPuzzle = false
            currentError = error as? DatabaseError ?? DatabaseError.connectionFailed
            dailyManager.resetDailyPuzzleState()
            loadNewPuzzle()
        }
    }
    
    func loadAuthorIfNeeded(name: String) {
        guard name != lastAuthorName else { return }
        lastAuthorName = name
        
        Task { [weak self] in
            guard let self = self else { return }
            do {
                let author = try await self.databaseService.fetchAuthor(byName: name)
                self.currentAuthor = author
            } catch {
                self.currentAuthor = nil
            }
        }
    }
    
    // MARK: - Private Methods
    private func handleSessionChange(_ session: PuzzleSession) {
        if session.isComplete && !session.wasLogged {
            logPuzzleCompletion()
        } else if session.isFailed && !session.wasLogged {
            logPuzzleFailure()
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
    
    private func logPuzzleCompletion() {
        guard let puzzle = currentPuzzle else { return }
        progressManager.logCompletion(
            puzzle: puzzle,
            session: gameState.session,
            encodingType: encodingType
        )
        gameState.session.wasLogged = true
    }
    
    private func logPuzzleFailure() {
        guard let puzzle = currentPuzzle else { return }
        progressManager.logFailure(
            puzzle: puzzle,
            session: gameState.session,
            encodingType: encodingType
        )
        gameState.session.wasLogged = true
    }
    
    private func loadInitialPuzzle() {
        do {
            if let puzzle = try databaseService.fetchRandomPuzzle(encodingType: encodingType, selectedDifficulties: UserSettings.selectedDifficulties) {
                gameState.startNewPuzzle(puzzle)
                loadAuthorIfNeeded(name: puzzle.hint ?? "")
            } else {
                useFallbackPuzzle()
            }
        } catch {
            currentError = error as? DatabaseError ?? DatabaseError.connectionFailed
            useFallbackPuzzle()
        }
    }
    
    private func loadNewPuzzleWithExclusions() {
        do {
            let completedIDs = Set(progressManager.allAttempts()
                .filter { $0.completedAt != nil }
                .map { $0.puzzleID })
            
            var nextPuzzle: Puzzle?
            let maxTries = 10
            var tries = 0
            
            repeat {
                if let candidate = try databaseService.fetchRandomPuzzle(
                    current: currentPuzzle,
                    encodingType: encodingType,
                    selectedDifficulties: UserSettings.selectedDifficulties
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
            
            if nextPuzzle == nil {
                nextPuzzle = try databaseService.fetchRandomPuzzle(
                    encodingType: encodingType,
                    selectedDifficulties: UserSettings.selectedDifficulties
                )
            }
            
            if let puzzle = nextPuzzle {
                gameState.startNewPuzzle(puzzle)
                loadAuthorIfNeeded(name: puzzle.hint ?? "")
            }
        } catch {
            currentError = error as? DatabaseError ?? DatabaseError.connectionFailed
        }
    }
    
    private func loadNewPuzzleWithDifficulty() {
        gameState.completedLetters = []
        let selectedDifficulties = UserSettings.selectedDifficulties
        
        do {
            let completedIDs = Set(progressManager.allAttempts()
                .filter { $0.completedAt != nil }
                .map { $0.puzzleID })
            
            var nextPuzzle: Puzzle?
            let maxTries = 10
            var tries = 0
            
            repeat {
                if let candidate = try databaseService.fetchRandomPuzzle(
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
            
            if nextPuzzle == nil {
                nextPuzzle = try databaseService.fetchRandomPuzzle(
                    encodingType: encodingType,
                    selectedDifficulties: selectedDifficulties
                )
            }
            
            if let puzzle = nextPuzzle {
                gameState.startNewPuzzle(puzzle)
                loadAuthorIfNeeded(name: puzzle.hint ?? "")
            } else {
                currentError = DatabaseError.noDataFound
                useFallbackPuzzle()
            }
        } catch {
            currentError = error as? DatabaseError ?? DatabaseError.connectionFailed
            useFallbackPuzzle()
        }
        
        gameState.updateCompletedLetters()
    }
    
    private func useFallbackPuzzle() {
        let fallbackPuzzle = Puzzle(
            quoteId: 0,
            encodedText: "THE QUICK BROWN FOX JUMPS OVER THE LAZY DOG",
            solution: "THE QUICK BROWN FOX JUMPS OVER THE LAZY DOG",
            hint: "A pangram containing every letter of the alphabet"
        )
        gameState.startNewPuzzle(fallbackPuzzle)
    }
}

// MARK: - PuzzleSession Extension
extension PuzzleSession {
    var wasLogged: Bool {
        get { self.userInfo["wasLogged"] as? Bool ?? false }
        set { self.userInfo["wasLogged"] = newValue }
    }
}