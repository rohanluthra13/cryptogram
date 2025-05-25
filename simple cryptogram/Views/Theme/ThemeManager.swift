import SwiftUI
import Combine

@MainActor
class ThemeManager: ObservableObject {
    private var cancellables = Set<AnyCancellable>()
    
    var isDarkMode: Bool {
        get { AppSettings.shared?.isDarkMode ?? false }
        set { 
            AppSettings.shared?.isDarkMode = newValue
            applyTheme()
        }
    }
    
    init() {
        // Set initial appearance on app launch
        applyTheme()
        
        // Listen for AppSettings changes
        AppSettings.shared?.objectWillChange
            .sink { [weak self] _ in
                self?.objectWillChange.send()
                self?.applyTheme()
            }
            .store(in: &cancellables)
    }
    
    func toggleTheme() {
        isDarkMode.toggle()
        applyTheme()
    }
    
    func applyTheme() {
        setSystemAppearance(isDark: AppSettings.shared?.isDarkMode ?? false)
    }
    
    private func setSystemAppearance(isDark: Bool) {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.overrideUserInterfaceStyle = isDark ? .dark : .light
        }
    }
} 