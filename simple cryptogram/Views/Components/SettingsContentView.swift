import SwiftUI

struct SettingsContentView: View {
    @AppStorage("encodingType") private var selectedEncodingType = "Letters"
    @AppStorage("isDarkMode") private var isDarkMode = false
    @EnvironmentObject private var puzzleViewModel: PuzzleViewModel
    @EnvironmentObject private var themeManager: ThemeManager
    @StateObject private var settingsViewModel = SettingsViewModel()
    @State private var showDifficultyInfo = false
    
    // Typewriter animation properties for info text
    @State private var displayedInfoText = ""
    @State private var typingTimer: Timer?
    @State private var currentCharacterIndex = 0
    @State private var isTypingComplete = false
    let typingSpeed: Double = 0.04
    let infoText = "normal mode gives you some starting letters.\nexpert mode does not."
    
    let encodingTypes = ["Letters", "Numbers"]
    
    var body: some View {
        VStack(spacing: 0) {
            // Add spacing at top to push content down
            Spacer()
                .frame(height: 260)
            
            // Fixed header section
            VStack(spacing: 5) {
                // Gameplay heading
                Text("Gameplay")
                    .font(.subheadline)
                    .foregroundColor(CryptogramTheme.Colors.text)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.bottom, 5)
                
                // Difficulty toggle with info button
                ZStack {
                    HStack {
                        Spacer()
                        
                        // Normal mode button
                        Button(action: {
                            if settingsViewModel.selectedMode != .normal {
                                settingsViewModel.selectedMode = .normal
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
                        
                        // Toggle arrow
                        Button(action: {
                            settingsViewModel.selectedMode = settingsViewModel.selectedMode == .normal ? .expert : .normal
                        }) {
                            Image(systemName: settingsViewModel.selectedMode == .normal ? "arrow.right" : "arrow.left")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(CryptogramTheme.Colors.text)
                        }
                        .accessibilityLabel("Toggle difficulty mode")
                        .padding(.horizontal, 6)
                        
                        // Expert mode button
                        Button(action: {
                            if settingsViewModel.selectedMode != .expert {
                                settingsViewModel.selectedMode = .expert
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
                    
                    // Info button
                    HStack {
                        Spacer()
                        Button(action: {
                            withAnimation {
                                if showDifficultyInfo {
                                    // Reset typing animation when hiding info
                                    displayedInfoText = ""
                                    isTypingComplete = false
                                    showDifficultyInfo = false
                                } else {
                                    showDifficultyInfo = true
                                    // Start typing animation when showing info
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                        startTypewriterAnimation()
                                    }
                                }
                            }
                        }) {
                            Text("i")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(CryptogramTheme.Colors.text)
                        }
                        .accessibilityLabel("Difficulty Info")
                        .padding(.trailing, 5)
                    }
                }
                .padding(.vertical, 5)
            }
            .padding(.bottom, 20)
                            
            // Content with fixed top spacing
            ZStack(alignment: .top) {
                // Default content
                if !showDifficultyInfo {
                    VStack(spacing: 15) {
                        // Encoding toggle
                        VStack(spacing: 8) {
                            HStack {
                                Spacer()
                                
                                // Letters option
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
                                
                                // Toggle
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
                                
                                // Numbers option
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
                        
                        // Appearance section
                        Text("Appearance")
                            .font(.subheadline)
                            .foregroundColor(CryptogramTheme.Colors.text)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.bottom, 5)
                            .padding(.top, 10)
                        
                        // Dark mode toggle
                        VStack(spacing: 8) {
                            HStack {
                                Spacer()
                                
                                // Light mode
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
                                
                                // Toggle
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
                        
                        // Layout selection buttons
                        VStack(spacing: 8) {
                            HStack {
                                Spacer()
                                
                                // Left layout button
                                Button(action: {
                                    settingsViewModel.selectedNavBarLayout = .leftLayout
                                }) {
                                    Text("Left")
                                        .font(.footnote)
                                        .fontWeight(settingsViewModel.selectedNavBarLayout == .leftLayout ? .bold : .regular)
                                        .foregroundColor(settingsViewModel.selectedNavBarLayout == .leftLayout ?
                                                       CryptogramTheme.Colors.text :
                                                       CryptogramTheme.Colors.text.opacity(0.4))
                                }
                                .buttonStyle(PlainButtonStyle())
                                .accessibilityLabel("Left navigation bar layout")
                                .padding(.trailing, 6)
                                
                                // Center layout button
                                Button(action: {
                                    settingsViewModel.selectedNavBarLayout = .centerLayout
                                }) {
                                    Text("Center")
                                        .font(.footnote)
                                        .fontWeight(settingsViewModel.selectedNavBarLayout == .centerLayout ? .bold : .regular)
                                        .foregroundColor(settingsViewModel.selectedNavBarLayout == .centerLayout ?
                                                       CryptogramTheme.Colors.text :
                                                       CryptogramTheme.Colors.text.opacity(0.4))
                                }
                                .buttonStyle(PlainButtonStyle())
                                .accessibilityLabel("Center navigation bar layout")
                                .padding(.horizontal, 6)
                                
                                // Right layout button
                                Button(action: {
                                    settingsViewModel.selectedNavBarLayout = .rightLayout
                                }) {
                                    Text("Right")
                                        .font(.footnote)
                                        .fontWeight(settingsViewModel.selectedNavBarLayout == .rightLayout ? .bold : .regular)
                                        .foregroundColor(settingsViewModel.selectedNavBarLayout == .rightLayout ?
                                                       CryptogramTheme.Colors.text :
                                                       CryptogramTheme.Colors.text.opacity(0.4))
                                }
                                .buttonStyle(PlainButtonStyle())
                                .accessibilityLabel("Right navigation bar layout")
                                .padding(.leading, 6)
                                
                                Spacer()
                            }
                        }
                    }
                }
                
                // Info content (overlaid when visible)
                if showDifficultyInfo {
                    // Custom text with bold words using attributed string
                    Text(attributedInfoText)
                        .font(.footnote)
                        .foregroundColor(CryptogramTheme.Colors.text)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 5)
                        .padding(.horizontal, 20)
                }
            }
            
            Spacer() // Fill remaining space
        }
    }
    
    // Format the displayed text with bold words
    private var attributedInfoText: AttributedString {
        guard !displayedInfoText.isEmpty else { return AttributedString("") }
        
        var attributed = AttributedString(displayedInfoText)
        
        // Find and bold "normal" and "expert" words
        if let normalRange = displayedInfoText.range(of: "normal") {
            let nsNormalRange = NSRange(normalRange, in: displayedInfoText)
            let attributedRange = Range<AttributedString.Index>(nsNormalRange, in: attributed)!
            attributed[attributedRange].font = .boldSystemFont(ofSize: UIFont.systemFontSize)
        }
        
        if let expertRange = displayedInfoText.range(of: "expert") {
            let nsExpertRange = NSRange(expertRange, in: displayedInfoText)
            let attributedRange = Range<AttributedString.Index>(nsExpertRange, in: attributed)!
            attributed[attributedRange].font = .boldSystemFont(ofSize: UIFont.systemFontSize)
        }
        
        return attributed
    }
    
    // Start typing animation
    private func startTypewriterAnimation() {
        displayedInfoText = ""
        currentCharacterIndex = 0
        isTypingComplete = false
        
        // Cancel any existing timer
        typingTimer?.invalidate()
        
        // Create a timer that adds one character at a time
        typingTimer = Timer.scheduledTimer(withTimeInterval: typingSpeed, repeats: true) { timer in
            if currentCharacterIndex < infoText.count {
                let index = infoText.index(infoText.startIndex, offsetBy: currentCharacterIndex)
                displayedInfoText += String(infoText[index])
                currentCharacterIndex += 1
            } else {
                timer.invalidate()
                typingTimer = nil
                isTypingComplete = true
            }
        }
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