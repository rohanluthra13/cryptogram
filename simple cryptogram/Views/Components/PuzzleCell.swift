import SwiftUI

struct PuzzleCell: View {
    let cell: CryptogramCell
    let isSelected: Bool
    let onTap: () -> Void
    let isCompleted: Bool
    var shouldAnimate: Bool = false
    var onAnimationComplete: (() -> Void)? = nil
    
    @State private var cellHighlightAmount: CGFloat = 0.0
    @State private var animateCompletionBorder: Bool = false  // flash border on group completion
    @EnvironmentObject private var viewModel: PuzzleViewModel
    @EnvironmentObject private var settingsViewModel: SettingsViewModel
    @EnvironmentObject private var appSettings: AppSettings
    
    // Combine completion state with toggle
    private var effectiveCompleted: Bool {
        isCompleted // Always show highlights for completed letters
    }

    var body: some View {
        Button(action: {
            onTap()
            if !viewModel.hasUserEngaged {
                viewModel.userEngaged()
            }
        }) {
            VStack(spacing: 2) {
                // Input cell
                ZStack(alignment: .center) {
                    // Background for revealed/pre-filled cells
                    if cell.isPreFilled {
                        Rectangle()
                            .frame(width: 24, height: 28)
                            .foregroundColor(CryptogramTheme.Colors.preFilledBackground)
                            .cornerRadius(2)
                    } else if cell.isRevealed {
                        Rectangle()
                            .frame(width: 24, height: 28)
                            .foregroundColor(Color.green.opacity(0.15))
                            .cornerRadius(2)
                    }
                    // Fill animation background - REMOVED for completed letters
                    if !effectiveCompleted && cellHighlightAmount > 0 {
                        Rectangle()
                            .frame(width: 24, height: 28)
                            .foregroundColor(CryptogramTheme.Colors.success.opacity(0.2 * cellHighlightAmount))
                            .cornerRadius(2)
                    }
                    Text(cell.userInput)
                        .font(.system(size: settingsViewModel.textSize.inputSize, weight: .medium, design: .monospaced))
                        .foregroundColor(userInputColor)
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
                    .font(.system(size: settingsViewModel.textSize.encodedSize, weight: .medium, design: .monospaced))
                    .foregroundColor(textColor)
            }
            .padding(.horizontal, 0)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(cell.isRevealed)
        .onChange(of: shouldAnimate) { _, animate in
            if animate {
                // Only animate border/text color, no background highlight
                withAnimation(.easeInOut(duration: 0.3)) {
                    if !effectiveCompleted {
                        cellHighlightAmount = 1.0
                    }
                    animateCompletionBorder = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation {
                        if !effectiveCompleted {
                            cellHighlightAmount = 0.0
                        }
                        animateCompletionBorder = false
                    }
                    onAnimationComplete?()
                }
            }
        }
        .onChange(of: isSelected) { oldValue, selected in
            if selected && isCompleted {
                // No wiggle on selection
            }
        }
        .onChange(of: viewModel.isWiggling) { oldValue, wiggling in
            // No wiggle on viewModel change
        }
        .onAppear {
            // No wiggle on appear
        }
    }
    
    private var userInputColor: Color {
        if cell.isError {
            return CryptogramTheme.Colors.error
        } else if animateCompletionBorder {
            return CryptogramTheme.Colors.success  // flash green on completion
        } else if effectiveCompleted {
            return .gray // muted when completed
        } else {
            return CryptogramTheme.Colors.text
        }
    }

    private var textColor: Color {
        if cell.isError {
            return CryptogramTheme.Colors.error
        } else if animateCompletionBorder {
            return CryptogramTheme.Colors.success  // flash green on completion
        } else if effectiveCompleted {
            return CryptogramTheme.Colors.success // steady green when completed
        } else {
            return CryptogramTheme.Colors.text
        }
    }
    
    private var borderColor: Color {
        if isSelected {
            return CryptogramTheme.Colors.selectedBorder
        } else if cell.isError {
            return CryptogramTheme.Colors.error
        } else if animateCompletionBorder {
            return CryptogramTheme.Colors.success  // flash green on completion
        } else {
            return CryptogramTheme.Colors.border
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        PuzzleCell(
            cell: CryptogramCell(
                quoteId: 0,
                position: 0,
                encodedChar: "A",
                solutionChar: "X",
                isSymbol: false,
                userInput: "X",
                isRevealed: false,
                isError: false
            ),
            isSelected: false,
            onTap: {},
            isCompleted: false
        )
        
        PuzzleCell(
            cell: CryptogramCell(
                quoteId: 0,
                position: 1,
                encodedChar: "26",
                solutionChar: "Y",
                isSymbol: false,
                userInput: "Y",
                isRevealed: false,
                isError: false
            ),
            isSelected: true,
            onTap: {},
            isCompleted: false
        )
        
        PuzzleCell(
            cell: CryptogramCell(
                quoteId: 0,
                position: 2,
                encodedChar: "C",
                solutionChar: "Z",
                isSymbol: false,
                userInput: "Z",
                isRevealed: true,
                isError: false
            ),
            isSelected: false,
            onTap: {},
            isCompleted: false
        )
        
        PuzzleCell(
            cell: CryptogramCell(
                quoteId: 0,
                position: 3,
                encodedChar: "14",
                solutionChar: "W",
                isSymbol: false,
                userInput: "W",
                isRevealed: false,
                isError: true
            ),
            isSelected: false,
            onTap: {},
            isCompleted: false
        )
        
        PuzzleCell(
            cell: CryptogramCell(
                quoteId: 0,
                position: 4,
                encodedChar: "14",
                solutionChar: "W",
                isSymbol: false,
                userInput: "W",
                isRevealed: false,
                isError: false
            ),
            isSelected: false,
            onTap: {},
            isCompleted: true
        )
    }
    .padding()
    .background(CryptogramTheme.Colors.background)
} 