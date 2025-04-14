import SwiftUI

struct UserSettings {
    static let difficultyModeKey = "difficultyMode"

    static var currentMode: DifficultyMode {
        get {
            let storedValue = UserDefaults.standard.string(forKey: difficultyModeKey) ?? DifficultyMode.normal.rawValue
            return DifficultyMode(rawValue: storedValue) ?? .normal
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: difficultyModeKey)
        }
    }

    // Note: Using UserDefaults directly instead of @AppStorage because 
    // @AppStorage requires a View context or property wrapper usage,
    // which isn't ideal for a static helper like this.
    // Functionality remains the same.
} 