import SwiftUI

struct PuzzleView: View {
    @StateObject private var viewModel: PuzzleViewModel
    @State private var showSettings = false
    
    init(puzzle: Puzzle? = nil) {
        _viewModel = StateObject(wrappedValue: PuzzleViewModel(initialPuzzle: puzzle))
    }
    
    var body: some View {
        ZStack {
            if let puzzle = viewModel.currentPuzzle {
                VStack(spacing: 0) {
                    // Timer and Mistakes on the same horizontal level
                    ZStack {
                        HStack {
                            MistakesView(mistakeCount: viewModel.state.mistakeCount)
                                .padding(.leading, 16)
                            
                            Spacer()
                        }
                        
                        TimerView(startTime: viewModel.state.startTime, isPaused: viewModel.isPaused)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                    .padding(.top, 8)
                    
                    // Hints view under the mistakes
                    HintsView(
                        hintCount: viewModel.state.hintCount,
                        onRequestHint: { viewModel.revealHint() },
                        maxHints: viewModel.state.maxHints
                    )
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.top, 4)
                    
                    // Puzzle Grid in ScrollView with flexible height
                    ScrollView {
                        PuzzleGrid(
                            encodedText: puzzle.encodedText,
                            userInput: viewModel.state.userInput,
                            selectedIndex: viewModel.state.selectedCellIndex,
                            revealedLetters: viewModel.state.revealedLetters,
                            revealedIndices: viewModel.state.revealedIndices,
                            errorIndices: viewModel.errorIndices,
                            onCellTap: viewModel.selectCell
                        )
                        .padding(.horizontal, 16)
                    }
                    .layoutPriority(1)
                    .frame(maxWidth: .infinity)
                    .frame(maxHeight: UIScreen.main.bounds.height * 0.5)
                    .padding(.horizontal, 12)
                    .padding(.top, 8)
                    
                    Spacer(minLength: 16)
                    
                    // Navigation Bar
                    NavigationBarView(
                        onMoveLeft: viewModel.moveToPreviousCell,
                        onMoveRight: viewModel.moveToNextCell,
                        onTogglePause: viewModel.togglePause,
                        onNextPuzzle: viewModel.loadNextPuzzle,
                        isPaused: viewModel.isPaused
                    )
                    
                    Spacer(minLength: 16)
                    
                    // Keyboard View - fixed at bottom
                    KeyboardView(
                        onLetterPress: viewModel.handleLetterInput,
                        onBackspacePress: viewModel.handleDelete
                    )
                    .padding(.bottom, 8)
                    .padding(.horizontal, 4)
                    .frame(maxWidth: .infinity)
                    .disabled(viewModel.isPaused || viewModel.state.isFailed) // Disable keyboard when game is paused or failed
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(CryptogramTheme.Colors.background)
                .overlay(
                    // Overlay for paused state or game over
                    Group {
                        if viewModel.isPaused {
                            ZStack {
                                // Semi-transparent overlay that allows clicks to pass through to navigation bar
                                Color.black.opacity(0.5)
                                    .edgesIgnoringSafeArea(.all)
                                    .allowsHitTesting(false)  // This lets clicks pass through
                                
                                // Pause text
                                Button(action: { viewModel.togglePause() }) {
                                    Text("PAUSED")
                                        .font(.headline)
                                        .foregroundColor(Color(hex: "#555555"))
                                }
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                                .padding(.bottom, 240)
                            }
                        } else if viewModel.state.isFailed {
                            Color(hex: "#f8f8f8").opacity(0.7)
                                .edgesIgnoringSafeArea(.all)
                                .overlay(
                                    VStack(spacing: 16) {
                                        Text("Game Over")
                                            .font(.headline)
                                            .foregroundColor(CryptogramTheme.Colors.text)
                                        
                                        HStack(spacing: 24) {
                                            // Try again icon - retry the current puzzle
                                            Button(action: { viewModel.resetCurrentPuzzle() }) {
                                                Image(systemName: "arrow.counterclockwise")
                                                    .font(.title3)
                                                    .frame(width: 44, height: 44)
                                                    .foregroundColor(CryptogramTheme.Colors.text)
                                                    .accessibilityLabel("Try Again")
                                            }
                                            
                                            // New puzzle icon - existing functionality
                                            Button(action: { viewModel.loadNextPuzzle() }) {
                                                Image(systemName: "arrow.2.circlepath")
                                                    .font(.title3)
                                                    .frame(width: 44, height: 44)
                                                    .foregroundColor(CryptogramTheme.Colors.text)
                                                    .accessibilityLabel("New Puzzle")
                                            }
                                        }
                                    }
                                )
                        } else if showSettings {
                            // Settings overlay with dismissible background
                            GeometryReader { geometry in
                                VStack(spacing: 0) {
                                    // Empty space at the top to keep settings button accessible
                                    Color.clear
                                        .frame(height: 50)
                                        .allowsHitTesting(false)
                                    
                                    // Semi-transparent overlay below the top area
                                    ZStack {
                                        // Background that can be tapped to dismiss - less transparent
                                        Color(hex: "#f8f8f8").opacity(0.85)
                                            .onTapGesture {
                                                showSettings = false
                                            }
                                        
                                        // Settings panel - no background, outline or shadows
                                        SettingsContentView()
                                            .padding(.horizontal, 24)
                                            .padding(.vertical, 20)
                                            .contentShape(Rectangle())
                                            .onTapGesture { } // Prevent dismissal when tapping content
                                            .environmentObject(viewModel)
                                    }
                                    .frame(height: geometry.size.height - 50)
                                }
                            }
                            .edgesIgnoringSafeArea(.bottom)
                        }
                    }
                )
                
                // Always place settings button on the very top layer of the ZStack
                VStack {
                    HStack {
                        Spacer()
                        
                        // Settings button
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
            } else {
                LoadingView(message: "Loading your puzzle...")
            }
        }
        .navigationBarHidden(true)
    }
}

#Preview {
    NavigationView {
        PuzzleView()
            .environmentObject(PuzzleViewModel())
    }
}
