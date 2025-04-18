import Foundation

struct PuzzleAttempt {
    let attemptID: UUID
    let puzzleID: UUID
    let encodingType: String
    let completedAt: Date?
    let failedAt: Date?
    let completionTime: TimeInterval?
    let mode: String
    let hintCount: Int
    let mistakeCount: Int
}
