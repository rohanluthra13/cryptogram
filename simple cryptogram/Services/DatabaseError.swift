import Foundation

enum DatabaseError: LocalizedError, Equatable {
    case initializationFailed(String)
    case connectionFailed
    case queryFailed(String)
    case dataCorrupted(String)
    case migrationFailed(String)
    case noDataFound
    case invalidData(String)
    case fileSystemError(String)
    
    var errorDescription: String? {
        switch self {
        case .initializationFailed(let reason):
            return "Unable to initialize database: \(reason)"
        case .connectionFailed:
            return "Failed to connect to the database"
        case .queryFailed(let query):
            return "Database query failed: \(query)"
        case .dataCorrupted(let details):
            return "Database contains corrupted data: \(details)"
        case .migrationFailed(let migration):
            return "Failed to apply database migration: \(migration)"
        case .noDataFound:
            return "No data found"
        case .invalidData(let details):
            return "Invalid data encountered: \(details)"
        case .fileSystemError(let error):
            return "File system error: \(error)"
        }
    }
    
    var userFriendlyMessage: String {
        switch self {
        case .initializationFailed, .connectionFailed:
            return "Unable to load puzzle data. Please try restarting the app."
        case .queryFailed, .dataCorrupted, .invalidData:
            return "There was an error loading your puzzle. Please try again."
        case .migrationFailed:
            return "Unable to update the app's data. Please reinstall the app if this persists."
        case .noDataFound:
            return "No puzzles available. Please check your internet connection."
        case .fileSystemError:
            return "Storage error occurred. Please check your device has available space."
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .initializationFailed, .connectionFailed:
            return "Try closing and reopening the app. If the problem persists, reinstall the app."
        case .queryFailed, .dataCorrupted, .invalidData:
            return "Try refreshing the puzzle or selecting a different one."
        case .migrationFailed:
            return "Back up your progress and reinstall the app."
        case .noDataFound:
            return "Check your internet connection and try again."
        case .fileSystemError:
            return "Free up storage space on your device and try again."
        }
    }
}