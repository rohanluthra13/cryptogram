import Foundation
import CryptoKit

/**
 * CryptogramCell is the unified model for all character representations in the cryptogram.
 * This model replaces the legacy EncodedChar model and provides enhanced functionality.
 * The 'encodedChar' property corresponds to what was previously 'value' in EncodedChar.
 */
struct CryptogramCell: Identifiable, Equatable {
    let id: UUID
    let quoteId: Int
    let position: Int            // Position in the original puzzle
    let encodedChar: String      // Encoded character or symbol
    let solutionChar: Character? // Correct solution character (nil for symbols)
    let isSymbol: Bool           // Whether this is a symbol (space, punctuation)
    
    var userInput: String = ""   // User's input for this cell
    var isRevealed: Bool = false // Whether this letter has been revealed
    var isError: Bool = false    // Whether there's an error in this cell
    var wasJustFilled: Bool = false // Flag to track when a cell was just filled for animation
    var isPreFilled: Bool = false // Whether this cell was pre-filled at the start (Normal mode)
    
    // Computed properties
    var isEmpty: Bool { userInput.isEmpty }
    var isCorrect: Bool { 
        // If there is no solution character, the cell can't be correct or incorrect
        guard let solution = solutionChar else {
            return true // Default to true to prevent being marked as incorrect
        }
        return userInput == String(solution)
    }
    
    static func deterministicCellUUID(quoteId: Int, position: Int, encodedChar: String, solutionChar: Character?, isSymbol: Bool) -> UUID {
        let baseString = "\(quoteId)-\(position)-\(encodedChar)-\(solutionChar ?? "_")-\(isSymbol)"
        let hash = SHA256.hash(data: Data(baseString.utf8))
        let hex = hash.compactMap { String(format: "%02x", $0) }.joined().prefix(32)
        let formatted = "\(hex.prefix(8))-\(hex.dropFirst(8).prefix(4))-\(hex.dropFirst(12).prefix(4))-\(hex.dropFirst(16).prefix(4))-\(hex.dropFirst(20))"
        return UUID(uuidString: String(formatted)) ?? UUID()
    }
    
    init(
        quoteId: Int,
        position: Int,
        encodedChar: String,
        solutionChar: Character? = nil,
        isSymbol: Bool = false,
        userInput: String = "",
        isRevealed: Bool = false,
        isError: Bool = false,
        wasJustFilled: Bool = false,
        isPreFilled: Bool = false
    ) {
        self.quoteId = quoteId
        self.position = position
        self.encodedChar = encodedChar
        self.solutionChar = solutionChar
        self.isSymbol = isSymbol
        self.userInput = userInput
        self.isRevealed = isRevealed
        self.isError = isError
        self.wasJustFilled = wasJustFilled
        self.isPreFilled = isPreFilled
        self.id = CryptogramCell.deterministicCellUUID(quoteId: quoteId, position: position, encodedChar: encodedChar, solutionChar: solutionChar, isSymbol: isSymbol)
    }
} 