import SwiftUI
import Combine

struct PuzzleView: View {
    @EnvironmentObject private var viewModel: PuzzleViewModel
    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject private var settingsViewModel: SettingsViewModel
    @Environment(AppSettings.self) private var appSettings
    @EnvironmentObject private var navigationCoordinator: NavigationCoordinator
    @StateObject private var uiState = PuzzleViewState()
    @Environment(\.dismiss) private var dismiss
    @Binding var showPuzzle: Bool
    
    // Create a custom binding for the layout
    private var layoutBinding: Binding<NavigationBarLayout> {
        Binding(
            get: { appSettings.navigationBarLayout },
            set: { appSettings.navigationBarLayout = $0 }
        )
    }
    
    var body: some View {
        ZStack {
            // Background
            CryptogramTheme.Colors.background
                .ignoresSafeArea()
            
            // Only show puzzle content if it's not a completed daily puzzle
            if !viewModel.isCompletedDailyPuzzle {
                // --- Persistent Top Bar (always visible) ---
                VStack {
                    TopBarView(uiState: uiState)
                        .environmentObject(viewModel)
                        .environmentObject(settingsViewModel)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .zIndex(0)

                // --- Main Content Block (puzzle, nav bar, keyboard) pushed to bottom ---
                VStack(spacing: 0) {
                    Spacer(minLength: 0)
                    MainContentView(
                        uiState: uiState,
                        layoutBinding: layoutBinding
                    )
                    .environmentObject(viewModel)
                    
                    // --- Bottom Banner Placeholder (for keyboard spacing) ---
                    Color.clear
                        .frame(height: PuzzleViewConstants.Spacing.bottomBarHeight)
                        .frame(maxWidth: .infinity)
                        .ignoresSafeArea(edges: .bottom)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                .zIndex(0)

                // --- Persistent Bottom Banner Above All Overlays ---
                BottomBarView(uiState: uiState, showPuzzle: $showPuzzle)
            }
        }
        .overlayManager(uiState: uiState)
        .environmentObject(viewModel)
        .environmentObject(themeManager)
        .environmentObject(settingsViewModel)
        .onChange(of: viewModel.isComplete) { oldValue, isComplete in
            if isComplete {
                // Add haptic feedback for completion
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
                
                // First trigger wiggle animation
                viewModel.triggerCompletionWiggle()
                
                // Then transition to completion view with a slight delay
                withAnimation(.easeOut(duration: PuzzleViewConstants.Animation.puzzleSwitchDuration).delay(PuzzleViewConstants.Animation.completionDelay)) {
                    // Show different completion view for daily puzzles
                    if viewModel.isDailyPuzzle {
                        uiState.showDailyCompletionView = true
                    } else {
                        uiState.showCompletionView = true
                    }
                }
                // Daily puzzle completion state is now handled internally by DailyPuzzleManager
            }
        }
        .onChange(of: viewModel.isFailed) { oldValue, isFailed in
            if isFailed {
                // Add haptic feedback for failure
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.error)
                
                // Don't show completion view - just keep the game over overlay
            }
        }
        .animation(.easeIn(duration: PuzzleViewConstants.Animation.failedAnimationDuration), value: viewModel.isFailed)
        .animation(.easeIn(duration: PuzzleViewConstants.Animation.pausedAnimationDuration), value: viewModel.isPaused)
        .onAppear {
            if viewModel.isCompletedDailyPuzzle {
                // Show completion view immediately for completed daily puzzles
                uiState.showDailyCompletionView = true
            } else {
                // Normal puzzle flow
                uiState.showBottomBarTemporarily()
            }
        }
    }
    
}

#Preview {
    PuzzleView(showPuzzle: .constant(true))
        .environmentObject(PuzzleViewModel())
        .environmentObject(ThemeManager())
        .environmentObject(SettingsViewModel())
        .environment(AppSettings())
        .environmentObject(NavigationCoordinator())
}
