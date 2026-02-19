import SwiftUI

// MARK: - Key Cap Button Style

/// A button style that renders a small pill behind the label.
/// The pill blends with the background color; a subtle shadow gives it depth.
/// On press, the pill scales down and the shadow flattens.
private struct KeyCapButtonStyle: ButtonStyle {
    let keyHeight: CGFloat
    let pillFill: Color
    let hasShadow: Bool

    func makeBody(configuration: Configuration) -> some View {
        let pressed = configuration.isPressed

        configuration.label
            .background(
                ZStack {
                    if hasShadow {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(CryptogramTheme.Colors.text.opacity(pressed ? 0.06 : 0.12))
                            .offset(x: pressed ? 0.5 : 1, y: pressed ? 0.5 : 1.5)
                    }
                    RoundedRectangle(cornerRadius: 8)
                        .fill(pillFill)
                }
                .frame(width: keyHeight * 0.55, height: keyHeight * 0.7)
                .scaleEffect(pressed ? 0.88 : 1.0)
                .animation(.easeOut(duration: 0.1), value: pressed)
            )
    }
}

// MARK: - Keyboard View

struct KeyboardView: View {
    var onLetterPress: (Character) -> Void
    var onBackspacePress: () -> Void
    var completedLetters: Set<String>

    @Environment(PuzzleViewModel.self) private var viewModel
    @Environment(AppSettings.self) private var appSettings

    @State private var showRemainingLetters = false

    private let topRow: [Character] = ["Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P"]
    private let middleRow: [Character] = ["A", "S", "D", "F", "G", "H", "J", "K", "L"]
    private let bottomRow: [Character] = ["Z", "X", "C", "V", "B", "N", "M"]

    private let keyHeight: CGFloat = 45
    private let keySpacing: CGFloat = 4
    private let rowSpacing: CGFloat = 6

    var body: some View {
        VStack(spacing: rowSpacing) {
            HStack(spacing: keySpacing) {
                ForEach(topRow, id: \.self) { key in
                    keyButton(for: key)
                }
            }

            HStack(spacing: keySpacing) {
                Spacer(minLength: 0)
                ForEach(middleRow, id: \.self) { key in
                    keyButton(for: key)
                }
                Spacer(minLength: 0)
            }

            HStack(spacing: keySpacing) {
                Spacer(minLength: 0)
                toggleRemainingLettersButton
                    .frame(width: keyHeight)
                ForEach(bottomRow, id: \.self) { key in
                    keyButton(for: key)
                }
                backspaceButton
                    .frame(width: keyHeight)
            }
        }
        .padding(.horizontal, 4)
        .frame(maxWidth: .infinity)
        .frame(height: keyHeight * 3 + rowSpacing * 2 + 8)
        .padding(.bottom, 0)
        .animation(.easeInOut(duration: 0.25), value: completedLetters)
    }

    // MARK: - Key Button

    private func keyButton(for key: Character) -> some View {
        let uppercaseKey = Character(String(key).uppercased())

        let isLocked: Bool = {
            if appSettings.encodingType == "Letters" {
                return completedLetters.contains(String(key).uppercased())
            } else {
                if let encodedChars = viewModel.solutionToEncodedMap[uppercaseKey] {
                    return encodedChars.contains(where: { completedLetters.contains($0) })
                }
                return false
            }
        }()

        let isInPuzzle = viewModel.lettersInPuzzle.contains(uppercaseKey)
        let isRemaining = isInPuzzle && !isLocked && showRemainingLetters

        let textColor = isLocked
            ? CryptogramTheme.Colors.text.opacity(0.2)
            : CryptogramTheme.Colors.text

        let pillFill: Color = {
            if isRemaining {
                return CryptogramTheme.Colors.success.opacity(0.2)
            }
            return CryptogramTheme.Colors.background
        }()

        return Button(action: { onLetterPress(key) }) {
            Text(String(key))
                .font(.system(size: 16, weight: .medium))
                .frame(height: keyHeight)
                .frame(minWidth: 0, maxWidth: .infinity)
                .foregroundColor(textColor)
                .accessibilityLabel("Key \(String(key))")
        }
        .buttonStyle(KeyCapButtonStyle(
            keyHeight: keyHeight,
            pillFill: pillFill,
            hasShadow: !isLocked
        ))
        .disabled(isLocked)
        .animation(.easeInOut(duration: 0.25), value: isLocked)
    }

    // MARK: - Backspace

    private var backspaceButton: some View {
        Button(action: onBackspacePress) {
            Image(systemName: "delete.left")
                .font(.system(size: 18, weight: .light))
                .frame(height: keyHeight)
                .frame(minWidth: 0, maxWidth: .infinity)
                .foregroundColor(CryptogramTheme.Colors.text)
                .accessibilityLabel("Backspace")
        }
        .buttonStyle(KeyCapButtonStyle(
            keyHeight: keyHeight,
            pillFill: CryptogramTheme.Colors.background,
            hasShadow: true
        ))
    }

    // MARK: - Toggle Remaining Letters

    private var toggleRemainingLettersButton: some View {
        Button {
            showRemainingLetters.toggle()
        } label: {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16, weight: .light))
                .frame(height: keyHeight)
                .frame(minWidth: 0, maxWidth: .infinity)
                .foregroundColor(CryptogramTheme.Colors.text)
                .accessibilityLabel("Show/Hide Letters Remaining")
        }
        .buttonStyle(KeyCapButtonStyle(
            keyHeight: keyHeight,
            pillFill: showRemainingLetters
                ? CryptogramTheme.Colors.success.opacity(0.2)
                : CryptogramTheme.Colors.background,
            hasShadow: true
        ))
    }
}

#Preview {
    KeyboardView(onLetterPress: { _ in }, onBackspacePress: { }, completedLetters: ["A", "B"])
        .padding(8)
}
