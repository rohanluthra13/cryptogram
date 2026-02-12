import SwiftUI

@main
struct simple_cryptogramApp: App {
    @State private var appSettings: AppSettings
    @Environment(\.scenePhase) private var scenePhase
    @State private var viewModel: PuzzleViewModel
    @State private var themeManager = ThemeManager()

    init() {
        // Create AppSettings instance on main thread first
        let settings = AppSettings()
        AppSettings.shared = settings
        _appSettings = State(wrappedValue: settings)

        // Now create ViewModels that depend on AppSettings
        _viewModel = State(wrappedValue: PuzzleViewModel())
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appSettings)
                .environment(viewModel)
                .environment(themeManager)
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
