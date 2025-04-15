import SwiftUI

struct PuzzleCell: View {
    let cell: CryptogramCell
    let isSelected: Bool
    let onTap: () -> Void
    
    @AppStorage("encodingType") private var encodingType = "Letters"
    @State private var cellHighlightAmount: CGFloat = 0.0
    @State private var wiggleOffset: CGFloat = 0
    @EnvironmentObject private var viewModel: PuzzleViewModel
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 2) {
                // Input cell
                ZStack(alignment: .center) {
                    // Background for revealed/pre-filled cells
                    if cell.isPreFilled { // Normal mode pre-filled
                        Rectangle()
                            .frame(width: 24, height: 28)
                            .foregroundColor(CryptogramTheme.Colors.preFilledBackground)
                            .cornerRadius(2)
                    } else if cell.isRevealed { // Hinted cell
                        Rectangle()
                            .frame(width: 24, height: 28)
                            .foregroundColor(Color.green.opacity(0.15))
                            .cornerRadius(2)
                    }
                    
                    // Fill animation background
                    if cellHighlightAmount > 0 {
                        Rectangle()
                            .frame(width: 24, height: 28)
                            .foregroundColor(CryptogramTheme.Colors.selectedBorder.opacity(0.2 * cellHighlightAmount))
                            .cornerRadius(2)
                    }
                    
                    Text(cell.userInput)
                        .font(.system(size: 13, weight: .medium, design: .monospaced))
                        .foregroundColor(.primary)
                        .frame(height: 30)
                        .frame(width: 28)
                        .scaleEffect(1.0 + (0.2 * cellHighlightAmount))
                    
                    Rectangle()
                        .frame(width: 25, height: 1)
                        .foregroundColor(borderColor)
                        .offset(y: 12)
                }
                
                // Encoded value (letter or number)
                Text(cell.encodedChar)
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(textColor)
            }
            .padding(.horizontal, 0)
            .offset(x: wiggleOffset)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(cell.isRevealed)
        .onChange(of: cell.wasJustFilled) { oldValue, newValue in
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
        .onChange(of: viewModel.isWiggling) { oldValue, wiggling in
            if wiggling {
                // Randomize wiggle direction slightly for natural effect
                // Add slight delay based on cell position for wave effect
                let randomOffset = CGFloat.random(in: -3...3)
                let staggerDelay = Double(cell.position % 5) * 0.05
                
                withAnimation(
                    .spring(response: 0.15, dampingFraction: 0.2)
                    .delay(staggerDelay)
                    .repeatCount(3, autoreverses: true)
                ) {
                    wiggleOffset = randomOffset
                }
            } else {
                wiggleOffset = 0
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