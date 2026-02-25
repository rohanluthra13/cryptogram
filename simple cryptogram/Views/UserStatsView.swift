import SwiftUI

struct UserStatsView: View {
    var viewModel: PuzzleViewModel
    @Environment(\.typography) private var typography
    
    var body: some View {
        VStack {
            // stats fixed at top
            
            SettingsSection(title: "stats") {
                VStack(spacing: 24) {
                    HStack {
                        Text("total completed:")
                            .font(typography.footnote)
                            .foregroundColor(CryptogramTheme.Colors.text)
                        Text("\(viewModel.totalCompletions)")
                            .font(typography.footnote)
                            .fontWeight(.bold)
                            .foregroundColor(CryptogramTheme.Colors.text)
                        Spacer()
                    }
                    .padding(.leading, 80)
                    HStack {
                        Text("total played:")
                            .font(typography.footnote)
                            .foregroundColor(CryptogramTheme.Colors.text)
                        Text("\(viewModel.totalAttempts)")
                            .font(typography.footnote)
                            .fontWeight(.bold)
                            .foregroundColor(CryptogramTheme.Colors.text)
                        Spacer()
                    }
                    .padding(.leading, 80)
                    HStack {
                        Text("win rate:")
                            .font(typography.footnote)
                            .foregroundColor(CryptogramTheme.Colors.text)
                        Text("\(viewModel.winRatePercentage)%")
                            .font(typography.footnote)
                            .fontWeight(.bold)
                            .foregroundColor(CryptogramTheme.Colors.text)
                        Spacer()
                    }
                    .padding(.leading, 80)
                    HStack {
                        Text("average time:")
                            .font(typography.footnote)
                            .foregroundColor(CryptogramTheme.Colors.text)
                        Text(viewModel.averageTime?.formattedAsMinutesSeconds ?? "--:--")
                            .font(typography.footnote)
                            .fontWeight(.bold)
                            .foregroundColor(CryptogramTheme.Colors.text)
                        Spacer()
                    }
                    .padding(.leading, 80)
                    HStack {
                        Text("current streak:")
                            .font(typography.footnote)
                            .foregroundColor(CryptogramTheme.Colors.text)
                        Text("\(viewModel.currentDailyStreak) days")
                            .font(typography.footnote)
                            .fontWeight(.bold)
                            .foregroundColor(CryptogramTheme.Colors.text)
                        Spacer()
                    }
                    .padding(.leading, 80)
                    HStack {
                        Text("best streak:")
                            .font(typography.footnote)
                            .foregroundColor(CryptogramTheme.Colors.text)
                        Text("\(viewModel.bestDailyStreak) days")
                            .font(typography.footnote)
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
    }
}

#Preview {
    UserStatsView(viewModel: PuzzleViewModel())
}
