import SwiftUI

struct UserStatsView: View {
    @ObservedObject var viewModel: PuzzleViewModel
    @State private var showResetConfirmation = false
    @State private var displayedConfirmationText = ""
    private let confirmationFullText = "are you sure? this will delete all your user history."
    
    var body: some View {
        VStack {
            // stats fixed at top
            
            SettingsSection(title: "stats") {
                VStack(spacing: 24) {
                    HStack {
                        Text("total completed:")
                            .font(.footnote)
                            .foregroundColor(CryptogramTheme.Colors.text)
                        Text("\(viewModel.totalCompletions)")
                            .font(.footnote)
                            .fontWeight(.bold)
                            .foregroundColor(CryptogramTheme.Colors.text)
                        Spacer()
                    }
                    .padding(.leading, 80)
                    HStack {
                        Text("total played:")
                            .font(.footnote)
                            .foregroundColor(CryptogramTheme.Colors.text)
                        Text("\(viewModel.totalAttempts)")
                            .font(.footnote)
                            .fontWeight(.bold)
                            .foregroundColor(CryptogramTheme.Colors.text)
                        Spacer()
                    }
                    .padding(.leading, 80)
                    HStack {
                        Text("win rate:")
                            .font(.footnote)
                            .foregroundColor(CryptogramTheme.Colors.text)
                        Text("\(viewModel.winRatePercentage)%")
                            .font(.footnote)
                            .fontWeight(.bold)
                            .foregroundColor(CryptogramTheme.Colors.text)
                        Spacer()
                    }
                    .padding(.leading, 80)
                    HStack {
                        Text("average time:")
                            .font(.footnote)
                            .foregroundColor(CryptogramTheme.Colors.text)
                        Text(viewModel.averageTime.map { formatTime($0) } ?? "--:--")
                            .font(.footnote)
                            .fontWeight(.bold)
                            .foregroundColor(CryptogramTheme.Colors.text)
                        Spacer()
                    }
                    .padding(.leading, 80)
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
            }
        }
        .padding(.top, 100)
        .frame(maxHeight: .infinity, alignment: .top)
        .padding()
        .overlay(
            Group {
                if !showResetConfirmation {
                    Button(action: { showResetConfirmation = true }) {
                        Text("reset account")
                            .font(.footnote)
                            .fontWeight(.thin)
                            .foregroundColor(CryptogramTheme.Colors.text)
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
            .padding(.bottom, 24),
            alignment: .bottom
        )
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

#Preview {
    UserStatsView(viewModel: PuzzleViewModel())
}
