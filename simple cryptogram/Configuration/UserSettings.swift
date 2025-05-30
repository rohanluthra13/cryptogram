import SwiftUI

/// Legacy UserSettings - Forwarding layer during migration to AppSettings
/// This struct is maintained for backward compatibility during the transition period.
/// All methods now forward to the centralized AppSettings instance.
/// TODO: This will be deprecated after user validation of the new AppSettings system.
struct UserSettings {
    static let navigationBarLayoutKey = "navigationBarLayout"
    static let selectedDifficultiesKey = "selectedDifficulties"
    
    // Notification name for layout changes
    static let navigationBarLayoutChangedNotification = Notification.Name("NavigationBarLayoutChanged")

    @MainActor
    static var navigationBarLayout: NavigationBarLayout {
        get {
            // Return default if AppSettings isn't initialized yet
            guard let settings = AppSettings.shared else {
                return .centerLayout
            }
            return settings.navigationBarLayout
        }
        set {
            guard let settings = AppSettings.shared else { return }
            settings.navigationBarLayout = newValue
            // Post notification for backward compatibility
            NotificationCenter.default.post(name: navigationBarLayoutChangedNotification, object: nil)
        }
    }
    
    @MainActor
    static var selectedDifficulties: [String] {
        get {
            // Return default if AppSettings isn't initialized yet
            guard let settings = AppSettings.shared else {
                return ["easy", "medium", "hard"]
            }
            return settings.selectedDifficulties
        }
        set {
            guard let settings = AppSettings.shared else { return }
            settings.selectedDifficulties = newValue
        }
    }

    // MARK: - Migration Helper Methods
    
    /// Check if settings need migration from old UserDefaults keys
    static func needsMigration() -> Bool {
        // Check if any old keys exist that haven't been migrated
        let defaults = UserDefaults.standard
        return defaults.object(forKey: navigationBarLayoutKey) != nil ||
               defaults.object(forKey: selectedDifficultiesKey) != nil
    }
    
    /// Clean up old UserDefaults keys after successful migration
    /// This should only be called after confirming AppSettings is working correctly
    static func cleanupOldKeys() {
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: navigationBarLayoutKey)
        defaults.removeObject(forKey: selectedDifficultiesKey)
        defaults.synchronize()
    }
} 