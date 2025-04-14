import SwiftUI

struct PuzzleCompletionView: View {
    @ObservedObject var viewModel: PuzzleViewModel
    @Environment(\.colorScheme) var colorScheme
    @Binding var showCompletionView: Bool
    
    // Animation states
    @State private var showQuote = false
    @State private var showAttribution = false
    @State private var showStats = false
    @State private var showNextButton = false
    
    var body: some View {
        ZStack {
            // Background
            CryptogramTheme.Colors.background
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 24) {
                // Header with icon
                Image(systemName: "trophy.fill")
                    .font(.system(size: 48))
                    .foregroundColor(CryptogramTheme.Colors.primary)
                    .opacity(showQuote ? 1 : 0)
                    .scaleEffect(showQuote ? 1 : 0.8)
                
                Spacer()
                
                // Quote
                if let quote = viewModel.currentPuzzle?.solution {
                    Text(quote)
                        .font(.system(.title3, design: .serif))
                        .italic()
                        .multilineTextAlignment(.center)
                        .foregroundColor(CryptogramTheme.Colors.text)
                        .padding(.horizontal, 32)
                        .opacity(showQuote ? 1 : 0)
                        .scaleEffect(showQuote ? 1 : 0.9)
                }
                
                // Attribution
                if let author = viewModel.currentPuzzle?.author, !author.isEmpty {
                    HStack {
                        Spacer()
                        Text("— \(author)")
                            .font(.subheadline)
                            .foregroundColor(CryptogramTheme.Colors.secondary)
                    }
                    .padding(.horizontal, 40)
                    .opacity(showAttribution ? 1 : 0)
                }
                
                if let source = viewModel.currentPuzzle?.hint, !source.isEmpty {
                    Text(source)
                        .font(.caption)
                        .foregroundColor(CryptogramTheme.Colors.secondary.opacity(0.7))
                        .padding(.top, 4)
                        .opacity(showAttribution ? 1 : 0)
                }
                
                Spacer()
                
                // Stats
                CompletionStatsView(viewModel: viewModel)
                    .opacity(showStats ? 1 : 0)
                    .offset(y: showStats ? 0 : 20)
                
                // Next button
                Button(action: { loadNextPuzzle() }) {
                    Text("Next Puzzle")
                        .font(CryptogramTheme.Typography.button)
                        .foregroundColor(.white)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 24)
                        .background(CryptogramTheme.Colors.primary)
                        .cornerRadius(CryptogramTheme.Layout.buttonCornerRadius)
                }
                .opacity(showNextButton ? 1 : 0)
                .offset(y: showNextButton ? 0 : 15)
                .padding(.bottom, 32)
            }
            .padding(CryptogramTheme.Layout.gridPadding)
        }
        .onAppear {
            startAnimationSequence()
        }
    }
    
    private func startAnimationSequence() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.4)) {
            showQuote = true
        }
        
        withAnimation(.easeInOut(duration: 0.5).delay(1.2)) {
            showAttribution = true
        }
        
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(1.8)) {
            showStats = true
        }
        
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(2.3)) {
            showNextButton = true
        }
    }
    
    private func loadNextPuzzle() {
        // Hide the completion view first
        withAnimation(.easeOut(duration: 0.3)) {
            showCompletionView = false
        }
        
        // Reset current session and load next puzzle
        viewModel.reset()
        
        // Load next puzzle
        viewModel.refreshPuzzleWithCurrentSettings()
    }
} 