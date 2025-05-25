import Foundation

@MainActor
class PuzzleProgressManager: ObservableObject {
    // MARK: - Properties
    private let progressStore: PuzzleProgressStore
    @Published var currentError: DatabaseError?
    
    // MARK: - Initialization
    init(progressStore: PuzzleProgressStore? = nil) {
        if let store = progressStore {
            self.progressStore = store
        } else if let db = DatabaseService.shared.db {
            self.progressStore = LocalPuzzleProgressStore(database: db)
        } else {
            fatalError("Database connection not initialized for progress tracking!")
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
            mode: UserSettings.currentMode.rawValue,
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
            mode: UserSettings.currentMode.rawValue,
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
}