
//
//  MigrationUtility.swift
//  simple cryptogram
//
//  Created on 25/05/2025.
//

import Foundation
import SwiftUI

/// Utility class for migrating settings from @AppStorage to AppSettings
class MigrationUtility {
    
    /// Migrate settings from @AppStorage to AppSettings
    /// @AppStorage values take precedence over existing values
    @MainActor
    static func migrateFromAppStorage(to settings: AppSettings) {
        let defaults = UserDefaults.standard
        
        // Game Settings
        if let encodingType = defaults.string(forKey: "encodingType") {
            settings.encodingType = encodingType
        }
        
        if defaults.object(forKey: "autoSubmitLetter") != nil {
            settings.autoSubmitLetter = defaults.bool(forKey: "autoSubmitLetter")
        }
        
        // UI Settings
        if let navBarLayoutValue = defaults.string(forKey: "navBarLayout"),
           let layout = NavigationBarLayout(rawValue: navBarLayoutValue) {
            settings.navigationBarLayout = layout
        }
        
        if let textSizeValue = defaults.string(forKey: "textSize"),
           let textSize = TextSizeOption(rawValue: textSizeValue) {
            settings.textSize = textSize
        }
        
        if defaults.object(forKey: "soundFeedbackEnabled") != nil {
            settings.soundFeedbackEnabled = defaults.bool(forKey: "soundFeedbackEnabled")
        }
        
        if defaults.object(forKey: "hapticFeedbackEnabled") != nil {
            settings.hapticFeedbackEnabled = defaults.bool(forKey: "hapticFeedbackEnabled")
        }
        
        // Theme Settings
        if defaults.object(forKey: "isDarkMode") != nil {
            settings.isDarkMode = defaults.bool(forKey: "isDarkMode")
        }
        
        if defaults.object(forKey: "highContrastMode") != nil {
            settings.highContrastMode = defaults.bool(forKey: "highContrastMode")
        }
        
        // Daily Puzzle State
        if defaults.object(forKey: "lastCompletedDailyPuzzleID") != nil {
            settings.lastCompletedDailyPuzzleID = defaults.integer(forKey: "lastCompletedDailyPuzzleID")
        }
        
    }

    /// Check if migration is needed based on stored version
    static func isMigrationNeeded(currentVersion: Int, storedVersion: Int) -> Bool {
        return storedVersion < currentVersion
    }
}
