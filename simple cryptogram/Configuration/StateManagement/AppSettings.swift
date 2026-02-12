import Foundation
import SwiftUI
import Observation

/// Central settings manager for the application.
/// Reads/writes directly to UserDefaults — no abstraction layer.
@MainActor
@Observable final class AppSettings {
    // MARK: - Game Settings
    var encodingType: String = "Letters" {
        didSet { defaults.set(encodingType, forKey: "appSettings.encodingType") }
    }

    var selectedDifficulties: [String] = ["easy", "medium", "hard"] {
        didSet { defaults.set(selectedDifficulties, forKey: "appSettings.selectedDifficulties") }
    }

    var autoSubmitLetter: Bool = false {
        didSet { defaults.set(autoSubmitLetter, forKey: "appSettings.autoSubmitLetter") }
    }

    // MARK: - UI Settings
    var navigationBarLayout: NavigationBarLayout = .centerLayout {
        didSet { defaults.set(navigationBarLayout.rawValue, forKey: "appSettings.navigationBarLayout") }
    }

    var textSize: TextSizeOption = .medium {
        didSet { defaults.set(textSize.rawValue, forKey: "appSettings.textSize") }
    }

    var fontFamily: FontOption = .system {
        didSet { defaults.set(fontFamily.rawValue, forKey: "appSettings.fontFamily") }
    }

    var soundFeedbackEnabled: Bool = true {
        didSet { defaults.set(soundFeedbackEnabled, forKey: "appSettings.soundFeedbackEnabled") }
    }

    var hapticFeedbackEnabled: Bool = true {
        didSet { defaults.set(hapticFeedbackEnabled, forKey: "appSettings.hapticFeedbackEnabled") }
    }

    // MARK: - Navigation State
    var shouldShowCalendarOnReturn: Bool = false

    // MARK: - Theme Settings
    var isDarkMode: Bool = false {
        didSet { defaults.set(isDarkMode, forKey: "appSettings.isDarkMode") }
    }

    var highContrastMode: Bool = false {
        didSet { defaults.set(highContrastMode, forKey: "appSettings.highContrastMode") }
    }

    // MARK: - Daily Puzzle State
    var lastCompletedDailyPuzzleID: Int = 0 {
        didSet { defaults.set(lastCompletedDailyPuzzleID, forKey: "appSettings.lastCompletedDailyPuzzleID") }
    }

    // MARK: - Quote Length Display (absorbed from SettingsViewModel)

    var quoteLengthDisplayText: String {
        let hasEasy = selectedDifficulties.contains("easy")
        let hasMedium = selectedDifficulties.contains("medium")
        let hasHard = selectedDifficulties.contains("hard")

        if hasEasy && hasMedium && hasHard { return "all" }
        if hasEasy && !hasMedium && !hasHard { return "short" }
        if !hasEasy && hasMedium && !hasHard { return "medium" }
        if !hasEasy && !hasMedium && hasHard { return "long" }
        if hasEasy && hasMedium && !hasHard { return "short & medium" }
        if !hasEasy && hasMedium && hasHard { return "medium & long" }
        if hasEasy && !hasMedium && hasHard { return "short & long" }
        return "custom"
    }

    func isLengthSelected(_ length: String) -> Bool {
        selectedDifficulties.contains(length)
    }

    func toggleLength(_ length: String) {
        if isLengthSelected(length) {
            guard selectedDifficulties.count > 1 else { return }
            selectedDifficulties.removeAll { $0 == length }
        } else {
            selectedDifficulties.append(length)
        }
    }

    // MARK: - Singleton

    private static var _shared: AppSettings?

    @MainActor
    static var shared: AppSettings {
        get {
            if let existing = _shared { return existing }
            let instance = AppSettings()
            _shared = instance
            return instance
        }
        set { _shared = newValue }
    }

    // MARK: - Storage

    private let defaults: Foundation.UserDefaults

    // MARK: - Initialization

    init(defaults: Foundation.UserDefaults = .standard) {
        self.defaults = defaults
        loadSettings()
        migrateFromAppStorageIfNeeded()
        savedDefaults = SavedDefaults()
        snapshotCurrentAsDefaults()
    }

    // MARK: - Loading

    private func loadSettings() {
        if let v = defaults.string(forKey: "appSettings.encodingType") { encodingType = v }
        if let v = defaults.stringArray(forKey: "appSettings.selectedDifficulties") { selectedDifficulties = v }
        if defaults.object(forKey: "appSettings.autoSubmitLetter") != nil { autoSubmitLetter = defaults.bool(forKey: "appSettings.autoSubmitLetter") }

        if let raw = defaults.string(forKey: "appSettings.navigationBarLayout"),
           let v = NavigationBarLayout(rawValue: raw) { navigationBarLayout = v }
        if let raw = defaults.string(forKey: "appSettings.textSize"),
           let v = TextSizeOption(rawValue: raw) { textSize = v }
        if let raw = defaults.string(forKey: "appSettings.fontFamily"),
           let v = FontOption(rawValue: raw) { fontFamily = v }
        if defaults.object(forKey: "appSettings.soundFeedbackEnabled") != nil { soundFeedbackEnabled = defaults.bool(forKey: "appSettings.soundFeedbackEnabled") }
        if defaults.object(forKey: "appSettings.hapticFeedbackEnabled") != nil { hapticFeedbackEnabled = defaults.bool(forKey: "appSettings.hapticFeedbackEnabled") }
        if defaults.object(forKey: "appSettings.isDarkMode") != nil { isDarkMode = defaults.bool(forKey: "appSettings.isDarkMode") }
        if defaults.object(forKey: "appSettings.highContrastMode") != nil { highContrastMode = defaults.bool(forKey: "appSettings.highContrastMode") }
        if defaults.object(forKey: "appSettings.lastCompletedDailyPuzzleID") != nil { lastCompletedDailyPuzzleID = defaults.integer(forKey: "appSettings.lastCompletedDailyPuzzleID") }
    }

    // MARK: - One-Time Migration from Legacy @AppStorage Keys

    private static let settingsVersion = 1

    private func migrateFromAppStorageIfNeeded() {
        let storedVersion = defaults.integer(forKey: "appSettings.migratedVersion")
        guard storedVersion < Self.settingsVersion else { return }

        // Migrate from old @AppStorage keys to appSettings.* keys
        if let v = defaults.string(forKey: "encodingType") { encodingType = v }
        if defaults.object(forKey: "autoSubmitLetter") != nil { autoSubmitLetter = defaults.bool(forKey: "autoSubmitLetter") }
        if let raw = defaults.string(forKey: "navBarLayout"),
           let v = NavigationBarLayout(rawValue: raw) { navigationBarLayout = v }
        if let raw = defaults.string(forKey: "textSize"),
           let v = TextSizeOption(rawValue: raw) { textSize = v }
        if defaults.object(forKey: "soundFeedbackEnabled") != nil { soundFeedbackEnabled = defaults.bool(forKey: "soundFeedbackEnabled") }
        if defaults.object(forKey: "hapticFeedbackEnabled") != nil { hapticFeedbackEnabled = defaults.bool(forKey: "hapticFeedbackEnabled") }
        if defaults.object(forKey: "isDarkMode") != nil { isDarkMode = defaults.bool(forKey: "isDarkMode") }
        if defaults.object(forKey: "highContrastMode") != nil { highContrastMode = defaults.bool(forKey: "highContrastMode") }
        if defaults.object(forKey: "lastCompletedDailyPuzzleID") != nil { lastCompletedDailyPuzzleID = defaults.integer(forKey: "lastCompletedDailyPuzzleID") }

        defaults.set(Self.settingsVersion, forKey: "appSettings.migratedVersion")
    }

    // MARK: - Reset

    private struct SavedDefaults {
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

    private var savedDefaults = SavedDefaults()

    private func snapshotCurrentAsDefaults() {
        savedDefaults = SavedDefaults(
            encodingType: encodingType,
            selectedDifficulties: selectedDifficulties,
            autoSubmitLetter: autoSubmitLetter,
            navigationBarLayout: navigationBarLayout,
            textSize: textSize,
            fontFamily: fontFamily,
            soundFeedbackEnabled: soundFeedbackEnabled,
            hapticFeedbackEnabled: hapticFeedbackEnabled,
            isDarkMode: isDarkMode,
            highContrastMode: highContrastMode
        )
    }

    func reset() {
        encodingType = savedDefaults.encodingType
        selectedDifficulties = savedDefaults.selectedDifficulties
        autoSubmitLetter = savedDefaults.autoSubmitLetter
        navigationBarLayout = savedDefaults.navigationBarLayout
        textSize = savedDefaults.textSize
        fontFamily = savedDefaults.fontFamily
        soundFeedbackEnabled = savedDefaults.soundFeedbackEnabled
        hapticFeedbackEnabled = savedDefaults.hapticFeedbackEnabled
        isDarkMode = savedDefaults.isDarkMode
        highContrastMode = savedDefaults.highContrastMode
    }

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
        snapshotCurrentAsDefaults()
    }

    func saveAsUserDefaults() {
        snapshotCurrentAsDefaults()
    }
}
