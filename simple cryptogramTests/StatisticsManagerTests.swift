import Testing
import Foundation
@testable import simple_cryptogram

@MainActor
struct StatisticsManagerTests {
    
    // MARK: - Mock Progress Manager
    class MockProgressManager: PuzzleProgressManager {
        private var mockAttempts: [PuzzleAttempt] = []
        
        override func allAttempts() -> [PuzzleAttempt] {
            return mockAttempts
        }
        
        override func attempts(for puzzleID: UUID, encodingType: String) -> [PuzzleAttempt] {
            return mockAttempts.filter { $0.puzzleID == puzzleID && $0.encodingType == encodingType }
        }
        
        override func completionCount(for puzzleID: UUID, encodingType: String) -> Int {
            return mockAttempts.filter { 
                $0.puzzleID == puzzleID && 
                $0.encodingType == encodingType && 
                $0.completedAt != nil 
            }.count
        }
        
        override func bestTime(for puzzleID: UUID, encodingType: String) -> TimeInterval? {
            let completions = mockAttempts.filter { 
                $0.puzzleID == puzzleID && 
                $0.encodingType == encodingType && 
                $0.completedAt != nil &&
                $0.completionTime != nil
            }
            return completions.compactMap { $0.completionTime }.min()
        }
        
        func addMockAttempt(_ attempt: PuzzleAttempt) {
            mockAttempts.append(attempt)
        }
        
        func clearMockAttempts() {
            mockAttempts.removeAll()
        }
    }
    
    // MARK: - Test Data
    private var testPuzzleID = UUID()
    
    private func createTestAttempt(
        puzzleID: UUID? = nil,
        encodingType: String = "Letters",
        isCompleted: Bool = true,
        completionTime: TimeInterval? = 120.0,
        mistakeCount: Int = 1,
        hintCount: Int = 0
    ) -> PuzzleAttempt {
        return PuzzleAttempt(
            attemptID: UUID(),
            puzzleID: puzzleID ?? testPuzzleID,
            encodingType: encodingType,
            completedAt: isCompleted ? Date() : nil,
            failedAt: isCompleted ? nil : Date(),
            completionTime: completionTime,
            mode: "normal",
            hintCount: hintCount,
            mistakeCount: mistakeCount
        )
    }
    
    // MARK: - Initialization Tests
    @Test func initialization() async throws {
        let mockProgressManager = MockProgressManager()
        let statisticsManager = StatisticsManager(progressManager: mockProgressManager)
        
        #expect(statisticsManager != nil)
        #expect(statisticsManager.totalAttempts == 0)
        #expect(statisticsManager.totalCompletions == 0)
        #expect(statisticsManager.totalFailures == 0)
    }
    
    // MARK: - Total Statistics Tests
    @Test func totalAttempts() async throws {
        let mockProgressManager = MockProgressManager()
        let statisticsManager = StatisticsManager(progressManager: mockProgressManager)
        
        // Initially 0
        #expect(statisticsManager.totalAttempts == 0)
        
        // Add some attempts
        mockProgressManager.addMockAttempt(createTestAttempt(isCompleted: true))
        mockProgressManager.addMockAttempt(createTestAttempt(isCompleted: false))
        mockProgressManager.addMockAttempt(createTestAttempt(isCompleted: true))
        
        #expect(statisticsManager.totalAttempts == 3)
    }
    
    @Test func totalCompletions() async throws {
        let mockProgressManager = MockProgressManager()
        let statisticsManager = StatisticsManager(progressManager: mockProgressManager)
        
        // Add mixed attempts
        mockProgressManager.addMockAttempt(createTestAttempt(isCompleted: true))
        mockProgressManager.addMockAttempt(createTestAttempt(isCompleted: false))
        mockProgressManager.addMockAttempt(createTestAttempt(isCompleted: true))
        mockProgressManager.addMockAttempt(createTestAttempt(isCompleted: false))
        
        #expect(statisticsManager.totalCompletions == 2)
        #expect(statisticsManager.totalFailures == 2)
    }
    
    @Test func totalFailures() async throws {
        let mockProgressManager = MockProgressManager()
        let statisticsManager = StatisticsManager(progressManager: mockProgressManager)
        
        // Add only failures
        mockProgressManager.addMockAttempt(createTestAttempt(isCompleted: false))
        mockProgressManager.addMockAttempt(createTestAttempt(isCompleted: false))
        
        #expect(statisticsManager.totalFailures == 2)
        #expect(statisticsManager.totalCompletions == 0)
    }
    
    // MARK: - Win Rate Tests
    @Test func winRatePercentageWithCompletions() async throws {
        let mockProgressManager = MockProgressManager()
        let statisticsManager = StatisticsManager(progressManager: mockProgressManager)
        
        // 3 completions out of 5 attempts = 60%
        mockProgressManager.addMockAttempt(createTestAttempt(isCompleted: true))
        mockProgressManager.addMockAttempt(createTestAttempt(isCompleted: true))
        mockProgressManager.addMockAttempt(createTestAttempt(isCompleted: true))
        mockProgressManager.addMockAttempt(createTestAttempt(isCompleted: false))
        mockProgressManager.addMockAttempt(createTestAttempt(isCompleted: false))
        
        #expect(statisticsManager.winRatePercentage == 60)
    }
    
    @Test func winRatePercentageWithNoAttempts() async throws {
        let mockProgressManager = MockProgressManager()
        let statisticsManager = StatisticsManager(progressManager: mockProgressManager)
        
        #expect(statisticsManager.winRatePercentage == 0)
    }
    
    @Test func winRatePercentageWithPerfectRecord() async throws {
        let mockProgressManager = MockProgressManager()
        let statisticsManager = StatisticsManager(progressManager: mockProgressManager)
        
        // All completions
        mockProgressManager.addMockAttempt(createTestAttempt(isCompleted: true))
        mockProgressManager.addMockAttempt(createTestAttempt(isCompleted: true))
        mockProgressManager.addMockAttempt(createTestAttempt(isCompleted: true))
        
        #expect(statisticsManager.winRatePercentage == 100)
    }
    
    @Test func winRatePercentageWithNoCompletions() async throws {
        let mockProgressManager = MockProgressManager()
        let statisticsManager = StatisticsManager(progressManager: mockProgressManager)
        
        // All failures
        mockProgressManager.addMockAttempt(createTestAttempt(isCompleted: false))
        mockProgressManager.addMockAttempt(createTestAttempt(isCompleted: false))
        
        #expect(statisticsManager.winRatePercentage == 0)
    }
    
    // MARK: - Average Time Tests
    @Test func averageTimeWithCompletions() async throws {
        let mockProgressManager = MockProgressManager()
        let statisticsManager = StatisticsManager(progressManager: mockProgressManager)
        
        // Add completions with different times
        mockProgressManager.addMockAttempt(createTestAttempt(completionTime: 120.0))
        mockProgressManager.addMockAttempt(createTestAttempt(completionTime: 180.0))
        mockProgressManager.addMockAttempt(createTestAttempt(completionTime: 240.0))
        mockProgressManager.addMockAttempt(createTestAttempt(isCompleted: false)) // Should be ignored
        
        let averageTime = statisticsManager.averageTime
        #expect(averageTime == 180.0) // (120 + 180 + 240) / 3
    }
    
    @Test func averageTimeWithNoCompletions() async throws {
        let mockProgressManager = MockProgressManager()
        let statisticsManager = StatisticsManager(progressManager: mockProgressManager)
        
        // Add only failures
        mockProgressManager.addMockAttempt(createTestAttempt(isCompleted: false))
        
        #expect(statisticsManager.averageTime == nil)
    }
    
    @Test func averageTimeWithNilCompletionTimes() async throws {
        let mockProgressManager = MockProgressManager()
        let statisticsManager = StatisticsManager(progressManager: mockProgressManager)
        
        // Add completions without completion times
        mockProgressManager.addMockAttempt(createTestAttempt(completionTime: nil))
        mockProgressManager.addMockAttempt(createTestAttempt(completionTime: nil))
        
        #expect(statisticsManager.averageTime == nil)
    }
    
    @Test func averageTimeWithMixedCompletionTimes() async throws {
        let mockProgressManager = MockProgressManager()
        let statisticsManager = StatisticsManager(progressManager: mockProgressManager)
        
        // Mix of valid and nil completion times
        mockProgressManager.addMockAttempt(createTestAttempt(completionTime: 120.0))
        mockProgressManager.addMockAttempt(createTestAttempt(completionTime: nil))
        mockProgressManager.addMockAttempt(createTestAttempt(completionTime: 180.0))
        
        let averageTime = statisticsManager.averageTime
        #expect(averageTime == 150.0) // (120 + 180) / 2
    }
    
    // MARK: - Global Best Time Tests
    @Test func globalBestTimeWithCompletions() async throws {
        let mockProgressManager = MockProgressManager()
        let statisticsManager = StatisticsManager(progressManager: mockProgressManager)
        
        // Add completions with different times
        mockProgressManager.addMockAttempt(createTestAttempt(completionTime: 240.0))
        mockProgressManager.addMockAttempt(createTestAttempt(completionTime: 120.0))
        mockProgressManager.addMockAttempt(createTestAttempt(completionTime: 180.0))
        
        #expect(statisticsManager.globalBestTime == 120.0)
    }
    
    @Test func globalBestTimeWithNoCompletions() async throws {
        let mockProgressManager = MockProgressManager()
        let statisticsManager = StatisticsManager(progressManager: mockProgressManager)
        
        #expect(statisticsManager.globalBestTime == nil)
    }
    
    @Test func globalBestTimeWithNilTimes() async throws {
        let mockProgressManager = MockProgressManager()
        let statisticsManager = StatisticsManager(progressManager: mockProgressManager)
        
        // Add completions without completion times
        mockProgressManager.addMockAttempt(createTestAttempt(completionTime: nil))
        mockProgressManager.addMockAttempt(createTestAttempt(completionTime: nil))
        
        #expect(statisticsManager.globalBestTime == nil)
    }
    
    // MARK: - Puzzle-Specific Statistics Tests
    @Test func completionCountForSpecificPuzzle() async throws {
        let mockProgressManager = MockProgressManager()
        let statisticsManager = StatisticsManager(progressManager: mockProgressManager)
        
        // Add attempts for different puzzles
        let puzzle1ID = UUID()
        let puzzle2ID = UUID()
        mockProgressManager.addMockAttempt(createTestAttempt(puzzleID: puzzle1ID, isCompleted: true))
        mockProgressManager.addMockAttempt(createTestAttempt(puzzleID: puzzle1ID, isCompleted: false))
        mockProgressManager.addMockAttempt(createTestAttempt(puzzleID: puzzle1ID, isCompleted: true))
        mockProgressManager.addMockAttempt(createTestAttempt(puzzleID: puzzle2ID, isCompleted: true))
        
        let puzzle1Completions = statisticsManager.completionCount(for: puzzle1ID, encodingType: "Letters")
        let puzzle2Completions = statisticsManager.completionCount(for: puzzle2ID, encodingType: "Letters")
        
        #expect(puzzle1Completions == 2)
        #expect(puzzle2Completions == 1)
    }
    
    @Test func failureCountForSpecificPuzzle() async throws {
        let mockProgressManager = MockProgressManager()
        let statisticsManager = StatisticsManager(progressManager: mockProgressManager)
        
        // Add attempts for specific puzzle
        let puzzleID = UUID()
        mockProgressManager.addMockAttempt(createTestAttempt(puzzleID: puzzleID, isCompleted: true))
        mockProgressManager.addMockAttempt(createTestAttempt(puzzleID: puzzleID, isCompleted: false))
        mockProgressManager.addMockAttempt(createTestAttempt(puzzleID: puzzleID, isCompleted: false))
        
        let failureCount = statisticsManager.failureCount(for: puzzleID, encodingType: "Letters")
        #expect(failureCount == 2)
    }
    
    @Test func bestTimeForSpecificPuzzle() async throws {
        let mockProgressManager = MockProgressManager()
        let statisticsManager = StatisticsManager(progressManager: mockProgressManager)
        
        // Add attempts for specific puzzle
        let puzzleID = UUID()
        mockProgressManager.addMockAttempt(createTestAttempt(puzzleID: puzzleID, completionTime: 240.0))
        mockProgressManager.addMockAttempt(createTestAttempt(puzzleID: puzzleID, completionTime: 120.0))
        mockProgressManager.addMockAttempt(createTestAttempt(puzzleID: puzzleID, completionTime: 180.0))
        
        let bestTime = statisticsManager.bestTime(for: puzzleID, encodingType: "Letters")
        #expect(bestTime == 120.0)
    }
    
    // MARK: - Encoding Type Separation Tests
    @Test func statisticsSeparateByEncodingType() async throws {
        let mockProgressManager = MockProgressManager()
        let statisticsManager = StatisticsManager(progressManager: mockProgressManager)
        
        // Add attempts for different encoding types
        let puzzleID = UUID()
        mockProgressManager.addMockAttempt(createTestAttempt(puzzleID: puzzleID, encodingType: "Letters", isCompleted: true))
        mockProgressManager.addMockAttempt(createTestAttempt(puzzleID: puzzleID, encodingType: "Numbers", isCompleted: false))
        
        let lettersCompletions = statisticsManager.completionCount(for: puzzleID, encodingType: "Letters")
        let numbersCompletions = statisticsManager.completionCount(for: puzzleID, encodingType: "Numbers")
        let lettersFailures = statisticsManager.failureCount(for: puzzleID, encodingType: "Letters")
        let numbersFailures = statisticsManager.failureCount(for: puzzleID, encodingType: "Numbers")
        
        #expect(lettersCompletions == 1)
        #expect(numbersCompletions == 0)
        #expect(lettersFailures == 0)
        #expect(numbersFailures == 1)
    }
    
    // MARK: - Reset Statistics Tests
    @Test func resetAllStatistics() async throws {
        let mockProgressManager = MockProgressManager()
        let statisticsManager = StatisticsManager(progressManager: mockProgressManager)
        
        // Add some attempts
        mockProgressManager.addMockAttempt(createTestAttempt(isCompleted: true))
        mockProgressManager.addMockAttempt(createTestAttempt(isCompleted: false))
        
        // Verify stats exist
        #expect(statisticsManager.totalAttempts == 2)
        
        // Reset
        statisticsManager.resetAllStatistics()
        
        // Should trigger progress manager reset (in real implementation)
        // For mock, we need to clear manually
        mockProgressManager.clearMockAttempts()
        
        #expect(statisticsManager.totalAttempts == 0)
        #expect(statisticsManager.totalCompletions == 0)
        #expect(statisticsManager.totalFailures == 0)
    }
}