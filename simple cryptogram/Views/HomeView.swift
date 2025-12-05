import SwiftUI

struct HomeView: View {
    @Environment(PuzzleViewModel.self) private var viewModel
    @Environment(AppSettings.self) private var appSettings
    @Environment(ThemeManager.self) private var themeManager
    @Environment(SettingsViewModel.self) private var settingsViewModel
    @Environment(\.typography) private var typography
    @Environment(NavigationCoordinator.self) private var navigationCoordinator
    @State private var showSettings = false
    @State private var showStats = false
    @State private var selectedMode: PuzzleMode = .random
    @State private var showLengthSelection = false
    @State private var isBottomBarVisible = true
    @State private var bottomBarHideTask: Task<Void, Never>?
    @State private var showCalendar = false
    @State private var showInfoOverlay = false
    
    enum PuzzleMode {
        case random
        case daily
    }
    
    // Computed property to check if today's daily puzzle is completed
    private var isDailyPuzzleCompleted: Bool {
        // Check if today's daily puzzle is completed regardless of current puzzle
        return viewModel.isTodaysDailyPuzzleCompleted
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                CryptogramTheme.Colors.background
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Main content
                    HomeMainContent(
                        showLengthSelection: $showLengthSelection,
                        selectedMode: $selectedMode,
                        showCalendar: $showCalendar,
                        isDailyPuzzleCompleted: isDailyPuzzleCompleted
                    )
                    
                    // Bottom bar
                    ZStack {
                        // Visible bottom bar with icons
                        if isBottomBarVisible || showSettings || showStats {
                            HStack {
                                // Stats button
                                Button(action: {
                                    showStats.toggle()
                                    showBottomBarTemporarily()
                                }) {
                                    Image(systemName: "chart.bar")
                                        .font(.system(size: PuzzleViewConstants.Sizes.statsIconSize))
                                        .foregroundColor(CryptogramTheme.Colors.text)
                                        .opacity(PuzzleViewConstants.Colors.iconOpacity)
                                        .frame(width: PuzzleViewConstants.Sizes.iconButtonFrame, height: PuzzleViewConstants.Sizes.iconButtonFrame)
                                }
                                
                                Spacer()
                                
                                // Settings button
                                Button(action: {
                                    showSettings.toggle()
                                    showBottomBarTemporarily()
                                }) {
                                    Image(systemName: "gearshape")
                                        .font(.system(size: PuzzleViewConstants.Sizes.settingsIconSize))
                                        .foregroundColor(CryptogramTheme.Colors.text)
                                        .opacity(PuzzleViewConstants.Colors.iconOpacity)
                                        .frame(width: PuzzleViewConstants.Sizes.iconButtonFrame, height: PuzzleViewConstants.Sizes.iconButtonFrame)
                                }
                            }
                            .frame(height: PuzzleViewConstants.Spacing.bottomBarHeight)
                            .padding(.horizontal, PuzzleViewConstants.Spacing.bottomBarHorizontalPadding)
                            .transition(.opacity)
                        }
                        
                        // Invisible tap area to bring back bottom bar
                        if !isBottomBarVisible && !showSettings && !showStats {
                            Rectangle()
                                .fill(Color.clear)
                                .frame(height: PuzzleViewConstants.Spacing.bottomBarHeight)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    showBottomBarTemporarily()
                                }
                        }
                    }
                    .frame(height: PuzzleViewConstants.Spacing.bottomBarHeight)
                }
                
                // Legacy overlays are extracted to a separate component
                
                // Floating info button (top-right corner) - only show when no overlays are active
                if !showInfoOverlay && !showSettings && !showStats && !showCalendar {
                    VStack {
                        HStack {
                            Spacer()
                            Button(action: {
                                withAnimation {
                                    showInfoOverlay.toggle()
                                }
                            }) {
                                Image(systemName: "questionmark")
                                    .font(.system(size: PuzzleViewConstants.Sizes.questionMarkSize, design: typography.fontOption.design))
                                    .foregroundColor(CryptogramTheme.Colors.text)
                                    .opacity(PuzzleViewConstants.Colors.iconOpacity)
                                    .frame(width: PuzzleViewConstants.Sizes.iconButtonFrame, height: PuzzleViewConstants.Sizes.iconButtonFrame)
                                    .accessibilityLabel("About / Info")
                            }
                        }
                        .padding(.top, 0)
                        .padding(.horizontal, PuzzleViewConstants.Spacing.topBarPadding)
                        .frame(maxWidth: .infinity)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .zIndex(OverlayZIndex.floatingInfo)
                }
                
                
                // Unified overlays (on top of puzzle)
                EmptyView()
            }
            .commonOverlays(
                showSettings: $showSettings,
                showStats: $showStats,
                showCalendar: $showCalendar,
                showInfoOverlay: $showInfoOverlay
            )
            .onAppear {
                showBottomBarTemporarily()
                // Reset to initial state when returning to HomeView
                showLengthSelection = false
                
                // Check if we should show calendar on return
                if appSettings.shouldShowCalendarOnReturn {
                    showCalendar = true
                    appSettings.shouldShowCalendarOnReturn = false
                }
            }
        }
    }
    
    private func showBottomBarTemporarily() {
        withAnimation {
            isBottomBarVisible = true
        }
        bottomBarHideTask?.cancel()

        bottomBarHideTask = Task {
            try? await Task.sleep(for: .seconds(PuzzleViewConstants.Animation.bottomBarAutoHideDelay))
            guard !Task.isCancelled else { return }
            withAnimation {
                isBottomBarVisible = false
            }
        }
    }
}

#Preview {
    HomeView()
        .environment(PuzzleViewModel())
        .environment(AppSettings())
        .environment(ThemeManager())
        .environment(SettingsViewModel())
        .environment(NavigationCoordinator())
}
