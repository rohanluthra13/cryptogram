import Foundation

enum DifficultyMode: String, CaseIterable, Identifiable {
    case normal
    case expert

    var id: String { self.rawValue }

    var displayName: String {
        switch self {
        case .normal:
            return "Normal"
        case .expert:
            return "Expert"
        }
    }
} 