import Foundation

#if DEBUG
struct CryptogramCellTests {
    static func runTests() {
        print("=== Running Cryptogram Cell Tests ===")
        
        testLetterEncoding()
        testComplexLetterEncoding()
        testNumberEncoding()
        testComplexNumberEncoding()
        
        print("=== Tests Complete ===")
    }
    
    static func testLetterEncoding() {
        print("Testing Letter Encoding...")
        
        let puzzle = Puzzle(
            encodedText: "ABC, DEF",
            solution: "XYZ, MNO",
            hint: "Test puzzle"
        )
        
        let cells = puzzle.createCells(encodingType: "Letters")
        
        // Validate cell count - now we should have 7 cells (3 letters + comma + space + 3 letters)
        print("Letter encoding cell count: \(cells.count)")
        assert(cells.count == 7, "Expected 7 cells but got \(cells.count)")
        
        // Validate first few letter cells
        assert(cells[0].encodedChar == "A", "Expected 'A' but got '\(cells[0].encodedChar)'")
        assert(cells[0].solutionChar == "X", "Expected 'X' but got '\(String(describing: cells[0].solutionChar))'")
        assert(!cells[0].isSymbol, "Cell 0 should not be a symbol")
        
        // Validate comma is created from solution, not encoded text
        assert(cells[3].encodedChar == ",", "Expected comma but got '\(cells[3].encodedChar)'")
        assert(cells[3].isSymbol, "Cell 3 should be a symbol")
        
        // Validate space after comma
        assert(cells[4].encodedChar == " ", "Expected space but got '\(cells[4].encodedChar)'")
        assert(cells[4].isSymbol, "Cell 4 should be a symbol")
        
        // Validate cells after the punctuation
        assert(cells[5].encodedChar == "D", "Expected 'D' but got '\(cells[5].encodedChar)'")
        assert(cells[5].solutionChar == "M", "Expected 'M' but got '\(String(describing: cells[5].solutionChar))'")
        
        print("Letter encoding test passed!")
    }
    
    static func testComplexLetterEncoding() {
        print("Testing Complex Letter Encoding...")
        
        let puzzle = Puzzle(
            encodedText: "ABC, DEF! GHI.",
            solution: "XYZ, MNO! PQR.",
            hint: "Complex test puzzle"
        )
        
        let cells = puzzle.createCells(encodingType: "Letters")
        
        // Validate cell count - should have correct number including punctuation and spaces
        print("Complex letter encoding cell count: \(cells.count)")
        
        // Validate first few cells
        assert(cells[0].encodedChar == "A", "Expected 'A' but got '\(cells[0].encodedChar)'")
        assert(cells[0].solutionChar == "X", "Expected 'X' but got '\(String(describing: cells[0].solutionChar))'")
        
        // Validate punctuation characters
        let commaIndex = cells.firstIndex(where: { $0.encodedChar == "," })
        assert(commaIndex != nil, "Comma not found in cells")
        if let idx = commaIndex {
            assert(cells[idx].isSymbol, "Comma should be marked as a symbol")
        }
        
        let exclamationIndex = cells.firstIndex(where: { $0.encodedChar == "!" })
        assert(exclamationIndex != nil, "Exclamation mark not found")
        if let idx = exclamationIndex {
            assert(cells[idx].isSymbol, "Exclamation mark should be marked as a symbol")
            
            // Validate that a space follows the exclamation mark as in the solution
            if idx + 1 < cells.count {
                assert(cells[idx + 1].encodedChar == " ", "Expected space after exclamation but got '\(cells[idx + 1].encodedChar)'")
                assert(cells[idx + 1].isSymbol, "Space should be a symbol")
            }
        }
        
        // Validate period at the end
        let periodIndex = cells.lastIndex(where: { $0.encodedChar == "." })
        assert(periodIndex != nil, "Period not found in cells")
        if let idx = periodIndex {
            assert(cells[idx].isSymbol, "Period should be marked as a symbol")
            assert(idx == cells.count - 1, "Period should be the last cell")
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
        
        // Validate cell count
        print("Number encoding cell count: \(cells.count)")
        
        // Find comma
        let commaIndex = cells.firstIndex(where: { $0.encodedChar == "," })
        assert(commaIndex != nil, "Comma not found in cells")
        if let idx = commaIndex {
            assert(cells[idx].isSymbol, "Comma should be marked as a symbol")
            
            // Validate space after comma
            if idx + 1 < cells.count {
                assert(cells[idx + 1].encodedChar == " ", "Expected space after comma but got '\(cells[idx + 1].encodedChar)'")
                assert(cells[idx + 1].isSymbol, "Space should be a symbol")
            }
        }
        
        // Find period
        let periodIndex = cells.lastIndex(where: { $0.encodedChar == "." })
        assert(periodIndex != nil, "Period not found")
        if let idx = periodIndex {
            assert(cells[idx].isSymbol, "Period should be a symbol")
            assert(idx == cells.count - 1, "Period should be the last cell")
        }
        
        print("Number encoding test passed!")
    }
    
    static func testComplexNumberEncoding() {
        print("Testing Complex Number Encoding...")
        
        // Use a more complex number encoding with multiple punctuation marks
        let puzzle = Puzzle(
            encodedText: "1 2 3 ' 4 5 6 , 7 8 9 ? 10 11 12 !",
            solution: "ABC'DEF, GHI? JKL!",
            hint: "Complex test numeric puzzle"
        )
        
        let cells = puzzle.createCells(encodingType: "Numbers")
        
        // Validate cell count
        print("Complex number encoding cell count: \(cells.count)")
        
        // Validate apostrophe
        let apostropheIndex = cells.firstIndex(where: { $0.encodedChar == "'" })
        assert(apostropheIndex != nil, "Apostrophe not found")
        if let idx = apostropheIndex {
            assert(cells[idx].isSymbol, "Apostrophe should be a symbol")
            
            // Validate letter after apostrophe
            if idx + 1 < cells.count {
                assert(cells[idx + 1].encodedChar == "4", "Expected '4' after apostrophe but got '\(cells[idx + 1].encodedChar)'")
                assert(cells[idx + 1].solutionChar == "D", "Expected 'D' but got '\(String(describing: cells[idx + 1].solutionChar))'")
            }
        }
        
        // Validate comma
        let commaIndex = cells.firstIndex(where: { $0.encodedChar == "," })
        assert(commaIndex != nil, "Comma not found")
        if let idx = commaIndex {
            assert(cells[idx].isSymbol, "Comma should be a symbol")
            
            // Validate space after comma
            if idx + 1 < cells.count {
                assert(cells[idx + 1].encodedChar == " ", "Expected space after comma but got '\(cells[idx + 1].encodedChar)'")
                assert(cells[idx + 1].isSymbol, "Space after comma should be a symbol")
            }
        }
        
        // Validate question mark
        let questionIndex = cells.firstIndex(where: { $0.encodedChar == "?" })
        assert(questionIndex != nil, "Question mark not found")
        if let idx = questionIndex {
            assert(cells[idx].isSymbol, "Question mark should be a symbol")
            
            // Validate space after question mark
            if idx + 1 < cells.count {
                assert(cells[idx + 1].encodedChar == " ", "Expected space after question mark but got '\(cells[idx + 1].encodedChar)'")
                assert(cells[idx + 1].isSymbol, "Space after question mark should be a symbol")
            }
        }
        
        // Validate exclamation mark as last character
        assert(cells.last?.encodedChar == "!", "Expected exclamation mark as last character but got '\(cells.last?.encodedChar ?? "nil")'")
        assert(cells.last?.isSymbol == true, "Last cell should be a symbol")
        
        print("Complex number encoding test passed!")
    }
}
#endif 