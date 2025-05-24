import Foundation
import UIKit

@MainActor
class InputHandler: ObservableObject {
    // MARK: - Dependencies
    private weak var gameState: GameStateManager?
    
    // MARK: - Initialization
    init(gameState: GameStateManager) {
        self.gameState = gameState
    }
    
    // MARK: - Cell Selection
    func selectCell(at index: Int) {
        guard let gameState = gameState,
              index >= 0 && index < gameState.cells.count else { return }
        
        gameState.selectCell(at: index)
        
        // Add subtle haptic feedback for cell selection
        DispatchQueue.main.async {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred(intensity: 0.5)
        }
    }
    
    // MARK: - Letter Input
    func inputLetter(_ letter: String, at index: Int) {
        guard let gameState = gameState,
              index >= 0 && index < gameState.cells.count,
              !gameState.cells[index].isSymbol else { return }
        
        // Start timer on first input
        gameState.startTimer()
        
        let uppercaseLetter = letter.uppercased()
        let cell = gameState.cells[index]
        let wasEmpty = cell.userInput.isEmpty
        
        // Reset all wasJustFilled flags first
        gameState.resetAllWasJustFilled()
        
        // Check if input is correct
        let isCorrect = String(cell.solutionChar ?? " ") == uppercaseLetter
        
        if isCorrect {
            // Correct input
            gameState.updateCell(at: index, with: uppercaseLetter, isRevealed: false, isError: false)
            
            // Light haptic feedback for correct letter
            DispatchQueue.main.async {
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
            }
            
            // Move to next cell
            moveToNextCell()
        } else if !uppercaseLetter.isEmpty {
            // Incorrect input
            gameState.updateCell(at: index, with: uppercaseLetter, isRevealed: false, isError: true)
            
            // Medium haptic feedback for incorrect letter
            DispatchQueue.main.async {
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
            }
            
            // Only count a mistake once per entry and only for newly entered incorrect letters
            if wasEmpty {
                gameState.incrementMistakes()
            }
            
            // Clear incorrect input after brief delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self, weak gameState] in
                guard let gameState = gameState else { return }
                gameState.clearCell(at: index)
            }
        }
        
        gameState.userEngaged()
    }
    
    // MARK: - Delete
    func handleDelete(at index: Int? = nil) {
        guard let gameState = gameState else { return }
        
        let targetIndex = index ?? gameState.selectedCellIndex ?? -1
        if targetIndex >= 0 {
            gameState.clearCell(at: targetIndex)
        }
        
        gameState.userEngaged()
    }
    
    // MARK: - Navigation
    func moveToNextCell() {
        guard let gameState = gameState,
              let currentIndex = gameState.selectedCellIndex else { return }
        
        // Find the next non-symbol, empty cell
        var nextIndex = currentIndex + 1
        while nextIndex < gameState.cells.count {
            if !gameState.cells[nextIndex].isSymbol && gameState.cells[nextIndex].userInput.isEmpty {
                gameState.selectCell(at: nextIndex)
                return
            }
            nextIndex += 1
        }
    }
    
    func moveToAdjacentCell(direction: Int) {
        guard let gameState = gameState else { return }
        
        // If no cell is selected, select the first non-symbol cell
        if gameState.selectedCellIndex == nil {
            if let firstNonSymbolIndex = gameState.cells.indices.first(where: { !gameState.cells[$0].isSymbol }) {
                gameState.selectCell(at: firstNonSymbolIndex)
                return
            } else {
                return
            }
        }
        
        guard let currentIndex = gameState.selectedCellIndex else { return }
        
        // Calculate the target index
        let targetIndex = currentIndex + direction
        
        // Check if the target index is valid
        if targetIndex >= 0 && targetIndex < gameState.cells.count {
            // Skip symbol cells
            if !gameState.cells[targetIndex].isSymbol {
                gameState.selectCell(at: targetIndex)
            } else {
                // If we hit a symbol cell, continue in the same direction
                moveToAdjacentCell(direction: direction > 0 ? direction + 1 : direction - 1)
            }
        }
    }
    
    func selectNextUnrevealedCell(after index: Int) {
        guard let gameState = gameState else { return }
        
        let nextIndex = gameState.cells.indices.first { idx in
            idx > index && 
            !gameState.cells[idx].isSymbol && 
            !gameState.cells[idx].isRevealed && 
            gameState.cells[idx].userInput.isEmpty
        }
        
        if let next = nextIndex {
            gameState.selectCell(at: next)
        }
    }
}