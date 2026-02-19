import SwiftUI

enum PuzzleViewConstants {
    // MARK: - Spacing
    enum Spacing {
        static let topBarPadding: CGFloat = 16
        static let mainContentHorizontalPadding: CGFloat = 12
        static let puzzleGridHorizontalPadding: CGFloat = 16
        static let puzzleGridBottomPadding: CGFloat = 12
        static let keyboardHorizontalPadding: CGFloat = 4
        static let bottomBarHeight: CGFloat = 48
        static let bottomBarHorizontalPadding: CGFloat = 64
    }
    
    // MARK: - Sizes
    enum Sizes {
        static let iconButtonFrame: CGFloat = 44
        static let statsIconSize: CGFloat = 20
        static let settingsIconSize: CGFloat = 24
        static let questionMarkSize: CGFloat = 13
        static let floatingInfoButtonSize: CGFloat = 24
        static let floatingInfoButtonOffset: CGSize = CGSize(width: -10, height: 50)
    }
    
    // MARK: - Animation
    enum Animation {
        static let overlayDuration: TimeInterval = 0.3
        static let puzzleSwitchDuration: TimeInterval = 0.5
        static let completionDelay: TimeInterval = 0.7
        static let dailyPuzzleLoadDelay: TimeInterval = 0.05
        static let failedAnimationDuration: TimeInterval = 1.0
        static let pausedAnimationDuration: TimeInterval = 0.6
        static let bottomBarAutoHideDelay: TimeInterval = 3.0
        static let completionWiggleDelay: TimeInterval = 0.8
    }
    
    // MARK: - Overlay
    enum Overlay {
        static let backgroundOpacity: Double = 0.98
        static let settingsBackgroundOpacity: Double = 0.95
        static let pauseOverlayOpacity: Double = 0.5
        static let pauseTextBottomPadding: CGFloat = 240
        static let overlayHorizontalPadding: CGFloat = 24
        static let overlayVerticalPadding: CGFloat = 20
        static let infoOverlayTopSpacing: CGFloat = 120
        static let statsOverlayTopPadding: CGFloat = 24
    }
    
    // MARK: - Colors
    enum Colors {
        static let dailyPuzzleGreen = Color(hex: "#01780F")
        static let iconOpacity: Double = 0.7
        static let activeIconOpacity: Double = 1.0
    }
}