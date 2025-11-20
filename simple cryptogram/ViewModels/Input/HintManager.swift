import Foundation
import UIKit

@MainActor
class HintManager: ObservableObject {
    // MARK: - Dependencies
    private let gameState: GameStateManager
    private let inputHandler: InputHandler

    // MARK: - Initialization
    init(gameState: GameStateManager, inputHandler: InputHandler) {
        self.gameState = gameState
        self.inputHandler = inputHandler
    }
    
    // MARK: - Reveal Operations
    func revealCell(at index: Int? = nil) {
        // Determine target index
        let targetIndex: Int
        
        if let idx = index {
            // Validate the provided index
            guard idx >= 0 && idx < gameState.cells.count else { return }
            guard !gameState.cells[idx].isSymbol else { return }
            guard !gameState.cells[idx].isRevealed else { return }
            targetIndex = idx
        } else if let selected = gameState.selectedCellIndex,
                  selected >= 0 && selected < gameState.cells.count &&
                  !gameState.cells[selected].isSymbol &&
                  !gameState.cells[selected].isRevealed {
            targetIndex = selected
        } else {
            // Find first unrevealed, non-symbol cell
            if let firstUnrevealedIndex = gameState.cells.indices.first(where: {
                !gameState.cells[$0].isSymbol && 
                !gameState.cells[$0].isRevealed && 
                gameState.cells[$0].userInput.isEmpty
            }) {
                targetIndex = firstUnrevealedIndex
            } else {
                // No unrevealed cells left
                return
            }
        }
        
        // Start timer if needed
        gameState.startTimer()
        
        // Reveal the cell
        guard let solutionChar = gameState.cells[targetIndex].solutionChar else { return }
        let solutionString = String(solutionChar)
        
        gameState.updateCell(at: targetIndex, with: solutionString, isRevealed: true, isError: false)
        gameState.markCellRevealed(at: targetIndex)
        
        // Track hint usage
        gameState.incrementHints()
        
        // Add haptic feedback for revealing a letter
        DispatchQueue.main.async {
            let generator = UISelectionFeedbackGenerator()
            generator.selectionChanged()
        }
        
        // Select next unrevealed cell
        inputHandler.selectNextUnrevealedCell(after: targetIndex)

        gameState.userEngaged()
    }
}