import Foundation

struct Author: Identifiable, Codable {
    let id: Int
    let name: String
    let fullName: String?
    let birthDate: String?
    let deathDate: String?
    let placeOfBirth: String?
    let placeOfDeath: String?
    let summary: String?
}
