import SwiftUI

struct KeyboardView: View {
    // Callbacks for key presses
    var onLetterPress: (Character) -> Void
    var onBackspacePress: () -> Void
    var completedLetters: Set<String> // Remove default value to force explicit passing

    @Environment(PuzzleViewModel.self) private var viewModel
    @Environment(AppSettings.self) private var appSettings

    // New state for showing/hiding remaining letters (session only, defaults to hide)
    @State private var showRemainingLetters = false

    private let topRow: [Character] = ["Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P"]
    private let middleRow: [Character] = ["A", "S", "D", "F", "G", "H", "J", "K", "L"]
    private let bottomRow: [Character] = ["Z", "X", "C", "V", "B", "N", "M"]

    // Constants for layout
    private let keyHeight: CGFloat = 45
    private let rowSpacing: CGFloat = 6

    var body: some View {
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
                toggleRemainingLettersButton.frame(width: keyHeight)
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
        .padding(.bottom, 0)
        .animation(.easeInOut(duration: 0.25), value: completedLetters) // Animate changes to completedLetters
    }
    
    // Helper method to create a key button
    private func keyButton(for key: Character) -> some View {
        let uppercaseKey = Character(String(key).uppercased())

        // Use pre-computed mappings for O(1) lookups instead of O(n) filtering
        let baseLocked: Bool
        if appSettings.encodingType == "Letters" {
            baseLocked = completedLetters.contains(String(key).uppercased())
        } else {
            // For number encoding, check pre-computed map
            if let encodedChars = viewModel.solutionToEncodedMap[uppercaseKey] {
                baseLocked = encodedChars.contains(where: { completedLetters.contains($0) })
            } else {
                baseLocked = false
            }
        }
        let isLocked = baseLocked

        // Use pre-computed lettersInPuzzle for O(1) lookup
        let isInPuzzle = viewModel.lettersInPuzzle.contains(uppercaseKey)
        let isRemaining = isInPuzzle && !isLocked && showRemainingLetters

        return Button(action: { onLetterPress(key) }) {
            Text(String(key))
                .font(.system(size: 16, weight: .medium))
                .frame(height: keyHeight)
                .frame(minWidth: 0, maxWidth: .infinity)
                .foregroundColor(isLocked ? Color.gray : CryptogramTheme.Colors.text)
                .cornerRadius(5)
                .accessibilityLabel("Key \(key)")
        }
        .background(
            isRemaining ? AnyView(
                RoundedRectangle(cornerRadius: 8)
                    .fill(CryptogramTheme.Colors.success.opacity(0.2))
                    .frame(width: keyHeight * 0.55, height: keyHeight * 0.7)
                    .shadow(color: Color.black.opacity(0.13), radius: 2, x: 0, y: 1)
            ) : AnyView(Color.clear)
        )
        .cornerRadius(5)
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
    
    // Toggle button for remaining letters (repurposed magnifying glass)
    private var toggleRemainingLettersButton: some View {
        Button {
            showRemainingLetters.toggle()
        } label: {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16, weight: .light))
                .frame(height: keyHeight)
                .frame(minWidth: 0, maxWidth: .infinity)
                .foregroundColor(CryptogramTheme.Colors.text) // Always gray text
                .cornerRadius(5)
                .accessibilityLabel("Show/Hide Letters Remaining")
        }
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(showRemainingLetters ? CryptogramTheme.Colors.success.opacity(0.2) : Color(.systemGray5))
                .frame(width: keyHeight * 0.55, height: keyHeight * 0.7)
                .shadow(color: Color.black.opacity(0.13), radius: 2, x: 0, y: 1)
        )
        .frame(width: keyHeight * 0.7, height: keyHeight * 0.7)
    }
}

#Preview {
    KeyboardView(onLetterPress: { _ in }, onBackspacePress: { }, completedLetters: ["A", "B"])
        .padding(8)
} 