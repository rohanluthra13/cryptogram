import SwiftUI

class ThemeManager: ObservableObject {
    @AppStorage("isDarkMode") private var isDarkMode = false
    
    init() {
        // Set initial appearance on app launch
        applyTheme()
    }
    
    func toggleTheme() {
        isDarkMode.toggle()
        applyTheme()
    }
    
    func applyTheme() {
        setSystemAppearance(isDark: isDarkMode)
    }
    
    private func setSystemAppearance(isDark: Bool) {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.overrideUserInterfaceStyle = isDark ? .dark : .light
        }
    }
} 