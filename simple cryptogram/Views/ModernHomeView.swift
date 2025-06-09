import SwiftUI

/// Modernized HomeView using new NavigationState and HomeViewModel architecture
/// Clean separation between presentation and business logic
struct ModernHomeView: View {
    // MARK: - New Architecture Dependencies
    @StateObject private var homeViewModel = HomeViewModel()
    @StateObject private var navigationState = NavigationState()
    
    // MARK: - Legacy Dependencies (for compatibility)
    @EnvironmentObject private var businessLogic: BusinessLogicCoordinator
    @Environment(AppSettings.self) private var appSettings
    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject private var settingsViewModel: SettingsViewModel
    @Environment(\.typography) private var typography
    
    var body: some View {
        NavigationStack(path: $navigationState.navigationPath) {
            ZStack {
                // Background
                CryptogramTheme.Colors.background
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Main content
                    VStack {
                        Text("Modern Home View")
                            .font(.title)
                        
                        Button("Load Random Puzzle") {
                            handlePuzzleSelection(type: .random)
                        }
                        
                        Button("Load Daily Puzzle") {
                            handlePuzzleSelection(type: .daily)
                        }
                        
                        Button("Load with Exclusions") {
                            handlePuzzleSelection(type: .exclusions)
                        }
                    }
                    
                    // Bottom bar
                    BottomBarSection()
                }
                
                // Floating info button (top-right corner)
                if navigationState.isMainUIVisible {
                    FloatingInfoButton()
                }
            }
            .commonOverlays(
                showSettings: settingsBinding,
                showStats: statsBinding,
                showCalendar: calendarBinding,
                showInfoOverlay: infoBinding
            )
            .navigationDestination(for: Puzzle.self) { puzzle in
                ModernPuzzleView(puzzle: puzzle)
                    .environmentObject(businessLogic)
                    .environmentObject(navigationState)
            }
            .onAppear {
                setupViewAppearance()
            }
            .onReceive(NotificationCenter.default.publisher(for: .showCalendarOverlay)) { _ in
                navigationState.presentOverlay(OverlayType.calendar)
            }
        }
        .environmentObject(navigationState)
    }
    
    // MARK: - Computed Properties
    
    private var settingsBinding: Binding<Bool> {
        Binding(
            get: { navigationState.isPresenting(OverlayType.settings) },
            set: { if $0 { navigationState.presentOverlay(OverlayType.settings) } else { navigationState.dismissOverlay() } }
        )
    }
    
    private var statsBinding: Binding<Bool> {
        Binding(
            get: { navigationState.isPresenting(OverlayType.stats) },
            set: { if $0 { navigationState.presentOverlay(OverlayType.stats) } else { navigationState.dismissOverlay() } }
        )
    }
    
    private var calendarBinding: Binding<Bool> {
        Binding(
            get: { navigationState.isPresenting(OverlayType.calendar) },
            set: { if $0 { navigationState.presentOverlay(OverlayType.calendar) } else { navigationState.dismissOverlay() } }
        )
    }
    
    private var infoBinding: Binding<Bool> {
        Binding(
            get: { navigationState.isPresenting(OverlayType.info) },
            set: { if $0 { navigationState.presentOverlay(OverlayType.info) } else { navigationState.dismissOverlay() } }
        )
    }
    
    // MARK: - Subviews
    
    @ViewBuilder
    private func BottomBarSection() -> some View {
        ZStack {
            // Visible bottom bar with icons
            if navigationState.isBottomBarVisible {
                HStack {
                    // Stats button
                    Button(action: navigationState.toggleStats) {
                        Image(systemName: "chart.bar")
                            .font(.system(size: PuzzleViewConstants.Sizes.statsIconSize))
                            .foregroundColor(CryptogramTheme.Colors.text)
                            .opacity(PuzzleViewConstants.Colors.iconOpacity)
                            .frame(width: PuzzleViewConstants.Sizes.iconButtonFrame, height: PuzzleViewConstants.Sizes.iconButtonFrame)
                    }
                    
                    Spacer()
                    
                    // Settings button
                    Button(action: navigationState.toggleSettings) {
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
            if !navigationState.isBottomBarVisible && navigationState.isMainUIVisible {
                Rectangle()
                    .fill(Color.clear)
                    .frame(height: PuzzleViewConstants.Spacing.bottomBarHeight)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        navigationState.showBottomBarTemporarily()
                    }
            }
        }
        .frame(height: PuzzleViewConstants.Spacing.bottomBarHeight)
    }
    
    @ViewBuilder
    private func FloatingInfoButton() -> some View {
        VStack {
            HStack {
                Spacer()
                Button(action: navigationState.toggleInfo) {
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
    
    // MARK: - Action Handlers
    
    private func handlePuzzleSelection(type: PuzzleSelectionType) {
        Task {
            var puzzle: Puzzle?
            
            switch type {
            case .random:
                puzzle = await homeViewModel.loadRandomPuzzle()
            case .daily:
                if let result = await homeViewModel.loadTodaysDailyPuzzle() {
                    puzzle = result.puzzle
                    // Handle daily puzzle progress restoration if needed
                }
            case .exclusions:
                puzzle = await homeViewModel.loadPuzzleWithExclusions()
            }
            
            if let puzzle = puzzle {
                navigationState.navigateToPuzzle(puzzle)
            }
        }
    }
    
    private func setupViewAppearance() {
        navigationState.showBottomBarTemporarily()
        homeViewModel.resetViewState()
        
        // Check if we should show calendar on return
        if appSettings.shouldShowCalendarOnReturn {
            navigationState.presentOverlay(.calendar)
            appSettings.shouldShowCalendarOnReturn = false
        }
    }
}

// MARK: - Supporting Types

enum PuzzleSelectionType {
    case random
    case daily
    case exclusions
}

// Use existing HomeMainContent from Components

#Preview {
    ModernHomeView()
        .environmentObject(BusinessLogicCoordinator())
        .environment(AppSettings())
        .environmentObject(ThemeManager())
        .environmentObject(SettingsViewModel())
}