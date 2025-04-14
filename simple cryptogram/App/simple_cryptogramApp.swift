import SwiftUI

@main
struct simple_cryptogramApp: App {
    @StateObject private var viewModel = PuzzleViewModel()
    @StateObject private var themeManager = ThemeManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(viewModel)
                .environmentObject(themeManager)
                .preferredColorScheme(UserDefaults.standard.bool(forKey: "isDarkMode") ? .dark : .light)
        }
    }
}

