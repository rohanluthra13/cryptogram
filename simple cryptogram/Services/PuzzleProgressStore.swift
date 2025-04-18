import Foundation

protocol PuzzleProgressStore {
    func logAttempt(_ attempt: PuzzleAttempt)
    func attempts(for puzzleID: UUID, encodingType: String?) -> [PuzzleAttempt]
    func latestAttempt(for puzzleID: UUID, encodingType: String?) -> PuzzleAttempt?
    func bestCompletionTime(for puzzleID: UUID, encodingType: String?) -> TimeInterval?
    func clearAllProgress()
    // New: Fetch all attempts (all puzzles, all encodings)
    func allAttempts() -> [PuzzleAttempt]
}
