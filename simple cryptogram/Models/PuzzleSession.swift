import Foundation

/// Represents a single puzzle-solving session with metrics and state
struct PuzzleSession: Equatable {
    var startTime: Date?
    var endTime: Date?
    var mistakeCount: Int
    var hintCount: Int
    var selectedCellIndex: Int?
    var isComplete: Bool
    var isFailed: Bool
    var revealedIndices: Set<Int>
    
    var completionTime: TimeInterval? {
        guard let start = startTime, let end = endTime else { return nil }
        return end.timeIntervalSince(start)
    }
    
    var isPaused: Bool = false
    private var pauseStartTime: Date?
    
    // Determines if the session has actively started
    var hasStarted: Bool {
        return startTime != nil && !isComplete && !isFailed
    }
    
    init(
        startTime: Date? = nil,
        endTime: Date? = nil,
        mistakeCount: Int = 0,
        hintCount: Int = 0,
        selectedCellIndex: Int? = nil,
        isComplete: Bool = false,
        isFailed: Bool = false,
        revealedIndices: Set<Int> = []
    ) {
        self.startTime = startTime
        self.endTime = endTime
        self.mistakeCount = mistakeCount
        self.hintCount = hintCount
        self.selectedCellIndex = selectedCellIndex
        self.isComplete = isComplete
        self.isFailed = isFailed
        self.revealedIndices = revealedIndices
    }
    
    mutating func incrementMistakes() {
        print("[DEBUG] incrementMistakes called. Previous mistakeCount: \(mistakeCount)")
        mistakeCount += 1
        print("[DEBUG] incrementMistakes: New mistakeCount: \(mistakeCount)")
        // defer failure marking to checkPuzzleCompletion for proper logging
    }
    
    mutating func markComplete() {
        isComplete = true
        endTime = Date()
    }
    
    mutating func markFailed() {
        isFailed = true
        endTime = Date()
    }
    
    mutating func revealCell(at index: Int) {
        revealedIndices.insert(index)
        hintCount += 1
    }
    
    mutating func togglePause() {
        isPaused.toggle()
        
        if isPaused {
            pauseStartTime = Date()
        } else if let pauseStart = pauseStartTime, let start = startTime {
            // Adjust the start time by the pause duration
            let pauseDuration = Date().timeIntervalSince(pauseStart)
            startTime = start.addingTimeInterval(pauseDuration)
            pauseStartTime = nil
        }
    }
    
    mutating func reset() {
        startTime = nil
        endTime = nil
        mistakeCount = 0
        hintCount = 0
        selectedCellIndex = nil
        isComplete = false
        isFailed = false
        revealedIndices = []
        isPaused = false
        pauseStartTime = nil
    }
} 