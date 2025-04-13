import SwiftUI

struct PuzzleCell: View {
    let letter: Character
    let userInput: String
    let isSelected: Bool
    let isRevealed: Bool
    let isError: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                if letter.isLetter {
                    // Input cell
                    ZStack(alignment: .center) {
                        if isRevealed {
                            Rectangle()
                                .frame(width: 24, height: 28)
                                .foregroundColor(Color.green.opacity(0.15))
                                .cornerRadius(2)
                        }
                        
                        Text(userInput)
                            .font(.system(size: 14, weight: .medium, design: .monospaced))
                            .foregroundColor(.primary)
                            .frame(height: 32)
                            .frame(width: 40)
                        
                        Rectangle()
                            .frame(width: 25, height: 1)
                            .foregroundColor(borderColor)
                            .offset(y: 12)
                    }
                }
                
                // Encoded letter
                Text(String(letter))
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundColor(textColor)
            }
            .padding(.horizontal, 6)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var textColor: Color {
        if isError {
            return CryptogramTheme.Colors.error
        } else {
            return CryptogramTheme.Colors.text
        }
    }
    
    private var borderColor: Color {
        if isError {
            return CryptogramTheme.Colors.error
        } else if isSelected {
            return CryptogramTheme.Colors.primary
        } else {
            return CryptogramTheme.Colors.secondary.opacity(0.3)
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        PuzzleCell(
            letter: "A",
            userInput: "X",
            isSelected: false,
            isRevealed: false,
            isError: false,
            onTap: {}
        )
        
        PuzzleCell(
            letter: " ",
            userInput: "",
            isSelected: false,
            isRevealed: false,
            isError: false,
            onTap: {}
        )
        
        PuzzleCell(
            letter: "!",
            userInput: "",
            isSelected: false,
            isRevealed: false,
            isError: false,
            onTap: {}
        )
        
        PuzzleCell(
            letter: "B",
            userInput: "Y",
            isSelected: true,
            isRevealed: false,
            isError: false,
            onTap: {}
        )
        
        PuzzleCell(
            letter: "C",
            userInput: "Z",
            isSelected: false,
            isRevealed: true,
            isError: false,
            onTap: {}
        )
        
        PuzzleCell(
            letter: "D",
            userInput: "W",
            isSelected: false,
            isRevealed: false,
            isError: true,
            onTap: {}
        )
    }
    .padding()
    .background(CryptogramTheme.Colors.background)
} 