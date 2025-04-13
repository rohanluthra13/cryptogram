import SwiftUI

struct KeyboardView: View {
    // Callbacks for key presses
    var onLetterPress: (Character) -> Void
    var onBackspacePress: () -> Void

    private let topRow: [Character] = ["Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P"]
    private let middleRow: [Character] = ["A", "S", "D", "F", "G", "H", "J", "K", "L"]
    private let bottomRow: [Character] = ["Z", "X", "C", "V", "B", "N", "M"]

    // Constants for layout
    private let keyHeight: CGFloat = 45
    private let rowSpacing: CGFloat = 6

    var body: some View {
        VStack(spacing: rowSpacing) {
            // Top row
            HStack(spacing: 2) {
                ForEach(topRow, id: \.self) { key in
                    keyButton(for: key)
                }
            }

            // Middle row
            HStack(spacing: 2) {
                Spacer(minLength: 0)
                ForEach(middleRow, id: \.self) { key in
                    keyButton(for: key)
                }
                Spacer(minLength: 0)
            }

            // Bottom row with backspace
            HStack(spacing: 2) {
                Spacer(minLength: 0)
                ForEach(bottomRow, id: \.self) { key in
                    keyButton(for: key)
                }
                backspaceButton
                    .frame(width: keyHeight)  // Make backspace width match height
            }
        }
        .padding(.horizontal, 4)
        .frame(maxWidth: .infinity)  // Use all available width
        .frame(height: keyHeight * 3 + rowSpacing * 2 + 8) // Fixed height based on contents
    }
    
    // Helper method to create a key button
    private func keyButton(for key: Character) -> some View {
        Button(action: { onLetterPress(key) }) {
            Text(String(key))
                .font(.system(size: 16, weight: .medium))
                .frame(height: keyHeight)
                .frame(minWidth: 0, maxWidth: .infinity)
                .foregroundColor(CryptogramTheme.Colors.text)
                .cornerRadius(5)
                .accessibilityLabel("Key \(key)")
        }
    }
    
    private var backspaceButton: some View {
        Button(action: onBackspacePress) {
            Image(systemName: "delete.left")
                .font(.system(size: 18, weight: .light))
                .frame(height: keyHeight)
                .frame(minWidth: 0, maxWidth: .infinity)
                .foregroundColor(CryptogramTheme.Colors.text)
                .cornerRadius(5)
                .accessibilityLabel("Backspace")
        }
    }
}

#Preview {
    KeyboardView(onLetterPress: { _ in }, onBackspacePress: { })
        .padding(8)
        .previewLayout(.sizeThatFits)
} 