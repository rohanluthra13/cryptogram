import SwiftUI

struct SettingsContentView: View {
    @AppStorage("encodingType") private var selectedEncodingType = "Letters"
    @AppStorage("isDarkMode") private var isDarkMode = false
    @EnvironmentObject private var puzzleViewModel: PuzzleViewModel
    @EnvironmentObject private var themeManager: ThemeManager
    @StateObject private var settingsViewModel = SettingsViewModel()
    
    let encodingTypes = ["Letters", "Numbers"]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Gameplay Section
            Text("Gameplay")
                .font(.subheadline)
                .foregroundColor(CryptogramTheme.Colors.text)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.bottom, 5)
            
            // Difficulty Toggle
            VStack(spacing: 8) {
                HStack {
                    Spacer()

                    // Left side - Normal mode option
                    Button(action: {
                        if settingsViewModel.selectedMode != .normal {
                            settingsViewModel.selectedMode = .normal
                            // Potentially refresh puzzle or apply settings if needed immediately
                            // puzzleViewModel.refreshPuzzleWithCurrentSettings()
                        }
                    }) {
                        Text(DifficultyMode.normal.displayName.lowercased())
                            .font(.footnote)
                            .fontWeight(settingsViewModel.selectedMode == .normal ? .bold : .regular)
                            .foregroundColor(settingsViewModel.selectedMode == .normal ?
                                            CryptogramTheme.Colors.text :
                                            CryptogramTheme.Colors.text.opacity(0.4))
                    }
                    .buttonStyle(PlainButtonStyle())
                    .accessibilityLabel("Switch to Normal difficulty")
                    .padding(.trailing, 6)

                    // Center - Toggle switch with arrows
                    Button(action: {
                        settingsViewModel.selectedMode = settingsViewModel.selectedMode == .normal ? .expert : .normal
                        // Potentially refresh puzzle or apply settings if needed immediately
                        // puzzleViewModel.refreshPuzzleWithCurrentSettings()
                    }) {
                        Image(systemName: settingsViewModel.selectedMode == .normal ? "arrow.right" : "arrow.left")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(CryptogramTheme.Colors.text)
                    }
                    .accessibilityLabel("Toggle difficulty mode")
                    .padding(.horizontal, 6)

                    // Right side - Expert mode option
                    Button(action: {
                        if settingsViewModel.selectedMode != .expert {
                            settingsViewModel.selectedMode = .expert
                            // Potentially refresh puzzle or apply settings if needed immediately
                            // puzzleViewModel.refreshPuzzleWithCurrentSettings()
                        }
                    }) {
                        Text(DifficultyMode.expert.displayName.lowercased())
                            .font(.footnote)
                            .fontWeight(settingsViewModel.selectedMode == .expert ? .bold : .regular)
                            .foregroundColor(settingsViewModel.selectedMode == .expert ?
                                            CryptogramTheme.Colors.text :
                                            CryptogramTheme.Colors.text.opacity(0.4))
                    }
                    .buttonStyle(PlainButtonStyle())
                    .accessibilityLabel("Switch to Expert difficulty")
                    .padding(.leading, 6)

                    Spacer()
                }
            }
            .padding(.top, 10) // Add spacing if needed

            // Encoding Type toggle
            VStack(spacing: 8) {
                HStack {
                    Spacer()
                    
                    // Left side - Letters option
                    Button(action: {
                        if selectedEncodingType != "Letters" {
                            selectedEncodingType = "Letters"
                            puzzleViewModel.refreshPuzzleWithCurrentSettings()
                        }
                    }) {
                        Text("ABC")
                            .font(.footnote)
                            .fontWeight(selectedEncodingType == "Letters" ? .bold : .regular)
                            .foregroundColor(selectedEncodingType == "Letters" ? 
                                            CryptogramTheme.Colors.text : 
                                            CryptogramTheme.Colors.text.opacity(0.4))
                    }
                    .buttonStyle(PlainButtonStyle())
                    .accessibilityLabel("Switch to Letters encoding")
                    .padding(.trailing, 6)
                    
                    // Center - Toggle switch with arrows
                    Button(action: {
                        selectedEncodingType = selectedEncodingType == "Letters" ? "Numbers" : "Letters"
                        puzzleViewModel.refreshPuzzleWithCurrentSettings()
                    }) {
                        Image(systemName: selectedEncodingType == "Letters" ? "arrow.right" : "arrow.left")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(CryptogramTheme.Colors.text)
                    }
                    .accessibilityLabel("Toggle encoding type")
                    .padding(.horizontal, 6)
                    
                    // Right side - Numbers option
                    Button(action: {
                        if selectedEncodingType != "Numbers" {
                            selectedEncodingType = "Numbers"
                            puzzleViewModel.refreshPuzzleWithCurrentSettings()
                        }
                    }) {
                        Text("123")
                            .font(.footnote)
                            .fontWeight(selectedEncodingType == "Numbers" ? .bold : .regular)
                            .foregroundColor(selectedEncodingType == "Numbers" ? 
                                            CryptogramTheme.Colors.text : 
                                            CryptogramTheme.Colors.text.opacity(0.4))
                    }
                    .buttonStyle(PlainButtonStyle())
                    .accessibilityLabel("Switch to Numbers encoding")
                    .padding(.leading, 6)
                    
                    Spacer()
                }
            }
            
            // Add a divider before the Appearance section
            Divider()
                .padding(.top, 5)
            
            // Appearance Section
            Text("Appearance")
                .font(.subheadline)
                .foregroundColor(CryptogramTheme.Colors.text)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.bottom, 5)
                .padding(.top, 10)
            
            // Dark Mode toggle
            VStack(spacing: 8) {
                HStack {
                    Spacer()
                    
                    // Left side - Light mode option
                    Button(action: {
                        if isDarkMode {
                            isDarkMode = false
                            themeManager.applyTheme()
                        }
                    }) {
                        Image(systemName: "sun.max")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(!isDarkMode ? 
                                           CryptogramTheme.Colors.text : 
                                           CryptogramTheme.Colors.text.opacity(0.4))
                    }
                    .buttonStyle(PlainButtonStyle())
                    .accessibilityLabel("Switch to Light mode")
                    .padding(.trailing, 6)
                    
                    // Center - Toggle switch
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
                    
                    // Right side - Dark mode option
                    Button(action: {
                        if !isDarkMode {
                            isDarkMode = true
                            themeManager.applyTheme()
                        }
                    }) {
                        Image(systemName: "moon.stars")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(isDarkMode ? 
                                           CryptogramTheme.Colors.text : 
                                           CryptogramTheme.Colors.text.opacity(0.4))
                    }
                    .buttonStyle(PlainButtonStyle())
                    .accessibilityLabel("Switch to Dark mode")
                    .padding(.leading, 6)
                    
                    Spacer()
                }
            }
        }
    }
}

#Preview {
    SettingsContentView()
        .padding()
        .background(Color(hex: "#f8f8f8"))
        .previewLayout(.sizeThatFits)
        .environmentObject(PuzzleViewModel())
        .environmentObject(ThemeManager())
        .environmentObject(SettingsViewModel())
} 