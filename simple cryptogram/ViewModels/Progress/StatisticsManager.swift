import Foundation
import Observation

@MainActor
@Observable
final class StatisticsManager {
    // MARK: - Dependencies
    private let progressManager: PuzzleProgressManager

    // MARK: - Caching
    private var cachedAttempts: [PuzzleAttempt]?
    private var cacheTimestamp: Date?
    private let cacheDuration: TimeInterval = 1.0

    private func getCachedAttempts() -> [PuzzleAttempt] {
        if let cached = cachedAttempts,
           let timestamp = cacheTimestamp,
           Date().timeIntervalSince(timestamp) < cacheDuration {
            return cached
        }
        let attempts = progressManager.allAttempts()
        cachedAttempts = attempts
        cacheTimestamp = Date()
        return attempts
    }

    func invalidateCache() {
        cachedAttempts = nil
        cacheTimestamp = nil
    }

    // MARK: - Initialization
    init(progressManager: PuzzleProgressManager) {
        self.progressManager = progressManager
    }

    // MARK: - Global Statistics
    var totalAttempts: Int {
        getCachedAttempts().count
    }

    var totalCompletions: Int {
        getCachedAttempts().filter { $0.completedAt != nil }.count
    }

    var totalFailures: Int {
        getCachedAttempts().filter { $0.failedAt != nil }.count
    }

    var winRatePercentage: Int {
        let attempts = getCachedAttempts()
        guard !attempts.isEmpty else { return 0 }
        let completions = attempts.filter { $0.completedAt != nil }.count
        return Int(Double(completions) / Double(attempts.count) * 100)
    }

    var globalBestTime: TimeInterval? {
        getCachedAttempts()
            .compactMap { $0.completionTime }
            .min()
    }

    var averageTime: TimeInterval? {
        let times = getCachedAttempts().compactMap { $0.completionTime }
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
    
    func getCompletedPuzzleIds(for encodingType: String) -> Set<UUID> {
        return Set(getCachedAttempts()
            .filter { $0.encodingType == encodingType && $0.completedAt != nil }
            .map { $0.puzzleID })
    }
}