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
    @EnvironmentObject private var navigationCoordinator: NavigationCoordinator
    @Environment(\.typography) private var typography
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var uiState: PuzzleViewState
    @Namespace private var statsOverlayNamespace
    
    // Game over typing animation state
    @State private var gameOverTypedText = ""
    @State private var showGameOverButtons = false
    @State private var currentGameOverMessage = ""
    @State private var gameOverTypingTimer: Timer?
    @State private var showContinueFriction = false
    @State private var frictionTypedText = ""
    @State private var frictionTypingTimer: Timer?
    
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
                
                // X button positioned at screen level
                VStack {
                    HStack {
                        Spacer()
                        Button(action: { uiState.showInfoOverlay = false }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(CryptogramTheme.Colors.text.opacity(0.6))
                                .frame(width: 22, height: 22)
                        }
                        .padding(.top, 50)
                        .padding(.trailing, 20)
                    }
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
        if viewModel.isPaused && uiState.completionState == .none && !uiState.showSettings && !uiState.showStatsOverlay {
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
            .zIndex(OverlayZIndex.pauseGameOver)
            .transition(.opacity)
            .animation(.easeInOut(duration: PuzzleViewConstants.Animation.overlayDuration), value: viewModel.isPaused)
        }
    }
    
    // MARK: - Game Over Overlay
    private let gameOverMessages = [
        "uh oh that's 3 mistakes.",
        "oh no game over.",
        "sucks to suck huh.",
        "oops you made a whoopsie.",
        "third strike, you're out!",
        "better luck next time.",
        "so close yet so far.",
        "practice makes perfect."
    ]
    
    @ViewBuilder
    private var gameOverOverlay: some View {
        if viewModel.isFailed && uiState.completionState == .none && !uiState.showSettings && !uiState.showStatsOverlay {
            ZStack {
                CryptogramTheme.Colors.background
                    .ignoresSafeArea()
                    .opacity(0.98)
                    .onTapGesture { } // Consume taps on background
                
                // Info button in top-right corner
                VStack {
                    HStack {
                        Spacer()
                        Button(action: {
                            withAnimation {
                                uiState.showInfoOverlay.toggle()
                            }
                        }) {
                            Image(systemName: "questionmark")
                                .font(.system(size: PuzzleViewConstants.Sizes.questionMarkSize, design: typography.fontOption.design))
                                .foregroundColor(CryptogramTheme.Colors.text)
                                .opacity(uiState.showInfoOverlay ? PuzzleViewConstants.Colors.activeIconOpacity : PuzzleViewConstants.Colors.iconOpacity)
                                .frame(width: PuzzleViewConstants.Sizes.iconButtonFrame, height: PuzzleViewConstants.Sizes.iconButtonFrame)
                                .accessibilityLabel("About / Info")
                        }
                        .padding(.trailing, PuzzleViewConstants.Spacing.topBarPadding)
                    }
                    Spacer()
                }
                .padding(.top, 0)
                
                VStack(spacing: 48) {
                    Spacer()
                    
                    Text(gameOverTypedText)
                        .font(typography.body)
                        .foregroundColor(CryptogramTheme.Colors.text)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 12)
                    
                    // Button container - always present to maintain layout
                    VStack(spacing: 32) {
                        if showGameOverButtons && !showContinueFriction {
                            // Continue button
                            Button(action: {
                                startContinueFriction()
                            }) {
                                Text("continue")
                                    .font(typography.caption)
                                    .foregroundColor(CryptogramTheme.Colors.text)
                            }
                            .transition(.opacity)
                            
                            // New Puzzle button
                            Button(action: {
                                viewModel.refreshPuzzleWithCurrentSettings()
                            }) {
                                Text("new puzzle")
                                    .font(typography.caption)
                                    .foregroundColor(CryptogramTheme.Colors.text)
                            }
                            .transition(.opacity)
                            
                            // Try Again button
                            Button(action: {
                                viewModel.reset()
                                if let currentPuzzle = viewModel.currentPuzzle {
                                    viewModel.startNewPuzzle(puzzle: currentPuzzle)
                                }
                            }) {
                                Text("try again")
                                    .font(typography.caption)
                                    .foregroundColor(CryptogramTheme.Colors.text)
                            }
                            .transition(.opacity)
                        } else if showContinueFriction {
                            // Friction message in place of continue button
                            Text(frictionTypedText)
                                .font(typography.caption)
                                .foregroundColor(CryptogramTheme.Colors.text)
                                .padding(.horizontal, 32)
                                .multilineTextAlignment(.center)
                                .transition(.opacity)
                            
                            // Invisible placeholders for other buttons
                            Text("new puzzle")
                                .font(typography.caption)
                                .foregroundColor(.clear)
                            
                            Text("try again")
                                .font(typography.caption)
                                .foregroundColor(.clear)
                        } else {
                            // Invisible placeholders with same height as buttons
                            Text("continue")
                                .font(typography.caption)
                                .foregroundColor(.clear)
                            
                            Text("new puzzle")
                                .font(typography.caption)
                                .foregroundColor(.clear)
                            
                            Text("try again")
                                .font(typography.caption)
                                .foregroundColor(.clear)
                        }
                    }
                    .padding(.bottom, 180)
                    .animation(.easeIn(duration: 0.3), value: showGameOverButtons)
                    .animation(.easeIn(duration: 0.3), value: showContinueFriction)
                }
                
                // Bottom bar positioned absolutely - doesn't affect other content
                if showGameOverButtons && !showContinueFriction {
                    if uiState.isGameOverBottomBarVisible {
                        VStack {
                            Spacer()
                            HStack {
                                // Stats button
                                Button(action: {
                                    uiState.toggleStats()
                                }) {
                                    Image(systemName: "chart.bar")
                                        .font(.system(size: PuzzleViewConstants.Sizes.statsIconSize))
                                        .foregroundColor(CryptogramTheme.Colors.text)
                                        .opacity(PuzzleViewConstants.Colors.iconOpacity)
                                        .frame(width: PuzzleViewConstants.Sizes.iconButtonFrame, height: PuzzleViewConstants.Sizes.iconButtonFrame)
                                        .accessibilityLabel("Stats/Chart")
                                }
                                
                                Spacer()
                                
                                // Home button (center)
                                Button(action: {
                                    dismiss()
                                }) {
                                    Image(systemName: "house")
                                        .font(.title3)
                                        .foregroundColor(CryptogramTheme.Colors.text)
                                        .opacity(PuzzleViewConstants.Colors.iconOpacity)
                                        .frame(width: PuzzleViewConstants.Sizes.iconButtonFrame, height: PuzzleViewConstants.Sizes.iconButtonFrame)
                                        .accessibilityLabel("Return to Home")
                                }
                                
                                Spacer()
                                
                                // Settings button
                                Button(action: {
                                    uiState.toggleSettings()
                                }) {
                                    Image(systemName: "gearshape")
                                        .font(.system(size: PuzzleViewConstants.Sizes.settingsIconSize))
                                        .foregroundColor(CryptogramTheme.Colors.text)
                                        .opacity(PuzzleViewConstants.Colors.iconOpacity)
                                        .frame(width: PuzzleViewConstants.Sizes.iconButtonFrame, height: PuzzleViewConstants.Sizes.iconButtonFrame)
                                        .accessibilityLabel("Settings")
                                }
                            }
                            .frame(height: PuzzleViewConstants.Spacing.bottomBarHeight, alignment: .bottom)
                            .padding(.horizontal, PuzzleViewConstants.Spacing.bottomBarHorizontalPadding)
                            .frame(maxWidth: .infinity)
                            .ignoresSafeArea(edges: .bottom)
                            .onTapGesture {
                                uiState.showGameOverBottomBarTemporarily()
                            }
                        }
                        .transition(.opacity)
                        .animation(.easeInOut(duration: PuzzleViewConstants.Animation.overlayDuration), value: uiState.isGameOverBottomBarVisible)
                    } else {
                        // Invisible tap area to bring back bottom bar
                        VStack {
                            Spacer()
                            Rectangle()
                                .fill(Color.clear)
                                .frame(height: PuzzleViewConstants.Spacing.bottomBarHeight)
                                .frame(maxWidth: .infinity)
                                .ignoresSafeArea(edges: .bottom)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    uiState.showGameOverBottomBarTemporarily()
                                }
                        }
                    }
                }
            }
            .zIndex(OverlayZIndex.pauseGameOver)
            .transition(.opacity)
            .animation(.easeInOut(duration: PuzzleViewConstants.Animation.overlayDuration), value: viewModel.isFailed)
            .onAppear {
                startGameOverTyping()
            }
            .onDisappear {
                resetGameOverAnimation()
            }
        }
    }
    
    // MARK: - Stats Overlay
    @ViewBuilder
    private var statsOverlay: some View {
        if uiState.showStatsOverlay {
            ZStack {
                CryptogramTheme.Colors.surface
                    .opacity(0.98)
                    .ignoresSafeArea()
                    .onTapGesture { uiState.showStatsOverlay = false }
                    .overlay(
                        VStack(spacing: 0) {
                            Spacer(minLength: 0)
                            UserStatsView(viewModel: viewModel)
                                .padding(.top, 24)
                        }
                    )
                
                // X button positioned at screen level
                VStack {
                    HStack {
                        Spacer()
                        Button(action: { uiState.showStatsOverlay = false }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(CryptogramTheme.Colors.text.opacity(0.6))
                                .frame(width: 22, height: 22)
                        }
                        .padding(.top, 50)
                        .padding(.trailing, 20)
                    }
                    Spacer()
                }
            }
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
            ZStack {
                CryptogramTheme.Colors.surface
                    .opacity(0.98)
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture {
                        uiState.showSettings = false
                    }
                    .overlay(
                        SettingsContentView()
                            .padding(.horizontal, PuzzleViewConstants.Overlay.overlayHorizontalPadding)
                            .padding(.vertical, 20)
                            .background(Color.clear)
                            .contentShape(Rectangle())
                            .onTapGesture {}
                            .environmentObject(viewModel)
                            .environmentObject(themeManager)
                            .environmentObject(settingsViewModel)
                    )
                
                // X button positioned at screen level
                VStack {
                    HStack {
                        Spacer()
                        Button(action: { uiState.showSettings = false }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(CryptogramTheme.Colors.text.opacity(0.6))
                                .frame(width: 22, height: 22)
                        }
                        .padding(.top, 50)
                        .padding(.trailing, 20)
                    }
                    Spacer()
                }
            }
            .zIndex(OverlayZIndex.statsSettings)
        }
    }
    
    // MARK: - Completion Overlay
    @ViewBuilder
    private var completionOverlay: some View {
        switch uiState.completionState {
        case .regular:
            PuzzleCompletionView(showCompletionView: $uiState.showCompletionView)
                .environmentObject(themeManager)
                .environmentObject(viewModel)
                .environmentObject(navigationCoordinator)
                .environmentObject(settingsViewModel)
                .transition(.opacity)
                .animation(.easeInOut(duration: 0.2), value: uiState.completionState)
                .zIndex(OverlayZIndex.completion)
        case .daily:
            PuzzleCompletionView(showCompletionView: $uiState.showDailyCompletionView, isDailyPuzzle: true)
                .environmentObject(themeManager)
                .environmentObject(viewModel)
                .environmentObject(navigationCoordinator)
                .environmentObject(settingsViewModel)
                .transition(.opacity)
                .animation(.easeInOut(duration: 0.2), value: uiState.completionState)
                .zIndex(OverlayZIndex.dailyCompletion)
        case .none:
            EmptyView()
        }
    }
    
    // MARK: - Daily Completion Overlay
    @ViewBuilder
    private var dailyCompletionOverlay: some View {
        // This is now handled in completionOverlay
        EmptyView()
    }
    
    // MARK: - Game Over Animation Methods
    private func startGameOverTyping() {
        // Reset state
        gameOverTypedText = ""
        showGameOverButtons = false
        
        // Select a random message
        currentGameOverMessage = gameOverMessages.randomElement() ?? "game over"
        
        // Start typing after 0.7s delay (increased from 0.5s to avoid overlap with mistake animation)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            typeGameOverMessage()
        }
    }
    
    private func typeGameOverMessage() {
        gameOverTypingTimer?.invalidate()
        
        let characters = Array(currentGameOverMessage)
        var currentIndex = 0
        
        gameOverTypingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            if currentIndex < characters.count {
                gameOverTypedText.append(characters[currentIndex])
                currentIndex += 1
            } else {
                timer.invalidate()
                // Show buttons after typing completes
                withAnimation {
                    showGameOverButtons = true
                }
                // Show bottom bar temporarily (auto-hides after 3s)
                Task { @MainActor in
                    uiState.showGameOverBottomBarTemporarily()
                }
            }
        }
    }
    
    private func resetGameOverAnimation() {
        gameOverTypingTimer?.invalidate()
        frictionTypingTimer?.invalidate()
        gameOverTypedText = ""
        showGameOverButtons = false
        currentGameOverMessage = ""
        showContinueFriction = false
        frictionTypedText = ""
    }
    
    private func startContinueFriction() {
        // Hide buttons and start friction message
        withAnimation {
            showGameOverButtons = false
            showContinueFriction = true
        }
        
        // Reset friction text
        frictionTypedText = ""
        
        // Start typing after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            typeFrictionMessage()
        }
    }
    
    private func typeFrictionMessage() {
        frictionTypingTimer?.invalidate()
        
        let message = "since there are no ads this is a bit of friction cause, well, you did make 3 mistakes..."
        let characters = Array(message)
        var currentIndex = 0
        
        frictionTypingTimer = Timer.scheduledTimer(withTimeInterval: 0.08, repeats: true) { timer in
            if currentIndex < characters.count {
                frictionTypedText.append(characters[currentIndex])
                currentIndex += 1
            } else {
                timer.invalidate()
                // Auto-continue after typing completes
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    viewModel.continueAfterFailure()
                }
            }
        }
    }
}

// Extension to make it easy to apply the overlay manager
extension View {
    func overlayManager(uiState: PuzzleViewState) -> some View {
        self.modifier(OverlayManager(uiState: uiState))
    }
}
