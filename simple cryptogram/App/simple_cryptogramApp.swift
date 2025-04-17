import SwiftUI

@main
struct simple_cryptogramApp: App {
    @StateObject private var viewModel = PuzzleViewModel()
    @StateObject private var themeManager = ThemeManager()
    @StateObject private var settingsViewModel = SettingsViewModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(viewModel)
                .environmentObject(themeManager)
                .environmentObject(settingsViewModel)
                .preferredColorScheme(UserDefaults.standard.bool(forKey: "isDarkMode") ? .dark : .light)
        }
    }
}
