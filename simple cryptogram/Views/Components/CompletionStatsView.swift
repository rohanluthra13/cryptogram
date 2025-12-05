import SwiftUI

struct CompletionStatsView: View {
    @Environment(PuzzleViewModel.self) private var viewModel
    @Environment(\.typography) private var typography
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
                            .font(typography.footnote)
                        Text(completionTime.formattedAsShortMinutesSeconds)
                            .foregroundColor(CryptogramTheme.Colors.text)
                    }
                }
                
                // Mistakes - show green tick if no mistakes, otherwise show 3 cross icons
                HStack(spacing: 8) {
                    Text("mistakes:")
                        .foregroundColor(CryptogramTheme.Colors.text)
                        .font(typography.footnote)
                    
                    if viewModel.mistakeCount == 0 {
                        // Show "none!" text with green tick
                        HStack(spacing: 4) {
                            Text("none!")
                                .foregroundColor(CryptogramTheme.Colors.text)
                            
                            Image(systemName: "checkmark")
                                .font(typography.caption.weight(.semibold))
                                .foregroundColor(checkmarkColor)
                        }
                    } else {
                        // Show crosses for mistakes
                        HStack(spacing: 8) {
                            ForEach(0..<maxMistakes, id: \.self) { index in
                                Text("X")
                                    .font(typography.body.weight(.bold))
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
                        .font(typography.footnote)
                    
                    if viewModel.hintCount == 0 {
                        // Show "none!" text with green tick
                        HStack(spacing: 4) {
                            Text("none!")
                                .foregroundColor(CryptogramTheme.Colors.text)
                            
                            Image(systemName: "checkmark")
                                .font(typography.caption.weight(.semibold))
                                .foregroundColor(checkmarkColor)
                        }
                    } else {
                        // Show lightbulb and count for hints used - using green color and filled version
                        Image(systemName: "lightbulb.fill")
                            .rotationEffect(.degrees(45))
                            .foregroundColor(Color(hex: "#01780F").opacity(0.5))
                            .font(typography.caption)
                        
                        Text("\(viewModel.hintCount)")
                            .foregroundColor(CryptogramTheme.Colors.text)
                    }
                }
            }
            .font(typography.footnote)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            
            Spacer()
        }
    }
}