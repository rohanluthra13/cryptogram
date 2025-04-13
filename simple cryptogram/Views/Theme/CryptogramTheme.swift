import SwiftUI

struct CryptogramTheme {
    struct Colors {
        // Main colors
        static let primary = Color("Primary")
        static let secondary = Color(.systemGray2)
        
        // Updated colors using hex
        static let background = Color(hex: "#f8f8f8")
        static let text = Color(hex: "#555555")
        
        // System colors for states
        static let error = Color(.systemRed)
        static let success = Color(.systemGreen)
        static let hint = Color(.systemOrange)
        
        // Border colors
        static let selectedBorder = Color.blue
        static let border = Color(.systemGray4)
    }
    
    struct Layout {
        // Base sizes
        static let cellSize: CGFloat = 40
        static let cellSpacing: CGFloat = 4
        
        // Grid layout
        static let gridColumns = 10
        static let gridPadding: CGFloat = 10
        static let shadowRadius: CGFloat = 3
        
        // Spacing
        static let buttonCornerRadius: CGFloat = 8
        static let cellCornerRadius: CGFloat = 4
    }
    
    struct Typography {
        static let title = Font.system(.title, design: .rounded)
        static let body = Font.system(.body, design: .rounded)
        static let cell = Font.system(.title2, design: .monospaced)
        static let button = Font.system(.body, design: .rounded)
    }
    
    struct Animation {
        static let buttonPress: SwiftUI.Animation = .easeInOut(duration: 0.2)
        static let cellSelection: SwiftUI.Animation = .easeInOut(duration: 0.2)
        static let reveal: SwiftUI.Animation = .easeInOut(duration: 0.3)
    }
} 
