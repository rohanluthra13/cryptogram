import SwiftUI

struct NavigationBarView: View {
    // Callbacks for button actions
    var onMoveLeft: () -> Void
    var onMoveRight: () -> Void
    var onTogglePause: () -> Void
    var onNextPuzzle: () -> Void
    var onTryAgain: (() -> Void)? = nil
    
    // State for buttons
    var isPaused: Bool
    var isFailed: Bool = false
    var showCenterButtons: Bool = true
    
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
            
            // Center buttons group - conditionally shown
            if showCenterButtons {
                HStack(spacing: centerSpacing) {
                    // Pause/Play button OR Try Again when failed
                    if isFailed {
                        // Try Again button (replaces pause button when game is over)
                        Button(action: onTryAgain ?? onNextPuzzle) {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.title3)
                                .frame(width: buttonSize, height: buttonSize)
                                .foregroundColor(CryptogramTheme.Colors.text)
                                .accessibilityLabel("Try Again")
                        }
                    } else {
                        // Normal Pause/Play button
                        Button(action: onTogglePause) {
                            Image(systemName: isPaused ? "play" : "pause")
                                .font(.title3)
                                .frame(width: buttonSize, height: buttonSize)
                                .foregroundColor(CryptogramTheme.Colors.text)
                                .accessibilityLabel(isPaused ? "Resume" : "Pause")
                        }
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
            } else {
                // Empty space to maintain layout when center buttons are hidden
                Spacer()
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
        .padding(.top, 8)
        .padding(.bottom, 4)
        .frame(maxWidth: .infinity)
        .background(CryptogramTheme.Colors.background)
    }
}

#Preview {
    VStack(spacing: 20) {
        NavigationBarView(
            onMoveLeft: {},
            onMoveRight: {},
            onTogglePause: {},
            onNextPuzzle: {},
            isPaused: false
        )
        
        NavigationBarView(
            onMoveLeft: {},
            onMoveRight: {},
            onTogglePause: {},
            onNextPuzzle: {},
            onTryAgain: {},
            isPaused: false,
            isFailed: true
        )
        
        NavigationBarView(
            onMoveLeft: {},
            onMoveRight: {},
            onTogglePause: {},
            onNextPuzzle: {},
            isPaused: false,
            showCenterButtons: false
        )
    }
} 