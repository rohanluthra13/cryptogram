import Foundation

struct CompletedQuote: Codable, Identifiable {
    let id: String
    let solution: String
    let author: String
}
