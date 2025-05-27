import SwiftUI
import Combine

struct PuzzleView: View {
    @EnvironmentObject private var viewModel: PuzzleViewModel
    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject private var settingsViewModel: SettingsViewModel
    @EnvironmentObject private var appSettings: AppSettings
    @StateObject private var uiState = PuzzleViewState()
    
    // Create a custom binding for the layout
    private var layoutBinding: Binding<NavigationBarLayout> {
        Binding(
            get: { UserSettings.navigationBarLayout },
            set: { UserSettings.navigationBarLayout = $0 }
        )
    }
    
    var body: some View {
        ZStack {
            // Background
            CryptogramTheme.Colors.background
                .ignoresSafeArea()
            
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
            BottomBarView(uiState: uiState)
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
                
                // Show completion view after a delay
                withAnimation(.easeOut(duration: PuzzleViewConstants.Animation.puzzleSwitchDuration).delay(2.0)) {
                    // Show different completion view for daily puzzles
                    if viewModel.isDailyPuzzle {
                        uiState.showDailyCompletionView = true
                    } else {
                        uiState.showCompletionView = true
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .animation(.easeIn(duration: PuzzleViewConstants.Animation.failedAnimationDuration), value: viewModel.isFailed)
        .animation(.easeIn(duration: PuzzleViewConstants.Animation.pausedAnimationDuration), value: viewModel.isPaused)
        .onAppear {
            uiState.showBottomBarTemporarily()
            
            // Check if daily puzzle is already completed and skip directly to completion view
            if viewModel.isDailyPuzzle && viewModel.isComplete && viewModel.session.endTime != nil {
                // Skip the wiggle animation and go straight to completion view
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.easeOut(duration: PuzzleViewConstants.Animation.puzzleSwitchDuration)) {
                        uiState.showDailyCompletionView = true
                    }
                }
            }
        }
        .onDisappear {
            // viewModel.pauseTimer()
        }
    }
    
}

#Preview {
    NavigationView {
        PuzzleView()
            .environmentObject(PuzzleViewModel())
            .environmentObject(ThemeManager())
            .environmentObject(SettingsViewModel())
    }
}
