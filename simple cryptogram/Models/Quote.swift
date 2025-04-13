import Foundation

struct simple_cryptogramQuote: Identifiable, Codable {
    let id: Int
    let quoteText: String
    let author: String
    let length: Int
    let difficulty: String
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case quoteText = "quote_text"
        case author
        case length
        case difficulty
        case createdAt = "created_at"
    }
} 