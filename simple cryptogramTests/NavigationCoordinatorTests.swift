import XCTest
@testable import simple_cryptogram

@MainActor
final class NavigationCoordinatorTests: XCTestCase {

    var coordinator: NavigationCoordinator!

    override func setUp() {
        super.setUp()
        coordinator = NavigationCoordinator()
    }

    override func tearDown() {
        coordinator = nil
        super.tearDown()
    }

    // MARK: - Initial State

    func testInitialState() {
        XCTAssertEqual(coordinator.navigationPath.count, 0)
    }

    // MARK: - Navigation

    func testNavigateToPuzzle() {
        let puzzle = Puzzle(
            quoteId: 1,
            encodedText: "ABC",
            solution: "THE",
            hint: "Test Author"
        )
        coordinator.navigateToPuzzle(puzzle)
        XCTAssertEqual(coordinator.navigationPath.count, 1)
    }

    func testNavigateToHome() {
        let puzzle = Puzzle(
            quoteId: 1,
            encodedText: "ABC",
            solution: "THE",
            hint: "Test Author"
        )
        coordinator.navigateToPuzzle(puzzle)
        XCTAssertEqual(coordinator.navigationPath.count, 1)

        coordinator.navigateToHome()
        XCTAssertEqual(coordinator.navigationPath.count, 0)
    }

    func testNavigateBack() {
        let puzzle1 = Puzzle(quoteId: 1, encodedText: "ABC", solution: "THE", hint: "A1")
        let puzzle2 = Puzzle(quoteId: 2, encodedText: "DEF", solution: "DOG", hint: "A2")

        coordinator.navigateToPuzzle(puzzle1)
        coordinator.navigateToPuzzle(puzzle2)
        XCTAssertEqual(coordinator.navigationPath.count, 2)

        coordinator.navigateBack()
        XCTAssertEqual(coordinator.navigationPath.count, 1)

        coordinator.navigateBack()
        XCTAssertEqual(coordinator.navigationPath.count, 0)
    }

    func testNavigateBackWhenEmpty() {
        coordinator.navigateBack()
        XCTAssertEqual(coordinator.navigationPath.count, 0)
    }
}
