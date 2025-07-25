import SwiftUI
import Combine

/// Represents the different completion view states
enum CompletionState: Equatable {
    case none
    case regular
    case daily
}

/// Manages UI state for PuzzleView, separating presentation logic from game logic
@MainActor
class PuzzleViewState: ObservableObject {
    // MARK: - Overlay States
    @Published var showSettings = false
    @Published var completionState: CompletionState = .none
    @Published var showStatsOverlay = false
    @Published var showInfoOverlay = false
    @Published var showCalendar = false
    
    // Legacy completion view properties (for backward compatibility during transition)
    var showCompletionView: Bool {
        get { completionState == .regular }
        set { completionState = newValue ? .regular : .none }
    }
    
    var showDailyCompletionView: Bool {
        get { completionState == .daily }
        set { completionState = newValue ? .daily : .none }
    }
    
    // MARK: - Animation States
    @Published var isSwitchingPuzzle = false
    @Published var displayedGameOver = ""
    
    // MARK: - Bottom Bar
    @Published var isBottomBarVisible = true
    @Published var isGameOverBottomBarVisible = false
    private var bottomBarHideWorkItem: DispatchWorkItem?
    private var gameOverBottomBarHideWorkItem: DispatchWorkItem?
    
    // MARK: - Constants
    let fullGameOverText = "game over"
    
    // MARK: - Computed Properties
    
    /// Whether the main UI controls should be visible (no overlays active)
    var isMainUIVisible: Bool {
        !showSettings && !showStatsOverlay && !showCalendar && completionState == .none
    }
    
    /// Whether any modal overlay is showing
    var isAnyOverlayVisible: Bool {
        showSettings || showStatsOverlay || showCalendar || completionState != .none || showInfoOverlay
    }
    
    // MARK: - Methods
    
    /// Shows the bottom bar temporarily, auto-hiding after 3 seconds
    func showBottomBarTemporarily() {
        isBottomBarVisible = true
        bottomBarHideWorkItem?.cancel()
        
        let workItem = DispatchWorkItem { [weak self] in
            withAnimation {
                self?.isBottomBarVisible = false
            }
        }
        bottomBarHideWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + PuzzleViewConstants.Animation.bottomBarAutoHideDelay, execute: workItem)
    }
    
    /// Shows the game over bottom bar temporarily, auto-hiding after 3 seconds
    func showGameOverBottomBarTemporarily() {
        isGameOverBottomBarVisible = true
        gameOverBottomBarHideWorkItem?.cancel()
        
        let workItem = DispatchWorkItem { [weak self] in
            withAnimation {
                self?.isGameOverBottomBarVisible = false
            }
        }
        gameOverBottomBarHideWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + PuzzleViewConstants.Animation.bottomBarAutoHideDelay, execute: workItem)
    }
    
    /// Cancels auto-hide of bottom bar
    func cancelBottomBarHide() {
        bottomBarHideWorkItem?.cancel()
        isBottomBarVisible = true
    }
    
    /// Toggles settings overlay, closing other overlays
    func toggleSettings() {
        withAnimation {
            if showSettings {
                showSettings = false
                showStatsOverlay = false
            } else {
                showSettings = true
                showStatsOverlay = false
            }
            showBottomBarTemporarily()
            showGameOverBottomBarTemporarily()
        }
    }
    
    /// Toggles stats overlay, closing other overlays
    func toggleStats() {
        withAnimation {
            if showStatsOverlay {
                showStatsOverlay = false
                showSettings = false
            } else {
                showStatsOverlay = true
                showSettings = false
            }
            showBottomBarTemporarily()
            showGameOverBottomBarTemporarily()
        }
    }
    
    /// Closes all overlays
    func closeAllOverlays() {
        withAnimation {
            showSettings = false
            showStatsOverlay = false
            showInfoOverlay = false
            showCalendar = false
            completionState = .none
        }
    }
    
    /// Handles puzzle switching animation
    func animatePuzzleSwitch(completion: @escaping () -> Void) {
        withAnimation(.easeInOut(duration: PuzzleViewConstants.Animation.puzzleSwitchDuration)) {
            isSwitchingPuzzle = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + PuzzleViewConstants.Animation.puzzleSwitchDuration) {
            completion()
            withAnimation(.easeInOut(duration: PuzzleViewConstants.Animation.puzzleSwitchDuration)) {
                self.isSwitchingPuzzle = false
            }
        }
    }
    
    /// Starts typewriter effect for game over text
    func startGameOverTypewriter(delay: TimeInterval = 1.2) {
        displayedGameOver = ""
        for (i, ch) in fullGameOverText.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay + Double(i) * 0.2) { [weak self] in
                self?.displayedGameOver.append(ch)
            }
        }
    }
}