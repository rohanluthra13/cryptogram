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
        XCTAssertNil(coordinator.activeSheet)
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
    
    // MARK: - Sheet Presentation Tests
    
    func testPresentSheet() {
        // Test each sheet type
        let sheetTypes: [NavigationCoordinator.SheetType] = [
            .settings,
            .statistics,
            .calendar,
            .info
        ]
        
        for sheetType in sheetTypes {
            // Act
            coordinator.presentSheet(sheetType)
            
            // Assert
            XCTAssertNotNil(coordinator.activeSheet)
            XCTAssertTrue(coordinator.isSheetActive(sheetType))
            
            // Clean up for next iteration
            coordinator.dismissSheet()
        }
    }
    
    func testPresentAuthorInfoSheet() {
        // Arrange
        let author = Author(
            id: 1,
            name: "Test Author",
            fullName: "Test Full Author Name",
            birthDate: "1900",
            deathDate: "2000",
            placeOfBirth: "Test Birth Place",
            placeOfDeath: "Test Death Place",
            summary: "Test biography"
        )
        
        // Act
        coordinator.presentSheet(.authorInfo(author))
        
        // Assert
        XCTAssertNotNil(coordinator.activeSheet)
        XCTAssertTrue(coordinator.isSheetActive(.authorInfo(author)))
        
        // Test that different author is not active
        let differentAuthor = Author(
            id: 2,
            name: "Different Author",
            fullName: "Different Full Name",
            birthDate: "1800",
            deathDate: "1900",
            placeOfBirth: "Different Birth Place",
            placeOfDeath: "Different Death Place",
            summary: "Different bio"
        )
        XCTAssertFalse(coordinator.isSheetActive(.authorInfo(differentAuthor)))
    }
    
    func testDismissSheet() {
        // Arrange
        coordinator.presentSheet(.settings)
        
        // Act
        coordinator.dismissSheet()
        
        // Assert
        XCTAssertNil(coordinator.activeSheet)
        XCTAssertFalse(coordinator.isSheetActive(.settings))
    }
    
    func testIsSheetActiveWithNoActiveSheet() {
        // Assert
        XCTAssertFalse(coordinator.isSheetActive(.settings))
        XCTAssertFalse(coordinator.isSheetActive(.statistics))
        XCTAssertFalse(coordinator.isSheetActive(.calendar))
        XCTAssertFalse(coordinator.isSheetActive(.info))
    }
    
    func testSheetTypeIdentifiers() {
        // Test that each sheet type has a unique identifier
        XCTAssertEqual(NavigationCoordinator.SheetType.settings.id, "settings")
        XCTAssertEqual(NavigationCoordinator.SheetType.statistics.id, "statistics")
        XCTAssertEqual(NavigationCoordinator.SheetType.calendar.id, "calendar")
        XCTAssertEqual(NavigationCoordinator.SheetType.info.id, "info")
        
        let author = Author(
            id: 42,
            name: "Test",
            fullName: nil,
            birthDate: "1900",
            deathDate: "2000",
            placeOfBirth: nil,
            placeOfDeath: nil,
            summary: nil
        )
        XCTAssertEqual(NavigationCoordinator.SheetType.authorInfo(author).id, "author_42")
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