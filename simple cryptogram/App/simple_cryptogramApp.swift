import SwiftUI

@main
struct simple_cryptogramApp: App {
    @State private var appSettings: AppSettings
    @StateObject private var viewModel: PuzzleViewModel
    @StateObject private var themeManager = ThemeManager()
    @StateObject private var settingsViewModel = SettingsViewModel()
    @StateObject private var deepLinkManager = DeepLinkManager()
    
    init() {
        // Create AppSettings instance on main thread first
        let settings = AppSettings()
        AppSettings.shared = settings
        _appSettings = State(wrappedValue: settings)
        
        // Now create ViewModels that depend on AppSettings
        _viewModel = StateObject(wrappedValue: PuzzleViewModel())
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appSettings)
                .environmentObject(viewModel)
                .environmentObject(themeManager)
                .environmentObject(settingsViewModel)
                .environmentObject(deepLinkManager)
                .preferredColorScheme(appSettings.isDarkMode ? .dark : .light)
                .onOpenURL { url in
                    deepLinkManager.handle(url: url)
                }
        }
    }
}
