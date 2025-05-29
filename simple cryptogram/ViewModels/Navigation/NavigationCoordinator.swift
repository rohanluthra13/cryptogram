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
    
    /// Currently active sheet presentation
    @Published var activeSheet: SheetType?
    
    /// Controls whether the puzzle view is shown
    @Published var showPuzzle = false
    
    /// Current puzzle being played (if any)
    @Published var currentPuzzle: Puzzle?
    
    /// Difficulty for random puzzle selection
    @Published var selectedDifficulty: String?
    
    // MARK: - Sheet Types
    
    enum SheetType: Identifiable, Equatable {
        case settings
        case statistics
        case calendar
        case info
        case authorInfo(Author)
        
        var id: String {
            switch self {
            case .settings: return "settings"
            case .statistics: return "statistics"
            case .calendar: return "calendar"
            case .info: return "info"
            case .authorInfo(let author): return "author_\(author.id)"
            }
        }
    }
    
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
    }
    
    /// Present a sheet
    func presentSheet(_ sheet: SheetType) {
        self.activeSheet = sheet
    }
    
    /// Dismiss current sheet
    func dismissSheet() {
        self.activeSheet = nil
    }
    
    /// Check if a specific sheet is active
    func isSheetActive(_ sheet: SheetType) -> Bool {
        guard let activeSheet = activeSheet else { return false }
        
        switch (activeSheet, sheet) {
        case (.settings, .settings),
             (.statistics, .statistics),
             (.calendar, .calendar),
             (.info, .info):
            return true
        case (.authorInfo(let active), .authorInfo(let check)):
            return active.id == check.id
        default:
            return false
        }
    }
}