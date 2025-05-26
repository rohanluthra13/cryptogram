import SwiftUI

// Z-Index hierarchy constants
enum OverlayZIndex {
    static let pauseGameOver: Double = 120
    static let info: Double = 125
    static let floatingInfo: Double = 130
    static let statsSettings: Double = 150
    static let bottomBar: Double = 190
    static let completion: Double = 200
    static let dailyCompletion: Double = 201
}

struct OverlayManager: ViewModifier {
    @EnvironmentObject private var viewModel: PuzzleViewModel
    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject private var settingsViewModel: SettingsViewModel
    @ObservedObject var uiState: PuzzleViewState
    @Namespace private var statsOverlayNamespace
    
    func body(content: Content) -> some View {
        content
            .overlay(infoOverlay)
            .overlay(pauseOverlay)
            .overlay(gameOverOverlay)
            .overlay(statsOverlay)
            .overlay(settingsOverlay)
            .overlay(completionOverlay)
            .overlay(dailyCompletionOverlay)
    }
    
    // MARK: - Info Overlay
    @ViewBuilder
    private var infoOverlay: some View {
        if uiState.showInfoOverlay {
            ZStack(alignment: .top) {
                // Background layer that dismisses overlay on tap
                CryptogramTheme.Colors.background
                    .ignoresSafeArea()
                    .opacity(PuzzleViewConstants.Overlay.backgroundOpacity)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation {
                            uiState.showInfoOverlay = false
                        }
                    }
                // Foreground overlay content - interactive
                VStack {
                    Spacer(minLength: PuzzleViewConstants.Overlay.infoOverlayTopSpacing)
                    ScrollView {
                        InfoOverlayView()
                    }
                    .padding(.horizontal, PuzzleViewConstants.Overlay.overlayHorizontalPadding)
                    Spacer()
                }
            }
            .transition(.opacity)
            .animation(.easeInOut(duration: PuzzleViewConstants.Animation.overlayDuration), value: uiState.showInfoOverlay)
            .zIndex(OverlayZIndex.info)
        }
    }
    
    // MARK: - Pause Overlay
    @ViewBuilder
    private var pauseOverlay: some View {
        if viewModel.isPaused && !uiState.showCompletionView && !uiState.showSettings && !uiState.showStatsOverlay {
            ZStack {
                Color.black.opacity(0.5)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
                VStack {
                    Spacer()
                    Text("paused")
                        .font(CryptogramTheme.Typography.body)
                        .fontWeight(.bold)
                        .foregroundColor(CryptogramTheme.Colors.text)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 12)
                        .padding(.bottom, 240)
                        .onTapGesture {
                            viewModel.togglePause()
                        }
                        .allowsHitTesting(true)
                }
            }
            .zIndex(OverlayZIndex.pauseGameOver)
            .transition(.opacity)
            .animation(.easeInOut(duration: PuzzleViewConstants.Animation.overlayDuration), value: viewModel.isPaused)
        }
    }
    
    // MARK: - Game Over Overlay
    @ViewBuilder
    private var gameOverOverlay: some View {
        if viewModel.isFailed && !uiState.showCompletionView && !uiState.showSettings && !uiState.showStatsOverlay {
            ZStack {
                Color.black.opacity(0.5)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
                VStack {
                    Spacer()
                    Text("game over")
                        .font(CryptogramTheme.Typography.body)
                        .fontWeight(.bold)
                        .foregroundColor(CryptogramTheme.Colors.text)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 12)
                        .padding(.bottom, 240)
                        .allowsHitTesting(false)
                }
            }
            .zIndex(OverlayZIndex.pauseGameOver)
            .transition(.opacity)
            .animation(.easeInOut(duration: PuzzleViewConstants.Animation.overlayDuration), value: viewModel.isFailed)
        }
    }
    
    // MARK: - Stats Overlay
    @ViewBuilder
    private var statsOverlay: some View {
        if uiState.showStatsOverlay {
            CryptogramTheme.Colors.surface
                .opacity(0.95)
                .ignoresSafeArea()
                .onTapGesture { uiState.showStatsOverlay = false }
                .overlay(
                    VStack(spacing: 0) {
                        Spacer(minLength: 0)
                        UserStatsView(viewModel: viewModel)
                            .padding(.top, 24)
                    }
                )
                .matchedGeometryEffect(id: "statsOverlay", in: statsOverlayNamespace)
                .transition(.opacity)
                .animation(.easeInOut(duration: PuzzleViewConstants.Animation.overlayDuration), value: uiState.showStatsOverlay)
                .zIndex(OverlayZIndex.statsSettings)
        }
    }
    
    // MARK: - Settings Overlay
    @ViewBuilder
    private var settingsOverlay: some View {
        if uiState.showSettings {
            CryptogramTheme.Colors.surface
                .opacity(0.95)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    uiState.showSettings = false
                }
                .overlay(
                    SettingsContentView()
                        .padding(.horizontal, PuzzleViewConstants.Overlay.overlayHorizontalPadding)
                        .padding(.vertical, 20)
                        .environmentObject(viewModel)
                        .environmentObject(themeManager)
                        .environmentObject(settingsViewModel)
                )
                .zIndex(OverlayZIndex.statsSettings)
        }
    }
    
    // MARK: - Completion Overlay
    @ViewBuilder
    private var completionOverlay: some View {
        if uiState.showCompletionView {
            PuzzleCompletionView(showCompletionView: $uiState.showCompletionView)
                .environmentObject(themeManager)
                .environmentObject(viewModel)
                .zIndex(OverlayZIndex.completion)
        }
    }
    
    // MARK: - Daily Completion Overlay
    @ViewBuilder
    private var dailyCompletionOverlay: some View {
        if uiState.showDailyCompletionView {
            PuzzleCompletionView(showCompletionView: $uiState.showDailyCompletionView, hideStats: true)
                .environmentObject(themeManager)
                .environmentObject(viewModel)
                .zIndex(OverlayZIndex.dailyCompletion)
        }
    }
}

// Extension to make it easy to apply the overlay manager
extension View {
    func overlayManager(uiState: PuzzleViewState) -> some View {
        self.modifier(OverlayManager(uiState: uiState))
    }
}