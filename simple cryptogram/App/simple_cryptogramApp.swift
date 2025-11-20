import SwiftUI

@main
struct simple_cryptogramApp: App {
    @State private var appSettings: AppSettings
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var viewModel: PuzzleViewModel
    @StateObject private var themeManager = ThemeManager()
    @StateObject private var settingsViewModel = SettingsViewModel()
    @StateObject private var deepLinkManager = DeepLinkManager()
    
    init() {
        // Use the automatically initialized singleton (static let)
        _appSettings = State(wrappedValue: AppSettings.shared)

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
