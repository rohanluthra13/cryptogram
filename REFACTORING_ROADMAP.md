# Simple Cryptogram Refactoring Roadmap

## Overview
This roadmap outlines a systematic approach to refactoring the Simple Cryptogram codebase based on current codebase analysis. The refactoring prioritizes user-facing stability and addresses the most complex architectural issues first.

## Phase 0: Infrastructure and Safety Setup (Week 1)

### 0.1 Enable Testing Infrastructure
**Priority**: 🔴 Critical  
**Files**: Test files, new FeatureFlags system

- [ ] Re-enable disabled integration tests (AppSettingsTests, PuzzleViewModelIntegrationTests)
- [ ] Create performance baseline tests for critical paths
- [ ] Set up memory leak detection tests
- [ ] Establish build-time feature flag system

```swift
enum FeatureFlag: String, CaseIterable {
    case newNavigation = "new_navigation"
    case modernAppSettings = "modern_app_settings"
    case extractedServices = "extracted_services"
    
    var isEnabled: Bool {
        #if DEBUG
        return UserDefaults.standard.bool(forKey: "ff_\(rawValue)")
        #else
        return true // Production flags
        #endif
    }
}
```

### 0.2 Document Performance Baseline
**Priority**: 🔴 Critical  
**Files**: New performance documentation

- [ ] Measure app launch time
- [ ] Benchmark puzzle loading performance
- [ ] Profile memory usage patterns
- [ ] Document current overlay animation performance

## Phase 1: Navigation Modernization (Week 2-3)

### 1.1 Replace Overlay-Based Navigation (HIGHEST PRIORITY)
**Priority**: 🔴 Critical  
**Files**: `ContentView.swift`, `HomeView.swift`, `PuzzleView.swift`

**Current Issues**: Complex overlay management with 8+ boolean flags, custom swipe gestures, z-index management, code duplication across overlays.

- [ ] Create NavigationCoordinator with feature flag
- [ ] Replace PuzzleView overlay with NavigationLink
- [ ] Migrate settings/stats/calendar to sheet presentation
- [ ] Simplify swipe-to-exit using built-in navigation
- [ ] Remove OverlayZIndex enum and manual z-index management

```swift
@Observable
final class NavigationCoordinator {
    var puzzlePath = NavigationPath()
    var activeSheet: SheetType?
    var showPuzzle = false
    
    enum SheetType: Identifiable {
        case settings, statistics, calendar, info
        var id: String { String(describing: self) }
    }
}

// In HomeView - replace overlay with:
.sheet(item: $navigationCoordinator.activeSheet) { sheet in
    switch sheet {
    case .settings: SettingsContentView()
    case .statistics: StatsView()
    // etc
    }
}
```

### 1.2 Create Reusable Navigation Components
**Priority**: 🟡 High  
**Files**: New components in `Views/Components/`

- [ ] Extract `StandardSheet` component
- [ ] Create `CloseButton` component  
- [ ] Consolidate toolbar patterns
- [ ] Remove duplicate overlay code

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

---

*This roadmap is a living document and should be updated as the refactoring progresses based on codebase analysis and real-world constraints.*