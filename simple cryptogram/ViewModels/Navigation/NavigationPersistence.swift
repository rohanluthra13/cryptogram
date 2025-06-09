import Foundation
import SwiftUI
import ObjectiveC
import Combine

/// Handles persistence of navigation state across app launches
@MainActor
class NavigationPersistence {
    
    // MARK: - Constants
    private enum Keys {
        static let currentScreen = "navigation.currentScreen"
        static let navigationHistory = "navigation.history"
        static let lastPuzzleId = "navigation.lastPuzzleId"
        static let lastOpenedDate = "navigation.lastOpenedDate"
    }
    
    // MARK: - Properties
    private let userDefaults = UserDefaults.standard
    
    // MARK: - Persistence Methods
    
    /// Save current navigation state
    func save(navigationState: NavigationState) {
        // Save current screen
        switch navigationState.currentScreen {
        case .home:
            userDefaults.set("home", forKey: Keys.currentScreen)
            userDefaults.removeObject(forKey: Keys.lastPuzzleId)
        case .puzzle(let puzzle):
            userDefaults.set("puzzle", forKey: Keys.currentScreen)
            userDefaults.set(puzzle.quoteId, forKey: Keys.lastPuzzleId)
        }
        
        // Save navigation history
        let historyData = navigationState.navigationHistory.compactMap { screen -> [String: Any]? in
            switch screen {
            case .home:
                return ["type": "home"]
            case .puzzle(let puzzle):
                return ["type": "puzzle", "id": puzzle.quoteId]
            }
        }
        
        if let encoded = try? JSONSerialization.data(withJSONObject: historyData) {
            userDefaults.set(encoded, forKey: Keys.navigationHistory)
        }
        
        // Save timestamp
        userDefaults.set(Date(), forKey: Keys.lastOpenedDate)
    }
    
    /// Restore navigation state
    func restore(to navigationState: NavigationState, businessLogic: BusinessLogicCoordinator) async {
        // Check if we should restore (only if app was opened recently)
        if let lastOpened = userDefaults.object(forKey: Keys.lastOpenedDate) as? Date {
            let timeSinceLastOpen = Date().timeIntervalSince(lastOpened)
            
            // Don't restore if more than 1 hour has passed
            if timeSinceLastOpen > 3600 {
                clearSavedState()
                return
            }
        }
        
        // Restore navigation history
        if let historyData = userDefaults.data(forKey: Keys.navigationHistory),
           let history = try? JSONSerialization.jsonObject(with: historyData) as? [[String: Any]] {
            
            var restoredHistory: [Screen] = []
            
            for item in history {
                if let type = item["type"] as? String {
                    switch type {
                    case "home":
                        restoredHistory.append(.home)
                    case "puzzle":
                        if let puzzleId = item["id"] as? Int {
                            do {
                                if let puzzle = try DatabaseService.shared.fetchPuzzleById(puzzleId) {
                                    restoredHistory.append(.puzzle(puzzle))
                                }
                            } catch {
                                // Skip if puzzle can't be loaded
                                print("Failed to restore puzzle \(puzzleId): \(error)")
                            }
                        }
                    default:
                        break
                    }
                }
            }
            
            // Update navigation history
            navigationState.navigationHistory = restoredHistory
        }
        
        // Restore current screen
        if let screenType = userDefaults.string(forKey: Keys.currentScreen) {
            switch screenType {
            case "home":
                navigationState.navigateToHome()
                
            case "puzzle":
                if let puzzleId = userDefaults.object(forKey: Keys.lastPuzzleId) as? Int {
                    do {
                        guard let puzzle = try DatabaseService.shared.fetchPuzzleById(puzzleId) else {
                            print("Failed to restore puzzle with id \(puzzleId) - not found")
                            navigationState.navigateToHome()
                            return
                        }
                        
                        // Check if it's a daily puzzle
                        if let dailyPuzzle = try DatabaseService.shared.fetchDailyPuzzle(for: Date()),
                           dailyPuzzle.quoteId == puzzle.quoteId {
                            businessLogic.loadDailyPuzzle(for: Date())
                        } else {
                            businessLogic.startNewPuzzle(puzzle: puzzle)
                        }
                        
                        navigationState.navigateToPuzzle(puzzle)
                    } catch {
                        print("Failed to restore puzzle navigation: \(error)")
                        navigationState.navigateToHome()
                    }
                }
                
            default:
                navigationState.navigateToHome()
            }
        }
    }
    
    /// Clear saved navigation state
    func clearSavedState() {
        userDefaults.removeObject(forKey: Keys.currentScreen)
        userDefaults.removeObject(forKey: Keys.navigationHistory)
        userDefaults.removeObject(forKey: Keys.lastPuzzleId)
        userDefaults.removeObject(forKey: Keys.lastOpenedDate)
    }
    
    // MARK: - State Queries
    
    /// Check if there's saved navigation state
    var hasSavedState: Bool {
        return userDefaults.string(forKey: Keys.currentScreen) != nil
    }
    
    /// Get the last opened date
    var lastOpenedDate: Date? {
        return userDefaults.object(forKey: Keys.lastOpenedDate) as? Date
    }
}

// MARK: - NavigationState Extension

extension NavigationState {
    private static var persistenceKey: UInt8 = 0
    
    /// Navigation persistence manager
    var persistence: NavigationPersistence {
        get {
            if let existing = objc_getAssociatedObject(self, &NavigationState.persistenceKey) as? NavigationPersistence {
                return existing
            }
            let new = NavigationPersistence()
            objc_setAssociatedObject(self, &NavigationState.persistenceKey, new, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            return new
        }
    }
    
    /// Enable automatic persistence
    func enablePersistence() {
        // Save state on significant changes
        $currentScreen
            .debounce(for: .seconds(0.5), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.persistence.save(navigationState: self)
            }
            .store(in: &cancellables)
        
        $navigationHistory
            .debounce(for: .seconds(0.5), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.persistence.save(navigationState: self)
            }
            .store(in: &cancellables)
    }
    
    /// Restore persisted navigation state
    func restorePersistedState(businessLogic: BusinessLogicCoordinator) async {
        await persistence.restore(to: self, businessLogic: businessLogic)
    }
}

// MARK: - App Lifecycle Integration

extension View {
    /// Modifier to enable navigation persistence
    func navigationPersistence(navigationState: NavigationState, businessLogic: BusinessLogicCoordinator) -> some View {
        self
            .onAppear {
                Task {
                    await navigationState.restorePersistedState(businessLogic: businessLogic)
                    navigationState.enablePersistence()
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
                navigationState.persistence.save(navigationState: navigationState)
            }
    }
}