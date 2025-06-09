import Foundation
import SwiftUI
import os.log

/// Performance optimizations for navigation system
@MainActor
final class NavigationPerformance {
    
    // MARK: - Logging
    static let logger = Logger(subsystem: "com.cryptogram.navigation", category: "performance")
    
    // MARK: - Navigation Optimizations
    
    /// Optimized navigation with preloading
    static func optimizedNavigate(
        to screen: Screen,
        navigationState: NavigationState,
        businessLogic: BusinessLogicCoordinator
    ) {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Preload resources if needed
        switch screen {
        case .puzzle(let puzzle):
            // Preload author data in background
            Task.detached(priority: .utility) {
                await businessLogic.authorService.loadAuthorIfNeeded(name: puzzle.hint)
            }
        case .home:
            // Clean up resources when returning home
            cleanupResources()
        }
        
        // Perform navigation
        navigationState.navigateTo(screen)
        
        let elapsed = CFAbsoluteTimeGetCurrent() - startTime
        logger.debug("Navigation to \(screen.id) completed in \(elapsed, format: .fixed(precision: 4))s")
    }
    
    /// Clean up resources when navigating away
    private static func cleanupResources() {
        // Cancel any pending operations
        URLSession.shared.getAllTasks { tasks in
            tasks.forEach { $0.cancel() }
        }
        
        // Clear image caches if needed
        URLCache.shared.removeAllCachedResponses()
    }
    
    // MARK: - Memory Optimizations
    
    /// Memory-efficient overlay presentation
    static func presentOverlayOptimized(
        _ overlay: OverlayType,
        navigationState: NavigationState
    ) {
        // Release previous overlay resources
        if let previousOverlay = navigationState.presentedOverlay {
            releaseOverlayResources(previousOverlay)
        }
        
        // Present new overlay
        navigationState.presentOverlay(overlay)
        
        // Preload overlay resources
        preloadOverlayResources(overlay)
    }
    
    private static func releaseOverlayResources(_ overlay: OverlayType) {
        switch overlay {
        case .stats, .calendar:
            // These overlays might have cached data
            NotificationCenter.default.post(name: .releaseOverlayResources, object: overlay)
        default:
            break
        }
    }
    
    private static func preloadOverlayResources(_ overlay: OverlayType) {
        switch overlay {
        case .calendar:
            // Preload calendar data
            Task.detached(priority: .utility) {
                // Preload today's daily puzzle
                _ = try? DatabaseService.shared.fetchDailyPuzzle(for: Date())
            }
        default:
            break
        }
    }
    
    // MARK: - Animation Optimizations
    
    /// Reduced motion support
    static var prefersReducedMotion: Bool {
        UIAccessibility.isReduceMotionEnabled
    }
    
    /// Get optimized animation based on system preferences
    static func optimizedAnimation(_ animation: Animation) -> Animation {
        if prefersReducedMotion {
            return .linear(duration: 0.01)  // Very fast animation instead of none
        }
        return animation
    }
    
    /// Get optimized transition based on system preferences
    static func optimizedTransition(_ transition: AnyTransition) -> AnyTransition {
        if prefersReducedMotion {
            return .opacity
        }
        return transition
    }
}

// MARK: - Navigation Cache

/// Cache for navigation-related data
@MainActor
final class NavigationCache {
    static let shared = NavigationCache()
    
    private var puzzleCache: [Int: Puzzle] = [:]
    private var authorCache: [String: Author] = [:]
    private let cacheLimit = 50
    
    private init() {}
    
    /// Cache a puzzle for quick access
    func cache(_ puzzle: Puzzle) {
        puzzleCache[puzzle.quoteId] = puzzle
        
        // Evict old entries if needed
        if puzzleCache.count > cacheLimit {
            let sortedKeys = puzzleCache.keys.sorted()
            if let oldestKey = sortedKeys.first {
                puzzleCache.removeValue(forKey: oldestKey)
            }
        }
    }
    
    /// Retrieve cached puzzle
    func getCachedPuzzle(id: Int) -> Puzzle? {
        return puzzleCache[id]
    }
    
    /// Cache author data
    func cache(_ author: Author) {
        authorCache[author.name] = author
        
        // Evict if needed
        if authorCache.count > cacheLimit {
            if let oldestKey = authorCache.keys.first {
                authorCache.removeValue(forKey: oldestKey)
            }
        }
    }
    
    /// Clear all caches
    func clearAll() {
        puzzleCache.removeAll()
        authorCache.removeAll()
    }
}

// MARK: - Performance Monitoring

extension NavigationState {
    /// Enable performance monitoring for navigation
    func enablePerformanceMonitoring() {
        if FeatureFlag.performanceMonitoring.isEnabled {
            $currentScreen
                .sink { [weak self] screen in
                    guard self != nil else { return }
                    NavigationPerformance.logger.debug("Screen changed to: \(screen.id)")
                }
                .store(in: &cancellables)
        }
    }
}

// MARK: - View Extensions for Performance

extension View {
    /// Apply performance-optimized navigation transition
    func performanceOptimizedTransition() -> some View {
        self.transition(
            NavigationPerformance.optimizedTransition(
                NavigationAnimations.slideAndFade
            )
        )
        .animation(
            NavigationPerformance.optimizedAnimation(
                NavigationAnimations.navigationSpring
            ),
            value: UUID()
        )
    }
    
    /// Apply performance-optimized overlay transition
    func performanceOptimizedOverlay() -> some View {
        self.transition(
            NavigationPerformance.optimizedTransition(
                NavigationAnimations.scaleAndFade
            )
        )
        .animation(
            NavigationPerformance.optimizedAnimation(
                NavigationAnimations.overlaySpring
            ),
            value: UUID()
        )
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let releaseOverlayResources = Notification.Name("releaseOverlayResources")
}

// MARK: - Lazy Loading Support

/// Protocol for views that support lazy loading
protocol LazyLoadable {
    func preload() async
    func unload()
}

/// Lazy loading container for heavy views
struct LazyLoadingView<Content: View>: View {
    let content: () -> Content
    @State private var isLoaded = false
    
    var body: some View {
        Group {
            if isLoaded {
                content()
            } else {
                ProgressView()
                    .task {
                        // Small delay to let navigation complete
                        try? await Task.sleep(nanoseconds: 50_000_000) // 0.05s
                        withAnimation {
                            isLoaded = true
                        }
                    }
            }
        }
    }
}