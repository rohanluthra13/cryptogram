import SwiftUI

struct CompletionStatsView: View {
    @ObservedObject var viewModel: PuzzleViewModel
    
    var body: some View {
        VStack(spacing: 16) {
            // Time
            if let completionTime = viewModel.completionTime {
                HStack {
                    Image(systemName: "clock")
                        .foregroundColor(CryptogramTheme.Colors.primary)
                    Text("Time: \(formatTime(completionTime))")
                        .foregroundColor(CryptogramTheme.Colors.text)
                }
            }
            
            // Mistakes
            if viewModel.mistakeCount > 0 {
                HStack {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundColor(CryptogramTheme.Colors.error)
                    Text("Mistakes: \(viewModel.mistakeCount)")
                        .foregroundColor(CryptogramTheme.Colors.text)
                }
            }
            
            // Hints
            if viewModel.hintCount > 0 {
                HStack {
                    Image(systemName: "lightbulb.fill")
                        .foregroundColor(CryptogramTheme.Colors.hint)
                    Text("Hints used: \(viewModel.hintCount)")
                        .foregroundColor(CryptogramTheme.Colors.text)
                }
            }
        }
        .font(CryptogramTheme.Typography.body)
        .padding()
        .background(CryptogramTheme.Colors.surface.opacity(0.1))
        .cornerRadius(CryptogramTheme.Layout.buttonCornerRadius)
    }
    
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
} 