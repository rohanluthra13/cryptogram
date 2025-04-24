import SwiftUI

struct SettingsContentView: View {
    @AppStorage("encodingType") private var selectedEncodingType = "Letters"
    @AppStorage("isDarkMode") private var isDarkMode = false
    @AppStorage("selectedDifficulties") private var selectedDifficulties = "easy,medium,hard" // default all selected
    @EnvironmentObject private var puzzleViewModel: PuzzleViewModel
    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject private var settingsViewModel: SettingsViewModel
    
    // State properties for info panels
    @State private var showDifficultyInfo = false
    @State private var showLengthSelector = false
    @State private var showTextSizeSelector = false
    
    // Info text for difficulty
    private let difficultyInfoText = "normal mode gives you some starting letters.\nexpert mode does not."
    private let lengthInfoText = "easy: short quotes (13-49 chars)\nmedium: medium quotes (50-99 chars)\nhard: long quotes (100+ chars)"
    
    var body: some View {
        VStack(spacing: 20) {
            // Top spacing to position content as needed
            Spacer()
                .frame(height: 100)
            
            // Gameplay Section
            SettingsSection(title: "gameplay") {
                VStack(spacing: 15) {
                    // Difficulty toggle with info support
                    ToggleOptionRow(
                        leftOption: (DifficultyMode.normal, DifficultyMode.normal.displayName.lowercased()),
                        rightOption: (DifficultyMode.expert, DifficultyMode.expert.displayName.lowercased()),
                        selection: $settingsViewModel.selectedMode,
                        showInfoButton: true,
                        onInfoButtonTap: {
                            withAnimation {
                                showDifficultyInfo.toggle()
                                if showLengthSelector { showLengthSelector = false }
                            }
                        }
                    )
                    
                    ZStack {
                        // Info panel for difficulty
                        InfoPanel(
                            infoText: difficultyInfoText,
                            isVisible: $showDifficultyInfo
                        )
                        .padding(.top, 8)
                        
                        // Encoding toggle and length dropdown (hidden when info is shown)
                        if !showDifficultyInfo {
                            VStack(spacing: 15) {
                                // Encoding toggle
                                ToggleOptionRow(
                                    leftOption: ("Letters", "abc"),
                                    rightOption: ("Numbers", "123"),
                                    selection: $selectedEncodingType
                                )
                                .transition(.opacity)
                                
                                // Quote Length Dropdown Toggle
                                Button(action: {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        showLengthSelector.toggle()
                                    }
                                }) {
                                    HStack {
                                        Spacer()
                                        
                                        Text("character length: ")
                                            .font(.footnote)
                                            .foregroundColor(CryptogramTheme.Colors.text) +
                                        Text(settingsViewModel.quoteRangeDisplayText)
                                            .font(.footnote)
                                            .fontWeight(.bold)
                                            .foregroundColor(CryptogramTheme.Colors.text)
                                        
                                        Image(systemName: showLengthSelector ? "chevron.up" : "chevron.down")
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundColor(CryptogramTheme.Colors.text)
                                            .padding(.leading, 4)
                                        
                                        Spacer()
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(CryptogramTheme.Colors.surface)
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                // Show checkboxes when expanded
                                if showLengthSelector {
                                    HStack(spacing: 4) {
                                        MultiCheckboxRow(
                                            title: "< 50",
                                            isSelected: settingsViewModel.isLengthSelected("easy"),
                                            action: { settingsViewModel.toggleLength("easy") }
                                        )
                                        MultiCheckboxRow(
                                            title: "50 - 99",
                                            isSelected: settingsViewModel.isLengthSelected("medium"),
                                            action: { settingsViewModel.toggleLength("medium") }
                                        )
                                        MultiCheckboxRow(
                                            title: "100 +",
                                            isSelected: settingsViewModel.isLengthSelected("hard"),
                                            action: { settingsViewModel.toggleLength("hard") }
                                        )
                                    }
                                    .frame(maxWidth: .infinity)
                                    .contentShape(Rectangle())
                                    .overlay(
                                        GeometryReader { geometry in
                                            Color.clear.preference(key: HStackWidthPreferenceKey.self, value: geometry.size.width)
                                        }
                                    )
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .transition(.move(edge: .top).combined(with: .opacity))
                                    .padding(.top, 0)
                                }
                            }
                        }
                    }
                }
            }
            
            // Appearance Section - only visible when no info panels are shown
            if !showDifficultyInfo && !showLengthSelector {
                SettingsSection(title: "theme & layout") {
                    VStack(spacing: 15) {
                        // Dark mode toggle with icons
                        HStack {
                            Spacer()
                            
                            // Light mode
                            IconToggleButton(
                                iconName: "sun.max",
                                isSelected: !isDarkMode,
                                action: {
                                    if isDarkMode {
                                        isDarkMode = false
                                        themeManager.applyTheme()
                                    }
                                },
                                accessibilityLabel: "Switch to Light mode"
                            )
                            .padding(.trailing, 6)
                            
                            // Toggle arrow
                            Button(action: {
                                isDarkMode.toggle()
                                themeManager.applyTheme()
                            }) {
                                Image(systemName: !isDarkMode ? "arrow.right" : "arrow.left")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(CryptogramTheme.Colors.text)
                            }
                            .accessibilityLabel("Toggle dark mode")
                            .padding(.horizontal, 6)
                            
                            // Dark mode
                            IconToggleButton(
                                iconName: "moon.stars",
                                isSelected: isDarkMode,
                                action: {
                                    if !isDarkMode {
                                        isDarkMode = true
                                        themeManager.applyTheme()
                                    }
                                },
                                accessibilityLabel: "Switch to Dark mode"
                            )
                            .padding(.leading, 6)
                            
                            Spacer()
                        }
                        .padding(.vertical, 15)
                        
                        // Text Size Dropdown
                        VStack(spacing: 8) {
                            Button {
                                withAnimation(.easeInOut) { showTextSizeSelector.toggle() }
                            } label: {
                                HStack {
                                    Spacer()
                                    Text("text size:")
                                        .font(.footnote)
                                        .foregroundColor(CryptogramTheme.Colors.text)
                                    Text(settingsViewModel.textSize.displayName.lowercased())
                                        .font(.footnote).fontWeight(.bold)
                                        .foregroundColor(CryptogramTheme.Colors.text)
                                    Image(systemName: showTextSizeSelector ? "chevron.up" : "chevron.down")
                                        .font(.system(size:12, weight:.medium))
                                        .foregroundColor(CryptogramTheme.Colors.text)
                                    Spacer()
                                }
                                .padding(.vertical, 10).padding(.horizontal, 16)
                                .background(RoundedRectangle(cornerRadius:8)
                                              .fill(CryptogramTheme.Colors.surface))
                            }
                            .buttonStyle(PlainButtonStyle())

                            if showTextSizeSelector {
                                HStack(spacing: 16) {
                                    ForEach(TextSizeOption.allCases) { opt in
                                        Button {
                                            settingsViewModel.textSize = opt
                                        } label: {
                                            VStack(spacing: 4) {
                                                Text("A")
                                                    .font(.system(size: opt.inputSize,
                                                                  weight: settingsViewModel.textSize == opt ? .bold : .regular,
                                                                  design: .monospaced))
                                                    .foregroundColor(CryptogramTheme.Colors.text.opacity(settingsViewModel.textSize == opt ? 1 : 0.4))
                                                Rectangle()
                                                    .frame(height: 1)
                                                    .foregroundColor(CryptogramTheme.Colors.border)
                                                Text(opt == .small ? "4" : opt == .medium ? "2" : "0")
                                                    .font(.system(size: opt.encodedSize,
                                                                  weight: settingsViewModel.textSize == opt ? .bold : .regular,
                                                                  design: .monospaced))
                                                    .foregroundColor(CryptogramTheme.Colors.text.opacity(settingsViewModel.textSize == opt ? 1 : 0.4))
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
                        }
                        
                        // Layout selection with visual previews
                        NavBarLayoutSelector(selection: $settingsViewModel.selectedNavBarLayout)
                        
                    }
                }
                .transition(.opacity)
            }
            
            Spacer() // Fill remaining space
            
            // Reset account section at the bottom, no header
            ResetAccountSection(viewModel: puzzleViewModel)
        }
        .animation(.easeInOut(duration: 0.3), value: showDifficultyInfo)
        .animation(.easeInOut(duration: 0.3), value: showLengthSelector)
    }
}

// PreferenceKey to help with centering if needed
struct HStackWidthPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// Replace #Preview with @Preview if using the standard SwiftUI preview provider, or comment/remove if ambiguous or unsupported.
// #Preview {
//     SettingsContentView()
//         .padding()
//         .background(Color(hex: "#f8f8f8"))
//         .environmentObject(PuzzleViewModel())
//         .environmentObject(ThemeManager())
//         .environmentObject(SettingsViewModel())
// }