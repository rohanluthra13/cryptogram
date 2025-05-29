import Foundation

@MainActor
class PuzzleSelectionManager: ObservableObject {
    private let databaseService: DatabaseService
    private let progressManager: PuzzleProgressManager
    private let statisticsManager: StatisticsManager
    
    init(
        databaseService: DatabaseService,
        progressManager: PuzzleProgressManager,
        statisticsManager: StatisticsManager
    ) {
        self.databaseService = databaseService
        self.progressManager = progressManager
        self.statisticsManager = statisticsManager
    }
    
    func loadRandomPuzzle(
        encodingType: String,
        difficulties: [String],
        excludeCompleted: Bool = false
    ) async throws -> Puzzle {
        if excludeCompleted {
            return try await loadPuzzleWithExclusions(
                encodingType: encodingType,
                difficulties: difficulties
            )
        } else {
            return try await loadPuzzleWithDifficulty(
                encodingType: encodingType,
                difficulties: difficulties
            )
        }
    }
    
    private func loadPuzzleWithExclusions(
        encodingType: String,
        difficulties: [String]
    ) async throws -> Puzzle {
        let completedPuzzleIds = statisticsManager.getCompletedPuzzleIds(for: encodingType)
        
        // Try up to 10 times to find an uncompleted puzzle
        for _ in 0..<10 {
            if let puzzle = try databaseService.fetchRandomPuzzle(
                encodingType: encodingType,
                selectedDifficulties: difficulties
            ) {
                if !completedPuzzleIds.contains(puzzle.id) {
                    return puzzle
                }
            }
        }
        
        // Fallback: load any random puzzle (even if completed)
        return try await loadPuzzleWithDifficulty(
            encodingType: encodingType,
            difficulties: difficulties
        )
    }
    
    private func loadPuzzleWithDifficulty(
        encodingType: String,
        difficulties: [String]
    ) async throws -> Puzzle {
        if let puzzle = try databaseService.fetchRandomPuzzle(
            encodingType: encodingType,
            selectedDifficulties: difficulties
        ) {
            return puzzle
        } else {
            // Fallback to hardcoded puzzle
            return createFallbackPuzzle()
        }
    }
    
    func createFallbackPuzzle() -> Puzzle {
        return Puzzle(
            id: UUID(),
            quoteId: 0,
            encodedText: "THE QUICK BROWN FOX JUMPS OVER THE LAZY DOG",
            solution: "THE QUICK BROWN FOX JUMPS OVER THE LAZY DOG",
            hint: "A pangram containing every letter of the alphabet",
            author: "Unknown",
            difficulty: "easy",
            length: 43
        )
    }
}