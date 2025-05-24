import Foundation
import SQLite

class LocalPuzzleProgressStore: PuzzleProgressStore {
    private let db: Connection
    private let attemptsTable = Table("puzzle_progress_attempts")
    private var initializationError: DatabaseError?
    
    // Helper function to generate fallback UUID for corrupted data
    private func generateFallbackUUID(for string: String) -> UUID? {
        // Try to create a deterministic UUID based on the corrupted string
        // This ensures consistency if the same corrupted data is encountered again
        let data = string.data(using: .utf8) ?? Data()
        let hash = data.reduce(0) { $0 &+ Int($1) }
        let fallbackString = "00000000-0000-0000-0000-\(String(format: "%012d", abs(hash)))"
        return UUID(uuidString: fallbackString)
    }
    private let attemptID = Expression<String>("attempt_id")
    private let puzzleID = Expression<String>("puzzle_id")
    private let encodingType = Expression<String>("encoding_type")
    private let completedAt = Expression<String?>("completed_at")
    private let failedAt = Expression<String?>("failed_at")
    private let completionTime = Expression<Double?>("completion_time")
    private let mode = Expression<String>("mode")
    private let hintCount = Expression<Int>("hint_count")
    private let mistakeCount = Expression<Int>("mistake_count")
    // Metadata table for tracking schema version
    private let metadataTable = Table("metadata")
    private let metaKey = Expression<String>("key")
    private let metaValue = Expression<String>("value")

    init(database: Connection) {
        self.db = database
        // Create metadata table if needed
        do {
            try db.run(metadataTable.create(ifNotExists: true) { t in
                t.column(metaKey, primaryKey: true)
                t.column(metaValue)
            })
        } catch {
            initializationError = DatabaseError.migrationFailed("Failed to create metadata table: \(error.localizedDescription)")
        }
        // Read current schema version
        var currentVersion = 0
        do {
            if let row = try db.pluck(metadataTable.filter(metaKey == "schema_version")) {
                let versionString = row[metaValue]
                if let v = Int(versionString) {
                    currentVersion = v
                }
            }
        } catch {
            // Schema version not found is ok - it means first run
        }
        do {
            try db.run(attemptsTable.create(ifNotExists: true) { t in
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
        } catch {
            initializationError = DatabaseError.migrationFailed("Failed to create attempts table: \(error.localizedDescription)")
        }
        // Versioned migration to add missing columns
        if currentVersion < 1 {
            let stmts = [
                "ALTER TABLE puzzle_progress_attempts ADD COLUMN mode TEXT DEFAULT 'normal'",
                "ALTER TABLE puzzle_progress_attempts ADD COLUMN hint_count INTEGER DEFAULT 0",
                "ALTER TABLE puzzle_progress_attempts ADD COLUMN mistake_count INTEGER DEFAULT 0"
            ]
            do {
                for s in stmts { 
                    try db.run(s) 
                }
                // Update schema version
                try db.run(metadataTable.insert(or: .replace,
                    metaKey <- "schema_version", metaValue <- "1"))
            } catch {
                initializationError = DatabaseError.migrationFailed("Failed to migrate to schema version 1: \(error.localizedDescription)")
            }
        }
    }

    func logAttempt(_ attempt: PuzzleAttempt) throws {
        if let error = initializationError {
            throw error
        }
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
        do {
            try db.run(insert)
        } catch {
            throw DatabaseError.queryFailed("Failed to log puzzle attempt: \(error.localizedDescription)")
        }
    }

    func attempts(for puzzleID: UUID, encodingType: String? = nil) throws -> [PuzzleAttempt] {
        if let error = initializationError {
            throw error
        }
        let query = encodingType == nil ?
            attemptsTable.filter(self.puzzleID == puzzleID.uuidString) :
            attemptsTable.filter(self.puzzleID == puzzleID.uuidString && self.encodingType == encodingType!)
        let formatter = ISO8601DateFormatter()
        do {
            return try db.prepare(query).compactMap { row in
                // Safely unwrap UUIDs with fallback generation for corrupted data
                guard let attemptUUID = UUID(uuidString: row[attemptID]) ?? generateFallbackUUID(for: row[attemptID]),
                      let puzzleUUID = UUID(uuidString: row[self.puzzleID]) ?? generateFallbackUUID(for: row[self.puzzleID]) else {
                    // Log corrupted data but continue processing other records
                    return nil
                }
                
                return PuzzleAttempt(
                    attemptID: attemptUUID,
                    puzzleID: puzzleUUID,
                    encodingType: row[self.encodingType],
                    completedAt: row[completedAt].flatMap { formatter.date(from: $0) },
                    failedAt: row[failedAt].flatMap { formatter.date(from: $0) },
                    completionTime: row[completionTime],
                    mode: row[self.mode],
                    hintCount: row[self.hintCount],
                    mistakeCount: row[self.mistakeCount]
                )
            }
        } catch {
            throw DatabaseError.queryFailed("Failed to fetch attempts: \(error.localizedDescription)")
        }
    }

    func latestAttempt(for puzzleID: UUID, encodingType: String? = nil) throws -> PuzzleAttempt? {
        let all = try attempts(for: puzzleID, encodingType: encodingType)
        return all.sorted(by: { ($0.completedAt ?? $0.failedAt ?? .distantPast) > ($1.completedAt ?? $1.failedAt ?? .distantPast) }).first
    }

    func bestCompletionTime(for puzzleID: UUID, encodingType: String? = nil) throws -> TimeInterval? {
        let all = try attempts(for: puzzleID, encodingType: encodingType)
        return all.compactMap { $0.completionTime }.min()
    }

    func clearAllProgress() throws {
        if let error = initializationError {
            throw error
        }
        do {
            try db.run(attemptsTable.delete())
        } catch {
            throw DatabaseError.queryFailed("Failed to clear progress: \(error.localizedDescription)")
        }
    }

    // New: Fetch all attempts (all puzzles, all encodings)
    func allAttempts() throws -> [PuzzleAttempt] {
        if let error = initializationError {
            throw error
        }
        let formatter = ISO8601DateFormatter()
        let query = attemptsTable
        do {
            return try db.prepare(query).compactMap { row in
                // Safely unwrap UUIDs with fallback generation for corrupted data
                guard let attemptUUID = UUID(uuidString: row[attemptID]) ?? generateFallbackUUID(for: row[attemptID]),
                      let puzzleUUID = UUID(uuidString: row[self.puzzleID]) ?? generateFallbackUUID(for: row[self.puzzleID]) else {
                    // Log corrupted data but continue processing other records
                    return nil
                }
                
                return PuzzleAttempt(
                    attemptID: attemptUUID,
                    puzzleID: puzzleUUID,
                    encodingType: row[self.encodingType],
                    completedAt: row[completedAt].flatMap { formatter.date(from: $0) },
                    failedAt: row[failedAt].flatMap { formatter.date(from: $0) },
                    completionTime: row[completionTime],
                    mode: row[self.mode],
                    hintCount: row[self.hintCount],
                    mistakeCount: row[self.mistakeCount]
                )
            }
        } catch {
            throw DatabaseError.queryFailed("Failed to fetch all attempts: \(error.localizedDescription)")
        }
    }
}
