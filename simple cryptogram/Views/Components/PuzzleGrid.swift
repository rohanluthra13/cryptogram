import SwiftUI

struct PuzzleGrid: View {
    let encodedText: String
    let userInput: [String]
    let selectedIndex: Int?
    let revealedLetters: Set<Character>
    let revealedIndices: Set<Int>
    let errorIndices: Set<Int>
    let onCellTap: (Int) -> Void
    
    private let columns = 10 // Using 10 columns as previously set
    
    var body: some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(minimum: 20, maximum: 45), spacing: CryptogramTheme.Layout.cellSpacing), count: columns),
            spacing: CryptogramTheme.Layout.cellSpacing * 3 // Increased vertical spacing between rows
        ) {
            ForEach(Array(encodedText.enumerated()), id: \.offset) { index, letter in
                PuzzleCell(
                    letter: letter,
                    userInput: index < userInput.count ? userInput[index] : "",
                    isSelected: index == selectedIndex,
                    isRevealed: revealedIndices.contains(index),
                    isError: errorIndices.contains(index),
                    onTap: { onCellTap(index) }
                )
                .aspectRatio(1, contentMode: .fit)
            }
        }
        .padding(CryptogramTheme.Layout.gridPadding)
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    PuzzleGrid(
        encodedText: "HELLO WORLD THIS IS A LONGER PUZZLE WITH MULTIPLE WORDS",
        userInput: Array(repeating: "", count: 58),
        selectedIndex: 2,
        revealedLetters: Set(["H", "E"]),
        revealedIndices: Set([0, 1]),
        errorIndices: Set([4]),
        onCellTap: { _ in }
    )
    .background(CryptogramTheme.Colors.background)
    .frame(height: 300)
} 