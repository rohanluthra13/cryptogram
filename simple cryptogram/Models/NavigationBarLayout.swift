import Foundation

enum NavigationBarLayout: String, CaseIterable, Identifiable {
    case leftLayout
    case centerLayout  // Default/current layout
    case rightLayout
    
    var id: String { self.rawValue }
    
    var displayName: String {
        switch self {
        case .leftLayout: return "Left"
        case .centerLayout: return "Center"
        case .rightLayout: return "Right"
        }
    }
} 