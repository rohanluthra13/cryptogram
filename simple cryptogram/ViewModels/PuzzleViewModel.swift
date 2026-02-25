import Foundation
import Observation
import SwiftUI
import UIKit

// MARK: - Supporting Types

struct WordGroup: Identifiable {
    let id = UUID()
    let indices: [Int]
    let includesSpace: Bool
}

// MARK: - PuzzleViewModel

@MainActor
@Observable
final class PuzzleViewModel {

    // MARK: - Core State (was GameStateManager)

    var cells: [CryptogramCell] = []
    var session: PuzzleSession = PuzzleSession()
    private(set) var currentPuzzle: Puzzle?
    var isWiggling = false
    var completedLetters: Set<String> = []
    var hasUserEngaged: Bool = false
    var showCompletedHighlights: Bool = false

    // Keyboard optimization mappings (pre-computed)
    private(set) var solutionToEncodedMap: [Character: Set<String>] = [:]
    private(set) var lettersInPuzzle: Set<Character> = []

    // MARK: - Daily State (was DailyPuzzleManager)

    var isDailyPuzzle: Bool = false
    var isDailyPuzzleCompletedPublished: Bool = false
    var completionVersion: Int = 0
    private(set) var currentDailyDate: Date?

    // MARK: - Author (was AuthorService)

    private(set) var currentAuthor: Author?
    private var lastAuthorName: String?

    // MARK: - Loading / Error

    var isLoadingPuzzle: Bool = false
    var currentError: DatabaseError?

    // MARK: - Dependencies (2, not 9)

    private let db: DatabaseService
    private let progressStore: PuzzleProgressStore

    // MARK: - Statistics Cache

    private var cachedAttempts: [PuzzleAttempt]?
    private var cacheTimestamp: Date?
    private let cacheDuration: TimeInterval = 1.0

    // MARK: - Settings Access

    private var encodingType: String { AppSettings.shared.encodingType }
    private var selectedDifficulties: [String] { AppSettings.shared.selectedDifficulties }

    // MARK: - Computed Properties

    var selectedCellIndex: Int? { session.selectedCellIndex }
    var isComplete: Bool { session.isComplete }
    var isFailed: Bool { session.isFailed }
    var mistakeCount: Int { session.mistakeCount }
    var startTime: Date? { session.startTime }
    var endTime: Date? { session.endTime }
    var isPaused: Bool { session.isPaused }
    var hintCount: Int { session.hintCount }
    var completionTime: TimeInterval? { session.completionTime }

    var nonSymbolCells: [CryptogramCell] {
        cells.filter { !$0.isSymbol }
    }

    var progressPercentage: Double {
        let total = nonSymbolCells.count
        guard total > 0 else { return 0.0 }
        let filled = nonSymbolCells.filter { !$0.userInput.isEmpty }.count
        return Double(filled) / Double(total)
    }

    var wordGroups: [WordGroup] {
        var groups: [WordGroup] = []
        var current: [Int] = []
        for index in cells.indices {
            if cells[index].isSymbol && cells[index].encodedChar == " " {
                if !current.isEmpty {
                    groups.append(WordGroup(indices: current, includesSpace: true))
                    current = []
                }
            } else {
                current.append(index)
            }
        }
        if !current.isEmpty {
            groups.append(WordGroup(indices: current, includesSpace: false))
        }
        return groups
    }

    var cellsToAnimate: [UUID] {
        cells.filter { $0.wasJustFilled }.map { $0.id }
    }

    var isCompletedDailyPuzzle: Bool {
        isDailyPuzzle && isComplete && session.endTime != nil
    }

    var currentDailyPuzzleDate: Date? { currentDailyDate }
    var dailyCompletionVersion: Int { completionVersion }

    // Daily puzzle completion checks
    var isDailyPuzzleCompleted: Bool {
        checkDailyPuzzleCompleted()
    }

    func isTodaysDailyPuzzleCompleted() -> Bool {
        let dateStr = Self.dateString(from: Date())
        return readDailyProgress(for: dateStr)?.isCompleted ?? false
    }

    // MARK: - Statistics Properties

    var completionCountForCurrentPuzzle: Int {
        guard let puzzle = currentPuzzle else { return 0 }
        return progressStore_completionCount(for: puzzle.id, encodingType: encodingType)
    }

    var failureCountForCurrentPuzzle: Int {
        guard let puzzle = currentPuzzle else { return 0 }
        return progressStore_failureCount(for: puzzle.id, encodingType: encodingType)
    }

    var bestTimeForCurrentPuzzle: TimeInterval? {
        guard let puzzle = currentPuzzle else { return nil }
        return try? progressStore.bestCompletionTime(for: puzzle.id, encodingType: encodingType)
    }

    var totalAttempts: Int { getCachedAttempts().count }
    var totalCompletions: Int { getCachedAttempts().filter { $0.completedAt != nil }.count }
    var totalFailures: Int { getCachedAttempts().filter { $0.failedAt != nil }.count }
    var globalBestTime: TimeInterval? { getCachedAttempts().compactMap { $0.completionTime }.min() }

    var winRatePercentage: Int {
        let attempts = getCachedAttempts()
        guard !attempts.isEmpty else { return 0 }
        let completions = attempts.filter { $0.completedAt != nil }.count
        return Int(Double(completions) / Double(attempts.count) * 100)
    }

    var averageTime: TimeInterval? {
        let times = getCachedAttempts().compactMap { $0.completionTime }
        guard !times.isEmpty else { return nil }
        return times.reduce(0, +) / Double(times.count)
    }

    // MARK: - Daily Streak Properties

    var currentDailyStreak: Int {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let minDate = DateComponents(calendar: .current, year: 2025, month: 4, day: 23).date!

        var checkDate = today
        if !wasCompletedSameDay(checkDate) {
            guard let yesterday = cal.date(byAdding: .day, value: -1, to: checkDate) else { return 0 }
            checkDate = yesterday
        }

        var streak = 0
        while checkDate >= minDate {
            if wasCompletedSameDay(checkDate) {
                streak += 1
                guard let prev = cal.date(byAdding: .day, value: -1, to: checkDate) else { break }
                checkDate = prev
            } else {
                break
            }
        }
        return streak
    }

    var bestDailyStreak: Int {
        let cal = Calendar.current
        let minDate = DateComponents(calendar: .current, year: 2025, month: 4, day: 23).date!
        let today = cal.startOfDay(for: Date())

        var best = 0
        var current = 0
        var checkDate = minDate

        while checkDate <= today {
            if wasCompletedSameDay(checkDate) {
                current += 1
                best = max(best, current)
            } else {
                current = 0
            }
            guard let next = cal.date(byAdding: .day, value: 1, to: checkDate) else { break }
            checkDate = next
        }
        return best
    }

    private func wasCompletedSameDay(_ date: Date) -> Bool {
        let dateStr = Self.dateString(from: date)
        guard let progress = readDailyProgress(for: dateStr),
              progress.isCompleted,
              let endTime = progress.endTime else { return false }
        return Self.dateString(from: endTime) == dateStr
    }

    // MARK: - Initialization

    init(initialPuzzle: Puzzle? = nil, progressStore: PuzzleProgressStore? = nil) {
        self.db = DatabaseService.shared

        if let store = progressStore {
            self.progressStore = store
        } else if let conn = DatabaseService.shared.db {
            self.progressStore = LocalPuzzleProgressStore(database: conn)
        } else {
            self.progressStore = NoOpProgressStore()
        }

        if let puzzle = initialPuzzle {
            startNewPuzzle(puzzle: puzzle)
        } else {
            loadInitialPuzzle()
        }
    }

    // MARK: - Puzzle Loading

    func startNewPuzzle(puzzle: Puzzle, skipAnimationInit: Bool = false) {
        completedLetters = []
        currentPuzzle = puzzle
        cells = puzzle.createCells(encodingType: encodingType)
        session = PuzzleSession()
        updateKeyboardMappings()

        if !skipAnimationInit {
            applyDifficultyPrefills()
        }

        selectFirstEditableCell()
        loadAuthorIfNeeded(name: puzzle.author)
    }

    func loadNewPuzzle() {
        // Clear daily state FIRST — prevents stale daily saves
        isDailyPuzzle = false
        isDailyPuzzleCompletedPublished = false
        currentDailyDate = nil

        Task {
            await loadPuzzleWithDifficulty()
        }
    }

    func loadNewPuzzleAsync() async {
        isDailyPuzzle = false
        isDailyPuzzleCompletedPublished = false
        currentDailyDate = nil
        await loadPuzzleWithDifficulty()
    }

    func refreshPuzzleWithCurrentSettings() {
        isDailyPuzzle = false
        isDailyPuzzleCompletedPublished = false
        currentDailyDate = nil
        Task {
            await loadPuzzleWithExclusions()
        }
    }

    func loadDailyPuzzle() {
        loadDailyPuzzle(for: Date())
    }

    func loadDailyPuzzle(for date: Date) {
        isLoadingPuzzle = true
        isDailyPuzzle = true
        currentDailyDate = date
        let dateStr = Self.dateString(from: date)

        do {
            // Check for saved progress first
            if let progress = readDailyProgress(for: dateStr),
               let puzzle = try db.fetchPuzzleById(progress.quoteId, encodingType: encodingType) {
                startNewPuzzle(puzzle: puzzle, skipAnimationInit: true)
                restoreDailyProgress(from: progress)
                isLoadingPuzzle = false
                return
            }

            // No saved progress — load fresh
            guard let puzzle = try db.fetchDailyPuzzle(for: date, encodingType: encodingType) else {
                isDailyPuzzle = false
                currentDailyDate = nil
                isLoadingPuzzle = false
                currentError = .noDataFound
                loadNewPuzzle()
                return
            }

            startNewPuzzle(puzzle: puzzle, skipAnimationInit: false)
            isLoadingPuzzle = false
        } catch {
            isLoadingPuzzle = false
            currentError = error as? DatabaseError ?? .connectionFailed
            isDailyPuzzle = false
            currentDailyDate = nil
            loadNewPuzzle()
        }
    }

    private func loadInitialPuzzle() {
        Task { await loadPuzzleWithDifficulty() }
    }

    private func loadPuzzleWithExclusions() async {
        isLoadingPuzzle = true
        let completedIds = getCompletedPuzzleIds(for: encodingType)

        for _ in 0..<10 {
            if let puzzle = try? db.fetchRandomPuzzle(
                encodingType: encodingType,
                selectedDifficulties: selectedDifficulties
            ), !completedIds.contains(puzzle.id) {
                startNewPuzzle(puzzle: puzzle)
                isLoadingPuzzle = false
                return
            }
        }
        // Fallback
        await loadPuzzleWithDifficulty()
    }

    private func loadPuzzleWithDifficulty() async {
        isLoadingPuzzle = true
        do {
            if let puzzle = try db.fetchRandomPuzzle(
                encodingType: encodingType,
                selectedDifficulties: selectedDifficulties
            ) {
                startNewPuzzle(puzzle: puzzle)
            } else {
                startNewPuzzle(puzzle: Self.fallbackPuzzle())
            }
        } catch {
            currentError = error as? DatabaseError ?? .connectionFailed
            startNewPuzzle(puzzle: Self.fallbackPuzzle())
        }
        isLoadingPuzzle = false
    }

    private static func fallbackPuzzle() -> Puzzle {
        Puzzle(
            id: UUID(),
            quoteId: 0,
            encodedText: "THE QUICK BROWN FOX JUMPS OVER THE LAZY DOG",
            solution: "THE QUICK BROWN FOX JUMPS OVER THE LAZY DOG",
            hint: "A pangram containing every letter of the alphabet",
            author: "Unknown",
            difficulty: "easy",
            length: 43
        )
    }

    // MARK: - Input Handling (was InputHandler)

    func selectCell(at index: Int) {
        guard index >= 0 && index < cells.count, !cells[index].isSymbol else { return }
        session.selectedCellIndex = index

        Task {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred(intensity: 0.5)
        }
    }

    func inputLetter(_ letter: String, at index: Int) {
        guard index >= 0 && index < cells.count,
              !cells[index].isSymbol,
              letter.count == 1,
              let firstChar = letter.first, firstChar.isLetter else { return }

        startTimerIfNeeded()
        let uppercased = letter.uppercased()
        let cell = cells[index]
        let wasEmpty = cell.userInput.isEmpty

        resetAllWasJustFilled()

        let isCorrect = String(cell.solutionChar ?? " ") == uppercased

        if isCorrect {
            updateCell(at: index, with: uppercased, isRevealed: false, isError: false)
            Task {
                let gen = UIImpactFeedbackGenerator(style: .light)
                gen.impactOccurred()
            }
            moveToNextCell()
            markEngaged()
            saveDailyProgressIfNeeded()
        } else {
            updateCell(at: index, with: uppercased, isRevealed: false, isError: true)
            Task {
                let gen = UIImpactFeedbackGenerator(style: .medium)
                gen.impactOccurred()
            }
            if wasEmpty {
                incrementMistakes()
            }
            markEngaged()
            Task { [weak self] in
                try? await Task.sleep(for: .seconds(0.5))
                guard !Task.isCancelled else { return }
                self?.clearCell(at: index)
                self?.saveDailyProgressIfNeeded()
            }
        }
    }

    func handleDelete(at index: Int? = nil) {
        let targetIndex = index ?? selectedCellIndex ?? -1
        guard targetIndex >= 0 && targetIndex < cells.count,
              !cells[targetIndex].isSymbol else { return }

        clearCell(at: targetIndex)
        markEngaged()
        saveDailyProgressIfNeeded()
    }

    // MARK: - Hints (was HintManager)

    func revealCell(at index: Int? = nil) {
        let targetIndex: Int

        if let idx = index,
           idx >= 0 && idx < cells.count,
           !cells[idx].isSymbol,
           !cells[idx].isRevealed {
            targetIndex = idx
        } else if let sel = selectedCellIndex,
                  sel >= 0 && sel < cells.count,
                  !cells[sel].isSymbol,
                  !cells[sel].isRevealed {
            targetIndex = sel
        } else if let first = cells.indices.first(where: {
            !cells[$0].isSymbol && !cells[$0].isRevealed && cells[$0].userInput.isEmpty
        }) {
            targetIndex = first
        } else {
            return
        }

        startTimerIfNeeded()

        guard let sol = cells[targetIndex].solutionChar else { return }
        let solStr = String(sol)

        updateCell(at: targetIndex, with: solStr, isRevealed: true, isError: false)
        cells[targetIndex].isRevealed = true
        cells[targetIndex].isPreFilled = false
        session.revealCell(at: targetIndex)

        DispatchQueue.main.async {
            let gen = UISelectionFeedbackGenerator()
            gen.selectionChanged()
        }

        selectNextUnrevealedCell(after: targetIndex)
        markEngaged()
        saveDailyProgressIfNeeded()
    }

    // MARK: - Game State

    func reset() {
        completedLetters = []
        session = PuzzleSession()
        hasUserEngaged = false

        for i in cells.indices {
            cells[i].userInput = ""
            cells[i].isError = false
            cells[i].wasJustFilled = false
            cells[i].isRevealed = false
            cells[i].isPreFilled = false
        }

        applyDifficultyPrefills()
        updateCompletedLetters()
        selectFirstEditableCell()
    }

    func continueAfterFailure() {
        session.clearFailureState()
    }

    func togglePause() { session.togglePause() }

    func pause() {
        guard session.startTime != nil && !session.isComplete && !session.isFailed && !isPaused else { return }
        session.togglePause()
    }

    func resume() {
        guard session.startTime != nil && !session.isComplete && !session.isFailed && isPaused else { return }
        session.togglePause()
    }

    func triggerCompletionWiggle() {
        isWiggling = true
        Task { [weak self] in
            try? await Task.sleep(for: .seconds(0.6))
            guard !Task.isCancelled else { return }
            self?.isWiggling = false
        }
    }

    func markCellAnimationComplete(_ cellId: UUID) {
        if let idx = cells.firstIndex(where: { $0.id == cellId }) {
            cells[idx].wasJustFilled = false
        }
    }

    func userEngaged() {
        markEngaged()
    }

    func moveToNextCell() {
        guard let current = selectedCellIndex else { return }
        var next = current + 1
        while next < cells.count {
            if !shouldSkipCell(cells[next]) {
                session.selectedCellIndex = next
                return
            }
            next += 1
        }
    }

    func moveToAdjacentCell(direction: Int) {
        if selectedCellIndex == nil {
            if let first = cells.indices.first(where: { !shouldSkipCell(cells[$0]) }) {
                session.selectedCellIndex = first
            }
            return
        }
        guard let current = selectedCellIndex else { return }
        var target = current + direction
        while target >= 0 && target < cells.count {
            if !shouldSkipCell(cells[target]) {
                session.selectedCellIndex = target
                return
            }
            target += direction
        }
    }

    // MARK: - Daily Puzzle Save (NO debounce, synchronous)

    func saveDailyProgressIfNeeded() {
        guard isDailyPuzzle, let puzzle = currentPuzzle else { return }
        let dateStr = Self.dateString(from: currentDailyDate ?? Date())

        let progress = DailyPuzzleProgress(
            date: dateStr,
            quoteId: puzzle.quoteId,
            userInputs: cells.map { $0.userInput },
            hintCount: session.hintCount,
            mistakeCount: session.mistakeCount,
            startTime: session.startTime,
            endTime: session.endTime,
            isCompleted: session.isComplete,
            isPreFilled: cells.map { $0.isPreFilled },
            isRevealed: cells.map { $0.isRevealed }
        )

        if let data = try? JSONEncoder().encode(progress) {
            UserDefaults.standard.set(data, forKey: dailyProgressKey(for: dateStr))
            if session.isComplete {
                completionVersion += 1
            }
        }
    }

    /// Called when completion is detected. Alias for saveDailyProgressIfNeeded.
    func saveCompletionIfDaily() {
        saveDailyProgressIfNeeded()
    }

    /// Called on app background. No debounce means nothing pending — just save current state.
    func flushPendingDailySave() {
        saveDailyProgressIfNeeded()
    }

    // MARK: - Progress & Stats (was PuzzleProgressManager + StatisticsManager)

    func logCompletionIfNeeded() {
        guard let puzzle = currentPuzzle,
              session.isComplete,
              session.endTime != nil,
              !session.wasLogged else { return }

        let attempt = PuzzleAttempt(
            attemptID: UUID(),
            puzzleID: puzzle.id,
            encodingType: encodingType,
            completedAt: session.endTime ?? Date(),
            failedAt: nil,
            completionTime: session.completionTime ?? 0,
            mode: "normal",
            hintCount: session.hintCount,
            mistakeCount: session.mistakeCount
        )
        try? progressStore.logAttempt(attempt)
        session.wasLogged = true
        invalidateStatsCache()
    }

    func logFailureIfNeeded() {
        guard let puzzle = currentPuzzle,
              session.isFailed,
              !session.wasLogged else { return }

        let attempt = PuzzleAttempt(
            attemptID: UUID(),
            puzzleID: puzzle.id,
            encodingType: encodingType,
            completedAt: nil,
            failedAt: Date(),
            completionTime: nil,
            mode: "normal",
            hintCount: session.hintCount,
            mistakeCount: session.mistakeCount
        )
        try? progressStore.logAttempt(attempt)
        session.wasLogged = true
        invalidateStatsCache()
    }

    func resetAllProgress() {
        try? progressStore.clearAllProgress()
        AppSettings.shared.completedQuoteIds = []
        invalidateStatsCache()
    }

    // MARK: - Author (was AuthorService)

    private func loadAuthorIfNeeded(name: String) {
        guard name != lastAuthorName else { return }
        lastAuthorName = name

        Task { [weak self] in
            guard let self else { return }
            do {
                let author = try await self.db.fetchAuthor(byName: name)
                self.currentAuthor = author
            } catch {
                self.currentAuthor = nil
            }
        }
    }

    // MARK: - Cell Helpers

    private func updateCell(at index: Int, with input: String, isRevealed: Bool, isError: Bool) {
        guard index >= 0 && index < cells.count else { return }
        cells[index].userInput = input
        cells[index].isRevealed = isRevealed
        cells[index].isError = isError
        if !input.isEmpty { cells[index].wasJustFilled = true }
        updateCompletedLetters()
        checkPuzzleCompletion()
    }

    private func clearCell(at index: Int) {
        guard index >= 0 && index < cells.count else { return }
        cells[index].userInput = ""
        cells[index].isError = false
        cells[index].wasJustFilled = false
        updateCompletedLetters()
    }

    func updateCompletedLetters() {
        var letterHasEmpty: [String: Bool] = [:]
        for cell in cells where !cell.isSymbol {
            let letter = cell.encodedChar
            if letterHasEmpty[letter] == nil {
                letterHasEmpty[letter] = cell.userInput.isEmpty
            } else if cell.userInput.isEmpty {
                letterHasEmpty[letter] = true
            }
        }
        completedLetters = Set(letterHasEmpty.filter { !$0.value }.keys)
    }

    private func checkPuzzleCompletion() {
        let correct = nonSymbolCells.filter { $0.isCorrect }.count
        let total = nonSymbolCells.count
        if correct == total && !session.isComplete {
            session.markComplete()
            if let puzzle = currentPuzzle {
                AppSettings.shared.markQuoteCompleted(puzzle.quoteId)
            }
        }
    }

    private func incrementMistakes() {
        session.incrementMistakes()
        if session.mistakeCount >= 3 && !session.isFailed && !session.hasContinuedAfterFailure {
            Task { [weak self] in
                try? await Task.sleep(for: .seconds(0.6))
                guard !Task.isCancelled else { return }
                self?.session.markFailed()
            }
        }
    }

    private func startTimerIfNeeded() {
        if session.startTime == nil {
            session.startTime = Date()
        }
    }

    private func markEngaged() {
        guard !hasUserEngaged else { return }
        hasUserEngaged = true
    }

    private func resetAllWasJustFilled() {
        for i in cells.indices { cells[i].wasJustFilled = false }
    }

    private func shouldSkipCell(_ cell: CryptogramCell) -> Bool {
        cell.isSymbol || cell.isRevealed || cell.isPreFilled || (!cell.userInput.isEmpty && cell.isCorrect)
    }

    private func selectFirstEditableCell() {
        if let idx = cells.indices.first(where: { !cells[$0].isSymbol && !cells[$0].isRevealed && !cells[$0].isPreFilled }) {
            session.selectedCellIndex = idx
        }
    }

    private func selectNextUnrevealedCell(after index: Int) {
        if let next = cells.indices.first(where: {
            $0 > index && !cells[$0].isSymbol && !cells[$0].isRevealed && cells[$0].userInput.isEmpty
        }) {
            session.selectedCellIndex = next
        }
    }

    private func updateKeyboardMappings() {
        var solutionMap: [Character: Set<String>] = [:]
        var puzzleLetters: Set<Character> = []
        for cell in cells where !cell.isSymbol {
            if let sol = cell.solutionChar {
                solutionMap[sol, default: []].insert(cell.encodedChar)
                puzzleLetters.insert(sol)
            }
        }
        solutionToEncodedMap = solutionMap
        lettersInPuzzle = puzzleLetters
    }

    private func applyDifficultyPrefills() {
        guard let solution = currentPuzzle?.solution.uppercased() else { return }
        let uniqueLetters = Set(solution.filter { $0.isLetter })
        guard !uniqueLetters.isEmpty else { return }

        let numToReveal = max(1, Int(ceil(Double(uniqueLetters.count) * 0.20)))
        let lettersToReveal = uniqueLetters.shuffled().prefix(numToReveal)
        var revealedIndices = Set<Int>()

        for letter in lettersToReveal {
            let matching = cells.indices.filter {
                cells[$0].solutionChar == letter &&
                !revealedIndices.contains($0) &&
                !cells[$0].isRevealed
            }
            if let idx = matching.randomElement() {
                cells[idx].userInput = String(letter)
                cells[idx].isRevealed = true
                cells[idx].isError = false
                cells[idx].isPreFilled = true
                revealedIndices.insert(idx)
            }
        }
    }

    // MARK: - Daily Puzzle Helpers

    private func checkDailyPuzzleCompleted() -> Bool {
        guard isDailyPuzzle, let puzzle = currentPuzzle else {
            updateDailyCompletedStatus(false)
            return false
        }
        let dateStr = currentDailyDate != nil ? Self.dateString(from: currentDailyDate!) : Self.dateString(from: Date())
        if let progress = readDailyProgress(for: dateStr),
           progress.quoteId == puzzle.quoteId {
            let completed = progress.isCompleted
            updateDailyCompletedStatus(completed)
            return completed
        }
        updateDailyCompletedStatus(false)
        return false
    }

    private func restoreDailyProgress(from progress: DailyPuzzleProgress) {
        for (i, input) in progress.userInputs.enumerated() where i < cells.count {
            cells[i].userInput = input
            let hasContent = !input.isEmpty
            cells[i].isPreFilled = hasContent && (progress.isPreFilled?[i] ?? false)
            cells[i].isRevealed = hasContent && (progress.isRevealed?[i] ?? false)
        }
        session.hintCount = progress.hintCount
        session.mistakeCount = progress.mistakeCount
        session.startTime = progress.startTime
        session.endTime = progress.endTime
        session.isComplete = progress.isCompleted
        if progress.isCompleted {
            session.markComplete()
        }
        updateCompletedLetters()
    }

    private func readDailyProgress(for dateStr: String) -> DailyPuzzleProgress? {
        guard let data = UserDefaults.standard.data(forKey: dailyProgressKey(for: dateStr)) else { return nil }
        return try? JSONDecoder().decode(DailyPuzzleProgress.self, from: data)
    }

    private func dailyProgressKey(for dateStr: String) -> String {
        "dailyPuzzleProgress-\(dateStr)"
    }

    private static func dateString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone.current
        return formatter.string(from: date)
    }

    private func updateDailyCompletedStatus(_ completed: Bool) {
        if isDailyPuzzleCompletedPublished != completed {
            isDailyPuzzleCompletedPublished = completed
        }
    }

    // MARK: - Statistics Helpers

    private func getCachedAttempts() -> [PuzzleAttempt] {
        if let cached = cachedAttempts,
           let ts = cacheTimestamp,
           Date().timeIntervalSince(ts) < cacheDuration {
            return cached
        }
        let attempts = (try? progressStore.allAttempts()) ?? []
        cachedAttempts = attempts
        cacheTimestamp = Date()
        return attempts
    }

    private func invalidateStatsCache() {
        cachedAttempts = nil
        cacheTimestamp = nil
    }

    private func progressStore_completionCount(for puzzleId: UUID, encodingType: String) -> Int {
        let attempts = (try? progressStore.attempts(for: puzzleId, encodingType: encodingType)) ?? []
        return attempts.filter { $0.completedAt != nil }.count
    }

    private func progressStore_failureCount(for puzzleId: UUID, encodingType: String) -> Int {
        let attempts = (try? progressStore.attempts(for: puzzleId, encodingType: encodingType)) ?? []
        return attempts.filter { $0.failedAt != nil }.count
    }

    private func getCompletedPuzzleIds(for encodingType: String) -> Set<UUID> {
        Set(getCachedAttempts()
            .filter { $0.encodingType == encodingType && $0.completedAt != nil }
            .map { $0.puzzleID })
    }
}

// MARK: - NoOpProgressStore

private class NoOpProgressStore: PuzzleProgressStore {
    func logAttempt(_ attempt: PuzzleAttempt) throws {}
    func attempts(for puzzleID: UUID, encodingType: String?) throws -> [PuzzleAttempt] { [] }
    func latestAttempt(for puzzleID: UUID, encodingType: String?) throws -> PuzzleAttempt? { nil }
    func bestCompletionTime(for puzzleID: UUID, encodingType: String?) throws -> TimeInterval? { nil }
    func clearAllProgress() throws {}
    func allAttempts() throws -> [PuzzleAttempt] { [] }
}
