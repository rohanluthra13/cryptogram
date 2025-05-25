# Phase 2.3: NavigationBarView Refactoring Design

## Current State Analysis

### File Statistics
- **Current Lines**: 271 lines
- **Target**: ~108 lines (60% reduction)
- **Code Duplication**: ~75% (massive duplication across 3 layout views)

### Current Issues
1. **Massive Code Duplication**: Each layout view (left/center/right) contains nearly identical button creation code
2. **No Abstraction**: Direct button creation repeated 6 times (2 buttons × 3 layouts)
3. **Hardcoded Layout Logic**: Each layout manually positions buttons with HStack/Spacer
4. **Repeated Styling**: Button styling (font, frame, color) duplicated everywhere
5. **Conditional Logic Duplication**: isFailed check repeated in all 3 layouts

### Layout Patterns
- **Left Layout**: Navigation arrows left, action buttons right
- **Center Layout**: Left arrow far left, action buttons center, right arrow far right
- **Right Layout**: Action buttons left, navigation arrows right

## Proposed Architecture

### 1. Strategy Pattern Implementation

```swift
protocol NavigationBarLayoutStrategy {
    func buildLayout(
        navigationButtons: NavigationButtonGroup,
        actionButtons: ActionButtonGroup,
        configuration: LayoutConfiguration
    ) -> AnyView
}

struct LeftLayoutStrategy: NavigationBarLayoutStrategy { }
struct CenterLayoutStrategy: NavigationBarLayoutStrategy { }
struct RightLayoutStrategy: NavigationBarLayoutStrategy { }
```

### 2. Component Extraction

```swift
// Reusable button components
struct NavigationButton: View {
    let direction: Direction
    let action: () -> Void
    
    enum Direction {
        case left, right
        
        var icon: String {
            switch self {
            case .left: return "chevron.left"
            case .right: return "chevron.right"
            }
        }
        
        var label: String {
            switch self {
            case .left: return "Move Left"
            case .right: return "Move Right"
            }
        }
    }
}

struct ActionButton: View {
    let type: ActionType
    let action: () -> Void
    
    enum ActionType {
        case pause(isPaused: Bool)
        case tryAgain
        case nextPuzzle
        
        var icon: String {
            switch self {
            case .pause(let isPaused): return isPaused ? "play" : "pause"
            case .tryAgain: return "arrow.counterclockwise"
            case .nextPuzzle: return "arrow.2.circlepath"
            }
        }
        
        var label: String {
            switch self {
            case .pause(let isPaused): return isPaused ? "Resume" : "Pause"
            case .tryAgain: return "Try Again"
            case .nextPuzzle: return "New Puzzle"
            }
        }
    }
}
```

### 3. Button Group Abstractions

```swift
struct NavigationButtonGroup: View {
    let onMoveLeft: () -> Void
    let onMoveRight: () -> Void
    let spacing: CGFloat = 16
    
    var body: some View {
        HStack(spacing: spacing) {
            NavigationButton(direction: .left, action: onMoveLeft)
            NavigationButton(direction: .right, action: onMoveRight)
        }
    }
}

struct ActionButtonGroup: View {
    let isPaused: Bool
    let isFailed: Bool
    let onTogglePause: () -> Void
    let onNextPuzzle: () -> Void
    let onTryAgain: (() -> Void)?
    let spacing: CGFloat = 16
    
    var body: some View {
        HStack(spacing: spacing) {
            if isFailed {
                ActionButton(type: .tryAgain, action: onTryAgain ?? onNextPuzzle)
            } else {
                ActionButton(type: .pause(isPaused: isPaused), action: onTogglePause)
            }
            ActionButton(type: .nextPuzzle, action: onNextPuzzle)
        }
    }
}
```

### 4. Layout Configuration

```swift
struct LayoutConfiguration {
    let buttonSize: CGFloat = 44
    let centerSpacing: CGFloat = 16
    let edgePadding: CGFloat = 10
    let groupPadding: CGFloat = 60
    let showCenterButtons: Bool
}
```

### 5. Refactored NavigationBarView

```swift
struct NavigationBarView: View {
    // Callbacks
    var onMoveLeft: () -> Void
    var onMoveRight: () -> Void
    var onTogglePause: () -> Void
    var onNextPuzzle: () -> Void
    var onTryAgain: (() -> Void)? = nil
    
    // State
    var isPaused: Bool
    var isFailed: Bool = false
    var showCenterButtons: Bool = true
    
    // Layout
    @Binding var layout: NavigationBarLayout
    
    // Strategy factory
    private var layoutStrategy: NavigationBarLayoutStrategy {
        switch layout {
        case .leftLayout: return LeftLayoutStrategy()
        case .centerLayout: return CenterLayoutStrategy()
        case .rightLayout: return RightLayoutStrategy()
        }
    }
    
    var body: some View {
        layoutStrategy.buildLayout(
            navigationButtons: NavigationButtonGroup(
                onMoveLeft: onMoveLeft,
                onMoveRight: onMoveRight
            ),
            actionButtons: ActionButtonGroup(
                isPaused: isPaused,
                isFailed: isFailed,
                onTogglePause: onTogglePause,
                onNextPuzzle: onNextPuzzle,
                onTryAgain: onTryAgain
            ),
            configuration: LayoutConfiguration(
                showCenterButtons: showCenterButtons
            )
        )
        .modifier(NavigationBarStyle())
    }
}

// Common styling
struct NavigationBarStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(.top, 8)
            .padding(.bottom, 4)
            .frame(maxWidth: .infinity)
    }
}
```

## Implementation Plan

### Step 1: Create Base Components (20 mins)
1. Create `NavigationButton` component
2. Create `ActionButton` component
3. Extract common button styling to `NavigationBarButtonStyle`

### Step 2: Create Button Groups (15 mins)
1. Implement `NavigationButtonGroup`
2. Implement `ActionButtonGroup`
3. Add configuration support

### Step 3: Implement Layout Strategies (30 mins)
1. Define `NavigationBarLayoutStrategy` protocol
2. Implement `LeftLayoutStrategy`
3. Implement `CenterLayoutStrategy`
4. Implement `RightLayoutStrategy`

### Step 4: Refactor Main View (15 mins)
1. Update `NavigationBarView` to use strategies
2. Remove duplicated code
3. Add layout configuration

### Step 5: Testing & Polish (20 mins)
1. Update preview provider with all layouts
2. Test all button states (paused, failed, etc.)
3. Verify accessibility labels
4. Performance testing

## Expected Benefits

### Code Reduction
- **Before**: 271 lines
- **After**: ~108 lines (60% reduction)
- **Removed**: 163 lines of duplicated code

### Maintainability Improvements
1. **Single Source of Truth**: Button styling defined once
2. **Easy Layout Changes**: Add new layouts by implementing strategy
3. **Testable Components**: Each piece can be tested in isolation
4. **Clear Separation**: Layout logic separate from button creation

### Architecture Benefits
1. **Strategy Pattern**: Clean separation of layout algorithms
2. **Composition**: Small, reusable components
3. **Type Safety**: Enums for button types prevent errors
4. **Flexibility**: Easy to add new button types or layouts

## Risks & Mitigations

### Risk 1: Breaking Existing Functionality
**Mitigation**: Incremental refactoring with tests at each step

### Risk 2: Performance Impact
**Mitigation**: Use @ViewBuilder and lightweight view composition

### Risk 3: Accessibility Regression
**Mitigation**: Ensure all accessibility labels are preserved

## Success Criteria

1. ✅ Code reduced by 60% (from 271 to ~108 lines)
2. ✅ All three layouts function identically to current implementation
3. ✅ No visual or behavioral changes
4. ✅ All accessibility features preserved
5. ✅ Preview provider shows all layout variations
6. ✅ Easy to add a 4th layout if needed

## Alternative Approaches Considered

### 1. View Builders with Conditionals
- **Pros**: Simpler, less abstraction
- **Cons**: Still has duplication, harder to extend

### 2. SwiftUI Layout Protocol
- **Pros**: More "SwiftUI native"
- **Cons**: Overkill for this use case, iOS 16+ only

### 3. Configuration Object Only
- **Pros**: Very simple
- **Cons**: Doesn't eliminate all duplication

## Decision
Use Strategy Pattern with component extraction for maximum code reuse and flexibility while maintaining simplicity.