import Foundation

// Note: This file previously relied on the EncodedChar model which has been removed.
// CryptogramCell now serves as the unified model for all cryptogram character representations.

struct Puzzle: Identifiable {
    let id: UUID
    let quoteId: Int // Database quote ID for daily puzzle progress
    let encodedText: String
    let solution: String
    let hint: String
    let author: String
    let difficulty: String
    let length: Int
    
    init(
        id: UUID = UUID(),
        quoteId: Int,
        encodedText: String,
        solution: String,
        hint: String,
        author: String = "Unknown",
        difficulty: String = "Medium",
        length: Int? = nil
    ) {
        self.id = id
        self.quoteId = quoteId
        self.encodedText = encodedText
        self.solution = solution
        self.hint = hint
        self.author = author
        self.difficulty = difficulty
        self.length = length ?? encodedText.count
    }
    
    // Creates a list of CryptogramCells from the puzzle
    func createCells(encodingType: String = "Letters") -> [CryptogramCell] {
        var _ = [CryptogramCell]()
        
        if encodingType == "Letters" {
            return createLetterEncodedCells()
        } else {
            return createNumberEncodedCells()
        }
    }
    
    // Create cells for letter-encoded puzzles (standard cryptogram)
    // 
    // This method follows these key steps:
    // 1. Skip all spaces and punctuation in the encoded text
    // 2. Create cells only for letters/numbers from the encoded text
    // 3. Add spaces and punctuation cells based on their position in the solution text
    //
    // This ensures that:
    // - Spaces and punctuation from the solution text are correctly represented
    // - Letters are properly aligned between encoded and solution text
    // - No extra cells are created for spaces/punctuation in the encoded text
    private func createLetterEncodedCells() -> [CryptogramCell] {
        var _ = [CryptogramCell]()
        
        // Ensure solution and encodedText are properly aligned
        let solutionArray = Array(solution.uppercased())
        let encodedArray = Array(encodedText)
        
        // Count how many actual letters we have in the encoded text
        var letterCount = 0
        for char in encodedArray {
            if char.isLetter {
                letterCount += 1
            }
        }
        
        // Ensure we have enough solution characters for the encoded text
        guard letterCount <= solutionArray.count else {
            print("Error: Encoded text has more letters than solution")
            return []
        }
        
        var solutionIndex = 0
        var _ = 0
        var processedCells: [CryptogramCell] = []
        
        for i in 0..<encodedArray.count {
            let encodedChar = String(encodedArray[i])
            let isSymbol = !(encodedArray[i].isLetter || encodedArray[i].isNumber)
            
            var solutionChar: Character? = nil
            
            // Skip all non-alphanumeric characters in the encoded text
            if isSymbol {
                continue
            }
            
            // Only assign a solution character for letter cells and if we have enough solution characters
            if !isSymbol && solutionIndex < solutionArray.count {
                // Skip spaces and punctuation in the solution
                while solutionIndex < solutionArray.count && !solutionArray[solutionIndex].isLetter {
                    solutionIndex += 1
                }
                
                if solutionIndex < solutionArray.count {
                    solutionChar = solutionArray[solutionIndex]
                    solutionIndex += 1
                }
            }
            
            let cell = CryptogramCell(
                quoteId: quoteId,
                position: processedCells.count,
                encodedChar: encodedChar,
                solutionChar: solutionChar,
                isSymbol: isSymbol
            )
            
            processedCells.append(cell)
        }
        
        // Now rebuild the cells array with spaces and punctuation inserted where they appear in the solution
        var finalCells: [CryptogramCell] = []
        solutionIndex = 0
        
        for cell in processedCells {
            if !cell.isSymbol && cell.solutionChar != nil {
                // Find the position of this solution character
                while solutionIndex < solutionArray.count && solutionArray[solutionIndex] != cell.solutionChar {
                    // Add a cell for any non-alphanumeric character we encounter in the solution
                    if !solutionArray[solutionIndex].isLetter {
                        finalCells.append(CryptogramCell(
                            quoteId: quoteId,
                            position: finalCells.count,
                            encodedChar: String(solutionArray[solutionIndex]),
                            solutionChar: nil,
                            isSymbol: true
                        ))
                    }
                    solutionIndex += 1
                }
                
                if solutionIndex < solutionArray.count {
                    finalCells.append(cell)
                    solutionIndex += 1
                }
            }
        }
        
        // Check if there are any remaining non-alphanumeric characters in the solution
        while solutionIndex < solutionArray.count {
            if !solutionArray[solutionIndex].isLetter {
                finalCells.append(CryptogramCell(
                    quoteId: quoteId,
                    position: finalCells.count,
                    encodedChar: String(solutionArray[solutionIndex]),
                    solutionChar: nil,
                    isSymbol: true
                ))
            }
            solutionIndex += 1
        }
        
        // Debug information
        print("Letter encoded puzzle: \(encodedText)")
        print("Solution: \(solution)")
        print("Created \(finalCells.count) cells")
        
        return finalCells
    }
    
    // Create cells for number-encoded puzzles
    //
    // This method follows these key steps:
    // 1. Skip spaces and punctuation in the encoded text
    // 2. Create cells only for number components representing letters
    // 3. Add spaces and punctuation cells based on their position in the solution text
    //
    // This ensures that:
    // - Spaces and punctuation from the solution text are correctly represented
    // - Numbers are properly aligned with the solution letters they represent
    // - No extra cells are created for spaces/punctuation in the encoded text
    private func createNumberEncodedCells() -> [CryptogramCell] {
        var cells: [CryptogramCell] = []
        
        // For number encoding format from the database, we need to:
        // 1. Identify actual numbers vs punctuation
        // 2. Skip the spaces between numbers as they're just separators
        
        // Split by whitespace to get each component
        let components = encodedText.components(separatedBy: .whitespaces)
        let solutionArray = Array(solution.uppercased())
        
        var position = 0
        var solutionIndex = 0
        
        // Filter out empty components (spaces between numbers)
        let nonEmptyComponents = components.filter { !$0.isEmpty }
        
        for component in nonEmptyComponents {
            // Skip all punctuation components - only process number components
            if component.allSatisfy({ $0.isPunctuation || $0.isSymbol }) {
                continue
            }
            
            if component.allSatisfy({ $0.isNumber }) {
                // This is a number representing a letter in the solution
                // Skip spaces and punctuation in the solution to find the next letter
                while solutionIndex < solutionArray.count && !solutionArray[solutionIndex].isLetter {
                    solutionIndex += 1
                }
                
                if solutionIndex < solutionArray.count {
                    cells.append(CryptogramCell(
                        quoteId: quoteId,
                        position: position,
                        encodedChar: component,
                        solutionChar: solutionArray[solutionIndex],
                        isSymbol: false
                    ))
                    solutionIndex += 1
                    position += 1
                }
            } else if component.count > 1 {
                // This might be multiple characters (rare case)
                print("Warning: Multi-character component in number encoding: \(component)")
                
                // If it contains any numbers, it might need to map to solution
                let hasNumbers = component.contains(where: { $0.isNumber })
                
                if hasNumbers {
                    // Skip spaces and punctuation in the solution
                    while solutionIndex < solutionArray.count && !solutionArray[solutionIndex].isLetter {
                        solutionIndex += 1
                    }
                
                    cells.append(CryptogramCell(
                        quoteId: quoteId,
                        position: position,
                        encodedChar: component,
                        solutionChar: hasNumbers && solutionIndex < solutionArray.count ? solutionArray[solutionIndex] : nil,
                        isSymbol: !hasNumbers
                    ))
                    
                    if solutionIndex < solutionArray.count {
                        solutionIndex += 1
                    }
                    position += 1
                }
            }
        }
        
        // Rebuild cells array with spaces and punctuation inserted based on solution
        var finalCells: [CryptogramCell] = []
        solutionIndex = 0
        
        for cell in cells {
            if !cell.isSymbol && cell.solutionChar != nil {
                // Find this character in the solution
                while solutionIndex < solutionArray.count && solutionArray[solutionIndex] != cell.solutionChar {
                    // Add cell for any non-alphanumeric character we encounter in the solution
                    if !solutionArray[solutionIndex].isLetter {
                        finalCells.append(CryptogramCell(
                            quoteId: quoteId,
                            position: finalCells.count,
                            encodedChar: String(solutionArray[solutionIndex]),
                            solutionChar: nil,
                            isSymbol: true
                        ))
                    }
                    solutionIndex += 1
                }
                
                if solutionIndex < solutionArray.count {
                    // Found the letter in the solution, add the cell
                    finalCells.append(cell)
                    solutionIndex += 1
                }
            }
        }
        
        // Check if there are any remaining non-alphanumeric characters in the solution
        while solutionIndex < solutionArray.count {
            if !solutionArray[solutionIndex].isLetter {
                finalCells.append(CryptogramCell(
                    quoteId: quoteId,
                    position: finalCells.count,
                    encodedChar: String(solutionArray[solutionIndex]),
                    solutionChar: nil,
                    isSymbol: true
                ))
            }
            solutionIndex += 1
        }
        
        // Debug information
        print("Number encoded puzzle: \(encodedText)")
        print("Solution: \(solution)")
        print("Created \(finalCells.count) cells, mapped to \(solutionIndex) solution characters")
        
        return finalCells
    }
    
    /// Original author string from DB
    var authorName: String { author }
} 
