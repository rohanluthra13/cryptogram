# Simple Cryptogram - App Overview

A SwiftUI-based iOS puzzle game where users decode encrypted quotes. The app uses MVVM architecture with a SQLite database for puzzle content.

---

## How the App Works (User Flow)

```
App Launch → HomeView → Select Puzzle Type → PuzzleView → Complete → Completion Screen → Back to Home
```

1. User opens app → lands on **HomeView** (puzzle selection screen)
2. User picks "Short/Medium/Long/Random" or "Daily Puzzle"
3. App navigates to **PuzzleView** where they solve the cryptogram
4. On completion/failure, overlays appear (completion screen or game over)
5. User can return home and repeat

---

## File Structure

### 📁 `App/` - Entry Point

| File | Purpose |
|------|---------|
| 📄 `simple_cryptogramApp.swift` | App launch point. Creates shared objects (`AppSettings`, `PuzzleViewModel`, `ThemeManager`), sets up window with `ContentView`, handles app lifecycle (pause/resume). |

---

### 📁 `Views/` - The UI Layer

#### ✅ Main Views (Active)

| File | Purpose |
|------|---------|
| 📄 `ContentView.swift` | Root container. Wraps `HomeView` in `NavigationStack`, handles navigation to `PuzzleView`. |
| 📄 `HomeView.swift` | Home screen. Puzzle length selection (Short/Medium/Long/Random), daily puzzle button, bottom bar with stats/settings. |
| 📄 `PuzzleView.swift` | Main gameplay screen. Shows puzzle grid, keyboard, top bar, handles completion/failure states. |
| 📄 `KeyboardView.swift` | On-screen letter keyboard for input. |
| 📄 `UserStatsView.swift` | Statistics display (win rate, best times, etc.). |

#### 🗑️ Dead Code (To Delete)

| File | Lines | Status |
|------|-------|--------|
| 📄 `ModernContentView.swift` | 130 | 🗑️ Abandoned refactor - NEVER USED |
| 📄 `ModernHomeView.swift` | 224 | 🗑️ Abandoned refactor - NEVER USED |
| 📄 `ModernPuzzleView.swift` | 517 | 🗑️ Abandoned refactor - NEVER USED |

These were an attempt to use `BusinessLogicCoordinator` + `NavigationState` instead of `PuzzleViewModel`. The refactor was abandoned mid-way.

#### 📁 `Views/Components/` - Reusable UI Pieces

| File | Purpose |
|------|---------|
| 📄 `TopBarView.swift` | Top navigation bar (home, pause, hint buttons) |
| 📄 `BottomBarView.swift` | Bottom bar (stats, settings buttons) |
| 📄 `NavigationBarView.swift` | Letter navigation bar `< A >` for cycling through letters |
| 📄 `PuzzleCell.swift` | Individual puzzle cell component |
| 📄 `WordAwarePuzzleGrid.swift` | Puzzle grid that wraps words correctly |
| 📄 `PuzzleCompletionView.swift` | Victory screen after completing puzzle |
| 📄 `OverlayManager.swift` | ⚠️ **MASSIVE (921 lines)** - handles ALL overlays (settings, stats, calendar, pause, game over, completion) |
| 📄 `CalendarView.swift` | Calendar for daily puzzles |
| 📄 `ContinuousCalendarView.swift` | Scrolling calendar variant |
| 📄 `SettingsContentView.swift` | Settings panel content |
| 📄 `StatsView.swift` | Stats display component |
| 📄 `InfoOverlayView.swift` | "About" info overlay |
| 📄 `AuthorInfoView.swift` | Shows quote author info |
| 📄 `LoadingView.swift` | Loading spinner |
| 📄 `WeeklySnapshot.swift` | 🗑️ **UNUSED** - marked "for future use" |

#### 📁 `Views/Components/Settings/` - Settings UI Components

Small reusable components for building the settings screen:
- 📄 `SettingsSection.swift`
- 📄 `ToggleOptionRow.swift`
- 📄 `MultiOptionRow.swift`
- 📄 `IconToggleButton.swift`
- 📄 `InfoPanel.swift`
- 📄 `NavBarLayoutSelector.swift`
- 📄 `NavBarLayoutPreview.swift`
- 📄 `NavBarLayoutDropdown.swift`

#### 📁 `Views/Theme/` - Visual Styling

| File | Purpose |
|------|---------|
| 📄 `ThemeManager.swift` | Manages dark/light mode, colors |
| 📄 `CryptogramTheme.swift` | Color definitions |
| 📄 `ColorExtensions.swift` | Custom color extensions |
| 📄 `ViewModifiers.swift` | Shared view modifiers (typography injection, etc.) |

---

### 📁 `ViewModels/` - Business Logic Layer

#### ✅ Main Orchestrator

| File | Purpose |
|------|---------|
| 📄 `PuzzleViewModel.swift` | 🎯 **CENTRAL HUB (374 lines)** - Views talk to this, it delegates to specialized managers. Coordinates all game logic. |

#### 🗑️ Dead Code (To Delete)

| File | Lines | Status |
|------|-------|--------|
| 📄 `BusinessLogicCoordinator.swift` | 349 | 🗑️ Duplicate of `PuzzleViewModel` - NEVER USED. Was meant to replace `PuzzleViewModel` in Modern* views. |

#### ✅ State Management

| File | Purpose |
|------|---------|
| 📄 `PuzzleViewState.swift` | UI state for `PuzzleView`. Manages: `showSettings`, `showStats`, `completionState`, bottom bar visibility, animations. |
| 📄 `PuzzleUIViewModel.swift` | Minor UI helpers |

#### 📁 `ViewModels/GameState/` - Core Game Logic

| File | Purpose |
|------|---------|
| 📄 `GameStateManager.swift` | 🎮 **THE GAME ENGINE (341 lines)**. Manages puzzle cells, user input validation, tracks mistakes/completion/pausing, handles pre-filled letters (20% revealed at start), checks if puzzle is solved. |

#### 📁 `ViewModels/Input/` - User Input Handling

| File | Purpose |
|------|---------|
| 📄 `InputHandler.swift` | ⌨️ Processes keyboard input, cell selection, navigation between cells |
| 📄 `HintManager.swift` | 💡 Handles hint reveals |

#### 📁 `ViewModels/Progress/` - Statistics & Progress

| File | Purpose |
|------|---------|
| 📄 `PuzzleProgressManager.swift` | 📊 Logs completions/failures to database. 🔴 **HAS `fatalError()` ON LINE 24** |
| 📄 `StatisticsManager.swift` | 📈 Calculates win rates, best times, averages |

#### 📁 `ViewModels/Daily/` - Daily Puzzle Feature

| File | Purpose |
|------|---------|
| 📄 `DailyPuzzleManager.swift` | 📅 Loads puzzles by date, saves/restores daily progress |
| 📄 `DailyPuzzleProgress.swift` | 💾 Data model for daily puzzle state (stored in UserDefaults) |

#### 📁 `ViewModels/Navigation/` - Navigation System

| File | Purpose | Status |
|------|---------|--------|
| 📄 `NavigationCoordinator.swift` | Simple navigation path management | ✅ **ACTIVE** |
| 📄 `NavigationState.swift` | More complex navigation system | 🗑️ **UNUSED** - for Modern* views |
| 📄 `NavigationAnimations.swift` | Animation constants | ✅ Active |
| 📄 `NavigationPerformance.swift` | Performance monitoring | ⚠️ Has debug prints |
| 📄 `NavigationPersistence.swift` | State persistence | ⚠️ Has debug prints |
| 📄 `DeepLinkManager.swift` | URL deep linking support | ⚠️ Has debug prints |

#### ✅ Other ViewModels

| File | Purpose |
|------|---------|
| 📄 `HomeViewModel.swift` | Logic for home screen |
| 📄 `SettingsViewModel.swift` | Settings logic, difficulty change notifications |

---

### 📁 `Models/` - Data Structures

| File | Purpose |
|------|---------|
| 📄 `Puzzle.swift` | 🧩 Puzzle data (quote, solution, encoding, difficulty). Also contains cell creation logic (287 lines - bit bloated). |
| 📄 `CryptogramCell.swift` | 🔤 Single cell: encoded char, solution char, user input, state flags |
| 📄 `PuzzleSession.swift` | ⏱️ Game session: start time, mistakes, completion state, hints used |
| 📄 `PuzzleAttempt.swift` | 📝 Logged attempt for statistics |
| 📄 `Author.swift` | ✍️ Author info (name, bio) |
| 📄 `FontOption.swift` | 🔠 Font selection enum (System, Rounded, Serif, Monospaced) |
| 📄 `TextSizeOption.swift` | 📏 Text size enum |
| 📄 `NavigationBarLayout.swift` | 📐 Layout options for letter nav bar |

---

### 📁 `Services/` - Data Access Layer

| File | Purpose |
|------|---------|
| 📄 `DatabaseService.swift` | 🗄️ SQLite connection, puzzle fetching. Uses SQLite.swift library. |
| 📄 `LocalPuzzleProgressStore.swift` | 💾 Saves puzzle attempts to SQLite |
| 📄 `PuzzleProgressStore.swift` | 📋 Protocol for progress storage |
| 📄 `PuzzleSelectionManager.swift` | 🎲 Smart puzzle selection (excludes completed, filters by difficulty) |
| 📄 `AuthorService.swift` | 👤 Loads author info from database |
| 📄 `DatabaseError.swift` | ❌ Error types with user-friendly messages |
| 📄 `ErrorRecoveryService.swift` | 🔧 Automatic error recovery strategies |

---

### 📁 `Configuration/` - Settings & State

| File | Purpose |
|------|---------|
| 📄 `StateManagement/AppSettings.swift` | ⚙️ Central settings singleton. All app settings flow through here. 🔴 **HAS FORCE UNWRAP `shared!`** |
| 📄 `StateManagement/PersistenceStrategy.swift` | 💾 Protocol for saving settings |
| 📄 `StateManagement/MigrationUtility.swift` | 🔄 Migrates old @AppStorage settings |
| 📄 `StateManagement/StateManager.swift` | 📦 General state management |
| 📄 `UserSettings.swift` | 🏚️ Legacy wrapper (forwards to AppSettings) |

---

### 📁 `Utils/`

| File | Purpose |
|------|---------|
| 📄 `FeatureFlags.swift` | 🚩 Feature flag system. `newNavigation`: ✅ enabled, `modernAppSettings`: ❌ disabled, `extractedServices`: ❌ disabled |

---

## How Components Link Together

```
┌─────────────────────────────────────────────────────────────────────┐
│                     📱 simple_cryptogramApp                          │
│  Creates: AppSettings, PuzzleViewModel, ThemeManager                │
│  Injects them as @EnvironmentObject to all views                    │
└─────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────┐
│                        📄 ContentView                                │
│  - Wraps HomeView in NavigationStack                                │
│  - Handles navigation to PuzzleView via .navigationDestination      │
│  - Shows error alerts                                               │
└─────────────────────────────────────────────────────────────────────┘
                          │                    │
                          ▼                    ▼
┌──────────────────────────────┐    ┌──────────────────────────────┐
│        🏠 HomeView           │    │       🧩 PuzzleView          │
│  - Puzzle length selection   │    │  - TopBarView (nav buttons)  │
│  - Daily puzzle button       │    │  - WordAwarePuzzleGrid       │
│  - Stats/Settings overlays   │    │  - KeyboardView              │
│                              │    │  - BottomBarView             │
│  Uses: .commonOverlays()     │    │  Uses: .overlayManager()     │
└──────────────────────────────┘    └──────────────────────────────┘
                                                  │
                                                  ▼
┌─────────────────────────────────────────────────────────────────────┐
│                      🎯 PuzzleViewModel                              │
│  CENTRAL ORCHESTRATOR - Views call methods on this                  │
│  Delegates to specialized managers:                                  │
│                                                                      │
│  ┌─────────────────┐  ┌─────────────────┐  ┌──────────────────┐    │
│  │🎮 GameState     │  │⌨️ InputHandler  │  │💡 HintManager    │    │
│  │   Manager       │  │ (key presses)   │  │ (reveal cells)   │    │
│  └─────────────────┘  └─────────────────┘  └──────────────────┘    │
│                                                                      │
│  ┌─────────────────┐  ┌─────────────────┐  ┌──────────────────┐    │
│  │📊 Progress      │  │📈 Statistics    │  │📅 DailyPuzzle    │    │
│  │   Manager       │  │   Manager       │  │   Manager        │    │
│  └─────────────────┘  └─────────────────┘  └──────────────────┘    │
└─────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────┐
│                       🗄️ DatabaseService                             │
│  SQLite database connection                                         │
│  - fetchRandomPuzzle()                                              │
│  - fetchDailyPuzzle()                                               │
│  - LocalPuzzleProgressStore (logs attempts)                         │
└─────────────────────────────────────────────────────────────────────┘
```

---

## ✅ Cleanup Completed (Phase 1)

### 🔴 Critical Fixes - DONE ✅

| Fix | Status |
|-----|--------|
| `PuzzleProgressManager.swift` - Replaced `fatalError()` with graceful `NoOpProgressStore` fallback | ✅ Fixed |
| `AppSettings.swift` - Replaced force unwrap `shared!` with computed property + lazy initialization | ✅ Fixed |

### 🗑️ Dead Code Deleted (~2,500 lines) - DONE ✅

| File | Lines | Status |
|------|-------|--------|
| 📄 `ModernContentView.swift` | 130 | ✅ Deleted |
| 📄 `ModernHomeView.swift` | 224 | ✅ Deleted |
| 📄 `ModernPuzzleView.swift` | 517 | ✅ Deleted |
| 📄 `BusinessLogicCoordinator.swift` | 349 | ✅ Deleted |
| 📄 `NavigationState.swift` | 296 | ✅ Deleted |
| 📄 `WeeklySnapshot.swift` | 196 | ✅ Deleted |
| 📄 `NavigationPerformance.swift` | ~250 | ✅ Deleted (depended on deleted types) |
| 📄 `NavigationPersistence.swift` | ~215 | ✅ Deleted (depended on deleted types) |
| 📄 `DeepLinkManager.swift` | ~200 | ✅ Deleted (never configured, orphaned) |
| 📄 `Phase5NavigationTests.swift` | ~350 | ✅ Deleted (tested deleted code) |
| 📄 `NavigationStateTests.swift` | ~220 | ✅ Deleted (tested deleted code) |

---

## 🟠 Remaining Cleanup (Phase 2 - Optional)

| Issue | Files Affected |
|-------|----------------|
| Remove debug `print()` statements | `FeatureFlags.swift` |
| Remove `NotificationCenter` usage (11 occurrences) | `PuzzleViewModel.swift`, `SettingsViewModel.swift`, `HomeView.swift`, etc. |

### 🟡 Nice to Have (Low Priority)

| Issue | Notes |
|-------|-------|
| `OverlayManager.swift` is 921 lines | Could be split into smaller files, but functional |
| `UserSettings.swift` legacy layer | Can delete after confirming AppSettings works everywhere |
| `Puzzle.swift` has business logic | Cell creation could move to a service, but low priority |

---

## 🧪 Test Coverage

The app has **~70 tests** across **~16 test files** covering:

| Test File | Coverage |
|-----------|----------|
| `GameStateManagerTests` | ✅ Core game logic |
| `InputHandlerTests` | ✅ Input validation (10 tests) |
| `HintManagerTests` | ✅ Hint system (7 tests) |
| `PuzzleProgressManagerTests` | ✅ Progress persistence (12 tests) |
| `StatisticsManagerTests` | ✅ Stats calculations |
| `DailyPuzzleManagerTests` | ✅ Daily puzzle workflows (5 tests) |
| `DatabaseServiceTests` | ✅ Database integration |
| `LocalPuzzleProgressStoreTests` | ✅ Progress storage |
| `AppSettingsTests` | ✅ Settings management |
| `NavigationCoordinatorTests` | ✅ Navigation |
| `PerformanceBaselineTests` | ✅ Performance regression detection |
| `MemoryLeakDetectionTests` | ✅ Retain cycle detection |

---

## 📦 Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| SQLite.swift | 0.15.3 | SQLite database abstraction |

---

## ✨ Key Features

- 🧩 Puzzle gameplay with letter/number encoding modes
- 📅 Daily puzzle system with calendar access to past puzzles
- 💡 Pre-filled letters at puzzle start (20% of unique letters revealed)
- 📊 Statistics tracking (wins, times, failure rates)
- ✍️ Author information cards
- 🔠 Font selection (System, Rounded, Serif, Monospaced)
- 🌙 Dark/light mode support
- 📳 Haptic feedback
- 💬 Game-over screen with "friction" message (no ads substitute)
