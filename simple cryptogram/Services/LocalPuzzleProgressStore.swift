import Foundation
import SQLite

class LocalPuzzleProgressStore: PuzzleProgressStore {
    private let db: Connection
    private let attemptsTable = Table("puzzle_progress_attempts")
    private let attemptID = Expression<String>("attempt_id")
    private let puzzleID = Expression<String>("puzzle_id")
    private let encodingType = Expression<String>("encoding_type")
    private let completedAt = Expression<String?>("completed_at")
    private let failedAt = Expression<String?>("failed_at")
    private let completionTime = Expression<Double?>("completion_time")
    private let mode = Expression<String>("mode")
    private let hintCount = Expression<Int>("hint_count")
    private let mistakeCount = Expression<Int>("mistake_count")

    init(database: Connection) {
        self.db = database
        try? db.run(attemptsTable.create(ifNotExists: true) { t in
            t.column(attemptID, primaryKey: true)
            t.column(puzzleID)
            t.column(encodingType)
            t.column(completedAt)
            t.column(failedAt)
            t.column(completionTime)
            t.column(mode)
            t.column(hintCount)
            t.column(mistakeCount)
        })
    }

    func logAttempt(_ attempt: PuzzleAttempt) {
        let formatter = ISO8601DateFormatter()
        let insert = attemptsTable.insert(
            self.attemptID <- attempt.attemptID.uuidString,
            self.puzzleID <- attempt.puzzleID.uuidString,
            self.encodingType <- attempt.encodingType,
            self.completedAt <- attempt.completedAt.map { formatter.string(from: $0) },
            self.failedAt <- attempt.failedAt.map { formatter.string(from: $0) },
            self.completionTime <- attempt.completionTime,
            self.mode <- attempt.mode,
            self.hintCount <- attempt.hintCount,
            self.mistakeCount <- attempt.mistakeCount
        )
        _ = try? db.run(insert)
    }

    func attempts(for puzzleID: UUID, encodingType: String? = nil) -> [PuzzleAttempt] {
        let query = encodingType == nil ?
            attemptsTable.filter(self.puzzleID == puzzleID.uuidString) :
            attemptsTable.filter(self.puzzleID == puzzleID.uuidString && self.encodingType == encodingType!)
        let formatter = ISO8601DateFormatter()
        return (try? db.prepare(query).compactMap { row in
            PuzzleAttempt(
                attemptID: UUID(uuidString: row[attemptID])!,
                puzzleID: UUID(uuidString: row[self.puzzleID])!,
                encodingType: row[self.encodingType],
                completedAt: row[completedAt].flatMap { formatter.date(from: $0) },
                failedAt: row[failedAt].flatMap { formatter.date(from: $0) },
                completionTime: row[completionTime],
                mode: row[self.mode],
                hintCount: row[self.hintCount],
                mistakeCount: row[self.mistakeCount]
            )
        }) ?? []
    }

    func latestAttempt(for puzzleID: UUID, encodingType: String? = nil) -> PuzzleAttempt? {
        let all = attempts(for: puzzleID, encodingType: encodingType)
        return all.sorted(by: { ($0.completedAt ?? $0.failedAt ?? .distantPast) > ($1.completedAt ?? $1.failedAt ?? .distantPast) }).first
    }

    func bestCompletionTime(for puzzleID: UUID, encodingType: String? = nil) -> TimeInterval? {
        let all = attempts(for: puzzleID, encodingType: encodingType)
        return all.compactMap { $0.completionTime }.min()
    }

    func clearAllProgress() {
        _ = try? db.run(attemptsTable.delete())
    }

    // New: Fetch all attempts (all puzzles, all encodings)
    func allAttempts() -> [PuzzleAttempt] {
        let formatter = ISO8601DateFormatter()
        let query = attemptsTable
        return (try? db.prepare(query).compactMap { row in
            PuzzleAttempt(
                attemptID: UUID(uuidString: row[attemptID])!,
                puzzleID: UUID(uuidString: row[self.puzzleID])!,
                encodingType: row[self.encodingType],
                completedAt: row[completedAt].flatMap { formatter.date(from: $0) },
                failedAt: row[failedAt].flatMap { formatter.date(from: $0) },
                completionTime: row[completionTime],
                mode: row[self.mode],
                hintCount: row[self.hintCount],
                mistakeCount: row[self.mistakeCount]
            )
        }) ?? []
    }
}
