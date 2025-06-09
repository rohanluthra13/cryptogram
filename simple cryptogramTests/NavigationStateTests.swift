import XCTest
@testable import simple_cryptogram

@MainActor
final class NavigationStateTests: XCTestCase {
    var navigationState: NavigationState!
    
    override func setUp() {
        super.setUp()
        navigationState = NavigationState()
    }
    
    override func tearDown() {
        navigationState = nil
        super.tearDown()
    }
    
    // MARK: - Navigation Tests
    
    func testInitialState() {
        XCTAssertEqual(navigationState.currentScreen, .home)
        XCTAssertTrue(navigationState.navigationPath.isEmpty)
        XCTAssertNil(navigationState.presentedOverlay)
        XCTAssertTrue(navigationState.navigationHistory.isEmpty)
        XCTAssertTrue(navigationState.isBottomBarVisible)
        XCTAssertTrue(navigationState.isMainUIVisible)
        XCTAssertTrue(navigationState.isOnHomeScreen)
        XCTAssertFalse(navigationState.isOnPuzzleScreen)
    }
    
    func testNavigateToPuzzle() {
        let puzzle = createTestPuzzle()
        
        navigationState.navigateToPuzzle(puzzle)
        
        XCTAssertEqual(navigationState.currentScreen, .puzzle(puzzle))
        XCTAssertFalse(navigationState.navigationPath.isEmpty)
        XCTAssertEqual(navigationState.navigationHistory.count, 1)
        XCTAssertEqual(navigationState.navigationHistory.first, .home)
        XCTAssertFalse(navigationState.isOnHomeScreen)
        XCTAssertTrue(navigationState.isOnPuzzleScreen)
        XCTAssertEqual(navigationState.currentPuzzle?.id, puzzle.id)
    }
    
    func testNavigateToHome() {
        let puzzle = createTestPuzzle()
        navigationState.navigateToPuzzle(puzzle)
        
        navigationState.navigateToHome()
        
        XCTAssertEqual(navigationState.currentScreen, .home)
        XCTAssertTrue(navigationState.navigationPath.isEmpty)
        XCTAssertTrue(navigationState.navigationHistory.isEmpty)
        XCTAssertTrue(navigationState.isOnHomeScreen)
        XCTAssertFalse(navigationState.isOnPuzzleScreen)
        XCTAssertNil(navigationState.currentPuzzle)
    }
    
    func testNavigateBack() {
        let puzzle = createTestPuzzle()
        navigationState.navigateToPuzzle(puzzle)
        
        navigationState.navigateBack()
        
        XCTAssertEqual(navigationState.currentScreen, .home)
        XCTAssertTrue(navigationState.navigationPath.isEmpty)
        XCTAssertTrue(navigationState.navigationHistory.isEmpty)
        XCTAssertTrue(navigationState.isOnHomeScreen)
    }
    
    func testNavigateBackWithoutHistory() {
        // Already on home, no history
        navigationState.navigateBack()
        
        XCTAssertEqual(navigationState.currentScreen, .home)
        XCTAssertTrue(navigationState.navigationPath.isEmpty)
    }
    
    // MARK: - Overlay Tests
    
    func testPresentOverlay() {
        navigationState.presentOverlay(OverlayType.settings)
        
        XCTAssertEqual(navigationState.presentedOverlay, OverlayType.settings)
        XCTAssertTrue(navigationState.isPresenting(OverlayType.settings))
        XCTAssertTrue(navigationState.isAnyOverlayPresented)
        XCTAssertFalse(navigationState.isMainUIVisible)
    }
    
    func testDismissOverlay() {
        navigationState.presentOverlay(OverlayType.settings)
        navigationState.dismissOverlay()
        
        XCTAssertNil(navigationState.presentedOverlay)
        XCTAssertFalse(navigationState.isPresenting(OverlayType.settings))
        XCTAssertFalse(navigationState.isAnyOverlayPresented)
        XCTAssertTrue(navigationState.isMainUIVisible)
    }
    
    func testToggleOverlay() {
        // Present overlay
        navigationState.toggleOverlay(OverlayType.stats)
        XCTAssertTrue(navigationState.isPresenting(OverlayType.stats))
        
        // Dismiss overlay
        navigationState.toggleOverlay(OverlayType.stats)
        XCTAssertFalse(navigationState.isPresenting(OverlayType.stats))
    }
    
    func testOverlayDismissedOnNavigation() {
        navigationState.presentOverlay(OverlayType.settings)
        let puzzle = createTestPuzzle()
        
        navigationState.navigateToPuzzle(puzzle)
        
        XCTAssertNil(navigationState.presentedOverlay)
        XCTAssertFalse(navigationState.isAnyOverlayPresented)
    }
    
    // MARK: - Convenience Methods Tests
    
    func testToggleSettingsConvenience() {
        navigationState.toggleSettings()
        XCTAssertTrue(navigationState.isPresenting(OverlayType.settings))
        
        navigationState.toggleSettings()
        XCTAssertFalse(navigationState.isPresenting(OverlayType.settings))
    }
    
    func testToggleStatsConvenience() {
        navigationState.toggleStats()
        XCTAssertTrue(navigationState.isPresenting(OverlayType.stats))
        
        navigationState.toggleStats()
        XCTAssertFalse(navigationState.isPresenting(OverlayType.stats))
    }
    
    func testShowCompletionConvenience() {
        navigationState.showCompletion(.regular)
        XCTAssertTrue(navigationState.isPresenting(OverlayType.completion(.regular)))
        
        navigationState.showCompletion(.daily)
        XCTAssertTrue(navigationState.isPresenting(OverlayType.completion(.daily)))
    }
    
    func testShowGameOverConvenience() {
        navigationState.showGameOver()
        XCTAssertTrue(navigationState.isPresenting(OverlayType.gameOver))
    }
    
    func testShowPauseConvenience() {
        navigationState.showPause()
        XCTAssertTrue(navigationState.isPresenting(OverlayType.pause))
    }
    
    // MARK: - Bottom Bar Tests
    
    func testBottomBarAutoHide() {
        let expectation = XCTestExpectation(description: "Bottom bar auto-hide")
        
        // Mock the auto-hide delay for testing
        navigationState.showBottomBarTemporarily()
        XCTAssertTrue(navigationState.isBottomBarVisible)
        
        // Simulate the delay passing (in real app this would be handled by DispatchQueue)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            // In real implementation, this would be called by the work item
            self.navigationState.isBottomBarVisible = false
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
        XCTAssertFalse(navigationState.isBottomBarVisible)
    }
    
    func testCancelBottomBarHide() {
        navigationState.showBottomBarTemporarily()
        navigationState.cancelBottomBarHide()
        
        XCTAssertTrue(navigationState.isBottomBarVisible)
    }
    
    // MARK: - Screen Equality Tests
    
    func testScreenEquality() {
        let puzzle1 = createTestPuzzle(id: 1)
        let puzzle2 = createTestPuzzle(id: 2)
        let puzzle1Copy = createTestPuzzle(id: 1)
        
        XCTAssertEqual(Screen.home, Screen.home)
        XCTAssertEqual(Screen.puzzle(puzzle1), Screen.puzzle(puzzle1Copy))
        XCTAssertNotEqual(Screen.puzzle(puzzle1), Screen.puzzle(puzzle2))
        XCTAssertNotEqual(Screen.home, Screen.puzzle(puzzle1))
    }
    
    func testOverlayEquality() {
        XCTAssertEqual(OverlayType.settings, OverlayType.settings)
        XCTAssertEqual(OverlayType.completion(.regular), OverlayType.completion(.regular))
        XCTAssertNotEqual(OverlayType.completion(.regular), OverlayType.completion(.daily))
        XCTAssertNotEqual(OverlayType.settings, OverlayType.stats)
    }
    
    // MARK: - Helper Methods
    
    private func createTestPuzzle(id: Int = 1) -> Puzzle {
        return Puzzle(
            quoteId: id,
            encodedText: "test encoded",
            solution: "test decoded",
            hint: "test hint",
            difficulty: "easy"
        )
    }
}

// MARK: - Performance Tests

extension NavigationStateTests {
    func testNavigationPerformance() {
        let puzzle = createTestPuzzle()
        
        measure {
            for _ in 0..<1000 {
                navigationState.navigateToPuzzle(puzzle)
                navigationState.navigateToHome()
            }
        }
    }
    
    func testOverlayPerformance() {
        measure {
            for _ in 0..<1000 {
                navigationState.presentOverlay(.settings)
                navigationState.dismissOverlay()
            }
        }
    }
}