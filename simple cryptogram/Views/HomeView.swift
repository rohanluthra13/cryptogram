import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var viewModel: PuzzleViewModel
    @Environment(AppSettings.self) private var appSettings
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.typography) private var typography
    @EnvironmentObject private var navigationCoordinator: NavigationCoordinator
    @State private var showSettings = false
    @State private var showStats = false
    @State private var navigateToPuzzle = false
    @State private var showPuzzle = false
    @State private var puzzleOffset: CGFloat = 0
    @State private var puzzleOpenedFromCalendar = false
    @State private var selectedMode: PuzzleMode = .random
    @State private var showLengthSelection = false
    @State private var isBottomBarVisible = true
    @State private var bottomBarHideWorkItem: DispatchWorkItem?
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
                
                // Puzzle view (below overlays)
                if !FeatureFlag.newNavigation.isEnabled && showPuzzle {
                    PuzzleView(showPuzzle: $showPuzzle)
                        .transition(.move(edge: .trailing))
                        .offset(x: puzzleOffset)
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    // Only allow dragging from left edge
                                    if value.startLocation.x < 30 && value.translation.width > 0 {
                                        puzzleOffset = value.translation.width
                                    }
                                }
                                .onEnded { value in
                                    if value.startLocation.x < 30 && value.translation.width > 100 {
                                        withAnimation(.easeInOut(duration: 0.3)) {
                                            showPuzzle = false
                                            puzzleOffset = 0
                                        }
                                        // Reset flag after animation completes
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                            puzzleOpenedFromCalendar = false
                                        }
                                    } else {
                                        withAnimation(.spring()) {
                                            puzzleOffset = 0
                                        }
                                    }
                                }
                        )
                        .zIndex(100) // Below overlays but above main content
                }
                
                // Legacy overlays (on top of puzzle)
                HomeLegacyOverlays(
                    showSettings: $showSettings,
                    showStats: $showStats,
                    showCalendar: $showCalendar,
                    showInfoOverlay: $showInfoOverlay,
                    puzzleOpenedFromCalendar: $puzzleOpenedFromCalendar
                )
            }
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
            .onChange(of: showPuzzle) { oldValue, newValue in
                // When showing puzzle not from calendar, hide calendar
                if !oldValue && newValue && !puzzleOpenedFromCalendar {
                    showCalendar = false
                }
                // When returning from puzzle, reset length selection
                if oldValue && !newValue {
                    showLengthSelection = false
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .showCalendarOverlay)) { _ in
                showCalendar = true
            }
            .onReceive(NotificationCenter.default.publisher(for: .navigateToPuzzleFromCalendar)) { _ in
                showPuzzle = true
            }
            .onReceive(NotificationCenter.default.publisher(for: .navigateToPuzzle)) { _ in
                showPuzzle = true
            }
            .onReceive(NotificationCenter.default.publisher(for: .resetHomeViewState)) { _ in
                // Reset to initial state when returning from PuzzleView
                showLengthSelection = false
            }
        }
    }
    
    private func showBottomBarTemporarily() {
        withAnimation {
            isBottomBarVisible = true
        }
        bottomBarHideWorkItem?.cancel()
        
        let workItem = DispatchWorkItem {
            withAnimation {
                self.isBottomBarVisible = false
            }
        }
        bottomBarHideWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + PuzzleViewConstants.Animation.bottomBarAutoHideDelay, execute: workItem)
    }
}

#Preview {
    HomeView()
        .environmentObject(PuzzleViewModel())
        .environment(AppSettings())
        .environmentObject(ThemeManager())
        .environmentObject(NavigationCoordinator())
}
