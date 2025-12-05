import Foundation
import SwiftUI

@MainActor
class DailyPuzzleManager: ObservableObject {
    // MARK: - Published Properties
    @Published var isDailyPuzzle: Bool = false
    @Published var isDailyPuzzleCompletedPublished: Bool = false
    
    // MARK: - Dependencies
    private let databaseService: DatabaseService
    private(set) var currentPuzzleDate: Date?

    // MARK: - Debounce
    private var saveTask: Task<Void, Never>?
    
    // Computed property for encodingType
    private var encodingType: String {
        return AppSettings.shared.encodingType
    }
    
    // MARK: - Initialization
    init(databaseService: DatabaseService = .shared) {
        self.databaseService = databaseService
    }
    
    // MARK: - Public Methods
    func loadDailyPuzzle() throws -> (puzzle: Puzzle, progress: DailyPuzzleProgress?) {
        return try loadDailyPuzzle(for: Date())
    }
    
    func loadDailyPuzzle(for date: Date) throws -> (puzzle: Puzzle, progress: DailyPuzzleProgress?) {
        isDailyPuzzle = true
        currentPuzzleDate = date
        let dateStr = Self.dateString(from: date)
        
        // Check for saved progress first
        if let data = UserDefaults.standard.data(forKey: dailyProgressKey(for: dateStr)),
           let progress = try? JSONDecoder().decode(DailyPuzzleProgress.self, from: data),
           let puzzle = try databaseService.fetchPuzzleById(progress.quoteId, encodingType: encodingType) {
            // Return puzzle with existing progress
            return (puzzle: puzzle, progress: progress)
        }
        
        // No saved progress - load fresh daily puzzle
        guard let puzzle = try databaseService.fetchDailyPuzzle(for: date, encodingType: encodingType) else {
            isDailyPuzzle = false
            throw DatabaseError.noDataFound
        }
        
        return (puzzle: puzzle, progress: nil)
    }
    
    func saveDailyPuzzleProgress(
        puzzle: Puzzle,
        cells: [CryptogramCell],
        session: PuzzleSession
    ) {
        guard isDailyPuzzle else { return }

        // Cancel any pending save
        saveTask?.cancel()

        // Capture values for the async task
        let dateStr = Self.dateString(from: currentPuzzleDate ?? Date())
        let userInputs = cells.map { $0.userInput }
        let isPreFilled = cells.map { $0.isPreFilled }
        let isRevealed = cells.map { $0.isRevealed }
        let quoteId = puzzle.quoteId
        let hintCount = session.hintCount
        let mistakeCount = session.mistakeCount
        let startTime = session.startTime
        let endTime = session.endTime
        let isComplete = session.isComplete

        // If puzzle is complete, save immediately
        if isComplete {
            performSave(
                dateStr: dateStr,
                quoteId: quoteId,
                userInputs: userInputs,
                hintCount: hintCount,
                mistakeCount: mistakeCount,
                startTime: startTime,
                endTime: endTime,
                isCompleted: isComplete,
                isPreFilled: isPreFilled,
                isRevealed: isRevealed
            )
            return
        }

        // Debounce non-completion saves by 1 second
        saveTask = Task {
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            guard !Task.isCancelled else { return }
            performSave(
                dateStr: dateStr,
                quoteId: quoteId,
                userInputs: userInputs,
                hintCount: hintCount,
                mistakeCount: mistakeCount,
                startTime: startTime,
                endTime: endTime,
                isCompleted: isComplete,
                isPreFilled: isPreFilled,
                isRevealed: isRevealed
            )
        }
    }

    private func performSave(
        dateStr: String,
        quoteId: Int,
        userInputs: [String],
        hintCount: Int,
        mistakeCount: Int,
        startTime: Date?,
        endTime: Date?,
        isCompleted: Bool,
        isPreFilled: [Bool],
        isRevealed: [Bool]
    ) {
        let progress = DailyPuzzleProgress(
            date: dateStr,
            quoteId: quoteId,
            userInputs: userInputs,
            hintCount: hintCount,
            mistakeCount: mistakeCount,
            startTime: startTime,
            endTime: endTime,
            isCompleted: isCompleted,
            isPreFilled: isPreFilled,
            isRevealed: isRevealed
        )

        if let data = try? JSONEncoder().encode(progress) {
            UserDefaults.standard.set(data, forKey: dailyProgressKey(for: dateStr))
        }
    }
    
    func restoreDailyProgress(
        to cells: inout [CryptogramCell],
        session: inout PuzzleSession,
        from progress: DailyPuzzleProgress
    ) {
        // Restore cell states
        for (i, input) in progress.userInputs.enumerated() where i < cells.count {
            cells[i].userInput = input
            cells[i].isPreFilled = progress.isPreFilled?[i] ?? false
            cells[i].isRevealed = progress.isRevealed?[i] ?? false
        }
        
        // Restore session state
        session.hintCount = progress.hintCount
        session.mistakeCount = progress.mistakeCount
        session.startTime = progress.startTime
        session.endTime = progress.endTime
        session.isComplete = progress.isCompleted
        
        if progress.isCompleted {
            session.markComplete()
        }
    }
    
    func checkDailyPuzzleCompleted(puzzle: Puzzle?) -> Bool {
        guard isDailyPuzzle, let puzzle = puzzle else { 
            updateCompletedStatus(false)
            return false 
        }
        
        // Use the current puzzle date instead of today's date
        let dateStr = currentPuzzleDate != nil ? Self.dateString(from: currentPuzzleDate!) : Self.currentDateString()
        if let data = UserDefaults.standard.data(forKey: dailyProgressKey(for: dateStr)),
           let progress = try? JSONDecoder().decode(DailyPuzzleProgress.self, from: data),
           progress.quoteId == puzzle.quoteId {
            let completed = progress.isCompleted
            updateCompletedStatus(completed)
            return completed
        }
        
        updateCompletedStatus(false)
        return false
    }
    
    func resetDailyPuzzleState() {
        isDailyPuzzle = false
        isDailyPuzzleCompletedPublished = false
        currentPuzzleDate = nil
    }
    
    func isTodaysDailyPuzzleCompleted() -> Bool {
        let dateStr = Self.currentDateString()
        if let data = UserDefaults.standard.data(forKey: dailyProgressKey(for: dateStr)),
           let progress = try? JSONDecoder().decode(DailyPuzzleProgress.self, from: data) {
            return progress.isCompleted
        }
        return false
    }
    
    // MARK: - Private Methods
    private func dailyProgressKey(for date: String) -> String {
        "dailyPuzzleProgress-\(date)"
    }
    
    private static func currentDateString() -> String {
        return dateString(from: Date())
    }
    
    private static func dateString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone.current
        return formatter.string(from: date)
    }
    
    private func updateCompletedStatus(_ completed: Bool) {
        if isDailyPuzzleCompletedPublished != completed {
            DispatchQueue.main.async { [weak self] in
                self?.isDailyPuzzleCompletedPublished = completed
            }
        }
    }
}