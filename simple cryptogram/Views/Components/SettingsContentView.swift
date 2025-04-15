import SwiftUI

struct SettingsContentView: View {
    @AppStorage("encodingType") private var selectedEncodingType = "Letters"
    @AppStorage("isDarkMode") private var isDarkMode = false
    @EnvironmentObject private var puzzleViewModel: PuzzleViewModel
    @EnvironmentObject private var themeManager: ThemeManager
    @StateObject private var settingsViewModel = SettingsViewModel()
    
    // State properties for info panels
    @State private var showDifficultyInfo = false
    
    // Info text for difficulty
    private let difficultyInfoText = "normal mode gives you some starting letters.\nexpert mode does not."
    
    var body: some View {
        VStack(spacing: 20) {
            // Top spacing to position content as needed
            Spacer()
                .frame(height: 160)
            
            // Gameplay Section
            SettingsSection(title: "Gameplay") {
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
                        
                        // Encoding toggle (hidden when info is shown)
                        if !showDifficultyInfo {
                            ToggleOptionRow(
                                leftOption: ("Letters", "ABC"),
                                rightOption: ("Numbers", "123"),
                                selection: $selectedEncodingType
                            )
                            .transition(.opacity)
                        }
                    }
                }
            }
            
            // Appearance Section - only visible when no info panels are shown
            if !showDifficultyInfo {
                SettingsSection(title: "Appearance") {
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
                        .padding(.top, 15)
                        
                        // Layout selection with visual previews
                        NavBarLayoutSelector(selection: $settingsViewModel.selectedNavBarLayout)
                            .padding(.top, 10)
                    }
                }
                .transition(.opacity)
            }
            
            Spacer() // Fill remaining space
        }
        .animation(.easeInOut(duration: 0.3), value: showDifficultyInfo)
    }
}

#Preview {
    SettingsContentView()
        .padding()
        .background(Color(hex: "#f8f8f8"))
        .environmentObject(PuzzleViewModel())
        .environmentObject(ThemeManager())
        .environmentObject(SettingsViewModel())
} 