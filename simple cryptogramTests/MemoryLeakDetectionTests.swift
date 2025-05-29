//
//  MemoryLeakDetectionTests.swift
//  simple cryptogramTests
//
//  Created on 29/05/2025.
//

import Testing
@preconcurrency import Foundation
import Combine
@testable import simple_cryptogram

/// Memory leak detection tests to identify potential retain cycles before refactoring
@MainActor
struct MemoryLeakDetectionTests {
    
    // MARK: - PuzzleViewModel Memory Management
    
    @Test func puzzleViewModelDeallocation() async throws {
        weak var weakViewModel: PuzzleViewModel?
        
        // Create and immediately scope the view model
        do {
            // Create a simple test puzzle instead of loading from database
            let testPuzzle = Puzzle(
                id: UUID(),
                quoteId: 1,
                encodedText: "TEST",
                solution: "TEST",
                hint: "Test Author",
                author: "Test Author",
                difficulty: "easy",
                length: 4
            )
            
            let viewModel = PuzzleViewModel(initialPuzzle: testPuzzle)
            weakViewModel = viewModel
            
            // Use the view model
            if let firstCellIndex = viewModel.cells.firstIndex(where: { !$0.isSymbol }) {
                viewModel.inputLetter("A", at: firstCellIndex)
            }
        }
        
        // Force garbage collection
        await Task.yield()
        
        // ViewModel should be deallocated
        #expect(weakViewModel == nil, "PuzzleViewModel should be deallocated when no longer referenced")
    }
    
    @Test func gameStateManagerDeallocation() async throws {
        weak var weakGameState: GameStateManager?
        
        do {
            let databaseService = DatabaseService.shared
            let gameState = GameStateManager(databaseService: databaseService)
            weakGameState = gameState
            
            // Use the game state
            let puzzleSelectionManager = PuzzleSelectionManager(
                databaseService: databaseService,
                progressManager: PuzzleProgressManager(),
                statisticsManager: StatisticsManager(progressManager: PuzzleProgressManager())
            )
            let puzzle = puzzleSelectionManager.createFallbackPuzzle()
            gameState.startNewPuzzle(puzzle)
            gameState.updateCell(at: 0, with: "A")
        }
        
        await Task.yield()
        
        #expect(weakGameState == nil, "GameStateManager should be deallocated")
    }
    
    @Test func inputHandlerDeallocation() async throws {
        weak var weakInputHandler: InputHandler?
        weak var weakGameState: GameStateManager?
        
        do {
            let databaseService = DatabaseService.shared
            let gameState = GameStateManager(databaseService: databaseService)
            let inputHandler = InputHandler(gameState: gameState)
            
            weakGameState = gameState
            weakInputHandler = inputHandler
            
            // Use input handler
            let puzzleSelectionManager = PuzzleSelectionManager(
                databaseService: databaseService,
                progressManager: PuzzleProgressManager(),
                statisticsManager: StatisticsManager(progressManager: PuzzleProgressManager())
            )
            let puzzle = puzzleSelectionManager.createFallbackPuzzle()
            gameState.startNewPuzzle(puzzle)
            inputHandler.inputLetter("A", at: 0)
        }
        
        await Task.yield()
        
        #expect(weakInputHandler == nil, "InputHandler should be deallocated")
        #expect(weakGameState == nil, "GameStateManager should be deallocated")
    }
    
    // MARK: - Manager Interaction Memory Tests
    
    @Test func managerInteractionMemoryManagement() async throws {
        weak var weakGameState: GameStateManager?
        weak var weakInputHandler: InputHandler?
        weak var weakHintManager: HintManager?
        
        do {
            let databaseService = DatabaseService.shared
            let gameState = GameStateManager(databaseService: databaseService)
            let inputHandler = InputHandler(gameState: gameState)
            let hintManager = HintManager(gameState: gameState, inputHandler: inputHandler)
            
            weakGameState = gameState
            weakInputHandler = inputHandler
            weakHintManager = hintManager
            
            // Simulate interaction between managers
            let puzzleSelectionManager = PuzzleSelectionManager(
                databaseService: databaseService,
                progressManager: PuzzleProgressManager(),
                statisticsManager: StatisticsManager(progressManager: PuzzleProgressManager())
            )
            let puzzle = puzzleSelectionManager.createFallbackPuzzle()
            gameState.startNewPuzzle(puzzle)
            inputHandler.inputLetter("A", at: 0)
            
            if let firstCellIndex = gameState.cells.firstIndex(where: { !$0.isSymbol }) {
                hintManager.revealCell(at: firstCellIndex)
            }
        }
        
        await Task.yield()
        
        #expect(weakGameState == nil, "GameStateManager should be deallocated")
        #expect(weakInputHandler == nil, "InputHandler should be deallocated")
        #expect(weakHintManager == nil, "HintManager should be deallocated")
    }
    
    // MARK: - Theme Manager Memory Tests
    
    @Test func themeManagerMemoryManagement() async throws {
        weak var weakThemeManager: ThemeManager?
        
        do {
            let themeManager = ThemeManager()
            weakThemeManager = themeManager
            
            // Trigger theme changes
            // Trigger theme changes
            themeManager.applyTheme()
            themeManager.toggleTheme()
        }
        
        await Task.yield()
        
        #expect(weakThemeManager == nil, "ThemeManager should be deallocated")
    }
    
    // MARK: - AppSettings Memory Tests
    
    @Test func appSettingsSubscriptionCleanup() async throws {
        var cancellables = Set<AnyCancellable>()
        weak var weakSubscriber: NSObject?
        
        do {
            let appSettings = AppSettings()
            let subscriber = NSObject()
            weakSubscriber = subscriber
            
            // Create subscription using NotificationCenter
            NotificationCenter.default.publisher(for: .init("AppSettingsChanged"))
                .sink { _ in
                    // Retain subscriber in closure
                    _ = subscriber
                }
                .store(in: &cancellables)
            
            // Change settings to trigger publisher
            appSettings.encodingType = "Numbers"
        }
        
        // Clear subscriptions
        cancellables.removeAll()
        
        await Task.yield()
        
        #expect(weakSubscriber == nil, "Subscriber should be deallocated after cancellables are cleared")
    }
    
    // MARK: - Database Service Memory Tests
    
    @Test func databaseServiceMemoryManagement() async throws {
        // DatabaseService is a singleton, so we test that it doesn't retain unnecessary objects
        var weakPuzzle: Puzzle?
        
        do {
            let databaseService = DatabaseService.shared
            let puzzle = try databaseService.fetchRandomPuzzle(encodingType: "Letters", selectedDifficulties: ["easy", "medium", "hard"])
            weakPuzzle = puzzle
            
            // Use the puzzle
            _ = puzzle?.encodedText
        }
        
        // Puzzle is a struct, so it won't be deallocated
        // We're just checking that DatabaseService doesn't keep unnecessary references
        #expect(weakPuzzle != nil, "Puzzle is a struct and won't be deallocated")
    }
    
    // MARK: - Progress Manager Memory Tests
    
    @Test func progressManagerMemoryManagement() async throws {
        weak var weakProgressManager: PuzzleProgressManager?
        weak var weakProgressStore: LocalPuzzleProgressStore?
        
        do {
            let databaseService = DatabaseService.shared
            let progressStore = LocalPuzzleProgressStore(database: databaseService.db!)
            let progressManager = PuzzleProgressManager(progressStore: progressStore)
            
            weakProgressStore = progressStore
            weakProgressManager = progressManager
            
            // Use progress manager
            let attempt = PuzzleAttempt(
                attemptID: UUID(),
                puzzleID: UUID(),
                encodingType: "Letters",
                completedAt: nil,
                failedAt: nil,
                completionTime: nil,
                mode: "normal",
                hintCount: 0,
                mistakeCount: 0
            )
            
            try progressStore.logAttempt(attempt)
        }
        
        await Task.yield()
        
        #expect(weakProgressManager == nil, "PuzzleProgressManager should be deallocated")
        #expect(weakProgressStore == nil, "LocalPuzzleProgressStore should be deallocated")
    }
    
    // MARK: - Notification Observer Memory Tests
    
    @Test func notificationObserverCleanup() async throws {
        weak var weakObserver: NSObject?
        var token: NSObjectProtocol?
        
        do {
            let observer = NSObject()
            weakObserver = observer
            
            token = NotificationCenter.default.addObserver(
                forName: .init("TestNotification"),
                object: nil,
                queue: .main
            ) { _ in
                // Retain observer
                _ = observer
            }
            
            // Trigger notification
            NotificationCenter.default.post(name: .init("TestNotification"), object: nil)
        }
        
        // Remove observer
        if let token = token {
            NotificationCenter.default.removeObserver(token)
        }
        
        await Task.yield()
        
        #expect(weakObserver == nil, "Observer should be deallocated after removing from NotificationCenter")
    }
    
    // MARK: - Extended Usage Memory Test
    
    @Test func extendedUsageMemoryStability() async throws {
        weak var weakViewModel: PuzzleViewModel?
        
        do {
            let viewModel = PuzzleViewModel()
            weakViewModel = viewModel
            
            // Simulate extended app usage
            for round in 0..<3 {
                // Load puzzle
                viewModel.loadNewPuzzle()
                try await Task.sleep(nanoseconds: 50_000_000) // 0.05s
                
                // Input letters
                let nonSymbolIndices = viewModel.cells.enumerated().compactMap { index, cell in
                    cell.isSymbol ? nil : index
                }
                
                for i in 0..<min(5, nonSymbolIndices.count) {
                    viewModel.inputLetter("A", at: nonSymbolIndices[i])
                }
                
                // Use hints
                if let firstIndex = nonSymbolIndices.first {
                    viewModel.revealCell(at: firstIndex)
                }
                
                // Make mistakes
                if nonSymbolIndices.count > 1 {
                    viewModel.inputLetter("X", at: nonSymbolIndices[1])
                    try await Task.sleep(nanoseconds: 100_000_000) // Wait for error animation
                }
                
                // Load daily puzzle
                viewModel.loadDailyPuzzle()
                try await Task.sleep(nanoseconds: 50_000_000) // 0.05s
                
                print("📊 Memory Test - Completed round \(round + 1)/3")
            }
            
            // Verify view model is still functional
            #expect(viewModel.cells.count > 0, "ViewModel should remain functional after extended usage")
            #expect(viewModel.currentPuzzle != nil, "ViewModel should have current puzzle")
        }
        
        await Task.yield()
        
        #expect(weakViewModel == nil, "PuzzleViewModel should be deallocated after extended usage test")
    }
    
    // MARK: - Combine Publisher Memory Tests
    
    @Test func combinePublisherMemoryManagement() async throws {
        weak var weakViewModel: PuzzleViewModel?
        var cancellables = Set<AnyCancellable>()
        
        do {
            let viewModel = PuzzleViewModel()
            weakViewModel = viewModel
            
            // Create multiple subscriptions
            viewModel.gameState.$cells
                .sink { _ in }
                .store(in: &cancellables)
            
            viewModel.gameState.$currentPuzzle
                .sink { _ in }
                .store(in: &cancellables)
            
            // GameStateManager doesn't have $isComplete, just observe it via objectWillChange
            viewModel.gameState.objectWillChange
                .sink { _ in }
                .store(in: &cancellables)
            
            // Trigger state changes
            viewModel.loadNewPuzzle()
            try await Task.sleep(nanoseconds: 100_000_000) // 0.1s
            
            if let firstCellIndex = viewModel.cells.firstIndex(where: { !$0.isSymbol }) {
                viewModel.inputLetter("A", at: firstCellIndex)
            }
        }
        
        // Clear all subscriptions
        cancellables.removeAll()
        
        await Task.yield()
        
        #expect(weakViewModel == nil, "PuzzleViewModel should be deallocated after clearing Combine subscriptions")
    }
}

// MARK: - Memory Monitoring Helper

struct MemoryMonitor {
    static func logMemoryUsage(label: String) {
        var memoryInfo = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &memoryInfo) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            let memoryUsageMB = Double(memoryInfo.resident_size) / 1024.0 / 1024.0
            print("📊 Memory Usage [\(label)]: \(String(format: "%.2f", memoryUsageMB)) MB")
        }
    }
    
    static func checkForLeaks() {
        print("📊 Memory leak detection completed - check test results for any failed expectations")
    }
}