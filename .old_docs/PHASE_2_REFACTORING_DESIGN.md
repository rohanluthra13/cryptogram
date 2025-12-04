# Phase 2: ViewModel Refactoring Design

## Phase 2.1: PuzzleViewModel Refactoring (COMPLETED ✓)

## Current State Analysis

### File Metrics
- **Lines**: 1036 (target: <200)
- **Responsibilities**: 8+ mixed concerns
- **Published Properties**: 12
- **Methods**: 30+
- **Dependencies**: Multiple direct service calls

### Current Responsibilities
1. **Game State Management**
   - Puzzle session tracking
   - Cell state management
   - Selection tracking
   - Completion/failure detection

2. **Input Handling**
   - Letter input processing
   - Delete operations
   - Cell navigation
   - Hint/reveal logic

3. **Progress Tracking**
   - Attempt logging
   - Statistics calculation
   - Progress persistence

4. **Daily Puzzle Management**
   - Daily puzzle loading
   - Progress save/restore
   - Date-based caching

5. **UI State**
   - Animation triggers
   - Error state
   - Highlight management

6. **Statistics**
   - Current puzzle stats
   - Global user stats
   - Win rate calculations

7. **Author Management**
   - Author info loading
   - Caching

8. **Settings Integration**
   - Difficulty mode handling
   - Encoding type management

## Proposed Architecture

### Core Components

```
ViewModels/
├── PuzzleViewModel.swift (Coordinator, <200 lines)
├── GameState/
│   ├── GameStateManager.swift (~150 lines)
│   └── PuzzleSessionManager.swift (~100 lines)
├── Progress/
│   ├── PuzzleProgressManager.swift (~150 lines)
│   └── StatisticsManager.swift (~100 lines)
├── Input/
│   ├── InputHandler.swift (~200 lines)
│   └── HintManager.swift (~80 lines)
└── Daily/
    └── DailyPuzzleManager.swift (~150 lines)
```

### Detailed Component Design

#### 1. PuzzleViewModel (Coordinator)
**Responsibilities:**
- Coordinate between sub-managers
- Expose combined state to views
- Handle view lifecycle events

**Key Properties:**
```swift
@Published var gameState: GameStateManager
@Published var progress: PuzzleProgressManager
@Published var currentError: DatabaseError?

private let inputHandler: InputHandler
private let dailyManager: DailyPuzzleManager
private let statistics: StatisticsManager
```

#### 2. GameStateManager
**Responsibilities:**
- Manage puzzle cells and current puzzle
- Track completion/failure states
- Handle session state

**Key Properties:**
```swift
@Published private(set) var cells: [CryptogramCell]
@Published private(set) var currentPuzzle: Puzzle?
@Published private(set) var session: PuzzleSession
@Published var isWiggling: Bool
@Published var completedLetters: Set<String>
```

**Key Methods:**
- `startNewPuzzle(puzzle:skipAnimationInit:)`
- `resetPuzzle()`
- `checkCompletion()`
- `updateCompletedLetters()`

#### 3. PuzzleSessionManager
**Responsibilities:**
- Manage current game session
- Track timing and pauses
- Count mistakes and hints

**Integration:**
- Used by GameStateManager
- Provides session state to other components

#### 4. InputHandler
**Responsibilities:**
- Process letter input
- Handle delete operations
- Manage cell navigation
- Coordinate with hint manager

**Key Methods:**
- `inputLetter(_:at:)`
- `handleDelete(at:)`
- `moveToNextCell()`
- `moveToAdjacentCell(direction:)`
- `selectCell(at:)`

#### 5. HintManager
**Responsibilities:**
- Reveal cells
- Track hint usage
- Manage pre-filled cells (Normal mode)

**Key Methods:**
- `revealCell(at:)`
- `applyDifficultyPrefills(cells:puzzle:)`
- `selectNextUnrevealedCell(after:)`

#### 6. PuzzleProgressManager
**Responsibilities:**
- Log attempts
- Track puzzle-specific progress
- Interface with PuzzleProgressStore

**Key Methods:**
- `logCompletion(puzzle:session:)`
- `logFailure(puzzle:session:)`
- `attemptCount(for:)`
- `bestTime(for:)`

#### 7. StatisticsManager
**Responsibilities:**
- Calculate global statistics
- Compute win rates and averages
- Provide formatted stat strings

**Key Properties:**
```swift
var totalAttempts: Int
var totalCompletions: Int
var winRatePercentage: Int
var averageTime: TimeInterval?
var globalBestTime: TimeInterval?
```

#### 8. DailyPuzzleManager
**Responsibilities:**
- Load daily puzzles
- Save/restore daily progress
- Check completion status

**Key Methods:**
- `loadDailyPuzzle()`
- `saveDailyProgress(cells:session:)`
- `isDailyPuzzleCompleted(for:)`

## Implementation Strategy

### Phase 1: Extract Core Managers (Day 1)
1. Create GameStateManager
   - Move cell management
   - Move puzzle state
   - Move completion logic

2. Create InputHandler
   - Extract input methods
   - Move navigation logic
   - Keep haptic feedback

### Phase 2: Extract Support Managers (Day 2)
1. Create HintManager
   - Extract hint logic
   - Move pre-fill logic

2. Create PuzzleProgressManager
   - Move progress logging
   - Extract attempt tracking

3. Create StatisticsManager
   - Move stat calculations
   - Create computed properties

### Phase 3: Extract Daily & Refactor (Day 3)
1. Create DailyPuzzleManager
   - Move daily puzzle logic
   - Extract progress persistence

2. Refactor PuzzleViewModel
   - Wire up all managers
   - Create coordinator methods
   - Ensure backward compatibility

### Phase 4: Testing (Day 4)
1. Unit test each manager
2. Integration tests for coordinator
3. UI tests for critical flows

## Migration Considerations

### Data Flow
- PuzzleViewModel becomes a thin coordinator
- Each manager owns its domain
- Communication via Combine publishers

### Dependency Injection
```swift
class PuzzleViewModel {
    init(
        puzzle: Puzzle? = nil,
        progressStore: PuzzleProgressStore? = nil,
        databaseService: DatabaseService = .shared
    ) {
        self.gameState = GameStateManager(databaseService: databaseService)
        self.inputHandler = InputHandler(gameState: gameState)
        self.progress = PuzzleProgressManager(store: progressStore)
        // ... etc
    }
}
```

### Backward Compatibility
- Keep all public APIs identical
- Use computed properties to expose sub-manager state
- Maintain @Published property names

## Benefits

1. **Separation of Concerns**
   - Each manager has single responsibility
   - Easier to understand and modify

2. **Testability**
   - Each component can be tested in isolation
   - Mock dependencies easily

3. **Maintainability**
   - Bugs easier to locate
   - Features easier to add

4. **Reusability**
   - Managers can be used in other contexts
   - Widget could use StatisticsManager

## Risk Mitigation

1. **Incremental Refactoring**
   - One manager at a time
   - Keep tests passing

2. **Feature Flag Option**
   - Could use flag to switch implementations
   - Allows A/B testing

3. **Performance Monitoring**
   - Profile before/after
   - Ensure no regression

## Success Metrics

- [x] PuzzleViewModel < 200 lines
- [x] All tests passing
- [x] No performance regression
- [x] Improved code coverage (target 80%)
- [x] Zero user-facing changes

---

## Phase 2.2: State Management Consolidation Design

### Current State Analysis

#### State Distribution Overview

##### 1. @AppStorage Usage (Direct UserDefaults)
Found in 11 files with the following properties:
- `encodingType` - PuzzleViewModel, GameStateManager
- `textSize` - SettingsViewModel  
- `soundFeedbackEnabled` - PuzzleCell
- `hapticFeedbackEnabled` - Multiple views (PuzzleView, KeyboardView, PuzzleCell, PuzzleCompletionView)
- `navBarLayout` - PuzzleView
- `autoSubmitLetter` - DailyPuzzleManager
- `lastCompletedDailyPuzzleID` - DailyPuzzleManager
- Various theme-related settings - ThemeManager

##### 2. UserSettings (Static Helper)
- `difficultyMode` 
- `navigationBarLayout`
- `selectedDifficulties`

##### 3. PuzzleViewModel State
- Game state (via GameStateManager)
- Progress tracking (via PuzzleProgressManager)
- Daily puzzle state (via DailyPuzzleManager)
- Author information
- Error handling state

##### 4. SettingsViewModel State
- Duplicates UserSettings properties as @Published
- Manages text size with both @AppStorage and @Published

### Key Issues Identified

1. **State Duplication**
   - `navigationBarLayout` exists in UserSettings AND as @AppStorage in views
   - Settings are accessed inconsistently (some via UserSettings, some via @AppStorage)
   - SettingsViewModel duplicates UserSettings properties

2. **Inconsistent Access Patterns**
   - Some components use @AppStorage directly
   - Some use UserSettings static methods
   - Some use SettingsViewModel @Published properties

3. **No Central Authority**
   - No single source of truth for settings
   - No consistent API for state access
   - Mixed storage mechanisms

4. **Notification Complexity**
   - Multiple notification patterns for state changes
   - Some use NotificationCenter, some use Combine

### Proposed Design

#### 1. StateManager Protocol
```swift
protocol StateManager {
    associatedtype StateType
    
    /// Current state value
    var currentValue: StateType { get }
    
    /// Publisher for state changes
    var publisher: AnyPublisher<StateType, Never> { get }
    
    /// Update state value
    func update(_ newValue: StateType)
    
    /// Reset to user-defined defaults
    func reset()
    
    /// Reset to factory defaults
    func resetToFactory()
}
```

#### 2. Centralized Settings Architecture

```
Configuration/
├── StateManagement/
│   ├── StateManager.swift (protocol)
│   ├── AppSettings.swift (central settings manager)
│   ├── PersistenceStrategy.swift (storage abstraction)
│   └── MigrationUtility.swift (handles version migration)
├── Settings/
│   └── SettingTypes.swift (enums and types for settings)
└── UserSettings.swift (kept for migration, forwards to AppSettings)
```

#### 3. AppSettings Structure
```swift
@MainActor
class AppSettings: ObservableObject {
    // MARK: - Game Settings
    @Published var encodingType: String = "Letters"
    @Published var difficultyMode: DifficultyMode = .normal
    @Published var selectedDifficulties: [String] = ["easy", "medium", "hard"]
    @Published var autoSubmitLetter: Bool = false
    
    // MARK: - UI Settings
    @Published var navigationBarLayout: NavigationBarLayout = .centerLayout
    @Published var textSize: TextSizeOption = .medium
    @Published var soundFeedbackEnabled: Bool = true
    @Published var hapticFeedbackEnabled: Bool = true
    
    // MARK: - Theme Settings
    @Published var darkModePreference: String = "system"
    @Published var highContrastMode: Bool = false
    
    // MARK: - Daily Puzzle State
    @Published var lastCompletedDailyPuzzleID: Int = 0
    
    // MARK: - Migration Support
    private static let settingsVersion = 1
    @Published private var migratedVersion: Int = 0
    
    // Singleton instance
    static let shared = AppSettings()
    
    // Persistence layer
    private let persistence: PersistenceStrategy
    
    init(persistence: PersistenceStrategy = UserDefaultsPersistence()) {
        self.persistence = persistence
        loadSettings()
        performMigrationIfNeeded()
        setupObservers()
    }
    
    // Migration from @AppStorage takes precedence
    private func performMigrationIfNeeded() {
        guard migratedVersion < Self.settingsVersion else { return }
        MigrationUtility.migrateFromAppStorage(to: self)
        migratedVersion = Self.settingsVersion
    }
}
```

#### 4. PersistenceStrategy (Simple Synchronous Design)
```swift
protocol PersistenceStrategy {
    func value<T>(for key: String, type: T.Type) -> T? where T: Codable
    func setValue<T>(_ value: T, for key: String) where T: Codable
    func removeValue(for key: String)
    func synchronize()
}

class UserDefaultsPersistence: PersistenceStrategy {
    private let defaults = UserDefaults.standard
    
    func value<T>(for key: String, type: T.Type) -> T? where T: Codable {
        // Simple synchronous implementation
    }
    // ... rest of implementation
}
```

### Migration Strategy

#### Phase A: Preparation (Current Phase 2.2)
1. Create new StateManager protocol
2. Implement AppSettings with backward compatibility
3. Create migration utilities (prioritize @AppStorage values)
4. Keep UserSettings as migration helper
5. Add unit tests (target 70-80% coverage for critical paths)

#### Phase B: Migration
1. Update ViewModels to use AppSettings
2. Replace @AppStorage with AppSettings.shared
3. Update SettingsViewModel to be a thin wrapper
4. Verify settings propagation

#### Phase C: Testing & Stabilization
1. User testing period
2. Monitor for any issues
3. Gather feedback on settings behavior

#### Phase D: Cleanup (After User Validation)
1. Mark UserSettings methods as deprecated
2. Plan removal for future release (2-3 versions later)
3. Remove duplicate state storage
4. Consolidate notification patterns

### State Access Patterns

#### For Views:
```swift
struct SomeView: View {
    @EnvironmentObject var settings: AppSettings
    
    var body: some View {
        Text("Size: \(settings.textSize.rawValue)")
    }
}
```

#### For ViewModels:
```swift
class SomeViewModel: ObservableObject {
    private let settings = AppSettings.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        settings.$encodingType
            .sink { [weak self] _ in
                self?.updateForNewEncoding()
            }
            .store(in: &cancellables)
    }
}
```

### Benefits

1. **Single Source of Truth**: All settings in one place
2. **Type Safety**: Strongly typed settings with no string keys
3. **Testability**: Easy to mock/inject for testing
4. **Migration Path**: Backward compatible during transition
5. **Performance**: Reduced redundant storage/observers
6. **Consistency**: One way to access/update settings

## Implementation Plan

### Task 1: Create Core Infrastructure (Day 1)
- [ ] Create StateManager protocol with reset() and resetToFactory()
- [ ] Create synchronous PersistenceStrategy protocol and UserDefaultsPersistence
- [ ] Create AppSettings class with basic properties
- [ ] Add migration utilities that prioritize @AppStorage values
- [ ] Implement version checking for future migrations

### Task 2: Implement Settings Categories (Day 1)
- [ ] Move all game settings to AppSettings
- [ ] Move all UI settings to AppSettings  
- [ ] Move theme settings to AppSettings
- [ ] Add computed properties for complex settings
- [ ] Keep UserSettings as forwarding layer

### Task 3: Update Core Components (Day 2)
- [ ] Update PuzzleViewModel to use AppSettings
- [ ] Update SettingsViewModel to use AppSettings
- [ ] Update GameStateManager for consistency
- [ ] Add AppSettings to environment
- [ ] Ensure @MainActor threading consistency

### Task 4: Migrate Views (Day 2)
- [ ] Replace @AppStorage in all views
- [ ] Update UserSettings references to forward to AppSettings
- [ ] Test all settings changes propagate correctly
- [ ] Verify no regressions

### Task 5: Testing & Documentation (Day 3)
- [ ] Write unit tests for AppSettings (70-80% coverage)
- [ ] Write migration tests
- [ ] Test state synchronization
- [ ] Add one integration test for settings flow
- [ ] Update CLAUDE.md with new patterns

## Success Criteria

1. All settings accessible through single AppSettings instance
2. No duplicate state storage
3. All existing functionality preserved
4. Settings changes propagate correctly to all observers
5. Zero crashes during migration
6. @AppStorage values take precedence during migration
7. Test coverage 70-80% for critical settings paths
8. UserSettings remains functional as migration helper

## Risk Mitigation

1. **Backward Compatibility**: Keep UserSettings during entire migration
2. **Gradual Migration**: Update one component at a time
3. **No Feature Flag**: Keep it simple for puzzle game
4. **Extensive Testing**: Test each migration step thoroughly
5. **Data Migration**: @AppStorage values take precedence
6. **Defer Deprecation**: Only deprecate UserSettings after user validation