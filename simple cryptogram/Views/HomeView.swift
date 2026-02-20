import SwiftUI

struct HomeView: View {
    @Environment(PuzzleViewModel.self) private var viewModel
    @Environment(AppSettings.self) private var appSettings
    @Environment(ThemeManager.self) private var themeManager
    @Environment(\.typography) private var typography
    @Environment(NavigationCoordinator.self) private var navigationCoordinator
    @State private var showSettings = false
    @State private var showStats = false
    @State private var selectedMode: PuzzleMode = .random
    @State private var showLengthSelection = false
    @State private var isBottomBarVisible = true
    @State private var bottomBarHideTask: Task<Void, Never>?
    @State private var showCalendar = false
    @State private var showQuotebook = false
    @State private var showInfoOverlay = false

    enum PuzzleMode {
        case random
        case daily
    }

    private var isDailyPuzzleCompleted: Bool {
        viewModel.isTodaysDailyPuzzleCompleted()
    }

    var body: some View {
        ZStack {
            CryptogramTheme.Colors.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                mainContent

                // Bottom bar
                ZStack {
                    if isBottomBarVisible || showSettings || showStats {
                        HStack {
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

            // Floating info button
            if !showInfoOverlay && !showSettings && !showStats && !showCalendar && !showQuotebook {
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
                .zIndex(130)
            }

            // Overlays
            if showSettings {
                FullScreenOverlay(isPresented: $showSettings) {
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
                FullScreenOverlay(isPresented: $showStats) {
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

            if showQuotebook {
                FullScreenOverlay(isPresented: $showQuotebook) {
                    QuotebookView()
                        .environment(appSettings)
                }
                .zIndex(150)
            }

            if showInfoOverlay {
                FullScreenOverlay(isPresented: $showInfoOverlay) {
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
        }
        .onAppear {
            showBottomBarTemporarily()
            showLengthSelection = false

            if appSettings.shouldShowCalendarOnReturn {
                showCalendar = true
                appSettings.shouldShowCalendarOnReturn = false
            }
        }
    }

    // MARK: - Main Content (inlined from HomeMainContent)

    private var mainContent: some View {
        VStack(spacing: 20) {
            Spacer()
            Spacer()
            Spacer()

            if !showLengthSelection {
                VStack(spacing: 50) {
                    playButton
                    dailyPuzzleButton
                }
                .transition(.opacity.combined(with: .scale))
            } else {
                VStack(spacing: 20) {
                    randomButton

                    Text("or select length")
                        .font(typography.footnote)
                        .italic()
                        .foregroundColor(CryptogramTheme.Colors.text.opacity(0.7))
                        .padding(.vertical, 4)

                    HStack(spacing: 30) {
                        lengthButton("short", difficulty: "easy")
                        lengthButton("medium", difficulty: "medium")
                        lengthButton("long", difficulty: "hard")
                    }
                }
                .transition(.opacity.combined(with: .scale))
            }

            Spacer()
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if showLengthSelection {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showLengthSelection = false
                }
            }
        }
    }

    private var playButton: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
                showLengthSelection = true
            }
        }) {
            Text("play")
                .font(typography.body)
                .foregroundColor(CryptogramTheme.Colors.text)
                .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var dailyPuzzleButton: some View {
        VStack(spacing: 36) {
            Button(action: {
                selectMode(.daily)
            }) {
                HStack(spacing: 8) {
                    Text("daily puzzle")
                        .font(typography.body)
                        .foregroundColor(CryptogramTheme.Colors.text)
                        .padding(.vertical, 8)

                    if isDailyPuzzleCompleted {
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Color(hex: "#01780F").opacity(0.5))
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())

            HStack(spacing: 32) {
                Button(action: {
                    showCalendar = true
                }) {
                    Image(systemName: "calendar")
                        .font(.system(size: 24))
                        .foregroundColor(CryptogramTheme.Colors.text.opacity(0.8))
                }
                .buttonStyle(PlainButtonStyle())

                Button(action: {
                    showQuotebook = true
                }) {
                    Image(systemName: "book.closed")
                        .font(.system(size: 24))
                        .foregroundColor(CryptogramTheme.Colors.text.opacity(0.8))
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }

    private var randomButton: some View {
        Button(action: {
            appSettings.selectedDifficulties = ["easy", "medium", "hard"]
            selectMode(.random)
        }) {
            HStack(spacing: 4) {
                Text("just play")
                    .font(typography.body)
                    .foregroundColor(CryptogramTheme.Colors.text)
                Image(systemName: "dice")
                    .font(typography.caption)
                    .foregroundColor(CryptogramTheme.Colors.text)
                    .rotationEffect(.degrees(30))
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func lengthButton(_ title: String, difficulty: String) -> some View {
        Button(action: {
            appSettings.selectedDifficulties = [difficulty]
            selectMode(.random)
        }) {
            Text(title)
                .font(typography.body)
                .foregroundColor(CryptogramTheme.Colors.text)
                .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - Actions

    private func selectMode(_ mode: PuzzleMode) {
        selectedMode = mode

        switch mode {
        case .random:
            if appSettings.selectedDifficulties.isEmpty {
                appSettings.selectedDifficulties = ["easy", "medium", "hard"]
            }
        case .daily:
            viewModel.loadDailyPuzzle()
            if let puzzle = viewModel.currentPuzzle {
                navigationCoordinator.navigateToPuzzle(puzzle)
            }
            return
        }

        Task {
            await viewModel.loadNewPuzzleAsync()
            if let puzzle = viewModel.currentPuzzle {
                navigationCoordinator.navigateToPuzzle(puzzle)
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
        .environment(NavigationCoordinator())
}
