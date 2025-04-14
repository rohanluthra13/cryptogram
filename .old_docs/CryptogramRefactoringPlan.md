# Cryptogram App Refactoring Plan

## Current Issues
The current implementation has several architectural issues:

1. **Multiple Sources of Truth**
   - Separate arrays for encodedText, userInput, revealed letters/indices
   - Complex synchronization logic required

2. **Complex Index Mapping**
   - Constant translation between encodedText positions and userInput positions
   - Fragile logic prone to off-by-one errors

3. **Poor Separation of Concerns**
   - Views containing complex index translation logic
   - Business logic scattered across components

4. **Type Safety Gaps**
   - Heavy reliance on indices which can lead to out-of-bounds errors

## Proposed Solution: Cell-Based Architecture

### Core Data Model

```swift
struct CryptogramCell: Identifiable {
    let id = UUID()
    let position: Int            // Position in the original puzzle
    let encodedChar: String      // Encoded character or symbol
    let solutionChar: Character? // Correct solution character (nil for symbols)
    let isSymbol: Bool           // Whether this is a symbol (space, punctuation)
    
    var userInput: String = ""   // User's input for this cell
    var isRevealed: Bool = false // Whether this letter has been revealed
    var isError: Bool = false    // Whether there's an error in this cell
    
    // Computed properties
    var isEmpty: Bool { userInput.isEmpty }
    var isCorrect: Bool { userInput == String(solutionChar ?? " ") }
}
```

### ViewModel Redesign

```swift
class PuzzleViewModel: ObservableObject {
    @Published private(set) var cells: [CryptogramCell] = []
    @Published private(set) var selectedCellIndex: Int?
    @Published private(set) var isComplete: Bool = false
    @Published private(set) var mistakeCount: Int = 0
    @Published private(set) var startTime: Date?
    @Published private(set) var endTime: Date?
    
    // Computed properties
    var completionTime: TimeInterval? {
        guard let start = startTime, let end = endTime else { return nil }
        return end.timeIntervalSince(start)
    }
    
    var nonSymbolCells: [CryptogramCell] {
        cells.filter { !$0.isSymbol }
    }
    
    var progressPercentage: Double {
        let filledCells = nonSymbolCells.filter { !$0.isEmpty }.count
        return Double(filledCells) / Double(nonSymbolCells.count)
    }
}
```

## Implementation Steps

### Phase 1: Core Model Implementation ✅ COMPLETED

1. **Create the CryptogramCell model** ✅
   - Define the structure with all necessary properties
   - Add relevant computed properties
   - Implemented in `simple cryptogram/Models/CryptogramCell.swift`

2. **Update the Puzzle model** ✅
   - Refactor to work with the cell-based approach
   - Ensure proper initialization from raw data
   - Added methods for creating cells for both letter and number encoding
   - Implemented in `simple cryptogram/Models/Puzzle.swift`

3. **Testing** ✅
   - Created simple test cases to validate the core model implementation
   - Tests verify both letter encoding and number encoding
   - Implemented in `simple cryptogram/Models/CryptogramCellTests.swift`

### Phase 2: ViewModel Refactoring ✅ COMPLETED

1. **Refactor PuzzleViewModel** ✅
   - Removed index translation methods
   - Implemented cell creation from puzzle data
   - Updated all state management methods to work with cells
   - Implemented in `simple cryptogram/ViewModels/PuzzleViewModel.swift`

2. **Add helper methods for common operations** ✅
   - Added selectCell, inputLetter, revealCell, handleDelete methods
   - Implemented moveToNextCell for navigation
   - Added checkPuzzleCompletion for game completion logic
   - Enhanced input validation with direct cell property comparisons
   - Added computed properties for non-symbol cells and progress tracking

3. **Improvements** ✅
   - Eliminated multiple sources of truth by using a single array of cells
   - Simplified puzzle state management
   - Removed complex index mapping logic
   - Added proper error handling for invalid inputs
   - Ensured proper synchronization of related cells when updating

### Phase 3: UI Component Refactoring ✅ COMPLETED

1. **Update PuzzleCell** ✅
   - Modified to use a CryptogramCell object instead of individual properties
   - Updated computed properties to reference cell properties
   - Implemented all necessary UI interactions
   - Updated preview with sample CryptogramCell instances
   - Implemented in `simple cryptogram/Views/Components/PuzzleCell.swift`

2. **Update PuzzleGrid** ✅
   - Refactored to iterate through viewModel.cells array
   - Removed complex index mapping and encodedText parsing
   - Simplified cell type detection and rendering
   - Applied proper selection highlighting based on cell position
   - Implemented in `simple cryptogram/Views/Components/PuzzleGrid.swift`

3. **Add navigation support** ✅
   - Added moveToAdjacentCell method to PuzzleViewModel
   - Implemented proper cell navigation with support for skipping symbols
   - Connected navigation controls to view model methods

4. **Completed UI functionality updates** ✅
   - Added progress percentage indicator 
   - Updated all view references to use the cell-based model
   - Implemented proper hint and reveal functionality

### Phase 4: Game Screen Updates

1. **Test the updated UI components**
   - Verify that all game functionality works as expected
   - Check for any regressions in gameplay experience
   - Validate puzzle completion detection

2. **Performance optimization**
   - Profile the app to identify any performance bottlenecks
   - Optimize cell rendering for large puzzles
   - Ensure smooth animation and interaction

3. **Refinements**
   - Polish the UI for improved user experience
   - Add additional accessibility support
   - Implement any remaining features from the original app

## Migration Strategy

1. **Implement the new cell model alongside existing code** ✅
   - Add the new models without removing existing code
   - Create converter functions between old and new formats

2. **Gradually migrate components** ✅
   - Start with the ViewModel
   - Then update UI components
   - Finally, remove old code paths

3. **Testing strategy**
   - Create unit tests for the new cell model and ViewModel
   - Implement UI tests for critical gameplay features
   - Compare behavior between old and new implementations

## Testing Plan

1. **Unit Tests**
   - CryptogramCell model (ensuring properties work correctly)
   - PuzzleViewModel (cell creation, input validation, completion detection)
   - State transitions (starting, revealing, completing)

2. **UI Tests**
   - Cell selection and input
   - Error state visualization
   - Puzzle completion feedback
   - Hint system

## Timeline Estimate

- Phase 1 (Core Model): ✅ Completed
- Phase 2 (ViewModel): ✅ Completed
- Phase 3 (UI Components): ✅ Completed
- Phase 4 (Game Screen): 1-2 days
- Testing & Refinement: 2-3 days

**Total: 3-5 days remaining** 