# Codebase Review Findings

**Date**: 2026-02-12
**Codebase**: Simple Cryptogram (~9,700 lines app code, ~3,600 lines tests)

---

## Project Stats

| Layer | Lines | % of Total |
|-------|-------|------------|
| Views | 5,498 | 56.7% |
| ViewModels | 2,260 | 23.3% |
| Services | 813 | 8.4% |
| Models | 572 | 5.9% |
| Configuration | 424 | 4.4% |
| Utils | 89 | 0.9% |

---

## Strengths

- **No force unwraps** in the ViewModel layer — proper optional handling throughout
- **Comprehensive test suite** — 15 active test files with memory leak detection and performance baselines
- **Clean manager separation** — GameState, Input, Hints, Progress, Daily, Stats each have single responsibilities
- **Modern Swift** — `@Observable`, async/await, `@MainActor`, weak references for retain cycle prevention
- **Typed error handling** — `DatabaseError` with user-friendly messages and recovery suggestions
- **Good dependency injection** in most managers (protocol-based `PuzzleProgressStore`, constructor injection in `HomeViewModel`)

---

## Problems

### P1 — OverlayManager.swift (930 lines)

**Location**: `Views/Components/OverlayManager.swift`

The largest file in the project. Contains two parallel overlay systems (`OverlayManager` and `UnifiedOverlayModifier`) with ~400 lines of duplicated code. Handles seven distinct overlays (pause, game over, stats, settings, calendar, info, completion) all in one file.

The game over overlay also contains a full typing animation implementation with Timer-based state management.

**Impact**: Hardest file to maintain. Changes to any overlay risk breaking others. Duplication means bugs must be fixed in two places.

**Recommendation**: Extract each overlay into its own component. Remove the duplicate `UnifiedOverlayModifier` system. Extract typing animation into a reusable component.

---

### P2 — PuzzleCompletionView.swift (472 lines, 14 @State properties)

**Location**: `Views/Components/PuzzleCompletionView.swift`

Contains business logic that doesn't belong in a view:
- Date formatting (25 lines of date parsing)
- Quote typing animation with Timer
- Author bio typing animation with Task management
- Complex animation sequencing with staggered delays

14 separate `@State` properties manage fragmented animation state (`showQuote`, `showAttribution`, `showStats`, `showNextButton`, `displayedQuote`, `authorIsBold`, `isAuthorVisible`, `typingTimer`, `currentCharacterIndex`, `quoteToType`, `showSummaryLine`, `showBornLine`, `showDiedLine`, `summaryTyped`, `bornTyped`, `diedTyped`).

Timer-based animations are a potential memory leak risk — relies on `onDisappear` which isn't guaranteed.

**Impact**: Difficult to test, difficult to modify animation behavior, potential stability issues.

**Recommendation**: Extract a reusable `TypewriterText` component. Move animation orchestration to a dedicated manager. Consolidate `@State` into a single struct or move to a `CompletionAnimationManager`. Replace Timers with Task-based async/await.

---

### P3 — AppSettings Configuration Sprawl

**Location**: `Configuration/StateManagement/AppSettings.swift` (244 lines)

17 persistent properties each with identical `didSet` boilerplate:
```swift
var encodingType: String = "Letters" {
    didSet { persistence.setValue(encodingType, for: "appSettings.encodingType") }
}
```

Adding a new setting requires edits in 4 places:
1. Property declaration with `didSet`
2. `UserDefaults` struct default value
3. `loadSettings()` method
4. `saveCurrentAsUserDefaults()` method

Transient UI state (`shouldShowCalendarOnReturn`) is mixed in with persistent settings.

**Impact**: Error-prone when adding settings. Easy to forget one of the 4 edit points.

**Recommendation**: Use a PropertyWrapper or metadata-driven approach to eliminate boilerplate. Move transient state to a separate UI state object.

---

### P4 — Inconsistent Persistence Patterns

Multiple approaches to persistence coexist:
- `AppSettings` uses custom `PersistenceStrategy` wrapper
- `DailyPuzzleManager` uses raw `UserDefaults.standard` directly
- `FeatureFlags` uses raw `UserDefaults.standard` directly
- `ContinuousCalendarView` uses raw `UserDefaults.standard` directly

`PersistenceStrategy` also calls the deprecated `defaults.synchronize()`.

**Impact**: No single source of truth for how data is persisted. Hard to audit what's stored where.

**Recommendation**: Consolidate all persistence through `AppSettings.persistence` or a shared persistence service.

---

### P5 — DatabaseService Column Duplication

**Location**: `Services/DatabaseService.swift` (241 lines)

Every query method re-declares the same column expressions:
```swift
let id = Expression<Int64>("id")
let quoteText = Expression<String>("quote_text")
let author = Expression<String>("author")
// ... repeated in every method
```

**Impact**: Maintenance burden. Risk of typos or inconsistency between methods.

**Recommendation**: Extract a `DatabaseSchema` struct with shared column definitions.

---

### P6 — Dead / Stale Code

| Item | Location | Issue |
|------|----------|-------|
| `ErrorRecoveryService` stubs | `Services/ErrorRecoveryService.swift` | Methods return `true` with comments admitting they don't work. `attemptDatabaseReinitialization()` does nothing. Migration recovery always returns `false`. |
| `newNavigation` feature flag | `Utils/FeatureFlags.swift` | Permanently `true`. Adds unnecessary code paths with no value. |
| `SettingsImports.swift` | `Views/Components/Settings/` | Empty file (0 lines) |
| Disabled integration tests | `simple cryptogramTests/` | `PuzzleViewModelIntegrationTests.swift.disabled` — 18K lines |
| `StateManager` protocol | `Configuration/StateManagement/StateManager.swift` | Defined but never implemented |
| Implementation plans in code dir | `data/migrations/*.md` | 6 markdown planning files mixed with SQL migrations |

**Recommendation**: Remove dead code. Either re-enable or delete the disabled tests. Move planning docs out of code directory.

---

### P7 — SettingsViewModel Logic Duplication

**Location**: `ViewModels/SettingsViewModel.swift` (lines 33-111)

`quoteRangeDisplayText` and `quoteLengthDisplayText` contain identical 8-branch if-else trees mapping difficulty combinations to display strings. Same logic written twice.

**Recommendation**: Extract shared helper function.

---

### P8 — Hardcoded Layout Values

~378 occurrences of hardcoded padding, frame sizes, and spacing across Views despite `PuzzleViewConstants` existing. Examples:
- `.padding(.horizontal, 32)`
- `.padding(.bottom, 240)`
- `.frame(height: 150)`

Some hardcoded hex colors appear outside the theme system: `Color(hex: "#9B0303")`, `Color(hex: "#01780F")`.

**Recommendation**: Route all spacing/sizing through `PuzzleViewConstants`. Move all colors to theme/asset catalog.

---

### P9 — Model Layer Concerns

**CryptogramCell** (`Models/CryptogramCell.swift`): Mutable struct with many `var` properties (`userInput`, `isRevealed`, `isError`, `wasJustFilled`, `isPreFilled`). Value semantics + heavy mutation can cause unexpected SwiftUI behavior.

**Puzzle.swift** (287 lines): Cell creation logic for letter and number encodings has significant duplication — both `createLetterEncodedCells()` and `createNumberEncodedCells()` follow the same pattern with minor differences.

**PuzzleSession.swift**: Uses `[String: Any]` for `userInfo` dictionary — type-unsafe, prone to key typos.

---

### P10 — Accessibility Gaps

- Missing accessibility labels on navigation buttons, info overlay buttons, settings toggles
- Color-only state indicators (red X for errors, green checkmarks) with no alternative
- Hardcoded strings not localized
- No VoiceOver descriptions for puzzle grid cells

---

## Cleanup Priority

| Priority | Item | Effort | Impact |
|----------|------|--------|--------|
| High | P1: Split OverlayManager | Medium | High — maintainability |
| High | P2: Extract completion view logic | Medium | High — stability, testability |
| High | P6: Remove dead code | Low | Medium — cognitive load |
| Medium | P4: Consolidate persistence | Medium | Medium — consistency |
| Medium | P7: Fix SettingsViewModel duplication | Low | Low — easy win |
| Medium | P5: DatabaseService schema constants | Low | Low — maintenance |
| Medium | P3: AppSettings boilerplate | Medium | Medium — extensibility |
| Lower | P8: Consolidate hardcoded values | High | Medium — consistency |
| Lower | P9: Model layer cleanup | Medium | Medium — correctness |
| Lower | P10: Accessibility | High | High — user reach |
