# Remove Sheet Modifiers Design Document

## Overview
This document outlines the plan to completely remove all sheet-based presentation code from the Simple Cryptogram app, committing fully to the overlay-based presentation system.

## Motivation
- The app currently has two competing presentation systems: modern sheets and legacy overlays
- Even with `modernSheets` feature flag disabled, sheet modifiers in the view hierarchy may still interfere
- Overlays are still sliding up from bottom, suggesting sheet modifiers are taking precedence
- Maintaining two systems increases complexity and potential for bugs

## Components to Remove

### 1. View Modifiers

#### HomeView.swift
- **Line 210**: Remove `.homeSheetPresentation(puzzleOpenedFromCalendar: $puzzleOpenedFromCalendar)`
- This modifier adds sheet presentation capability even when not used

#### PuzzleView.swift
- **Lines 107-145**: Remove entire `.sheet()` modifier block
- This includes all the switch cases for different sheet types

### 2. Files to Delete

#### /Views/Components/HomeSheetPresentation.swift
- Entire file can be deleted
- Contains `HomeSheetPresentation` ViewModifier and extension

#### /Views/Components/StandardSheet.swift
- Entire file can be deleted
- Contains `StandardSheet` and `CompactSheet` views
- Only used for sheet presentations

### 3. NavigationCoordinator Cleanup

#### /ViewModels/Navigation/NavigationCoordinator.swift
Need to remove:
- `@Published var activeSheet: SheetType?` property
- `enum SheetType` definition
- `presentSheet(_:)` method
- `dismissSheet()` method
- Any other sheet-related logic

Keep:
- Navigation path management
- Puzzle navigation methods
- Other non-sheet navigation logic

### 4. Feature Flag Cleanup

#### /Utils/FeatureFlags.swift
- Remove `case modernSheets = "modern_sheets"` from enum
- Remove all references to `modernSheets` in the `isEnabled` computed property
- Update any documentation mentioning modern sheets

### 5. Code References to Clean

Search and remove all occurrences of:
- `FeatureFlag.modernSheets.isEnabled`
- `navigationCoordinator.presentSheet(`
- `navigationCoordinator.dismissSheet()`
- `navigationCoordinator.activeSheet`

These appear in:
- HomeView.swift (multiple button actions)
- PuzzleView.swift (button actions)
- Any other views that check for modern sheets

## Implementation Steps

### Phase 1: Remove Sheet Modifiers
1. Remove `.homeSheetPresentation()` from HomeView
2. Remove `.sheet()` modifier from PuzzleView
3. Test that overlays still function

### Phase 2: Clean NavigationCoordinator
1. Remove all sheet-related properties and methods
2. Update any views that reference these properties
3. Ensure navigation still works for puzzle selection

### Phase 3: Delete Unused Files
1. Delete HomeSheetPresentation.swift
2. Delete StandardSheet.swift
3. Remove modernSheets from FeatureFlags

### Phase 4: Update Button Actions
1. Find all button actions that check `FeatureFlag.modernSheets.isEnabled`
2. Remove the conditional checks
3. Ensure they only use the legacy overlay approach

### Phase 5: Testing
1. Verify all overlays (settings, stats, calendar, info) work correctly
2. Confirm overlays use fade transition, not slide-up
3. Test on both HomeView and PuzzleView
4. Test on both light and dark themes

## Expected Outcomes

### Before
```swift
Button(action: {
    if FeatureFlag.modernSheets.isEnabled {
        navigationCoordinator.presentSheet(.settings)
    } else {
        showSettings.toggle()
    }
})
```

### After
```swift
Button(action: {
    showSettings.toggle()
})
```

## Benefits
1. **Simpler codebase**: Only one presentation system to maintain
2. **Predictable behavior**: No conflicts between presentation systems
3. **Easier debugging**: Clear which system is responsible for presentations
4. **Reduced bundle size**: Less code to compile and ship
5. **Better performance**: No unnecessary view modifiers or state management

## Risks and Mitigation
- **Risk**: Accidentally breaking overlay functionality
  - **Mitigation**: Thorough testing of each overlay after changes
  
- **Risk**: Missing some sheet references
  - **Mitigation**: Use global search for all sheet-related terms

## Future Considerations
- Once sheet modifiers are removed, the overlay system becomes the permanent solution
- Any future presentation needs should use the overlay system
- Consider documenting the overlay system for future developers

## Verification Checklist
- [x] All `.sheet()` modifiers removed
- [x] HomeSheetPresentation.swift deleted
- [x] StandardSheet.swift deleted
- [x] NavigationCoordinator cleaned of sheet logic
- [x] FeatureFlag modernSheets removed
- [x] All button actions updated
- [x] All overlays tested and working
- [x] No slide-up animations present
- [x] Code compiles without errors
- [x] All tests pass