import SwiftUI

/// Represents the different completion view states
enum CompletionState: Equatable {
    case none
    case regular
    case daily
}

struct PuzzleView: View {
    @Environment(PuzzleViewModel.self) private var viewModel
    @Environment(ThemeManager.self) private var themeManager
    @Environment(AppSettings.self) private var appSettings
    @Environment(NavigationCoordinator.self) private var navigationCoordinator
    @Binding var showPuzzle: Bool

    // Overlay state
    @State private var showSettings = false
    @State private var showStats = false
    @State private var showCalendar = false
    @State private var showInfo = false
    @State private var completionState: CompletionState = .none

    // Bottom bar auto-hide
    @State private var isBottomBarVisible = true
    @State private var bottomBarHideTask: Task<Void, Never>?

    // Puzzle switch animation
    @State private var isSwitchingPuzzle = false

    // Create a custom binding for the layout
    private var layoutBinding: Binding<NavigationBarLayout> {
        Binding(
            get: { appSettings.navigationBarLayout },
            set: { appSettings.navigationBarLayout = $0 }
        )
    }

    private var showControls: Bool {
        viewModel.currentPuzzle != nil && !showSettings && !showStats && !showCalendar && completionState == .none
    }

    var body: some View {
        ZStack {
            // Background
            CryptogramTheme.Colors.background
                .ignoresSafeArea()

            // Show puzzle content if completion view is not showing or it's not a completed daily puzzle
            if completionState == .none && !viewModel.isCompletedDailyPuzzle {
                VStack(spacing: 0) {
                    TopBarView(showInfoOverlay: $showInfo, showControls: showControls)
                    mainContent
                    bottomBar
                }
            }

            // Overlays
            if showSettings {
                FullScreenOverlay(isPresented: $showSettings, backgroundColor: CryptogramTheme.Colors.surface) {
                    SettingsContentView()
                        .padding(.horizontal, PuzzleViewConstants.Overlay.overlayHorizontalPadding)
                        .padding(.vertical, 20)
                        .background(Color.clear)
                        .environment(viewModel)
                        .environment(themeManager)
                        .environment(appSettings)
                }
                .zIndex(150)
            }

            if showStats {
                FullScreenOverlay(isPresented: $showStats, backgroundColor: CryptogramTheme.Colors.surface) {
                    VStack(spacing: 0) {
                        Spacer(minLength: 0)
                        UserStatsView(viewModel: viewModel)
                            .padding(.top, 24)
                    }
                }
                .zIndex(150)
            }

            if showCalendar {
                FullScreenOverlay(isPresented: $showCalendar) {
                    ContinuousCalendarView(
                        showCalendar: $showCalendar,
                        onSelectDate: { date in
                            viewModel.loadDailyPuzzle(for: date)
                            if let puzzle = viewModel.currentPuzzle {
                                navigationCoordinator.navigateToPuzzle(puzzle)
                            }
                        }
                    )
                    .id(viewModel.dailyCompletionVersion)
                    .environment(viewModel)
                    .environment(appSettings)
                }
                .zIndex(150)
            }

            if showInfo {
                FullScreenOverlay(isPresented: $showInfo) {
                    VStack {
                        Spacer(minLength: PuzzleViewConstants.Overlay.infoOverlayTopSpacing)
                        ScrollView {
                            InfoOverlayView()
                        }
                        .padding(.horizontal, PuzzleViewConstants.Overlay.overlayHorizontalPadding)
                        Spacer()
                    }
                }
                .zIndex(125)
            }

            if viewModel.isPaused && completionState == .none && !showSettings && !showStats {
                pauseOverlay
                    .zIndex(120)
            }

            if viewModel.isFailed && completionState == .none && !showSettings && !showStats {
                GameOverOverlay(
                    showSettings: $showSettings,
                    showStats: $showStats,
                    showInfoOverlay: $showInfo
                )
                .zIndex(120)
            }

            if completionState == .regular {
                PuzzleCompletionView(showCompletionView: Binding(
                    get: { completionState == .regular },
                    set: { if !$0 { completionState = .none } }
                ))
                .environment(themeManager)
                .environment(viewModel)
                .environment(navigationCoordinator)
                .environment(appSettings)
                .transition(.opacity)
                .animation(.easeInOut(duration: 0.2), value: completionState)
                .zIndex(200)
            }

            if completionState == .daily {
                PuzzleCompletionView(showCompletionView: Binding(
                    get: { completionState == .daily },
                    set: { if !$0 { completionState = .none } }
                ), isDailyPuzzle: true)
                .environment(themeManager)
                .environment(viewModel)
                .environment(navigationCoordinator)
                .environment(appSettings)
                .transition(.opacity)
                .animation(.easeInOut(duration: 0.2), value: completionState)
                .zIndex(201)
            }
        }
        .gesture(
            DragGesture()
                .onEnded { value in
                    if value.translation.width > 100 && abs(value.translation.height) < 100 {
                        navigationCoordinator.navigateBack()
                    }
                }
        )
        .navigationBarBackButtonHidden(true)
        .onChange(of: viewModel.isComplete) { oldValue, isComplete in
            if isComplete {
                viewModel.saveCompletionIfDaily()
                viewModel.triggerCompletionWiggle()

                withAnimation(.easeOut(duration: PuzzleViewConstants.Animation.puzzleSwitchDuration).delay(PuzzleViewConstants.Animation.completionDelay)) {
                    completionState = viewModel.isDailyPuzzle ? .daily : .regular
                }
            }
        }
        .sensoryFeedback(.success, trigger: viewModel.isComplete) { _, isComplete in isComplete }
        .sensoryFeedback(.error, trigger: viewModel.isFailed) { _, isFailed in isFailed }
        .animation(.easeIn(duration: PuzzleViewConstants.Animation.failedAnimationDuration), value: viewModel.isFailed)
        .animation(.easeIn(duration: PuzzleViewConstants.Animation.pausedAnimationDuration), value: viewModel.isPaused)
        .onAppear {
            if viewModel.isCompletedDailyPuzzle {
                if completionState == .none {
                    completionState = .daily
                }
            } else {
                showBottomBarTemporarily()
            }
        }
        .onDisappear {
            completionState = .none
        }
    }

    // MARK: - Main Content (inlined from MainContentView)

    @ViewBuilder
    private var mainContent: some View {
        if viewModel.currentPuzzle != nil {
            ScrollView {
                WordAwarePuzzleGrid()
                    .padding(.horizontal, PuzzleViewConstants.Spacing.puzzleGridHorizontalPadding)
                    .allowsHitTesting(!viewModel.isPaused)
            }
            .padding(.horizontal, PuzzleViewConstants.Spacing.mainContentHorizontalPadding)
            .padding(.bottom, PuzzleViewConstants.Spacing.puzzleGridBottomPadding)
            .opacity(isSwitchingPuzzle ? 0 : 1)
            .animation(.easeInOut(duration: PuzzleViewConstants.Animation.puzzleSwitchDuration), value: isSwitchingPuzzle)

            NavigationBarView(
                onMoveLeft: { viewModel.moveToAdjacentCell(direction: -1) },
                onMoveRight: { viewModel.moveToAdjacentCell(direction: 1) },
                onTogglePause: viewModel.togglePause,
                onNextPuzzle: {
                    Task {
                        withAnimation(.easeInOut(duration: PuzzleViewConstants.Animation.puzzleSwitchDuration)) {
                            isSwitchingPuzzle = true
                        }
                        try? await Task.sleep(for: .seconds(PuzzleViewConstants.Animation.puzzleSwitchDuration))
                        viewModel.refreshPuzzleWithCurrentSettings()
                        withAnimation(.easeInOut(duration: PuzzleViewConstants.Animation.puzzleSwitchDuration)) {
                            isSwitchingPuzzle = false
                        }
                    }
                },
                isPaused: viewModel.isPaused,
                showCenterButtons: true,
                isDailyPuzzle: viewModel.isDailyPuzzle,
                layout: layoutBinding
            )
            .allowsHitTesting(!viewModel.isFailed)

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
            .padding(.horizontal, PuzzleViewConstants.Spacing.keyboardHorizontalPadding)
            .frame(maxWidth: .infinity)
            .allowsHitTesting(!viewModel.isPaused)
        }
    }

    // MARK: - Bottom Bar (inlined from BottomBarView)

    @ViewBuilder
    private var bottomBar: some View {
        let shouldShowBar = !showInfo && (isBottomBarVisible || showSettings || showStats)

        ZStack {
            // Invisible tap target — always present to bring bar back
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture { showBottomBarTemporarily() }

            if shouldShowBar {
                HStack {
                    Button(action: { toggleStats() }) {
                        Image(systemName: "chart.bar")
                            .font(.system(size: PuzzleViewConstants.Sizes.statsIconSize))
                            .foregroundColor(CryptogramTheme.Colors.text)
                            .opacity(PuzzleViewConstants.Colors.iconOpacity)
                            .frame(width: PuzzleViewConstants.Sizes.iconButtonFrame, height: PuzzleViewConstants.Sizes.iconButtonFrame)
                            .accessibilityLabel("Stats/Chart")
                    }

                    Spacer()

                    Button(action: {
                        navigationCoordinator.navigateToHome()
                    }) {
                        Image(systemName: "house")
                            .font(.title3)
                            .foregroundColor(CryptogramTheme.Colors.text)
                            .opacity(PuzzleViewConstants.Colors.iconOpacity)
                            .frame(width: PuzzleViewConstants.Sizes.iconButtonFrame, height: PuzzleViewConstants.Sizes.iconButtonFrame)
                            .accessibilityLabel("Return to Home")
                    }

                    Spacer()

                    Button(action: { toggleSettings() }) {
                        Image(systemName: "gearshape")
                            .font(.system(size: PuzzleViewConstants.Sizes.settingsIconSize))
                            .foregroundColor(CryptogramTheme.Colors.text)
                            .opacity(PuzzleViewConstants.Colors.iconOpacity)
                            .frame(width: PuzzleViewConstants.Sizes.iconButtonFrame, height: PuzzleViewConstants.Sizes.iconButtonFrame)
                            .accessibilityLabel("Settings")
                    }
                }
                .padding(.horizontal, PuzzleViewConstants.Spacing.bottomBarHorizontalPadding)
            }
        }
        .frame(height: PuzzleViewConstants.Spacing.bottomBarHeight)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Pause Overlay

    @Environment(\.typography) private var typography

    private var pauseOverlay: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .allowsHitTesting(false)
            VStack {
                Spacer()
                Text("paused")
                    .font(typography.body)
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
        .transition(.opacity)
        .animation(.easeInOut(duration: PuzzleViewConstants.Animation.overlayDuration), value: viewModel.isPaused)
    }

    // MARK: - Bottom Bar Helpers

    private func showBottomBarTemporarily() {
        isBottomBarVisible = true
        bottomBarHideTask?.cancel()
        bottomBarHideTask = Task {
            try? await Task.sleep(for: .seconds(PuzzleViewConstants.Animation.bottomBarAutoHideDelay))
            guard !Task.isCancelled else { return }
            withAnimation { isBottomBarVisible = false }
        }
    }

    private func toggleSettings() {
        withAnimation {
            showSettings.toggle()
            showStats = false
        }
        showBottomBarTemporarily()
    }

    private func toggleStats() {
        withAnimation {
            showStats.toggle()
            showSettings = false
        }
        showBottomBarTemporarily()
    }
}

#Preview {
    PuzzleView(showPuzzle: .constant(true))
        .environment(PuzzleViewModel())
        .environment(ThemeManager())
        .environment(AppSettings())
        .environment(NavigationCoordinator())
}
