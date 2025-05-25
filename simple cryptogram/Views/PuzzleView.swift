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

            // --- Floating Question Mark Button ---
            FloatingInfoButton(uiState: uiState)
                .environmentObject(viewModel)

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
                    uiState.showCompletionView = true
                }
                // Daily puzzle completion state is now handled internally by DailyPuzzleManager
            }
        }
        .navigationBarHidden(true)
        .animation(.easeIn(duration: PuzzleViewConstants.Animation.failedAnimationDuration), value: viewModel.isFailed)
        .animation(.easeIn(duration: PuzzleViewConstants.Animation.pausedAnimationDuration), value: viewModel.isPaused)
        .onAppear {
            uiState.showBottomBarTemporarily()
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
