import Foundation

struct PuzzleState: Equatable {
    var userInput: [String]
    var letterMapping: [Character: Character]
    var selectedCellIndex: Int?
    var mistakeCount: Int
    var revealedLetters: Set<Character>
    var revealedIndices: Set<Int>
    var isComplete: Bool
    var startTime: Date
    var endTime: Date?
    var hintCount: Int
    var maxHints: Int
    var isFailed: Bool
    
    var completionTime: TimeInterval? {
        guard let endTime = endTime else { return nil }
        return endTime.timeIntervalSince(startTime)
    }
    
    var isHintAvailable: Bool {
        return true // Always allow hints
    }
    
    init(
        userInput: [String] = [],
        letterMapping: [Character: Character] = [:],
        selectedCellIndex: Int? = nil,
        mistakeCount: Int = 0,
        revealedLetters: Set<Character> = [],
        revealedIndices: Set<Int> = [],
        isComplete: Bool = false,
        startTime: Date = Date(),
        endTime: Date? = nil,
        hintCount: Int = 0,
        maxHints: Int = Int.max, // Essentially unlimited hints
        isFailed: Bool = false
    ) {
        self.userInput = userInput
        self.letterMapping = letterMapping
        self.selectedCellIndex = selectedCellIndex
        self.mistakeCount = mistakeCount
        self.revealedLetters = revealedLetters
        self.revealedIndices = revealedIndices
        self.isComplete = isComplete
        self.startTime = startTime
        self.endTime = endTime
        self.hintCount = hintCount
        self.maxHints = maxHints
        self.isFailed = isFailed
    }
    
    mutating func selectCell(at index: Int) {
        selectedCellIndex = index
    }
    
    mutating func inputLetter(_ letter: Character, at index: Int) {
        guard index < userInput.count else { return }
        userInput[index] = String(letter)
    }
    
    mutating func revealLetter(_ letter: Character, at index: Int) {
        revealedLetters.insert(letter)
        revealedIndices.insert(index)
        hintCount += 1
    }
    
    mutating func markComplete() {
        isComplete = true
        endTime = Date()
    }
    
    mutating func markFailed() {
        isFailed = true
        endTime = Date()
    }
    
    mutating func incrementMistakeCount() {
        mistakeCount += 1
    }
    
    mutating func reset() {
        self = PuzzleState(
            userInput: [],
            letterMapping: [:],
            selectedCellIndex: nil,
            mistakeCount: 0,
            revealedLetters: [],
            revealedIndices: [],
            isComplete: false,
            startTime: Date(),
            endTime: nil,
            hintCount: 0,
            isFailed: false
        )
    }
} 