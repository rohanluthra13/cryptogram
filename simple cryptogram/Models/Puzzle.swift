import Foundation

struct Puzzle: Identifiable {
    let id: UUID
    let encodedText: String
    let solution: String
    let hint: String
    let author: String
    let difficulty: String
    let length: Int
    
    init(
        id: UUID = UUID(),
        encodedText: String,
        solution: String,
        hint: String,
        author: String = "Unknown",
        difficulty: String = "Medium",
        length: Int? = nil
    ) {
        self.id = id
        self.encodedText = encodedText
        self.solution = solution
        self.hint = hint
        self.author = author
        self.difficulty = difficulty
        self.length = length ?? encodedText.count
    }
} 
