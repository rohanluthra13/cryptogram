import SwiftUI

struct InfoPanel: View {
    let infoText: String
    @Binding var isVisible: Bool
    
    // Typewriter animation properties
    @State private var displayedInfoText = ""
    @State private var typingTimer: Timer?
    @State private var currentCharacterIndex = 0
    @State private var isTypingComplete = false
    let typingSpeed: Double = 0.04
    
    var body: some View {
        VStack {
            if isVisible {
                Text(attributedInfoText)
                    .font(.footnote)
                    .foregroundColor(CryptogramTheme.Colors.text)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    .onAppear {
                        startTypewriterAnimation()
                    }
                    .onDisappear {
                        resetTypewriterAnimation()
                    }
                    .onTapGesture {
                        skipTypingAnimation()
                    }
            }
        }
        .frame(maxWidth: .infinity)
        .animation(.easeInOut(duration: 0.3), value: isVisible)
    }
    
    // Format the displayed text with bold words
    private var attributedInfoText: AttributedString {
        guard !displayedInfoText.isEmpty else { return AttributedString("") }
        
        var attributed = AttributedString(displayedInfoText)
        
        // Find and bold specific words - using a reusable function to handle multiple words
        boldWordInText(&attributed, word: "normal")
        boldWordInText(&attributed, word: "expert")
        
        return attributed
    }
    
    // Helper function to bold specific words in text
    private func boldWordInText(_ attributed: inout AttributedString, word: String) {
        if let range = displayedInfoText.range(of: word) {
            let nsRange = NSRange(range, in: displayedInfoText)
            if let attributedRange = Range<AttributedString.Index>(nsRange, in: attributed) {
                attributed[attributedRange].font = .boldSystemFont(ofSize: UIFont.systemFontSize)
            }
        }
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
    
    private func resetTypewriterAnimation() {
        typingTimer?.invalidate()
        typingTimer = nil
        displayedInfoText = ""
        currentCharacterIndex = 0
        isTypingComplete = false
    }
    
    // Skip typing animation and show full text immediately
    private func skipTypingAnimation() {
        typingTimer?.invalidate()
        typingTimer = nil
        displayedInfoText = infoText
        currentCharacterIndex = infoText.count
        isTypingComplete = true
    }
}

struct InfoPanelPreview: View {
    @State private var showInfo = true
    
    var body: some View {
        VStack(spacing: 20) {
            Toggle("Show Info", isOn: $showInfo)
                .padding()
            
            InfoPanel(
                infoText: "normal mode gives you some starting letters.\nexpert mode does not.",
                isVisible: $showInfo
            )
        }
    }
}

#Preview {
    InfoPanelPreview()
        .padding()
        .background(CryptogramTheme.Colors.background)
} 