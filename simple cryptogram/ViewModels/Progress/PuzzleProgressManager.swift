import Foundation
import Combine

@MainActor
class PuzzleProgressManager: ObservableObject {
    // MARK: - Properties
    private let progressStore: PuzzleProgressStore?
    @Published var currentError: DatabaseError?

    /// Indicates whether progress tracking is available
    var isAvailable: Bool {
        return progressStore != nil
    }
    
    // Session monitoring
    private var cancellables = Set<AnyCancellable>()
    private var gameStateManager: GameStateManager?
    private var encodingType: String {
        return AppSettings.shared.encodingType
    }
    
    // MARK: - Initialization
    init(progressStore: PuzzleProgressStore? = nil) {
        if let store = progressStore {
            self.progressStore = store
            print("✅ Progress tracking enabled (custom store)")
        } else if let db = DatabaseService.shared.db {
            self.progressStore = LocalPuzzleProgressStore(database: db)
            print("✅ Progress tracking enabled (local store)")
        } else {
            // Graceful degradation - progress tracking disabled but app continues
            self.progressStore = nil
            print("⚠️ Database unavailable - progress tracking disabled")
        }
    }
    
    // MARK: - Logging Methods
    func logCompletion(puzzle: Puzzle, session: PuzzleSession, encodingType: String) {
        guard let progressStore = progressStore else {
            print("⚠️ Progress tracking unavailable - completion not logged")
            return
        }

        let timeTaken = session.completionTime ?? 0
        let attempt = PuzzleAttempt(
            attemptID: UUID(),
            puzzleID: puzzle.id,
            encodingType: encodingType,
            completedAt: session.endTime ?? Date(),
            failedAt: nil,
            completionTime: timeTaken,
            mode: "normal",
            hintCount: session.hintCount,
            mistakeCount: session.mistakeCount
        )

        do {
            try progressStore.logAttempt(attempt)
        } catch {
            currentError = error as? DatabaseError ?? DatabaseError.connectionFailed
        }
    }
    
    func logFailure(puzzle: Puzzle, session: PuzzleSession, encodingType: String) {
        guard let progressStore = progressStore else {
            print("⚠️ Progress tracking unavailable - failure not logged")
            return
        }

        let attempt = PuzzleAttempt(
            attemptID: UUID(),
            puzzleID: puzzle.id,
            encodingType: encodingType,
            completedAt: nil,
            failedAt: Date(),
            completionTime: nil,
            mode: "normal",
            hintCount: session.hintCount,
            mistakeCount: session.mistakeCount
        )

        do {
            try progressStore.logAttempt(attempt)
        } catch {
            currentError = error as? DatabaseError ?? DatabaseError.connectionFailed
        }
    }
    
    // MARK: - Progress Queries
    func attempts(for puzzleId: UUID, encodingType: String) -> [PuzzleAttempt] {
        guard let progressStore = progressStore else {
            print("⚠️ Progress tracking unavailable - no attempts available")
            return []
        }

        do {
            return try progressStore.attempts(for: puzzleId, encodingType: encodingType)
        } catch {
            currentError = error as? DatabaseError ?? DatabaseError.connectionFailed
            return []
        }
    }
    
    func completionCount(for puzzleId: UUID, encodingType: String) -> Int {
        attempts(for: puzzleId, encodingType: encodingType)
            .filter { $0.completedAt != nil }
            .count
    }
    
    func failureCount(for puzzleId: UUID, encodingType: String) -> Int {
        attempts(for: puzzleId, encodingType: encodingType)
            .filter { $0.failedAt != nil }
            .count
    }
    
    func bestTime(for puzzleId: UUID, encodingType: String) -> TimeInterval? {
        guard let progressStore = progressStore else {
            print("⚠️ Progress tracking unavailable - no best time available")
            return nil
        }

        do {
            return try progressStore.bestCompletionTime(for: puzzleId, encodingType: encodingType)
        } catch {
            currentError = error as? DatabaseError ?? DatabaseError.connectionFailed
            return nil
        }
    }
    
    func allAttempts() -> [PuzzleAttempt] {
        guard let progressStore = progressStore else {
            print("⚠️ Progress tracking unavailable - no attempts available")
            return []
        }

        do {
            return try progressStore.allAttempts()
        } catch {
            currentError = error as? DatabaseError ?? DatabaseError.connectionFailed
            return []
        }
    }
    
    func clearAllProgress() {
        guard let progressStore = progressStore else {
            print("⚠️ Progress tracking unavailable - no progress to clear")
            return
        }

        do {
            try progressStore.clearAllProgress()
        } catch {
            currentError = error as? DatabaseError ?? DatabaseError.connectionFailed
        }
    }
    
    // MARK: - Session Monitoring
    func startMonitoring(gameState: GameStateManager) {
        self.gameStateManager = gameState
        
        gameState.$session
            .receive(on: DispatchQueue.main)
            .sink { [weak self] session in
                self?.handleSessionChange(session)
            }
            .store(in: &cancellables)
    }
    
    private func handleSessionChange(_ session: PuzzleSession) {
        guard let gameState = gameStateManager,
              let currentPuzzle = gameState.currentPuzzle else { return }
        
        if session.isComplete && session.endTime != nil && !session.wasLogged {
            logPuzzleCompletion(puzzle: currentPuzzle, session: session)
        } else if session.isFailed && !session.wasLogged {
            logPuzzleFailure(puzzle: currentPuzzle, session: session)
        }
    }
    
    private func logPuzzleCompletion(puzzle: Puzzle, session: PuzzleSession) {
        logCompletion(puzzle: puzzle, session: session, encodingType: encodingType)
        gameStateManager?.markSessionAsLogged()
    }
    
    private func logPuzzleFailure(puzzle: Puzzle, session: PuzzleSession) {
        logFailure(puzzle: puzzle, session: session, encodingType: encodingType)
        gameStateManager?.markSessionAsLogged()
    }
}

// MARK: - PuzzleSession Extension
extension PuzzleSession {
    var wasLogged: Bool {
        get { self.userInfo["wasLogged"] as? Bool ?? false }
    }
    
    mutating func setWasLogged(_ value: Bool) {
        self.userInfo["wasLogged"] = value
    }
}