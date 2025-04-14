# Cryptogram Difficulty Modes Implementation Plan

This plan outlines the steps to implement "Normal" and "Expert" difficulty modes for the cryptogram puzzle.

- **Expert Mode:** No letters revealed initially (current behavior).
- **Normal Mode:** Reveal a single instance of a percentage (e.g., 20%, min 1) of the unique letters in the solution.

## Phase 1: Settings UI & Persistence

**Goal:** Allow the user to select the difficulty mode and persist their choice.
**Status: Completed**

1.  **Define Difficulty Enum:**
    *   Create a `DifficultyMode` enum with cases `.normal` and `.expert`.
    *   Make it `CaseIterable`, `Identifiable` (for Picker), and give it a `String` raw value (e.g., "normal", "expert") for persistence. Add a computed property for user-friendly display names (e.g., "Normal", "Expert").
    *   *Location:* Create a new file `simple cryptogram/Models/DifficultyMode.swift`.

2.  **Define AppStorage Key & User Settings:**
    *   Create a new file `simple cryptogram/Configuration/UserSettings.swift`.
    *   Inside `UserSettings.swift`, define a struct `UserSettings` (or similar).
    *   Add a static constant `difficultyModeKey = "difficultyMode"`.
    *   Add a static computed property `currentMode` that reads/writes the `DifficultyMode` raw value from/to `@AppStorage(difficultyModeKey)` providing a default (e.g., `.normal`). This will be the helper used by the ViewModel.

3.  **Create Settings View Model:**
    *   *Decision:* Create a dedicated ViewModel for clarity.
    *   Create a new file `simple cryptogram/ViewModels/SettingsViewModel.swift`.
    *   Define an `ObservableObject` class `SettingsViewModel`.
    *   Add a `@Published` property `selectedMode: DifficultyMode`.
    *   In its `init`, read the initial value from `UserSettings.currentMode`.
    *   Use `.sink` on the `$selectedMode` publisher to write changes back to `UserSettings.currentMode`.

4.  **Update Settings UI (`SettingsContentView.swift`):**
    *   Add `@StateObject private var viewModel = SettingsViewModel()` (or inject if preferred).
    *   Add a `Picker` component within a `Section` titled "Difficulty".
    *   Bind the `Picker`'s selection to `viewModel.selectedMode`.
    *   Use `DifficultyMode.allCases` for the `ForEach` loop, displaying the user-friendly names (`mode.displayName`) and using `self` for the tag (due to `Identifiable`).

5.  **Helper for Accessing Mode:**
    *   This is handled by the static `UserSettings.currentMode` property created in Step 2. `PuzzleViewModel` will access this.

## Phase 2: Puzzle Initialization Logic

**Goal:** Modify the puzzle setup process to reveal letters based on the selected difficulty.
**Status: Completed**

1.  **Target File & Function:**
    *   Modify `PuzzleViewModel.swift`.
    *   Specifically, add logic within the `startNewPuzzle(puzzle: Puzzle)` function, *after* the `cells = puzzle.createCells(...)` line.

2.  **Access Difficulty Setting:**
    *   Inside `startNewPuzzle`, read the mode: `let difficulty = UserSettings.currentMode`.

3.  **Conditional Reveal Logic:**
    *   Add `if difficulty == .normal { ... }`.
    *   Inside the `if`:
        *   Get the solution string: `let solution = puzzle.solution.uppercased()`.
        *   Find unique *letters*: `let uniqueLetters = Set(solution.filter { $0.isLetter })`.
        *   Handle empty case: `guard !uniqueLetters.isEmpty else { return }`.
        *   Calculate reveal count:
            *   `let revealPercentage = 0.20` (or make this configurable later).
            *   `let numToReveal = max(1, Int(ceil(Double(uniqueLetters.count) * revealPercentage)))`.
        *   Select letters: `let lettersToReveal = uniqueLetters.shuffled().prefix(numToReveal)`.
        *   Reveal one instance per letter:
            *   Create a temporary mapping `var revealedIndices = Set<Int>()`.
            *   Loop `for letter in lettersToReveal`:
                *   Find all indices in the `cells` array where `cell.solutionChar == letter`: `let matchingIndices = cells.indices.filter { cells[$0].solutionChar == letter }`.
                *   Skip if no matches: `guard !matchingIndices.isEmpty else { continue }`.
                *   Select one random index: `let indexToReveal = matchingIndices.randomElement()!`.
                *   Check if already revealed (unlikely but safe): `guard !revealedIndices.contains(indexToReveal) else { continue }`
                *   Mark the cell in the main `cells` array:
                    *   `cells[indexToReveal].userInput = String(letter)`
                    *   `cells[indexToReveal].isRevealed = true`
                    *   `cells[indexToReveal].isError = false` (ensure no error state)
                *   Track revealed index: `revealedIndices.insert(indexToReveal)`.

4.  **Mark Revealed Cells:**
    *   The existing `CryptogramCell` model in `simple cryptogram/Models/CryptogramCell.swift` already has `isRevealed: Bool`. Step 3 updates this flag directly. No extra state needed.

## Phase 3: Puzzle UI Update

**Goal:** Visually differentiate the pre-revealed cells in Normal mode and prevent user edits.
**Status: Completed**

1.  **Access Revealed State:**
    *   The views `simple cryptogram/Views/Components/PuzzleCell.swift` and `simple cryptogram/Views/Components/WordAwarePuzzleGrid.swift` already use `PuzzleViewModel` which holds the `cells` array containing the `isRevealed` state.

2.  **Modify Cell View (`PuzzleCell.swift`):**
    *   The view already uses `cell.isRevealed` to show a green background rectangle.
    *   The `CryptogramCellStyle` view modifier (in `simple cryptogram/Views/Theme/ViewModifiers.swift`) also uses `isRevealed` to set a green border.
    *   **Decision:** Enhance `PuzzleCell.swift` to also *disable interaction* for revealed cells. Wrap the content inside the `Button` with an `if !cell.isRevealed { ... }` or apply `.disabled(cell.isRevealed)` to the `Button` itself. Review which approach feels better for UX (e.g., should tapping a revealed cell do nothing, or maybe show a small pop-up "This letter was given"? For now, simply disabling seems sufficient).

3.  **Ensure Reset Logic:**
    *   The logic in `startNewPuzzle` (Phase 2) runs every time a new puzzle starts, correctly resetting and recalculating revealed cells based on the current settings.

## Phase 4: Testing

**Goal:** Ensure the feature works correctly.

1.  **Test Expert Mode:** Verify that no letters are revealed when Expert mode is selected.
2.  **Test Normal Mode:**
    *   Start several puzzles in Normal mode.
    *   Verify that *some* letters are revealed.
    *   Count the unique letters in the solution and verify that the correct *number* of unique letters have *one instance* revealed (approximately the target percentage, minimum 1).
    *   Confirm that revealed cells are visually distinct and potentially disabled.
    *   Check edge cases (short quotes, quotes with few unique letters).
3.  **Test Mode Switching:** Change the mode in settings and start a new puzzle to ensure the change takes effect immediately. 