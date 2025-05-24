# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview
Simple Cryptogram is a SwiftUI-based iOS puzzle game where users decode encrypted quotes. The app uses MVVM architecture with a SQLite database for content storage.

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

### MVVM Pattern
- **Views**: SwiftUI views in `Views/` directory
- **ViewModels**: Business logic in `ViewModels/` (PuzzleViewModel, SettingsViewModel)
- **Models**: Data structures in `Models/`
- **Services**: Data access and business services in `Services/`

### Key Architectural Components

1. **DatabaseService** (`Services/DatabaseService.swift`): Singleton managing SQLite operations
   - Handles quotes, authors, and daily puzzles
   - Supports database migrations via SQL files in `data/migrations/`

2. **PuzzleViewModel** (`ViewModels/PuzzleViewModel.swift`): Core game state management
   - Manages puzzle encoding/decoding logic
   - Handles user input and validation
   - Tracks completion and hints

3. **LocalPuzzleProgressStore** (`Services/LocalPuzzleProgressStore.swift`): User progress persistence
   - Implements PuzzleProgressStore protocol
   - Tracks attempts, completions, and statistics

4. **ThemeManager** (`Views/Theme/ThemeManager.swift`): Centralized theming
   - Dynamic color management for light/dark modes
   - Custom color assets in `Assets.xcassets/Colors/`

### State Management
- Environment objects for app-wide state sharing
- UserDefaults for settings persistence
- NotificationCenter for settings change propagation

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
- Letter and number encoding modes
- Normal/Expert difficulty levels
- Daily puzzle system with calendar-based access
- Comprehensive statistics tracking
- Author information cards
- Haptic feedback for user interactions

### Testing Approach
- Unit tests for ViewModels and Services
- UI tests for critical user flows
- Database migration tests when adding new schema changes

### Common Development Tasks
When adding new features:
1. Update database schema if needed (add migration in `data/migrations/`)
2. Extend relevant ViewModels for business logic
3. Create reusable components in `Views/Components/`
4. Update UserSettings if adding new preferences
5. Test on both light and dark themes