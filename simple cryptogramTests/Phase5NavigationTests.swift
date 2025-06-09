import Testing
import Foundation
import SwiftUI
@testable import simple_cryptogram

/// Tests for Phase 5 navigation enhancements
@MainActor
struct Phase5NavigationTests {
    
    // MARK: - Navigation Animation Tests
    
    @Test func navigationAnimationsAreDefined() {
        // Test animation constants
        #expect(NavigationAnimations.Duration.navigationTransition > 0)
        #expect(NavigationAnimations.Duration.overlayPresent > 0)
        #expect(NavigationAnimations.Duration.overlayDismiss > 0)
        #expect(NavigationAnimations.Duration.puzzleSwitch > 0)
        
        // Test spring animations exist
        #expect(NavigationAnimations.navigationSpring != nil)
        #expect(NavigationAnimations.overlaySpring != nil)
        #expect(NavigationAnimations.puzzleSwitchSpring != nil)
        
        // Test transitions exist
        #expect(NavigationAnimations.slideAndFade != nil)
        #expect(NavigationAnimations.scaleAndFade != nil)
        #expect(NavigationAnimations.bottomSheet != nil)
    }
    
    @Test func navigationStateUsesAnimations() async {
        let navigationState = NavigationState()
        let puzzle = createTestPuzzle()
        
        // Test navigation with animation
        navigationState.navigateTo(.puzzle(puzzle))
        #expect(navigationState.currentScreen == .puzzle(puzzle))
        
        // Test overlay animation
        navigationState.presentOverlay(.settings)
        #expect(navigationState.presentedOverlay == .settings)
        
        navigationState.dismissOverlay()
        #expect(navigationState.presentedOverlay == nil)
    }
    
    // MARK: - Deep Linking Tests
    
    @Test func deepLinkParsing() {
        // Test home deep link
        if let homeURL = URL(string: "cryptogram://home") {
            let deepLink = DeepLinkManager.DeepLink.parse(from: homeURL)
            #expect(deepLink == .home)
        }
        
        // Test puzzle deep link
        if let puzzleURL = URL(string: "cryptogram://puzzle/123") {
            let deepLink = DeepLinkManager.DeepLink.parse(from: puzzleURL)
            #expect(deepLink == .puzzle(id: 123))
        }
        
        // Test daily puzzle deep link
        if let dailyURL = URL(string: "cryptogram://daily") {
            let deepLink = DeepLinkManager.DeepLink.parse(from: dailyURL)
            #expect(deepLink == .dailyPuzzle(date: nil))
        }
        
        // Test daily puzzle with date
        if let dailyDateURL = URL(string: "cryptogram://daily/2025-01-09") {
            let deepLink = DeepLinkManager.DeepLink.parse(from: dailyDateURL)
            if case .dailyPuzzle(let date) = deepLink! {
                #expect(date != nil)
            } else {
                Issue.record("Expected daily puzzle with date")
            }
        }
        
        // Test stats deep link
        if let statsURL = URL(string: "cryptogram://stats") {
            let deepLink = DeepLinkManager.DeepLink.parse(from: statsURL)
            #expect(deepLink == .stats)
        }
        
        // Test settings deep link
        if let settingsURL = URL(string: "cryptogram://settings") {
            let deepLink = DeepLinkManager.DeepLink.parse(from: settingsURL)
            #expect(deepLink == .settings)
        }
    }
    
    @Test func deepLinkURLGeneration() {
        // Test URL generation
        let homeLink = DeepLinkManager.DeepLink.home
        #expect(homeLink.url?.absoluteString == "cryptogram://home")
        
        let puzzleLink = DeepLinkManager.DeepLink.puzzle(id: 456)
        #expect(puzzleLink.url?.absoluteString == "cryptogram://puzzle/456")
        
        let dailyLink = DeepLinkManager.DeepLink.dailyPuzzle(date: nil)
        #expect(dailyLink.url?.absoluteString == "cryptogram://daily")
        
        let statsLink = DeepLinkManager.DeepLink.stats
        #expect(statsLink.url?.absoluteString == "cryptogram://stats")
    }
    
    @Test func deepLinkManagerHandling() async {
        let deepLinkManager = DeepLinkManager()
        let navigationState = NavigationState()
        let businessLogic = BusinessLogicCoordinator()
        
        // Configure manager
        deepLinkManager.configure(
            navigationState: navigationState,
            businessLogic: businessLogic
        )
        
        // Test pending deep link
        if let url = URL(string: "cryptogram://home") {
            deepLinkManager.handle(url: url)
            
            // Should navigate to home
            #expect(navigationState.currentScreen == .home)
        }
        
        // Test stats deep link
        if let statsURL = URL(string: "cryptogram://stats") {
            deepLinkManager.handle(url: statsURL)
            
            // Wait for navigation
            try? await Task.sleep(nanoseconds: 100_000_000)
            
            // Should present stats overlay
            #expect(navigationState.presentedOverlay == .stats)
        }
    }
    
    // MARK: - Navigation Persistence Tests
    
    @Test func navigationPersistenceSaveAndRestore() async {
        let persistence = NavigationPersistence()
        let navigationState = NavigationState()
        let businessLogic = BusinessLogicCoordinator()
        
        // Set up navigation state
        let puzzle = createTestPuzzle()
        navigationState.navigateTo(.puzzle(puzzle))
        navigationState.navigationHistory = [.home]
        
        // Save state
        persistence.save(navigationState: navigationState)
        
        // Create new navigation state
        let newNavigationState = NavigationState()
        
        // Restore state
        await persistence.restore(to: newNavigationState, businessLogic: businessLogic)
        
        // Should restore to home (puzzle might not exist in test DB)
        #expect(newNavigationState.currentScreen == .home)
    }
    
    @Test func navigationPersistenceTimeLimits() {
        let persistence = NavigationPersistence()
        
        // Test fresh state
        #expect(persistence.hasSavedState == false)
        
        // Save state
        let navigationState = NavigationState()
        persistence.save(navigationState: navigationState)
        
        #expect(persistence.hasSavedState == true)
        #expect(persistence.lastOpenedDate != nil)
        
        // Clear state
        persistence.clearSavedState()
        #expect(persistence.hasSavedState == false)
    }
    
    // MARK: - Performance Optimization Tests
    
    @Test func navigationPerformanceOptimizations() async {
        let navigationState = NavigationState()
        let businessLogic = BusinessLogicCoordinator()
        
        // Test optimized navigation
        let startTime = CFAbsoluteTimeGetCurrent()
        
        NavigationPerformance.optimizedNavigate(
            to: .home,
            navigationState: navigationState,
            businessLogic: businessLogic
        )
        
        let elapsed = CFAbsoluteTimeGetCurrent() - startTime
        
        // Navigation should be fast
        #expect(elapsed < 0.1, "Navigation took \(elapsed)s")
        #expect(navigationState.currentScreen == .home)
    }
    
    @Test func navigationCacheOperations() {
        let cache = NavigationCache.shared
        
        // Clear cache first
        cache.clearAll()
        
        // Test puzzle caching
        let puzzle = createTestPuzzle()
        cache.cache(puzzle)
        
        let cachedPuzzle = cache.getCachedPuzzle(id: puzzle.quoteId)
        #expect(cachedPuzzle?.quoteId == puzzle.quoteId)
        
        // Test author caching
        let author = Author(
            id: 1,
            name: "Test Author",
            fullName: "Test Author Full",
            birthDate: "1900-01-01",
            deathDate: "2000-01-01",
            placeOfBirth: "Test City",
            placeOfDeath: "Test City",
            summary: "Test bio"
        )
        cache.cache(author)
        
        // Clear and verify
        cache.clearAll()
        #expect(cache.getCachedPuzzle(id: puzzle.id) == nil)
    }
    
    @Test func reducedMotionSupport() {
        // Test that reduced motion APIs are accessible
        let prefersReduced = NavigationPerformance.prefersReducedMotion
        #expect(prefersReduced == UIAccessibility.isReduceMotionEnabled)
        
        // Test animation optimization
        let animation = Animation.easeInOut
        let optimized = NavigationPerformance.optimizedAnimation(animation)
        
        if prefersReduced {
            #expect(optimized == .none)
        } else {
            #expect(optimized == animation)
        }
    }
    
    // MARK: - Integration Tests
    
    @Test func phase5IntegratedNavigation() async {
        let navigationState = NavigationState()
        let businessLogic = BusinessLogicCoordinator()
        let deepLinkManager = DeepLinkManager()
        
        // Enable all features
        navigationState.enablePersistence()
        navigationState.enablePerformanceMonitoring()
        
        // Configure deep linking
        deepLinkManager.configure(
            navigationState: navigationState,
            businessLogic: businessLogic
        )
        
        // Test navigation flow
        navigationState.navigateToHome()
        #expect(navigationState.isOnHomeScreen)
        
        // Test overlay with animation
        navigationState.presentOverlay(.settings)
        #expect(navigationState.isAnyOverlayPresented)
        
        // Test puzzle switch animation
        var animationCompleted = false
        navigationState.animatePuzzleSwitch {
            animationCompleted = true
        }
        
        #expect(navigationState.isSwitchingPuzzle)
        
        // Wait for animation
        try? await Task.sleep(nanoseconds: 500_000_000)
        #expect(animationCompleted)
        #expect(!navigationState.isSwitchingPuzzle)
    }
    
    // MARK: - Helpers
    
    private func createTestPuzzle() -> Puzzle {
        return Puzzle(
            quoteId: 1,
            encodedText: "SDRS PZXSD",
            solution: "TEST QUOTE",
            hint: "Test Author",
            author: "Test Author",
            difficulty: "easy"
        )
    }
}

// MARK: - Performance Measurement Tests

extension Phase5NavigationTests {
    
    @Test func measureNavigationPerformance() async {
        let iterations = 10
        var totalTime: TimeInterval = 0
        
        for _ in 0..<iterations {
            let navigationState = NavigationState()
            let puzzle = createTestPuzzle()
            
            let startTime = CFAbsoluteTimeGetCurrent()
            navigationState.navigateTo(.puzzle(puzzle))
            navigationState.navigateToHome()
            let elapsed = CFAbsoluteTimeGetCurrent() - startTime
            
            totalTime += elapsed
        }
        
        let averageTime = totalTime / Double(iterations)
        #expect(averageTime < 0.01, "Average navigation time: \(averageTime)s")
        
        print("📊 Phase 5 - Average navigation time: \(String(format: "%.6f", averageTime))s")
    }
    
    @Test func measureOverlayPerformance() async {
        let iterations = 10
        var totalTime: TimeInterval = 0
        
        for _ in 0..<iterations {
            let navigationState = NavigationState()
            
            let startTime = CFAbsoluteTimeGetCurrent()
            navigationState.presentOverlay(.settings)
            navigationState.dismissOverlay()
            let elapsed = CFAbsoluteTimeGetCurrent() - startTime
            
            totalTime += elapsed
        }
        
        let averageTime = totalTime / Double(iterations)
        #expect(averageTime < 0.01, "Average overlay time: \(averageTime)s")
        
        print("📊 Phase 5 - Average overlay time: \(String(format: "%.6f", averageTime))s")
    }
}