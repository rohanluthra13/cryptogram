import Testing
@testable import simple_cryptogram

@MainActor
struct InputHandlerTests {
    
    // MARK: - Test Data
    private func createTestGameState() -> GameStateManager {
        let gameState = GameStateManager(databaseService: DatabaseService.shared)
        let puzzle = Puzzle(
            quoteId: 1,
            encodedText: "ABC DEF",
            solution: "THE DOG",
            hint: "Test puzzle"
        )
        gameState.startNewPuzzle(puzzle)
        return gameState
    }
    
    // MARK: - Initialization Tests
    @Test func initialization() async throws {
        let gameState = createTestGameState()
        let inputHandler = InputHandler(gameState: gameState)
        
        // InputHandler should initialize without crashing
        #expect(inputHandler != nil)
    }
    
    // MARK: - Cell Selection Tests
    @Test func selectValidCell() async throws {
        let gameState = createTestGameState()
        let inputHandler = InputHandler(gameState: gameState)
        
        // Find first non-symbol cell
        guard let firstNonSymbolIndex = gameState.cells.firstIndex(where: { !$0.isSymbol }) else {
            throw TestError("No non-symbol cells found")
        }
        
        inputHandler.selectCell(at: firstNonSymbolIndex)
        
        #expect(gameState.session.selectedCellIndex == firstNonSymbolIndex)
    }
    
    @Test func selectInvalidCell() async throws {
        let gameState = createTestGameState()
        let inputHandler = InputHandler(gameState: gameState)
        
        // Try to select out-of-bounds index
        inputHandler.selectCell(at: 999)
        
        // Selection should not change or should be nil
        #expect(gameState.session.selectedCellIndex == nil || gameState.session.selectedCellIndex != 999)
    }
    
    @Test func selectSymbolCell() async throws {
        let gameState = createTestGameState()
        let inputHandler = InputHandler(gameState: gameState)
        
        // Find first symbol cell (space)
        guard let symbolIndex = gameState.cells.firstIndex(where: { $0.isSymbol }) else {
            throw TestError("No symbol cells found")
        }
        
        inputHandler.selectCell(at: symbolIndex)
        
        // Should not select symbol cells
        #expect(gameState.session.selectedCellIndex != symbolIndex)
    }
    
    // MARK: - Letter Input Tests
    @Test func inputValidLetter() async throws {
        let gameState = createTestGameState()
        let inputHandler = InputHandler(gameState: gameState)
        
        guard let firstNonSymbolIndex = gameState.cells.firstIndex(where: { !$0.isSymbol }) else {
            throw TestError("No non-symbol cells found")
        }
        
        inputHandler.selectCell(at: firstNonSymbolIndex)
        inputHandler.inputLetter("T", at: firstNonSymbolIndex)
        
        #expect(gameState.cells[firstNonSymbolIndex].userInput == "T")
        #expect(gameState.hasUserEngaged)
    }
    
    @Test func inputMultipleLetters() async throws {
        let gameState = createTestGameState()
        let inputHandler = InputHandler(gameState: gameState)
        
        let nonSymbolIndices = gameState.cells.enumerated().compactMap { index, cell in
            cell.isSymbol ? nil : index
        }
        
        guard nonSymbolIndices.count >= 2 else {
            throw TestError("Need at least 2 non-symbol cells")
        }
        
        inputHandler.inputLetter("T", at: nonSymbolIndices[0])
        inputHandler.inputLetter("H", at: nonSymbolIndices[1])
        
        #expect(gameState.cells[nonSymbolIndices[0]].userInput == "T")
        #expect(gameState.cells[nonSymbolIndices[1]].userInput == "H")
    }
    
    @Test func inputInvalidCharacter() async throws {
        let gameState = createTestGameState()
        let inputHandler = InputHandler(gameState: gameState)
        
        guard let firstNonSymbolIndex = gameState.cells.firstIndex(where: { !$0.isSymbol }) else {
            throw TestError("No non-symbol cells found")
        }
        
        let originalLetter = gameState.cells[firstNonSymbolIndex].userInput
        
        inputHandler.inputLetter("123", at: firstNonSymbolIndex) // Invalid input
        
        // Should not change the cell
        #expect(gameState.cells[firstNonSymbolIndex].userInput == originalLetter)
    }
    
    // MARK: - Delete Tests
    @Test func deleteFromSelectedCell() async throws {
        let gameState = createTestGameState()
        let inputHandler = InputHandler(gameState: gameState)
        
        guard let firstNonSymbolIndex = gameState.cells.firstIndex(where: { !$0.isSymbol }) else {
            throw TestError("No non-symbol cells found")
        }
        
        // Add letter first
        inputHandler.selectCell(at: firstNonSymbolIndex)
        inputHandler.inputLetter("T", at: firstNonSymbolIndex)
        #expect(gameState.cells[firstNonSymbolIndex].userInput == "T")
        
        // Delete
        inputHandler.handleDelete()
        
        #expect(gameState.cells[firstNonSymbolIndex].userInput.isEmpty)
    }
    
    @Test func deleteFromSpecificCell() async throws {
        let gameState = createTestGameState()
        let inputHandler = InputHandler(gameState: gameState)
        
        guard let firstNonSymbolIndex = gameState.cells.firstIndex(where: { !$0.isSymbol }) else {
            throw TestError("No non-symbol cells found")
        }
        
        // Add letter first
        inputHandler.inputLetter("T", at: firstNonSymbolIndex)
        #expect(gameState.cells[firstNonSymbolIndex].userInput == "T")
        
        // Delete from specific index
        inputHandler.handleDelete(at: firstNonSymbolIndex)
        
        #expect(gameState.cells[firstNonSymbolIndex].userInput.isEmpty)
    }
    
    // MARK: - Navigation Tests
    @Test func moveToNextCell() async throws {
        let gameState = createTestGameState()
        let inputHandler = InputHandler(gameState: gameState)
        
        let nonSymbolIndices = gameState.cells.enumerated().compactMap { index, cell in
            cell.isSymbol ? nil : index
        }
        
        guard nonSymbolIndices.count >= 2 else {
            throw TestError("Need at least 2 non-symbol cells")
        }
        
        // Select first cell
        inputHandler.selectCell(at: nonSymbolIndices[0])
        #expect(gameState.session.selectedCellIndex == nonSymbolIndices[0])
        
        // Move to next
        inputHandler.moveToNextCell()
        
        // Should select next non-symbol cell
        #expect(gameState.session.selectedCellIndex == nonSymbolIndices[1])
    }
    
    @Test func moveToAdjacentCell() async throws {
        let gameState = createTestGameState()
        let inputHandler = InputHandler(gameState: gameState)
        
        let nonSymbolIndices = gameState.cells.enumerated().compactMap { index, cell in
            cell.isSymbol ? nil : index
        }
        
        guard nonSymbolIndices.count >= 2 else {
            throw TestError("Need at least 2 non-symbol cells")
        }
        
        // Select first cell
        inputHandler.selectCell(at: nonSymbolIndices[0])
        
        // Move forward
        inputHandler.moveToAdjacentCell(direction: 1)
        
        // Should move to next valid cell
        let newSelection = gameState.session.selectedCellIndex
        #expect(newSelection != nonSymbolIndices[0])
        #expect(newSelection != nil)
    }
    
    @Test func moveToAdjacentCellBackward() async throws {
        let gameState = createTestGameState()
        let inputHandler = InputHandler(gameState: gameState)
        
        let nonSymbolIndices = gameState.cells.enumerated().compactMap { index, cell in
            cell.isSymbol ? nil : index
        }
        
        guard nonSymbolIndices.count >= 2 else {
            throw TestError("Need at least 2 non-symbol cells")
        }
        
        // Select second cell
        inputHandler.selectCell(at: nonSymbolIndices[1])
        
        // Move backward
        inputHandler.moveToAdjacentCell(direction: -1)
        
        // Should move to previous valid cell
        let newSelection = gameState.session.selectedCellIndex
        #expect(newSelection != nonSymbolIndices[1])
        #expect(newSelection != nil)
    }
    
    // MARK: - Edge Cases Tests
    @Test func navigationAtBoundaries() async throws {
        let gameState = createTestGameState()
        let inputHandler = InputHandler(gameState: gameState)
        
        let nonSymbolIndices = gameState.cells.enumerated().compactMap { index, cell in
            cell.isSymbol ? nil : index
        }
        
        guard !nonSymbolIndices.isEmpty else {
            throw TestError("Need at least 1 non-symbol cell")
        }
        
        // Select last cell
        inputHandler.selectCell(at: nonSymbolIndices.last!)
        
        // Try to move forward (should handle gracefully)
        inputHandler.moveToNextCell()
        
        // Should either stay at last cell or wrap to first
        let selection = gameState.session.selectedCellIndex
        #expect(selection != nil)
        #expect(nonSymbolIndices.contains(selection!))
    }
    
    @Test func inputWithNoSelection() async throws {
        let gameState = createTestGameState()
        let inputHandler = InputHandler(gameState: gameState)
        
        // Don't select any cell
        #expect(gameState.session.selectedCellIndex == nil)
        
        // Try to input letter
        guard let firstNonSymbolIndex = gameState.cells.firstIndex(where: { !$0.isSymbol }) else {
            throw TestError("No non-symbol cells found")
        }
        
        inputHandler.inputLetter("T", at: firstNonSymbolIndex)
        
        // Should still work
        #expect(gameState.cells[firstNonSymbolIndex].userInput == "T")
    }
}

// MARK: - Test Error
struct TestError: Error {
    let message: String
    
    init(_ message: String) {
        self.message = message
    }
}