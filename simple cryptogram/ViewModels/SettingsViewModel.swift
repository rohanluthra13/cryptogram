import SwiftUI
import Combine

class SettingsViewModel: ObservableObject {
    @Published var selectedMode: DifficultyMode = UserSettings.currentMode
    @Published var selectedNavBarLayout: NavigationBarLayout = UserSettings.navigationBarLayout
    
    private var modeCancellable: AnyCancellable?
    private var navBarLayoutCancellable: AnyCancellable?

    init() {
        // No need to read initial value here, @Published already uses UserSettings values
        
        // Sink changes from the @Published properties back to UserSettings
        modeCancellable = $selectedMode
            .dropFirst() // Don't write the initial value back
            .sink { newMode in
                UserSettings.currentMode = newMode
            }
            
        navBarLayoutCancellable = $selectedNavBarLayout
            .dropFirst() // Don't write the initial value back
            .sink { newLayout in
                UserSettings.navigationBarLayout = newLayout
            }
    }
} 