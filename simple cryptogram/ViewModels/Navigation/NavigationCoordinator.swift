//
//  NavigationCoordinator.swift
//  simple cryptogram
//
//  Created on 29/05/2025.
//

import SwiftUI

/// Legacy NavigationCoordinator maintained for backward compatibility
/// New code should use NavigationState directly
final class NavigationCoordinator: ObservableObject {
    // MARK: - Navigation State
    
    /// Navigation path for puzzle navigation
    @Published var navigationPath = NavigationPath()
    
    // MARK: - Navigation Methods
    
    /// Navigate to puzzle view with specified puzzle
    func navigateToPuzzle(_ puzzle: Puzzle) {
        navigationPath.append(puzzle)
    }
    
    /// Navigate back to home
    func navigateToHome() {
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