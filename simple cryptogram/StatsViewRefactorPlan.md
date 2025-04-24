# StatsView Refactor: Phased Implementation Plan

This document outlines a phased, production-grade plan for refactoring the stats bar in the Cryptogram app. The goal is to unify all top-bar stats/icons (mistakes, hints, timer, daily puzzle, question/help) into a single, reusable `StatsView` component, replacing the manual layout currently in `PuzzleView`. The plan is designed for a context window of 8k tokens, with enough detail for a senior developer to execute safely.

---

## **Overview of Current State**
- **PuzzleView**: Manually assembles the top bar using `MistakesView`, `HintsView`, `TimerView`, a calendar (daily puzzle) icon, and a question (help) icon.
- **StatsView**: Exists, but does not encapsulate all top-bar icons or logic.
- **Theming**: Managed via `CryptogramTheme` and `ThemeManager`.
- **PuzzleViewModel**: Provides all state and actions needed for the stats bar.

---

## **Phased Refactor Plan**

### **Phase 1: Expand and Isolate StatsView**
1. **Design and Implement the New StatsView API**
   - Accept all relevant state and actions as parameters:
     - `mistakeCount`, `maxMistakes`, `hintCount`, `maxHints`, `startTime`, `isPaused`
     - `onRequestHint`, `onDailyPuzzle`, `onHelp`
   - Example signature:
     ```swift
     struct StatsView: View {
         let mistakeCount: Int
         let maxMistakes: Int
         let hintCount: Int
         let maxHints: Int
         let startTime: Date
         let isPaused: Bool
         let onRequestHint: () -> Void
         let onDailyPuzzle: () -> Void
         let onHelp: () -> Void
     }
     ```
2. **Move Icon Layout/Logic into StatsView**
   - Layout: Single row (or two rows if preferred) with all icons.
   - Use `CryptogramTheme` for colors, fonts, etc.
   - Add accessibility labels for all icons.
   - Ensure all icons are always visible and state-driven.
3. **Add Comprehensive Previews**
   - Showcase all possible states (e.g., max mistakes, hints used, timer running/paused, etc.).
   - Preview in both light and dark mode.
4. **Do Not Change PuzzleView Yet**
   - The old manual top bar remains in use for now.

---

### **Phase 2: Integrate in Parallel**
1. **Render Both Old and New Bars in PuzzleView (Temporarily)**
   - Use a debug flag, environment variable, or preview to show both bars for comparison.
   - Example:
     ```swift
     #if DEBUG
     VStack {
         StatsView(...)
         // Old manual bar
     }
     #else
     StatsView(...)
     #endif
     ```
2. **Test the New StatsView in Context**
   - Ensure all actions (hint, daily puzzle, help) work as expected.
   - Compare visual and functional parity with the old bar.
   - Adjust layout, spacing, or icon logic as needed.

---

### **Phase 3: Swap and Clean Up**
1. **Replace the Old Manual Top Bar**
   - Remove the manual assembly of stats icons in `PuzzleView`.
   - Use only the new `StatsView`.
2. **Remove Redundant Code**
   - Delete any now-unused UI code or helper functions.
   - Update documentation and comments.

---

### **Phase 4: Final QA and Polish**
1. **Comprehensive Testing**
   - Test all icon actions (including edge cases).
   - Verify appearance in all supported themes and accessibility settings.
   - Test on all supported device sizes.
2. **Solicit Feedback**
   - If working in a team, request code review and user feedback.
3. **Finalize and Ship**
   - Merge the refactor to main.
   - Monitor for regressions or user-reported issues.

---

## **Additional Notes**
- **Theming:** All icon colors, backgrounds, and fonts should use `CryptogramTheme` for consistency.
- **Accessibility:** Each icon/button must have a descriptive `.accessibilityLabel`.
- **Extensibility:** If new stats/icons are needed in the future, add them only to `StatsView`.
- **Testing:** Use SwiftUI previews and, if possible, unit/UI tests for the stats bar.

---

## **Example: New StatsView Usage in PuzzleView**
```swift
StatsView(
    mistakeCount: viewModel.mistakeCount,
    maxMistakes: 3,
    hintCount: viewModel.hintCount,
    maxHints: viewModel.nonSymbolCells.count / 4,
    startTime: viewModel.startTime ?? Date(),
    isPaused: viewModel.isPaused,
    onRequestHint: { viewModel.revealCell() },
    onDailyPuzzle: { viewModel.loadDailyPuzzle() },
    onHelp: { /* Show help sheet or FAQ */ }
)
```

---

## **Checklist for Each Phase**
- [ ] StatsView API matches all required state/actions
- [ ] All icons present and styled per theme
- [ ] Accessibility labels set for all icons
- [ ] Previews cover all major states
- [ ] Manual bar and StatsView can be rendered side-by-side (Phase 2)
- [ ] All actions work as expected in context
- [ ] Old code removed after swap (Phase 3)
- [ ] Thorough QA and device/theme testing completed

---

**This document should be updated as the refactor progresses.**
