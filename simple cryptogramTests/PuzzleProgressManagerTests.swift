import Testing
import Foundation
@testable import simple_cryptogram

@MainActor
struct PuzzleProgressManagerTests {
    
    // MARK: - Mock Progress Store
    class MockProgressStore: PuzzleProgressStore {
        private var attempts: [PuzzleAttempt] = []
        
        func logAttempt(_ attempt: PuzzleAttempt) throws {
            attempts.append(attempt)
        }
        
        func attempts(for puzzleID: UUID, encodingType: String?) throws -> [PuzzleAttempt] {
            if let encodingType = encodingType {
                return attempts.filter { $0.puzzleID == puzzleID && $0.encodingType == encodingType }
            } else {
                return attempts.filter { $0.puzzleID == puzzleID }
            }
        }
        
        func allAttempts() throws -> [PuzzleAttempt] {
            return attempts
        }
        
        func clearAllProgress() throws {
            attempts.removeAll()
        }
        
        func bestCompletionTime(for puzzleID: UUID, encodingType: String?) throws -> TimeInterval? {
            let filteredAttempts: [PuzzleAttempt]
            if let encodingType = encodingType {
                filteredAttempts = attempts.filter { 
                    $0.puzzleID == puzzleID && 
                    $0.encodingType == encodingType && 
                    $0.completedAt != nil &&
                    $0.completionTime != nil
                }
            } else {
                filteredAttempts = attempts.filter { 
                    $0.puzzleID == puzzleID && 
                    $0.completedAt != nil &&
                    $0.completionTime != nil
                }
            }
            return filteredAttempts.compactMap { $0.completionTime }.min()
        }
        
        func latestAttempt(for puzzleID: UUID, encodingType: String?) throws -> PuzzleAttempt? {
            let filteredAttempts = try attempts(for: puzzleID, encodingType: encodingType)
            return filteredAttempts.last
        }
        
        func clearAttempts() {
            attempts.removeAll()
        }
    }
    
    // MARK: - Test Data
    private func createTestPuzzle() -> Puzzle {
        return Puzzle(
            quoteId: 1,
            encodedText: "ABC DEF",
            solution: "THE DOG",
            hint: "Test puzzle"
        )
    }
    
    private func createTestSession(isComplete: Bool = false, completionTime: TimeInterval? = nil) -> PuzzleSession {
        var session = PuzzleSession()
        session.startTime = Date()
        session.mistakeCount = 2
        session.hintCount = 1
        
        if isComplete {
            session.endTime = Date()
            session.isComplete = true
            if let time = completionTime {
                session.endTime = session.startTime?.addingTimeInterval(time)
            }
        }
        
        return session
    }
    
    // MARK: - Initialization Tests
    @Test func initialization() async throws {
        let mockStore = MockProgressStore()
        let manager = PuzzleProgressManager(progressStore: mockStore)
        
        #expect(manager != nil)
        #expect(manager.currentError == nil)
    }
    
    @Test func initializationWithDefaultStore() async throws {
        let manager = PuzzleProgressManager()
        
        #expect(manager != nil)
        #expect(manager.currentError == nil)
    }
    
    // MARK: - Completion Logging Tests
    @Test func logCompletionSuccess() async throws {
        let mockStore = MockProgressStore()
        let manager = PuzzleProgressManager(progressStore: mockStore)
        let puzzle = createTestPuzzle()
        let session = createTestSession(isComplete: true, completionTime: 120.0)
        
        manager.logCompletion(puzzle: puzzle, session: session, encodingType: "Letters")
        
        let attempts = try mockStore.attempts(for: puzzle.id, encodingType: "Letters")
        #expect(attempts.count == 1)
        
        let attempt = attempts[0]
        #expect(attempt.puzzleID == puzzle.id)
        #expect(attempt.encodingType == "Letters")
        #expect(attempt.completedAt != nil)
        #expect(attempt.mistakeCount == 2)
        #expect(attempt.hintCount == 1)
        #expect(attempt.completionTime == 120.0)
    }
    
    @Test func logCompletionWithoutEndTime() async throws {
        let mockStore = MockProgressStore()
        let manager = PuzzleProgressManager(progressStore: mockStore)
        let puzzle = createTestPuzzle()
        var session = createTestSession(isComplete: true)
        session.endTime = nil // Remove end time
        
        manager.logCompletion(puzzle: puzzle, session: session, encodingType: "Letters")
        
        let attempts = try mockStore.attempts(for: puzzle.id, encodingType: "Letters")
        #expect(attempts.count == 1)
        #expect(attempts[0].completionTime == nil)
    }
    
    // MARK: - Failure Logging Tests
    @Test func logFailureSuccess() async throws {
        let mockStore = MockProgressStore()
        let manager = PuzzleProgressManager(progressStore: mockStore)
        let puzzle = createTestPuzzle()
        let session = createTestSession()
        
        manager.logFailure(puzzle: puzzle, session: session, encodingType: "Numbers")
        
        let attempts = try mockStore.attempts(for: puzzle.id, encodingType: "Numbers")
        #expect(attempts.count == 1)
        
        let attempt = attempts[0]
        #expect(attempt.puzzleID == puzzle.id)
        #expect(attempt.encodingType == "Numbers")
        #expect(attempt.completedAt == nil)
        #expect(attempt.mistakeCount == 2)
        #expect(attempt.hintCount == 1)
    }
    
    // MARK: - Query Tests
    @Test func attemptCountForPuzzle() async throws {
        let mockStore = MockProgressStore()
        let manager = PuzzleProgressManager(progressStore: mockStore)
        let puzzle = createTestPuzzle()
        
        // Initially no attempts
        let initialAttempts = manager.attempts(for: puzzle.id, encodingType: "Letters")
        #expect(initialAttempts.count == 0)
        
        // Log some attempts
        manager.logCompletion(puzzle: puzzle, session: createTestSession(isComplete: true), encodingType: "Letters")
        manager.logFailure(puzzle: puzzle, session: createTestSession(), encodingType: "Letters")
        
        let finalAttempts = manager.attempts(for: puzzle.id, encodingType: "Letters")
        #expect(finalAttempts.count == 2)
    }
    
    @Test func attemptCountForDifferentEncodingTypes() async throws {
        let mockStore = MockProgressStore()
        let manager = PuzzleProgressManager(progressStore: mockStore)
        let puzzle = createTestPuzzle()
        
        // Log attempts for different encoding types
        manager.logCompletion(puzzle: puzzle, session: createTestSession(isComplete: true), encodingType: "Letters")
        manager.logFailure(puzzle: puzzle, session: createTestSession(), encodingType: "Numbers")
        
        let lettersCount = manager.attempts(for: puzzle.id, encodingType: "Letters").count
        let numbersCount = manager.attempts(for: puzzle.id, encodingType: "Numbers").count
        
        #expect(lettersCount == 1)
        #expect(numbersCount == 1)
    }
    
    @Test func bestTimeForPuzzle() async throws {
        let mockStore = MockProgressStore()
        let manager = PuzzleProgressManager(progressStore: mockStore)
        let puzzle = createTestPuzzle()
        
        // Initially no best time
        let initialBestTime = manager.bestTime(for: puzzle.id, encodingType: "Letters")
        #expect(initialBestTime == nil)
        
        // Log completions with different times
        manager.logCompletion(puzzle: puzzle, session: createTestSession(isComplete: true, completionTime: 120.0), encodingType: "Letters")
        manager.logCompletion(puzzle: puzzle, session: createTestSession(isComplete: true, completionTime: 90.0), encodingType: "Letters")
        manager.logCompletion(puzzle: puzzle, session: createTestSession(isComplete: true, completionTime: 150.0), encodingType: "Letters")
        
        let bestTime = manager.bestTime(for: puzzle.id, encodingType: "Letters")
        #expect(bestTime == 90.0)
    }
    
    @Test func completionCountForPuzzle() async throws {
        let mockStore = MockProgressStore()
        let manager = PuzzleProgressManager(progressStore: mockStore)
        let puzzle = createTestPuzzle()
        
        // Initially no completions
        let initialCount = manager.completionCount(for: puzzle.id, encodingType: "Letters")
        #expect(initialCount == 0)
        
        // Log some attempts (mix of completions and failures)
        manager.logCompletion(puzzle: puzzle, session: createTestSession(isComplete: true), encodingType: "Letters")
        manager.logFailure(puzzle: puzzle, session: createTestSession(), encodingType: "Letters")
        manager.logCompletion(puzzle: puzzle, session: createTestSession(isComplete: true), encodingType: "Letters")
        
        let finalCount = manager.completionCount(for: puzzle.id, encodingType: "Letters")
        #expect(finalCount == 2)
    }
    
    @Test func allAttemptsRetrieval() async throws {
        let mockStore = MockProgressStore()
        let manager = PuzzleProgressManager(progressStore: mockStore)
        let puzzle1 = createTestPuzzle()
        let puzzle2 = Puzzle(quoteId: 2, encodedText: "XYZ", solution: "CAT", hint: "Animal")
        
        // Log attempts for different puzzles
        manager.logCompletion(puzzle: puzzle1, session: createTestSession(isComplete: true), encodingType: "Letters")
        manager.logFailure(puzzle: puzzle2, session: createTestSession(), encodingType: "Numbers")
        
        let allAttempts = manager.allAttempts()
        #expect(allAttempts.count == 2)
        
        let puzzle1Attempts = allAttempts.filter { $0.puzzleID == puzzle1.id }
        let puzzle2Attempts = allAttempts.filter { $0.puzzleID == puzzle2.id }
        
        #expect(puzzle1Attempts.count == 1)
        #expect(puzzle2Attempts.count == 1)
    }
    
    // MARK: - Error Handling Tests
    @Test func errorHandling() async throws {
        // Create a store that will throw errors
        class ErrorStore: PuzzleProgressStore {
            func logAttempt(_ attempt: PuzzleAttempt) throws {
                throw DatabaseError.connectionFailed
            }
            
            func attempts(for puzzleID: UUID, encodingType: String?) throws -> [PuzzleAttempt] {
                throw DatabaseError.queryFailed("Test error")
            }
            
            func latestAttempt(for puzzleID: UUID, encodingType: String?) throws -> PuzzleAttempt? {
                throw DatabaseError.queryFailed("Test error")
            }
            
            func allAttempts() throws -> [PuzzleAttempt] {
                throw DatabaseError.dataCorrupted("Test error")
            }
            
            func clearAllProgress() throws {
                throw DatabaseError.queryFailed("Test error")
            }
            
            func bestCompletionTime(for puzzleID: UUID, encodingType: String?) throws -> TimeInterval? {
                throw DatabaseError.queryFailed("Test error")
            }
        }
        
        let errorStore = ErrorStore()
        let manager = PuzzleProgressManager(progressStore: errorStore)
        let puzzle = createTestPuzzle()
        let session = createTestSession(isComplete: true)
        
        // Should handle errors gracefully
        manager.logCompletion(puzzle: puzzle, session: session, encodingType: "Letters")
        
        // Error should be set
        #expect(manager.currentError != nil)
        
        // Queries should return safe defaults
        let attempts = manager.attempts(for: puzzle.id, encodingType: "Letters")
        #expect(attempts.count == 0)
        
        let bestTime = manager.bestTime(for: puzzle.id, encodingType: "Letters")
        #expect(bestTime == nil)
    }
    
    // MARK: - Reset Tests
    @Test func resetAllProgress() async throws {
        let mockStore = MockProgressStore()
        let manager = PuzzleProgressManager(progressStore: mockStore)
        let puzzle = createTestPuzzle()
        
        // Log some attempts
        manager.logCompletion(puzzle: puzzle, session: createTestSession(isComplete: true), encodingType: "Letters")
        manager.logFailure(puzzle: puzzle, session: createTestSession(), encodingType: "Letters")
        
        // Verify attempts exist
        #expect(manager.allAttempts().count == 2)
        
        // Reset all progress
        manager.clearAllProgress()
        
        // Should have no attempts
        #expect(manager.allAttempts().count == 0)
    }
}