# Simple Cryptogram - Modernization Plan

**Goal:** Transform into a modern, best-practice Swift app with efficient, simple code.

**Current State:** 77 Swift files | ~9,800 lines | 16 test files

---

## Phase 1: Performance Fixes (Critical)

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

## Phase 2: Delete Dead Code

| File | Reason |
|------|--------|
| `Configuration/UserSettings.swift` | Legacy forwarding layer, marked TODO for deletion |
| `Views/Components/NavigationBarView.swift.backup` | Backup file in source control |

---

## Phase 3: Consolidate Duplicates

### 3.1 Extract Time Formatting Utility
**Files:** `UserStatsView.swift:67-71`, `CompletionStatsView.swift:93-97`

**Fix:** Create shared extension:
```swift
// Utils/TimeInterval+Formatting.swift
extension TimeInterval {
    var formattedAsMinutesSeconds: String {
        let minutes = Int(self) / 60
        let seconds = Int(self) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
```

---

### 3.2 Unify Calendar Views
**Files:** `CalendarView.swift`, `ContinuousCalendarView.swift`

**Fix:** Create single `DailyCalendarView` with mode parameter:
```swift
enum CalendarMode {
    case singleMonth
    case continuous
}

struct DailyCalendarView: View {
    let mode: CalendarMode
    // Shared logic here
}
```

---

### 3.3 Extract Typewriter Animation
**Files:** `InfoPanel.swift:62-82`, `PuzzleUIViewModel.swift:75-124`

**Fix:** Create reusable component:
```swift
struct TypewriterText: View {
    let fullText: String
    let characterDelay: TimeInterval
    @State private var displayedText = ""
    // Animation logic here
}
```

---

### 3.4 Consolidate Stats Display Components
**Files:** `StatsView.swift`, `UserStatsView.swift`, `CompletionStatsView.swift`

**Fix:** Create shared stat display components:
```swift
struct StatItem: View {
    let icon: String
    let value: String
    let label: String?
}
```

---

## Phase 4: Modernize to @Observable (iOS 17+)

### Files to Convert (10 ViewModels):

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

## Phase 5: Replace DispatchQueue with async/await

### Locations to Update:

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

## Phase 6: Replace Completion Handlers with async/await

| File | Function |
|------|----------|
| `PuzzleViewState.swift:135` | `animatePuzzleSwitch(completion:)` |
| `OverlayManager.swift:53` | `dismiss(completion:)` |
| `PuzzleCompletionView.swift:50` | `typeLine(..., completion:)` |

---

## Phase 7: Minor API Updates

### 7.1 Replace Deprecated APIs
```swift
// Before
.edgesIgnoringSafeArea(.all)

// After
.ignoresSafeArea()
```

**Locations:** `OverlayManager.swift:453, 741`, `PuzzleCompletionView.swift`

### 7.2 Replace NotificationCenter with Direct Bindings
**Files:** `PuzzleViewModel.swift:182-195`, `SettingsViewModel.swift:22`

Use `.onChange(of:)` in views or Combine publishers instead.

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

| Phase | Effort | Impact |
|-------|--------|--------|
| 1. Performance Fixes | 1-2 days | High - fixes lag/battery issues |
| 2. Delete Dead Code | 10 min | Low - cleanup |
| 3. Consolidate Duplicates | 1 day | Medium - maintainability |
| 4. @Observable Migration | 2-3 days | High - modern Swift |
| 5. async/await Migration | 1-2 days | Medium - cleaner code |
| 6. Completion → async | 2-3 hours | Low - cleaner code |
| 7. Minor API Updates | 1 hour | Low - future-proofing |
| 8. Architecture | 1-2 weeks | High - testability/maintainability |

**Recommended Order:** Phases 1-3 first (quick wins), then 4-5 (modernization), then 8 (if time permits).
