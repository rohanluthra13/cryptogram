//
//  MemoryLeakDetectionTestsSimple.swift
//  simple cryptogramTests
//
//  Created on 30/05/2025.
//

import Testing
@preconcurrency import Foundation
import Combine
@testable import simple_cryptogram

/// Simplified memory leak detection tests
@MainActor
struct MemoryLeakDetectionTestsSimple {
    
    @Test func basicMemoryTest() async throws {
        // Simple test to ensure tests can run
        let puzzle = Puzzle(
            id: UUID(),
            quoteId: 1,
            encodedText: "TEST",
            solution: "TEST",
            hint: "Test Author",
            author: "Test Author",
            difficulty: "easy",
            length: 4
        )
        
        #expect(puzzle.encodedText == "TEST")
    }
    
    @Test func gameStateManagerBasicTest() async throws {
        weak var weakGameState: GameStateManager?
        
        do {
            let databaseService = DatabaseService.shared
            let gameState = GameStateManager(databaseService: databaseService)
            weakGameState = gameState
            
            // Create test puzzle
            let puzzle = Puzzle(
                id: UUID(),
                quoteId: 1,
                encodedText: "ABC",
                solution: "ABC",
                hint: "Test",
                author: "Test",
                difficulty: "easy",
                length: 3
            )
            
            gameState.startNewPuzzle(puzzle)
        }
        
        await Task.yield()
        
        #expect(weakGameState == nil, "GameStateManager should be deallocated")
    }
    
    @Test func themeManagerBasicTest() async throws {
        weak var weakThemeManager: ThemeManager?
        
        do {
            let themeManager = ThemeManager()
            weakThemeManager = themeManager
            
            // Basic usage
            themeManager.applyTheme()
        }
        
        await Task.yield()
        
        #expect(weakThemeManager == nil, "ThemeManager should be deallocated")
    }
}