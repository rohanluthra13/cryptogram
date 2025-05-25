import Testing
@testable import simple_cryptogram
import SQLite
import Foundation

struct LocalPuzzleProgressStoreTests {
    
    // MARK: - Basic Functionality Tests
    
    @Test func logAttempt() async throws {
        let testDB = try Connection(.inMemory)
        let store = LocalPuzzleProgressStore(database: testDB)
        
        let attempt = PuzzleAttempt(
            attemptID: UUID(),
            puzzleID: UUID(),
            encodingType: "Letters",
            completedAt: nil,
            failedAt: nil,
            completionTime: nil,
            mode: "Normal",
            hintCount: 1,
            mistakeCount: 2
        )
        
        try store.logAttempt(attempt)
        
        // Verify it was stored
        let attempts = try store.attempts(for: attempt.puzzleID, encodingType: attempt.encodingType)
        #expect(attempts.count == 1)
        #expect(attempts.first?.attemptID == attempt.attemptID)
    }
    
    @Test func logCompletedAttempt() async throws {
        let testDB = try Connection(.inMemory)
        let store = LocalPuzzleProgressStore(database: testDB)
        
        let completedAt = Date()
        let attempt = PuzzleAttempt(
            attemptID: UUID(),
            puzzleID: UUID(),
            encodingType: "Letters",
            completedAt: completedAt,
            failedAt: nil,
            completionTime: 120.5,
            mode: "Normal",
            hintCount: 0,
            mistakeCount: 0
        )
        
        try store.logAttempt(attempt)
        
        let attempts = try store.attempts(for: attempt.puzzleID, encodingType: attempt.encodingType)
        #expect(attempts.first?.completedAt != nil)
        #expect(attempts.first?.completionTime == 120.5)
    }
    
    @Test func logFailedAttempt() async throws {
        let testDB = try Connection(.inMemory)
        let store = LocalPuzzleProgressStore(database: testDB)
        
        let failedAt = Date()
        let attempt = PuzzleAttempt(
            attemptID: UUID(),
            puzzleID: UUID(),
            encodingType: "Letters",
            completedAt: nil,
            failedAt: failedAt,
            completionTime: nil,
            mode: "Expert",
            hintCount: 0,
            mistakeCount: 3
        )
        
        try store.logAttempt(attempt)
        
        let attempts = try store.attempts(for: attempt.puzzleID, encodingType: attempt.encodingType)
        #expect(attempts.first?.failedAt != nil)
        #expect(attempts.first?.completedAt == nil)
    }
    
    // MARK: - Data Corruption Tests
    
    @Test func corruptedUUIDHandling() async throws {
        let testDB = try Connection(.inMemory)
        let store = LocalPuzzleProgressStore(database: testDB)
        
        // Manually insert corrupted data
        let attemptsTable = Table("puzzle_progress_attempts")
        let attemptID = Expression<String>("attempt_id")
        let puzzleID = Expression<String>("puzzle_id")
        let encodingType = Expression<String>("encoding_type")
        let mode = Expression<String>("mode")
        let hintCount = Expression<Int>("hint_count")
        let mistakeCount = Expression<Int>("mistake_count")
        
        // Insert record with invalid UUID
        let insert = attemptsTable.insert(
            attemptID <- "not-a-valid-uuid",
            puzzleID <- UUID().uuidString,
            encodingType <- "Letters",
            mode <- "Normal",
            hintCount <- 0,
            mistakeCount <- 0
        )
        
        try testDB.run(insert)
        
        // This should handle the corrupted data gracefully
        let allAttempts = try store.allAttempts()
        
        // The corrupted record should either be skipped or given a fallback UUID
        // The important thing is it doesn't crash
        #expect(true, "Should handle corrupted UUID without crashing")
    }
    
    @Test func multipleCorruptedRecords() async throws {
        let testDB = try Connection(.inMemory)
        let store = LocalPuzzleProgressStore(database: testDB)
        
        let attemptsTable = Table("puzzle_progress_attempts")
        let attemptID = Expression<String>("attempt_id")
        let puzzleID = Expression<String>("puzzle_id")
        let encodingType = Expression<String>("encoding_type")
        let mode = Expression<String>("mode")
        let hintCount = Expression<Int>("hint_count")
        let mistakeCount = Expression<Int>("mistake_count")
        
        // Insert multiple corrupted records
        let corruptedIDs = ["bad-id-1", "bad-id-2", "completely-invalid", ""]
        let validPuzzleID = UUID()
        
        for badID in corruptedIDs {
            let insert = attemptsTable.insert(
                attemptID <- badID,
                puzzleID <- validPuzzleID.uuidString,
                encodingType <- "Letters",
                mode <- "Normal",
                hintCount <- 0,
                mistakeCount <- 0
            )
            try testDB.run(insert)
        }
        
        // Also insert a valid record
        let validAttempt = PuzzleAttempt(
            attemptID: UUID(),
            puzzleID: validPuzzleID,
            encodingType: "Letters",
            completedAt: nil,
            failedAt: nil,
            completionTime: nil,
            mode: "Normal",
            hintCount: 0,
            mistakeCount: 0
        )
        try store.logAttempt(validAttempt)
        
        // Fetch attempts - should handle corrupted data gracefully
        let attempts = try store.attempts(for: validPuzzleID, encodingType: "Letters")
        
        // Should at least return the valid attempt
        #expect(attempts.count >= 1)
        #expect(attempts.contains { $0.attemptID == validAttempt.attemptID })
    }
    
    // MARK: - Migration Tests
    
    @Test func schemaVersion() async throws {
        let testDB = try Connection(.inMemory)
        let store = LocalPuzzleProgressStore(database: testDB)
        
        // The store should create the metadata table and track schema version
        let metadataTable = Table("metadata")
        let key = Expression<String>("key")
        let value = Expression<String>("value")
        
        // Check if schema version was set
        if let row = try testDB.pluck(metadataTable.filter(key == "schema_version")) {
            let version = row[value]
            #expect(version == "1", "Schema version should be set to 1")
        } else {
            Issue.record("Schema version should be set")
        }
    }
    
    @Test func migrationFromVersion0() async throws {
        // Simulate an old database without the new columns
        // First, create a fresh connection without running migrations
        let freshDB = try Connection(.inMemory)
        
        // Create the old table structure manually
        let attemptsTable = Table("puzzle_progress_attempts")
        let attemptID = Expression<String>("attempt_id")
        let puzzleID = Expression<String>("puzzle_id")
        let encodingType = Expression<String>("encoding_type")
        let completedAt = Expression<String?>("completed_at")
        let failedAt = Expression<String?>("failed_at")
        let completionTime = Expression<Double?>("completion_time")
        
        try freshDB.run(attemptsTable.create { t in
            t.column(attemptID, primaryKey: true)
            t.column(puzzleID)
            t.column(encodingType)
            t.column(completedAt)
            t.column(failedAt)
            t.column(completionTime)
            // Note: missing mode, hint_count, mistake_count columns
        })
        
        // Now create store which should run migrations
        let migratedStore = LocalPuzzleProgressStore(database: freshDB)
        
        // Test that we can insert with the new columns
        let attempt = PuzzleAttempt(
            attemptID: UUID(),
            puzzleID: UUID(),
            encodingType: "Numbers",
            completedAt: nil,
            failedAt: nil,
            completionTime: nil,
            mode: "Expert",
            hintCount: 2,
            mistakeCount: 1
        )
        
        // This should work after migration
        do {
            try migratedStore.logAttempt(attempt)
            #expect(true, "Should be able to log attempt after migration")
        } catch {
            Issue.record("Failed to log attempt after migration: \(error)")
        }
    }
    
    // MARK: - Query Tests
    
    @Test func bestCompletionTime() async throws {
        let testDB = try Connection(.inMemory)
        let store = LocalPuzzleProgressStore(database: testDB)
        
        let puzzleId = UUID()
        let times = [150.5, 120.3, 180.7, 90.2]
        
        for (index, time) in times.enumerated() {
            let attempt = PuzzleAttempt(
                attemptID: UUID(),
                puzzleID: puzzleId,
                encodingType: "Letters",
                completedAt: Date(),
                failedAt: nil,
                completionTime: time,
                mode: "Normal",
                hintCount: index, // Just to make them different
                mistakeCount: 0
            )
            try store.logAttempt(attempt)
        }
        
        let bestTime = try store.bestCompletionTime(for: puzzleId, encodingType: "Letters")
        #expect(bestTime == 90.2) // Should be the minimum time
    }
    
    @Test func latestAttempt() async throws {
        let testDB = try Connection(.inMemory)
        let store = LocalPuzzleProgressStore(database: testDB)
        
        let puzzleId = UUID()
        var lastAttempt: PuzzleAttempt?
        
        // Create attempts with different times
        for i in 0..<3 {
            let attempt = PuzzleAttempt(
                attemptID: UUID(),
                puzzleID: puzzleId,
                encodingType: "Letters",
                completedAt: Date().addingTimeInterval(TimeInterval(i * 60)),
                failedAt: nil,
                completionTime: 100.0,
                mode: "Normal",
                hintCount: 0,
                mistakeCount: i
            )
            try store.logAttempt(attempt)
            lastAttempt = attempt
        }
        
        let latest = try store.latestAttempt(for: puzzleId, encodingType: "Letters")
        #expect(latest?.attemptID == lastAttempt?.attemptID)
    }
    
    // MARK: - Statistics Tests
    
    @Test func allAttemptsRetrieval() async throws {
        let testDB = try Connection(.inMemory)
        let store = LocalPuzzleProgressStore(database: testDB)
        
        var expectedAttempts: [PuzzleAttempt] = []
        
        // Create attempts for different puzzles and encoding types
        for i in 0..<10 {
            let attempt = PuzzleAttempt(
                attemptID: UUID(),
                puzzleID: UUID(),
                encodingType: i % 2 == 0 ? "Letters" : "Numbers",
                completedAt: i % 3 == 0 ? Date() : nil,
                failedAt: i % 3 == 0 ? nil : Date(),
                completionTime: i % 3 == 0 ? Double(100 + i) : nil,
                mode: i % 3 == 0 ? "Expert" : "Normal",
                hintCount: i / 2,
                mistakeCount: i
            )
            try store.logAttempt(attempt)
            expectedAttempts.append(attempt)
        }
        
        let allAttempts = try store.allAttempts()
        #expect(allAttempts.count == 10)
        
        // Verify all attempts are present
        let attemptIDs = Set(allAttempts.map { $0.attemptID })
        let expectedIDs = Set(expectedAttempts.map { $0.attemptID })
        #expect(attemptIDs == expectedIDs)
    }
    
    @Test func clearAllProgress() async throws {
        let testDB = try Connection(.inMemory)
        let store = LocalPuzzleProgressStore(database: testDB)
        
        // Add some data
        for _ in 0..<5 {
            let attempt = PuzzleAttempt(
                attemptID: UUID(),
                puzzleID: UUID(),
                encodingType: "Letters",
                completedAt: Date(),
                failedAt: nil,
                completionTime: 100.0,
                mode: "Normal",
                hintCount: 0,
                mistakeCount: 0
            )
            try store.logAttempt(attempt)
        }
        
        // Verify data exists
        #expect(!(try store.allAttempts()).isEmpty)
        
        // Clear all progress
        try store.clearAllProgress()
        
        // Verify data is gone
        #expect((try store.allAttempts()).isEmpty)
    }
}