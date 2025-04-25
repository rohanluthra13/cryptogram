# SettingsContentView Refactoring Implementation Plan

## Overview
The current `SettingsContentView` (`Views/Components/SettingsContentView.swift`) suffers from:
- Inconsistent spacing and hard-coded layout values
- Complex nested view hierarchy
- Custom toggles lacking a unified style
- Info panels that shift other content when shown
- Mixed styling approaches outside the theme system

This plan refactors the view into modular, theme-driven components with reusable toggles and info support.

## Dependencies & Existing Components
- **ViewModifiers.swift** – will add new `SettingsToggleStyle`
- **SettingsSection** – wrapper for each settings group
- **ToggleOptionRow** – binary toggle UI
- **InfoPanel** – expandable info overlay
- **MultiCheckboxRow** – grouped length selectors
- **IconToggleButton** – icon-based toggles
- **NavBarLayoutSelector** – layout preview selector
- **ThemeManager**, **SettingsViewModel**, **PuzzleViewModel**, **CryptogramTheme**

## Goals
1. Modular section‑based design
2. Reusable, theme‑aware toggle components with info buttons
3. Info panels overlay without shifting layout
4. Maintain current animations and state persistence
5. Clean, consistent spacing via theme modifiers
6. Enable easy future extensions

## Detailed Steps

1. **Add ViewModifier** (`ViewModifiers.swift`)
   - Create `struct SettingsToggleStyle: ViewModifier` with parameters `isSelected: Bool`.
   - Apply font, weight, padding, background/foreground from `CryptogramTheme`.

2. **Enhance ToggleOptionRow**
   - Add optional properties `showInfoButton: Bool` and `onInfoButtonTap: () -> Void`.
   - Render an info button when `showInfoButton == true`, invoking `onInfoButtonTap`.
   - Wrap labels in `modifier(SettingsToggleStyle(isSelected: ...))`.

3. **Refine InfoPanel**
   - Change from inline stacking to `.overlay` with high Z-index.
   - Animate appearance using `.transition(.opacity.combined(with: .move(edge: .top)))`.
   - Ensure it does not alter parent layout size by using `fixedSize()` or `background`.

4. **Update MultiCheckboxRow**
   - Apply `SettingsToggleStyle` to label and checkbox.
   - Center items using `HStack` with `Spacer()` and fixed width via `GeometryReader` preference.

5. **Polish IconToggleButton & NavBarLayoutSelector**
   - Use `SettingsToggleStyle` for icon labels.
   - Add consistent padding and accessibility labels.
   - Ensure theme colors via `CryptogramTheme.Colors.surface` and `.text`.

6. **Split SettingsContentView** (`SettingsContentView.swift`)
   - Extract `GameplaySection` and `AppearanceSection` into private subviews.
   - Remove hard‑coded `.frame(height: 160)` and replace with `padding(.top, value)` from theme.
   - Use `@ViewBuilder` closures for clarity and smaller body.
   - Manage state (`showDifficultyInfo`, `showLengthSelector`) locally within `GameplaySection`.
   - Apply `.animation` modifiers at section scope.

7. **Testing & Validation**
   - Verify AppStorage bindings and `SettingsViewModel` updates.
   - Test info toggles, dropdown transitions, and dark/light modes on device/simulator.
   - Add SwiftUI previews for each section and state.

## File Mapping
- **ViewModifiers.swift**: add `SettingsToggleStyle`
- **ToggleOptionRow.swift**: extend signature + styling
- **InfoPanel.swift**: change to overlay + animations
- **MultiCheckboxRow.swift**: styling + alignment
- **SettingsContentView.swift**: reorganize into sub‑views and apply new modifiers

## Summary
This refactoring delivers a maintainable, theme‑driven `SettingsContentView`, with modular components and consistent styling, simplifying future updates and ensuring a polished UX.
