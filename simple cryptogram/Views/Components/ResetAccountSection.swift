import SwiftUI

struct ResetAccountSection: View {
    @ObservedObject var viewModel: PuzzleViewModel
    @State private var showResetConfirmation = false
    @State private var displayedConfirmationText = ""
    private let confirmationFullText = "are you sure? this will delete all your user history."

    var body: some View {
        VStack {
            Spacer(minLength: 0)
            Group {
                if !showResetConfirmation {
                    Button(action: { showResetConfirmation = true }) {
                        Text("reset account")
                            .settingsToggleStyle(isSelected: false)
                    }
                    .buttonStyle(PlainButtonStyle())
                } else {
                    VStack(spacing: 12) {
                        Text(displayedConfirmationText)
                            .font(.footnote)
                            .fontWeight(.thin)
                            .foregroundColor(CryptogramTheme.Colors.text)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: 200)
                            .onAppear {
                                displayedConfirmationText = ""
                                for (i, c) in confirmationFullText.enumerated() {
                                    DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.05) {
                                        if showResetConfirmation {
                                            displayedConfirmationText.append(c)
                                        }
                                    }
                                }
                            }
                        HStack(spacing: 32) {
                            Button("no") { showResetConfirmation = false }
                                .font(.footnote)
                                .fontWeight(.thin)
                                .foregroundColor(CryptogramTheme.Colors.text)
                                .buttonStyle(PlainButtonStyle())
                            Button("yes") {
                                viewModel.resetAllProgress()
                                showResetConfirmation = false
                            }
                            .font(.footnote)
                            .fontWeight(.thin)
                            .foregroundColor(CryptogramTheme.Colors.text)
                            .buttonStyle(PlainButtonStyle())
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
            }
            .padding(.bottom, 24)
        }
    }
}
