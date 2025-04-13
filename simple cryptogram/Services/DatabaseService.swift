import Foundation
import SQLite

class DatabaseService {
    static let shared = DatabaseService()
    private var db: Connection?
    private let databaseFileName = "quotes.db"
    private var isInitialized = false
    
    private init() {
        setupDatabase()
    }
    
    private func setupDatabase() {
        do {
            print("Starting database setup...")
            print("Looking for database file: \(databaseFileName)")
            
            // First try to find the database in the data directory
            let dataDirectoryPath = Bundle.main.bundlePath.appending("/data/\(databaseFileName)")
            print("Checking data directory path: \(dataDirectoryPath)")
            
            if FileManager.default.fileExists(atPath: dataDirectoryPath) {
                print("Found database in data directory")
                db = try Connection(dataDirectoryPath, readonly: true)
                print("Successfully connected to data directory database")
                isInitialized = true
                return
            }
            
            // If not in data directory, try the main bundle
            if let bundlePath = Bundle.main.path(forResource: databaseFileName, ofType: nil) {
                print("Found database in bundle at: \(bundlePath)")
                db = try Connection(bundlePath, readonly: true)
                print("Successfully connected to bundle database")
                isInitialized = true
                return
            }
            
            print("Database not found in data directory or bundle, checking documents directory")
            
            // If not in bundle, try to find it in the documents directory
            let fileManager = FileManager.default
            let documentsPath = try fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            let databasePath = documentsPath.appendingPathComponent(databaseFileName)
            
            print("Documents directory path: \(documentsPath.path)")
            print("Database path in documents: \(databasePath.path)")
            
            if !fileManager.fileExists(atPath: databasePath.path) {
                print("Database not found in documents directory")
                print("Error: Could not find \(databaseFileName) in any location")
                return
            } else {
                print("Found existing database in documents directory")
            }
            
            db = try Connection(databasePath.path)
            print("Successfully connected to documents database")
            isInitialized = true
            
        } catch {
            print("Error setting up database: \(error.localizedDescription)")
        }
    }
    
    func fetchRandomPuzzle(current: Puzzle? = nil, encodingType: String = "Letters") -> Puzzle? {
        guard let db = db else {
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
            let letterKey = Expression<String>("letter_key")
            let numberEncoded = Expression<String>("number_encoded")
            let numberKey = Expression<String>("number_key")
            
            // Start with a random query
            var randomQuery = quotesTable.select(id, quoteText, author, length, difficulty, createdAt)
                .order(Expression<Int>.random())
            
            // If we have a current puzzle, exclude it from the results
            if let currentPuzzle = current,
               let currentId = Int(currentPuzzle.id.uuidString) {
                randomQuery = randomQuery.filter(id != currentId)
            }
            
            // Limit to 1 result
            randomQuery = randomQuery.limit(1)
            
            if let quoteRow = try db.pluck(randomQuery),
               let encodedRow = try db.pluck(encodedQuotesTable.filter(quoteId == quoteRow[id])) {
                
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                _ = dateFormatter.date(from: quoteRow[createdAt])
                
                // Select the encoded text based on encoding type
                let encodedText = encodingType == "Numbers" ? encodedRow[numberEncoded] : encodedRow[letterEncoded]
                
                return Puzzle(
                    id: UUID(uuidString: String(quoteRow[id])) ?? UUID(),
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
        guard let db = db else {
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
            let letterKey = Expression<String>("letter_key")
            let numberEncoded = Expression<String>("number_encoded")
            let numberKey = Expression<String>("number_key")
            
            if let quoteRow = try db.pluck(quotesTable.filter(quoteId == id)),
               let encodedRow = try db.pluck(encodedQuotesTable.filter(encodedQuoteId == id)) {
                
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                _ = dateFormatter.date(from: quoteRow[createdAt])
                
                // Select the encoded text based on encoding type
                let encodedText = encodingType == "Numbers" ? encodedRow[numberEncoded] : encodedRow[letterEncoded]
                
                return Puzzle(
                    id: UUID(uuidString: String(quoteRow[quoteId])) ?? UUID(),
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
}


