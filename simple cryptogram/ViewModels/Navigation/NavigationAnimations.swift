import SwiftUI

/// Custom navigation transitions and animations for the app
enum NavigationAnimations {
    
    // MARK: - Animation Constants
    enum Duration {
        static let navigationTransition: TimeInterval = 0.35
        static let overlayPresent: TimeInterval = 0.3
        static let overlayDismiss: TimeInterval = 0.25
        static let puzzleSwitch: TimeInterval = 0.4
        static let screenFade: TimeInterval = 0.2
    }
    
    // MARK: - Spring Animations
    static let navigationSpring = Animation.spring(
        response: Duration.navigationTransition,
        dampingFraction: 0.85,
        blendDuration: 0
    )
    
    static let overlaySpring = Animation.spring(
        response: Duration.overlayPresent,
        dampingFraction: 0.9,
        blendDuration: 0
    )
    
    static let puzzleSwitchSpring = Animation.spring(
        response: Duration.puzzleSwitch,
        dampingFraction: 0.8,
        blendDuration: 0
    )
    
    // MARK: - Easing Animations
    static let fadeIn = Animation.easeIn(duration: Duration.screenFade)
    static let fadeOut = Animation.easeOut(duration: Duration.screenFade)
    static let smoothTransition = Animation.easeInOut(duration: Duration.navigationTransition)
    
    // MARK: - Custom Transitions
    
    /// Slide and fade transition for navigation
    static var slideAndFade: AnyTransition {
        AnyTransition.asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        )
    }
    
    /// Scale and fade transition for overlays
    static var scaleAndFade: AnyTransition {
        AnyTransition.scale(scale: 0.9).combined(with: .opacity)
    }
    
    /// Bottom sheet style transition
    static var bottomSheet: AnyTransition {
        AnyTransition.asymmetric(
            insertion: .move(edge: .bottom).combined(with: .opacity),
            removal: .move(edge: .bottom).combined(with: .opacity)
        )
    }
    
    /// Puzzle switch transition (fade through)
    static var puzzleSwitch: AnyTransition {
        AnyTransition.asymmetric(
            insertion: .opacity.animation(fadeIn),
            removal: .opacity.animation(fadeOut)
        )
    }
}

// MARK: - View Extensions for Navigation Animations

extension View {
    /// Apply navigation transition animation
    func navigationTransition() -> some View {
        self.transition(NavigationAnimations.slideAndFade)
            .animation(NavigationAnimations.navigationSpring, value: UUID())
    }
    
    /// Apply overlay presentation animation
    func overlayTransition() -> some View {
        self.transition(NavigationAnimations.scaleAndFade)
            .animation(NavigationAnimations.overlaySpring, value: UUID())
    }
    
    /// Apply puzzle switch animation
    func puzzleSwitchTransition() -> some View {
        self.transition(NavigationAnimations.puzzleSwitch)
            .animation(NavigationAnimations.puzzleSwitchSpring, value: UUID())
    }
}

// MARK: - Navigation Transition Modifier

struct NavigationTransitionModifier: ViewModifier {
    let isPresented: Bool
    let transition: AnyTransition
    let animation: Animation
    
    func body(content: Content) -> some View {
        if isPresented {
            content
                .transition(transition)
                .animation(animation, value: isPresented)
        }
    }
}

// MARK: - Custom Navigation Link Style

struct AnimatedNavigationLinkStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}