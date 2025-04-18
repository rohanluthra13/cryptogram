import SwiftUI

struct KeyboardView: View {
    // Callbacks for key presses
    var onLetterPress: (Character) -> Void
    var onBackspacePress: () -> Void
    var completedLetters: Set<String> // Remove default value to force explicit passing

    @AppStorage("encodingType") private var encodingType = "Letters"
    @EnvironmentObject private var viewModel: PuzzleViewModel

    private let topRow: [Character] = ["Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P"]
    private let middleRow: [Character] = ["A", "S", "D", "F", "G", "H", "J", "K", "L"]
    private let bottomRow: [Character] = ["Z", "X", "C", "V", "B", "N", "M"]

    // Constants for layout
    private let keyHeight: CGFloat = 45
    private let rowSpacing: CGFloat = 6

    var body: some View {
        print("KeyboardView: completedLetters = \(completedLetters)")
        return VStack(spacing: rowSpacing) {
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
        .padding(.bottom, 4)
        .animation(.easeInOut(duration: 0.25), value: completedLetters) // Animate changes to completedLetters
    }
    
    // Helper method to create a key button
    private func keyButton(for key: Character) -> some View {
        let isLocked: Bool
        if encodingType == "Letters" {
            isLocked = completedLetters.contains(String(key).uppercased())
        } else {
            // For number encoding, lock the key if ANY encodedChar for this letter is in completedLetters
            let mappedNumbers = viewModel.cells.filter { cell in
                guard let solutionChar = cell.solutionChar else { return false }
                return String(solutionChar).uppercased() == String(key).uppercased() && !cell.isSymbol
            }.map { $0.encodedChar }
            isLocked = mappedNumbers.contains(where: { completedLetters.contains($0) })
        }
        return Button(action: { onLetterPress(key) }) {
            Text(String(key))
                .font(.system(size: 16, weight: .medium))
                .frame(height: keyHeight)
                .frame(minWidth: 0, maxWidth: .infinity)
                .foregroundColor(isLocked ? Color.gray : CryptogramTheme.Colors.text)
                .cornerRadius(5)
                .accessibilityLabel("Key \(key)")
        }
        .disabled(isLocked)
        .scaleEffect(isLocked ? 0.95 : 1.0) // Subtle scale animation for lock
        .animation(.easeInOut(duration: 0.25), value: isLocked)
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
    KeyboardView(onLetterPress: { _ in }, onBackspacePress: { }, completedLetters: ["A", "B"])
        .padding(8)
} 