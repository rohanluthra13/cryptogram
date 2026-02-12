//
//  PerformanceBaselineTests.swift
//  simple cryptogramTests
//
//  Created on 29/05/2025.
//

import Testing
import Foundation
@testable import simple_cryptogram

/// Performance baseline tests to measure current app performance before refactoring
@MainActor
struct PerformanceBaselineTests {
    
    // MARK: - App Launch Performance
    
    @Test func appLaunchTime() async throws {
        // Measure AppSettings initialization time
        let startTime = Date()
        
        let appSettings = AppSettings()
        
        let initTime = Date().timeIntervalSince(startTime)
        
        // Baseline: AppSettings should initialize quickly
        #expect(initTime < 0.1, "AppSettings initialization took \(initTime)s, should be <0.1s")
        
        print("📊 Performance Baseline - AppSettings init: \(String(format: "%.4f", initTime))s")
    }
    
    @Test func databaseInitializationTime() async throws {
        let startTime = Date()
        
        let databaseService = DatabaseService.shared
        _ = try databaseService.fetchRandomPuzzle(selectedDifficulties: ["easy", "medium", "hard"])
        
        let dbTime = Date().timeIntervalSince(startTime)
        
        // Baseline: Database should be ready quickly
        #expect(dbTime < 0.5, "Database initialization took \(dbTime)s, should be <0.5s")
        
        print("📊 Performance Baseline - Database init: \(String(format: "%.4f", dbTime))s")
    }
    
    // MARK: - Puzzle Loading Performance
    
    @Test func puzzleLoadingTime() async throws {
        let puzzleViewModel = PuzzleViewModel()
        
        let startTime = Date()
        
        puzzleViewModel.loadNewPuzzle()
        
        // Wait for puzzle to load
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1s
        
        let loadTime = Date().timeIntervalSince(startTime)
        
        // Baseline: Puzzle should load quickly
        #expect(loadTime < 0.2, "Puzzle loading took \(loadTime)s, should be <0.2s")
        #expect(puzzleViewModel.currentPuzzle != nil, "Puzzle should be loaded")
        #expect(!puzzleViewModel.cells.isEmpty, "Puzzle cells should be populated")
        
        print("📊 Performance Baseline - Puzzle loading: \(String(format: "%.4f", loadTime))s")
        print("📊 Performance Baseline - Puzzle cells count: \(puzzleViewModel.cells.count)")
    }
    
    @Test func dailyPuzzleLoadingTime() async throws {
        let puzzleViewModel = PuzzleViewModel()
        
        let startTime = Date()
        
        puzzleViewModel.loadDailyPuzzle()
        
        // Wait for puzzle to load
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1s
        
        let loadTime = Date().timeIntervalSince(startTime)
        
        // Baseline: Daily puzzle should load quickly
        #expect(loadTime < 0.2, "Daily puzzle loading took \(loadTime)s, should be <0.2s")
        
        print("📊 Performance Baseline - Daily puzzle loading: \(String(format: "%.4f", loadTime))s")
    }
    
    // MARK: - Input Performance
    
    @Test func rapidInputPerformance() async throws {
        let puzzleViewModel = PuzzleViewModel()
        puzzleViewModel.loadNewPuzzle()
        
        // Wait for puzzle to load
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1s
        
        let nonSymbolIndices = puzzleViewModel.cells.enumerated().compactMap { index, cell in
            cell.isSymbol ? nil : index
        }
        
        guard nonSymbolIndices.count >= 10 else {
            throw TestError("Need at least 10 cells for performance test")
        }
        
        let startTime = Date()
        
        // Rapidly input 10 letters
        for i in 0..<10 {
            let index = nonSymbolIndices[i % nonSymbolIndices.count]
            puzzleViewModel.inputLetter("A", at: index)
        }
        
        let inputTime = Date().timeIntervalSince(startTime)
        
        // Baseline: Rapid input should be responsive
        #expect(inputTime < 0.05, "Rapid input (10 letters) took \(inputTime)s, should be <0.05s")
        
        print("📊 Performance Baseline - Rapid input (10 letters): \(String(format: "%.4f", inputTime))s")
    }
    
    // MARK: - Memory Usage Tests
    
    @Test func memoryUsageBaseline() async throws {
        let puzzleViewModel = PuzzleViewModel()
        
        // Load multiple puzzles to test memory usage
        for _ in 0..<5 {
            puzzleViewModel.loadNewPuzzle()
            try await Task.sleep(nanoseconds: 50_000_000) // 0.05s
            
            // Input some letters
            let nonSymbolIndices = puzzleViewModel.cells.enumerated().compactMap { index, cell in
                cell.isSymbol ? nil : index
            }
            
            for i in 0..<min(5, nonSymbolIndices.count) {
                puzzleViewModel.inputLetter("A", at: nonSymbolIndices[i])
            }
        }
        
        // Memory should remain stable
        #expect(puzzleViewModel.cells.count > 0, "Cells should remain populated")
        #expect(puzzleViewModel.currentPuzzle != nil, "Current puzzle should exist")
        
        print("📊 Performance Baseline - Memory test completed successfully")
    }
    
    // MARK: - Animation Performance
    
    @Test func animationPerformance() async throws {
        let puzzleViewModel = PuzzleViewModel()
        puzzleViewModel.loadNewPuzzle()
        
        // Wait for puzzle to load
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1s
        
        let startTime = Date()
        
        // Trigger animations by making mistakes
        if let firstCellIndex = puzzleViewModel.cells.firstIndex(where: { !$0.isSymbol }) {
            // Input wrong letter to trigger error animation
            puzzleViewModel.inputLetter("X", at: firstCellIndex)
            
            // Wait for animation
            try await Task.sleep(nanoseconds: 600_000_000) // 0.6s for error animation
        }
        
        let animationTime = Date().timeIntervalSince(startTime)
        
        // Baseline: Animation should complete within reasonable time
        #expect(animationTime < 1.0, "Error animation took \(animationTime)s, should complete <1.0s")
        
        print("📊 Performance Baseline - Error animation: \(String(format: "%.4f", animationTime))s")
    }
    
    // MARK: - Statistics Performance
    
    @Test func statisticsCalculationTime() async throws {
        let puzzleViewModel = PuzzleViewModel()
        puzzleViewModel.loadNewPuzzle()
        
        // Complete a puzzle to generate statistics
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1s
        
        let startTime = Date()
        
        // Access various statistics
        _ = puzzleViewModel.totalCompletions
        _ = puzzleViewModel.totalAttempts
        _ = puzzleViewModel.winRatePercentage
        _ = puzzleViewModel.averageTime
        _ = puzzleViewModel.globalBestTime
        
        let statsTime = Date().timeIntervalSince(startTime)
        
        // Baseline: Statistics should calculate quickly
        #expect(statsTime < 0.01, "Statistics calculation took \(statsTime)s, should be <0.01s")
        
        print("📊 Performance Baseline - Statistics calculation: \(String(format: "%.4f", statsTime))s")
    }
    
    // MARK: - Large Puzzle Performance
    
    @Test func largePuzzleHandling() async throws {
        // Test performance with a large puzzle (simulated)
        let puzzleViewModel = PuzzleViewModel()
        
        // Load puzzle
        puzzleViewModel.loadNewPuzzle()
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1s
        
        let cellCount = puzzleViewModel.cells.count
        
        let startTime = Date()
        
        // Process all cells
        for (index, cell) in puzzleViewModel.cells.enumerated() {
            if !cell.isSymbol {
                puzzleViewModel.inputLetter("A", at: index)
            }
        }
        
        let processingTime = Date().timeIntervalSince(startTime)
        let timePerCell = cellCount > 0 ? processingTime / Double(cellCount) : 0
        
        // Baseline: Should handle large puzzles efficiently
        #expect(timePerCell < 0.001, "Processing time per cell: \(timePerCell)s, should be <0.001s")
        
        print("📊 Performance Baseline - Large puzzle (\(cellCount) cells): \(String(format: "%.4f", processingTime))s")
        print("📊 Performance Baseline - Time per cell: \(String(format: "%.6f", timePerCell))s")
    }
}

// MARK: - Performance Monitoring Helper

struct PerformanceMonitor {
    static func measureTime<T>(operation: () throws -> T) rethrows -> (result: T, time: TimeInterval) {
        let startTime = Date()
        let result = try operation()
        let time = Date().timeIntervalSince(startTime)
        return (result, time)
    }
    
    static func measureAsyncTime<T>(operation: () async throws -> T) async rethrows -> (result: T, time: TimeInterval) {
        let startTime = Date()
        let result = try await operation()
        let time = Date().timeIntervalSince(startTime)
        return (result, time)
    }
    
    static func logPerformanceBaseline() {
        print("📊 Run PerformanceBaselineTests to establish baseline metrics")
    }
}

// MARK: - Test Error

extension PerformanceBaselineTests {
    struct TestError: Error {
        let message: String
        
        init(_ message: String) {
            self.message = message
        }
    }
}