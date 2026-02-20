import SwiftUI

/// A complete set of derived colors for a theme.
struct ColorPalette {
    let background: Color
    let text: Color
    let surface: Color
    let border: Color
    let selectedBorder: Color

    /// Whether this palette is dark (for .preferredColorScheme).
    let isDark: Bool

    /// Derive a full palette from a hue (0–1), saturation (0–1), and light/dark flag.
    /// Saturation 0 = neutral gray (classic theme) with a fixed blue selectedBorder.
    static func forHue(_ hue: Double, saturation: Double, isDark: Bool) -> ColorPalette {
        // Selected border: classic (unsaturated) uses fixed blue; colored themes use theme hue
        let sbHue: Double
        let sbSat: Double
        if saturation < 0.01 {
            sbHue = 0.60
            sbSat = isDark ? 0.47 : 0.44
        } else {
            sbHue = hue
            sbSat = saturation * 0.45
        }

        if isDark {
            return ColorPalette(
                background:     Color(hue: hue, saturation: saturation * 0.18, brightness: 0.14),
                text:           Color(hue: hue, saturation: saturation * 0.08, brightness: 0.83),
                surface:        Color(hue: hue, saturation: saturation * 0.14, brightness: 0.22),
                border:         Color(hue: hue, saturation: saturation * 0.10, brightness: 0.35),
                selectedBorder: Color(hue: sbHue, saturation: sbSat, brightness: 0.75),
                isDark: true
            )
        } else {
            return ColorPalette(
                background:     Color(hue: hue, saturation: saturation * 0.14, brightness: 0.97),
                text:           Color(hue: hue, saturation: saturation * 0.15, brightness: 0.33),
                surface:        Color(hue: hue, saturation: saturation * 0.08, brightness: 1.0),
                border:         Color(hue: hue, saturation: saturation * 0.10, brightness: 0.90),
                selectedBorder: Color(hue: sbHue, saturation: sbSat, brightness: 0.49),
                isDark: false
            )
        }
    }
}

enum ThemePreset: String, CaseIterable, Identifiable {
    case light, dark, cream, ocean, sage, rose, lavender, slate

    var id: String { rawValue }

    var hue: Double {
        switch self {
        case .light:    return 0
        case .dark:     return 0
        case .cream:    return 0.08
        case .ocean:    return 0.58
        case .sage:     return 0.35
        case .rose:     return 0.95
        case .lavender: return 0.75
        case .slate:    return 0.60
        }
    }

    var saturation: Double {
        switch self {
        case .light:    return 0
        case .dark:     return 0
        case .slate:    return 0.5
        default:        return 0.8
        }
    }

    var isDark: Bool {
        self == .dark
    }

    var displayName: String { rawValue }

    /// Whether this is a color preset (not plain light/dark)
    var isColor: Bool { self != .light && self != .dark }

    /// All color presets (excludes light and dark)
    static var colorPresets: [ThemePreset] {
        allCases.filter { $0.isColor }
    }

    /// Swatch color for the picker dot
    var previewColor: Color {
        switch self {
        case .light:    return Color(hue: 0, saturation: 0, brightness: 0.95)
        case .dark:     return Color(hue: 0, saturation: 0, brightness: 0.2)
        default:        return Color(hue: hue, saturation: saturation * 0.6, brightness: 0.7)
        }
    }
}
