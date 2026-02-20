# Theme System: Option B — Hardcoded Presets + Future Custom Themes

## Current State (Phase 1–2)

- HSB derivation engine: `ColorPalette.forHue(hue, saturation, isDark)` derives 5 colors
- Light/dark toggle is separate from color choice
- Colored themes are tinted light/dark — not independent themes

## Target Architecture

Each theme is a standalone palette. Light and dark are just two of many equal themes. No separate light/dark toggle — the theme *is* the mode.

### Core Palette: 2 Primary + 3 Derived

Instead of 5 independent colors per theme, define **2 core colors** and derive the rest:

| Color | Role | Source |
|-------|------|--------|
| **background** | Full-screen fill, overlay bg | **User/designer picks** |
| **text** | Body text, labels, icons | **User/designer picks** |
| **surface** | Cell fill, cards — sits on top of background | Derived from background (lighten/darken ~5-8%) |
| **border** | Cell borders, dividers | Derived: blend ~70% background + ~30% text |
| **selectedBorder** | Active cell highlight, focus ring | Fixed color OR formula-derived (see below) |

### Derivation Rules

```
surface = background adjusted toward white (light themes) or toward lighter (dark themes)
           — e.g. blend(background, white, 0.05–0.08) for light
           — e.g. blend(background, white, 0.08–0.12) for dark

border  = blend(background, text, 0.25–0.35)
           — sits between background and text on the brightness scale
           — closer to background than text

selectedBorder = TBD, two options:
  Option A: Fixed accent (e.g. always the same blue, like classic theme uses now)
  Option B: Derive from background hue — e.g. complementary hue, or
            offset hue by ~0.5 with moderate saturation and mid brightness
```

### selectedBorder — Open Question

The accent color is the hardest to auto-derive. Options:

1. **Fixed blue** — simple, always works, current classic behavior. Downside: doesn't feel "themed."
2. **Derive from background hue** — e.g. complementary (hue + 0.5) or analogous (hue + 0.15). Risk: some combos look bad.
3. **Third designer-picked color per preset** — most control, slightly more to maintain. For the ~8 curated presets this is trivial. For future "custom theme" (user picks 2 colors), fall back to option 1 or 2.

Recommendation: for curated presets, hand-pick the accent (option 3). For future custom themes, use fixed blue (option 1) as the safe default.

## Preset Themes (~8)

Each preset stores 2 core colors + 1 accent. The other 2 are derived.

```
light       — white bg, dark text, blue accent
dark        — near-black bg, light gray text, blue accent
cream       — warm off-white bg, brown text, amber accent
ocean       — pale blue bg, navy text, coral accent
sage        — pale green bg, dark green text, gold accent
rose        — pale pink bg, deep rose text, mauve accent
lavender    — pale purple bg, dark purple text, indigo accent
slate       — cool gray bg, charcoal text, blue accent
```

These are starting points — exact hex values TBD when implementing.

## Data Model

```swift
struct ColorPalette {
    let background: Color
    let text: Color
    let surface: Color      // derived
    let border: Color       // derived
    let selectedBorder: Color
    let isDark: Bool        // inferred from background brightness

    /// Create a palette from 2 core colors + accent. Derives surface and border.
    static func from(background: Color, text: Color, accent: Color) -> ColorPalette { ... }
}

enum ThemePreset: String, CaseIterable, Identifiable {
    case light, dark, cream, ocean, sage, rose, lavender, slate

    var palette: ColorPalette { ... }   // returns hardcoded/derived palette
    var previewColor: Color { ... }     // dot swatch for picker UI
}
```

`isDark` can be inferred from background brightness (< 0.5 = dark) to set `.preferredColorScheme` automatically.

## UI

- Single row of color dots in settings (no separate light/dark toggle)
- Light = white/light gray dot, Dark = dark dot, others = their background color
- Tapping a dot applies the full theme immediately

## Migration Path

1. Replace `ThemePreset` enum — add `isDark` per preset, define core colors
2. Replace `ColorPalette.forHue()` with `ColorPalette.from(background:text:accent:)`
3. Remove `themeHue` / `themeSaturation` from AppSettings — replace with `themePreset` only
4. Remove `isDarkMode` toggle from AppSettings — infer from active preset
5. Update `.preferredColorScheme` to read from active palette's `isDark`
6. Update settings UI — remove sun/moon, keep dot picker as sole theme chooser
7. Keep `ColorPalette.forHue()` in codebase for future "custom theme" feature

## Future: Custom Theme

User picks 2 colors (background + text) via color picker. Accent defaults to fixed blue (or derived). Uses `ColorPalette.from(background:text:accent:)` — same pipeline as presets. Stored as raw color values in UserDefaults alongside the preset enum.
