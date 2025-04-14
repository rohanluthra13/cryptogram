# Cryptogram Word Wrapping Implementation Plan

## Issue Summary
In the current implementation of the cryptogram puzzle app, words can be split across multiple lines in the puzzle grid. This occurs because we're using a fixed 10-column LazyVGrid without consideration for word boundaries. When words exceed the grid width, they wrap to the next line, breaking the word's visual continuity. This makes the puzzles harder to solve than intended, as seeing complete words is an important aid in pattern recognition for cryptogram solving.

## Current Implementation

The current approach uses:
- A fixed 10-column LazyVGrid layout in PuzzleGrid.swift
- Cells are displayed sequentially without awareness of word boundaries
- No mechanism prevents words from being split when they reach the end of a line

```swift
// Current implementation in PuzzleGrid
LazyVGrid(
    columns: Array(repeating: GridItem(.flexible(minimum: 20, maximum: 45), spacing: CryptogramTheme.Layout.cellSpacing), count: columns),
    spacing: CryptogramTheme.Layout.cellSpacing * 3
) {
    ForEach(viewModel.cells.indices, id: \.self) { index in
        // Display cells without word awareness
        // ...
    }
}
```

## Proposed Solution

Replace the LazyVGrid with a word-aware flow layout that keeps words together, ensuring they don't split across lines. This involves:

1. Grouping cells into word units based on spaces and punctuation
2. Using a VStack of HStacks to display each word as a complete unit
3. Maintaining the visual style and interaction model of the current implementation

## Implementation Steps

### 1. Add Word Grouping Logic to PuzzleViewModel ✅ IMPLEMENTED

Added a computed property to the PuzzleViewModel that groups cells by words:

```swift
// Added to PuzzleViewModel
struct WordGroup: Identifiable {
    let id = UUID()
    let indices: [Int]
    let includesSpace: Bool
}

var wordGroups: [WordGroup] {
    var groups: [WordGroup] = []
    var currentWordIndices: [Int] = []
    
    for index in cells.indices {
        let cell = cells[index]
        
        if cell.isSymbol && cell.encodedChar == " " {
            // End current word
            if !currentWordIndices.isEmpty {
                groups.append(WordGroup(indices: currentWordIndices, includesSpace: true))
                currentWordIndices = []
            }
        } else {
            // Add to current word
            currentWordIndices.append(index)
        }
    }
    
    // Add last word if not empty
    if !currentWordIndices.isEmpty {
        groups.append(WordGroup(indices: currentWordIndices, includesSpace: false))
    }
    
    return groups
}
```

### 2. Create a New WordAwarePuzzleGrid Component ✅ IMPLEMENTED

Created a new component that uses the word groups to ensure words stay together:

```swift
struct WordAwarePuzzleGrid: View {
    @EnvironmentObject private var viewModel: PuzzleViewModel
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: CryptogramTheme.Layout.cellSpacing * 3) {
                LazyVStack(alignment: .leading, spacing: CryptogramTheme.Layout.cellSpacing * 2) {
                    ForEach(viewModel.wordGroups) { wordGroup in
                        HStack(spacing: CryptogramTheme.Layout.cellSpacing) {
                            ForEach(wordGroup.indices, id: \.self) { index in
                                let cell = viewModel.cells[index]
                                
                                if cell.isSymbol && cell.encodedChar == " " {
                                    // Display space
                                    Spacer()
                                        .frame(width: 20, height: 20)
                                } else if cell.isSymbol {
                                    // Display punctuation
                                    Text(cell.encodedChar)
                                        .font(.system(size: 16, weight: .medium, design: .monospaced))
                                        .foregroundColor(CryptogramTheme.Colors.text)
                                        .frame(width: 20, height: 20)
                                } else {
                                    // Display puzzle cell
                                    PuzzleCell(
                                        cell: cell,
                                        isSelected: viewModel.selectedCellIndex == index,
                                        onTap: { viewModel.selectCell(at: index) }
                                    )
                                    .aspectRatio(1, contentMode: .fit)
                                }
                            }
                            
                            if wordGroup.includesSpace {
                                Spacer()
                                    .frame(width: 20, height: 20)
                            }
                        }
                        .padding(.trailing, 4)
                    }
                }
            }
            .padding(CryptogramTheme.Layout.gridPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
```

### 3. Update PuzzleView to Use the New Grid ✅ IMPLEMENTED

Updated PuzzleView to use WordAwarePuzzleGrid instead of PuzzleGrid:

```swift
// In PuzzleView
ScrollView {
    WordAwarePuzzleGrid()
        .environmentObject(viewModel)
        .padding(.horizontal, 16)
}
```

### 4. Test and Refine Spacing and Layout

- Test with various puzzle lengths and word sizes
- Adjust spacing parameters as needed for optimal visual appearance
- Verify that navigation between cells still works correctly

## Benefits

1. **Improved Puzzle Experience**: Words stay intact, making the puzzle more intuitive to solve
2. **Maintained Visual Style**: Preserves the current visual design with minimal changes
3. **Consistent Interaction Model**: User interactions remain unchanged
4. **Accessibility**: Improved readability by keeping logical word units together
5. **Simplicity**: Implementation is straightforward with pure SwiftUI, no complex custom layouts required

## Timeline

- Development: 1-2 days
- Testing: 1 day
- Refinement: 1 day
- Total: 3-4 days 