import SwiftUI

/// Legacy UserSettings - Forwarding layer during migration to AppSettings
/// This struct is maintained for backward compatibility during the transition period.
/// TODO: Delete this file after confirming all code uses AppSettings directly.
struct UserSettings {
    static let navigationBarLayoutKey = "navigationBarLayout"
    static let selectedDifficultiesKey = "selectedDifficulties"

    // MARK: - Migration Helper Methods

    /// Check if settings need migration from old UserDefaults keys
    static func needsMigration() -> Bool {
        let defaults = UserDefaults.standard
        return defaults.object(forKey: navigationBarLayoutKey) != nil ||
               defaults.object(forKey: selectedDifficultiesKey) != nil
    }

    /// Clean up old UserDefaults keys after successful migration
    static func cleanupOldKeys() {
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: navigationBarLayoutKey)
        defaults.removeObject(forKey: selectedDifficultiesKey)
        defaults.synchronize()
    }
} 