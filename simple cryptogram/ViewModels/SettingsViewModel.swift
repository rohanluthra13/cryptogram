import SwiftUI
import Combine

class SettingsViewModel: ObservableObject {
    @Published var selectedMode: DifficultyMode = UserSettings.currentMode
    private var cancellable: AnyCancellable?

    init() {
        // No need to read initial value here, @Published already uses UserSettings.currentMode
        
        // Sink changes from the @Published property back to UserSettings
        cancellable = $selectedMode
            .dropFirst() // Don't write the initial value back
            .sink { newMode in
                UserSettings.currentMode = newMode
            }
    }
} 