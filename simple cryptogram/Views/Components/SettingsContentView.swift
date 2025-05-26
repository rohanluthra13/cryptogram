import SwiftUI

struct SettingsContentView: View {
    @EnvironmentObject private var puzzleViewModel: PuzzleViewModel
    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject private var settingsViewModel: SettingsViewModel
    @EnvironmentObject private var appSettings: AppSettings
    @Environment(\.typography) private var typography
    
    // State properties for info panels
    @State private var showLengthSelector = false
    @State private var showTextSizeSelector = false
    @State private var showFontSelector = false
    
    // Computed bindings for AppSettings
    private var selectedEncodingType: Binding<String> {
        Binding(
            get: { appSettings.encodingType },
            set: { appSettings.encodingType = $0 }
        )
    }
    
    private var isDarkMode: Binding<Bool> {
        Binding(
            get: { appSettings.isDarkMode },
            set: { appSettings.isDarkMode = $0 }
        )
    }
    
    // Info text for length
    private let lengthInfoText = "short: quotes under 50 characters\nmedium: quotes 50-99 characters\nlong: quotes 100+ characters"
    
    var body: some View {
        VStack(spacing: 20) {
            // Top spacing to position content as needed
            Spacer()
                .frame(height: 60)
            
            // Gameplay Section
            SettingsSection(title: "gameplay") {
                VStack(spacing: 15) {
                    // Encoding toggle and length dropdown
                    VStack(spacing: 15) {
                                // Encoding toggle
                                ToggleOptionRow(
                                    leftOption: ("Letters", "abc"),
                                    rightOption: ("Numbers", "123"),
                                    selection: selectedEncodingType
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
                                        
                                        Text("quote length: ")
                                            .font(typography.footnote)
                                            .foregroundColor(CryptogramTheme.Colors.text) +
                                        Text(settingsViewModel.quoteLengthDisplayText)
                                            .font(typography.footnote)
                                            .fontWeight(.bold)
                                            .foregroundColor(CryptogramTheme.Colors.text)
                                        
                                        Image(systemName: showLengthSelector ? "chevron.up" : "chevron.down")
                                            .font(.system(size: 12, weight: .medium, design: typography.fontOption.design))
                                            .foregroundColor(CryptogramTheme.Colors.text)
                                            .padding(.leading, 4)
                                        
                                        Spacer()
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)
                                    .background(Color.clear) // Ensure no background
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                // Show checkboxes when expanded
                                if showLengthSelector {
                                    HStack(spacing: 4) {
                                        MultiCheckboxRow(
                                            title: "short",
                                            isSelected: settingsViewModel.isLengthSelected("easy"),
                                            action: { settingsViewModel.toggleLength("easy") }
                                        )
                                        MultiCheckboxRow(
                                            title: "medium",
                                            isSelected: settingsViewModel.isLengthSelected("medium"),
                                            action: { settingsViewModel.toggleLength("medium") }
                                        )
                                        MultiCheckboxRow(
                                            title: "long",
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
            
            // Appearance Section - only visible when length selector is not shown
            if !showLengthSelector {
                SettingsSection(title: "theme & layout") {
                    VStack(spacing: 15) {
                        // Dark mode toggle with icons
                        HStack {
                            Spacer()
                            
                            // Light mode
                            IconToggleButton(
                                iconName: "sun.max",
                                isSelected: !isDarkMode.wrappedValue,
                                action: {
                                    if isDarkMode.wrappedValue {
                                        isDarkMode.wrappedValue = false
                                        themeManager.applyTheme()
                                    }
                                },
                                accessibilityLabel: "Switch to Light mode"
                            )
                            .padding(.trailing, 6)
                            
                            // Toggle arrow
                            Button(action: {
                                isDarkMode.wrappedValue.toggle()
                                themeManager.applyTheme()
                            }) {
                                Image(systemName: !isDarkMode.wrappedValue ? "arrow.right" : "arrow.left")
                                    .font(.system(size: 13, weight: .medium, design: typography.fontOption.design))
                                    .foregroundColor(CryptogramTheme.Colors.text)
                            }
                            .accessibilityLabel("Toggle dark mode")
                            .padding(.horizontal, 6)
                            
                            // Dark mode
                            IconToggleButton(
                                iconName: "moon.stars",
                                isSelected: isDarkMode.wrappedValue,
                                action: {
                                    if !isDarkMode.wrappedValue {
                                        isDarkMode.wrappedValue = true
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
                                    Text("text size: ")
                                        .font(typography.footnote)
                                        .foregroundColor(CryptogramTheme.Colors.text)
                                    Text(settingsViewModel.textSize.displayName.lowercased())
                                        .font(typography.footnote)
                                        .fontWeight(.bold)
                                        .foregroundColor(CryptogramTheme.Colors.text)
                                    Image(systemName: showTextSizeSelector ? "chevron.up" : "chevron.down")
                                        .font(.system(size: 12, weight: .medium, design: typography.fontOption.design))
                                        .foregroundColor(CryptogramTheme.Colors.text)
                                        .padding(.leading, 4)
                                    Spacer()
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(Color.clear) // Ensure no background
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
                                                                  design: typography.fontOption.design))
                                                    .foregroundColor(CryptogramTheme.Colors.text.opacity(settingsViewModel.textSize == opt ? 1 : 0.4))
                                                Rectangle()
                                                    .frame(height: 1)
                                                    .foregroundColor(CryptogramTheme.Colors.border)
                                                Text(opt == .small ? "4" : opt == .medium ? "2" : "0")
                                                    .font(.system(size: opt.encodedSize,
                                                                  weight: settingsViewModel.textSize == opt ? .bold : .regular,
                                                                  design: typography.fontOption.design))
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
                        
                        // Font selection
                        VStack(spacing: 8) {
                            Button {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    showFontSelector.toggle()
                                }
                            } label: {
                                HStack {
                                    Spacer()
                                    Text("font: ")
                                        .font(typography.footnote)
                                        .foregroundColor(CryptogramTheme.Colors.text) +
                                    Text(appSettings.fontFamily.rawValue.lowercased())
                                        .font(typography.footnote)
                                        .fontWeight(.bold)
                                        .foregroundColor(CryptogramTheme.Colors.text)
                                    
                                    Image(systemName: showFontSelector ? "chevron.up" : "chevron.down")
                                        .font(.system(size: 12, weight: .medium, design: typography.fontOption.design))
                                        .foregroundColor(CryptogramTheme.Colors.text)
                                        .padding(.leading, 4)
                                    
                                    Spacer()
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(Color.clear)
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            if showFontSelector {
                                HStack(spacing: 16) {
                                    ForEach(FontOption.allCases, id: \.self) { font in
                                        Button {
                                            appSettings.fontFamily = font
                                        } label: {
                                            Text(font.rawValue.lowercased())
                                                .font(typography.footnote)
                                                .fontWeight(appSettings.fontFamily == font ? .bold : .regular)
                                                .foregroundColor(CryptogramTheme.Colors.text.opacity(appSettings.fontFamily == font ? 1 : 0.6))
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
        .animation(.easeInOut(duration: 0.3), value: showLengthSelector)
        .animation(.easeInOut(duration: 0.3), value: showTextSizeSelector)
        .animation(.easeInOut(duration: 0.3), value: showFontSelector)
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