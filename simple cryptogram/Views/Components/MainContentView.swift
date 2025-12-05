import SwiftUI

struct MainContentView: View {
    @Environment(PuzzleViewModel.self) private var viewModel
    var uiState: PuzzleViewState
    let layoutBinding: Binding<NavigationBarLayout>
    
    var body: some View {
        if viewModel.currentPuzzle != nil {
            VStack(spacing: 0) {
                Group {
                    ScrollView {
                        WordAwarePuzzleGrid()
                            .padding(.horizontal, PuzzleViewConstants.Spacing.puzzleGridHorizontalPadding)
                            .allowsHitTesting(!viewModel.isPaused)
                    }
                    .layoutPriority(1)
                    .frame(maxWidth: .infinity)
                    .frame(maxHeight: UIScreen.main.bounds.height * PuzzleViewConstants.Sizes.puzzleGridMaxHeightRatio)
                    .padding(.horizontal, PuzzleViewConstants.Spacing.mainContentHorizontalPadding)
                    .padding(.top, PuzzleViewConstants.Spacing.puzzleGridTopPadding)
                    .padding(.bottom, PuzzleViewConstants.Spacing.puzzleGridBottomPadding)

                    Rectangle()
                        .fill(Color.clear)
                        .frame(height: PuzzleViewConstants.Spacing.clearSpacerHeight)
                        .allowsHitTesting(false)
                }
                .opacity(uiState.isSwitchingPuzzle ? 0 : 1)
                .animation(.easeInOut(duration: PuzzleViewConstants.Animation.puzzleSwitchDuration), value: uiState.isSwitchingPuzzle)

                // Navigation Bar with all controls in a single layer
                NavigationBarView(
                    onMoveLeft: { viewModel.moveToAdjacentCell(direction: -1) },
                    onMoveRight: { viewModel.moveToAdjacentCell(direction: 1) },
                    onTogglePause: viewModel.togglePause,
                    onNextPuzzle: {
                        Task {
                            await uiState.animatePuzzleSwitch()
                            viewModel.refreshPuzzleWithCurrentSettings()
                            uiState.endPuzzleSwitch()
                        }
                    },
                    isPaused: viewModel.isPaused,
                    showCenterButtons: true, // Show all buttons in the nav bar
                    isDailyPuzzle: viewModel.isDailyPuzzle,
                    layout: layoutBinding
                )
                .allowsHitTesting(!viewModel.isFailed)
                
                // Keyboard View
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
                    },
                    completedLetters: viewModel.completedLetters
                )
                .padding(.bottom, 0)
                .padding(.horizontal, PuzzleViewConstants.Spacing.keyboardHorizontalPadding)
                .frame(maxWidth: .infinity)
                .allowsHitTesting(!viewModel.isPaused)
            }
            .frame(maxWidth: .infinity)
        }
    }
}

#Preview {
    MainContentView(
        uiState: PuzzleViewState(),
        layoutBinding: .constant(.leftLayout)
    )
    .environment(PuzzleViewModel())
    .environment(AppSettings())
}