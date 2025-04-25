import SwiftUI

struct CompletionStatsView: View {
    @EnvironmentObject private var viewModel: PuzzleViewModel
    let maxMistakes: Int = 3
    
    // Green color for checkmark icons, matching hint icon color
    private let checkmarkColor = Color(hex: "#01780F").opacity(0.5)
    
    var body: some View {
        HStack {
            Spacer()
            
            VStack(alignment: .leading, spacing: 10) {
                // Time
                if let completionTime = viewModel.completionTime {
                    HStack(spacing: 8) {
                        Text("time:")
                            .foregroundColor(CryptogramTheme.Colors.text)
                            .font(.footnote)
                        Text(formatTime(completionTime))
                            .foregroundColor(CryptogramTheme.Colors.text)
                    }
                }
                
                // Mistakes - show green tick if no mistakes, otherwise show 3 cross icons
                HStack(spacing: 8) {
                    Text("mistakes:")
                        .foregroundColor(CryptogramTheme.Colors.text)
                        .font(.footnote)
                    
                    if viewModel.mistakeCount == 0 {
                        // Show "none!" text with green tick
                        HStack(spacing: 4) {
                            Text("none!")
                                .foregroundColor(CryptogramTheme.Colors.text)
                            
                            Image(systemName: "checkmark")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(checkmarkColor)
                        }
                    } else {
                        // Show crosses for mistakes
                        HStack(spacing: 8) {
                            ForEach(0..<maxMistakes, id: \.self) { index in
                                Text("X")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(index < viewModel.mistakeCount 
                                                  ? Color.red.opacity(0.9) 
                                                  : CryptogramTheme.Colors.secondary.opacity(0.3))
                            }
                        }
                    }
                }
                
                // Hints - always show, but display differently based on count
                HStack(spacing: 8) {
                    Text("hints used:")
                        .foregroundColor(CryptogramTheme.Colors.text)
                        .font(.footnote)
                    
                    if viewModel.hintCount == 0 {
                        // Show "none!" text with green tick
                        HStack(spacing: 4) {
                            Text("none!")
                                .foregroundColor(CryptogramTheme.Colors.text)
                            
                            Image(systemName: "checkmark")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(checkmarkColor)
                        }
                    } else {
                        // Show lightbulb and count for hints used - using theme color and outline version
                        Image(systemName: "lightbulb")
                            .rotationEffect(.degrees(45))
                            .foregroundColor(CryptogramTheme.Colors.text)
                            .font(.system(size: 14))
                        
                        Text("\(viewModel.hintCount)")
                            .foregroundColor(CryptogramTheme.Colors.text)
                    }
                }
            }
            .font(.footnote)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            
            Spacer()
        }
    }
    
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}