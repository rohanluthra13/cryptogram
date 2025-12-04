import SwiftUI

@main
struct simple_cryptogramApp: App {
    @State private var appSettings: AppSettings
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var viewModel: PuzzleViewModel
    @StateObject private var themeManager = ThemeManager()
    @StateObject private var settingsViewModel = SettingsViewModel()
    
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
                .preferredColorScheme(appSettings.isDarkMode ? .dark : .light)
        }
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .active:
                viewModel.resume()
            case .inactive, .background:
                viewModel.pause()
            @unknown default:
                break
            }
        }
    }
}
