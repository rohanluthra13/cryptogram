# Navigation Bar Layout Implementation Plan

## Overview
This plan outlines the steps to add configurable navigation bar layouts to the Cryptogram app. We'll create three layout options (Left, Center, Right) that users can select from the Settings overlay, initially keeping all three layouts identical to the current implementation. This establishes the foundation for future differentiation of the layouts.

## Step 1: Create NavigationBarLayout Enum
**File:** `simple cryptogram/Models/NavigationBarLayout.swift`

```swift
import Foundation

enum NavigationBarLayout: String, CaseIterable, Identifiable {
    case leftLayout
    case centerLayout  // Default/current layout
    case rightLayout
    
    var id: String { self.rawValue }
    
    var displayName: String {
        switch self {
        case .leftLayout: return "Left"
        case .centerLayout: return "Center"
        case .rightLayout: return "Right"
        }
    }
}
```

## Step 2: Update UserSettings
**File:** `simple cryptogram/Configuration/UserSettings.swift`

Add a new property to store the layout preference:

```swift
static let navigationBarLayoutKey = "navigationBarLayout"

static var navigationBarLayout: NavigationBarLayout {
    get {
        let storedValue = UserDefaults.standard.string(forKey: navigationBarLayoutKey) ?? NavigationBarLayout.centerLayout.rawValue
        return NavigationBarLayout(rawValue: storedValue) ?? .centerLayout
    }
    set {
        UserDefaults.standard.set(newValue.rawValue, forKey: navigationBarLayoutKey)
    }
}
```

## Step 3: Update SettingsViewModel
**File:** `simple cryptogram/ViewModels/SettingsViewModel.swift`

Add a property for the navigation bar layout and observe changes:

```swift
import Combine

@Published var selectedNavBarLayout: NavigationBarLayout = UserSettings.navigationBarLayout
private var navBarLayoutCancellable: AnyCancellable?

init() {
    // Existing code for difficulty mode...
    
    // Sink changes from the navigation bar layout property back to UserSettings
    navBarLayoutCancellable = $selectedNavBarLayout
        .dropFirst() // Don't write the initial value back
        .sink { newLayout in
            UserSettings.navigationBarLayout = newLayout
        }
}
```

## Step 4: Add Selection UI to SettingsContentView
**File:** `simple cryptogram/Views/Components/SettingsContentView.swift`

Add a new section under the "Appearance" section for navigation bar layout selection:

```swift
// After dark mode toggle and before end of VStack
Divider()
    .padding(.vertical, 10)

// Navigation bar layout section
Text("Navigation Bar Layout")
    .font(.subheadline)
    .foregroundColor(CryptogramTheme.Colors.text)
    .frame(maxWidth: .infinity, alignment: .center)
    .padding(.vertical, 5)

// Layout selection buttons
HStack {
    Spacer()
    
    // Left layout button
    Button(action: {
        settingsViewModel.selectedNavBarLayout = .leftLayout
    }) {
        Text("Left")
            .font(.footnote)
            .fontWeight(settingsViewModel.selectedNavBarLayout == .leftLayout ? .bold : .regular)
            .foregroundColor(settingsViewModel.selectedNavBarLayout == .leftLayout ?
                           CryptogramTheme.Colors.text :
                           CryptogramTheme.Colors.text.opacity(0.4))
    }
    .buttonStyle(PlainButtonStyle())
    .accessibilityLabel("Left navigation bar layout")
    .padding(.trailing, 6)
    
    // Center layout button
    Button(action: {
        settingsViewModel.selectedNavBarLayout = .centerLayout
    }) {
        Text("Center")
            .font(.footnote)
            .fontWeight(settingsViewModel.selectedNavBarLayout == .centerLayout ? .bold : .regular)
            .foregroundColor(settingsViewModel.selectedNavBarLayout == .centerLayout ?
                           CryptogramTheme.Colors.text :
                           CryptogramTheme.Colors.text.opacity(0.4))
    }
    .buttonStyle(PlainButtonStyle())
    .accessibilityLabel("Center navigation bar layout")
    .padding(.horizontal, 6)
    
    // Right layout button
    Button(action: {
        settingsViewModel.selectedNavBarLayout = .rightLayout
    }) {
        Text("Right")
            .font(.footnote)
            .fontWeight(settingsViewModel.selectedNavBarLayout == .rightLayout ? .bold : .regular)
            .foregroundColor(settingsViewModel.selectedNavBarLayout == .rightLayout ?
                           CryptogramTheme.Colors.text :
                           CryptogramTheme.Colors.text.opacity(0.4))
    }
    .buttonStyle(PlainButtonStyle())
    .accessibilityLabel("Right navigation bar layout")
    .padding(.leading, 6)
    
    Spacer()
}
```

## Step 5: Update NavigationBarView
**File:** `simple cryptogram/Views/Components/NavigationBarView.swift`

Add layout parameter and refactor the view to use a switch statement for different layouts:

```swift
// Add to existing parameters
var layout: NavigationBarLayout = .centerLayout

var body: some View {
    switch layout {
    case .leftLayout:
        leftLayoutView
    case .centerLayout:
        centerLayoutView
    case .rightLayout:
        rightLayoutView
    }
}

// Left layout (initially identical to current/center layout)
private var leftLayoutView: some View {
    HStack(spacing: 0) {
        // Left navigation button at the extreme edge
        Button(action: onMoveLeft) {
            Image(systemName: "chevron.left")
                .font(.title3)
                .frame(width: buttonSize, height: buttonSize)
                .foregroundColor(CryptogramTheme.Colors.text)
                .accessibilityLabel("Move Left")
        }
        .padding(.leading, 0)
        
        Spacer()
        
        // Center buttons group - conditionally shown
        if showCenterButtons {
            HStack(spacing: centerSpacing) {
                // Pause/Play button OR Try Again when failed
                if isFailed {
                    // Try Again button (replaces pause button when game is over)
                    Button(action: onTryAgain ?? onNextPuzzle) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.title3)
                            .frame(width: buttonSize, height: buttonSize)
                            .foregroundColor(CryptogramTheme.Colors.text)
                            .accessibilityLabel("Try Again")
                    }
                } else {
                    // Normal Pause/Play button
                    Button(action: onTogglePause) {
                        Image(systemName: isPaused ? "play" : "pause")
                            .font(.title3)
                            .frame(width: buttonSize, height: buttonSize)
                            .foregroundColor(CryptogramTheme.Colors.text)
                            .accessibilityLabel(isPaused ? "Resume" : "Pause")
                    }
                }
                
                // Next puzzle button - using circular arrows to suggest swap
                Button(action: onNextPuzzle) {
                    Image(systemName: "arrow.2.circlepath")
                        .font(.title3)
                        .frame(width: buttonSize, height: buttonSize)
                        .foregroundColor(CryptogramTheme.Colors.text)
                        .accessibilityLabel("New Puzzle")
                }
            }
        } else {
            // Empty space to maintain layout when center buttons are hidden
            Spacer()
        }
        
        Spacer()
        
        // Right navigation button at the extreme edge
        Button(action: onMoveRight) {
            Image(systemName: "chevron.right")
                .font(.title3)
                .frame(width: buttonSize, height: buttonSize)
                .foregroundColor(CryptogramTheme.Colors.text)
                .accessibilityLabel("Move Right")
        }
        .padding(.trailing, 0)
    }
    .padding(.top, 8)
    .padding(.bottom, 4)
    .frame(maxWidth: .infinity)
    .background(CryptogramTheme.Colors.background)
}

// Center layout (current implementation)
private var centerLayoutView: some View {
    // Same implementation as leftLayoutView for now
    leftLayoutView
}

// Right layout (initially identical to current/center layout)
private var rightLayoutView: some View {
    // Same implementation as leftLayoutView for now
    leftLayoutView
}
```

## Step 6: Update PuzzleView
**File:** `simple cryptogram/Views/PuzzleView.swift`

Update the NavigationBarView instantiation:

```swift
NavigationBarView(
    onMoveLeft: { viewModel.moveToAdjacentCell(direction: -1) },
    onMoveRight: { viewModel.moveToAdjacentCell(direction: 1) },
    onTogglePause: viewModel.togglePause,
    onNextPuzzle: { viewModel.refreshPuzzleWithCurrentSettings() },
    onTryAgain: { 
        viewModel.reset()
        // Re-apply difficulty settings to the same puzzle
        if let currentPuzzle = viewModel.currentPuzzle {
            viewModel.startNewPuzzle(puzzle: currentPuzzle)
        }
    },
    isPaused: viewModel.isPaused,
    isFailed: viewModel.isFailed,
    showCenterButtons: true,
    layout: UserSettings.navigationBarLayout
)
```

## Step 7: Update Preview in NavigationBarView
**File:** `simple cryptogram/Views/Components/NavigationBarView.swift`

Update the preview to include examples with different layouts:

```swift
#Preview {
    VStack(spacing: 20) {
        NavigationBarView(
            onMoveLeft: {},
            onMoveRight: {},
            onTogglePause: {},
            onNextPuzzle: {},
            isPaused: false,
            layout: .leftLayout
        )
        .previewDisplayName("Left Layout")
        
        NavigationBarView(
            onMoveLeft: {},
            onMoveRight: {},
            onTogglePause: {},
            onNextPuzzle: {},
            isPaused: false,
            layout: .centerLayout
        )
        .previewDisplayName("Center Layout")
        
        NavigationBarView(
            onMoveLeft: {},
            onMoveRight: {},
            onTogglePause: {},
            onNextPuzzle: {},
            isPaused: false,
            layout: .rightLayout
        )
        .previewDisplayName("Right Layout")
    }
}
```

## Future Enhancements (Post-Implementation)

1. **Unique Layout Designs:** Once the selection mechanism is working, customize each layout:
   - Left Layout: Navigation buttons on left, action buttons on right
   - Center Layout: Current design (navigation at edges, actions in center)
   - Right Layout: Navigation buttons on right, action buttons on left

2. **Visual Previews:** Add small preview icons in the settings to illustrate each layout option

3. **Animation:** Add smooth transitions when switching between layouts

4. **Additional Layouts:** Potentially add more specialized layouts (e.g., "Minimal" with just essential controls)

## Testing Plan

1. **Unit Tests:**
   - Verify UserSettings correctly stores and retrieves the layout preference
   - Ensure SettingsViewModel correctly syncs with UserSettings

2. **Integration Tests:**
   - Verify layout changes are reflected immediately when selected
   - Ensure layout preference persists across app restarts

3. **UI Tests:**
   - Test navigation functionality works correctly in all layouts
   - Verify accessibility labels are correct for all buttons in all layouts

## Implementation Notes

- This implementation follows modern SwiftUI patterns with proper separation of concerns
- The reactive pattern using Combine for settings synchronization ensures changes are immediately reflected
- The buttonSize and centerSpacing constants are already defined in NavigationBarView and can be reused
- The initial implementation keeps all layouts visually identical, establishing the infrastructure for future visual differentiation
- The implementation can be completed in a single pass as the changes are focused and well-defined
- Using an enum for layout options provides type safety and extensibility
- The structure allows for future customization without requiring significant refactoring
- The implementation maintains consistent styling with the rest of the settings UI
