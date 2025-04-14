import SwiftUI

struct NavigationBarView: View {
    // Callbacks for button actions
    var onMoveLeft: () -> Void
    var onMoveRight: () -> Void
    var onTogglePause: () -> Void
    var onNextPuzzle: () -> Void
    
    // State for pause button
    var isPaused: Bool
    
    // Constants
    private let buttonSize: CGFloat = 44
    private let centerSpacing: CGFloat = 16
    
    var body: some View {
        HStack(spacing: 0) {
            // Left navigation button at the extreme edge
            Button(action: onMoveLeft) {
                Image(systemName: "chevron.left")
                    .font(.title3)
                    .frame(width: buttonSize, height: buttonSize)
                    .foregroundColor(CryptogramTheme.Colors.text)
                    .accessibilityLabel("Move Left")
            }
            .padding(.leading, 0)
            
            Spacer()
            
            // Center buttons group
            HStack(spacing: centerSpacing) {
                // Pause/Play button - using thinner icons
                Button(action: onTogglePause) {
                    Image(systemName: isPaused ? "play" : "pause")
                        .font(.title3)
                        .frame(width: buttonSize, height: buttonSize)
                        .foregroundColor(CryptogramTheme.Colors.text)
                        .accessibilityLabel(isPaused ? "Resume" : "Pause")
                }
                
                // Next puzzle button - using circular arrows to suggest swap
                Button(action: onNextPuzzle) {
                    Image(systemName: "arrow.2.circlepath")
                        .font(.title3)
                        .frame(width: buttonSize, height: buttonSize)
                        .foregroundColor(CryptogramTheme.Colors.text)
                        .accessibilityLabel("New Puzzle")
                }
            }
            
            Spacer()
            
            // Right navigation button at the extreme edge
            Button(action: onMoveRight) {
                Image(systemName: "chevron.right")
                    .font(.title3)
                    .frame(width: buttonSize, height: buttonSize)
                    .foregroundColor(CryptogramTheme.Colors.text)
                    .accessibilityLabel("Move Right")
            }
            .padding(.trailing, 0)
        }
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .background(CryptogramTheme.Colors.background)
    }
}

#Preview {
    NavigationBarView(
        onMoveLeft: {},
        onMoveRight: {},
        onTogglePause: {},
        onNextPuzzle: {},
        isPaused: false
    )
} 