//
//  AppSettings.swift
//  simple cryptogram
//
//  Created on 25/05/2025.
//

import Foundation
import SwiftUI
import Combine

/// Central settings manager for the application
@MainActor
final class AppSettings: ObservableObject {
    // MARK: - Game Settings
    @Published var encodingType: String = "Letters" {
        didSet { persistence.setValue(encodingType, for: "appSettings.encodingType") }
    }
    
    @Published var selectedDifficulties: [String] = ["easy", "medium", "hard"] {
        didSet { persistence.setValue(selectedDifficulties, for: "appSettings.selectedDifficulties") }
    }
    
    @Published var autoSubmitLetter: Bool = false {
        didSet { persistence.setValue(autoSubmitLetter, for: "appSettings.autoSubmitLetter") }
    }
    
    // MARK: - UI Settings
    @Published var navigationBarLayout: NavigationBarLayout = .centerLayout {
        didSet { persistence.setValue(navigationBarLayout.rawValue, for: "appSettings.navigationBarLayout") }
    }
    
    @Published var textSize: TextSizeOption = .medium {
        didSet { persistence.setValue(textSize.rawValue, for: "appSettings.textSize") }
    }
    
    @Published var fontFamily: FontOption = .system {
        didSet { persistence.setValue(fontFamily.rawValue, for: "appSettings.fontFamily") }
    }
    
    @Published var soundFeedbackEnabled: Bool = true {
        didSet { persistence.setValue(soundFeedbackEnabled, for: "appSettings.soundFeedbackEnabled") }
    }
    
    @Published var hapticFeedbackEnabled: Bool = true {
        didSet { persistence.setValue(hapticFeedbackEnabled, for: "appSettings.hapticFeedbackEnabled") }
    }
    
    // MARK: - Navigation State
    @Published var shouldShowCalendarOnReturn: Bool = false
    
    // MARK: - Theme Settings
    @Published var isDarkMode: Bool = false {
        didSet { persistence.setValue(isDarkMode, for: "appSettings.isDarkMode") }
    }
    
    @Published var highContrastMode: Bool = false {
        didSet { persistence.setValue(highContrastMode, for: "appSettings.highContrastMode") }
    }
    
    // MARK: - Daily Puzzle State
    @Published var lastCompletedDailyPuzzleID: Int = 0 {
        didSet { persistence.setValue(lastCompletedDailyPuzzleID, for: "appSettings.lastCompletedDailyPuzzleID") }
    }
    
    // MARK: - Migration Support
    private static let settingsVersion = 1
    @Published private var migratedVersion: Int = 0 {
        didSet { persistence.setValue(migratedVersion, for: "appSettings.migratedVersion") }
    }
    
    // MARK: - User-Defined Defaults
    private struct UserDefaults {
        var encodingType: String = "Letters"
        var selectedDifficulties: [String] = ["easy", "medium", "hard"]
        var autoSubmitLetter: Bool = false
        var navigationBarLayout: NavigationBarLayout = .centerLayout
        var textSize: TextSizeOption = .medium
        var fontFamily: FontOption = .system
        var soundFeedbackEnabled: Bool = true
        var hapticFeedbackEnabled: Bool = true
        var isDarkMode: Bool = false
        var highContrastMode: Bool = false
    }
    
    private var userDefaults = UserDefaults()
    
    // MARK: - Singleton
    // Note: shared instance is created in App struct to ensure main thread initialization
    static var shared: AppSettings!
    
    // MARK: - Dependencies
    private let persistence: PersistenceStrategy
    
    // MARK: - Initialization
    init(persistence: PersistenceStrategy = UserDefaultsPersistence()) {
        self.persistence = persistence
        loadSettings()
        performMigrationIfNeeded()
        saveCurrentAsUserDefaults()
    }
    
    // MARK: - Loading
    private func loadSettings() {
        // Game Settings
        if let encodingType = persistence.value(for: "appSettings.encodingType", type: String.self) {
            self.encodingType = encodingType
        }
        
        if let selectedDifficulties = persistence.value(for: "appSettings.selectedDifficulties", type: [String].self) {
            self.selectedDifficulties = selectedDifficulties
        }
        
        if let autoSubmitLetter = persistence.value(for: "appSettings.autoSubmitLetter", type: Bool.self) {
            self.autoSubmitLetter = autoSubmitLetter
        }
        
        // UI Settings
        if let navBarLayoutRaw = persistence.value(for: "appSettings.navigationBarLayout", type: String.self),
           let navigationBarLayout = NavigationBarLayout(rawValue: navBarLayoutRaw) {
            self.navigationBarLayout = navigationBarLayout
        }
        
        if let textSizeRaw = persistence.value(for: "appSettings.textSize", type: String.self),
           let textSize = TextSizeOption(rawValue: textSizeRaw) {
            self.textSize = textSize
        }
        
        if let fontFamilyRaw = persistence.value(for: "appSettings.fontFamily", type: String.self),
           let fontFamily = FontOption(rawValue: fontFamilyRaw) {
            self.fontFamily = fontFamily
        }
        
        if let soundFeedbackEnabled = persistence.value(for: "appSettings.soundFeedbackEnabled", type: Bool.self) {
            self.soundFeedbackEnabled = soundFeedbackEnabled
        }
        
        if let hapticFeedbackEnabled = persistence.value(for: "appSettings.hapticFeedbackEnabled", type: Bool.self) {
            self.hapticFeedbackEnabled = hapticFeedbackEnabled
        }
        
        // Theme Settings
        if let isDarkMode = persistence.value(for: "appSettings.isDarkMode", type: Bool.self) {
            self.isDarkMode = isDarkMode
        }
        
        if let highContrastMode = persistence.value(for: "appSettings.highContrastMode", type: Bool.self) {
            self.highContrastMode = highContrastMode
        }
        
        // Daily Puzzle State
        if let lastCompletedDailyPuzzleID = persistence.value(for: "appSettings.lastCompletedDailyPuzzleID", type: Int.self) {
            self.lastCompletedDailyPuzzleID = lastCompletedDailyPuzzleID
        }
        
        // Migration version
        if let migratedVersion = persistence.value(for: "appSettings.migratedVersion", type: Int.self) {
            self.migratedVersion = migratedVersion
        }
    }
    
    // MARK: - Migration
    private func performMigrationIfNeeded() {
        guard migratedVersion < Self.settingsVersion else { return }
        
        // Perform migration from @AppStorage
        MigrationUtility.migrateFromAppStorage(to: self)
        
        // Update migration version
        migratedVersion = Self.settingsVersion
        
        // Force synchronization after migration
        persistence.synchronize()
    }
    
    // MARK: - Reset Methods
    
    /// Save current settings as user defaults
    private func saveCurrentAsUserDefaults() {
        userDefaults.encodingType = encodingType
        userDefaults.selectedDifficulties = selectedDifficulties
        userDefaults.autoSubmitLetter = autoSubmitLetter
        userDefaults.navigationBarLayout = navigationBarLayout
        userDefaults.textSize = textSize
        userDefaults.fontFamily = fontFamily
        userDefaults.soundFeedbackEnabled = soundFeedbackEnabled
        userDefaults.hapticFeedbackEnabled = hapticFeedbackEnabled
        userDefaults.isDarkMode = isDarkMode
        userDefaults.highContrastMode = highContrastMode
    }
    
    /// Reset all settings to user-defined defaults
    func reset() {
        encodingType = userDefaults.encodingType
        selectedDifficulties = userDefaults.selectedDifficulties
        autoSubmitLetter = userDefaults.autoSubmitLetter
        navigationBarLayout = userDefaults.navigationBarLayout
        textSize = userDefaults.textSize
        fontFamily = userDefaults.fontFamily
        soundFeedbackEnabled = userDefaults.soundFeedbackEnabled
        hapticFeedbackEnabled = userDefaults.hapticFeedbackEnabled
        isDarkMode = userDefaults.isDarkMode
        highContrastMode = userDefaults.highContrastMode
    }
    
    /// Reset all settings to factory defaults
    func resetToFactory() {
        encodingType = "Letters"
        selectedDifficulties = ["easy", "medium", "hard"]
        autoSubmitLetter = false
        navigationBarLayout = .centerLayout
        textSize = .medium
        fontFamily = .system
        soundFeedbackEnabled = true
        hapticFeedbackEnabled = true
        isDarkMode = false
        highContrastMode = false
        
        // Also update user defaults to factory
        saveCurrentAsUserDefaults()
    }
    
    /// Update user defaults with current settings
    func saveAsUserDefaults() {
        saveCurrentAsUserDefaults()
    }
}
