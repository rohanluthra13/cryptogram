# Navigation Refactoring Roadmap

## Executive Summary

The current navigation system is a hybrid of legacy and modern approaches, causing complexity and bugs particularly in the completion view flow. This roadmap outlines a phased approach to refactor the navigation system, starting with the problematic completion views and expanding to a comprehensive navigation overhaul.

## Current State Analysis

### Architecture Issues

1. **Multiple Navigation Systems**
   - Legacy: State variables + NotificationCenter
   - Modern: NavigationStack with NavigationCoordinator
   - Hybrid: Feature flag switches between systems
   - Result: Complex, fragile navigation with timing dependencies

2. **Overlay-Based Presentation**
   - All modals use custom ZStack overlays (now the only system after sheet removal)
   - Overlays work well but have state management complexity
   - Completion views use notification-based navigation with timing issues
   - Daily vs regular completion handled with separate boolean states

3. **State Management Problems**
   - Views handle both presentation and business logic
   - Navigation state scattered across multiple components
   - Circular dependencies between views and state
   - No clear separation of concerns

4. **Technical Debt**
   - Code duplication across navigation paths
   - Inconsistent patterns for similar functionality
   - Complex timing-based navigation flows
   - Hard to test and maintain

### Impact Assessment

**High Risk Areas:**
- Daily puzzle completion navigation (currently broken - completion view reappears)
- Notification-based navigation with timing dependencies
- State synchronization between overlays and parent views
- Race conditions in overlay dismiss/navigation sequences

**Low Risk Areas:**
- Home view main navigation buttons
- Settings/Stats overlay presentation
- Regular puzzle completion flow

## Refactoring Strategy

### Phase 1: Fix Completion Views (1-2 days)
**Goal:** Stabilize daily puzzle completion navigation by improving overlay-based system

**Tasks:**
1. Remove notification-based navigation for completion flows
2. Implement direct navigation from completion overlay to home
3. Fix state management issues causing completion view to reappear
4. Unify completion view states (single enum instead of two booleans)
5. Remove timing dependencies and animation delays

**Implementation:**
```swift
// In PuzzleCompletionView.swift
func goHome() {
    // Direct navigation without notifications
    withAnimation(.easeOut(duration: 0.3)) {
        showCompletionView = false
        if FeatureFlag.newNavigation.isEnabled {
            navigationCoordinator.navigateToHome()
        }
    }
}

// In PuzzleView.swift
enum CompletionState {
    case none
    case regular(Puzzle, PuzzleStats)
    case daily(Puzzle, PuzzleStats)
}
@State private var completionState: CompletionState = .none
```

**Benefits:**
- Fixes immediate navigation bugs
- No timing dependencies or race conditions
- Cleaner state management
- Consistent overlay behavior

**Risks:**
- Need to ensure overlay animations remain smooth
- Must properly clean up state on navigation

### Phase 2: Unify Navigation System (3-4 days)
**Goal:** Remove legacy navigation, use NavigationStack exclusively

**Tasks:**
1. Remove FeatureFlag.newNavigation checks
2. Delete legacy navigation code
3. Update all navigation to use NavigationCoordinator
4. Simplify NavigationCoordinator API
5. Remove notification-based navigation

**Implementation:**
```swift
// Simplified NavigationCoordinator
class NavigationCoordinator: ObservableObject {
    @Published var path = NavigationPath()
    
    func navigate(to destination: NavigationDestination) {
        path.append(destination)
    }
    
    func popToRoot() {
        path.removeLast(path.count)
    }
}

enum NavigationDestination: Hashable {
    case puzzle(Puzzle)
    case dailyPuzzleCompletion(Puzzle, PuzzleStats)
    case puzzleCompletion(Puzzle, PuzzleStats)
}
```

**Benefits:**
- Single source of truth for navigation
- Predictable navigation behavior
- Easier to test and debug
- Type-safe navigation

**Risks:**
- Breaking changes for users mid-session
- Need thorough testing of all navigation paths

### Phase 3: Optimize Overlay System (2-3 days)
**Goal:** Improve and standardize the overlay presentation system

**Tasks:**
1. Create unified overlay manager for all modal presentations
2. Standardize overlay animations and transitions
3. Implement proper state cleanup on overlay dismissal
4. Add overlay presentation tests
5. Document overlay patterns for consistency

**Implementation:**
```swift
// Enhanced OverlayManager
enum OverlayType {
    case settings
    case stats
    case calendar
    case info
    case completion(CompletionType)
}

class OverlayManager: ObservableObject {
    @Published var activeOverlay: OverlayType?
    @Published var overlayQueue: [OverlayType] = []
    
    func present(_ overlay: OverlayType) {
        withAnimation(.easeIn(duration: 0.3)) {
            activeOverlay = overlay
        }
    }
    
    func dismiss(completion: (() -> Void)? = nil) {
        withAnimation(.easeOut(duration: 0.3)) {
            activeOverlay = nil
        }
        completion?()
    }
}
```

**Benefits:**
- Consistent overlay behavior across app
- Centralized state management
- Better testing capabilities
- Predictable animations

**Risks:**
- Need to migrate existing overlay logic
- Must maintain current UX during refactor

### Phase 4: State Management Refactor (3-4 days)
**Goal:** Separate navigation from business logic

**Tasks:**
1. Create NavigationState object for UI state
2. Move navigation logic out of views
3. Create view-specific ViewModels with minimal scope
4. Implement proper data flow patterns

**Implementation:**
```swift
// NavigationState.swift
@Observable
class NavigationState {
    var currentScreen: Screen = .home
    var presentedSheet: Sheet?
    var activeOverlay: Overlay?
    
    func navigateTo(_ screen: Screen) { }
    func present(_ sheet: Sheet) { }
    func dismiss() { }
}

// PuzzleCompletionViewModel.swift
class PuzzleCompletionViewModel: ObservableObject {
    let puzzle: Puzzle
    let stats: PuzzleStats
    
    func navigateHome() {
        // Just navigation, no state reset
        navigationState.navigateTo(.home)
    }
}
```

**Benefits:**
- Clear separation of concerns
- Views become truly declarative
- Easier to test business logic
- Reduced coupling

**Risks:**
- Major architectural change
- Need to update all views
- Potential for regression bugs

### Phase 5: Optimization & Polish (2-3 days)
**Goal:** Improve performance and user experience

**Tasks:**
1. Add navigation animations
2. Implement deep linking support
3. Add navigation persistence
4. Performance optimization
5. Comprehensive testing

**Benefits:**
- Better user experience
- Improved app performance
- Future-proof architecture

## Migration Plan

### Week 1: Phase 1 + Phase 2
- Day 1-2: Implement Phase 1 (Completion Views)
- Day 3-5: Implement Phase 2 (Unify Navigation)
- Deploy with feature flag for testing

### Week 2: Phase 3 + Phase 4
- Day 1-3: Implement Phase 3 (Convert Overlays)
- Day 4-5: Begin Phase 4 (State Management)

### Week 3: Phase 4 + Phase 5
- Day 1-2: Complete Phase 4
- Day 3-5: Implement Phase 5 (Optimization)
- Full testing and bug fixes

## Testing Strategy

1. **Unit Tests**
   - NavigationCoordinator logic
   - State management
   - View model navigation methods

2. **Integration Tests**
   - Full navigation flows
   - State preservation
   - Deep linking

3. **UI Tests**
   - User navigation paths
   - Edge cases (backgrounding, rotation)
   - Performance benchmarks

## Rollback Plan

Each phase can be feature-flagged:
```swift
enum NavigationFeatureFlag {
    case completionViewRefactor
    case unifiedNavigation
    case navigationDestinations
    case stateManagementRefactor
}
```

## Success Metrics

1. **Code Quality**
   - Reduced code duplication (target: 50% reduction)
   - Simplified navigation logic (remove 80% of notifications)
   - Better testability (90% navigation code coverage)

2. **Performance**
   - Faster navigation transitions
   - Reduced memory usage
   - No timing-based bugs

3. **Developer Experience**
   - Clear navigation patterns
   - Easy to add new screens
   - Predictable behavior

## Recommendations

1. **Start with Phase 1** - Fixes immediate bugs with minimal risk
2. **Feature flag each phase** - Allow gradual rollout and easy rollback
3. **Comprehensive testing** - Each phase needs thorough testing before proceeding
4. **Consider expanding scope** - The navigation issues reflect broader architectural problems that should be addressed

## Next Steps

1. Review and approve this roadmap
2. Create detailed technical specifications for Phase 1
3. Set up feature flags and testing infrastructure
4. Begin Phase 1 implementation

## Alternative Approach: Minimal Fix

If a full refactor is not feasible, consider:
1. Keep current overlay architecture
2. Fix completion view navigation by:
   - Removing notification delays
   - Adding proper state cleanup
   - Direct navigation calls
3. Document overlay patterns for consistency
4. Plan broader refactor for future major version

This approach maintains the current overlay system while fixing critical bugs.