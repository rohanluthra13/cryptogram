import Testing
import Foundation
@testable import simple_cryptogram

/// Regression tests for daily puzzle save bugs (fixed in Phase 1).
/// Bug 1: Stale pendingSaveParams overwriting completion state on app background → fixed by removing debounce
/// Bug 2: loadNextPuzzle calling reset() which saves empty state over completed daily progress → fixed by clearing isDailyPuzzle first
@MainActor
struct DailySaveBugTests {

    // MARK: - Test Helpers

    private func createTestPuzzle(quoteId: Int = 42) -> Puzzle {
        Puzzle(
            quoteId: quoteId,
            encodedText: "BCD EFG",
            solution: "THE DOG",
            hint: "Test Author"
        )
    }

    private func dateString(from date: Date = Date()) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone.current
        return formatter.string(from: date)
    }

    private func dailyProgressKey(for dateStr: String) -> String {
        "dailyPuzzleProgress-\(dateStr)"
    }

    private func cleanupUserDefaults(dateStr: String) {
        UserDefaults.standard.removeObject(forKey: dailyProgressKey(for: dateStr))
    }

    private func readSavedProgress(dateStr: String) -> DailyPuzzleProgress? {
        guard let data = UserDefaults.standard.data(forKey: dailyProgressKey(for: dateStr)) else {
            return nil
        }
        return try? JSONDecoder().decode(DailyPuzzleProgress.self, from: data)
    }

    private func createViewModelForDailyPuzzle() -> PuzzleViewModel {
        let vm = PuzzleViewModel()
        let puzzle = createTestPuzzle()
        vm.startNewPuzzle(puzzle: puzzle, skipAnimationInit: true)
        vm.isDailyPuzzle = true
        return vm
    }

    // MARK: - Bug 1: Background flush must not overwrite completion

    /// After completing a daily puzzle, going to background (flushPendingDailySave)
    /// must not overwrite the completed state.
    @Test func completedDailyPuzzleSurvivesBackgroundFlush() async throws {
        let dateStr = dateString()
        cleanupUserDefaults(dateStr: dateStr)
        defer { cleanupUserDefaults(dateStr: dateStr) }

        let vm = createViewModelForDailyPuzzle()

        // Fill in correct answers
        for i in vm.cells.indices where !vm.cells[i].isSymbol {
            if let sol = vm.cells[i].solutionChar {
                vm.cells[i].userInput = String(sol)
            }
        }
        vm.session.startTime = Date().addingTimeInterval(-60)
        vm.session.endTime = Date()
        vm.session.isComplete = true

        // Save completion
        vm.saveCompletionIfDaily()

        let afterCompletion = readSavedProgress(dateStr: dateStr)
        #expect(afterCompletion?.isCompleted == true, "Completion should be saved")

        // Simulate app going to background
        vm.flushPendingDailySave()

        let afterFlush = readSavedProgress(dateStr: dateStr)
        #expect(afterFlush?.isCompleted == true, "Background flush must not overwrite completion")
    }

    // MARK: - Bug 2: Next puzzle must not overwrite daily completion

    /// After completing a daily puzzle and loading a new random puzzle,
    /// the daily completion must remain in UserDefaults.
    @Test func nextPuzzleAfterDailyCompletionDoesNotOverwrite() async throws {
        let dateStr = dateString()
        cleanupUserDefaults(dateStr: dateStr)
        defer { cleanupUserDefaults(dateStr: dateStr) }

        let vm = createViewModelForDailyPuzzle()

        // Complete the puzzle
        for i in vm.cells.indices where !vm.cells[i].isSymbol {
            if let sol = vm.cells[i].solutionChar {
                vm.cells[i].userInput = String(sol)
            }
        }
        vm.session.startTime = Date().addingTimeInterval(-60)
        vm.session.endTime = Date()
        vm.session.isComplete = true

        // Save completion
        vm.saveCompletionIfDaily()

        let before = readSavedProgress(dateStr: dateStr)
        #expect(before?.isCompleted == true, "Setup: completion should be saved")

        // Simulate "next puzzle" — this clears isDailyPuzzle BEFORE loading
        // In the fixed code, loadNewPuzzle() sets isDailyPuzzle = false first
        vm.isDailyPuzzle = false

        // Now even if we call save, it should be a no-op because isDailyPuzzle is false
        vm.saveDailyProgressIfNeeded()

        let after = readSavedProgress(dateStr: dateStr)
        #expect(after?.isCompleted == true, "Next puzzle must not overwrite daily completion")
        #expect(after?.quoteId == 42, "Daily progress must not be replaced")
    }

    /// Verify that saveDailyProgressIfNeeded is a no-op when isDailyPuzzle is false.
    @Test func saveIsNoOpWhenNotDailyPuzzle() async throws {
        let dateStr = "2099-12-31"
        cleanupUserDefaults(dateStr: dateStr)
        defer { cleanupUserDefaults(dateStr: dateStr) }

        // Write completed progress directly
        let progress = DailyPuzzleProgress(
            date: dateStr,
            quoteId: 42,
            userInputs: ["T", "H", "E", " ", "D", "O", "G"],
            hintCount: 0,
            mistakeCount: 0,
            startTime: Date().addingTimeInterval(-60),
            endTime: Date(),
            isCompleted: true,
            isPreFilled: [false, false, false, false, false, false, false],
            isRevealed: [false, false, false, false, false, false, false]
        )
        let data = try JSONEncoder().encode(progress)
        UserDefaults.standard.set(data, forKey: dailyProgressKey(for: dateStr))

        // Create a ViewModel with isDailyPuzzle = false
        let vm = PuzzleViewModel()
        let puzzle = createTestPuzzle()
        vm.startNewPuzzle(puzzle: puzzle, skipAnimationInit: true)
        vm.isDailyPuzzle = false

        // This should be a no-op
        vm.saveDailyProgressIfNeeded()
        vm.flushPendingDailySave()

        // Verify original data is untouched
        let after = readSavedProgress(dateStr: dateStr)
        #expect(after?.isCompleted == true, "Non-daily save must not touch daily progress")
    }
}
