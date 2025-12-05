# Simple Cryptogram - Modernization Plan

**Goal:** Transform into a modern, best-practice Swift app with efficient, simple code.

**Current State:** ~70 Swift files | ~7,500 lines | 16 test files

---

## Phase 1: Performance Fixes (Critical) ✅ COMPLETE

### 1.1 Fix Repeated Database Queries
**File:** `ViewModels/Progress/StatisticsManager.swift`

**Problem:** `allAttempts()` called 6 times separately for different computed properties, each hitting the database.

**Fix:** Cache attempts and derive all stats from single fetch:
```swift
private var cachedAttempts: [PuzzleAttempt]?
private var cacheTimestamp: Date?

private func getAttempts() -> [PuzzleAttempt] {
    if let cached = cachedAttempts,
       let timestamp = cacheTimestamp,
       Date().timeIntervalSince(timestamp) < 1.0 {
        return cached
    }
    let attempts = (try? progressManager.allAttempts()) ?? []
    cachedAttempts = attempts
    cacheTimestamp = Date()
    return attempts
}
```

---

### 1.2 Fix O(n*m) Completed Letters Loop
**File:** `ViewModels/GameState/GameStateManager.swift:295-309`

**Problem:** For each unique letter, filters entire cells array again.

**Fix:** Single-pass algorithm:
```swift
func updateCompletedLetters() {
    var letterHasEmpty: [String: Bool] = [:]

    for cell in cells where !cell.isSymbol {
        let letter = cell.encodedChar
        if letterHasEmpty[letter] == nil {
            letterHasEmpty[letter] = cell.userInput.isEmpty
        } else if cell.userInput.isEmpty {
            letterHasEmpty[letter] = true
        }
    }

    completedLetters = Set(letterHasEmpty.filter { !$0.value }.keys)
}
```

---

### 1.3 Fix Keyboard Performance
**File:** `Views/KeyboardView.swift:66-89`

**Problem:** Each of 26 keyboard keys filters entire cells array multiple times per render.

**Fix:** Pre-compute mapping in ViewModel once when cells change:
```swift
// In GameStateManager or PuzzleViewModel
var solutionToEncodedMap: [Character: Set<String>] = [:]

func updateKeyboardMapping() {
    var map: [Character: Set<String>] = [:]
    for cell in cells where !cell.isSymbol {
        if let solution = cell.solutionChar {
            map[solution, default: []].insert(cell.encodedChar)
        }
    }
    solutionToEncodedMap = map
}
```

---

### 1.4 Debounce Daily Progress Saves
**File:** `ViewModels/Daily/DailyPuzzleManager.swift:51-80`

**Problem:** JSON encodes and saves all cells to UserDefaults on every keystroke.

**Fix:** Debounce saves with 1-second delay:
```swift
private var saveTask: Task<Void, Never>?

func saveDailyPuzzleProgress(...) {
    saveTask?.cancel()
    saveTask = Task {
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        guard !Task.isCancelled else { return }
        performSave(...)
    }
}
```

---

### 1.5 Reduce Timer Frequency
**File:** `Views/Components/StatsView.swift:25`

**Problem:** Timer updates every 0.25 seconds unconditionally.

**Fix:** Use 1-second interval and skip when paused:
```swift
.onReceive(Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()) { _ in
    guard !isPaused else { return }
    updateDisplayTime()
}
```

---

## Phase 2: Delete Dead Code ✅ COMPLETE

| File | Reason | Status |
|------|--------|--------|
| `Configuration/UserSettings.swift` | Legacy forwarding layer | ✅ Deleted |
| `Views/Components/NavigationBarView.swift.backup` | Backup file in source control | ✅ Deleted |
| `Views/Components/CalendarView.swift` | Unused (ContinuousCalendarView is used) | ✅ Deleted |

---

## Phase 3: Consolidate Duplicates (Partially Complete)

### 3.1 Extract Time Formatting Utility ✅ COMPLETE
**Files:** `UserStatsView.swift`, `CompletionStatsView.swift`, `StatsView.swift`

**Done:** Created `Utils/TimeInterval+Formatting.swift` with two extensions:
- `.formattedAsMinutesSeconds` → "02:45"
- `.formattedAsShortMinutesSeconds` → "2:45"

---

### 3.2 Unify Calendar Views ⏭️ SKIPPED
**Reason:** CalendarView.swift was unused dead code (deleted in Phase 2). Only ContinuousCalendarView is used.

---

### 3.3 Extract Typewriter Animation ⏭️ SKIPPED
**Reason:** After analysis, InfoPanel and PuzzleUIViewModel have different timing, completion handling, and state management. Extracting would add complexity without significant benefit.

---

### 3.4 Consolidate Stats Display Components ⏭️ SKIPPED
**Reason:** StatsView (gameplay), UserStatsView (overall stats), and CompletionStatsView (post-game) serve different purposes with minimal shared code beyond time formatting (already extracted in 3.1).

---

## Phase 4: Modernize to @Observable (iOS 17+) ✅ COMPLETE

### Files Converted (12 ViewModels):

| File | Current | Target |
|------|---------|--------|
| `PuzzleViewModel.swift` | `ObservableObject` + `@Published` | `@Observable` |
| `GameStateManager.swift` | `ObservableObject` + `@Published` | `@Observable` |
| `InputHandler.swift` | `ObservableObject` | `@Observable` |
| `HintManager.swift` | `ObservableObject` | `@Observable` |
| `PuzzleProgressManager.swift` | `ObservableObject` + `@Published` | `@Observable` |
| `StatisticsManager.swift` | `ObservableObject` | `@Observable` |
| `DailyPuzzleManager.swift` | `ObservableObject` + `@Published` | `@Observable` |
| `NavigationCoordinator.swift` | `ObservableObject` + `@Published` | `@Observable` |
| `ThemeManager.swift` | `ObservableObject` + `@Published` | `@Observable` |
| `SettingsViewModel.swift` | `ObservableObject` + `@Published` | `@Observable` |

### Conversion Pattern:
```swift
// Before
class GameStateManager: ObservableObject {
    @Published var cells: [CryptogramCell] = []
    @Published var session: PuzzleSession
}

// After
@Observable
final class GameStateManager {
    var cells: [CryptogramCell] = []
    var session: PuzzleSession
}
```

### View Updates Required:
- Replace `@ObservedObject` with `@Bindable` or remove entirely
- Replace `@EnvironmentObject` with `@Environment` for @Observable types
- Remove manual `objectWillChange.send()` calls (9 locations in GameStateManager)

---

## Phase 5: Replace DispatchQueue with async/await ✅ COMPLETE

### Locations Updated (~22 replacements):

| File | Line(s) | Current | Replacement |
|------|---------|---------|-------------|
| `HomeView.swift` | 161 | `DispatchQueue.main.asyncAfter` | `Task.sleep` |
| `PuzzleViewState.swift` | 70, 84 | `DispatchQueue.main.asyncAfter` | `Task.sleep` |
| `InputHandler.swift` | 22, 57, 69, 80 | `DispatchQueue` | `Task.sleep` |
| `OverlayManager.swift` | 571, 621, 640 | `DispatchQueue.main.asyncAfter` | `Task.sleep` |
| `PuzzleCompletionView.swift` | 60, 72 | `DispatchQueue` | `Task.sleep` |
| `GameStateManager.swift` | 205-207, 241-243 | Delayed state changes | Animation delays in View |

### Pattern:
```swift
// Before
private var workItem: DispatchWorkItem?
func showTemporarily() {
    workItem?.cancel()
    let item = DispatchWorkItem { self.isVisible = false }
    workItem = item
    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0, execute: item)
}

// After
private var hideTask: Task<Void, Never>?
func showTemporarily() {
    hideTask?.cancel()
    hideTask = Task {
        try? await Task.sleep(for: .seconds(3))
        withAnimation { isVisible = false }
    }
}
```

---

## Phase 6: Replace Completion Handlers with async/await ✅ COMPLETE

| File | Function | Status |
|------|----------|--------|
| `PuzzleViewState.swift` | `animatePuzzleSwitch(completion:)` → `animatePuzzleSwitch() async` | ✅ |
| `OverlayManager.swift` | `dismiss(completion:)` → `dismiss() async` | ✅ |
| `PuzzleCompletionView.swift` | `typeLine(..., completion:)` → `typeLine(...) async` | ✅ |

---

## Phase 7: Minor API Updates (Partially Complete)

### 7.1 Replace Deprecated APIs ✅ COMPLETE
```swift
// Before
.edgesIgnoringSafeArea(.all)

// After
.ignoresSafeArea()
```

**Updated:** `OverlayManager.swift` (2 locations), `PuzzleCompletionView.swift` (1 location)

### 7.2 Replace NotificationCenter with Direct Bindings ⏭️ DEFERRED
**Files:** `PuzzleViewModel.swift:166-179`, `SettingsViewModel.swift:23`

**Reason:** The current NotificationCenter pattern works correctly with @Observable and is not deprecated. Changing it would require architectural modifications with minimal benefit. The pattern is used only for difficulty selection changes between ViewModels.

---

## Phase 8: Architecture Improvements (Optional)

### 8.1 Dependency Injection
- Replace `AppSettings.shared` access with constructor injection
- Create service protocols (`DatabaseServiceProtocol`, etc.)
- Inject dependencies into ViewModels

### 8.2 Reduce @EnvironmentObject Usage
- `OverlayManager.swift` uses 7+ @EnvironmentObjects
- Create view-specific data structs instead

### 8.3 Split PuzzleViewModel
- Currently 373 lines orchestrating 8 managers
- Consider: `GameCoordinator`, `PuzzleLoadingCoordinator`, `ProgressCoordinator`

### 8.4 Consolidate UI State
- Move animation state from `GameStateManager` to `PuzzleViewState`
- Single source of truth for UI presentation

---

## Summary

| Phase | Status | Impact |
|-------|--------|--------|
| 1. Performance Fixes | ✅ Complete | High - fixes lag/battery issues |
| 2. Delete Dead Code | ✅ Complete | Low - cleanup |
| 3. Consolidate Duplicates | ✅ Complete (3.1 done, 3.2-3.4 skipped after analysis) | Medium - maintainability |
| 4. @Observable Migration | ✅ Complete | High - modern Swift |
| 5. async/await Migration | ✅ Complete | Medium - cleaner code |
| 6. Completion → async | ✅ Complete | Low - cleaner code |
| 7. Minor API Updates | ✅ Partial (7.1 done, 7.2 deferred) | Low - future-proofing |
| 8. Architecture | Optional | High - testability/maintainability |

**Modernization Complete!** Only Phase 8 (optional architecture improvements) remains.
