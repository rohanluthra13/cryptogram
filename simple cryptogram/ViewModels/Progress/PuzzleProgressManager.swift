import Foundation
import Observation

@MainActor
@Observable
final class PuzzleProgressManager {
    // MARK: - Properties
    private let progressStore: PuzzleProgressStore
    var currentError: DatabaseError?

    // Session monitoring
    private var gameStateManager: GameStateManager?
    private var encodingType: String {
        return AppSettings.shared.encodingType
    }

    // MARK: - Initialization
    init(progressStore: PuzzleProgressStore? = nil) {
        if let store = progressStore {
            self.progressStore = store
        } else if let db = DatabaseService.shared.db {
            self.progressStore = LocalPuzzleProgressStore(database: db)
        } else {
            // Gracefully handle missing database with a no-op fallback
            print("⚠️ Warning: Database connection not initialized for progress tracking. Using fallback store.")
            self.progressStore = NoOpProgressStore()
            self.currentError = .connectionFailed
        }
    }
    
    // MARK: - Logging Methods
    func logCompletion(puzzle: Puzzle, session: PuzzleSession, encodingType: String) {
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
        do {
            return try progressStore.bestCompletionTime(for: puzzleId, encodingType: encodingType)
        } catch {
            currentError = error as? DatabaseError ?? DatabaseError.connectionFailed
            return nil
        }
    }
    
    func allAttempts() -> [PuzzleAttempt] {
        do {
            return try progressStore.allAttempts()
        } catch {
            currentError = error as? DatabaseError ?? DatabaseError.connectionFailed
            return []
        }
    }
    
    func clearAllProgress() {
        do {
            try progressStore.clearAllProgress()
        } catch {
            currentError = error as? DatabaseError ?? DatabaseError.connectionFailed
        }
    }
    
    // MARK: - Session Monitoring
    func startMonitoring(gameState: GameStateManager) {
        self.gameStateManager = gameState
        // With @Observable, we can manually check session changes where needed
        // Session completion is typically logged after explicit events
    }

    func checkAndLogSessionIfNeeded() {
        guard let gameState = gameStateManager,
              let currentPuzzle = gameState.currentPuzzle else { return }

        let session = gameState.session

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

// MARK: - NoOpProgressStore (Fallback Implementation)
/// A safe fallback progress store that performs no operations when database is unavailable.
/// This prevents app crashes while maintaining the PuzzleProgressStore interface.
private class NoOpProgressStore: PuzzleProgressStore {
    func logAttempt(_ attempt: PuzzleAttempt) throws {
        // No-op: silently ignore logging when database is unavailable
        print("⚠️ NoOpProgressStore: Cannot log attempt (database unavailable)")
    }

    func attempts(for puzzleID: UUID, encodingType: String?) throws -> [PuzzleAttempt] {
        // Return empty array instead of crashing
        return []
    }

    func latestAttempt(for puzzleID: UUID, encodingType: String?) throws -> PuzzleAttempt? {
        // Return nil when no database available
        return nil
    }

    func bestCompletionTime(for puzzleID: UUID, encodingType: String?) throws -> TimeInterval? {
        // Return nil when no database available
        return nil
    }

    func clearAllProgress() throws {
        // No-op: nothing to clear
    }

    func allAttempts() throws -> [PuzzleAttempt] {
        // Return empty array instead of crashing
        return []
    }
}