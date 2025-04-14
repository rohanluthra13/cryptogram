import SwiftUI

struct PuzzleCell: View {
    let cell: CryptogramCell
    let isSelected: Bool
    let onTap: () -> Void
    
    @AppStorage("encodingType") private var encodingType = "Letters"
    @State private var cellHighlightAmount: CGFloat = 0.0
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                // Input cell
                ZStack(alignment: .center) {
                    if cell.isRevealed {
                        Rectangle()
                            .frame(width: 24, height: 28)
                            .foregroundColor(Color.green.opacity(0.15))
                            .cornerRadius(2)
                    }
                    
                    // Fill animation background
                    if cellHighlightAmount > 0 {
                        Rectangle()
                            .frame(width: 24, height: 28)
                            .foregroundColor(Color.blue.opacity(0.2 * cellHighlightAmount))
                            .cornerRadius(2)
                    }
                    
                    Text(cell.userInput)
                        .font(.system(size: 14, weight: .medium, design: .monospaced))
                        .foregroundColor(.primary)
                        .frame(height: 32)
                        .frame(width: 40)
                        .scaleEffect(1.0 + (0.2 * cellHighlightAmount))
                    
                    Rectangle()
                        .frame(width: 25, height: 1)
                        .foregroundColor(borderColor)
                        .offset(y: 12)
                }
                
                // Encoded value (letter or number)
                Text(cell.encodedChar)
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundColor(textColor)
            }
            .padding(.horizontal, 6)
        }
        .buttonStyle(PlainButtonStyle())
        .onChange(of: cell.wasJustFilled) { newValue in
            if newValue {
                withAnimation(.easeInOut(duration: 0.3)) {
                    cellHighlightAmount = 1.0
                }
                
                // Reset after animation
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation {
                        cellHighlightAmount = 0.0
                    }
                }
            }
        }
    }
    
    private var textColor: Color {
        if cell.isError {
            return CryptogramTheme.Colors.error
        } else {
            return CryptogramTheme.Colors.text
        }
    }
    
    private var borderColor: Color {
        if isSelected {
            return CryptogramTheme.Colors.selectedBorder
        } else if cell.isError {
            return CryptogramTheme.Colors.error
        } else {
            return CryptogramTheme.Colors.border
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        PuzzleCell(
            cell: CryptogramCell(
                position: 0,
                encodedChar: "A",
                solutionChar: "X",
                isSymbol: false,
                userInput: "X",
                isRevealed: false,
                isError: false
            ),
            isSelected: false,
            onTap: {}
        )
        
        PuzzleCell(
            cell: CryptogramCell(
                position: 1,
                encodedChar: "26",
                solutionChar: "Y",
                isSymbol: false,
                userInput: "Y",
                isRevealed: false,
                isError: false
            ),
            isSelected: true,
            onTap: {}
        )
        
        PuzzleCell(
            cell: CryptogramCell(
                position: 2,
                encodedChar: "C",
                solutionChar: "Z",
                isSymbol: false,
                userInput: "Z",
                isRevealed: true,
                isError: false
            ),
            isSelected: false,
            onTap: {}
        )
        
        PuzzleCell(
            cell: CryptogramCell(
                position: 3,
                encodedChar: "14",
                solutionChar: "W",
                isSymbol: false,
                userInput: "W",
                isRevealed: false,
                isError: true
            ),
            isSelected: false,
            onTap: {}
        )
    }
    .padding()
    .background(CryptogramTheme.Colors.background)
} 