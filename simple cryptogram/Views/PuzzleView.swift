import SwiftUI
import Combine

struct PuzzleView: View {
    @EnvironmentObject private var viewModel: PuzzleViewModel
    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject private var settingsViewModel: SettingsViewModel
    @State private var showSettings = false
    @State private var showCompletionView = false
    @State private var showStatsOverlay = false
    @State private var showInfoOverlay = false
    @State private var displayedGameOver = ""
    private let fullGameOverText = "game over"
    @State private var isSwitchingPuzzle = false
    @Namespace private var statsOverlayNamespace
    @AppStorage("isDarkMode") private var isDarkMode = false
    @State private var isBottomBarVisible = true
    @State private var bottomBarHideWorkItem: DispatchWorkItem?
    
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
                HStack(alignment: .top) {
                    // Left: mistakes & hints
                    if viewModel.currentPuzzle != nil && !showSettings && !showStatsOverlay && !showCompletionView {
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
                        if viewModel.currentPuzzle != nil && !showSettings && !showStatsOverlay && !showCompletionView {
                            let timerInactive = (viewModel.startTime ?? Date.distantFuture) > Date()
                            TimerView(startTime: viewModel.startTime ?? Date.distantFuture, isPaused: viewModel.isPaused, settingsViewModel: settingsViewModel)
                                .foregroundColor(timerInactive ? CryptogramTheme.Colors.secondary : CryptogramTheme.Colors.text)
                                .opacity(timerInactive ? 0.5 : 1.0)
                        }
                    }
                    .frame(minWidth: 0, maxWidth: .infinity, alignment: .center)
                    
                    // Right: settings & stats buttons
                    if viewModel.currentPuzzle != nil && !showSettings && !showStatsOverlay && !showCompletionView {
                        VStack(alignment: .trailing, spacing: 2) {
                            Button(action: {
                                viewModel.loadDailyPuzzle()
                            }) {
                                Image(systemName: "calendar")
                                    .font(.title3)
                                    .foregroundColor(viewModel.isDailyPuzzle ? Color.green.opacity(0.4) : CryptogramTheme.Colors.text)
                                    .opacity(0.7)
                                    .frame(width: 44, height: 44)
                                    .accessibilityLabel("Calendar")
                            }
                        }
                        .frame(minWidth: 0, maxWidth: .infinity, alignment: .trailing)
                    }
                }
                .padding(.top, 8)
                .padding(.horizontal, 16)
                .frame(maxWidth: .infinity)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .zIndex(0)

            // --- Main Content Block (puzzle, nav bar, keyboard) pushed to bottom ---
            VStack(spacing: 0) {
                Spacer(minLength: 0)
                if viewModel.currentPuzzle != nil {
                    VStack(spacing: 0) {
                        Group {
                            ScrollView {
                                WordAwarePuzzleGrid()
                                    .environmentObject(viewModel)
                                    .padding(.horizontal, 16)
                                    .allowsHitTesting(!viewModel.isPaused)
                            }
                            .layoutPriority(1)
                            .frame(maxWidth: .infinity)
                            .frame(maxHeight: UIScreen.main.bounds.height * 0.45)
                            .padding(.horizontal, 12)
                            .padding(.top, 60)
                            .padding(.bottom, 12)

                            Rectangle()
                                .fill(Color.clear)
                                .frame(height: 20)
                                .allowsHitTesting(false)
                        }
                        .opacity(isSwitchingPuzzle ? 0 : 1)
                        .animation(.easeInOut(duration: 0.5), value: isSwitchingPuzzle)

                        // Navigation Bar with all controls in a single layer
                        NavigationBarView(
                            onMoveLeft: { viewModel.moveToAdjacentCell(direction: -1) },
                            onMoveRight: { viewModel.moveToAdjacentCell(direction: 1) },
                            onTogglePause: viewModel.togglePause,
                            onNextPuzzle: {
                                withAnimation(.easeInOut(duration: 0.5)) { isSwitchingPuzzle = true }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    viewModel.refreshPuzzleWithCurrentSettings()
                                    withAnimation(.easeInOut(duration: 0.5)) { isSwitchingPuzzle = false }
                                }
                            },
                            onTryAgain: { 
                                viewModel.reset()
                                // Re-apply difficulty settings to the same puzzle
                                if let currentPuzzle = viewModel.currentPuzzle {
                                    viewModel.startNewPuzzle(puzzle: currentPuzzle)
                                }
                            },
                            isPaused: viewModel.isPaused,
                            isFailed: viewModel.isFailed,
                            showCenterButtons: true, // Show all buttons in the nav bar
                            layout: layoutBinding
                        )
                        // Keyboard View
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
                        .padding(.bottom, 0)
                        .padding(.horizontal, 4)
                        .frame(maxWidth: .infinity)
                        .allowsHitTesting(!viewModel.isPaused)
                    }
                    .frame(maxWidth: .infinity)
                }
                // --- Bottom Banner Placeholder (for keyboard spacing) ---
                Color.clear
                    .frame(height: 48)
                    .frame(maxWidth: .infinity)
                    .ignoresSafeArea(edges: .bottom)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            .zIndex(0)

            // --- Info Overlay (modal, animates, scrollable, uses SettingsSection style) ---
            if showInfoOverlay {
                ZStack(alignment: .top) {
                    // Background layer that dismisses overlay on tap
                    CryptogramTheme.Colors.background
                        .ignoresSafeArea()
                        .opacity(0.98)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            withAnimation {
                                showInfoOverlay = false
                            }
                        }
                    // Foreground overlay content - interactive
                    VStack {
                        Spacer(minLength: 120)
                        ScrollView {
                            InfoOverlayView()
                        }
                        .padding(.horizontal, 24)
                        Spacer()
                    }
                    // DO NOT block hit testing here; allow interaction
                }
                .transition(.opacity)
                .animation(.easeInOut(duration: 0.3), value: showInfoOverlay)
                .zIndex(125) // Info overlay now above pause overlay
            }

            // --- Floating Question Mark Button (above info, below stats/settings/completion) ---
            if viewModel.currentPuzzle != nil && !showSettings && !showStatsOverlay && !showCompletionView {
                VStack {
                    HStack {
                        Spacer()
                        Button(action: {
                            withAnimation {
                                showInfoOverlay.toggle()
                            }
                        }) {
                            Image(systemName: "questionmark")
                                .font(.system(size: 13))
                                .foregroundColor(CryptogramTheme.Colors.text)
                                .opacity(showInfoOverlay ? 1.0 : 0.7)
                                .frame(width: 24, height: 24)
                                .accessibilityLabel("About / Info")
                        }
                        .offset(x: -10, y: 60)
                        .padding(.trailing, 16)
                    }
                    Spacer()
                }
                .zIndex(130)
            }

            // --- Pause Overlay (modal, animates, semi-transparent background) ---
            if viewModel.isPaused && !showCompletionView && !showSettings && !showStatsOverlay {
                ZStack {
                    Color.black.opacity(0.5)
                        .ignoresSafeArea()
                        .allowsHitTesting(false)
                    VStack {
                        Spacer(minLength: 490)
                        Text("paused")
                            .font(CryptogramTheme.Typography.body)
                            .fontWeight(.bold)
                            .foregroundColor(CryptogramTheme.Colors.text)
                            .padding(.horizontal, 32)
                            .padding(.vertical, 12)
                            .onTapGesture {
                                viewModel.togglePause()
                            }
                            .allowsHitTesting(true)
                        Spacer()
                    }
                }
                .zIndex(120)
                .transition(.opacity)
                .animation(.easeInOut(duration: 0.3), value: viewModel.isPaused)
            }

            // --- Game Over Overlay (modal, animates, semi-transparent background, mimics pause overlay) ---
            if viewModel.isFailed && !showCompletionView && !showSettings && !showStatsOverlay {
                ZStack {
                    Color.black.opacity(0.5)
                        .ignoresSafeArea()
                        .allowsHitTesting(false)
                    VStack {
                        Spacer(minLength: 490)
                        Text("game over")
                            .font(CryptogramTheme.Typography.body)
                            .fontWeight(.bold)
                            .foregroundColor(CryptogramTheme.Colors.text)
                            .padding(.horizontal, 32)
                            .padding(.vertical, 12)
                            .onTapGesture {
                                // Optionally, you might want to trigger try again here, or leave as non-tappable
                            }
                            .allowsHitTesting(false) // Not tappable by default, nav bar handles retry
                        Spacer()
                    }
                }
                .zIndex(120)
                .transition(.opacity)
                .animation(.easeInOut(duration: 0.3), value: viewModel.isFailed)
            }

            // --- Stats Overlay (custom ZStack, slides from top) ---
            if showStatsOverlay {
                ZStack(alignment: .top) {
                    CryptogramTheme.Colors.background
                        .ignoresSafeArea()
                        .opacity(0.98)
                        .onTapGesture { showStatsOverlay = false }
                    VStack(spacing: 0) {
                        Spacer(minLength: 0)
                        UserStatsView(viewModel: viewModel)
                            .padding(.top, 24)
                    }
                }
                .matchedGeometryEffect(id: "statsOverlay", in: statsOverlayNamespace)
                .transition(.opacity)
                .animation(.easeInOut(duration: 0.3), value: showStatsOverlay)
                .zIndex(150)
            }

            // --- Settings Overlay ---
            if showSettings {
                ZStack {
                    CryptogramTheme.Colors.surface
                        .opacity(0.95)
                        .edgesIgnoringSafeArea(.all)
                        .onTapGesture {
                            showSettings = false
                        }
                        .zIndex(10)
                    SettingsContentView()
                        .padding(.horizontal, 24)
                        .padding(.vertical, 20)
                        .contentShape(Rectangle())
                        .onTapGesture { }
                        .environmentObject(viewModel)
                        .environmentObject(themeManager)
                        .environmentObject(settingsViewModel)
                        .zIndex(11)
                }
                .zIndex(150)
            }

            // --- Completion overlay - conditionally shown ---
            if showCompletionView {
                PuzzleCompletionView(showCompletionView: $showCompletionView)
                    .environmentObject(themeManager)
                    .environmentObject(viewModel)
                    .zIndex(200)
            }

            // --- Persistent Bottom Banner Above All Overlays (with icons) ---
            if !showInfoOverlay && (isBottomBarVisible || showSettings || showStatsOverlay) {
                VStack {
                    Spacer()
                    HStack {
                        Button(action: {
                            withAnimation {
                                if showStatsOverlay {
                                    showStatsOverlay = false
                                    showSettings = false
                                } else {
                                    showStatsOverlay.toggle()
                                    showSettings = false
                                }
                                showBottomBarTemporarily()
                            }
                        }) {
                            Image(systemName: "chart.bar")
                                .font(.system(size: 20))
                                .foregroundColor(CryptogramTheme.Colors.text)
                                .opacity(0.7)
                                .frame(width: 44, height: 44)
                                .accessibilityLabel("Stats/Chart")
                        }
                        Spacer()
                        Button(action: {
                            withAnimation {
                                if showSettings {
                                    showSettings = false
                                    showStatsOverlay = false
                                } else {
                                    showSettings.toggle()
                                    showStatsOverlay = false
                                }
                                showBottomBarTemporarily()
                            }
                        }) {
                            Image(systemName: "gearshape")
                                .font(.system(size:24))
                                .foregroundColor(CryptogramTheme.Colors.text)
                                .opacity(0.7)
                                .frame(width: 44, height: 44)
                                .accessibilityLabel("Settings")
                        }
                    }
                    .frame(height: 48, alignment: .bottom)
                    .padding(.horizontal, 64)
                    .frame(maxWidth: .infinity)
                    .ignoresSafeArea(edges: .bottom)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        showBottomBarTemporarily()
                    }
                }
                .zIndex(190)
            } else if !showInfoOverlay && !(isBottomBarVisible || showSettings || showStatsOverlay) {
                // Invisible tappable area to bring back bottom bar
                VStack {
                    Spacer()
                    Rectangle()
                        .fill(Color.clear)
                        .frame(height: 48)
                        .frame(maxWidth: .infinity)
                        .ignoresSafeArea(edges: .bottom)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            showBottomBarTemporarily()
                        }
                }
                .zIndex(189)
            }
        }
        .onChange(of: viewModel.isComplete) { oldValue, isComplete in
            if isComplete {
                // Add haptic feedback for completion
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
                
                // First trigger wiggle animation
                viewModel.triggerCompletionWiggle()
                
                // Then transition to completion view with a slight delay
                withAnimation(.easeOut(duration: 0.5).delay(0.7)) {
                    showCompletionView = true
                }
            }
        }
        .navigationBarHidden(true)
        .animation(.easeIn(duration: 1.0), value: viewModel.isFailed)
        .animation(.easeIn(duration: 0.6), value: viewModel.isPaused)
        .onAppear {
            showBottomBarTemporarily()
        }
        .onDisappear {
            // viewModel.pauseTimer()
        }
    }
    
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    // MARK: - Typewriter effect
    private func startTypewriterWithDelay(_ delay: TimeInterval = 1.2) {
        displayedGameOver = ""
        for (i, ch) in fullGameOverText.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay + Double(i) * 0.2) {
                displayedGameOver.append(ch)
            }
        }
    }
    
    private func showBottomBarTemporarily() {
        isBottomBarVisible = true
        bottomBarHideWorkItem?.cancel()
        let workItem = DispatchWorkItem {
            withAnimation {
                isBottomBarVisible = false
            }
        }
        bottomBarHideWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 3, execute: workItem)
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
