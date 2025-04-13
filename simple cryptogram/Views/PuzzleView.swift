import SwiftUI

struct PuzzleView: View {
    @StateObject private var viewModel: PuzzleViewModel
    
    init(puzzle: Puzzle? = nil) {
        _viewModel = StateObject(wrappedValue: PuzzleViewModel(initialPuzzle: puzzle))
    }
    
    var body: some View {
        ZStack {
            if let puzzle = viewModel.currentPuzzle {
                VStack(spacing: 0) {
                    // Timer and Mistakes on the same horizontal level
                    HStack {
                        MistakesView(mistakeCount: viewModel.state.mistakeCount)
                            .padding(.leading, 16)
                        
                        Spacer()
                        
                        TimerView(startTime: viewModel.state.startTime, isPaused: viewModel.isPaused)
                            .padding(.trailing, 16)
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
                    // Overlay for paused state
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
                            Color.black.opacity(0.5)
                                .edgesIgnoringSafeArea(.all)
                                .overlay(
                                    VStack(spacing: 16) {
                                        Text("Game Over")
                                            .font(.title)
                                            .foregroundColor(.white)
                                        
                                        Text("You made 3 mistakes")
                                            .font(.body)
                                            .foregroundColor(.white)
                                        
                                        Button(action: { viewModel.loadNextPuzzle() }) {
                                            Text("Try Another Puzzle")
                                                .font(.headline)
                                                .foregroundColor(.white)
                                                .padding()
                                                .background(CryptogramTheme.Colors.primary)
                                                .cornerRadius(10)
                                        }
                                    }
                                    .padding()
                                    .background(Color.black.opacity(0.7))
                                    .cornerRadius(10)
                                )
                        }
                    }
                )
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
    }
    .previewDevice(PreviewDevice(rawValue: "iPhone 16 Pro"))
}
