import SwiftUI

struct TopBarView: View {
    @EnvironmentObject private var viewModel: PuzzleViewModel
    @EnvironmentObject private var settingsViewModel: SettingsViewModel
    @ObservedObject var uiState: PuzzleViewState
    @Environment(\.dismiss) private var dismiss
    
    private var shouldShowControls: Bool {
        viewModel.currentPuzzle != nil && uiState.isMainUIVisible
    }
    
    var body: some View {
        HStack(alignment: .top) {
            // Left: mistakes & hints
            if shouldShowControls {
                VStack(spacing: 2) {
                    HStack {
                        MistakesView(mistakeCount: viewModel.mistakeCount)
                        Spacer()
                    }
                    HStack {
                        HintsView(
                            hintCount: viewModel.hintCount,
                            onRequestHint: { viewModel.revealCell() },
                            maxHints: viewModel.nonSymbolCells.count / 4
                        )
                        Spacer()
                    }
                }
                .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
            }
            
            // Center: timer
            ZStack {
                if shouldShowControls {
                    let timerInactive = (viewModel.startTime ?? Date.distantFuture) > Date()
                    if !timerInactive {
                        TimerView(
                            startTime: viewModel.startTime ?? Date.distantFuture,
                            isPaused: viewModel.isPaused || viewModel.isFailed,
                            settingsViewModel: settingsViewModel
                        )
                        .foregroundColor(CryptogramTheme.Colors.text)
                        .opacity(PuzzleViewConstants.Colors.activeIconOpacity)
                    }
                }
            }
            .frame(minWidth: 0, maxWidth: .infinity, alignment: .center)
            
            // Right: home button
            if shouldShowControls {
                // Home button
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "house")
                        .font(.title3)
                        .foregroundColor(CryptogramTheme.Colors.text)
                        .opacity(PuzzleViewConstants.Colors.iconOpacity)
                        .frame(width: PuzzleViewConstants.Sizes.iconButtonFrame, height: PuzzleViewConstants.Sizes.iconButtonFrame)
                        .accessibilityLabel("Return to Home")
                }
                .frame(minWidth: 0, maxWidth: .infinity, alignment: .trailing)
            }
        }
        .padding(.top, 0)
        .padding(.horizontal, PuzzleViewConstants.Spacing.topBarPadding)
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    TopBarView(uiState: PuzzleViewState())
        .environmentObject(PuzzleViewModel())
        .environmentObject(SettingsViewModel())
}