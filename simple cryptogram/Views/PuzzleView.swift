import SwiftUI

struct PuzzleView: View {
    @StateObject private var viewModel: PuzzleViewModel
    @StateObject private var themeManager = ThemeManager()
    @State private var showSettings = false
    @State private var showCompletionView = false
    @AppStorage("isDarkMode") private var isDarkMode = false
    
    init(puzzle: Puzzle? = nil) {
        _viewModel = StateObject(wrappedValue: PuzzleViewModel(initialPuzzle: puzzle))
    }
    
    var body: some View {
        ZStack {
            if viewModel.currentPuzzle != nil {
                VStack(spacing: 0) {
                    // Timer and Mistakes on the same horizontal level
                    ZStack {
                        HStack {
                            MistakesView(mistakeCount: viewModel.mistakeCount)
                                .padding(.leading, 16)
                            
                            Spacer()
                        }
                        
                        TimerView(startTime: viewModel.startTime ?? Date(), isPaused: viewModel.isPaused)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .opacity(viewModel.startTime == nil ? 0 : 1) // Hide if not started
                    }
                    .padding(.top, 8)
                    
                    // Hints view under the mistakes
                    HintsView(
                        hintCount: viewModel.hintCount,
                        onRequestHint: { viewModel.revealCell(at: viewModel.selectedCellIndex ?? 0) },
                        maxHints: viewModel.nonSymbolCells.count / 4 // Use approximately 1/4 of the cells as max hints
                    )
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.top, 4)
                    
                    // Puzzle Grid in ScrollView with flexible height
                    ScrollView {
                        WordAwarePuzzleGrid()
                            .environmentObject(viewModel)
                            .padding(.horizontal, 16)
                    }
                    .layoutPriority(1)
                    .frame(maxWidth: .infinity)
                    .frame(maxHeight: UIScreen.main.bounds.height * 0.5)
                    .padding(.horizontal, 12)
                    .padding(.top, 8)
                    
                    Spacer(minLength: 16)
                    
                    // Navigation Bar with all controls in a single layer
                    NavigationBarView(
                        onMoveLeft: { viewModel.moveToAdjacentCell(direction: -1) },
                        onMoveRight: { viewModel.moveToAdjacentCell(direction: 1) },
                        onTogglePause: viewModel.togglePause,
                        onNextPuzzle: { viewModel.refreshPuzzleWithCurrentSettings() },
                        onTryAgain: { 
                            viewModel.reset()
                            // Re-apply difficulty settings to the same puzzle
                            if let currentPuzzle = viewModel.currentPuzzle {
                                viewModel.startNewPuzzle(puzzle: currentPuzzle)
                            }
                        },
                        isPaused: viewModel.isPaused,
                        isFailed: viewModel.isFailed,
                        showCenterButtons: true // Show all buttons in the nav bar
                    )
                    
                    // Keyboard View - fixed at bottom
                    KeyboardView(
                        onLetterPress: { letter in
                            if let index = viewModel.selectedCellIndex {
                                viewModel.inputLetter(String(letter), at: index)
                            }
                        },
                        onBackspacePress: { 
                            if let index = viewModel.selectedCellIndex {
                                viewModel.handleDelete(at: index)
                            }
                        }
                    )
                    .padding(.bottom, 4)
                    .padding(.horizontal, 4)
                    .frame(maxWidth: .infinity)
                    .disabled(viewModel.isPaused || viewModel.isComplete) // Disable keyboard when game is paused or complete
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(CryptogramTheme.Colors.background)
                .opacity(showCompletionView ? 0 : 1)
                .overlay(
                    // Overlay for paused state (not completion which is handled separately)
                    Group {
                        if viewModel.isPaused {
                            ZStack {
                                // Semi-transparent overlay that allows clicks to pass through to navigation bar
                                Color.black.opacity(0.5)
                                    .edgesIgnoringSafeArea(.all)
                                    .allowsHitTesting(false)  // This lets clicks pass through
                                
                                // Pause text
                                Button(action: { viewModel.togglePause() }) {
                                    Text("paused")
                                        .font(.headline)
                                        .foregroundColor(CryptogramTheme.Colors.text)
                                }
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                                .padding(.bottom, 240)
                            }
                        } else if viewModel.isFailed {
                            ZStack {
                                // Semi-transparent overlay for game over
                                Color.black.opacity(0.5)
                                    .edgesIgnoringSafeArea(.all)
                                    .allowsHitTesting(false)  // This lets clicks pass through to navigation bar
                                
                                // Game over text - without dedicated icon
                                Text("game over")
                                    .font(.headline)
                                    .foregroundColor(CryptogramTheme.Colors.text)
                                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                                    .padding(.bottom, 240)
                            }
                        } else if showSettings {
                            // Full-screen settings overlay
                            ZStack {
                                // Background that covers the entire screen and can be tapped to dismiss
                                CryptogramTheme.Colors.surface
                                    .opacity(isDarkMode ? 0.95 : 0.85) // More opaque in dark mode
                                    .edgesIgnoringSafeArea(.all)
                                    .onTapGesture {
                                        showSettings = false
                                    }

                                // Settings content centered on the overlay
                                SettingsContentView()
                                    .padding(.horizontal, 24)
                                    .padding(.vertical, 20)
                                    .contentShape(Rectangle()) // Prevent dismissal when tapping content
                                    .onTapGesture { }
                                    .environmentObject(viewModel)
                                    .environmentObject(themeManager)
                            }
                        }
                    }
                )
            } else {
                LoadingView(message: "Loading your puzzle...")
            }
            
            // Completion overlay - conditionally shown
            if showCompletionView {
                PuzzleCompletionView(viewModel: viewModel, showCompletionView: $showCompletionView)
                    .transition(.opacity)
            }
            
            // Settings button on the top layer
            if !showCompletionView {
                // Settings button at top right
                VStack {
                    HStack {
                        Spacer()
                        
                        Button(action: { showSettings.toggle() }) {
                            Image(systemName: "gearshape")
                                .font(.title3)
                                .foregroundColor(CryptogramTheme.Colors.text)
                                .padding(.trailing, 16)
                                .padding(.top, 8)
                                .accessibilityLabel("Settings")
                        }
                    }
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
            }
        }
        .onChange(of: viewModel.isComplete) { oldValue, isComplete in
            if isComplete {
                // Add haptic feedback for completion
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
                
                // First trigger wiggle animation
                viewModel.triggerCompletionWiggle()
                
                // Then transition to completion view with a slight delay
                withAnimation(.easeOut(duration: 0.5).delay(0.7)) {
                    showCompletionView = true
                }
            }
        }
        .navigationBarHidden(true)
    }
    
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

#Preview {
    NavigationView {
        PuzzleView()
    }
}
