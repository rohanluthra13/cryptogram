import SwiftUI

struct UserSettings {
    static let difficultyModeKey = "difficultyMode"
    static let navigationBarLayoutKey = "navigationBarLayout"
    
    // Notification name for layout changes
    static let navigationBarLayoutChangedNotification = Notification.Name("NavigationBarLayoutChanged")

    static var currentMode: DifficultyMode {
        get {
            let storedValue = UserDefaults.standard.string(forKey: difficultyModeKey) ?? DifficultyMode.normal.rawValue
            return DifficultyMode(rawValue: storedValue) ?? .normal
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: difficultyModeKey)
        }
    }
    
    static var navigationBarLayout: NavigationBarLayout {
        get {
            let storedValue = UserDefaults.standard.string(forKey: navigationBarLayoutKey) ?? NavigationBarLayout.centerLayout.rawValue
            return NavigationBarLayout(rawValue: storedValue) ?? .centerLayout
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: navigationBarLayoutKey)
            // Post notification when the layout changes
            NotificationCenter.default.post(name: navigationBarLayoutChangedNotification, object: nil)
        }
    }

    // Note: Using UserDefaults directly instead of @AppStorage because 
    // @AppStorage requires a View context or property wrapper usage,
    // which isn't ideal for a static helper like this.
    // Functionality remains the same.
} 