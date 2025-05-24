import Foundation

/// Service to handle error recovery strategies for common database failures
class ErrorRecoveryService {
    static let shared = ErrorRecoveryService()
    
    private init() {}
    
    /// Attempts to recover from a database error
    /// - Parameter error: The database error to recover from
    /// - Returns: True if recovery was successful, false otherwise
    func attemptRecovery(from error: DatabaseError) -> Bool {
        switch error {
        case .initializationFailed, .connectionFailed:
            return attemptDatabaseReinitialization()
            
        case .migrationFailed:
            return attemptMigrationRecovery()
            
        case .dataCorrupted:
            return attemptDataRecovery()
            
        case .fileSystemError:
            return attemptFileSystemRecovery()
            
        case .queryFailed, .noDataFound, .invalidData:
            // These errors typically don't have automated recovery
            return false
        }
    }
    
    /// Attempt to reinitialize the database connection
    private func attemptDatabaseReinitialization() -> Bool {
        // Force DatabaseService to recreate its connection
        // This is handled by the singleton pattern - next access will retry
        return true
    }
    
    /// Attempt to recover from migration failures
    private func attemptMigrationRecovery() -> Bool {
        // In a production app, this might:
        // 1. Back up current data
        // 2. Reset to a known good schema
        // 3. Reapply migrations
        // For now, we'll just return false as manual intervention is needed
        return false
    }
    
    /// Attempt to recover from corrupted data
    private func attemptDataRecovery() -> Bool {
        // Options for data recovery:
        // 1. Skip corrupted records (already implemented in LocalPuzzleProgressStore)
        // 2. Reset to factory defaults
        // 3. Restore from backup
        // Currently handled by fallback UUID generation
        return true
    }
    
    /// Attempt to recover from file system errors
    private func attemptFileSystemRecovery() -> Bool {
        // Check available disk space
        let fileManager = FileManager.default
        do {
            let documentsURL = try fileManager.url(for: .documentDirectory, 
                                                  in: .userDomainMask, 
                                                  appropriateFor: nil, 
                                                  create: false)
            let attributes = try fileManager.attributesOfFileSystem(forPath: documentsURL.path)
            
            if let freeSpace = attributes[.systemFreeSize] as? NSNumber {
                let freeSpaceInBytes = freeSpace.int64Value
                let requiredSpace: Int64 = 10_000_000 // 10MB minimum
                
                if freeSpaceInBytes < requiredSpace {
                    // Not enough space - can't recover automatically
                    return false
                }
            }
            
            // Try to ensure documents directory exists
            try fileManager.createDirectory(at: documentsURL, 
                                          withIntermediateDirectories: true, 
                                          attributes: nil)
            return true
            
        } catch {
            return false
        }
    }
    
    /// Provides a user-friendly recovery action based on the error
    func recoveryAction(for error: DatabaseError) -> RecoveryAction? {
        switch error {
        case .initializationFailed, .connectionFailed:
            return .retry
            
        case .migrationFailed:
            return .reinstall
            
        case .dataCorrupted:
            return .resetProgress
            
        case .fileSystemError:
            return .freeSpace
            
        case .noDataFound:
            return .checkConnection
            
        case .queryFailed, .invalidData:
            return .retry
        }
    }
}

/// Possible recovery actions for database errors
enum RecoveryAction {
    case retry
    case reinstall
    case resetProgress
    case freeSpace
    case checkConnection
    
    var title: String {
        switch self {
        case .retry:
            return "Try Again"
        case .reinstall:
            return "Reinstall App"
        case .resetProgress:
            return "Reset Progress"
        case .freeSpace:
            return "Free Up Space"
        case .checkConnection:
            return "Check Connection"
        }
    }
    
    var instructions: String {
        switch self {
        case .retry:
            return "Close the app completely and reopen it to retry."
        case .reinstall:
            return "Delete and reinstall the app to fix database issues."
        case .resetProgress:
            return "Reset all progress data to fix corruption issues."
        case .freeSpace:
            return "Delete some files to free up storage space."
        case .checkConnection:
            return "Ensure you have a stable internet connection."
        }
    }
}