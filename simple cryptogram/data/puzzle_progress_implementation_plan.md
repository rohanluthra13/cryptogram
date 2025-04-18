# Puzzle Progress Tracking Implementation Plan (Phased, Multi-Attempt, with Time Tracking)

This document details a robust, scalable, and phased approach for tracking puzzle completion in the Simple Cryptogram app. It now supports **multiple attempts per puzzle**, tracking completions, failures, per encoding type, and time taken to complete. The schema is relational and future-proof for analytics and backend sync.

---

## Phased Implementation Roadmap

### **Phase 1: Core Completion Tracking (Multiple Attempts)**
- Define the `PuzzleProgressStore` protocol (basic version: log attempt, fetch attempts).
- Create the `puzzle_progress_attempts` table (attempt_id, puzzle_id, encoding_type, completed_at, etc.).
- Implement local storage (SQLite) for logging and querying attempts.
- Integrate with ViewModels/UI for logging puzzle attempts.
- Unit tests for basic attempt logging and retrieval.

### **Phase 2: Add Failure Tracking**
- Ensure schema/implementation supports both completions and failures per attempt.
- Update ViewModels/UI to record failures as attempts.
- Unit tests for failure tracking and multiple attempts.

### **Phase 3: Add Time Tracking**
- Ensure schema/implementation supports time taken per attempt.
- Integrate with ViewModels/UI to pass time taken when logging an attempt.
- Unit tests for time tracking.

### **Phase 4: Advanced Features & Analytics**
- Add advanced queries (e.g., best time, attempt history, streaks).
- Prepare for backend sync by implementing a remote progress store.
- Add migration logic from any legacy storage.

---

## Schema (Latest Version, Multi-Attempt)

```sql
CREATE TABLE IF NOT EXISTS puzzle_progress_attempts (
    attempt_id TEXT PRIMARY KEY,          -- Unique ID for each attempt (UUID or autoincrement)
    puzzle_id TEXT NOT NULL,              -- Foreign key to quotes table (the quote UID)
    encoding_type TEXT NOT NULL,
    completed_at TEXT,
    failed_at TEXT,
    completion_time REAL,
    FOREIGN KEY (puzzle_id) REFERENCES quotes(id)
);
```

### **Migration Example**
If upgrading from a single-attempt schema, create the new table and migrate any existing data as needed.

---

## Protocol (Multi-Attempt Version)

```swift
struct PuzzleAttempt {
    let attemptID: UUID
    let puzzleID: UUID
    let encodingType: String
    let completedAt: Date?
    let failedAt: Date?
    let completionTime: TimeInterval?
}

protocol PuzzleProgressStore {
    func logAttempt(_ attempt: PuzzleAttempt)  // Insert a new attempt (completion or failure)
    func attempts(for puzzleID: UUID, encodingType: String?) -> [PuzzleAttempt]
    func latestAttempt(for puzzleID: UUID, encodingType: String?) -> PuzzleAttempt?
    func bestCompletionTime(for puzzleID: UUID, encodingType: String?) -> TimeInterval?
    func clearAllProgress()
}
```

---

## Implementation (Multi-Attempt, Latest Version)

```swift
class LocalPuzzleProgressStore: PuzzleProgressStore {
    private let db: Connection
    private let attemptsTable = Table("puzzle_progress_attempts")
    private let attemptID = Expression<String>("attempt_id")
    private let puzzleID = Expression<String>("puzzle_id")
    private let encodingType = Expression<String>("encoding_type")
    private let completedAt = Expression<String?>("completed_at")
    private let failedAt = Expression<String?>("failed_at")
    private let completionTime = Expression<Double?>("completion_time")

    init(database: Connection) {
        self.db = database
        try? db.run(attemptsTable.create(ifNotExists: true) { t in
            t.column(attemptID, primaryKey: true)
            t.column(puzzleID)
            t.column(encodingType)
            t.column(completedAt)
            t.column(failedAt)
            t.column(completionTime)
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
            self.completionTime <- attempt.completionTime
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
                completionTime: row[completionTime]
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
}
```

---

## Example Usage in ViewModel

```swift
class PuzzleViewModel: ObservableObject {
    let progressStore: PuzzleProgressStore
    // ...
    func completeCurrentPuzzle(timeTaken: TimeInterval) {
        let attempt = PuzzleAttempt(
            attemptID: UUID(),
            puzzleID: currentPuzzle.id,
            encodingType: currentEncodingType,
            completedAt: Date(),
            failedAt: nil,
            completionTime: timeTaken
        )
        progressStore.logAttempt(attempt)
        // ... other logic
    }
    func failCurrentPuzzle() {
        let attempt = PuzzleAttempt(
            attemptID: UUID(),
            puzzleID: currentPuzzle.id,
            encodingType: currentEncodingType,
            completedAt: nil,
            failedAt: Date(),
            completionTime: nil
        )
        progressStore.logAttempt(attempt)
        // ... other logic
    }
    func allAttempts(_ puzzle: Puzzle, encodingType: String) -> [PuzzleAttempt] {
        progressStore.attempts(for: puzzle.id, encodingType: encodingType)
    }
    func bestTime(_ puzzle: Puzzle, encodingType: String) -> TimeInterval? {
        progressStore.bestCompletionTime(for: puzzle.id, encodingType: encodingType)
    }
}
```

---

## Summary Table

| Phase | Task                                    | Rationale                                 |
|-------|-----------------------------------------|--------------------------------------------|
| 1     | Completion tracking (multi-attempt)     | Foundation for analytics, richer UX        |
| 2     | Failure tracking                        | Enables richer analytics, user feedback    |
| 3     | Time tracking                           | Enables speed stats, streaks, gamification |
| 4     | Advanced features, analytics, backend   | Scalability, future-proofing               |

---

This phased plan ensures you can ship value incrementally, test each step, and easily extend your tracking for analytics and future backend sync. All attempts are tracked per puzzle and encoding type, supporting completions, failures, time taken, and attempt history. The schema is relational and ready for advanced queries or multi-user support in the future.
