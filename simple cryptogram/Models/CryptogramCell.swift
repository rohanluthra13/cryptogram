import Foundation

/**
 * CryptogramCell is the unified model for all character representations in the cryptogram.
 * This model replaces the legacy EncodedChar model and provides enhanced functionality.
 * The 'encodedChar' property corresponds to what was previously 'value' in EncodedChar.
 */
struct CryptogramCell: Identifiable {
    let id = UUID()
    let position: Int            // Position in the original puzzle
    let encodedChar: String      // Encoded character or symbol
    let solutionChar: Character? // Correct solution character (nil for symbols)
    let isSymbol: Bool           // Whether this is a symbol (space, punctuation)
    
    var userInput: String = ""   // User's input for this cell
    var isRevealed: Bool = false // Whether this letter has been revealed
    var isError: Bool = false    // Whether there's an error in this cell
    var wasJustFilled: Bool = false // Flag to track when a cell was just filled for animation
    
    // Computed properties
    var isEmpty: Bool { userInput.isEmpty }
    var isCorrect: Bool { 
        // If there is no solution character, the cell can't be correct or incorrect
        guard let solution = solutionChar else {
            return true // Default to true to prevent being marked as incorrect
        }
        return userInput == String(solution)
    }
    
    init(
        position: Int,
        encodedChar: String,
        solutionChar: Character? = nil,
        isSymbol: Bool = false,
        userInput: String = "",
        isRevealed: Bool = false,
        isError: Bool = false,
        wasJustFilled: Bool = false
    ) {
        self.position = position
        self.encodedChar = encodedChar
        self.solutionChar = solutionChar
        self.isSymbol = isSymbol
        self.userInput = userInput
        self.isRevealed = isRevealed
        self.isError = isError
        self.wasJustFilled = wasJustFilled
    }
} 