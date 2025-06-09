import Foundation
import SwiftUI
import Combine

/// Represents the main application screens
enum Screen: Hashable, Equatable {
    case home
    case puzzle(Puzzle)
    
    var id: String {
        switch self {
        case .home:
            return "home"
        case .puzzle(let puzzle):
            return "puzzle_\(puzzle.id)"
        }
    }
}

// OverlayType is defined in OverlayManager.swift - reusing existing definition

/// Centralized navigation and UI state management
/// Separates navigation concerns from business logic
@MainActor
class NavigationState: ObservableObject {
    // MARK: - Navigation State
    
    /// Current active screen
    @Published var currentScreen: Screen = .home
    
    /// Navigation stack for SwiftUI NavigationStack
    @Published var navigationPath = NavigationPath()
    
    /// Currently presented overlay (only one overlay can be active at a time)
    @Published var presentedOverlay: OverlayType?
    
    /// Navigation history for back navigation
    @Published internal var navigationHistory: [Screen] = []
    
    // MARK: - UI State Management
    
    /// Bottom bar visibility state
    @Published var isBottomBarVisible = true
    
    /// Game over specific bottom bar visibility
    @Published var isGameOverBottomBarVisible = false
    
    /// Animation states
    @Published var isSwitchingPuzzle = false
    
    // MARK: - Auto-hide Management
    private var bottomBarHideWorkItem: DispatchWorkItem?
    private var gameOverBottomBarHideWorkItem: DispatchWorkItem?
    
    // MARK: - Combine
    internal var cancellables = Set<AnyCancellable>()
    
    // MARK: - Navigation Methods
    
    /// Navigate to a specific screen
    func navigateTo(_ screen: Screen) {
        // Add current screen to history before navigation
        if currentScreen != screen {
            navigationHistory.append(currentScreen)
        }
        
        withAnimation(NavigationAnimations.navigationSpring) {
            currentScreen = screen
        }
        
        // Update NavigationPath for SwiftUI NavigationStack
        switch screen {
        case .home:
            navigationPath = NavigationPath()
        case .puzzle(let puzzle):
            navigationPath.append(puzzle)
        }
        
        // Dismiss any active overlay when navigating
        dismissOverlay()
    }
    
    /// Navigate back to the previous screen
    func navigateBack() {
        guard let previousScreen = navigationHistory.popLast() else {
            // No history, go to home
            navigateTo(.home)
            return
        }
        
        withAnimation(NavigationAnimations.navigationSpring) {
            currentScreen = previousScreen
        }
        
        // Update NavigationPath
        switch previousScreen {
        case .home:
            navigationPath = NavigationPath()
        case .puzzle(let puzzle):
            navigationPath.append(puzzle)
        }
        
        dismissOverlay()
    }
    
    /// Navigate to home screen (root)
    func navigateToHome() {
        navigationHistory.removeAll()
        navigateTo(.home)
    }
    
    /// Navigate to puzzle screen
    func navigateToPuzzle(_ puzzle: Puzzle) {
        navigateTo(.puzzle(puzzle))
    }
    
    // MARK: - Overlay Management
    
    /// Present an overlay over the current screen
    func presentOverlay(_ overlay: OverlayType) {
        withAnimation(NavigationAnimations.overlaySpring) {
            presentedOverlay = overlay
        }
        
        // Show bottom bar when overlay is presented
        showBottomBarTemporarily()
    }
    
    /// Dismiss the currently presented overlay
    func dismissOverlay() {
        guard presentedOverlay != nil else { return }
        
        withAnimation(NavigationAnimations.fadeOut) {
            presentedOverlay = nil
        }
    }
    
    /// Check if a specific overlay is currently presented
    func isPresenting(_ overlay: OverlayType) -> Bool {
        return presentedOverlay == overlay
    }
    
    /// Check if any overlay is currently presented
    var isAnyOverlayPresented: Bool {
        return presentedOverlay != nil
    }
    
    // MARK: - UI State Management
    
    /// Shows the bottom bar temporarily with auto-hide
    func showBottomBarTemporarily() {
        withAnimation {
            isBottomBarVisible = true
        }
        
        bottomBarHideWorkItem?.cancel()
        
        let workItem = DispatchWorkItem { [weak self] in
            Task { @MainActor in
                withAnimation {
                    self?.isBottomBarVisible = false
                }
            }
        }
        bottomBarHideWorkItem = workItem
        DispatchQueue.main.asyncAfter(
            deadline: .now() + PuzzleViewConstants.Animation.bottomBarAutoHideDelay,
            execute: workItem
        )
    }
    
    /// Shows the game over bottom bar temporarily with auto-hide
    func showGameOverBottomBarTemporarily() {
        withAnimation {
            isGameOverBottomBarVisible = true
        }
        
        gameOverBottomBarHideWorkItem?.cancel()
        
        let workItem = DispatchWorkItem { [weak self] in
            Task { @MainActor in
                withAnimation {
                    self?.isGameOverBottomBarVisible = false
                }
            }
        }
        gameOverBottomBarHideWorkItem = workItem
        DispatchQueue.main.asyncAfter(
            deadline: .now() + PuzzleViewConstants.Animation.bottomBarAutoHideDelay,
            execute: workItem
        )
    }
    
    /// Cancels auto-hide of bottom bar
    func cancelBottomBarHide() {
        bottomBarHideWorkItem?.cancel()
        withAnimation {
            isBottomBarVisible = true
        }
    }
    
    /// Starts puzzle switching animation
    func animatePuzzleSwitch(completion: @escaping () -> Void) {
        withAnimation(NavigationAnimations.puzzleSwitchSpring) {
            isSwitchingPuzzle = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + NavigationAnimations.Duration.puzzleSwitch) {
            Task { @MainActor in
                completion()
                withAnimation(NavigationAnimations.puzzleSwitchSpring) {
                    self.isSwitchingPuzzle = false
                }
            }
        }
    }
    
    // MARK: - Convenience Methods
    
    /// Toggle overlay - present if not shown, dismiss if shown
    func toggleOverlay(_ overlay: OverlayType) {
        if isPresenting(overlay) {
            dismissOverlay()
        } else {
            presentOverlay(overlay)
        }
    }
    
    /// Quick access for common overlays
    func toggleSettings() {
        toggleOverlay(OverlayType.settings)
    }
    
    func toggleStats() {
        toggleOverlay(OverlayType.stats)
    }
    
    func toggleCalendar() {
        toggleOverlay(OverlayType.calendar)
    }
    
    func toggleInfo() {
        toggleOverlay(OverlayType.info)
    }
    
    /// Present completion overlay based on completion state
    func showCompletion(_ state: CompletionState) {
        presentOverlay(OverlayType.completion(state))
    }
    
    /// Show game over overlay
    func showGameOver() {
        presentOverlay(OverlayType.gameOver)
    }
    
    /// Show pause overlay
    func showPause() {
        presentOverlay(OverlayType.pause)
    }
    
    // MARK: - State Queries
    
    /// Whether main UI controls should be visible (no overlays)
    var isMainUIVisible: Bool {
        return !isAnyOverlayPresented
    }
    
    /// Whether we're currently on the home screen
    var isOnHomeScreen: Bool {
        switch currentScreen {
        case .home:
            return true
        case .puzzle:
            return false
        }
    }
    
    /// Whether we're currently on a puzzle screen
    var isOnPuzzleScreen: Bool {
        switch currentScreen {
        case .home:
            return false
        case .puzzle:
            return true
        }
    }
    
    /// Get the current puzzle if on puzzle screen
    var currentPuzzle: Puzzle? {
        switch currentScreen {
        case .home:
            return nil
        case .puzzle(let puzzle):
            return puzzle
        }
    }
}