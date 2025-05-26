import SwiftUI

enum FontOption: String, CaseIterable, Codable {
    case system = "System"
    case rounded = "Rounded"
    case serif = "Serif"
    case monospaced = "Monospaced"
    
    var displayName: String {
        switch self {
        case .system: return "System (SF Pro)"
        case .rounded: return "Rounded"
        case .serif: return "Serif (New York)"
        case .monospaced: return "Monospaced"
        }
    }
    
    var design: Font.Design {
        switch self {
        case .system: return .default
        case .rounded: return .rounded
        case .serif: return .serif
        case .monospaced: return .monospaced
        }
    }
    
    var previewText: String {
        return "The quick brown fox jumps"
    }
}