import SwiftUI
import Combine

/// Modernized PuzzleView using new NavigationState and clean architecture
/// Separates presentation logic from business logic
struct ModernPuzzleView: View {
    // MARK: - Dependencies
    let puzzle: Puzzle
    @EnvironmentObject private var businessLogic: BusinessLogicCoordinator
    @EnvironmentObject private var navigationState: NavigationState
    @StateObject private var uiViewModel = PuzzleUIViewModel()
    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject private var settingsViewModel: SettingsViewModel
    @Environment(AppSettings.self) private var appSettings
    @Environment(\.typography) private var typography
    
    // Create a custom binding for the layout
    private var layoutBinding: Binding<NavigationBarLayout> {
        Binding(
            get: { appSettings.navigationBarLayout },
            set: { appSettings.navigationBarLayout = $0 }
        )
    }
    
    var body: some View {
        ZStack {
            // Background
            CryptogramTheme.Colors.background
                .ignoresSafeArea()
            
            // Show puzzle content when no completion overlay is active
            if !navigationState.isPresenting(OverlayType.completion(.regular)) && 
               !navigationState.isPresenting(OverlayType.completion(.daily)) &&
               !businessLogic.isCompletedDailyPuzzle {
                
                // Persistent Top Bar
                VStack {
                    ModernTopBarView(
                        businessLogic: businessLogic,
                        navigationState: navigationState
                    )
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .zIndex(0)

                // Main Content Block
                VStack(spacing: 0) {
                    Spacer(minLength: 0)
                    ModernMainContentView(
                        businessLogic: businessLogic,
                        navigationState: navigationState,
                        layoutBinding: layoutBinding
                    )
                    
                    // Bottom spacing for keyboard
                    Color.clear
                        .frame(height: PuzzleViewConstants.Spacing.bottomBarHeight)
                        .frame(maxWidth: .infinity)
                        .ignoresSafeArea(edges: .bottom)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                .zIndex(0)

                // Persistent Bottom Banner
                ModernBottomBarView(
                    businessLogic: businessLogic,
                    navigationState: navigationState
                )
            }
        }
        .modernOverlayManager(
            businessLogic: businessLogic,
            navigationState: navigationState,
            uiViewModel: uiViewModel
        )
        .onChange(of: businessLogic.isComplete) { oldValue, isComplete in
            if isComplete {
                handlePuzzleCompletion()
            }
        }
        .onChange(of: businessLogic.isFailed) { oldValue, isFailed in
            if isFailed {
                handlePuzzleFailure()
            }
        }
        .onAppear {
            handleViewAppear()
        }
        .onDisappear {
            handleViewDisappear()
        }
    }
    
    // MARK: - Event Handlers
    
    private func handlePuzzleCompletion() {
        // Add haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        // Trigger wiggle animation
        businessLogic.triggerCompletionWiggle()
        
        // Show appropriate completion overlay
        let completionState: CompletionState = businessLogic.isDailyPuzzle ? .daily : .regular
        
        withAnimation(.easeOut(duration: PuzzleViewConstants.Animation.puzzleSwitchDuration)
                        .delay(PuzzleViewConstants.Animation.completionDelay)) {
            navigationState.showCompletion(completionState)
        }
    }
    
    private func handlePuzzleFailure() {
        // Add haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
        
        // Show game over overlay
        navigationState.showGameOver()
        
        // Start game over animation
        uiViewModel.startGameOverTypewriter {
            navigationState.showGameOverBottomBarTemporarily()
        }
    }
    
    private func handleViewAppear() {
        // Initialize puzzle if needed
        if businessLogic.currentPuzzle?.id != puzzle.id {
            businessLogic.startNewPuzzle(puzzle: puzzle)
        }
        
        if businessLogic.isCompletedDailyPuzzle {
            // Show completion view immediately for completed daily puzzles
            navigationState.showCompletion(.daily)
        } else {
            // Normal puzzle flow
            navigationState.showBottomBarTemporarily()
        }
    }
    
    private func handleViewDisappear() {
        // Clean up any completion state
        if navigationState.isPresenting(OverlayType.completion(.regular)) ||
           navigationState.isPresenting(OverlayType.completion(.daily)) {
            navigationState.dismissOverlay()
        }
        
        // Reset UI animations
        uiViewModel.resetGameOverAnimation()
    }
}

// MARK: - Modern Overlay Manager

struct ModernOverlayManager: ViewModifier {
    let businessLogic: BusinessLogicCoordinator
    let navigationState: NavigationState
    let uiViewModel: PuzzleUIViewModel
    
    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject private var settingsViewModel: SettingsViewModel
    @Environment(\.typography) private var typography
    @Environment(\.dismiss) private var dismiss
    @Environment(AppSettings.self) private var appSettings
    
    func body(content: Content) -> some View {
        content
            .overlay(overlayContent)
    }
    
    @ViewBuilder
    private var overlayContent: some View {
        ZStack {
            // Info Overlay
            if navigationState.isPresenting(OverlayType.info) {
                InfoOverlayContent()
            }
            
            // Pause Overlay
            if navigationState.isPresenting(OverlayType.pause) {
                PauseOverlayContent()
            }
            
            // Game Over Overlay
            if navigationState.isPresenting(OverlayType.gameOver) {
                GameOverOverlayContent()
            }
            
            // Stats Overlay
            if navigationState.isPresenting(OverlayType.stats) {
                StatsOverlayContent()
            }
            
            // Settings Overlay
            if navigationState.isPresenting(OverlayType.settings) {
                SettingsOverlayContent()
            }
            
            // Calendar Overlay
            if navigationState.isPresenting(OverlayType.calendar) {
                CalendarOverlayContent()
            }
            
            // Completion Overlays
            if case .some(OverlayType.completion(let state)) = navigationState.presentedOverlay {
                CompletionOverlayContent(state: state)
            }
        }
    }
    
    // MARK: - Overlay Content Views
    
    @ViewBuilder
    private func InfoOverlayContent() -> some View {
        ZStack(alignment: .top) {
            CryptogramTheme.Colors.background
                .ignoresSafeArea()
                .opacity(PuzzleViewConstants.Overlay.backgroundOpacity)
                .contentShape(Rectangle())
                .onTapGesture {
                    navigationState.dismissOverlay()
                }
            
            VStack {
                Spacer(minLength: PuzzleViewConstants.Overlay.infoOverlayTopSpacing)
                ScrollView {
                    InfoOverlayView()
                }
                .padding(.horizontal, PuzzleViewConstants.Overlay.overlayHorizontalPadding)
                Spacer()
            }
            
            // Close button
            VStack {
                HStack {
                    Spacer()
                    Button(action: { navigationState.dismissOverlay() }) {
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
        .zIndex(OverlayZIndex.info)
    }
    
    @ViewBuilder
    private func PauseOverlayContent() -> some View {
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
                        businessLogic.togglePause()
                        navigationState.dismissOverlay()
                    }
                    .allowsHitTesting(true)
            }
        }
        .zIndex(OverlayZIndex.pauseGameOver)
        .transition(.opacity)
    }
    
    @ViewBuilder
    private func GameOverOverlayContent() -> some View {
        ZStack {
            CryptogramTheme.Colors.background
                .ignoresSafeArea()
                .opacity(0.98)
                .onTapGesture { } // Consume taps
            
            VStack(spacing: 48) {
                Spacer()
                
                Text(uiViewModel.displayedGameOver)
                    .font(typography.body)
                    .foregroundColor(CryptogramTheme.Colors.text)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 12)
                
                // Game over buttons
                VStack(spacing: 32) {
                    if uiViewModel.showGameOverButtons && !uiViewModel.showContinueFriction {
                        GameOverButtons()
                    } else if uiViewModel.showContinueFriction {
                        FrictionMessage()
                    } else {
                        // Placeholder buttons for layout
                        PlaceholderButtons()
                    }
                }
                .padding(.bottom, 180)
            }
            
            // Bottom bar for game over
            if uiViewModel.showGameOverButtons && !uiViewModel.showContinueFriction {
                GameOverBottomBar()
            }
        }
        .zIndex(OverlayZIndex.pauseGameOver)
        .transition(.opacity)
    }
    
    @ViewBuilder
    private func GameOverButtons() -> some View {
        VStack(spacing: 32) {
            Button("continue") {
                uiViewModel.startContinueFriction {
                    businessLogic.continueAfterFailure()
                    navigationState.dismissOverlay()
                }
            }
            .font(typography.caption)
            .foregroundColor(CryptogramTheme.Colors.text)
            
            Button("new puzzle") {
                Task {
                    await businessLogic.refreshPuzzleWithCurrentSettings()
                }
                navigationState.dismissOverlay()
            }
            .font(typography.caption)
            .foregroundColor(CryptogramTheme.Colors.text)
            
            Button("try again") {
                businessLogic.reset()
                if let currentPuzzle = businessLogic.currentPuzzle {
                    businessLogic.startNewPuzzle(puzzle: currentPuzzle)
                }
                navigationState.dismissOverlay()
            }
            .font(typography.caption)
            .foregroundColor(CryptogramTheme.Colors.text)
        }
        .transition(.opacity)
    }
    
    @ViewBuilder
    private func FrictionMessage() -> some View {
        VStack(spacing: 32) {
            Text(uiViewModel.frictionTypedText)
                .font(typography.caption)
                .foregroundColor(CryptogramTheme.Colors.text)
                .padding(.horizontal, 32)
                .multilineTextAlignment(.center)
            
            // Invisible placeholder buttons
            Text("new puzzle").font(typography.caption).foregroundColor(.clear)
            Text("try again").font(typography.caption).foregroundColor(.clear)
        }
        .transition(.opacity)
    }
    
    @ViewBuilder
    private func PlaceholderButtons() -> some View {
        VStack(spacing: 32) {
            Text("continue").font(typography.caption).foregroundColor(.clear)
            Text("new puzzle").font(typography.caption).foregroundColor(.clear)
            Text("try again").font(typography.caption).foregroundColor(.clear)
        }
    }
    
    @ViewBuilder
    private func GameOverBottomBar() -> some View {
        if navigationState.isGameOverBottomBarVisible {
            VStack {
                Spacer()
                HStack {
                    Button(action: navigationState.toggleStats) {
                        Image(systemName: "chart.bar")
                            .font(.system(size: PuzzleViewConstants.Sizes.statsIconSize))
                            .foregroundColor(CryptogramTheme.Colors.text)
                            .opacity(PuzzleViewConstants.Colors.iconOpacity)
                            .frame(width: PuzzleViewConstants.Sizes.iconButtonFrame, height: PuzzleViewConstants.Sizes.iconButtonFrame)
                    }
                    
                    Spacer()
                    
                    Button(action: { dismiss() }) {
                        Image(systemName: "house")
                            .font(.title3)
                            .foregroundColor(CryptogramTheme.Colors.text)
                            .opacity(PuzzleViewConstants.Colors.iconOpacity)
                            .frame(width: PuzzleViewConstants.Sizes.iconButtonFrame, height: PuzzleViewConstants.Sizes.iconButtonFrame)
                    }
                    
                    Spacer()
                    
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
            }
            .transition(.opacity)
        }
    }
    
    // Simplified placeholder implementations for other overlays
    @ViewBuilder private func StatsOverlayContent() -> some View {
        Rectangle().fill(Color.blue.opacity(0.3)).overlay(Text("Stats Overlay"))
    }
    
    @ViewBuilder private func SettingsOverlayContent() -> some View {
        Rectangle().fill(Color.green.opacity(0.3)).overlay(Text("Settings Overlay"))
    }
    
    @ViewBuilder private func CalendarOverlayContent() -> some View {
        Rectangle().fill(Color.orange.opacity(0.3)).overlay(Text("Calendar Overlay"))
    }
    
    @ViewBuilder private func CompletionOverlayContent(state: CompletionState) -> some View {
        Rectangle().fill(Color.purple.opacity(0.3)).overlay(Text("Completion: \(state)"))
    }
}

// Extension to make it easy to apply the modern overlay manager
extension View {
    func modernOverlayManager(
        businessLogic: BusinessLogicCoordinator,
        navigationState: NavigationState,
        uiViewModel: PuzzleUIViewModel
    ) -> some View {
        self.modifier(ModernOverlayManager(
            businessLogic: businessLogic,
            navigationState: navigationState,
            uiViewModel: uiViewModel
        ))
    }
}

// MARK: - Adapter Views for Existing Components

struct ModernTopBarView: View {
    let businessLogic: BusinessLogicCoordinator
    let navigationState: NavigationState
    
    var body: some View {
        HStack {
            Text("Top Bar")
            Spacer()
            Button("Pause") {
                businessLogic.togglePause()
                navigationState.showPause()
            }
        }
        .padding()
    }
}

struct ModernMainContentView: View {
    let businessLogic: BusinessLogicCoordinator
    let navigationState: NavigationState
    let layoutBinding: Binding<NavigationBarLayout>
    
    var body: some View {
        VStack {
            Text("Puzzle Content")
            Text("Progress: \(Int(businessLogic.progressPercentage))%")
        }
        .padding()
    }
}

struct ModernBottomBarView: View {
    let businessLogic: BusinessLogicCoordinator
    let navigationState: NavigationState
    
    var body: some View {
        if navigationState.isBottomBarVisible {
            HStack {
                Button("Stats") { navigationState.toggleStats() }
                Spacer()
                Button("Home") { navigationState.navigateToHome() }
                Spacer()
                Button("Settings") { navigationState.toggleSettings() }
            }
            .padding()
            .transition(.opacity)
        }
    }
}

#Preview {
    ModernPuzzleView(puzzle: Puzzle(
        quoteId: 1, 
        encodedText: "TEST ENCODED", 
        solution: "TEST DECODED", 
        hint: "test hint"
    ))
        .environmentObject(BusinessLogicCoordinator())
        .environmentObject(NavigationState())
        .environmentObject(ThemeManager())
        .environmentObject(SettingsViewModel())
        .environment(AppSettings())
}