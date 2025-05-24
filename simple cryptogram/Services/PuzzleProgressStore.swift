import Foundation

protocol PuzzleProgressStore {
    func logAttempt(_ attempt: PuzzleAttempt) throws
    func attempts(for puzzleID: UUID, encodingType: String?) throws -> [PuzzleAttempt]
    func latestAttempt(for puzzleID: UUID, encodingType: String?) throws -> PuzzleAttempt?
    func bestCompletionTime(for puzzleID: UUID, encodingType: String?) throws -> TimeInterval?
    func clearAllProgress() throws
    // New: Fetch all attempts (all puzzles, all encodings)
    func allAttempts() throws -> [PuzzleAttempt]
}
