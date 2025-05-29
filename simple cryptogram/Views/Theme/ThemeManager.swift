import SwiftUI
import Combine

@MainActor
class ThemeManager: ObservableObject {
    
    var isDarkMode: Bool {
        get { AppSettings.shared.isDarkMode }
        set { 
            AppSettings.shared.isDarkMode = newValue
            applyTheme()
        }
    }
    
    init() {
        // Set initial appearance on app launch
        applyTheme()
    }
    
    func toggleTheme() {
        isDarkMode.toggle()
        applyTheme()
    }
    
    func applyTheme() {
        setSystemAppearance(isDark: AppSettings.shared.isDarkMode)
    }
    
    private func setSystemAppearance(isDark: Bool) {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.overrideUserInterfaceStyle = isDark ? .dark : .light
        }
    }
} 