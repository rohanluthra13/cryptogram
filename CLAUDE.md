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
# Run all tests
xcodebuild test -project "simple cryptogram.xcodeproj" -scheme "simple cryptogram" -destination 'platform=iOS Simulator,name=iPhone 15'

# Run specific test
xcodebuild test -project "simple cryptogram.xcodeproj" -scheme "simple cryptogram" -only-testing:"simple cryptogramTests/YourTestClass/yourTestMethod"
```

## Architecture

### MVVM Pattern with Manager Architecture
- **Views**: SwiftUI views in `Views/` directory
- **ViewModels**: Orchestration and business logic in `ViewModels/`
- **Models**: Data structures in `Models/`
- **Services**: Data access and business services in `Services/`

### Core ViewModels Structure
The app uses a manager pattern to separate concerns:
```
ViewModels/
├── PuzzleViewModel.swift (452 lines) - Central orchestrator
├── SettingsViewModel.swift - Settings management
├── GameState/
│   └── GameStateManager.swift - Game state, cells, completion
├── Progress/
│   ├── PuzzleProgressManager.swift - Progress persistence
│   └── StatisticsManager.swift - Stats aggregation
├── Input/
│   ├── InputHandler.swift - Keyboard and selection
│   └── HintManager.swift - Hint system
└── Daily/
    └── DailyPuzzleManager.swift - Daily puzzle features
```

### Core Views Structure
```
Views/
├── ContentView.swift - Root view container
├── HomeView.swift - Home screen with puzzle selection
├── PuzzleView.swift - Main puzzle gameplay view
├── Components/
│   ├── PuzzleCompletionView.swift - Post-game completion screen
│   ├── TopBarView.swift - Top navigation bar
│   ├── WeeklySnapshot.swift - Weekly progress view (currently unused, available for future use)
│   └── ... other components
```

### Refactoring Infrastructure

1. **FeatureFlags** (`Utils/FeatureFlags.swift`): Feature flag system for gradual rollout
   - Enables/disables refactored components safely
   - Debug mode allows feature flag overrides
   - Production mode uses hardcoded safe defaults

2. **Performance Monitoring** (`simple cryptogramTests/PerformanceBaselineTests.swift`): 
   - Automated performance measurement tests
   - Baseline metrics for app launch, puzzle loading, user interaction
   - Regression detection during refactoring

3. **Memory Leak Detection** (`simple cryptogramTests/MemoryLeakDetectionTests.swift`):
   - Automated memory management validation
   - Retain cycle detection for managers and view models
   - Extended usage stability testing

### Key Architectural Components

1. **PuzzleViewModel** (`ViewModels/PuzzleViewModel.swift`): Central orchestrator
   - Coordinates all specialized managers
   - Maintains backward compatibility
   - Handles author loading and error state
   - Provides unified interface for views

2. **GameStateManager** (`ViewModels/GameState/GameStateManager.swift`): Core game logic
   - Manages puzzle cells and game session
   - Tracks mistakes, completion, and timing
   - Handles puzzle initialization and reset
   - Controls UI state (wiggling, highlights)
   - Applies pre-filled letters (20% of unique letters) at puzzle start

3. **InputHandler** (`ViewModels/Input/InputHandler.swift`): User input processing
   - Keyboard input validation
   - Cell selection and navigation
   - Delete and clear operations
   - Haptic feedback coordination

4. **HintManager** (`ViewModels/Input/HintManager.swift`): Hint system
   - Cell reveal operations
   - Hint count tracking
   - Smart cell selection after hints

5. **PuzzleProgressManager** (`ViewModels/Progress/PuzzleProgressManager.swift`): Progress tracking
   - Interfaces with LocalPuzzleProgressStore
   - Logs attempts and completions
   - Manages puzzle-specific progress

6. **StatisticsManager** (`ViewModels/Progress/StatisticsManager.swift`): Statistics aggregation
   - Calculates global and puzzle-specific stats
   - Win rates and timing analytics
   - Performance metrics

7. **DailyPuzzleManager** (`ViewModels/Daily/DailyPuzzleManager.swift`): Daily puzzles
   - Date-based puzzle loading (supports loading puzzles for any date)
   - Daily puzzle progress persistence in UserDefaults
   - Calendar integration
   - Tracks current puzzle date for proper progress saving
   - Supports viewing historical daily puzzles

8. **NavigationCoordinator** (`ViewModels/Navigation/NavigationCoordinator.swift`): Modern navigation
   - Centralized NavigationStack management
   - Feature flag controlled navigation modes
   - Puzzle navigation state management
   - Direct navigation without timing dependencies

9. **DatabaseService** (`Services/DatabaseService.swift`): Data layer
   - SQLite operations with error handling
   - Database migrations via SQL files
   - Throws DatabaseError for failures

10. **LocalPuzzleProgressStore** (`Services/LocalPuzzleProgressStore.swift`): Progress persistence
   - Implements PuzzleProgressStore protocol
   - Safe data handling with no force unwraps
   - Error propagation for corrupted data

11. **ThemeManager** (`Views/Theme/ThemeManager.swift`): Centralized theming
    - Dynamic color management for light/dark modes
    - Custom color assets in `Assets.xcassets/Colors/`
    - Typography system with dynamic font selection
    - Font options: System (SF Pro), Rounded, Serif (New York), Monospaced

### State Management
- **AppSettings** (`Configuration/StateManagement/AppSettings.swift`): Central source of truth for all app settings
  - Singleton instance created in App struct to ensure main thread initialization
  - All settings flow through this single instance
  - Implements automatic persistence via PersistenceStrategy
  - Supports reset to user defaults and factory defaults
  - Migrates legacy @AppStorage values automatically
- **UserSettings** (`Configuration/UserSettings.swift`): Legacy compatibility layer
  - Now forwards all calls to AppSettings
  - Maintained for backward compatibility during transition
- **PuzzleViewState** (`ViewModels/PuzzleViewState.swift`): UI state management
  - Uses `CompletionState` enum for completion view management
  - Centralized overlay state handling
  - No more separate boolean flags for different completion types
- Environment objects for app-wide state sharing
- Direct method calls instead of NotificationCenter for navigation

### Error Handling
- **DatabaseError** (`Services/DatabaseError.swift`): User-friendly error messages
  - Categorized errors (initialization, migration, data access)
  - Recovery suggestions for each error type
  - Localized error descriptions
- **ErrorRecoveryService** (`Services/ErrorRecoveryService.swift`): Automatic recovery
  - Retry logic for transient failures
  - Database reinitialization for corruption
  - User notification for unrecoverable errors
- All database operations use proper error propagation
- ViewModels handle errors gracefully with user feedback

### State Access Patterns
For Views:
```swift
@EnvironmentObject private var appSettings: AppSettings
// Access: appSettings.encodingType
```

For ViewModels:
```swift
private var encodingType: String {
    return AppSettings.shared?.encodingType ?? "Letters"
}
```

### Database Schema
The app uses SQLite with the following main tables:
- `quotes`: Puzzle content
- `encoded_quotes`: Pre-encoded puzzle data
- `authors`: Author biographical information
- `daily_puzzles`: Daily puzzle scheduling

## Development Considerations

### Feature Flags
The app uses feature flags for gradual rollout of refactored components. In debug builds, flags can be enabled/disabled via UserDefaults:

```bash
# Enable completed Phase 1 features (recommended for development)
xcrun simctl spawn booted defaults write com.yourcompany.simple-cryptogram ff_new_navigation -bool true
xcrun simctl spawn booted defaults write com.yourcompany.simple-cryptogram ff_modern_sheets -bool true

# Disable features for testing legacy behavior
xcrun simctl spawn booted defaults write com.yourcompany.simple-cryptogram ff_new_navigation -bool false
xcrun simctl spawn booted defaults write com.yourcompany.simple-cryptogram ff_modern_sheets -bool false

# Check current feature flag status in debugger
po FeatureFlag.allFlags
```

**Current Status (Post-Phase 1 Refactoring)**:
- `newNavigation`: ✅ Completed - NavigationStack-based navigation
- `modernSheets`: ❌ Removed - Committed to overlay-based presentation
- `modernAppSettings`: ⏳ Pending Phase 2
- `extractedServices`: ⏳ Pending Phase 3

**Navigation Updates**:
- ✅ Phase 1.1: NavigationStack implementation complete
- ✅ Sheet removal: All .sheet() modifiers removed
- ✅ Phase 1: Completion view navigation fixed with unified UI

### Swift Package Dependencies
- SQLite.swift (0.15.3): Database operations

### Key Features to Maintain
- Home screen with puzzle length selection (Short/Medium/Long/Random)
- Letter and number encoding modes
- Pre-filled letters at puzzle start (20% of unique letters revealed)
- Daily puzzle system with calendar-based access
  - Users can access any past daily puzzle
  - Progress is saved separately for each day
  - Completed daily puzzles show completion view only once per session
- Comprehensive statistics tracking
- Author information cards
- Haptic feedback for user interactions
- Navigation between home and puzzle views
- Font selection system (System, Rounded, Serif, Monospaced)

### Testing Approach
- **Comprehensive Test Suite**: 127+ tests covering all managers
  - Unit tests for each manager component
  - Integration tests for manager coordination
  - Performance tests for critical paths
  - Database migration and error handling tests
- **Test Organization**:
  - `GameStateManagerTests`: Game logic and state transitions
  - `InputHandlerTests`: Input validation and navigation
  - `HintManagerTests`: Hint system edge cases
  - `PuzzleProgressManagerTests`: Progress persistence
  - `StatisticsManagerTests`: Stats calculation accuracy
  - `DailyPuzzleManagerTests`: Daily puzzle workflows
  - `PuzzleViewModelIntegrationTests`: End-to-end scenarios
- **Testing Commands**:
  ```bash
  # Run all tests (use iPhone 16 simulator)
  xcodebuild test -project "simple cryptogram.xcodeproj" -scheme "simple cryptogram" -destination 'platform=iOS Simulator,name=iPhone 16'
  
  # Run specific manager tests
  xcodebuild test -project "simple cryptogram.xcodeproj" -scheme "simple cryptogram" -only-testing:"simple cryptogramTests/GameStateManagerTests"
  
  # Run performance baseline tests
  xcodebuild test -project "simple cryptogram.xcodeproj" -scheme "simple cryptogram" -only-testing:"simple cryptogramTests/PerformanceBaselineTests"
  
  # Run memory leak detection tests
  xcodebuild test -project "simple cryptogram.xcodeproj" -scheme "simple cryptogram" -only-testing:"simple cryptogramTests/MemoryLeakDetectionTests"
  ```

### Common Development Tasks
When adding new features:
1. Update database schema if needed (add migration in `data/migrations/`)
2. Identify the appropriate manager for your feature:
   - Game mechanics → GameStateManager
   - User input → InputHandler
   - Progress/stats → PuzzleProgressManager/StatisticsManager
   - Daily puzzles → DailyPuzzleManager
   - New domain → Create a new manager
3. Update PuzzleViewModel to expose new functionality
4. Create reusable components in `Views/Components/`
5. Add new settings to AppSettings (not UserSettings)
6. Write unit tests for your manager changes
7. Test on both light and dark themes
8. Ensure new settings are persisted via AppSettings' didSet observers
9. Handle errors appropriately using DatabaseError patterns
10. For UI features involving fonts:
    - Use `@Environment(\.typography)` in views to access dynamic typography
    - Typography is injected via `.injectTypography()` on ContentView
    - Puzzle cells remain monospaced regardless of font selection

### Navigation Flow
The app follows this navigation structure:
1. **ContentView** → **HomeView** (app entry point)
2. **HomeView** → **PuzzleView** (via puzzle selection)
3. **PuzzleView** → **PuzzleCompletionView** (on puzzle completion)
4. Navigation back to HomeView via:
   - Home button in TopBarView (during gameplay)
   - Home button in BottomBarView within PuzzleCompletionView (after completion)
   - Direct navigation using NavigationCoordinator (no delays or notifications)

### Completion View Design
- **Regular Puzzle Completion**: Shows next puzzle button + bottom bar (stats/home/settings)
- **Daily Puzzle Completion**: Shows calendar and next puzzle buttons + bottom bar
- Both use consistent bottom bar placement for home navigation
- No timing dependencies or notification-based navigation

### Puzzle Length Selection
- **Short**: Puzzles under 50 characters (maps to "easy" difficulty)
- **Medium**: Puzzles 50-99 characters (maps to "medium" difficulty)
- **Long**: Puzzles 100+ characters (maps to "hard" difficulty)
- **Random**: Any length (all difficulties selected)

### Component Design Patterns
- **Manager Pattern**: Each manager has a single responsibility
- **Coordinator Pattern**: PuzzleViewModel coordinates managers
- **Protocol-Oriented**: Use protocols for testability (e.g., PuzzleProgressStore)
- **Error Propagation**: Throw errors up, handle at view layer
- **Functional Composition**: See NavigationBarView for clean component design