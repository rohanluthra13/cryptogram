# Phase 2.1: PuzzleViewModel Refactoring Design

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

- [ ] PuzzleViewModel < 200 lines
- [ ] All tests passing
- [ ] No performance regression
- [ ] Improved code coverage (target 80%)
- [ ] Zero user-facing changes