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
                background:     Color(hue: hue, saturation: saturation * 0.08, brightness: 0.14),
                text:           Color(hue: hue, saturation: saturation * 0.04, brightness: 0.83),
                surface:        Color(hue: hue, saturation: saturation * 0.06, brightness: 0.22),
                border:         Color(hue: hue, saturation: saturation * 0.05, brightness: 0.35),
                selectedBorder: Color(hue: sbHue, saturation: sbSat, brightness: 0.75),
                isDark: true
            )
        } else {
            return ColorPalette(
                background:     Color(hue: hue, saturation: saturation * 0.04, brightness: 0.97),
                text:           Color(hue: hue, saturation: saturation * 0.10, brightness: 0.33),
                surface:        Color(hue: hue, saturation: saturation * 0.02, brightness: 1.0),
                border:         Color(hue: hue, saturation: saturation * 0.04, brightness: 0.90),
                selectedBorder: Color(hue: sbHue, saturation: sbSat, brightness: 0.49),
                isDark: false
            )
        }
    }
}
