import Testing
import Foundation
@testable import simple_cryptogram

@MainActor
struct DailyPuzzleManagerTests {
    
    // MARK: - Test Data
    private func createTestPuzzle() -> Puzzle {
        return Puzzle(
            quoteId: 1,
            encodedText: "ABC DEF",
            solution: "THE DOG",
            hint: "Test daily puzzle"
        )
    }
    
    private func createTestSession() -> PuzzleSession {
        var session = PuzzleSession()
        session.startTime = Foundation.Date()
        session.mistakeCount = 2
        session.hintCount = 1
        return session
    }
    
    private func createTestCells() -> [CryptogramCell] {
        let puzzle = createTestPuzzle()
        var cells: [CryptogramCell] = []
        
        for (index, char) in puzzle.encodedText.enumerated() {
            let solutionChar = puzzle.solution[puzzle.solution.index(puzzle.solution.startIndex, offsetBy: index)]
            let cell = CryptogramCell(
                quoteId: puzzle.quoteId,
                position: index,
                encodedChar: String(char),
                solutionChar: solutionChar,
                isSymbol: !char.isLetter && !char.isNumber
            )
            cells.append(cell)
        }
        
        return cells
    }
    
    // MARK: - Initialization Tests
    @Test func initialization() async throws {
        let manager = DailyPuzzleManager(databaseService: DatabaseService.shared)
        
        #expect(manager != nil)
        #expect(!manager.isDailyPuzzle)
        #expect(!manager.isDailyPuzzleCompletedPublished)
    }
    
    // MARK: - Progress Saving Tests
    @Test func saveDailyPuzzleProgress() async throws {
        let manager = DailyPuzzleManager(databaseService: DatabaseService.shared)
        
        let testPuzzle = createTestPuzzle()
        let testCells = createTestCells()
        let testSession = createTestSession()
        
        // Set as daily puzzle first
        manager.isDailyPuzzle = true
        
        manager.saveDailyPuzzleProgress(puzzle: testPuzzle, cells: testCells, session: testSession)
        
        // Progress should be saved (we can't directly verify UserDefaults in tests,
        // but we can verify the method doesn't crash)
        #expect(manager.isDailyPuzzle) // Should remain true
    }
    
    @Test func saveDailyPuzzleProgressWhenNotDaily() async throws {
        let manager = DailyPuzzleManager(databaseService: DatabaseService.shared)
        
        let testPuzzle = createTestPuzzle()
        let testCells = createTestCells()
        let testSession = createTestSession()
        
        // Not a daily puzzle
        #expect(!manager.isDailyPuzzle)
        
        manager.saveDailyPuzzleProgress(puzzle: testPuzzle, cells: testCells, session: testSession)
        
        // Should handle gracefully (no-op)
        #expect(!manager.isDailyPuzzle)
    }
    
    // MARK: - Progress Restoration Tests
    @Test func restoreDailyProgress() async throws {
        let manager = DailyPuzzleManager(databaseService: DatabaseService.shared)
        
        let testPuzzle = createTestPuzzle()
        var testCells = createTestCells()
        var testSession = createTestSession()
        
        // Create some progress data
        let progressData = DailyPuzzleProgress(
            date: "2025-05-24",
            quoteId: testPuzzle.quoteId,
            userInputs: testCells.map { $0.userInput },
            hintCount: testSession.hintCount,
            mistakeCount: testSession.mistakeCount,
            startTime: testSession.startTime,
            endTime: testSession.endTime,
            isCompleted: testSession.isComplete
        )
        
        // Modify cells and session to be different
        testCells[0].userInput = "X"
        testSession.mistakeCount = 5
        
        // Restore progress
        manager.restoreDailyProgress(to: &testCells, session: &testSession, from: progressData)
        
        // Should restore original values
        #expect(testCells[0].userInput == progressData.userInputs[0])
        #expect(testSession.mistakeCount == progressData.mistakeCount)
    }
    
    // MARK: - Completion Status Tests
    @Test func checkDailyPuzzleCompletedWithNilPuzzle() async throws {
        let manager = DailyPuzzleManager(databaseService: DatabaseService.shared)
        
        let isCompleted = manager.checkDailyPuzzleCompleted(puzzle: nil)
        #expect(!isCompleted)
    }
    
    // MARK: - State Reset Tests
    @Test func resetDailyPuzzleState() async throws {
        let manager = DailyPuzzleManager(databaseService: DatabaseService.shared)
        
        // Set daily puzzle state
        manager.isDailyPuzzle = true
        manager.isDailyPuzzleCompletedPublished = true
        
        manager.resetDailyPuzzleState()
        
        #expect(!manager.isDailyPuzzle)
        #expect(!manager.isDailyPuzzleCompletedPublished)
    }
    
    // MARK: - Edge Cases Tests
    @Test func saveProgressWithEmptyCells() async throws {
        let manager = DailyPuzzleManager(databaseService: DatabaseService.shared)
        
        let testPuzzle = createTestPuzzle()
        let emptyCells: [CryptogramCell] = []
        let testSession = createTestSession()
        
        manager.isDailyPuzzle = true
        
        // Should handle empty cells gracefully
        manager.saveDailyPuzzleProgress(puzzle: testPuzzle, cells: emptyCells, session: testSession)
        
        #expect(manager.isDailyPuzzle) // Should remain true
    }
}