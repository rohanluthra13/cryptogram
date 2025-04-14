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
                        Image(systemName: "arrow.left.arrow.right")
                            .font(.system(size: 15, weight: .medium))
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
                
                // Thin line under the toggle
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(Color.gray.opacity(0.3))
            }
            
            // Difficulty Picker
            VStack(spacing: 8) {
                Picker("Difficulty", selection: $settingsViewModel.selectedMode) {
                    ForEach(DifficultyMode.allCases) { mode in
                        Text(mode.displayName).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .accessibilityLabel("Select difficulty mode")
                
                // Thin line under the picker
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(Color.gray.opacity(0.3))
            }
            .padding(.top, 10) // Add some spacing above the difficulty picker
            
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
                        Image(systemName: "arrow.left.arrow.right")
                            .font(.system(size: 15, weight: .medium))
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
                
                // Thin line under the toggle
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(Color.gray.opacity(0.3))
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