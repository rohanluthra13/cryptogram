import Foundation

#if DEBUG
struct CryptogramCellTests {
    static func runTests() {
        print("=== Running Cryptogram Cell Tests ===")
        
        testLetterEncoding()
        testComplexLetterEncoding()
        testNumberEncoding()
        
        print("=== Tests Complete ===")
    }
    
    static func testLetterEncoding() {
        print("Testing Letter Encoding...")
        
        let puzzle = Puzzle(
            encodedText: "ABC DEF",
            solution: "XYZ MNO",
            hint: "Test puzzle"
        )
        
        let cells = puzzle.createCells(encodingType: "Letters")
        
        // Validate cell count - now we should have 7 cells (3 letters + space + 3 letters)
        print("Letter encoding cell count: \(cells.count)")
        assert(cells.count == 7, "Expected 7 cells but got \(cells.count)")
        
        // Validate first few letter cells
        assert(cells[0].encodedChar == "A", "Expected 'A' but got '\(cells[0].encodedChar)'")
        assert(cells[0].solutionChar == "X", "Expected 'X' but got '\(String(describing: cells[0].solutionChar))'")
        assert(!cells[0].isSymbol, "Cell 0 should not be a symbol")
        
        // Validate space is created from solution, not encoded text
        assert(cells[3].encodedChar == " ", "Expected space but got '\(cells[3].encodedChar)'")
        assert(cells[3].isSymbol, "Cell 3 should be a symbol")
        
        // Validate cells after the space
        assert(cells[4].encodedChar == "D", "Expected 'D' but got '\(cells[4].encodedChar)'")
        assert(cells[4].solutionChar == "M", "Expected 'M' but got '\(String(describing: cells[4].solutionChar))'")
        
        print("Letter encoding test passed!")
    }
    
    static func testComplexLetterEncoding() {
        print("Testing Complex Letter Encoding...")
        
        let puzzle = Puzzle(
            encodedText: "ABC, DEF GHI!",
            solution: "XYZ, MNO PQR!",
            hint: "Complex test puzzle"
        )
        
        let cells = puzzle.createCells(encodingType: "Letters")
        
        // Validate cell count - should have correct number including punctuation and spaces
        print("Complex letter encoding cell count: \(cells.count)")
        
        // Validate first few cells
        assert(cells[0].encodedChar == "A", "Expected 'A' but got '\(cells[0].encodedChar)'")
        assert(cells[0].solutionChar == "X", "Expected 'X' but got '\(String(describing: cells[0].solutionChar))'")
        
        // Find comma position
        let commaIndex = cells.firstIndex(where: { $0.encodedChar == "," })
        assert(commaIndex != nil, "Comma not found in cells")
        if let idx = commaIndex {
            assert(cells[idx].isSymbol, "Comma should be marked as a symbol")
        }
        
        // Find space after comma
        let spaceAfterCommaIndex = cells.firstIndex(where: { $0.encodedChar == " " && $0.isSymbol })
        assert(spaceAfterCommaIndex != nil, "Space after comma not found")
        
        // Test cell after first space
        if let spaceIdx = spaceAfterCommaIndex, spaceIdx + 1 < cells.count {
            assert(cells[spaceIdx + 1].encodedChar == "D", "Expected 'D' after space but got '\(cells[spaceIdx + 1].encodedChar)'")
            assert(cells[spaceIdx + 1].solutionChar == "M", "Expected 'M' but got '\(String(describing: cells[spaceIdx + 1].solutionChar))'")
        }
        
        // Find second space (between words)
        let secondSpaceIndex = cells.lastIndex(where: { $0.encodedChar == " " && $0.isSymbol })
        assert(secondSpaceIndex != nil, "Second space not found")
        
        // Test cell after second space
        if let spaceIdx = secondSpaceIndex, spaceIdx + 1 < cells.count {
            assert(cells[spaceIdx + 1].encodedChar == "G", "Expected 'G' after second space but got '\(cells[spaceIdx + 1].encodedChar)'")
            assert(cells[spaceIdx + 1].solutionChar == "P", "Expected 'P' but got '\(String(describing: cells[spaceIdx + 1].solutionChar))'")
        }
        
        // Test exclamation mark
        let exclamationIndex = cells.firstIndex(where: { $0.encodedChar == "!" })
        assert(exclamationIndex != nil, "Exclamation mark not found")
        if let idx = exclamationIndex {
            assert(cells[idx].isSymbol, "Exclamation mark should be marked as a symbol")
        }
        
        print("Complex letter encoding test passed!")
    }
    
    static func testNumberEncoding() {
        print("Testing Number Encoding...")
        
        // Use a more realistic number encoding format from the database
        // Where each number is separated by spaces
        let puzzle = Puzzle(
            encodedText: "12 13 8 12 9 11 22 17 , 24 9 13 2 .",
            solution: "HE WHO CAN, DOES.",
            hint: "Test numeric puzzle"
        )
        
        let cells = puzzle.createCells(encodingType: "Numbers")
        
        // Validate cell count - should have 15 cells total (9 numbers for letters + punctuation + spaces)
        print("Cell count: \(cells.count)")
        assert(cells.count == 15, "Expected 15 cells but got \(cells.count)")
        
        // Validate first few cells
        assert(cells[0].encodedChar == "12", "Expected '12' but got '\(cells[0].encodedChar)'")
        assert(cells[0].solutionChar == "H", "Expected 'H' but got '\(String(describing: cells[0].solutionChar))'")
        assert(!cells[0].isSymbol, "Cell 0 should not be a symbol")
        
        // Validate spaces
        assert(cells[1].encodedChar == " ", "Expected space but got '\(cells[1].encodedChar)'")
        assert(cells[1].isSymbol, "Cell 1 should be a symbol")
        
        // Validate punctuation
        assert(cells[8].encodedChar == ",", "Expected ',' but got '\(cells[8].encodedChar)'")
        assert(cells[8].isSymbol, "Cell 8 should be a symbol")
        
        print("Number encoding test passed!")
    }
}
#endif 