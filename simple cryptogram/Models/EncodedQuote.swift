import Foundation

struct simple_cryptogramEncodedQuote: Identifiable, Codable {
    let id: Int
    let quoteId: Int
    let letterEncoded: String
    let letterKey: String
    let numberEncoded: String
    let numberKey: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case quoteId = "quote_id"
        case letterEncoded = "letter_encoded"
        case letterKey = "letter_key"
        case numberEncoded = "number_encoded"
        case numberKey = "number_key"
    }
} 