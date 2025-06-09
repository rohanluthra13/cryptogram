import XCTest
import SwiftUI
@testable import simple_cryptogram

@MainActor
class OverlayManagerTests: XCTestCase {
    
    var puzzleViewState: PuzzleViewState!
    
    override func setUp() {
        super.setUp()
        puzzleViewState = PuzzleViewState()
    }
    
    override func tearDown() {
        puzzleViewState = nil
        super.tearDown()
    }
    
    // MARK: - PuzzleViewState Overlay Tests
    
    func testInitialOverlayStates() {
        // Test that all overlays start in closed state
        XCTAssertFalse(puzzleViewState.showSettings)
        XCTAssertFalse(puzzleViewState.showStatsOverlay)
        XCTAssertFalse(puzzleViewState.showInfoOverlay)
        XCTAssertFalse(puzzleViewState.showCalendar)
        XCTAssertEqual(puzzleViewState.completionState, .none)
    }
    
    func testSettingsToggle() {
        // Test settings overlay toggle
        puzzleViewState.toggleSettings()
        XCTAssertTrue(puzzleViewState.showSettings)
        XCTAssertFalse(puzzleViewState.showStatsOverlay) // Should close other overlays
        
        puzzleViewState.toggleSettings()
        XCTAssertFalse(puzzleViewState.showSettings)
    }
    
    func testStatsToggle() {
        // Test stats overlay toggle
        puzzleViewState.toggleStats()
        XCTAssertTrue(puzzleViewState.showStatsOverlay)
        XCTAssertFalse(puzzleViewState.showSettings) // Should close other overlays
        
        puzzleViewState.toggleStats()
        XCTAssertFalse(puzzleViewState.showStatsOverlay)
    }
    
    func testMutualExclusiveOverlays() {
        // Test that settings and stats overlays are mutually exclusive
        puzzleViewState.showSettings = true
        puzzleViewState.toggleStats()
        
        XCTAssertTrue(puzzleViewState.showStatsOverlay)
        XCTAssertFalse(puzzleViewState.showSettings)
        
        puzzleViewState.toggleSettings()
        XCTAssertTrue(puzzleViewState.showSettings)
        XCTAssertFalse(puzzleViewState.showStatsOverlay)
    }
    
    func testCloseAllOverlays() {
        // Test that closeAllOverlays closes everything
        puzzleViewState.showSettings = true
        puzzleViewState.showStatsOverlay = true
        puzzleViewState.showInfoOverlay = true
        puzzleViewState.showCalendar = true
        puzzleViewState.completionState = .regular
        
        puzzleViewState.closeAllOverlays()
        
        XCTAssertFalse(puzzleViewState.showSettings)
        XCTAssertFalse(puzzleViewState.showStatsOverlay)
        XCTAssertFalse(puzzleViewState.showInfoOverlay)
        XCTAssertFalse(puzzleViewState.showCalendar)
        XCTAssertEqual(puzzleViewState.completionState, .none)
    }
    
    func testCompletionStateLegacyCompatibility() {
        // Test backward compatibility properties
        puzzleViewState.completionState = .regular
        XCTAssertTrue(puzzleViewState.showCompletionView)
        XCTAssertFalse(puzzleViewState.showDailyCompletionView)
        
        puzzleViewState.completionState = .daily
        XCTAssertFalse(puzzleViewState.showCompletionView)
        XCTAssertTrue(puzzleViewState.showDailyCompletionView)
        
        puzzleViewState.showCompletionView = true
        XCTAssertEqual(puzzleViewState.completionState, .regular)
        
        puzzleViewState.showDailyCompletionView = true
        XCTAssertEqual(puzzleViewState.completionState, .daily)
    }
    
    func testMainUIVisibility() {
        // Test main UI visibility logic
        XCTAssertTrue(puzzleViewState.isMainUIVisible)
        
        puzzleViewState.showSettings = true
        XCTAssertFalse(puzzleViewState.isMainUIVisible)
        
        puzzleViewState.showSettings = false
        puzzleViewState.showStatsOverlay = true
        XCTAssertFalse(puzzleViewState.isMainUIVisible)
        
        puzzleViewState.showStatsOverlay = false
        puzzleViewState.showCalendar = true
        XCTAssertFalse(puzzleViewState.isMainUIVisible)
        
        puzzleViewState.showCalendar = false
        puzzleViewState.completionState = .regular
        XCTAssertFalse(puzzleViewState.isMainUIVisible)
    }
    
    func testAnyOverlayVisible() {
        // Test any overlay visible logic
        XCTAssertFalse(puzzleViewState.isAnyOverlayVisible)
        
        puzzleViewState.showInfoOverlay = true
        XCTAssertTrue(puzzleViewState.isAnyOverlayVisible)
        
        puzzleViewState.showInfoOverlay = false
        puzzleViewState.completionState = .daily
        XCTAssertTrue(puzzleViewState.isAnyOverlayVisible)
    }
    
    // MARK: - UnifiedOverlayManager Tests
    
    func testUnifiedOverlayManagerPresentation() {
        let overlayManager = UnifiedOverlayManager()
        
        // Test initial state
        XCTAssertNil(overlayManager.activeOverlay)
        XCTAssertTrue(overlayManager.overlayQueue.isEmpty)
        
        // Test presentation
        overlayManager.present(.settings)
        XCTAssertEqual(overlayManager.activeOverlay, .settings)
        XCTAssertTrue(overlayManager.isPresenting(.settings))
        
        // Test dismissal
        let expectation = XCTestExpectation(description: "Overlay dismissed")
        overlayManager.dismiss {
            expectation.fulfill()
        }
        XCTAssertNil(overlayManager.activeOverlay)
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testOverlayTypeEquality() {
        // Test OverlayType equality
        XCTAssertEqual(OverlayType.settings, OverlayType.settings)
        XCTAssertEqual(OverlayType.completion(.regular), OverlayType.completion(.regular))
        XCTAssertNotEqual(OverlayType.completion(.regular), OverlayType.completion(.daily))
        XCTAssertNotEqual(OverlayType.settings, OverlayType.stats)
    }
    
    func testOverlayZIndex() {
        // Test z-index hierarchy
        XCTAssertEqual(OverlayType.info.zIndex, OverlayZIndex.info)
        XCTAssertEqual(OverlayType.settings.zIndex, OverlayZIndex.statsSettings)
        XCTAssertEqual(OverlayType.completion(.regular).zIndex, OverlayZIndex.completion)
        XCTAssertEqual(OverlayType.completion(.daily).zIndex, OverlayZIndex.dailyCompletion)
        
        // Test hierarchy ordering
        XCTAssertLessThan(OverlayType.info.zIndex, OverlayType.settings.zIndex)
        XCTAssertLessThan(OverlayType.settings.zIndex, OverlayType.completion(.regular).zIndex)
    }
    
    // MARK: - Performance Tests
    
    func testOverlayStateChangePerformance() {
        measure {
            for _ in 0..<1000 {
                puzzleViewState.toggleSettings()
                puzzleViewState.toggleStats()
                puzzleViewState.closeAllOverlays()
            }
        }
    }
}

// MARK: - Test Helper Extensions

extension OverlayManagerTests {
    
    func assertAllOverlaysClosed(_ puzzleViewState: PuzzleViewState, file: StaticString = #file, line: UInt = #line) {
        XCTAssertFalse(puzzleViewState.showSettings, "Settings overlay should be closed", file: file, line: line)
        XCTAssertFalse(puzzleViewState.showStatsOverlay, "Stats overlay should be closed", file: file, line: line)
        XCTAssertFalse(puzzleViewState.showInfoOverlay, "Info overlay should be closed", file: file, line: line)
        XCTAssertFalse(puzzleViewState.showCalendar, "Calendar overlay should be closed", file: file, line: line)
        XCTAssertEqual(puzzleViewState.completionState, .none, "Completion state should be none", file: file, line: line)
    }
}