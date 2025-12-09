# Code Review Findings

Comprehensive code review conducted on 2025-12-10.

---

## 1. Dead Code (Safe to Delete)

| File/Item | Location | Lines |
|-----------|----------|-------|
| `PuzzleUIViewModel.swift` | ViewModels/ | ~130 |
| `NavigationAnimations.swift` | ViewModels/Navigation/ | ~100 |
| `LoadingView.swift` | Views/Components/ | ~18 |
| `FloatingInfoButton.swift` | Views/Components/ | ~36 |
| `SettingsImports.swift` | Views/Components/Settings/ | 0 (empty) |
| `ToolbarCloseButton` struct | Views/Components/CloseButton.swift:34-38 | 5 |
| `simple_cryptogramTests.swift` | Tests/ | placeholder |
| `PuzzleViewModelIntegrationTests.swift.disabled` | Tests/ | disabled |
| 3 unused feature flags | Utils/FeatureFlags.swift | `newNavigation`, `modernAppSettings`, `extractedServices` |

---

## 2. Bugs to Fix

### Critical

#### Off-by-one error in PuzzleCompletionView:51
```swift
// Current (bug - iterates one extra time)
for currentIndex in 0...characters.count {

// Fix
for currentIndex in 0..<characters.count {
```

#### Force unwrap of nullable parameter - LocalPuzzleProgressStore:137
```swift
// Current (crashes if encodingType is nil)
attemptsTable.filter(self.puzzleID == puzzleID.uuidString && self.encodingType == encodingType!)

// Fix - add guard
guard let encoding = encodingType else { return [] }
```

#### Force unwraps in PuzzleCompletionView (lines 70, 75, 177-178, 231, 241)
- Use optional binding or `map` instead of `?.isEmpty == false` + force unwrap
- Example fix:
```swift
// Current
bornTyped = (author.placeOfBirth?.isEmpty == false) ? " \(birthDate) (\(author.placeOfBirth!))" : " \(birthDate)"

// Fix
bornTyped = author.placeOfBirth.map { " \(birthDate) (\($0))" } ?? " \(birthDate)"
```

### Medium

#### Redundant DispatchQueue.main.async in @MainActor class - HintManager:64
```swift
// Current (redundant - already on main thread)
DispatchQueue.main.async {
    let generator = UISelectionFeedbackGenerator()
    generator.selectionChanged()
}

// Fix - remove wrapper
let generator = UISelectionFeedbackGenerator()
generator.selectionChanged()
```

#### Missing empty string check - AuthorService:17
```swift
// Current
guard name != lastAuthorName else { return }

// Fix
guard !name.isEmpty, name != lastAuthorName else { return }
```

---

## 3. SwiftUI Modernization Opportunities

### High Priority - Quick Wins

#### Convert to @Observable (consistency with rest of codebase)
- `HomeViewModel.swift:7` - still uses `ObservableObject`
- `PuzzleSelectionManager.swift:4` - still uses `ObservableObject`

#### Update onChange syntax (remove unused old value parameter)
```swift
// Current (iOS 17 verbose form)
.onChange(of: scenePhase) { _, newPhase in

// Modern (iOS 17.4+)
.onChange(of: scenePhase) { newPhase in
```

Files affected:
- `simple_cryptogramApp.swift:30`
- `ContentView.swift:20, 25`
- `PuzzleCell.swift:87, 107, 112`

#### Remove redundant UIWindow theme override - ThemeManager.swift
- Already using `.preferredColorScheme()` in the App struct, making `setSystemAppearance()` redundant

### Medium Priority

#### Replace Timer patterns with async/await
- `StatsView.swift:25` - `Timer.publish + onReceive` → `.task { while true { await Task.sleep } }`
- `PuzzleUIViewModel.swift` (if kept) - `Timer.scheduledTimer` → async for-loop

#### Replace NotificationCenter with callback - PuzzleViewModel.swift:167-173
```swift
// Current
NotificationCenter.default.addObserver(self, selector: #selector(handleDifficultySelectionChanged)...)

// Modern - use callback or @Observable property observation
```

---

## 4. Performance Improvements

### High Impact

#### Cache `wordGroups` computed property - GameStateManager.swift:86-108

Every view render recalculates word groups AND creates new UUIDs, causing SwiftUI to rebuild everything:
```swift
// Current - recalculates on every access
var wordGroups: [WordGroup] {
    // Full iteration every time
}

// Fix - compute once and cache
private var cachedWordGroups: [WordGroup]?
func updateWordGroups() { ... }
```

#### Single-pass statistics - StatisticsManager.swift:42-67

Currently iterates 3+ times for totals:
```swift
// Current
var totalCompletions: Int { getCachedAttempts().filter { $0.completedAt != nil }.count }
var totalFailures: Int { getCachedAttempts().filter { $0.failedAt != nil }.count }

// Fix - single aggregation
private func aggregateStats() -> (completions: Int, failures: Int) {
    var c = 0, f = 0
    for a in getCachedAttempts() {
        if a.completedAt != nil { c += 1 }
        if a.failedAt != nil { f += 1 }
    }
    return (c, f)
}
```

#### Reduce filter chains - GameStateManager.swift:74-84

`progressPercentage` calls `nonSymbolCells` which filters, then filters again:
```swift
// Current - filters twice
var progressPercentage: Double {
    let totalNonSymbol = nonSymbolCells.count  // filter #1
    let filledCells = nonSymbolCells.filter { !$0.userInput.isEmpty }.count  // filter #2
}

// Fix - single pass
var progressPercentage: Double {
    var total = 0, filled = 0
    for cell in cells where !cell.isSymbol {
        total += 1
        if !cell.userInput.isEmpty { filled += 1 }
    }
    return total > 0 ? Double(filled) / Double(total) : 0
}
```

### Medium Impact

#### Add Equatable to PuzzleCell
Prevents unnecessary re-renders in ForEach loops.

#### Cache date formatting in ContinuousCalendarView:101-108
Currently formats 35+ dates per render.

#### Increase stats cache duration - StatisticsManager.swift:13
1 second is too short; invalidate on event instead.

---

## Recommended Action Order

1. **Delete dead code** (safe, reduces maintenance burden)
2. **Fix the off-by-one bug** in PuzzleCompletionView (crash risk)
3. **Fix force unwraps** in LocalPuzzleProgressStore (crash risk)
4. **Cache wordGroups** (biggest performance win)
5. **Convert HomeViewModel/PuzzleSelectionManager to @Observable** (consistency)
6. **Update onChange syntax** (code cleanliness)

---

## Summary

| Category | Count |
|----------|-------|
| Dead code files/items | 9 |
| Critical bugs | 3 |
| Medium bugs | 2 |
| Modernization opportunities | 6 |
| Performance improvements | 6 |
