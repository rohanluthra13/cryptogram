import Testing
@testable import simple_cryptogram

@MainActor
struct GameStateManagerTests {
    
    // MARK: - Test Data
    private func createTestPuzzle() -> Puzzle {
        return Puzzle(
            quoteId: 1,
            encodedText: "ABC DEF",
            solution: "THE DOG",
            hint: "Test puzzle"
        )
    }
    
    private func createMockDatabaseService() -> DatabaseService {
        // For now, use the real service - we'll mock later if needed
        return DatabaseService.shared
    }
    
    // MARK: - Initialization Tests
    @Test func initialization() async throws {
        let manager = GameStateManager(databaseService: createMockDatabaseService())
        
        #expect(manager.cells.isEmpty)
        #expect(manager.currentPuzzle == nil)
        #expect(!manager.session.hasStarted)
        #expect(manager.completedLetters.isEmpty)
        #expect(!manager.hasUserEngaged)
        #expect(!manager.showCompletedHighlights)
    }
    
    // MARK: - Puzzle Loading Tests
    @Test func startNewPuzzle() async throws {
        let manager = GameStateManager(databaseService: createMockDatabaseService())
        let puzzle = createTestPuzzle()
        
        manager.startNewPuzzle(puzzle)
        
        #expect(manager.currentPuzzle?.id == puzzle.id)
        #expect(!manager.cells.isEmpty)
        #expect(manager.session.hasStarted)
        #expect(manager.session.startTime != nil)
    }
    
    @Test func startNewPuzzleWithSkipAnimation() async throws {
        let manager = GameStateManager(databaseService: createMockDatabaseService())
        let puzzle = createTestPuzzle()
        
        manager.startNewPuzzle(puzzle, skipAnimationInit: true)
        
        #expect(manager.currentPuzzle?.id == puzzle.id)
        #expect(!manager.cells.isEmpty)
        #expect(manager.cellsToAnimate.isEmpty)
    }
    
    // MARK: - Cell Management Tests
    @Test func cellCreation() async throws {
        let manager = GameStateManager(databaseService: createMockDatabaseService())
        let puzzle = createTestPuzzle()
        
        manager.startNewPuzzle(puzzle)
        
        // Should have cells for "ABC DEF" (7 characters including space)
        #expect(manager.cells.count == 7)
        
        // Check non-symbol cells (should exclude space)
        let nonSymbolCells = manager.nonSymbolCells
        #expect(nonSymbolCells.count == 6) // A, B, C, D, E, F
    }
    
    @Test func progressPercentage() async throws {
        let manager = GameStateManager(databaseService: createMockDatabaseService())
        let puzzle = createTestPuzzle()
        
        manager.startNewPuzzle(puzzle)
        
        // Initially 0% progress
        #expect(manager.progressPercentage == 0.0)
        
        // Fill some cells
        if let firstNonSymbolCell = manager.nonSymbolCells.first {
            let index = manager.cells.firstIndex { $0.id == firstNonSymbolCell.id } ?? 0
            manager.cells[index].userInput = "T"
            manager.updateCompletedLetters()
            
            // Should have some progress
            #expect(manager.progressPercentage > 0.0)
        }
    }
    
    // MARK: - Completion Tests
    @Test func completionDetection() async throws {
        let manager = GameStateManager(databaseService: createMockDatabaseService())
        let puzzle = createTestPuzzle()
        
        manager.startNewPuzzle(puzzle)
        
        // Fill all cells with correct letters using the updateCell method
        for i in 0..<manager.cells.count {
            if !manager.cells[i].isSymbol {
                let correctLetter = String(puzzle.solution[puzzle.solution.index(puzzle.solution.startIndex, offsetBy: i)])
                manager.updateCell(at: i, with: correctLetter)
            }
        }
        
        #expect(manager.isComplete)
        #expect(manager.session.endTime != nil)
    }
    
    // MARK: - Reset Tests
    @Test func resetPuzzle() async throws {
        let manager = GameStateManager(databaseService: createMockDatabaseService())
        let puzzle = createTestPuzzle()
        
        manager.startNewPuzzle(puzzle)
        
        // Add some user input
        if !manager.cells.isEmpty {
            manager.cells[0].userInput = "X"
        }
        manager.userEngaged()
        
        #expect(manager.hasUserEngaged)
        
        // Reset
        manager.resetPuzzle()
        
        // Should clear user input but keep puzzle
        #expect(manager.currentPuzzle?.id == puzzle.id)
        #expect(!manager.hasUserEngaged)
        #expect(manager.cells.allSatisfy { $0.userInput.isEmpty })
    }
    
    // MARK: - Word Groups Tests
    @Test func wordGroupGeneration() async throws {
        let manager = GameStateManager(databaseService: createMockDatabaseService())
        let puzzle = createTestPuzzle()
        
        manager.startNewPuzzle(puzzle)
        
        let wordGroups = manager.wordGroups
        
        // Should have 2 word groups for "ABC DEF"
        #expect(wordGroups.count == 2)
        
        // First group should be indices for "ABC"
        #expect(wordGroups[0].indices.count == 3)
        
        // Second group should be indices for "DEF"
        #expect(wordGroups[1].indices.count == 3)
    }
    
    // MARK: - Pause/Resume Tests
    @Test func pauseResume() async throws {
        let manager = GameStateManager(databaseService: createMockDatabaseService())
        let puzzle = createTestPuzzle()
        
        manager.startNewPuzzle(puzzle)
        
        #expect(!manager.isPaused)
        
        manager.togglePause()
        #expect(manager.isPaused)
        
        manager.togglePause()
        #expect(!manager.isPaused)
    }
    
    // MARK: - Animation Tests
    @Test func wiggleAnimation() async throws {
        let manager = GameStateManager(databaseService: createMockDatabaseService())
        
        #expect(!manager.isWiggling)
        
        manager.triggerCompletionWiggle()
        #expect(manager.isWiggling)
        
        // Wait for animation to complete (should reset after delay)
        try await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds
        #expect(!manager.isWiggling)
    }
    
    @Test func cellAnimationTracking() async throws {
        let manager = GameStateManager(databaseService: createMockDatabaseService())
        let puzzle = createTestPuzzle()
        
        manager.startNewPuzzle(puzzle)
        
        // Should have cells to animate initially
        #expect(!manager.cellsToAnimate.isEmpty)
        
        // Mark animations complete
        let cellsToComplete = manager.cellsToAnimate
        for cellId in cellsToComplete {
            manager.markCellAnimationComplete(cellId)
        }
        
        #expect(manager.cellsToAnimate.isEmpty)
    }
}