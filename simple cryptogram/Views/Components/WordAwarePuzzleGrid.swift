import SwiftUI

struct WordAwarePuzzleGrid: View {
    @Environment(PuzzleViewModel.self) private var viewModel
    
    var body: some View {
        ScrollView {
            FlowLayout(spacing: 8, alignment: .center) {
                ForEach(viewModel.wordGroups) { wordGroup in
                    HStack(spacing: 0) {
                        ForEach(wordGroup.indices, id: \.self) { index in
                            cellView(for: index)
                        }
                        if wordGroup.includesSpace {
                            Spacer()
                                .frame(width: 10, height: 20)
                        }
                    }
                }
            }
            .padding(CryptogramTheme.Layout.gridPadding)
            .frame(maxWidth: .infinity, alignment: .center)
        }
    }

    @ViewBuilder
    private func cellView(for index: Int) -> some View {
        // Guard against stale indices during async puzzle transitions
        if index >= viewModel.cells.count {
            EmptyView()
        } else {
        let cell = viewModel.cells[index]
        if cell.isSymbol && cell.encodedChar == " " {
            Spacer().frame(width: 10, height: 20)
        } else if cell.isSymbol {
            Text(cell.encodedChar)
                .font(.system(size: 16, weight: .medium, design: .monospaced))
                .foregroundColor(CryptogramTheme.Colors.text)
                .frame(width: 10, height: 20)
        } else {
            PuzzleCell(
                cell: cell,
                isSelected: viewModel.selectedCellIndex == index,
                onTap: { viewModel.selectCell(at: index) },
                isCompleted: viewModel.completedLetters.contains(cell.encodedChar),
                shouldAnimate: viewModel.cellsToAnimate.contains(cell.id),
                onAnimationComplete: { viewModel.markCellAnimationComplete(cell.id) }
            )
            .id("\(viewModel.currentPuzzle?.id ?? UUID())-\(cell.id)")
            .aspectRatio(1, contentMode: .fit)
        }
        }
    }
}

// A layout that flows items horizontally and then wraps to the next line when needed
struct FlowLayout: Layout {
    var spacing: CGFloat = 4
    var alignment: HorizontalAlignment = .center
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let layout = arrangeSubviews(proposal: proposal, subviews: subviews)
        
        if subviews.isEmpty {
            return .zero
        }
        
        return CGSize(
            width: proposal.width ?? .infinity,
            height: layout.maxY
        )
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let layout = arrangeSubviews(proposal: proposal, subviews: subviews)
        
        for (index, layoutItem) in layout.items.enumerated() {
            let position = CGPoint(
                x: bounds.minX + layoutItem.x,
                y: bounds.minY + layoutItem.y
            )
            
            subviews[index].place(
                at: position,
                proposal: ProposedViewSize(layoutItem.size)
            )
        }
    }
    
    private func arrangeSubviews(proposal: ProposedViewSize, subviews: Subviews) -> FlowLayoutResult {
        var layoutItems: [(index: Int, item: FlowLayoutItem)] = []
        var currentY: CGFloat = 0
        let availableWidth = proposal.width ?? .infinity
        
        // First pass: determine which items are on which row
        var rowItems: [[Int]] = [[]]
        var currentRowWidth: CGFloat = 0
        var currentRowIndex = 0
        
        for (index, subview) in subviews.enumerated() {
            let size = subview.sizeThatFits(
                ProposedViewSize(width: availableWidth, height: nil)
            )
            
            if currentRowWidth + size.width > availableWidth && currentRowWidth > 0 {
                // Start a new row
                currentRowIndex += 1
                rowItems.append([])
                currentRowWidth = 0
            }
            
            rowItems[currentRowIndex].append(index)
            currentRowWidth += size.width + spacing
        }
        
        // Second pass: position items with proper centering
        currentY = 0
        
        for row in rowItems {
            var rowWidth: CGFloat = 0
            var rowHeight: CGFloat = 0
            var sizes: [CGSize] = []
            
            // Calculate total row width and determine row height
            for index in row {
                let size = subviews[index].sizeThatFits(
                    ProposedViewSize(width: availableWidth, height: nil)
                )
                sizes.append(size)
                rowWidth += size.width
                rowHeight = max(rowHeight, size.height)
            }
            
            // Add spacing between items
            if row.count > 1 {
                rowWidth += spacing * CGFloat(row.count - 1)
            }
            
            // Calculate starting X position for centering
            var startX: CGFloat = 0
            if alignment == .center {
                startX = (availableWidth - rowWidth) / 2
            }
            
            // Position each item in the row
            var currentX = startX
            for (itemIndex, index) in row.enumerated() {
                let size = sizes[itemIndex]
                let layoutItem = FlowLayoutItem(
                    x: currentX,
                    y: currentY,
                    size: size
                )
                layoutItems.append((index: index, item: layoutItem))
                currentX += size.width + spacing
            }
            
            currentY += rowHeight + spacing
        }
        
        // Sort layout items by their original indices and extract just the items
        let sortedItems = layoutItems.sorted(by: { $0.index < $1.index }).map(\.item)
        
        return FlowLayoutResult(
            items: sortedItems,
            maxY: currentY - spacing
        )
    }
    
    struct FlowLayoutItem {
        var x: CGFloat
        var y: CGFloat
        var size: CGSize
    }
    
    struct FlowLayoutResult {
        var items: [FlowLayoutItem]
        var maxY: CGFloat
    }
}

#Preview {
    WordAwarePuzzleGrid()
        .background(CryptogramTheme.Colors.background)
        .frame(height: 300)
        .environment(PuzzleViewModel())
        .environment(AppSettings())
} 