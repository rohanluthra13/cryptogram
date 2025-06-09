import Foundation
import SwiftUI

/// View model specifically for HomeView
/// Handles home screen logic and puzzle selection without navigation concerns
@MainActor
class HomeViewModel: ObservableObject {
    // MARK: - Dependencies
    private let puzzleSelectionManager: PuzzleSelectionManager
    private let dailyPuzzleManager: DailyPuzzleManager
    private let databaseService: DatabaseService
    
    // MARK: - Published State
    @Published var selectedMode: PuzzleMode = .random
    @Published var showLengthSelection = false
    @Published var isLoadingPuzzle = false
    @Published var currentError: DatabaseError?
    
    // MARK: - Computed Properties
    private var encodingType: String {
        return AppSettings.shared.encodingType
    }
    
    private var selectedDifficulties: [String] {
        return AppSettings.shared.selectedDifficulties
    }
    
    /// Check if today's daily puzzle is completed
    var isDailyPuzzleCompleted: Bool {
        return dailyPuzzleManager.isTodaysDailyPuzzleCompleted()
    }
    
    // MARK: - Initialization
    init(
        puzzleSelectionManager: PuzzleSelectionManager? = nil,
        dailyPuzzleManager: DailyPuzzleManager? = nil,
        databaseService: DatabaseService? = nil
    ) {
        let dbService = databaseService ?? DatabaseService.shared
        self.databaseService = dbService
        self.puzzleSelectionManager = puzzleSelectionManager ?? PuzzleSelectionManager(
            databaseService: dbService,
            progressManager: PuzzleProgressManager(),
            statisticsManager: StatisticsManager(progressManager: PuzzleProgressManager())
        )
        self.dailyPuzzleManager = dailyPuzzleManager ?? DailyPuzzleManager(databaseService: dbService)
    }
    
    // MARK: - Puzzle Selection
    
    /// Load a random puzzle based on current settings
    func loadRandomPuzzle() async -> Puzzle? {
        isLoadingPuzzle = true
        currentError = nil
        
        do {
            let puzzle = try await puzzleSelectionManager.loadRandomPuzzle(
                encodingType: encodingType,
                difficulties: selectedDifficulties,
                excludeCompleted: false
            )
            isLoadingPuzzle = false
            return puzzle
        } catch {
            currentError = error as? DatabaseError ?? DatabaseError.connectionFailed
            isLoadingPuzzle = false
            return nil
        }
    }
    
    /// Load a puzzle with exclusions (avoid completed puzzles)
    func loadPuzzleWithExclusions() async -> Puzzle? {
        isLoadingPuzzle = true
        currentError = nil
        
        do {
            let puzzle = try await puzzleSelectionManager.loadRandomPuzzle(
                encodingType: encodingType,
                difficulties: selectedDifficulties,
                excludeCompleted: true
            )
            isLoadingPuzzle = false
            return puzzle
        } catch {
            currentError = error as? DatabaseError ?? DatabaseError.connectionFailed
            isLoadingPuzzle = false
            return nil
        }
    }
    
    /// Load today's daily puzzle
    func loadTodaysDailyPuzzle() async -> (puzzle: Puzzle, progress: DailyPuzzleProgress?)? {
        return await loadDailyPuzzle(for: Date())
    }
    
    /// Load daily puzzle for a specific date
    func loadDailyPuzzle(for date: Date) async -> (puzzle: Puzzle, progress: DailyPuzzleProgress?)? {
        isLoadingPuzzle = true
        currentError = nil
        
        do {
            let result = try dailyPuzzleManager.loadDailyPuzzle(for: date)
            isLoadingPuzzle = false
            return result
        } catch {
            currentError = error as? DatabaseError ?? DatabaseError.connectionFailed
            isLoadingPuzzle = false
            return nil
        }
    }
    
    // MARK: - UI State Management
    
    /// Handle mode selection change
    func selectMode(_ mode: PuzzleMode) {
        selectedMode = mode
        
        switch mode {
        case .random:
            showLengthSelection = true
        case .daily:
            showLengthSelection = false
        }
    }
    
    /// Reset view state (called when returning to home)
    func resetViewState() {
        showLengthSelection = false
        selectedMode = .random
    }
}

// MARK: - Supporting Types

enum PuzzleMode {
    case random
    case daily
}