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
    
    // Layout selection with binding
    @Binding var layout: NavigationBarLayout
    
    // Constants
    private let buttonSize: CGFloat = 44
    private let centerSpacing: CGFloat = 16
    
    var body: some View {
        switch layout {
        case .leftLayout:
            leftLayoutView
        case .centerLayout:
            centerLayoutView
        case .rightLayout:
            rightLayoutView
        }
    }
    
    // Left layout (initially identical to current/center layout)
    private var leftLayoutView: some View {
        HStack(spacing: 0) {
            // Navigation arrows on the left side
            HStack(spacing: centerSpacing) {
                // Left arrow
                Button(action: onMoveLeft) {
                    Image(systemName: "chevron.left")
                        .font(.title3)
                        .frame(width: buttonSize, height: buttonSize)
                        .foregroundColor(CryptogramTheme.Colors.text)
                        .accessibilityLabel("Move Left")
                }
                
                // Right arrow
                Button(action: onMoveRight) {
                    Image(systemName: "chevron.right")
                        .font(.title3)
                        .frame(width: buttonSize, height: buttonSize)
                        .foregroundColor(CryptogramTheme.Colors.text)
                        .accessibilityLabel("Move Right")
                }
            }
            .padding(.leading, 60)
            
            Spacer()
            
            // Action buttons on the right side
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
                .padding(.trailing, 60)
            }
        }
        .padding(.top, 8)
        .padding(.bottom, 4)
        .frame(maxWidth: .infinity)
        // .background(CryptogramTheme.Colors.background) // Removed explicit background for system default
    }
    
    // Center layout (current implementation)
    private var centerLayoutView: some View {
        HStack {
            // Left arrow on left edge
            Button(action: onMoveLeft) {
                Image(systemName: "chevron.left")
                    .font(.title3)
                    .frame(width: buttonSize, height: buttonSize)
                    .foregroundColor(CryptogramTheme.Colors.text)
                    .accessibilityLabel("Move Left")
            }
            .padding(.leading, 10)
            
            Spacer()
            
            // Action buttons in center
            if showCenterButtons {
                HStack(spacing: centerSpacing) {
                    // Pause/Play button OR Try Again when failed
                    if isFailed {
                        Button(action: onTryAgain ?? onNextPuzzle) {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.title3)
                                .frame(width: buttonSize, height: buttonSize)
                                .foregroundColor(CryptogramTheme.Colors.text)
                                .accessibilityLabel("Try Again")
                        }
                    } else {
                        Button(action: onTogglePause) {
                            Image(systemName: isPaused ? "play" : "pause")
                                .font(.title3)
                                .frame(width: buttonSize, height: buttonSize)
                                .foregroundColor(CryptogramTheme.Colors.text)
                                .accessibilityLabel(isPaused ? "Resume" : "Pause")
                        }
                    }
                    
                    // Next puzzle button
                    Button(action: onNextPuzzle) {
                        Image(systemName: "arrow.2.circlepath")
                            .font(.title3)
                            .frame(width: buttonSize, height: buttonSize)
                            .foregroundColor(CryptogramTheme.Colors.text)
                            .accessibilityLabel("New Puzzle")
                    }
                }
            }
            
            Spacer()
            
            // Right arrow on right edge
            Button(action: onMoveRight) {
                Image(systemName: "chevron.right")
                    .font(.title3)
                    .frame(width: buttonSize, height: buttonSize)
                    .foregroundColor(CryptogramTheme.Colors.text)
                    .accessibilityLabel("Move Right")
            }
            .padding(.trailing, 10)
        }
        .padding(.top, 8)
        .padding(.bottom, 4)
        .frame(maxWidth: .infinity)
        // .background(CryptogramTheme.Colors.background) // Removed explicit background for system default
    }
    
    // Right layout (initially identical to current/center layout)
    private var rightLayoutView: some View {
        HStack(spacing: 0) {
            // Action buttons on the left side
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
                .padding(.leading, 60)
            }
            
            Spacer()
            
            // Navigation arrows on the right side
            HStack(spacing: centerSpacing) {
                // Left arrow
                Button(action: onMoveLeft) {
                    Image(systemName: "chevron.left")
                        .font(.title3)
                        .frame(width: buttonSize, height: buttonSize)
                        .foregroundColor(CryptogramTheme.Colors.text)
                        .accessibilityLabel("Move Left")
                }
                
                // Right arrow
                Button(action: onMoveRight) {
                    Image(systemName: "chevron.right")
                        .font(.title3)
                        .frame(width: buttonSize, height: buttonSize)
                        .foregroundColor(CryptogramTheme.Colors.text)
                        .accessibilityLabel("Move Right")
                }
            }
            .padding(.trailing, 60)
        }
        .padding(.top, 8)
        .padding(.bottom, 4)
        .frame(maxWidth: .infinity)
        // .background(CryptogramTheme.Colors.background) // Removed explicit background for system default
    }
}

#Preview {
    VStack(spacing: 20) {
        NavigationBarView(
            onMoveLeft: {},
            onMoveRight: {},
            onTogglePause: {},
            onNextPuzzle: {},
            isPaused: false,
            layout: .constant(.leftLayout)
        )
        .previewDisplayName("Left Layout")
        
        NavigationBarView(
            onMoveLeft: {},
            onMoveRight: {},
            onTogglePause: {},
            onNextPuzzle: {},
            isPaused: false,
            layout: .constant(.centerLayout)
        )
        .previewDisplayName("Center Layout")
        
        NavigationBarView(
            onMoveLeft: {},
            onMoveRight: {},
            onTogglePause: {},
            onNextPuzzle: {},
            isPaused: false,
            layout: .constant(.rightLayout)
        )
        .previewDisplayName("Right Layout")
    }
} 