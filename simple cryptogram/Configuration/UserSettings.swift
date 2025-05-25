import SwiftUI

/// Legacy UserSettings - Forwarding layer during migration to AppSettings
/// This struct is maintained for backward compatibility during the transition period.
/// All methods now forward to the centralized AppSettings instance.
/// TODO: This will be deprecated after user validation of the new AppSettings system.
struct UserSettings {
    static let difficultyModeKey = "difficultyMode"
    static let navigationBarLayoutKey = "navigationBarLayout"
    static let selectedDifficultiesKey = "selectedDifficulties"
    
    // Notification name for layout changes
    static let navigationBarLayoutChangedNotification = Notification.Name("NavigationBarLayoutChanged")

    @MainActor
    static var currentMode: DifficultyMode {
        get {
            return AppSettings.shared?.difficultyMode ?? .normal
        }
        set {
            AppSettings.shared?.difficultyMode = newValue
        }
    }
    
    /// Legacy property maintained for compatibility
    @MainActor
    static var difficultyMode: DifficultyMode {
        get { currentMode }
        set { currentMode = newValue }
    }
    
    @MainActor
    static var navigationBarLayout: NavigationBarLayout {
        get {
            return AppSettings.shared?.navigationBarLayout ?? .centerLayout
        }
        set {
            AppSettings.shared?.navigationBarLayout = newValue
            // Post notification for backward compatibility
            NotificationCenter.default.post(name: navigationBarLayoutChangedNotification, object: nil)
        }
    }
    
    @MainActor
    static var selectedDifficulties: [String] {
        get {
            return AppSettings.shared?.selectedDifficulties ?? ["easy", "medium", "hard"]
        }
        set {
            AppSettings.shared?.selectedDifficulties = newValue
        }
    }

    // MARK: - Migration Helper Methods
    
    /// Check if settings need migration from old UserDefaults keys
    static func needsMigration() -> Bool {
        // Check if any old keys exist that haven't been migrated
        let defaults = UserDefaults.standard
        return defaults.object(forKey: difficultyModeKey) != nil ||
               defaults.object(forKey: navigationBarLayoutKey) != nil ||
               defaults.object(forKey: selectedDifficultiesKey) != nil
    }
    
    /// Clean up old UserDefaults keys after successful migration
    /// This should only be called after confirming AppSettings is working correctly
    static func cleanupOldKeys() {
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: difficultyModeKey)
        defaults.removeObject(forKey: navigationBarLayoutKey)
        defaults.removeObject(forKey: selectedDifficultiesKey)
        defaults.synchronize()
    }
} 