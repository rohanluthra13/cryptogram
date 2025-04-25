import SwiftUI

struct DisclaimersSection: View {
    @State private var showDisclaimers = false
    private let disclaimer1 = "quotes are sourced from ZenQuotes.io"
    private let disclaimer2 = "author summaries are AI generated and may not be fully accurate"
    @State private var displayedDisclaimer1 = ""
    @State private var displayedDisclaimer2 = ""
    @State private var typingTimer: Timer?
    @State private var currentDisclaimerIndex = 0
    @State private var currentCharIndex = 0
    private let typingSpeed: Double = 0.045

    var body: some View {
        VStack {
            Spacer(minLength: 0)
            Group {
                if !showDisclaimers {
                    Button(action: { showDisclaimers = true }) {
                        Text("disclaimers")
                            .settingsToggleStyle(isSelected: false)
                    }
                    .buttonStyle(PlainButtonStyle())
                } else {
                    VStack(spacing: 16) {
                        HStack(alignment: .top, spacing: 8) {
                            Text("•")
                                .font(.footnote)
                                .fontWeight(.regular)
                                .foregroundColor(CryptogramTheme.Colors.text.opacity(0.4))
                                .padding(.top, 1.5)
                            Text(displayedDisclaimer1)
                                .font(.footnote)
                                .fontWeight(.regular)
                                .foregroundColor(CryptogramTheme.Colors.text.opacity(0.4))
                                .multilineTextAlignment(.leading)
                                .frame(maxWidth: 240, alignment: .leading)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        if currentDisclaimerIndex > 0 || displayedDisclaimer1.count == disclaimer1.count {
                            HStack(alignment: .top, spacing: 8) {
                                Text("•")
                                    .font(.footnote)
                                    .fontWeight(.regular)
                                    .foregroundColor(CryptogramTheme.Colors.text.opacity(0.4))
                                    .padding(.top, 1.5)
                                Text(displayedDisclaimer2)
                                    .font(.footnote)
                                    .fontWeight(.regular)
                                    .foregroundColor(CryptogramTheme.Colors.text.opacity(0.4))
                                    .multilineTextAlignment(.leading)
                                    .frame(maxWidth: 240, alignment: .leading)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        showDisclaimers = false
                        typingTimer?.invalidate()
                    }
                    .onAppear {
                        startTypewriterAnimation()
                    }
                    .onDisappear {
                        typingTimer?.invalidate()
                        displayedDisclaimer1 = ""
                        displayedDisclaimer2 = ""
                        currentDisclaimerIndex = 0
                        currentCharIndex = 0
                    }
                }
            }
            .padding(.vertical, 16)
        }
        .frame(maxWidth: .infinity)
    }
}

// --- Typewriter animation logic ---
extension DisclaimersSection {
    private func startTypewriterAnimation() {
        displayedDisclaimer1 = ""
        displayedDisclaimer2 = ""
        currentDisclaimerIndex = 0
        currentCharIndex = 0
        typingTimer?.invalidate()
        typeNextCharacter()
    }

    private func typeNextCharacter() {
        let disclaimers = [disclaimer1, disclaimer2]
        if currentDisclaimerIndex >= disclaimers.count {
            typingTimer?.invalidate()
            return
        }
        let currentDisclaimer = disclaimers[currentDisclaimerIndex]
        if currentCharIndex < currentDisclaimer.count {
            let index = currentDisclaimer.index(currentDisclaimer.startIndex, offsetBy: currentCharIndex)
            if currentDisclaimerIndex == 0 {
                displayedDisclaimer1 += String(currentDisclaimer[index])
            } else {
                displayedDisclaimer2 += String(currentDisclaimer[index])
            }
            currentCharIndex += 1
            typingTimer = Timer.scheduledTimer(withTimeInterval: typingSpeed, repeats: false) { _ in
                typeNextCharacter()
            }
        } else {
            currentDisclaimerIndex += 1
            currentCharIndex = 0
            typingTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { _ in
                typeNextCharacter()
            }
        }
    }
}

#Preview {
    DisclaimersSection()
        .background(Color(.systemBackground))
}
