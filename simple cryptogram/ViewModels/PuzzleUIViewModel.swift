import Foundation
import SwiftUI
import Observation

/// View model specifically for PuzzleView UI state
/// Handles presentation logic without business logic
@MainActor
@Observable
final class PuzzleUIViewModel {
    // MARK: - Animation States
    var displayedGameOver = ""
    var showGameOverButtons = false
    var showContinueFriction = false
    var frictionTypedText = ""
    
    // MARK: - Game Over Animation
    private let fullGameOverText = "game over"
    // Timer properties excluded from observation - Timer.invalidate() is thread-safe for deinit access
    @ObservationIgnored private var gameOverTypingTimer: Timer?
    @ObservationIgnored private var frictionTypingTimer: Timer?
    
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
    
    // MARK: - Game Over Animation Methods
    
    /// Start the game over typewriter animation
    func startGameOverTypewriter(onComplete: @escaping () -> Void) {
        resetGameOverAnimation()
        
        let selectedMessage = gameOverMessages.randomElement() ?? "game over"
        
        // Start typing after 0.7s delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            Task { @MainActor in
                self.typeGameOverMessage(selectedMessage, onComplete: onComplete)
            }
        }
    }
    
    /// Start the continue friction message
    func startContinueFriction(onComplete: @escaping () -> Void) {
        withAnimation {
            showGameOverButtons = false
            showContinueFriction = true
        }
        
        frictionTypedText = ""
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            Task { @MainActor in
                self.typeFrictionMessage(onComplete: onComplete)
            }
        }
    }
    
    /// Reset all game over animation state
    func resetGameOverAnimation() {
        gameOverTypingTimer?.invalidate()
        frictionTypingTimer?.invalidate()
        displayedGameOver = ""
        showGameOverButtons = false
        showContinueFriction = false
        frictionTypedText = ""
    }
    
    // MARK: - Private Animation Methods
    
    private func typeGameOverMessage(_ message: String, onComplete: @escaping () -> Void) {
        gameOverTypingTimer?.invalidate()
        
        let characters = Array(message)
        var currentIndex = 0
        
        gameOverTypingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            if currentIndex < characters.count {
                Task { @MainActor in
                    self.displayedGameOver.append(characters[currentIndex])
                }
                currentIndex += 1
            } else {
                timer.invalidate()
                Task { @MainActor in
                    withAnimation {
                        self.showGameOverButtons = true
                    }
                    onComplete()
                }
            }
        }
    }
    
    private func typeFrictionMessage(onComplete: @escaping () -> Void) {
        frictionTypingTimer?.invalidate()
        
        let message = "since there are no ads this is a bit of friction cause, well, you did make 3 mistakes..."
        let characters = Array(message)
        var currentIndex = 0
        
        frictionTypingTimer = Timer.scheduledTimer(withTimeInterval: 0.08, repeats: true) { timer in
            if currentIndex < characters.count {
                Task { @MainActor in
                    self.frictionTypedText.append(characters[currentIndex])
                }
                currentIndex += 1
            } else {
                timer.invalidate()
                // Auto-continue after typing completes
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    Task { @MainActor in
                        onComplete()
                    }
                }
            }
        }
    }
    
    deinit {
        // Timer invalidation is safe from deinit
        gameOverTypingTimer?.invalidate()
        frictionTypingTimer?.invalidate()
    }
}