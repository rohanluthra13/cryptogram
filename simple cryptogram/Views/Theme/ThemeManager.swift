import SwiftUI
import Observation

@MainActor
@Observable
final class ThemeManager {

    var isDarkMode: Bool {
        get { AppSettings.shared.isDarkMode }
        set { AppSettings.shared.isDarkMode = newValue }
    }

    func toggleTheme() {
        isDarkMode.toggle()
    }
}
