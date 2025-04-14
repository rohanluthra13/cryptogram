import Foundation

struct Puzzle: Identifiable {
    let id: UUID
    let encodedText: String
    let solution: String
    let hint: String
    let author: String
    let difficulty: String
    let length: Int
    
    init(
        id: UUID = UUID(),
        encodedText: String,
        solution: String,
        hint: String,
        author: String = "Unknown",
        difficulty: String = "Medium",
        length: Int? = nil
    ) {
        self.id = id
        self.encodedText = encodedText
        self.solution = solution
        self.hint = hint
        self.author = author
        self.difficulty = difficulty
        self.length = length ?? encodedText.count
    }
    
    // Creates a list of CryptogramCells from the puzzle
    func createCells(encodingType: String = "Letters") -> [CryptogramCell] {
        var cells: [CryptogramCell] = []
        
        if encodingType == "Letters" {
            return createLetterEncodedCells()
        } else {
            return createNumberEncodedCells()
        }
    }
    
    // Create cells for letter-encoded puzzles (standard cryptogram)
    private func createLetterEncodedCells() -> [CryptogramCell] {
        var cells: [CryptogramCell] = []
        
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
        var solutionCharPosition = 0
        var processedCells: [CryptogramCell] = []
        
        for i in 0..<encodedArray.count {
            let encodedChar = String(encodedArray[i])
            let isSymbol = !(encodedArray[i].isLetter || encodedArray[i].isNumber)
            
            var solutionChar: Character? = nil
            
            // Only assign a solution character for letter cells and if we have enough solution characters
            if !isSymbol && solutionIndex < solutionArray.count {
                // Skip spaces in the solution
                while solutionIndex < solutionArray.count && solutionArray[solutionIndex] == " " {
                    solutionIndex += 1
                }
                
                if solutionIndex < solutionArray.count {
                    solutionChar = solutionArray[solutionIndex]
                    solutionIndex += 1
                }
            }
            
            // Skip spaces in encoded text - don't create cells for them
            if encodedChar == " " {
                continue
            }
            
            let cell = CryptogramCell(
                position: processedCells.count,
                encodedChar: encodedChar,
                solutionChar: solutionChar,
                isSymbol: isSymbol
            )
            
            processedCells.append(cell)
        }
        
        // Now rebuild the cells array with spaces inserted where they appear in the solution
        var finalCells: [CryptogramCell] = []
        solutionIndex = 0
        
        for cell in processedCells {
            if !cell.isSymbol && cell.solutionChar != nil {
                // Find the position of this solution character
                while solutionIndex < solutionArray.count && solutionArray[solutionIndex] != cell.solutionChar {
                    if solutionArray[solutionIndex] == " " {
                        // Add a space cell whenever we encounter a space in the solution
                        finalCells.append(CryptogramCell(
                            position: finalCells.count,
                            encodedChar: " ",
                            isSymbol: true
                        ))
                    }
                    solutionIndex += 1
                }
                
                if solutionIndex < solutionArray.count {
                    finalCells.append(cell)
                    solutionIndex += 1
                }
            } else {
                // Just add symbols directly
                finalCells.append(cell)
            }
        }
        
        // Check if there are any remaining spaces in the solution
        while solutionIndex < solutionArray.count {
            if solutionArray[solutionIndex] == " " {
                finalCells.append(CryptogramCell(
                    position: finalCells.count,
                    encodedChar: " ",
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
            if component.allSatisfy({ $0.isNumber }) {
                // This is a number representing a letter in the solution
                if solutionIndex < solutionArray.count {
                    cells.append(CryptogramCell(
                        position: position,
                        encodedChar: component,
                        solutionChar: solutionArray[solutionIndex],
                        isSymbol: false
                    ))
                    solutionIndex += 1
                    position += 1
                }
            } else if component.allSatisfy({ $0.isPunctuation || $0.isSymbol }) {
                // This is punctuation or a symbol
                cells.append(CryptogramCell(
                    position: position,
                    encodedChar: component,
                    isSymbol: true
                ))
                position += 1
            } else if component.count > 1 {
                // This might be multiple characters (rare case)
                print("Warning: Multi-character component in number encoding: \(component)")
                
                // If it contains any numbers, it might need to map to solution
                let hasNumbers = component.contains(where: { $0.isNumber })
                
                cells.append(CryptogramCell(
                    position: position,
                    encodedChar: component,
                    solutionChar: hasNumbers && solutionIndex < solutionArray.count ? solutionArray[solutionIndex] : nil,
                    isSymbol: !hasNumbers
                ))
                
                if hasNumbers {
                    solutionIndex += 1
                }
                position += 1
            }
        }
        
        // Add spaces between words based on solution
        var wordIndex = 0
        var cellsWithSpaces: [CryptogramCell] = []
        
        for cell in cells {
            cellsWithSpaces.append(cell)
            
            // If this cell maps to a solution letter and the next letter in the solution is a space,
            // add a visual space cell
            if !cell.isSymbol, 
               let currentSolutionChar = cell.solutionChar,
               wordIndex + 1 < solution.count,
               Array(solution)[wordIndex + 1] == " " {
                
                cellsWithSpaces.append(CryptogramCell(
                    position: cellsWithSpaces.count,
                    encodedChar: " ",
                    isSymbol: true
                ))
            }
            
            if !cell.isSymbol {
                wordIndex += 1
            }
        }
        
        // Debug information
        print("Number encoded puzzle: \(encodedText)")
        print("Solution: \(solution)")
        print("Created \(cellsWithSpaces.count) cells, \(solutionIndex) mapped to solution characters")
        
        return cellsWithSpaces
    }
} 
