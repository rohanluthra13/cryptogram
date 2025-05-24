# Technical Debt Roadmap

## Overview
This roadmap addresses critical and high-priority technical debt in the Simple Cryptogram codebase. The work is organized into phases to ensure stability while improving code quality.

## Phase 1: Critical Stability Issues (1-2 days)

### 1.1 Fix Memory Leaks in PuzzleViewModel ✅
**File**: `ViewModels/PuzzleViewModel.swift`
**Status**: COMPLETED (2025-01-24)
**Tasks**:
- [x] Add `deinit` method to remove all NotificationCenter observers
- [x] Review all closures and add `[weak self]` where needed
- [x] Test with Instruments to verify no retain cycles

**Changes Made**:
- Added `deinit` method that calls `NotificationCenter.default.removeObserver(self)`
- Fixed all DispatchQueue.async closures to use `[weak self]`
- Fixed Task closure in `loadAuthorIfNeeded` to use `[weak self]`
- Verified all DispatchQueue.asyncAfter closures already had proper weak references

### 1.2 Remove Force Unwrapping in LocalPuzzleProgressStore ✅
**File**: `Services/LocalPuzzleProgressStore.swift`
**Status**: COMPLETED (2025-01-24)
**Tasks**:
- [x] Replace force unwraps on lines 88, 89, 121-122 with safe unwrapping
- [x] Add fallback UUID generation for corrupted data
- [ ] Add unit tests for edge cases

**Changes Made**:
- Added `generateFallbackUUID(for:)` helper function that creates deterministic UUIDs from corrupted strings
- Replaced all force unwraps in `attempts(for:encodingType:)` method with safe unwrapping
- Replaced all force unwraps in `allAttempts()` method with safe unwrapping
- Added error logging when corrupted records are skipped
- Verified project builds successfully

### 1.3 Implement Proper Error Handling
**Files**: `Services/DatabaseService.swift`, `Services/LocalPuzzleProgressStore.swift`
**Tasks**:
- [ ] Create `DatabaseError` enum with user-friendly messages
- [ ] Replace print statements with proper error propagation
- [ ] Add error handling UI in ContentView
- [ ] Create error recovery strategies for common failures

## Phase 2: Architecture Refactoring (3-4 days)

### 2.1 Break Up PuzzleViewModel
**Current**: 867 lines of mixed responsibilities
**Target Structure**:
```
ViewModels/
├── PuzzleViewModel.swift (coordinator, <200 lines)
├── GameState/
│   ├── GameStateManager.swift
│   └── PuzzleSessionManager.swift
├── Progress/
│   ├── PuzzleProgressManager.swift
│   └── StatisticsManager.swift
└── Input/
    ├── InputHandler.swift
    └── HintManager.swift
```

**Tasks**:
- [ ] Extract game state logic to GameStateManager
- [ ] Move progress tracking to PuzzleProgressManager
- [ ] Create InputHandler for keyboard/selection logic
- [ ] Extract hint logic to HintManager
- [ ] Update PuzzleViewModel to coordinate between managers
- [ ] Add unit tests for each new component

### 2.2 Consolidate State Management
**Files**: `ViewModels/PuzzleViewModel.swift`, `Configuration/UserSettings.swift`
**Tasks**:
- [ ] Document which state belongs where (UserDefaults vs instance)
- [ ] Create StateManager protocol for consistent access
- [ ] Migrate all settings to UserSettings
- [ ] Remove redundant state storage
- [ ] Add state synchronization tests

### 2.3 Refactor NavigationBarView
**File**: `Views/Components/NavigationBarView.swift`
**Tasks**:
- [ ] Extract common layout components
- [ ] Create LayoutStrategy protocol
- [ ] Implement strategy pattern for three layouts
- [ ] Reduce code by ~60%
- [ ] Add preview tests for all layouts

## Phase 3: Performance & Testing (2-3 days)

### 3.1 Optimize Animation Performance
**Files**: `Views/Components/PuzzleCell.swift`, `Views/Components/WordAwarePuzzleGrid.swift`
**Tasks**:
- [ ] Audit all animations for overlap
- [ ] Implement animation coordinator
- [ ] Use `animation(_:value:)` instead of `.animation()`
- [ ] Add frame rate monitoring in debug builds
- [ ] Test on iPhone 8/SE for performance baseline

### 3.2 Establish Test Infrastructure
**Tasks**:
- [ ] Set up test targets if missing
- [ ] Add testing utilities and mocks
- [ ] Create test data builders
- [ ] Set up CI/CD test automation

### 3.3 Write Core Test Suites
**Priority Test Areas**:
```
Tests/
├── ViewModels/
│   ├── PuzzleViewModelTests.swift
│   ├── GameStateManagerTests.swift
│   └── SettingsViewModelTests.swift
├── Services/
│   ├── DatabaseServiceTests.swift
│   └── LocalPuzzleProgressStoreTests.swift
├── Models/
│   ├── PuzzleTests.swift
│   └── PuzzleAttemptTests.swift
└── Integration/
    ├── PuzzleCompletionFlowTests.swift
    └── DailyPuzzleTests.swift
```

**Coverage Goals**:
- [ ] 80% coverage for ViewModels
- [ ] 90% coverage for Services
- [ ] 100% coverage for Models
- [ ] Critical user flows covered by integration tests

## Implementation Strategy

### Week 1: Stability
- Days 1-2: Complete Phase 1 (Critical Issues)
- Day 3: Begin Phase 2.1 (PuzzleViewModel refactoring)

### Week 2: Architecture
- Days 4-5: Complete Phase 2.1
- Days 6-7: Complete Phase 2.2 & 2.3

### Week 3: Quality
- Days 8-9: Complete Phase 3.1 (Performance)
- Days 10-12: Complete Phase 3.2 & 3.3 (Testing)

## Success Criteria

### Phase 1
- [ ] No memory leaks detected in Instruments
- [ ] Zero crashes from force unwrapping
- [ ] All database errors handled gracefully

### Phase 2
- [ ] PuzzleViewModel under 200 lines
- [ ] All state management consistent
- [ ] NavigationBarView code reduced by 60%

### Phase 3
- [ ] Smooth 60fps on iPhone 8
- [ ] 80% overall test coverage
- [ ] All critical paths tested

## Risk Mitigation

1. **Feature Freeze**: No new features during refactoring
2. **Incremental Changes**: Small, testable commits
3. **Backward Compatibility**: Maintain all existing functionality
4. **User Testing**: Beta test after each phase

## Post-Refactoring Benefits

1. **Maintainability**: Easier to add new features
2. **Reliability**: Fewer crashes and bugs
3. **Performance**: Better experience on older devices
4. **Testability**: Confidence in future changes
5. **Developer Experience**: Cleaner, more intuitive codebase

## Notes

- Each task should be a separate commit
- Run full test suite after each phase
- Document any architectural decisions
- Keep CLAUDE.md updated with new patterns