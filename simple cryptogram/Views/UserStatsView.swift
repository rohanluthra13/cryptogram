import SwiftUI

struct UserStatsView: View {
    @ObservedObject var viewModel: PuzzleViewModel
    
    var body: some View {
        VStack {
            Spacer()
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
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
            }
            Spacer()
            Button(action: { viewModel.resetAllProgress() }) {
                Text("Reset All Stats")
                    .font(.footnote)
                    .foregroundColor(.red)
                    .padding(.top, 8)
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.bottom, 24)
        }
        .frame(maxHeight: .infinity)
        .padding()
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
