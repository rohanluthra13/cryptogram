# Phase 2.2: State Management Consolidation Design

## Current State Analysis

### State Distribution Overview

#### 1. @AppStorage Usage (Direct UserDefaults)
Found in 11 files with the following properties:
- `encodingType` - PuzzleViewModel, GameStateManager
- `textSize` - SettingsViewModel  
- `soundFeedbackEnabled` - PuzzleCell
- `hapticFeedbackEnabled` - Multiple views (PuzzleView, KeyboardView, PuzzleCell, PuzzleCompletionView)
- `navBarLayout` - PuzzleView
- `autoSubmitLetter` - DailyPuzzleManager
- `lastCompletedDailyPuzzleID` - DailyPuzzleManager
- Various theme-related settings - ThemeManager

#### 2. UserSettings (Static Helper)
- `difficultyMode` 
- `navigationBarLayout`
- `selectedDifficulties`

#### 3. PuzzleViewModel State
- Game state (via GameStateManager)
- Progress tracking (via PuzzleProgressManager)
- Daily puzzle state (via DailyPuzzleManager)
- Author information
- Error handling state

#### 4. SettingsViewModel State
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

## Proposed Design

### 1. StateManager Protocol
```swift
protocol StateManager {
    associatedtype StateType
    
    /// Current state value
    var currentValue: StateType { get }
    
    /// Publisher for state changes
    var publisher: AnyPublisher<StateType, Never> { get }
    
    /// Update state value
    func update(_ newValue: StateType)
    
    /// Reset to default value
    func reset()
}
```

### 2. Centralized Settings Architecture

```
Configuration/
├── StateManagement/
│   ├── StateManager.swift (protocol)
│   ├── SettingsStateManager.swift (central settings manager)
│   ├── GameStateManager.swift (existing, conforms to protocol)
│   └── PersistenceStrategy.swift (storage abstraction)
├── Settings/
│   ├── AppSettings.swift (all app-wide settings)
│   ├── GameSettings.swift (game-specific settings)
│   └── UISettings.swift (UI preferences)
└── UserSettings.swift (deprecated, migration helper)
```

### 3. AppSettings Structure
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
    
    // Singleton instance
    static let shared = AppSettings()
    
    // Persistence layer
    private let persistence: PersistenceStrategy
    
    init(persistence: PersistenceStrategy = UserDefaultsPersistence()) {
        self.persistence = persistence
        loadSettings()
        setupObservers()
    }
}
```

### 4. Migration Strategy

#### Phase A: Preparation (Current Phase 2.2)
1. Create new StateManager protocol
2. Implement AppSettings with backward compatibility
3. Create migration utilities
4. Add comprehensive tests

#### Phase B: Migration
1. Update ViewModels to use AppSettings
2. Replace @AppStorage with AppSettings.shared
3. Deprecate UserSettings static methods
4. Update SettingsViewModel to be a thin wrapper

#### Phase C: Cleanup
1. Remove deprecated UserSettings
2. Remove duplicate state storage
3. Consolidate notification patterns

### 5. State Access Patterns

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

### 6. Benefits

1. **Single Source of Truth**: All settings in one place
2. **Type Safety**: Strongly typed settings with no string keys
3. **Testability**: Easy to mock/inject for testing
4. **Migration Path**: Backward compatible during transition
5. **Performance**: Reduced redundant storage/observers
6. **Consistency**: One way to access/update settings

## Implementation Plan

### Task 1: Create Core Infrastructure (Day 1)
- [ ] Create StateManager protocol
- [ ] Create PersistenceStrategy protocol and UserDefaultsPersistence
- [ ] Create AppSettings class with basic properties
- [ ] Add migration utilities for existing @AppStorage

### Task 2: Implement Settings Categories (Day 1)
- [ ] Move all game settings to AppSettings
- [ ] Move all UI settings to AppSettings  
- [ ] Move theme settings to AppSettings
- [ ] Add computed properties for complex settings

### Task 3: Update Core Components (Day 2)
- [ ] Update PuzzleViewModel to use AppSettings
- [ ] Update SettingsViewModel to use AppSettings
- [ ] Update GameStateManager for consistency
- [ ] Add AppSettings to environment

### Task 4: Migrate Views (Day 2)
- [ ] Replace @AppStorage in all views
- [ ] Update UserSettings references
- [ ] Test all settings changes propagate correctly
- [ ] Verify no regressions

### Task 5: Testing & Documentation (Day 3)
- [ ] Write unit tests for AppSettings
- [ ] Write migration tests
- [ ] Test state synchronization
- [ ] Update CLAUDE.md with new patterns

## Success Criteria

1. All settings accessible through single AppSettings instance
2. No duplicate state storage
3. All existing functionality preserved
4. Settings changes propagate correctly to all observers
5. Zero crashes during migration
6. Improved app launch time (fewer observers)
7. Test coverage > 90% for settings management

## Risk Mitigation

1. **Backward Compatibility**: Keep UserSettings during migration
2. **Gradual Migration**: Update one component at a time
3. **Feature Flag**: Add toggle to revert to old system if needed
4. **Extensive Testing**: Test each migration step thoroughly
5. **Data Migration**: Ensure all existing settings preserved