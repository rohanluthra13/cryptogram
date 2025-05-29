import SwiftUI

@main
struct simple_cryptogramApp: App {
    @StateObject private var appSettings: AppSettings
    @StateObject private var viewModel: PuzzleViewModel
    @StateObject private var themeManager = ThemeManager()
    @StateObject private var settingsViewModel = SettingsViewModel()
    
    init() {
        // Create AppSettings instance on main thread first
        let settings = AppSettings()
        AppSettings.shared = settings
        _appSettings = StateObject(wrappedValue: settings)
        
        // Now create ViewModels that depend on AppSettings
        _viewModel = StateObject(wrappedValue: PuzzleViewModel())
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appSettings)
                .environmentObject(viewModel)
                .environmentObject(themeManager)
                .environmentObject(settingsViewModel)
                .preferredColorScheme(appSettings.isDarkMode ? .dark : .light)
        }
    }
}
