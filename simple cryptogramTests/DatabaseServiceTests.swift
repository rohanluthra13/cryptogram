import Testing
@testable import simple_cryptogram
import SQLite
import Foundation

struct DatabaseServiceTests {
    
    private func cleanupTestDatabase() {
        let fileManager = FileManager.default
        if let documentsURL = try? fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false) {
            let testDBPath = documentsURL.appendingPathComponent("quotes.db")
            try? fileManager.removeItem(at: testDBPath)
        }
    }
    
    // MARK: - Initialization Tests
    
    @Test func databaseInitialization() {
        // DatabaseService.shared should initialize without errors
        let db = DatabaseService.shared
        #expect(db.db != nil, "Database connection should be established")
    }
    
    // MARK: - Error Handling Tests
    
    @Test func fetchRandomPuzzleWithValidDatabase() async throws {
        let difficulties = ["easy", "medium", "hard"]
        
        do {
            let puzzle = try DatabaseService.shared.fetchRandomPuzzle(encodingType: "Letters", selectedDifficulties: difficulties)
            #expect(puzzle != nil, "Should fetch a puzzle successfully when database is valid")
        } catch {
            Issue.record("Valid database should not throw error: \(error)")
        }
    }
    
    @Test func fetchPuzzleByIdWithInvalidId() async throws {
        // Test fetching with an ID that doesn't exist
        do {
            let puzzle = try DatabaseService.shared.fetchPuzzleById(-999, encodingType: "Letters")
            #expect(puzzle == nil, "Should return nil for non-existent ID")
        } catch let error as DatabaseError {
            switch error {
            case .noDataFound:
                // This is expected
                break
            default:
                Issue.record("Expected noDataFound error, got: \(error)")
            }
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }
    
    // MARK: - Query Tests
    
    @Test func fetchRandomPuzzleWithDifficulties() async throws {
        // Test with easy difficulty
        let easyPuzzle = try DatabaseService.shared.fetchRandomPuzzle(encodingType: "Letters", selectedDifficulties: ["easy"])
        #expect(easyPuzzle?.difficulty == "easy", "Should return puzzle with requested difficulty")
        
        // Test with medium difficulty
        let mediumPuzzle = try DatabaseService.shared.fetchRandomPuzzle(encodingType: "Letters", selectedDifficulties: ["medium"])
        #expect(mediumPuzzle?.difficulty == "medium", "Should return puzzle with requested difficulty")
        
        // Test with all difficulties
        let anyPuzzle = try DatabaseService.shared.fetchRandomPuzzle(encodingType: "Letters", selectedDifficulties: ["easy", "medium", "hard"])
        #expect(["easy", "medium", "hard"].contains(anyPuzzle?.difficulty ?? ""), "Should return puzzle with one of requested difficulties")
    }
    
    @Test func fetchRandomPuzzleExcludesCurrent() async throws {
        // Get a puzzle
        let firstPuzzle = try DatabaseService.shared.fetchRandomPuzzle(encodingType: "Letters", selectedDifficulties: ["easy", "medium", "hard"])
        #expect(firstPuzzle != nil)
        
        // Get another puzzle, excluding the first
        let secondPuzzle = try DatabaseService.shared.fetchRandomPuzzle(current: firstPuzzle, encodingType: "Letters", selectedDifficulties: ["easy", "medium", "hard"])
        #expect(secondPuzzle != nil)
        
        // Verify they're different
        if let first = firstPuzzle, let second = secondPuzzle {
            #expect(first.quoteId != second.quoteId, "Should return a different puzzle when excluding current")
        }
    }
    
    @Test func fetchPuzzleWithDifferentEncodingTypes() async throws {
        // Test letter encoding
        let letterPuzzle = try DatabaseService.shared.fetchRandomPuzzle(encodingType: "Letters", selectedDifficulties: ["easy", "medium", "hard"])
        #expect(letterPuzzle != nil)
        #expect(!(letterPuzzle?.encodedText.isEmpty ?? true), "Letter encoded text should not be empty")
        
        // Test number encoding
        let numberPuzzle = try DatabaseService.shared.fetchRandomPuzzle(encodingType: "Numbers", selectedDifficulties: ["easy", "medium", "hard"])
        #expect(numberPuzzle != nil)
        #expect(!(numberPuzzle?.encodedText.isEmpty ?? true), "Number encoded text should not be empty")
        
        // Verify they have different encodings for the same puzzle if we fetch by ID
        if let quoteId = letterPuzzle?.quoteId {
            let sameLetterPuzzle = try DatabaseService.shared.fetchPuzzleById(quoteId, encodingType: "Letters")
            let sameNumberPuzzle = try DatabaseService.shared.fetchPuzzleById(quoteId, encodingType: "Numbers")
            
            #expect(sameLetterPuzzle?.encodedText != sameNumberPuzzle?.encodedText, 
                    "Same puzzle should have different encodings for Letters vs Numbers")
        }
    }
    
    // MARK: - Daily Puzzle Tests
    
    @Test func fetchDailyPuzzle() async throws {
        let today = Date()
        let dailyPuzzle = try DatabaseService.shared.fetchDailyPuzzle(for: today, encodingType: "Letters")
        
        // We may or may not have a daily puzzle for today
        if dailyPuzzle != nil {
            #expect(dailyPuzzle?.solution != nil, "Daily puzzle should have a solution")
            #expect(dailyPuzzle?.author != nil, "Daily puzzle should have an author")
        }
    }
    
    @Test func dailyPuzzlesExcludedFromRandom() async throws {
        // This test verifies that daily puzzles don't appear in random selection
        // Get some random puzzles and verify none are from daily_puzzles table
        var randomIds: Set<Int> = []
        
        for _ in 0..<10 {
            if let puzzle = try DatabaseService.shared.fetchRandomPuzzle(encodingType: "Letters", selectedDifficulties: ["easy", "medium", "hard"]) {
                randomIds.insert(puzzle.quoteId)
            }
        }
        
        // Check these IDs against daily puzzles
        if let db = DatabaseService.shared.db {
            let dailyPuzzlesTable = Table("daily_puzzles")
            let quoteId = Expression<Int>("quote_id")
            
            do {
                let dailyIds = try db.prepare(dailyPuzzlesTable.select(quoteId)).map { $0[quoteId] }
                let intersection = randomIds.intersection(Set(dailyIds))
                #expect(intersection.isEmpty, "Random puzzles should not include daily puzzles")
            } catch {
                // If daily_puzzles table doesn't exist, that's ok
            }
        }
    }
    
    // MARK: - Author Tests
    
    @Test func fetchAuthorInfo() async throws {
        // Get a puzzle first
        guard let puzzle = try DatabaseService.shared.fetchRandomPuzzle(encodingType: "Letters", selectedDifficulties: ["easy", "medium", "hard"]) else {
            Issue.record("Should be able to fetch a puzzle")
            return
        }
        
        let authorInfo = try await DatabaseService.shared.fetchAuthor(byName: puzzle.author)
        
        // Author info might not exist for all authors
        if let info = authorInfo {
            #expect(info.name == puzzle.author, "Author name should match")
            // Summary might be empty but should exist
            #expect(info.summary != nil)
        }
    }
    
    // MARK: - Error Recovery Tests
    
    @Test func databaseErrorMessages() {
        // Test that errors have appropriate user-friendly messages
        let errors: [DatabaseError] = [
            .connectionFailed,
            .queryFailed("Test query failure"),
            .migrationFailed("Test migration failure"),
            .initializationFailed("Test init failure"),
            .fileSystemError("Test file error"),
            .noDataFound
        ]
        
        for error in errors {
            #expect(!error.userFriendlyMessage.isEmpty, "Error should have user-friendly message")
            #expect(!(error.recoverySuggestion?.isEmpty ?? true), "Error should have recovery suggestion")
        }
    }
}