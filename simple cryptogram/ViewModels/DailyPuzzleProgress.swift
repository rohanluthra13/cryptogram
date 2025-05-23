import Foundation

struct DailyPuzzleProgress: Codable {
    let date: String            // e.g. "2025-04-23"
    let quoteId: Int            // Database ID, not UUID
    var userInputs: [String]    // Indexed to match cells
    var hintCount: Int
    var mistakeCount: Int
    var startTime: Date?        // Track session start time
    var endTime: Date?          // Track session end time (if complete)
    var isCompleted: Bool
    var isPreFilled: [Bool]?     // Persist pre-filled state (blue shading)
    var isRevealed: [Bool]?      // Persist revealed-by-hint state (green shading)

    var elapsedTime: TimeInterval? {
        guard let start = startTime else { return nil }
        if let end = endTime { return end.timeIntervalSince(start) }
        return Date().timeIntervalSince(start)
    }
}
