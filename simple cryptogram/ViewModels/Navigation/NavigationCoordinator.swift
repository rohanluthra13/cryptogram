//
//  NavigationCoordinator.swift
//  simple cryptogram
//
//  Created on 29/05/2025.
//

import SwiftUI

/// Centralized navigation state management using modern NavigationStack
final class NavigationCoordinator: ObservableObject {
    // MARK: - Navigation State
    
    /// Navigation path for puzzle navigation
    @Published var navigationPath = NavigationPath()
    
    /// Controls whether the puzzle view is shown
    @Published var showPuzzle = false
    
    /// Current puzzle being played (if any)
    @Published var currentPuzzle: Puzzle?
    
    /// Difficulty for random puzzle selection
    @Published var selectedDifficulty: String?
    
    // MARK: - Navigation Methods
    
    /// Navigate to puzzle view with specified puzzle
    func navigateToPuzzle(_ puzzle: Puzzle, difficulty: String? = nil) {
        self.currentPuzzle = puzzle
        self.selectedDifficulty = difficulty
        self.showPuzzle = true
        navigationPath.append(puzzle)
    }
    
    /// Navigate back to home
    func navigateToHome() {
        self.showPuzzle = false
        self.currentPuzzle = nil
        self.selectedDifficulty = nil
        navigationPath.removeLast(navigationPath.count)
        
        // Post notification to reset HomeView state
        NotificationCenter.default.post(name: .resetHomeViewState, object: nil)
    }
}