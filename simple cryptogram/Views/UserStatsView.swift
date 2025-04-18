import SwiftUI

struct UserStatsView: View {
    @ObservedObject var viewModel: PuzzleViewModel
    
    var body: some View {
        VStack(spacing: 24) {
            Text("Your Cryptogram Stats")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.top, 8)
            
            VStack(spacing: 12) {
                Text("All-Time Attempts")
                    .font(.headline)
                    .padding(.bottom, 4)
                
                HStack(spacing: 32) {
                    VStack {
                        Text("\(viewModel.totalCompletions)")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.green)
                        Text("Completed")
                            .font(.subheadline)
                    }
                    VStack {
                        Text("\(viewModel.totalFailures)")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.red)
                        Text("Failed")
                            .font(.subheadline)
                    }
                    VStack {
                        Text("\(viewModel.totalAttempts)")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.blue)
                        Text("Total")
                            .font(.subheadline)
                    }
                }
                
                if let bestTime = viewModel.globalBestTime {
                    Text("Best time: \(formatTime(bestTime))")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
            }
            Spacer()
            Button(role: .destructive) {
                viewModel.resetAllProgress()
            } label: {
                Label("Reset All Stats", systemImage: "arrow.counterclockwise")
                    .font(.headline)
                    .padding()
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)
            .padding(.bottom, 24)
        }
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
