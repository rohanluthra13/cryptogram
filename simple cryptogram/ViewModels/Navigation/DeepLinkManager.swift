import Foundation
import SwiftUI

/// Handles deep linking and URL navigation for the app
@MainActor
class DeepLinkManager: ObservableObject {
    
    // MARK: - Deep Link Types
    enum DeepLink: Equatable {
        case home
        case puzzle(id: Int)
        case dailyPuzzle(date: Date?)
        case stats
        case settings
        
        /// Parse URL into DeepLink
        static func parse(from url: URL) -> DeepLink? {
            guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
                return nil
            }
            
            let pathComponents = components.path.split(separator: "/").map(String.init)
            
            guard let firstComponent = pathComponents.first else {
                return .home
            }
            
            switch firstComponent {
            case "home":
                return .home
                
            case "puzzle":
                if pathComponents.count > 1,
                   let puzzleId = Int(pathComponents[1]) {
                    return .puzzle(id: puzzleId)
                }
                return nil
                
            case "daily":
                if pathComponents.count > 1 {
                    let dateString = pathComponents[1]
                    if let date = DateFormatter.iso8601.date(from: dateString) {
                        return .dailyPuzzle(date: date)
                    }
                }
                return .dailyPuzzle(date: nil) // Today's puzzle
                
            case "stats":
                return .stats
                
            case "settings":
                return .settings
                
            default:
                return nil
            }
        }
        
        /// Convert DeepLink to URL
        var url: URL? {
            var path: String
            
            switch self {
            case .home:
                path = "cryptogram://home"
            case .puzzle(let id):
                path = "cryptogram://puzzle/\(id)"
            case .dailyPuzzle(let date):
                if let date = date {
                    let dateString = DateFormatter.iso8601.string(from: date)
                    path = "cryptogram://daily/\(dateString)"
                } else {
                    path = "cryptogram://daily"
                }
            case .stats:
                path = "cryptogram://stats"
            case .settings:
                path = "cryptogram://settings"
            }
            
            return URL(string: path)
        }
    }
    
    // MARK: - Properties
    @Published var pendingDeepLink: DeepLink?
    
    private weak var navigationState: NavigationState?
    private weak var businessLogic: BusinessLogicCoordinator?
    private let databaseService = DatabaseService.shared
    
    // MARK: - Initialization
    func configure(navigationState: NavigationState, businessLogic: BusinessLogicCoordinator) {
        self.navigationState = navigationState
        self.businessLogic = businessLogic
    }
    
    // MARK: - Deep Link Handling
    
    /// Handle incoming URL
    func handle(url: URL) {
        guard let deepLink = DeepLink.parse(from: url) else {
            print("Failed to parse deep link: \(url)")
            return
        }
        
        // Store the deep link if navigation isn't ready yet
        if navigationState == nil || businessLogic == nil {
            pendingDeepLink = deepLink
            return
        }
        
        handleDeepLink(deepLink)
    }
    
    /// Process pending deep link if any
    func processPendingDeepLink() {
        guard let deepLink = pendingDeepLink else { return }
        pendingDeepLink = nil
        handleDeepLink(deepLink)
    }
    
    /// Handle a specific deep link
    private func handleDeepLink(_ deepLink: DeepLink) {
        guard let navigationState = navigationState,
              let businessLogic = businessLogic else {
            pendingDeepLink = deepLink
            return
        }
        
        switch deepLink {
        case .home:
            navigationState.navigateToHome()
            
        case .puzzle(let id):
            Task {
                await navigateToPuzzle(withId: id)
            }
            
        case .dailyPuzzle(let date):
            Task {
                await navigateToDailyPuzzle(date: date)
            }
            
        case .stats:
            if navigationState.isOnHomeScreen {
                navigationState.presentOverlay(.stats)
            } else {
                navigationState.navigateToHome()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    navigationState.presentOverlay(.stats)
                }
            }
            
        case .settings:
            if navigationState.isOnHomeScreen {
                navigationState.presentOverlay(.settings)
            } else {
                navigationState.navigateToHome()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    navigationState.presentOverlay(.settings)
                }
            }
        }
    }
    
    // MARK: - Navigation Helpers
    
    private func navigateToPuzzle(withId id: Int) async {
        do {
            guard let puzzle = try databaseService.fetchPuzzleById(id) else {
                print("Puzzle with id \(id) not found")
                return
            }
            await MainActor.run {
                businessLogic?.startNewPuzzle(puzzle: puzzle)
                navigationState?.navigateToPuzzle(puzzle)
            }
        } catch {
            print("Failed to load puzzle with id \(id): \(error)")
        }
    }
    
    private func navigateToDailyPuzzle(date: Date?) async {
        let targetDate = date ?? Date()
        await MainActor.run {
            businessLogic?.loadDailyPuzzle(for: targetDate)
            if let puzzle = businessLogic?.currentPuzzle {
                navigationState?.navigateToPuzzle(puzzle)
            }
        }
    }
}

// MARK: - DateFormatter Extension

extension DateFormatter {
    static let iso8601: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter
    }()
}