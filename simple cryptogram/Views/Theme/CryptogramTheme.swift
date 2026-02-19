import SwiftUI

struct CryptogramTheme {
    @MainActor struct Colors {
        // Main colors
        static let primary = Color("PrimaryApp")
        static let secondary = Color("SecondaryApp")

        // HSB-derived theme colors
        private static var activePalette: ColorPalette {
            let settings = AppSettings.shared
            return ColorPalette.forHue(
                settings.themeHue,
                saturation: settings.themeSaturation,
                isDark: settings.isDarkMode
            )
        }

        static var background: Color { activePalette.background }
        static var text: Color { activePalette.text }
        static var surface: Color { activePalette.surface }
        static var border: Color { activePalette.border }
        static var selectedBorder: Color { activePalette.selectedBorder }

        // System colors for states — theme-independent
        static let error = Color(.systemRed)
        static let success = Color(hex: "#01780F")
        static let hint = Color(.systemOrange)
        static let preFilledBackground = Color(.systemBlue).opacity(0.15) // Muted blue-grey for pre-filled cells
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
