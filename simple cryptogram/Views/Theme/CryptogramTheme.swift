import SwiftUI

struct CryptogramTheme {
    struct Colors {
        // Main colors
        static let primary = Color("PrimaryApp")
        static let secondary = Color("SecondaryApp")
        
        // Theme colors
        static let background = Color("Background")
        static let text = Color("Text")
        static let surface = Color("Surface")
        
        // System colors for states
        static let error = Color(.systemRed)
        static let success = Color(hex: "#01780F")
        static let hint = Color(.systemOrange)
        static let preFilledBackground = Color(.systemBlue).opacity(0.15) // Muted blue-grey for pre-filled cells
        
        // Border colors
        static let selectedBorder = Color("SelectedBorder")
        static let border = Color("Border")
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
        let fontOption: FontOption
        
        init(fontOption: FontOption = .system) {
            self.fontOption = fontOption
        }
        
        var title: Font {
            Font.system(.title, design: fontOption.design)
        }
        
        var body: Font {
            Font.system(.body, design: fontOption.design)
        }
        
        var cell: Font {
            // Always use monospaced for puzzle cells for better alignment
            Font.system(.title2, design: .monospaced)
        }
        
        var button: Font {
            Font.system(.body, design: fontOption.design)
        }
        
        var caption: Font {
            Font.system(.caption, design: fontOption.design)
        }
        
        var footnote: Font {
            Font.system(.footnote, design: fontOption.design)
        }
        
        // Convenience static instance for default
        static let `default` = Typography()
    }
    
    struct Animation {
        static let buttonPress: SwiftUI.Animation = .easeInOut(duration: 0.2)
        static let cellSelection: SwiftUI.Animation = .easeInOut(duration: 0.2)
        static let reveal: SwiftUI.Animation = .easeInOut(duration: 0.3)
    }
} 
