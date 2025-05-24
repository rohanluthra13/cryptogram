import Foundation

@MainActor
class StatisticsManager: ObservableObject {
    // MARK: - Dependencies
    private let progressManager: PuzzleProgressManager
    
    // MARK: - Initialization
    init(progressManager: PuzzleProgressManager) {
        self.progressManager = progressManager
    }
    
    // MARK: - Global Statistics
    var totalAttempts: Int {
        progressManager.allAttempts().count
    }
    
    var totalCompletions: Int {
        progressManager.allAttempts().filter { $0.completedAt != nil }.count
    }
    
    var totalFailures: Int {
        progressManager.allAttempts().filter { $0.failedAt != nil }.count
    }
    
    var winRatePercentage: Int {
        let attempts = totalAttempts
        guard attempts > 0 else { return 0 }
        return Int(Double(totalCompletions) / Double(attempts) * 100)
    }
    
    var globalBestTime: TimeInterval? {
        progressManager.allAttempts()
            .compactMap { $0.completionTime }
            .min()
    }
    
    var averageTime: TimeInterval? {
        let times = progressManager.allAttempts().compactMap { $0.completionTime }
        guard !times.isEmpty else { return nil }
        return times.reduce(0, +) / Double(times.count)
    }
    
    // MARK: - Puzzle-Specific Statistics
    func completionCount(for puzzleId: UUID, encodingType: String) -> Int {
        progressManager.completionCount(for: puzzleId, encodingType: encodingType)
    }
    
    func failureCount(for puzzleId: UUID, encodingType: String) -> Int {
        progressManager.failureCount(for: puzzleId, encodingType: encodingType)
    }
    
    func bestTime(for puzzleId: UUID, encodingType: String) -> TimeInterval? {
        progressManager.bestTime(for: puzzleId, encodingType: encodingType)
    }
    
    // MARK: - Utility Methods
    func resetAllStatistics() {
        progressManager.clearAllProgress()
    }
}