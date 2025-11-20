import Foundation
import UIKit

@MainActor
class InputHandler: ObservableObject {
    // MARK: - Dependencies
    private let gameState: GameStateManager

    // MARK: - Initialization
    init(gameState: GameStateManager) {
        self.gameState = gameState
    }
    
    // MARK: - Cell Selection
    func selectCell(at index: Int) {
        guard index >= 0 && index < gameState.cells.count else { return }

        gameState.selectCell(at: index)
        
        // Add subtle haptic feedback for cell selection
        DispatchQueue.main.async {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred(intensity: 0.5)
        }
    }
    
    // MARK: - Letter Input
    func inputLetter(_ letter: String, at index: Int) {
        guard index >= 0 && index < gameState.cells.count,
              !gameState.cells[index].isSymbol else { return }
        
        // Validate input - must be a single letter
        guard letter.count == 1,
              let firstChar = letter.first,
              firstChar.isLetter else { return }
        
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
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak gameState] in
                guard let gameState = gameState else { return }
                gameState.clearCell(at: index)
            }
        }
        
        gameState.userEngaged()
    }
    
    // MARK: - Delete
    func handleDelete(at index: Int? = nil) {
        let targetIndex = index ?? gameState.selectedCellIndex ?? -1
        if targetIndex >= 0 && targetIndex < gameState.cells.count && !gameState.cells[targetIndex].isSymbol {
            gameState.clearCell(at: targetIndex)
            gameState.userEngaged()
        }
    }
    
    // MARK: - Navigation
    private func shouldSkipCell(_ cell: CryptogramCell) -> Bool {
        // Skip if it's a symbol, revealed, pre-filled, or has correct input
        return cell.isSymbol || 
               cell.isRevealed || 
               cell.isPreFilled || 
               (!cell.userInput.isEmpty && cell.isCorrect)
    }
    
    func moveToNextCell() {
        guard let currentIndex = gameState.selectedCellIndex else { return }

        // Find the next editable cell
        var nextIndex = currentIndex + 1
        while nextIndex < gameState.cells.count {
            if !shouldSkipCell(gameState.cells[nextIndex]) {
                gameState.selectCell(at: nextIndex)
                return
            }
            nextIndex += 1
        }
    }
    
    func moveToAdjacentCell(direction: Int) {
        // If no cell is selected, select the first editable cell
        if gameState.selectedCellIndex == nil {
            if let firstEditableIndex = gameState.cells.indices.first(where: { !shouldSkipCell(gameState.cells[$0]) }) {
                gameState.selectCell(at: firstEditableIndex)
                return
            } else {
                return
            }
        }
        
        guard let currentIndex = gameState.selectedCellIndex else { return }
        
        // Find the next editable cell in the given direction
        var targetIndex = currentIndex + direction
        
        while targetIndex >= 0 && targetIndex < gameState.cells.count {
            if !shouldSkipCell(gameState.cells[targetIndex]) {
                gameState.selectCell(at: targetIndex)
                return
            }
            targetIndex += direction
        }
    }
    
    func selectNextUnrevealedCell(after index: Int) {
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