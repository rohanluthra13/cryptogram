//
//  NavigationCoordinator.swift
//  simple cryptogram
//
//  Created on 29/05/2025.
//

import SwiftUI
import Observation

/// NavigationCoordinator handles NavigationStack-based navigation
@MainActor
@Observable
final class NavigationCoordinator {
    // MARK: - Navigation State

    /// Navigation path for puzzle navigation
    var navigationPath = NavigationPath()
    
    // MARK: - Navigation Methods
    
    /// Navigate to puzzle view with specified puzzle
    func navigateToPuzzle(_ puzzle: Puzzle) {
        navigationPath.append(puzzle)
    }
    
    /// Navigate back to home
    func navigateToHome() {
        if AppSettings.shared.isRandomThemeEnabled {
            AppSettings.shared.applyRandomTheme()
        }
        // Clear the entire navigation path to return to root
        navigationPath = NavigationPath()
    }
    
    /// Pop one level back in navigation
    func navigateBack() {
        if !navigationPath.isEmpty {
            navigationPath.removeLast()
        }
    }
}