import SwiftUI
import Observation

/// Represents the different completion view states
enum CompletionState: Equatable {
    case none
    case regular
    case daily
}

/// Manages UI state for PuzzleView, separating presentation logic from game logic
@MainActor
@Observable
final class PuzzleViewState {
    // MARK: - Overlay States
    var showSettings = false
    var completionState: CompletionState = .none
    var showStatsOverlay = false
    var showInfoOverlay = false
    var showCalendar = false
    
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
    var isSwitchingPuzzle = false
    var displayedGameOver = ""

    // MARK: - Bottom Bar
    var isBottomBarVisible = true
    var isGameOverBottomBarVisible = false
    private var bottomBarHideTask: Task<Void, Never>?
    private var gameOverBottomBarHideTask: Task<Void, Never>?
    
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
        bottomBarHideTask?.cancel()

        bottomBarHideTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(PuzzleViewConstants.Animation.bottomBarAutoHideDelay))
            guard !Task.isCancelled else { return }
            withAnimation {
                self?.isBottomBarVisible = false
            }
        }
    }
    
    /// Shows the game over bottom bar temporarily, auto-hiding after 3 seconds
    func showGameOverBottomBarTemporarily() {
        isGameOverBottomBarVisible = true
        gameOverBottomBarHideTask?.cancel()

        gameOverBottomBarHideTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(PuzzleViewConstants.Animation.bottomBarAutoHideDelay))
            guard !Task.isCancelled else { return }
            withAnimation {
                self?.isGameOverBottomBarVisible = false
            }
        }
    }
    
    /// Cancels auto-hide of bottom bar
    func cancelBottomBarHide() {
        bottomBarHideTask?.cancel()
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
    func animatePuzzleSwitch() async {
        withAnimation(.easeInOut(duration: PuzzleViewConstants.Animation.puzzleSwitchDuration)) {
            isSwitchingPuzzle = true
        }

        try? await Task.sleep(for: .seconds(PuzzleViewConstants.Animation.puzzleSwitchDuration))
    }

    /// Ends puzzle switching animation
    func endPuzzleSwitch() {
        withAnimation(.easeInOut(duration: PuzzleViewConstants.Animation.puzzleSwitchDuration)) {
            isSwitchingPuzzle = false
        }
    }
    
    /// Starts typewriter effect for game over text
    func startGameOverTypewriter(delay: TimeInterval = 1.2) {
        displayedGameOver = ""
        Task { [weak self] in
            try? await Task.sleep(for: .seconds(delay))
            guard !Task.isCancelled, let self = self else { return }

            for (i, ch) in fullGameOverText.enumerated() {
                try? await Task.sleep(for: .seconds(Double(i) * 0.2))
                guard !Task.isCancelled else { return }
                self.displayedGameOver.append(ch)
            }
        }
    }
}