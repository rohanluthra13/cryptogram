import Foundation

/// Represents a single puzzle-solving session with metrics and state
struct PuzzleSession {
    var startTime: Date?
    var endTime: Date?
    var mistakeCount: Int
    var hintCount: Int
    var selectedCellIndex: Int?
    var isComplete: Bool
    var isFailed: Bool
    var revealedIndices: Set<Int>
    var hasContinuedAfterFailure: Bool = false
    
    var completionTime: TimeInterval? {
        guard let start = startTime, let end = endTime else { return nil }
        let rawTime = end.timeIntervalSince(start)
        return rawTime - totalPausedTime
    }
    
    var isPaused: Bool = false
    private var pauseStartTime: Date?
    var totalPausedTime: TimeInterval = 0
    
    var wasLogged: Bool = false
    
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
        mistakeCount += 1
        // defer failure marking to checkPuzzleCompletion for proper logging
    }
    
    mutating func markComplete() {
        isComplete = true
        if endTime == nil {
            endTime = Date()
        }
    }
    
    mutating func markFailed() {
        isFailed = true
        if endTime == nil {
            endTime = Date()
        }
    }
    
    mutating func revealCell(at index: Int) {
        revealedIndices.insert(index)
        hintCount += 1
    }
    
    mutating func togglePause() {
        isPaused.toggle()
        
        if isPaused {
            // Record the time when the game is paused
            pauseStartTime = Date()
        } else if let pauseStart = pauseStartTime {
            // Calculate the duration of the pause and add it to the total
            let pauseDuration = Date().timeIntervalSince(pauseStart)
            totalPausedTime += pauseDuration
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
        hasContinuedAfterFailure = false
        wasLogged = false
    }
    
    mutating func clearFailureState() {
        isFailed = false
        hasContinuedAfterFailure = true
        // Don't reset mistake count - allow unlimited mistakes from here
    }
} 