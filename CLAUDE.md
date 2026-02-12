# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview
Simple Cryptogram is a SwiftUI-based iOS puzzle game where users decode encrypted quotes. The app uses MVVM architecture with a SQLite database for content storage. The app features a home screen for puzzle selection before entering the game.

## Build and Development Commands

### Building
```bash
# Debug build
xcodebuild -project "simple cryptogram.xcodeproj" -scheme "simple cryptogram" -configuration Debug

# Release build
xcodebuild -project "simple cryptogram.xcodeproj" -scheme "simple cryptogram" -configuration Release

# Clean build
xcodebuild clean -project "simple cryptogram.xcodeproj"
```

### Testing
```bash
# Run all tests (use available iOS Simulator — check `xcrun simctl list devices` for names)
xcodebuild test -project "simple cryptogram.xcodeproj" -scheme "simple cryptogram" -destination 'platform=iOS Simulator,name=iPhone 17 Pro'

# Run specific test
xcodebuild test -project "simple cryptogram.xcodeproj" -scheme "simple cryptogram" -only-testing:"simple cryptogramTests/DatabaseServiceTests"
```

## Architecture

### MVVM Pattern — Simplified
- **Views**: SwiftUI views in `Views/` directory
- **ViewModels**: `PuzzleViewModel` is the single orchestrator for all game logic
- **Models**: Data structures in `Models/`
- **Services**: Data access in `Services/`

### Project Structure
```
simple cryptogram/
├── App/
│   └── simple_cryptogramApp.swift              — App entry point
│
├── Models/
│   ├── Puzzle.swift                            — Puzzle model (quoteId, encoded/solution text, author, difficulty)
│   ├── CryptogramCell.swift                    — Individual cell in the puzzle grid
│   ├── PuzzleAttempt.swift                     — Logged attempt record
│   ├── PuzzleSession.swift                     — Session timing, mistakes, hints, pause state
│   ├── Author.swift                            — Author biographical info
│   ├── FontOption.swift                        — Font selection enum
│   ├── TextSizeOption.swift                    — Text size enum
│   └── NavigationBarLayout.swift               — Nav bar layout enum
│
├── Configuration/StateManagement/
│   └── AppSettings.swift                       — All app settings, persisted via UserDefaults directly
│
├── Services/
│   ├── DatabaseService.swift                   — SQLite operations, puzzle fetching, author lookup
│   ├── LocalPuzzleProgressStore.swift          — Progress persistence (SQLite)
│   ├── PuzzleProgressStore.swift               — Protocol for progress store
│   └── DatabaseError.swift                     — Error types with user-friendly messages
│
├── ViewModels/
│   ├── PuzzleViewModel.swift (845 lines)       — THE single orchestrator: game state, input, hints, daily, stats
│   ├── PuzzleViewState.swift                   — Overlay state management (used by OverlayManager)
│   ├── PuzzleUIViewModel.swift                 — UI-specific view model
│   ├── DailyPuzzleProgress.swift               — Codable daily progress struct
│   └── Navigation/
│       └── NavigationCoordinator.swift         — NavigationStack path management
│
├── Views/
│   ├── ContentView.swift                       — Root NavigationStack container
│   ├── HomeView.swift                          — Home screen: play, daily puzzle, length selection
│   ├── PuzzleView.swift                        — Main puzzle gameplay view
│   ├── PuzzleViewConstants.swift               — Layout constants
│   ├── KeyboardView.swift                      — Custom keyboard
│   ├── UserStatsView.swift                     — User statistics display
│   ├── Components/
│   │   ├── OverlayManager.swift                — Overlay presentation system (settings, stats, completion, etc.)
│   │   ├── PuzzleCompletionView.swift          — Post-game completion screen
│   │   ├── PuzzleCell.swift                    — Individual puzzle cell view
│   │   ├── WordAwarePuzzleGrid.swift           — Word-aware grid layout
│   │   ├── NavigationBarView.swift             — Customizable navigation bar
│   │   ├── TopBarView.swift                    — Top bar with timer
│   │   ├── BottomBarView.swift                 — Bottom bar (stats/settings buttons)
│   │   ├── MainContentView.swift               — Main content wrapper
│   │   ├── ContinuousCalendarView.swift        — Calendar for daily puzzles
│   │   ├── SettingsContentView.swift           — Settings panel content
│   │   ├── StatsView.swift                     — Statistics display
│   │   ├── CompletionStatsView.swift           — Completion statistics
│   │   ├── InfoOverlayView.swift               — Info/about overlay
│   │   ├── AuthorInfoView.swift                — Author bio card
│   │   ├── FloatingInfoButton.swift            — Floating ? button
│   │   ├── CloseButton.swift                   — Reusable close button
│   │   ├── MultiCheckboxRow.swift              — Multi-checkbox component
│   │   ├── ResetAccountSection.swift           — Account reset UI
│   │   ├── DisclaimersSection.swift            — Disclaimers
│   │   ├── LoadingView.swift                   — Loading indicator
│   │   └── Settings/                           — Settings sub-components
│   │       ├── MultiOptionRow.swift
│   │       ├── SettingsSection.swift
│   │       ├── NavBarLayoutPreview.swift
│   │       ├── ToggleOptionRow.swift
│   │       ├── NavBarLayoutSelector.swift
│   │       ├── NavBarLayoutDropdown.swift
│   │       ├── IconToggleButton.swift
│   │       └── InfoPanel.swift
│   └── Theme/
│       ├── CryptogramTheme.swift               — Color palette
│       ├── ThemeManager.swift                  — Theme management
│       ├── ViewModifiers.swift                 — Shared view modifiers
│       └── ColorExtensions.swift               — Color utilities
│
└── Utils/
    └── TimeInterval+Formatting.swift           — Time formatting extension
```

### Key Architectural Components

1. **PuzzleViewModel** (`ViewModels/PuzzleViewModel.swift`): Single orchestrator for all game logic
   - Contains ALL game state, input handling, hints, daily puzzle management, statistics, and progress tracking
   - Previously split across 8 separate managers (GameStateManager, InputHandler, HintManager, DailyPuzzleManager, PuzzleProgressManager, StatisticsManager, PuzzleSelectionManager, AuthorService) — now consolidated into one file
   - Manages puzzle cells, session state, completion checking
   - Daily puzzle save is synchronous (no debounce) to prevent data loss bugs
   - Dependencies: DatabaseService, PuzzleProgressStore

2. **AppSettings** (`Configuration/StateManagement/AppSettings.swift`): All app settings
   - Persists directly to UserDefaults (no abstraction layer)
   - Includes settings display helpers (quoteLengthDisplayText, toggleLength)
   - Supports reset to user defaults and factory defaults
   - Injected via `@Environment(AppSettings.self)` in views

3. **NavigationCoordinator** (`ViewModels/Navigation/NavigationCoordinator.swift`): Navigation management
   - Manages NavigationStack path
   - Simple API: navigateToPuzzle(), navigateToHome(), navigateBack()

4. **DatabaseService** (`Services/DatabaseService.swift`): Data layer
   - SQLite operations with error handling
   - Puzzle fetching (random, by ID, daily)
   - Author information lookup
   - Throws DatabaseError for failures

5. **LocalPuzzleProgressStore** (`Services/LocalPuzzleProgressStore.swift`): Progress persistence
   - Implements PuzzleProgressStore protocol
   - Logs attempts, tracks completions, calculates statistics

6. **ThemeManager** (`Views/Theme/ThemeManager.swift`): Theming
   - Dynamic color management for light/dark modes
   - Typography system with font selection (System, Rounded, Serif, Monospaced)

### State Management
- **AppSettings**: Central source of truth for all app settings, persisted via UserDefaults
- **PuzzleViewState**: UI overlay state management (completion views, settings, stats overlays)
- **@Environment**: Used for dependency injection in views (AppSettings, PuzzleViewModel, ThemeManager, NavigationCoordinator)

### State Access Patterns
For Views:
```swift
@Environment(AppSettings.self) private var appSettings
// Access: appSettings.encodingType
```

For ViewModels:
```swift
private var encodingType: String {
    return AppSettings.shared?.encodingType ?? "Letters"
}
```

### Error Handling
- **DatabaseError** (`Services/DatabaseError.swift`): User-friendly error messages with recovery suggestions
- All database operations use proper error propagation
- PuzzleViewModel handles errors with user feedback

### Database Schema
The app uses SQLite with the following main tables:
- `quotes`: Puzzle content
- `encoded_quotes`: Pre-encoded puzzle data
- `authors`: Author biographical information
- `daily_puzzles`: Daily puzzle scheduling

## Development Considerations

### Swift Package Dependencies
- SQLite.swift (0.15.3): Database operations

### Key Features to Maintain
- Home screen with puzzle length selection (Short/Medium/Long/Random)
- Letter and number encoding modes
- Pre-filled letters at puzzle start (20% of unique letters revealed)
- Daily puzzle system with calendar-based access
  - Users can access any past daily puzzle
  - Progress is saved separately for each day (UserDefaults, JSON-encoded DailyPuzzleProgress)
  - Daily save is synchronous — no debounce, no pending save params
- Comprehensive statistics tracking
- Author information cards
- Haptic feedback for user interactions
- Navigation between home and puzzle views
- Font selection system (System, Rounded, Serif, Monospaced)

### Testing
- **Test Suite**: ~58 tests across 8 test files
- **Test Organization**:
  - `DatabaseServiceTests`: Database operations and error handling
  - `LocalPuzzleProgressStoreTests`: Progress persistence and migration
  - `AppSettingsTests`: Settings persistence and reset
  - `DailySaveBugTests`: Regression tests for daily puzzle save bugs
  - `NavigationCoordinatorTests`: Navigation state management
  - `OverlayManagerTests`: Overlay state and mutual exclusion
  - `PerformanceBaselineTests`: Performance baselines for critical paths
  - `simple_cryptogramTests`: Basic app tests

### Common Development Tasks
When adding new features:
1. Update database schema if needed (add migration in `data/migrations/`)
2. Add game logic directly to PuzzleViewModel (organized by MARK sections)
3. Create reusable view components in `Views/Components/`
4. Add new settings to AppSettings with UserDefaults persistence
5. Write tests for new functionality
6. Test on both light and dark themes
7. For UI features involving fonts:
   - Use `@Environment(\.typography)` in views to access dynamic typography
   - Typography is injected via `.injectTypography()` on ContentView
   - Puzzle cells remain monospaced regardless of font selection

### Navigation Flow
1. **ContentView** → **HomeView** (app entry point)
2. **HomeView** → **PuzzleView** (via puzzle selection or daily puzzle)
3. **PuzzleView** → completion/game-over overlays (managed by OverlayManager)
4. Navigation back to HomeView via NavigationCoordinator

### Puzzle Length Selection
- **Short**: Puzzles under 50 characters (maps to "easy" difficulty)
- **Medium**: Puzzles 50-99 characters (maps to "medium" difficulty)
- **Long**: Puzzles 100+ characters (maps to "hard" difficulty)
- **Random**: Any length (all difficulties selected)

### Design Patterns
- **Single Orchestrator**: PuzzleViewModel handles all game logic (no manager delegation)
- **Protocol-Oriented**: PuzzleProgressStore protocol for testability
- **Environment Injection**: @Environment for dependency injection in SwiftUI views
- **Synchronous Saves**: Daily puzzle progress saved synchronously to prevent race conditions
