import SwiftUI

enum TextSizeOption: String, CaseIterable, Identifiable {
    case small, medium, large
    var id: String { rawValue }
    var displayName: String { rawValue.capitalized }
    var inputSize: CGFloat {
        switch self {
        case .small: return 13
        case .medium: return 15
        case .large: return 17
        }
    }
    var encodedSize: CGFloat {
        switch self {
        case .small: return 10
        case .medium: return 12
        case .large: return 14
        }
    }
}
