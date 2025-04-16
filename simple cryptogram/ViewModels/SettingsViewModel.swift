import SwiftUI
import Combine

class SettingsViewModel: ObservableObject {
    @Published var selectedMode: DifficultyMode = UserSettings.currentMode
    @Published var selectedNavBarLayout: NavigationBarLayout = UserSettings.navigationBarLayout
    @Published var selectedLengths: [String] = UserSettings.selectedDifficulties
    
    private var modeCancellable: AnyCancellable?
    private var navBarLayoutCancellable: AnyCancellable?
    private var lengthCancellable: AnyCancellable?
    
    // Notification name for difficulty selection changes
    static let difficultySelectionChangedNotification = Notification.Name("DifficultySelectionChanged")

    // Computed property for the quote length dropdown display text
    var quoteRangeDisplayText: String {
        let hasEasy = selectedLengths.contains("easy")
        let hasMedium = selectedLengths.contains("medium")
        let hasHard = selectedLengths.contains("hard")
        
        // Show "all" when all options are selected
        if hasEasy && hasMedium && hasHard {
            return "all"
        }
        
        // Show specific ranges based on selections
        if hasEasy && !hasMedium && !hasHard {
            return "less than 50"
        }
        
        if hasEasy && hasMedium && !hasHard {
            return "less than 100"
        }
        
        if !hasEasy && hasMedium && !hasHard {
            return "50 to 100"
        }
        
        if !hasEasy && !hasMedium && hasHard {
            return "100 +"
        }
        
        if !hasEasy && hasMedium && hasHard {
            return "50 +"
        }
        
        if hasEasy && !hasMedium && hasHard {
            return "mixed"
        }
        
        // Fallback (shouldn't happen with current UI constraints)
        return "custom"
    }

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
            
        lengthCancellable = $selectedLengths
            .dropFirst()
            .sink { newLengths in
                UserSettings.selectedDifficulties = newLengths
                // Post notification when difficulty selection changes
                NotificationCenter.default.post(name: Self.difficultySelectionChangedNotification, object: nil)
            }
    }
    
    // Methods for length selection
    func isLengthSelected(_ length: String) -> Bool {
        return selectedLengths.contains(length)
    }
    
    func toggleLength(_ length: String) {
        if isLengthSelected(length) {
            // Don't allow deselecting if it's the only option left
            if selectedLengths.count > 1 {
                selectedLengths.removeAll { $0 == length }
            }
        } else {
            selectedLengths.append(length)
        }
    }
} 