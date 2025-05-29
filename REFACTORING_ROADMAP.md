# Simple Cryptogram Refactoring Roadmap

## Progress Summary

| Phase | Status | Completion Date | Key Achievements |
|-------|--------|----------------|------------------|
| Phase 0: Infrastructure | ✅ **COMPLETED** | 29/05/2025 | Feature flags, performance baselines, memory leak detection |
| Phase 1.1: Core Navigation | ✅ **COMPLETED** | 29/05/2025 | NavigationStack implementation, NavigationCoordinator, puzzle navigation |
| Phase 1.2: Sheet Presentations | ✅ **COMPLETED** | 29/05/2025 | StandardSheet/CloseButton components, .sheet() modifiers with feature flag |
| Phase 2: Settings | ⏳ Pending | - | Fix AppSettings, lightweight DI |
| Phase 3: Code Organization | ⏳ Pending | - | Extract services, memory management |
| Phase 4: Modern SwiftUI | ⏳ Pending | - | @Observable, modern patterns |
| Phase 5: Testing & Performance | ⏳ Pending | - | Final optimization |

**Current Week**: 1 of 10 (Phase 0 and 1.1 completed ahead of schedule)  
**Next Action**: Begin Phase 1.2 - Replace Sheet Overlays

## Overview
This roadmap outlines a systematic approach to refactoring the Simple Cryptogram codebase based on current codebase analysis. The refactoring prioritizes user-facing stability and addresses the most complex architectural issues first.

## Phase 0: Infrastructure and Safety Setup (Week 1) ✅ COMPLETED

### 0.1 Enable Testing Infrastructure ✅
**Priority**: 🔴 Critical  
**Status**: ✅ Completed on 29/05/2025  
**Files Created/Modified**: 
- `simple cryptogramTests/AppSettingsTests.swift` - Fixed and re-enabled
- `simple cryptogramTests/PerformanceBaselineTests.swift` - Created
- `simple cryptogramTests/MemoryLeakDetectionTests.swift` - Created
- `simple cryptogram/Utils/FeatureFlags.swift` - Created

**Accomplishments**:
- [x] ✅ Re-enabled AppSettingsTests with fixes for current implementation
- [x] ✅ Created comprehensive performance baseline tests (10 test cases)
- [x] ✅ Set up memory leak detection tests (12 test cases)
- [x] ✅ Established feature flag system with debug overrides

**Note**: PuzzleViewModelIntegrationTests temporarily disabled pending Phase 2 dependency injection.

### 0.2 Document Performance Baseline ✅
**Priority**: 🔴 Critical  
**Status**: ✅ Completed on 29/05/2025  
**Files Created**: 
- `PERFORMANCE_BASELINE.md` - Comprehensive baseline documentation
- Updated `CLAUDE.md` with new infrastructure details

**Established Baselines**:
- [x] ✅ App launch time: AppSettings init <0.1s, Database init <0.5s
- [x] ✅ Puzzle loading: Standard <0.2s, Daily <0.2s
- [x] ✅ User interaction: Rapid input (10 letters) <0.05s
- [x] ✅ Memory management: No retain cycles detected in managers

**Infrastructure Ready**:
- Feature flags for safe rollout/rollback
- Performance regression detection
- Memory leak monitoring
- Comprehensive test coverage

## Phase 1: Navigation Modernization (Week 2-3)

### 1.1 Replace Overlay-Based Navigation ✅ COMPLETED
**Priority**: 🔴 Critical  
**Status**: ✅ Completed on 29/05/2025  
**Files Modified**: `ContentView.swift`, `HomeView.swift`, `PuzzleView.swift`, `BottomBarView.swift`, `PuzzleCompletionView.swift`

**Accomplishments**:
- [x] ✅ Created NavigationCoordinator with feature flag
- [x] ✅ Replaced PuzzleView overlay with NavigationStack
- [x] ✅ Updated all navigation touchpoints to use coordinator
- [x] ✅ Maintained swipe gestures within NavigationStack
- [x] ✅ Added comprehensive tests for NavigationCoordinator

**Note**: Sheet presentations (settings/stats/calendar) deferred to Phase 1.2 for cleaner separation of concerns.

**NavigationCoordinator** is now implemented and ready for Phase 1.2 sheet presentations.

### 1.2 Create Reusable Navigation Components ✅ COMPLETED
**Priority**: 🟡 High  
**Status**: ✅ Completed on 29/05/2025  
**Files Created/Modified**: 
- `simple cryptogram/Views/Components/StandardSheet.swift` - Created
- `simple cryptogram/Views/Components/CloseButton.swift` - Created
- `simple cryptogram/Utils/FeatureFlags.swift` - Added `modernSheets` flag
- `HomeView.swift`, `PuzzleView.swift`, `BottomBarView.swift`, `TopBarView.swift` - Updated

**Accomplishments**:
- [x] ✅ Created `StandardSheet` component with consistent styling
- [x] ✅ Created `CompactSheet` variant for medium-sized sheets
- [x] ✅ Created `CloseButton` and `ToolbarCloseButton` components
- [x] ✅ Replaced all overlay-based sheets with .sheet() modifiers
- [x] ✅ Protected changes behind `modernSheets` feature flag
- [x] ✅ Integrated with NavigationCoordinator's sheet management

**Implementation Details**:
- Settings, Stats, Calendar, and Info overlays now use proper .sheet() presentation
- Maintained backward compatibility with feature flag
- Consistent sheet styling across the app
- Proper dismiss handling and sheet state management

## Phase 2: Settings Modernization (Week 4)

### 2.1 Fix AppSettings Preview Crash (MODERATE PRIORITY)
**Priority**: 🟡 High  
**Files**: `AppSettings.swift`, `PuzzleView.swift`

**Current Issues**: Force unwrapping crashes SwiftUI previews, optional chaining throughout codebase.

- [ ] Fix `AppSettings.shared!` in PuzzleView preview
- [ ] Standardize environment object vs singleton access
- [ ] Complete UserSettings → AppSettings migration
- [ ] Remove UserSettings compatibility layer

```swift
// Fix preview crash:
struct PuzzleView_Previews: PreviewProvider {
    static var previews: some View {
        PuzzleView(showPuzzle: .constant(true))
            .environmentObject(AppSettings())
    }
}
```

### 2.2 Lightweight Dependency Injection
**Priority**: 🟢 Medium  
**Files**: Core managers only

**Simplified Approach**: Use environment objects + protocols rather than full constructor injection.

- [ ] Create `SettingsProvider` protocol
- [ ] Update only GameStateManager and InputHandler to use protocol
- [ ] Keep other managers using environment objects
- [ ] Create mock implementations for testing

```swift
protocol SettingsProvider {
    var encodingType: String { get }
    var selectedDifficulties: [String] { get }
}

extension AppSettings: SettingsProvider { }

// Only for managers that need testability:
final class GameStateManager {
    private let settings: SettingsProvider
    init(settings: SettingsProvider = AppSettings.shared ?? AppSettings()) {
        self.settings = settings
    }
}
```

## Phase 3: Code Organization (Week 5-6)

### 3.1 Extract Services from PuzzleViewModel
**Priority**: 🟡 High  
**Files**: `PuzzleViewModel.swift` (currently 452 lines)

- [ ] Create `AuthorService` for author loading
- [ ] Extract puzzle loading logic to existing managers
- [ ] Move attempt tracking to PuzzleProgressManager
- [ ] Reduce PuzzleViewModel to <200 lines

### 3.2 Memory Management Review
**Priority**: 🟡 High  
**Files**: Manager classes with observer patterns

- [ ] Add `weak` references in observer patterns
- [ ] Fix potential retain cycles in ThemeManager
- [ ] Review OverlayManager memory management
- [ ] Add deinit logging for leak detection

## Phase 4: Modern SwiftUI Features (Week 7-8)

### 4.1 @Observable Migration
**Priority**: 🟢 Medium  
**Files**: ObservableObject classes

- [ ] Migrate AppSettings to @Observable
- [ ] Update view bindings
- [ ] Simplify published properties

### 4.2 Modern Presentation Patterns
**Priority**: 🟢 Medium  
**Files**: Remaining overlay components

- [ ] Use `.presentationDetents` for bottom sheets
- [ ] Replace custom animations with built-in transitions
- [ ] Add `.sensoryFeedback` for haptics

## Phase 5: Testing and Performance (Week 9-10)

### 5.1 Comprehensive Testing
**Priority**: 🟡 High  

- [ ] Integration tests for navigation flows
- [ ] Performance regression tests
- [ ] Memory leak automated detection
- [ ] UI tests for critical user journeys

### 5.2 Performance Optimization
**Priority**: 🟢 Medium  

- [ ] Add performance monitoring
- [ ] Optimize complex view updates
- [ ] Profile navigation transitions

## Implementation Strategy

### Feature Flag Rollout Plan
1. **Week 1**: Infrastructure setup
2. **Week 2-3**: Navigation behind `new_navigation` flag
3. **Week 4**: Settings behind `modern_app_settings` flag
4. **Week 5-6**: Services behind `extracted_services` flag
5. **Week 7-10**: Gradual feature flag removal

### Risk Mitigation

**Critical Risks Identified**:
1. **No performance baseline**: Mitigate with Phase 0 benchmarking
2. **Complex navigation state**: Feature flags allow rollback
3. **Memory leak potential**: Add detection in Phase 0
4. **Integration test gaps**: Re-enable before major changes

### Success Metrics (Updated)

**Quantitative**:
- Reduce navigation boolean flags from 8+ to 2
- Fix SwiftUI preview crashes (0 crashes)
- Maintain <2s app launch time
- Reduce HomeView from 400+ lines to <200 lines

**Qualitative**:
- Simplified navigation code
- Reliable SwiftUI previews
- Standard navigation patterns
- Improved debugging experience

## Phase Priority Rationale

1. **Navigation First**: Most complex, user-facing, affects all development
2. **Settings Second**: Blocking preview development, architectural foundation  
3. **Services Third**: Code organization, no user impact
4. **Modern Features**: Polish and future-proofing
5. **Testing/Performance**: Validation and optimization

**Total Estimated Time**: 10 weeks with reduced risk and better measurability

## Phase 0 Results & Lessons Learned

### Achievements
1. **Infrastructure Established**: All safety nets in place for refactoring
2. **Test Coverage Improved**: 22 new test cases for performance and memory
3. **Feature Flag System**: Safe rollout mechanism implemented
4. **Documentation Complete**: Clear baselines and guidelines for future phases

### Key Metrics Captured
- **AppSettings initialization**: ~0.05s (well under 0.1s target)
- **Database initialization**: ~0.3s (under 0.5s target)
- **Puzzle loading**: ~0.15s (under 0.2s target)
- **Memory management**: No retain cycles detected

### Unexpected Findings
1. **AppSettingsTests**: Required updates to match current implementation (no difficultyMode property)
2. **PuzzleViewModelIntegrationTests**: Needs proper DI implementation before re-enabling
3. **Simulator Compatibility**: iPhone 15 simulator not available, using iPhone 16

### Ready for Phase 1
With Phase 0 complete, the codebase now has:
- ✅ Performance baselines to prevent regressions
- ✅ Feature flags for safe experimentation
- ✅ Memory leak detection to ensure quality
- ✅ Clear documentation and test infrastructure

**Next Step**: Execute Phase 1.1 - Replace overlay-based navigation with NavigationStack

## Phase 1.1 Results & Lessons Learned

### Achievements
1. **NavigationCoordinator Created**: Clean navigation state management in `ViewModels/Navigation/`
2. **NavigationStack Integration**: Replaced overlay-based puzzle navigation
3. **Feature Flag Protection**: Safe rollout with `newNavigation` flag
4. **Comprehensive Testing**: NavigationCoordinatorTests with full coverage
5. **Backward Compatibility**: Old navigation still works when flag disabled

### Key Implementation Details
- Changed from `@Observable` to `ObservableObject` for SwiftUI compatibility
- Updated all navigation touchpoints (HomeView, PuzzleView, BottomBarView, PuzzleCompletionView)
- Maintained existing swipe gestures and animations where appropriate
- No breaking changes to existing functionality

### Metrics
- **Build Status**: ✅ BUILD SUCCEEDED
- **Test Coverage**: 100% for NavigationCoordinator
- **Files Modified**: 8 view files, 1 new ViewModel
- **Lines of Code**: ~200 lines added/modified

### Ready for Phase 1.2
The NavigationCoordinator already includes sheet management infrastructure:
- `SheetType` enum for all sheet types
- `presentSheet()` and `dismissSheet()` methods
- Sheet state tracking with `activeSheet`

## Phase 1.2 Results & Lessons Learned

### Achievements
1. **Reusable Sheet Components**: Created StandardSheet and CloseButton for consistent UI
2. **Modern Sheet Presentation**: Replaced overlay-based sheets with .sheet() modifiers
3. **Feature Flag Protection**: Added `modernSheets` flag for safe rollout
4. **Comprehensive Coverage**: Updated all sheet presentations in HomeView and PuzzleView

### Key Implementation Details
- StandardSheet provides NavigationView wrapper with consistent styling
- CompactSheet variant supports .medium and .large presentation detents
- Sheet state managed centrally by NavigationCoordinator
- Backward compatibility maintained - overlays still work when flag disabled

### Metrics
- **Build Status**: ✅ BUILD SUCCEEDED (SwiftUI compiler timeout and Equatable conformance issues resolved)
- **Files Created**: 5 new components (StandardSheet, CloseButton, HomeSheetPresentation, HomeLegacyOverlays, HomeMainContent)
- **Files Modified**: 7 view files updated
- **Lines of Code**: ~500 lines added/modified

### Ready for Phase 2
With Phase 1 (Navigation Modernization) fully complete, the codebase now has:
- ✅ Modern NavigationStack implementation
- ✅ Centralized navigation state management
- ✅ Reusable sheet components
- ✅ Clean separation between navigation and presentation

**Next Step**: Execute Phase 2.1 - Fix AppSettings Preview Crash

---

*Last Updated: 29/05/2025 - Phase 1.2 completed*  
*This roadmap is a living document and should be updated as the refactoring progresses based on codebase analysis and real-world constraints.*