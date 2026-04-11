# Styling Brief — Simple Cryptogram

A minimalist, typography-first SwiftUI aesthetic. The look is quiet, paper-like, and uncluttered: lowercase text, low-contrast chrome, generous whitespace, and SF Symbols instead of decorative UI. Reproduce this feel in another project by following the conventions below.

## Core Aesthetic Principles

1. **Quiet over loud.** Icons sit at `opacity 0.7`, secondary text at `opacity 0.4–0.8`. Nothing shouts. There are no filled buttons, no drop shadows on content, no gradients.
2. **Typography is the UI.** Most "buttons" are just `Text` with `PlainButtonStyle()` and vertical padding. No borders, no backgrounds, no chrome. The type itself is the tap target.
3. **Lowercase everywhere.** All user-facing copy is lowercase ("play", "daily puzzle", "or select length", "short / medium / long"). Never title-case or sentence-case UI labels.
4. **Whitespace is structural.** Large `Spacer()` stacks center content vertically. Generous `VStack(spacing: 20–50)` between primary actions.
5. **Monochrome with one accent.** The palette is derived from a single hue + saturation + light/dark flag. Color is used sparingly — a single muted green for success, system red for errors, system orange for hints.
6. **Overlays, not sheets.** Secondary screens fade in as full-screen overlays at 98% background opacity with a tiny `xmark` dismiss button in the top-right. No native `.sheet`, no nav bars.

## Color System

Colors are **computed from HSB**, not hardcoded. A single `ColorPalette.forHue(hue, saturation, isDark)` function derives the full palette. This makes themes cheap to add.

```swift
// Light mode
background:     Color(hue: h, saturation: s * 0.14, brightness: 0.97)
text:           Color(hue: h, saturation: s * 0.15, brightness: 0.33)
surface:        Color(hue: h, saturation: s * 0.08, brightness: 1.00)
border:         Color(hue: h, saturation: s * 0.10, brightness: 0.90)
selectedBorder: Color(hue: h, saturation: s * 0.45, brightness: 0.49)

// Dark mode
background:     Color(hue: h, saturation: s * 0.18, brightness: 0.14)
text:           Color(hue: h, saturation: s * 0.08, brightness: 0.83)
surface:        Color(hue: h, saturation: s * 0.14, brightness: 0.22)
border:         Color(hue: h, saturation: s * 0.10, brightness: 0.35)
selectedBorder: Color(hue: h, saturation: s * 0.45, brightness: 0.75)
```

**Key point:** saturation is always *scaled down* (×0.08–0.18) before being applied to background/text/surface. Even the "colored" themes are barely tinted — they read as off-whites and warm grays, not as color. Only `selectedBorder` uses meaningful saturation.

### Theme presets (hue, saturation)
```
light    (0,    0)
dark     (0,    0)
cream    (0.08, 0.8)
ocean    (0.58, 0.8)
sage     (0.35, 0.8)
rose     (0.95, 0.8)
lavender (0.75, 0.8)
slate    (0.60, 0.5)
```

### Fixed state colors (theme-independent)
```swift
error             = Color(.systemRed)
success           = Color(hex: "#01780F")    // muted forest green
hint              = Color(.systemOrange)
preFilledBackground = Color(.systemBlue).opacity(0.15)
```

## Typography

One `Typography` struct exposes semantic slots, all keyed off a user-selectable `FontOption` (System / Rounded / Serif / Monospaced). Views **never** call `Font.system(...)` directly for body copy — they read `@Environment(\.typography)`.

```swift
title    = Font.system(.title,    design: fontOption.design)
body     = Font.system(.body,     design: fontOption.design)
button   = Font.system(.body,     design: fontOption.design)
caption  = Font.system(.caption,  design: fontOption.design)
footnote = Font.system(.footnote, design: fontOption.design)
// cell is always monospaced regardless of user font choice
cell     = Font.system(.title2,   design: .monospaced)
```

Typography is injected at the root via `.injectTypography()` and consumed with `@Environment(\.typography) private var typography`.

**Weight/emphasis:** selected/active items use `.fontWeight(.bold)`; everything else is `.regular`. Italic is used sparingly for hint text ("or select length").

## Layout Constants

Centralize spacing/sizing in a single enum so values never get hardcoded in views.

```swift
enum Spacing {
    static let topBarPadding:               CGFloat = 16
    static let mainContentHorizontalPadding:CGFloat = 12
    static let bottomBarHeight:             CGFloat = 48
    static let bottomBarHorizontalPadding:  CGFloat = 64
}

enum Sizes {
    static let iconButtonFrame:   CGFloat = 44   // always 44×44 hit target
    static let statsIconSize:     CGFloat = 20
    static let settingsIconSize:  CGFloat = 24
    static let questionMarkSize:  CGFloat = 13
}

enum Animation {
    static let overlayDuration:        TimeInterval = 0.3
    static let puzzleSwitchDuration:   TimeInterval = 0.5
    static let bottomBarAutoHideDelay: TimeInterval = 3.0
}

enum Overlay {
    static let backgroundOpacity:        Double  = 0.98
    static let overlayHorizontalPadding: CGFloat = 24
}

// Corner radii
buttonCornerRadius: 8
cellCornerRadius:   4
```

## Component Patterns

### Text buttons (the default)
```swift
Button(action: { ... }) {
    Text("play")
        .font(typography.body)
        .foregroundColor(CryptogramTheme.Colors.text)
        .padding(.vertical, 8)
}
.buttonStyle(PlainButtonStyle())
```
No background, no border. Just text with vertical padding.

### Icon buttons
```swift
Button(action: { ... }) {
    Image(systemName: "gearshape")
        .font(.system(size: 24))
        .foregroundColor(CryptogramTheme.Colors.text)
        .opacity(0.7)                    // always 0.7 for idle icons
        .frame(width: 44, height: 44)    // always 44×44 hit target
}
```
Use SF Symbols exclusively. Common icons used: `gearshape`, `chart.bar`, `questionmark`, `xmark`, `calendar`, `book.closed`, `timeline.selection`, `dice`, `checkmark`.

### Full-screen overlays (instead of sheets)
```swift
if showSettings {
    FullScreenOverlay(isPresented: $showSettings) {
        SettingsContentView()
    }
}
```
The overlay container:
- Fills the screen with `background.opacity(0.98)`
- Tap outside dismisses
- Tiny `xmark` button (size 10, weight .medium, opacity 0.6) in top-right at `(top: 50, trailing: 20)`
- Transitions via `.opacity` with `.easeInOut(duration: 0.3)`

### Home/main screen pattern
```swift
ZStack {
    CryptogramTheme.Colors.background.ignoresSafeArea()

    VStack(spacing: 0) {
        VStack(spacing: 20) {
            Spacer(); Spacer(); Spacer()   // push content below center
            // primary actions
            Spacer()
        }
        // bottom bar with auto-hide
    }
}
```
Content is vertically centered-ish (slightly below center via stacked `Spacer()`s). Bottom bar auto-hides after 3s; tap anywhere to bring it back.

### Settings rows
Selected state is conveyed by **font weight + opacity**, not color:
```swift
.font(typography.footnote)
.fontWeight(isSelected ? .bold : .regular)
.foregroundColor(isSelected
    ? Colors.text
    : Colors.text.opacity(0.4))
```

## What to Avoid

- **No filled/tinted buttons** as primary affordances. If you need one, it's probably the wrong pattern for this style.
- **No drop shadows** on content (only on the legacy `CryptogramButton` modifier, which is rarely used).
- **No rounded cards, no material blur, no gradients, no stroke borders around content blocks.**
- **No title-case or ALL CAPS** labels.
- **No sheets or navigation bars** for secondary content — use full-screen overlays with the xmark dismiss.
- **No hardcoded colors** in views — always go through `CryptogramTheme.Colors` so theme switching works.
- **No hardcoded fonts** in views for body copy — always go through `@Environment(\.typography)`.
- **No hardcoded spacing** for anything reusable — promote it to the layout constants enum.

## Quick Checklist for New Views

- [ ] Background is `Colors.background.ignoresSafeArea()`
- [ ] All text pulls font from `@Environment(\.typography)`
- [ ] All colors pull from `CryptogramTheme.Colors`
- [ ] Labels are lowercase
- [ ] Buttons are `Text` + `PlainButtonStyle()` unless there's a real reason otherwise
- [ ] Icons are SF Symbols at `opacity 0.7`, framed 44×44
- [ ] Secondary screens use full-screen overlays, not sheets
- [ ] Spacing/sizing constants live in a shared enum, not inline
- [ ] Selected state = bold + full-opacity text; unselected = regular + `opacity(0.4)`
- [ ] Animations use `.easeInOut(duration: 0.2–0.3)`
