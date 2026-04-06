import SwiftUI

struct SettingsContentView: View {
    @Environment(PuzzleViewModel.self) private var puzzleViewModel
    @Environment(ThemeManager.self) private var themeManager
    @Environment(AppSettings.self) private var appSettings
    @Environment(\.typography) private var typography

    // Dropdown state — only one can be open at a time
    @State private var expandedDropdown: SettingsDropdown?

    private enum SettingsDropdown: Equatable {
        case quoteLength
        case textSize
        case font
        case colorTheme
        case buttonLayout
        case prompts

        static let themeDropdowns: Set<SettingsDropdown> = [.textSize, .font, .colorTheme, .buttonLayout]
    }

    private var isDropdownOpen: Bool { expandedDropdown != nil }

    /// True when this content should be invisible (faded to background)
    private func isDimmed(keepVisible dropdown: SettingsDropdown? = nil) -> Bool {
        isDropdownOpen && expandedDropdown != dropdown
    }

    /// True when content should be dimmed unless one of several dropdowns is active
    private func isDimmed(keepVisibleAny dropdowns: Set<SettingsDropdown>) -> Bool {
        guard let expanded = expandedDropdown else { return false }
        return !dropdowns.contains(expanded)
    }

    // Computed bindings for AppSettings
    private var selectedEncodingType: Binding<String> {
        Binding(
            get: { appSettings.encodingType },
            set: { appSettings.encodingType = $0 }
        )
    }

    private func toggleDropdown(_ dropdown: SettingsDropdown) {
        withAnimation(.easeInOut(duration: 0.3)) {
            expandedDropdown = expandedDropdown == dropdown ? nil : dropdown
        }
    }

    var body: some View {
        @Bindable var settings = appSettings

        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 20) {
                Spacer().frame(height: 60)

                // MARK: - Gameplay
                SettingsSection(title: "gameplay") {
                    VStack(spacing: 15) {
                        // Encoding toggle
                        ToggleOptionRow(
                            leftOption: ("Letters", "abc"),
                            rightOption: ("Numbers", "123"),
                            selection: selectedEncodingType
                        )
                        .dim(isDimmed())

                        // Quote Length
                        dropdownTrigger(
                            label: "quote length",
                            value: appSettings.quoteLengthDisplayText,
                            dropdown: .quoteLength
                        )
                        .dim(isDimmed(keepVisible: .quoteLength))

                        if expandedDropdown == .quoteLength {
                            HStack(spacing: 4) {
                                MultiCheckboxRow(
                                    title: "short",
                                    isSelected: appSettings.isLengthSelected("easy"),
                                    action: { appSettings.toggleLength("easy") }
                                )
                                MultiCheckboxRow(
                                    title: "medium",
                                    isSelected: appSettings.isLengthSelected("medium"),
                                    action: { appSettings.toggleLength("medium") }
                                )
                                MultiCheckboxRow(
                                    title: "long",
                                    isSelected: appSettings.isLengthSelected("hard"),
                                    action: { appSettings.toggleLength("hard") }
                                )
                            }
                            .frame(maxWidth: .infinity)
                            .transition(.move(edge: .top).combined(with: .opacity))
                        }
                    }
                }
                .dim(isDimmed(keepVisible: .quoteLength))

                // MARK: - Theme & Layout
                SettingsSection(title: "theme & layout") {
                    VStack(spacing: 15) {
                        // Theme icons + color picker
                        VStack(spacing: 0) {
                            HStack {
                                Spacer()

                                IconToggleButton(
                                    iconName: "sun.max",
                                    isSelected: !appSettings.isRandomThemeEnabled && appSettings.themePreset == ThemePreset.light.rawValue,
                                    action: { appSettings.applyPreset(.light) },
                                    accessibilityLabel: "Light theme"
                                )
                                .padding(.trailing, 6)

                                IconToggleButton(
                                    iconName: "moon.stars",
                                    isSelected: !appSettings.isRandomThemeEnabled && appSettings.themePreset == ThemePreset.dark.rawValue,
                                    action: { appSettings.applyPreset(.dark) },
                                    accessibilityLabel: "Dark theme"
                                )
                                .padding(.trailing, 6)

                                IconToggleButton(
                                    iconName: "die.face.3",
                                    isSelected: appSettings.isRandomThemeEnabled,
                                    action: {
                                        appSettings.isRandomThemeEnabled.toggle()
                                        if appSettings.isRandomThemeEnabled {
                                            appSettings.applyRandomTheme()
                                        }
                                    },
                                    accessibilityLabel: "Random theme"
                                )
                                .padding(.trailing, 6)

                                Button {
                                    toggleDropdown(.colorTheme)
                                } label: {
                                    if !appSettings.isRandomThemeEnabled, let activeColor = ThemePreset(rawValue: appSettings.themePreset), activeColor.isColor {
                                        Circle()
                                            .fill(activeColor.previewColor)
                                            .frame(width: 18, height: 18)
                                            .overlay(
                                                Circle().strokeBorder(CryptogramTheme.Colors.text, lineWidth: 1.5)
                                            )
                                    } else {
                                        Image(systemName: "ellipsis.circle")
                                            .font(.system(size: 15, weight: .medium))
                                            .foregroundColor(CryptogramTheme.Colors.text.opacity(expandedDropdown == .colorTheme ? 1 : 0.4))
                                    }
                                }
                                .buttonStyle(PlainButtonStyle())
                                .accessibilityLabel("Color themes")

                                Spacer()
                            }
                            .padding(.vertical, 15)
                            .dim(isDimmed(keepVisible: .colorTheme))

                            if expandedDropdown == .colorTheme {
                                HStack(spacing: 12) {
                                    ForEach(ThemePreset.colorPresets) { preset in
                                        Button {
                                            appSettings.applyPreset(preset)
                                        } label: {
                                            Circle()
                                                .fill(preset.previewColor)
                                                .frame(width: 18, height: 18)
                                                .overlay(
                                                    Circle().strokeBorder(CryptogramTheme.Colors.text, lineWidth: appSettings.themePreset == preset.rawValue ? 1.5 : 0)
                                                )
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                        .accessibilityLabel(preset.displayName)
                                    }
                                }
                                .padding(.vertical, 8)
                                .transition(.move(edge: .top).combined(with: .opacity))
                            }
                        }

                        // Text Size
                        dropdownTrigger(
                            label: "text size",
                            value: appSettings.textSize.displayName.lowercased(),
                            dropdown: .textSize
                        )
                        .dim(isDimmed(keepVisible: .textSize))

                        if expandedDropdown == .textSize {
                            HStack(spacing: 16) {
                                ForEach(TextSizeOption.allCases) { opt in
                                    Button {
                                        appSettings.textSize = opt
                                    } label: {
                                        VStack(spacing: 4) {
                                            Text("A")
                                                .font(.system(size: opt.inputSize,
                                                              weight: appSettings.textSize == opt ? .bold : .regular,
                                                              design: typography.fontOption.design))
                                                .foregroundColor(CryptogramTheme.Colors.text.opacity(appSettings.textSize == opt ? 1 : 0.4))
                                            Rectangle()
                                                .frame(height: 1)
                                                .foregroundColor(CryptogramTheme.Colors.border)
                                            Text(opt == .small ? "4" : opt == .medium ? "2" : "0")
                                                .font(.system(size: opt.encodedSize,
                                                              weight: appSettings.textSize == opt ? .bold : .regular,
                                                              design: typography.fontOption.design))
                                                .foregroundColor(CryptogramTheme.Colors.text.opacity(appSettings.textSize == opt ? 1 : 0.4))
                                        }
                                        .frame(width: 28)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .transition(.move(edge: .top).combined(with: .opacity))
                        }

                        // Font
                        dropdownTrigger(
                            label: "font",
                            value: appSettings.fontFamily.rawValue.lowercased(),
                            dropdown: .font
                        )
                        .dim(isDimmed(keepVisible: .font))

                        if expandedDropdown == .font {
                            VStack(spacing: 0) {
                                ForEach(FontOption.allCases, id: \.self) { font in
                                    Button {
                                        appSettings.fontFamily = font
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            expandedDropdown = nil
                                        }
                                    } label: {
                                        Text(font.rawValue.lowercased())
                                            .font(.system(.footnote, design: font.design))
                                            .fontWeight(appSettings.fontFamily == font ? .bold : .regular)
                                            .foregroundColor(CryptogramTheme.Colors.text.opacity(appSettings.fontFamily == font ? 1 : 0.6))
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 8)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .transition(.move(edge: .top).combined(with: .opacity))
                        }

                        // Button Layout
                        dropdownTrigger(
                            label: "button layout",
                            value: settings.navigationBarLayout.displayName,
                            dropdown: .buttonLayout
                        )
                        .dim(isDimmed(keepVisible: .buttonLayout))

                        if expandedDropdown == .buttonLayout {
                            VStack(spacing: 10) {
                                MultiOptionRow(
                                    options: NavigationBarLayout.allCases.sorted { $0.rawValue < $1.rawValue },
                                    selection: $settings.navigationBarLayout,
                                    labelProvider: { $0.displayName }
                                )

                                NavBarLayoutPreview(layout: settings.navigationBarLayout)
                                    .padding(.horizontal, 10)
                                    .padding(.bottom, 5)
                            }
                            .padding(.top, 8)
                            .transition(.move(edge: .top).combined(with: .opacity))
                        }
                    }
                }
                .dim(isDimmed(keepVisibleAny: SettingsDropdown.themeDropdowns))

                // MARK: - AI Assistant
                SettingsSection(title: "ai assistant") {
                    VStack(spacing: 12) {
                        // App toggles
                        HStack(spacing: 4) {
                            ForEach(LLMApp.allCases) { app in
                                MultiCheckboxRow(
                                    title: app.rawValue.lowercased(),
                                    isSelected: appSettings.isLLMAppEnabled(app),
                                    action: { appSettings.toggleLLMApp(app) }
                                )
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .dim(isDimmed())

                        // Prompt previews
                        dropdownTrigger(
                            label: expandedDropdown == .prompts ? "hide prompts" : "view prompts",
                            value: nil,
                            dropdown: .prompts
                        )
                        .dim(isDimmed(keepVisible: .prompts))

                        if expandedDropdown == .prompts {
                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(LLMPrompt.builtIn) { prompt in
                                    VStack(alignment: .leading, spacing: 2) {
                                        Label(prompt.label, systemImage: prompt.icon)
                                            .font(typography.caption)
                                            .foregroundColor(CryptogramTheme.Colors.text)
                                        Text(prompt.buildPrompt("\"The unexamined life...\"", "Socrates"))
                                            .font(typography.caption)
                                            .foregroundColor(CryptogramTheme.Colors.text.opacity(0.5))
                                            .lineLimit(2)
                                    }
                                }
                            }
                            .padding(.horizontal, 10)
                            .transition(.move(edge: .top).combined(with: .opacity))
                        }
                    }
                    .padding(.vertical, 8)
                }
                .dim(isDimmed(keepVisible: .prompts))

                // MARK: - Reset
                ResetAccountSection(viewModel: puzzleViewModel)
                    .dim(isDimmed())

                Spacer().frame(height: 40)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: expandedDropdown)
    }

    // MARK: - Unified Dropdown Trigger

    @ViewBuilder
    private func dropdownTrigger(label: String, value: String?, dropdown: SettingsDropdown) -> some View {
        Button {
            toggleDropdown(dropdown)
        } label: {
            HStack {
                Spacer()
                if let value {
                    Text("\(label): ")
                        .font(typography.footnote)
                        .foregroundColor(CryptogramTheme.Colors.text) +
                    Text(value)
                        .font(typography.footnote)
                        .fontWeight(.bold)
                        .foregroundColor(CryptogramTheme.Colors.text)
                } else {
                    Text(label)
                        .font(typography.footnote)
                        .foregroundColor(CryptogramTheme.Colors.text)
                }
                Image(systemName: expandedDropdown == dropdown ? "chevron.up" : "chevron.down")
                    .font(.system(size: 12, weight: .medium, design: typography.fontOption.design))
                    .foregroundColor(CryptogramTheme.Colors.text)
                    .padding(.leading, 4)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Dim Modifier

private extension View {
    /// Fades to invisible and disables interaction. Content stays in layout.
    func dim(_ shouldDim: Bool) -> some View {
        self
            .opacity(shouldDim ? 0 : 1)
            .allowsHitTesting(!shouldDim)
    }
}

// PreferenceKey to help with centering if needed
struct HStackWidthPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
