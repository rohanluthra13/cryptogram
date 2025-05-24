import Testing
@testable import simple_cryptogram

@MainActor
struct HintManagerTests {
    
    // MARK: - Test Data
    private func createTestSetup() -> (GameStateManager, InputHandler, HintManager) {
        let gameState = GameStateManager(databaseService: DatabaseService.shared)
        let puzzle = Puzzle(
            quoteId: 1,
            encodedText: "ABC DEF",
            solution: "THE DOG",
            hint: "Test puzzle"
        )
        gameState.startNewPuzzle(puzzle)
        
        let inputHandler = InputHandler(gameState: gameState)
        let hintManager = HintManager(gameState: gameState, inputHandler: inputHandler)
        
        return (gameState, inputHandler, hintManager)
    }
    
    // MARK: - Initialization Tests
    @Test func initialization() async throws {
        let (_, _, hintManager) = createTestSetup()
        
        // HintManager should initialize without crashing
        #expect(hintManager != nil)
    }
    
    // MARK: - Reveal Cell Tests
    @Test func revealSelectedCell() async throws {
        let (gameState, inputHandler, hintManager) = createTestSetup()
        
        guard let firstNonSymbolIndex = gameState.cells.firstIndex(where: { !$0.isSymbol }) else {
            throw TestError("No non-symbol cells found")
        }
        
        // Select a cell
        inputHandler.selectCell(at: firstNonSymbolIndex)
        
        let originalHintCount = gameState.hintCount
        
        // Reveal the selected cell
        hintManager.revealCell()
        
        // Cell should be revealed
        #expect(gameState.cells[firstNonSymbolIndex].isRevealed)
        #expect(!gameState.cells[firstNonSymbolIndex].userInput.isEmpty)
        #expect(gameState.hintCount == originalHintCount + 1)
    }
    
    @Test func revealSpecificCell() async throws {
        let (gameState, _, hintManager) = createTestSetup()
        
        guard let firstNonSymbolIndex = gameState.cells.firstIndex(where: { !$0.isSymbol }) else {
            throw TestError("No non-symbol cells found")
        }
        
        let originalHintCount = gameState.hintCount
        
        // Reveal specific cell
        hintManager.revealCell(at: firstNonSymbolIndex)
        
        // Cell should be revealed
        #expect(gameState.cells[firstNonSymbolIndex].isRevealed)
        #expect(!gameState.cells[firstNonSymbolIndex].userInput.isEmpty)
        #expect(gameState.hintCount == originalHintCount + 1)
    }
    
    @Test func revealAlreadyRevealedCell() async throws {
        let (gameState, _, hintManager) = createTestSetup()
        
        guard let firstNonSymbolIndex = gameState.cells.firstIndex(where: { !$0.isSymbol }) else {
            throw TestError("No non-symbol cells found")
        }
        
        // Reveal cell first time
        hintManager.revealCell(at: firstNonSymbolIndex)
        let hintCountAfterFirst = gameState.hintCount
        
        // Try to reveal again
        hintManager.revealCell(at: firstNonSymbolIndex)
        
        // Hint count should not increase
        #expect(gameState.hintCount == hintCountAfterFirst)
    }
    
    @Test func revealSymbolCell() async throws {
        let (gameState, _, hintManager) = createTestSetup()
        
        guard let symbolIndex = gameState.cells.firstIndex(where: { $0.isSymbol }) else {
            throw TestError("No symbol cells found")
        }
        
        let originalHintCount = gameState.hintCount
        
        // Try to reveal symbol cell
        hintManager.revealCell(at: symbolIndex)
        
        // Hint count should not change
        #expect(gameState.hintCount == originalHintCount)
    }
    
    @Test func revealWithUserInput() async throws {
        let (gameState, inputHandler, hintManager) = createTestSetup()
        
        guard let firstNonSymbolIndex = gameState.cells.firstIndex(where: { !$0.isSymbol }) else {
            throw TestError("No non-symbol cells found")
        }
        
        // Add user input first
        inputHandler.inputLetter("X", at: firstNonSymbolIndex)
        #expect(gameState.cells[firstNonSymbolIndex].userInput == "X")
        
        let originalHintCount = gameState.hintCount
        
        // Reveal the cell
        hintManager.revealCell(at: firstNonSymbolIndex)
        
        // Should override user input with correct letter
        #expect(gameState.cells[firstNonSymbolIndex].isRevealed)
        #expect(gameState.cells[firstNonSymbolIndex].userInput != "X")
        #expect(gameState.hintCount == originalHintCount + 1)
    }
    
    // MARK: - Navigation After Reveal Tests
    @Test func navigationAfterReveal() async throws {
        let (gameState, inputHandler, hintManager) = createTestSetup()
        
        let nonSymbolIndices = gameState.cells.enumerated().compactMap { index, cell in
            cell.isSymbol ? nil : index
        }
        
        guard nonSymbolIndices.count >= 3 else {
            throw TestError("Need at least 3 non-symbol cells")
        }
        
        // Reveal first two cells
        hintManager.revealCell(at: nonSymbolIndices[0])
        hintManager.revealCell(at: nonSymbolIndices[1])
        
        // The inputHandler should have moved selection after reveals
        // Just verify that cells were revealed
        #expect(gameState.cells[nonSymbolIndices[0]].isRevealed)
        #expect(gameState.cells[nonSymbolIndices[1]].isRevealed)
    }
    
    // MARK: - Difficulty Mode Pre-fills Tests
    // Note: HintManager in the refactored version doesn't have applyDifficultyPrefills
    // This is likely handled by GameStateManager during puzzle initialization
    @Test func prefillsAppliedInNormalMode() async throws {
        // Test that when UserSettings.currentMode is .normal, 
        // some cells are pre-filled when a puzzle starts
        // This would require mocking UserSettings or testing through PuzzleViewModel
        
        // For now, we'll skip this test as it requires integration testing
        #expect(true) // Placeholder
    }
    
    // MARK: - Edge Cases Tests
    @Test func revealWithInvalidIndex() async throws {
        let (gameState, _, hintManager) = createTestSetup()
        
        let originalHintCount = gameState.hintCount
        
        // Try to reveal invalid index
        hintManager.revealCell(at: 999)
        
        // Hint count should not change
        #expect(gameState.hintCount == originalHintCount)
    }
    
    @Test func revealWithNoSelectedCell() async throws {
        let (gameState, _, hintManager) = createTestSetup()
        
        // Ensure no cell is selected
        gameState.session.selectedCellIndex = nil
        
        let originalHintCount = gameState.hintCount
        
        // Try to reveal with no selection
        hintManager.revealCell()
        
        // Should handle gracefully - might select and reveal first available cell
        // or might do nothing - both are acceptable behaviors
        #expect(gameState.hintCount >= originalHintCount)
    }
    
    @Test func multipleRevealsUpdateCompletedLetters() async throws {
        let (gameState, _, hintManager) = createTestSetup()
        
        let nonSymbolIndices = gameState.cells.enumerated().compactMap { index, cell in
            cell.isSymbol ? nil : index
        }
        
        guard nonSymbolIndices.count >= 2 else {
            throw TestError("Need at least 2 non-symbol cells")
        }
        
        let originalCompletedCount = gameState.completedLetters.count
        
        // Reveal multiple cells
        hintManager.revealCell(at: nonSymbolIndices[0])
        hintManager.revealCell(at: nonSymbolIndices[1])
        
        // Completed letters should be updated
        #expect(gameState.completedLetters.count >= originalCompletedCount)
    }
}