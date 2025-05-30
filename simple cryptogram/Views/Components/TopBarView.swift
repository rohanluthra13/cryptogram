import SwiftUI

struct TopBarView: View {
    @EnvironmentObject private var viewModel: PuzzleViewModel
    @EnvironmentObject private var settingsViewModel: SettingsViewModel
    @EnvironmentObject private var navigationCoordinator: NavigationCoordinator
    @ObservedObject var uiState: PuzzleViewState
    @Environment(\.dismiss) private var dismiss
    @Environment(\.typography) private var typography
    
    private var shouldShowControls: Bool {
        viewModel.currentPuzzle != nil && uiState.isMainUIVisible
    }
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM dd yyyy"
        return formatter
    }()
    
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
                            endTime: viewModel.endTime,
                            isPaused: viewModel.isPaused || viewModel.isFailed,
                            settingsViewModel: settingsViewModel
                        )
                        .foregroundColor(CryptogramTheme.Colors.text)
                        .opacity(PuzzleViewConstants.Colors.activeIconOpacity)
                    }
                }
            }
            .frame(minWidth: 0, maxWidth: .infinity, alignment: .center)
            
            // Right: info button
            if shouldShowControls {
                VStack(alignment: .trailing, spacing: 0) {
                    Button(action: {
                        withAnimation {
                            uiState.showInfoOverlay.toggle()
                        }
                    }) {
                        Image(systemName: "questionmark")
                            .font(.system(size: PuzzleViewConstants.Sizes.questionMarkSize, design: typography.fontOption.design))
                            .foregroundColor(CryptogramTheme.Colors.text)
                            .opacity(uiState.showInfoOverlay ? PuzzleViewConstants.Colors.activeIconOpacity : PuzzleViewConstants.Colors.iconOpacity)
                            .frame(width: PuzzleViewConstants.Sizes.iconButtonFrame, height: PuzzleViewConstants.Sizes.iconButtonFrame)
                            .accessibilityLabel("About / Info")
                    }
                    
                    // Daily puzzle date below info button
                    if viewModel.isDailyPuzzle, let puzzleDate = viewModel.currentDailyPuzzleDate {
                        Text(puzzleDate, formatter: dateFormatter)
                            .font(typography.caption)
                            .foregroundColor(CryptogramTheme.Colors.text)
                            .opacity(0.7)
                            .padding(.top, 15) // Space between info button and date
                            .offset(x: -14) // Move text left to better align with icon above
                    }
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
        .environmentObject(NavigationCoordinator())
}
