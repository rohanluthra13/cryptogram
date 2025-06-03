//
//  NavigationCoordinatorTests.swift
//  simple cryptogramTests
//
//  Created on 29/05/2025.
//

import XCTest
@testable import simple_cryptogram

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
    
    // MARK: - Initial State Tests
    
    func testInitialState() {
        XCTAssertEqual(coordinator.navigationPath.count, 0)
        XCTAssertFalse(coordinator.showPuzzle)
        XCTAssertNil(coordinator.currentPuzzle)
        XCTAssertNil(coordinator.selectedDifficulty)
    }
    
    // MARK: - Navigation Tests
    
    func testNavigateToPuzzle() {
        // Arrange
        let puzzle = Puzzle(
            id: UUID(),
            quoteId: 1,
            encodedText: "ABC",
            solution: "THE",
            hint: "Test hint",
            author: "Test Author",
            difficulty: "easy"
        )
        let difficulty = "easy"
        
        // Act
        coordinator.navigateToPuzzle(puzzle, difficulty: difficulty)
        
        // Assert
        XCTAssertTrue(coordinator.showPuzzle)
        XCTAssertEqual(coordinator.currentPuzzle?.quoteId, puzzle.quoteId)
        XCTAssertEqual(coordinator.selectedDifficulty, difficulty)
        XCTAssertEqual(coordinator.navigationPath.count, 1)
    }
    
    func testNavigateToPuzzleWithoutDifficulty() {
        // Arrange
        let puzzle = Puzzle(
            id: UUID(),
            quoteId: 2,
            encodedText: "XYZ",
            solution: "CAT",
            hint: "Another hint",
            author: "Another Author",
            difficulty: "medium"
        )
        
        // Act
        coordinator.navigateToPuzzle(puzzle)
        
        // Assert
        XCTAssertTrue(coordinator.showPuzzle)
        XCTAssertEqual(coordinator.currentPuzzle?.quoteId, puzzle.quoteId)
        XCTAssertNil(coordinator.selectedDifficulty)
        XCTAssertEqual(coordinator.navigationPath.count, 1)
    }
    
    func testNavigateToHome() {
        // Arrange - First navigate to a puzzle
        let puzzle = Puzzle(
            id: UUID(),
            quoteId: 3,
            encodedText: "DEF",
            solution: "DOG",
            hint: "Test",
            author: "Test",
            difficulty: "hard"
        )
        coordinator.navigateToPuzzle(puzzle, difficulty: "hard")
        
        // Act
        coordinator.navigateToHome()
        
        // Assert
        XCTAssertFalse(coordinator.showPuzzle)
        XCTAssertNil(coordinator.currentPuzzle)
        XCTAssertNil(coordinator.selectedDifficulty)
        XCTAssertEqual(coordinator.navigationPath.count, 0)
    }
    
    // MARK: - Navigation State Management Tests
    
    func testNavigationPathClearsOnHome() {
        // Arrange - Add multiple puzzles to path
        let puzzle1 = Puzzle(
            id: UUID(),
            quoteId: 1,
            encodedText: "ABC",
            solution: "THE",
            hint: "Test hint",
            author: "Test Author",
            difficulty: "easy"
        )
        let puzzle2 = Puzzle(
            id: UUID(),
            quoteId: 2,
            encodedText: "XYZ",
            solution: "CAT",
            hint: "Another hint",
            author: "Another Author",
            difficulty: "medium"
        )
        
        coordinator.navigateToPuzzle(puzzle1)
        coordinator.navigationPath.append(puzzle2)
        XCTAssertEqual(coordinator.navigationPath.count, 2)
        
        // Act
        coordinator.navigateToHome()
        
        // Assert
        XCTAssertEqual(coordinator.navigationPath.count, 0)
    }
    
    // MARK: - Multiple Navigation Tests
    
    func testMultipleNavigations() {
        // Arrange
        let puzzles = (1...3).map { quoteId in
            Puzzle(
                id: UUID(),
                quoteId: quoteId,
                encodedText: "TEST\(quoteId)",
                solution: "ORIG\(quoteId)",
                hint: "Hint \(quoteId)",
                author: "Author \(quoteId)",
                difficulty: "easy"
            )
        }
        
        // Act - Navigate to multiple puzzles
        for puzzle in puzzles {
            coordinator.navigateToPuzzle(puzzle)
        }
        
        // Assert
        XCTAssertEqual(coordinator.navigationPath.count, 3)
        XCTAssertEqual(coordinator.currentPuzzle?.quoteId, puzzles.last?.quoteId)
        
        // Act - Navigate home
        coordinator.navigateToHome()
        
        // Assert
        XCTAssertEqual(coordinator.navigationPath.count, 0)
        XCTAssertNil(coordinator.currentPuzzle)
    }
}