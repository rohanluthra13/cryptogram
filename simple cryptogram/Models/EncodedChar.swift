import Foundation

struct EncodedChar: Identifiable {
    let id = UUID()
    let value: String  // The complete value (letter or full number)
    let isSymbol: Bool // Whether this is a space, punctuation, etc.
    
    // For input validation
    var correctValue: String?
    
    init(value: String, isSymbol: Bool = false) {
        self.value = value
        self.isSymbol = isSymbol
    }
} 