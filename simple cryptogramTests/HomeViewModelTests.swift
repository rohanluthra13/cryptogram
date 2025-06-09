import XCTest
@testable import simple_cryptogram

@MainActor
final class HomeViewModelTests: XCTestCase {
    var homeViewModel: HomeViewModel!
    var mockPuzzleSelectionManager: MockPuzzleSelectionManager!
    var mockDailyPuzzleManager: MockDailyPuzzleManager!
    var mockDatabaseService: MockDatabaseService!
    
    override func setUp() {
        super.setUp()
        mockDatabaseService = MockDatabaseService()
        mockPuzzleSelectionManager = MockPuzzleSelectionManager()
        mockDailyPuzzleManager = MockDailyPuzzleManager()
        
        homeViewModel = HomeViewModel(
            puzzleSelectionManager: mockPuzzleSelectionManager,
            dailyPuzzleManager: mockDailyPuzzleManager,
            databaseService: mockDatabaseService
        )
    }
    
    override func tearDown() {
        homeViewModel = nil
        mockPuzzleSelectionManager = nil
        mockDailyPuzzleManager = nil
        mockDatabaseService = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testInitialState() {
        XCTAssertEqual(homeViewModel.selectedMode, .random)
        XCTAssertFalse(homeViewModel.showLengthSelection)
        XCTAssertFalse(homeViewModel.isLoadingPuzzle)
        XCTAssertNil(homeViewModel.currentError)
    }
    
    // MARK: - Mode Selection Tests
    
    func testSelectRandomMode() {
        homeViewModel.selectMode(.random)
        
        XCTAssertEqual(homeViewModel.selectedMode, .random)
        XCTAssertTrue(homeViewModel.showLengthSelection)
    }
    
    func testSelectDailyMode() {
        homeViewModel.selectMode(.daily)
        
        XCTAssertEqual(homeViewModel.selectedMode, .daily)
        XCTAssertFalse(homeViewModel.showLengthSelection)
    }
    
    // MARK: - Puzzle Loading Tests
    
    func testLoadRandomPuzzleSuccess() async {
        let expectedPuzzle = createTestPuzzle()
        mockPuzzleSelectionManager.mockPuzzle = expectedPuzzle
        
        let result = await homeViewModel.loadRandomPuzzle()
        
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.id, expectedPuzzle.id)
        XCTAssertFalse(homeViewModel.isLoadingPuzzle)
        XCTAssertNil(homeViewModel.currentError)
        XCTAssertFalse(mockPuzzleSelectionManager.excludeCompleted)
    }
    
    func testLoadRandomPuzzleFailure() async {
        mockPuzzleSelectionManager.shouldThrowError = true
        
        let result = await homeViewModel.loadRandomPuzzle()
        
        XCTAssertNil(result)
        XCTAssertFalse(homeViewModel.isLoadingPuzzle)
        XCTAssertNotNil(homeViewModel.currentError)
    }
    
    func testLoadPuzzleWithExclusionsSuccess() async {
        let expectedPuzzle = createTestPuzzle()
        mockPuzzleSelectionManager.mockPuzzle = expectedPuzzle
        
        let result = await homeViewModel.loadPuzzleWithExclusions()
        
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.id, expectedPuzzle.id)
        XCTAssertFalse(homeViewModel.isLoadingPuzzle)
        XCTAssertNil(homeViewModel.currentError)
        XCTAssertTrue(mockPuzzleSelectionManager.excludeCompleted)
    }
    
    func testLoadPuzzleWithExclusionsFailure() async {
        mockPuzzleSelectionManager.shouldThrowError = true
        
        let result = await homeViewModel.loadPuzzleWithExclusions()
        
        XCTAssertNil(result)
        XCTAssertFalse(homeViewModel.isLoadingPuzzle)
        XCTAssertNotNil(homeViewModel.currentError)
    }
    
    func testLoadTodaysDailyPuzzle() async {
        let expectedPuzzle = createTestPuzzle()
        let expectedProgress = DailyPuzzleProgress(date: Date(), cellStates: [:], sessionData: PuzzleSession())
        mockDailyPuzzleManager.mockResult = (expectedPuzzle, expectedProgress)
        
        let result = await homeViewModel.loadTodaysDailyPuzzle()
        
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.puzzle.id, expectedPuzzle.id)
        XCTAssertNotNil(result?.progress)
        XCTAssertFalse(homeViewModel.isLoadingPuzzle)
        XCTAssertNil(homeViewModel.currentError)
    }
    
    func testLoadDailyPuzzleForDate() async {
        let testDate = Date()
        let expectedPuzzle = createTestPuzzle()
        mockDailyPuzzleManager.mockResult = (expectedPuzzle, nil)
        
        let result = await homeViewModel.loadDailyPuzzle(for: testDate)
        
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.puzzle.id, expectedPuzzle.id)
        XCTAssertNil(result?.progress)
        XCTAssertEqual(mockDailyPuzzleManager.requestedDate, testDate)
    }
    
    func testLoadDailyPuzzleFailure() async {
        mockDailyPuzzleManager.shouldThrowError = true
        
        let result = await homeViewModel.loadDailyPuzzle(for: Date())
        
        XCTAssertNil(result)
        XCTAssertFalse(homeViewModel.isLoadingPuzzle)
        XCTAssertNotNil(homeViewModel.currentError)
    }
    
    // MARK: - Loading State Tests
    
    func testLoadingStateManagement() async {
        // Use a custom expectation to test loading state during async operation
        let expectation = XCTestExpectation(description: "Loading state management")
        
        mockPuzzleSelectionManager.delayResponse = true
        
        // Start the async operation
        let loadingTask = Task {
            await homeViewModel.loadRandomPuzzle()
        }
        
        // Check loading state is set immediately
        DispatchQueue.main.async {
            XCTAssertTrue(self.homeViewModel.isLoadingPuzzle)
            expectation.fulfill()
        }
        
        await fulfillment(of: [expectation], timeout: 1.0)
        
        // Complete the loading
        mockPuzzleSelectionManager.completeDelayedResponse()
        await loadingTask.value
        
        // Verify loading state is cleared
        XCTAssertFalse(homeViewModel.isLoadingPuzzle)
    }
    
    // MARK: - Daily Puzzle Completion Tests
    
    func testIsDailyPuzzleCompleted() {
        mockDailyPuzzleManager.isTodaysCompleted = true
        
        XCTAssertTrue(homeViewModel.isDailyPuzzleCompleted)
        
        mockDailyPuzzleManager.isTodaysCompleted = false
        
        XCTAssertFalse(homeViewModel.isDailyPuzzleCompleted)
    }
    
    // MARK: - View State Management Tests
    
    func testResetViewState() {
        homeViewModel.selectMode(.daily)
        homeViewModel.showLengthSelection = true
        
        homeViewModel.resetViewState()
        
        XCTAssertEqual(homeViewModel.selectedMode, .random)
        XCTAssertFalse(homeViewModel.showLengthSelection)
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

// MARK: - Mock Classes

class MockPuzzleSelectionManager: PuzzleSelectionManager {
    var mockPuzzle: Puzzle?
    var shouldThrowError = false
    var excludeCompleted = false
    var delayResponse = false
    private var delayedCompletion: (() -> Void)?
    
    override func loadRandomPuzzle(
        encodingType: String,
        difficulties: [String],
        excludeCompleted: Bool
    ) async throws -> Puzzle {
        self.excludeCompleted = excludeCompleted
        
        if delayResponse {
            await withCheckedContinuation { continuation in
                delayedCompletion = {
                    continuation.resume()
                }
            }
        }
        
        if shouldThrowError {
            throw DatabaseError.connectionFailed
        }
        
        guard let puzzle = mockPuzzle else {
            throw DatabaseError.connectionFailed
        }
        
        return puzzle
    }
    
    func completeDelayedResponse() {
        delayedCompletion?()
        delayedCompletion = nil
    }
}

class MockDailyPuzzleManager: DailyPuzzleManager {
    var mockResult: (Puzzle, DailyPuzzleProgress?)?
    var shouldThrowError = false
    var isTodaysCompleted = false
    var requestedDate: Date?
    
    override func loadDailyPuzzle(for date: Date) throws -> (Puzzle, DailyPuzzleProgress?) {
        requestedDate = date
        
        if shouldThrowError {
            throw DatabaseError.connectionFailed
        }
        
        guard let result = mockResult else {
            throw DatabaseError.connectionFailed
        }
        
        return result
    }
    
    override func isTodaysDailyPuzzleCompleted() -> Bool {
        return isTodaysCompleted
    }
}

class MockDatabaseService: DatabaseService {
    var shouldThrowError = false
    
    override init() {
        // Skip the real initialization
    }
}

// MARK: - Performance Tests

extension HomeViewModelTests {
    func testPuzzleLoadingPerformance() {
        let puzzle = createTestPuzzle()
        mockPuzzleSelectionManager.mockPuzzle = puzzle
        
        measure {
            Task {
                for _ in 0..<100 {
                    _ = await homeViewModel.loadRandomPuzzle()
                }
            }
        }
    }
}