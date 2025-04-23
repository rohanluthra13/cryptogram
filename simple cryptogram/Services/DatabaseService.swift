import Foundation
import SQLite

class DatabaseService {
    static let shared = DatabaseService()
    private var _db: Connection?
    private let databaseFileName = "quotes.db"
    private var isInitialized = false
    
    private init() {
        setupDatabase()
    }
    
    private func setupDatabase() {
        let fileManager = FileManager.default
        let databaseFileName = "quotes.db"
        // Path to the app's Documents directory
        let documentsURL = try! fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        print("[DatabaseService] Documents directory: \(documentsURL.path)")
        let destinationURL = documentsURL.appendingPathComponent(databaseFileName)

        // Path to the bundled database in the app bundle
        guard let bundleDBPath = Bundle.main.path(forResource: "quotes", ofType: "db") else {
            print("Error: Could not find quotes.db in bundle.")
            return
        }

        // Copy the DB from the bundle to Documents if it doesn't already exist there
        if !fileManager.fileExists(atPath: destinationURL.path) {
            do {
                try fileManager.copyItem(atPath: bundleDBPath, toPath: destinationURL.path)
                print("Copied quotes.db to Documents directory.")
            } catch {
                print("Error copying quotes.db to Documents: \(error)")
                return
            }
        } else {
            print("quotes.db already exists in Documents directory.")
        }

        // Now open the DB from the Documents directory (read-write)
        do {
            _db = try Connection(destinationURL.path)
            print("Successfully connected to writable database in Documents.")
            isInitialized = true
        } catch {
            print("Error opening writable database: \(error)")
        }
    }
    
    // Make the database connection accessible for progress tracking and other services
    var db: Connection? { _db }
    
    func fetchRandomPuzzle(current: Puzzle? = nil, encodingType: String = "Letters", selectedDifficulties: [String] = UserSettings.selectedDifficulties) -> Puzzle? {
        guard let db = _db else {
            print("Error: Database not initialized")
            return nil
        }
        do {
            let quotesTable = Table("quotes")
            let encodedQuotesTable = Table("encoded_quotes")
            let id = Expression<Int>("id")
            let quoteText = Expression<String>("quote_text")
            let author = Expression<String>("author")
            let length = Expression<Int>("length")
            let difficulty = Expression<String>("difficulty")
            let createdAt = Expression<String>("created_at")
            let quoteId = Expression<Int>("quote_id")
            let letterEncoded = Expression<String>("letter_encoded")
            let _ = Expression<String>("letter_key")
            let numberEncoded = Expression<String>("number_encoded")
            let _ = Expression<String>("number_key")
            // Start with a random query, excluding daily puzzle quotes
            var randomQuery = quotesTable
                .select(id, quoteText, author, length, difficulty, createdAt)
                .filter(!Expression<Bool>("id IN (SELECT quote_id FROM daily_puzzles)"))
            if !selectedDifficulties.isEmpty {
                randomQuery = randomQuery.filter(selectedDifficulties.contains(difficulty))
            }
            randomQuery = randomQuery.order(Expression<Int>.random())
            if let currentPuzzle = current {
                randomQuery = randomQuery.filter(id != currentPuzzle.quoteId)
            }
            randomQuery = randomQuery.limit(1)
            if let quoteRow = try db.pluck(randomQuery),
               let encodedRow = try db.pluck(encodedQuotesTable.filter(quoteId == quoteRow[id])) {
                let encodedText = encodingType == "Numbers" ? encodedRow[numberEncoded] : encodedRow[letterEncoded]
                return Puzzle(
                    id: UUID(uuidString: String(quoteRow[id])) ?? UUID(),
                    quoteId: quoteRow[id],
                    encodedText: encodedText,
                    solution: quoteRow[quoteText],
                    hint: "Author: \(quoteRow[author])",
                    author: quoteRow[author],
                    difficulty: quoteRow[difficulty],
                    length: quoteRow[length]
                )
            }
        } catch {
            print("Error fetching random puzzle: \(error.localizedDescription)")
        }
        return nil
    }
    
    func fetchPuzzleById(_ id: Int, encodingType: String = "Letters") -> Puzzle? {
        guard let db = _db else {
            print("Error: Database not initialized")
            return nil
        }
        do {
            let quotesTable = Table("quotes")
            let encodedQuotesTable = Table("encoded_quotes")
            let quoteId = Expression<Int>("id")
            let quoteText = Expression<String>("quote_text")
            let author = Expression<String>("author")
            let length = Expression<Int>("length")
            let difficulty = Expression<String>("difficulty")
            let createdAt = Expression<String>("created_at")
            let encodedQuoteId = Expression<Int>("quote_id")
            let letterEncoded = Expression<String>("letter_encoded")
            let _ = Expression<String>("letter_key")
            let numberEncoded = Expression<String>("number_encoded")
            let _ = Expression<String>("number_key")
            if let quoteRow = try db.pluck(quotesTable.filter(quoteId == id)),
               let encodedRow = try db.pluck(encodedQuotesTable.filter(encodedQuoteId == id)) {
                let encodedText = encodingType == "Numbers" ? encodedRow[numberEncoded] : encodedRow[letterEncoded]
                return Puzzle(
                    id: UUID(uuidString: String(id)) ?? UUID(),
                    quoteId: id,
                    encodedText: encodedText,
                    solution: quoteRow[quoteText],
                    hint: "Author: \(quoteRow[author])",
                    author: quoteRow[author],
                    difficulty: quoteRow[difficulty],
                    length: quoteRow[length]
                )
            }
        } catch {
            print("Error fetching puzzle by ID: \(error.localizedDescription)")
        }
        return nil
    }
    
    /// Fetch an Author record by name
    func fetchAuthor(byName name: String) async -> Author? {
        guard let db = _db else {
            print("Error: Database not initialized")
            return nil
        }
        do {
            let authorsTable = Table("authors")
            let idExpr = Expression<Int>("id")
            let nameExpr = Expression<String>("name")
            let fullNameExpr = Expression<String?>("full_name")
            let birthDateExpr = Expression<String?>("birth_date")
            let deathDateExpr = Expression<String?>("death_date")
            let pobExpr = Expression<String?>("place_of_birth")
            let podExpr = Expression<String?>("place_of_death")
            let summaryExpr = Expression<String?>("summary")
            let query = authorsTable.filter(nameExpr == name)
            if let row = try db.pluck(query) {
                return Author(
                    id: row[idExpr],
                    name: row[nameExpr],
                    fullName: row[fullNameExpr],
                    birthDate: row[birthDateExpr],
                    deathDate: row[deathDateExpr],
                    placeOfBirth: row[pobExpr],
                    placeOfDeath: row[podExpr],
                    summary: row[summaryExpr]
                )
            }
        } catch {
            print("Error fetching author: \(error)")
        }
        return nil
    }
    
    /// Fetch the daily puzzle for a given date (default: today)
    func fetchDailyPuzzle(for date: Date = Date(), encodingType: String = "Letters") -> Puzzle? {
        guard let db = _db else {
            print("Error: Database not initialized")
            return nil
        }
        // Format date as yyyy-MM-dd
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: date)
        do {
            let dailyPuzzlesTable = Table("daily_puzzles")
            let quotesTable = Table("quotes")
            let encodedQuotesTable = Table("encoded_quotes")
            let id = Expression<Int>("id")
            let quoteId = Expression<Int>("quote_id")
            let puzzleDate = Expression<String>("puzzle_date")
            let quoteText = Expression<String>("quote_text")
            let author = Expression<String>("author")
            let length = Expression<Int>("length")
            let difficulty = Expression<String>("difficulty")
            let createdAt = Expression<String>("created_at")
            let encodedQuoteId = Expression<Int>("quote_id")
            let letterEncoded = Expression<String>("letter_encoded")
            let _ = Expression<String>("letter_key")
            let numberEncoded = Expression<String>("number_encoded")
            let _ = Expression<String>("number_key")

            // Find the daily puzzle for the specified date
            if let dailyRow = try db.pluck(dailyPuzzlesTable.filter(puzzleDate == dateString)) {
                let qid = dailyRow[quoteId]
                // Get the quote row
                if let quoteRow = try db.pluck(quotesTable.filter(id == qid)),
                   let encodedRow = try db.pluck(encodedQuotesTable.filter(encodedQuoteId == qid)) {
                    // Select the encoded text based on encoding type
                    let encodedText = encodingType == "Numbers" ? encodedRow[numberEncoded] : encodedRow[letterEncoded]
                    return Puzzle(
                        id: UUID(uuidString: String(qid)) ?? UUID(),
                        quoteId: qid,
                        encodedText: encodedText,
                        solution: quoteRow[quoteText],
                        hint: "Author: \(quoteRow[author])",
                        author: quoteRow[author],
                        difficulty: quoteRow[difficulty],
                        length: quoteRow[length]
                    )
                }
            }
        } catch {
            print("Error fetching daily puzzle: \(error.localizedDescription)")
        }
        return nil
    }
}
