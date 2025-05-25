import SwiftUI
import Combine

@MainActor
class SettingsViewModel: ObservableObject {
    // Direct references to AppSettings properties
    private let appSettings = AppSettings.shared
    private var cancellables = Set<AnyCancellable>()
    
    // Notification name for difficulty selection changes
    static let difficultySelectionChangedNotification = Notification.Name("DifficultySelectionChanged")
    
    // Computed properties that forward to AppSettings
    var selectedMode: DifficultyMode {
        get { appSettings.difficultyMode }
        set { appSettings.difficultyMode = newValue }
    }
    
    var selectedNavBarLayout: NavigationBarLayout {
        get { appSettings.navigationBarLayout }
        set { appSettings.navigationBarLayout = newValue }
    }
    
    var selectedLengths: [String] {
        get { appSettings.selectedDifficulties }
        set { 
            appSettings.selectedDifficulties = newValue
            // Post notification when difficulty selection changes
            NotificationCenter.default.post(name: Self.difficultySelectionChangedNotification, object: nil)
        }
    }
    
    var textSize: TextSizeOption {
        get { appSettings.textSize }
        set { appSettings.textSize = newValue }
    }

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
        // Forward AppSettings changes to trigger view updates
        appSettings.objectWillChange
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
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