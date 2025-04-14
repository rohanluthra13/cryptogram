import SwiftUI

struct PuzzleGrid: View {
    @EnvironmentObject private var viewModel: PuzzleViewModel
    
    private let columns = 10 // Using 10 columns as previously set
    
    var body: some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(minimum: 20, maximum: 45), spacing: CryptogramTheme.Layout.cellSpacing), count: columns),
            spacing: CryptogramTheme.Layout.cellSpacing * 3 // Increased vertical spacing between rows
        ) {
            ForEach(viewModel.cells.indices, id: \.self) { index in
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
        }
        .padding(CryptogramTheme.Layout.gridPadding)
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    PuzzleGrid()
        .background(CryptogramTheme.Colors.background)
        .frame(height: 300)
        .environmentObject(PuzzleViewModel())
} 