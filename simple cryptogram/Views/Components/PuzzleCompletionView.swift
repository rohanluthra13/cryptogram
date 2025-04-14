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
    @State private var displayedQuote = ""
    @State private var authorIsBold = false
    
    // Typewriter animation properties
    var typingSpeed: Double = 0.09
    @State private var typingTimer: Timer?
    @State private var currentCharacterIndex = 0
    @State private var quoteToType = ""
    
    var body: some View {
        ZStack {
            // Background
            CryptogramTheme.Colors.background
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 24) {
                Spacer()
                
                // Header - different for success vs failure
                if viewModel.isFailed {
                    Text("Game Over")
                        .font(.system(.title, design: .rounded))
                        .foregroundColor(CryptogramTheme.Colors.error)
                        .opacity(showQuote ? 1 : 0)
                        .scaleEffect(showQuote ? 1 : 0.9)
                        .padding(.top, 20)
                }
                
                // Quote
                if let quote = viewModel.currentPuzzle?.solution {
                    Text(displayedQuote.uppercased())
                        .font(.system(.body, design: .default))
                        .multilineTextAlignment(.center)
                        .foregroundColor(CryptogramTheme.Colors.text)
                        .padding(.horizontal, 32)
                        .opacity(showQuote ? 1 : 0)
                        .scaleEffect(showQuote ? 1 : 0.9)
                }
                
                // Author attribution - removed the redundant attribution with dash
                Spacer()
                    .frame(height: 8)
                    .opacity(showAttribution ? 1 : 0)
                
                // Source/hint
                if let source = viewModel.currentPuzzle?.hint, !source.isEmpty {
                    // Check if hint starts with "Author:" and remove that part if it does
                    let processedSource = source.hasPrefix("Author:") ? 
                        source.replacingOccurrences(of: "Author:", with: "").trimmingCharacters(in: .whitespacesAndNewlines) : 
                        source
                    
                    Text(processedSource)
                        .font(.caption)
                        .foregroundColor(CryptogramTheme.Colors.text)
                        .fontWeight(authorIsBold ? .bold : .regular)
                        .padding(.top, 4)
                        .opacity(showAttribution ? 1 : 0)
                }
                
                Spacer(minLength: 20) // Reduced spacer to move stats up
                
                // Display a message for failure case
                if viewModel.isFailed {
                    Text("Too many mistakes!")
                        .font(.headline)
                        .foregroundColor(CryptogramTheme.Colors.error)
                        .padding(.vertical, 5)
                        .opacity(showStats ? 1 : 0)
                }
                
                // Stats and button container
                VStack(spacing: 8) {
                    // Stats
                    CompletionStatsView(viewModel: viewModel)
                        .opacity(showStats ? 1 : 0)
                        .offset(y: showStats ? 0 : 20)
                    
                    // Next button directly below stats with minimal spacing
                    Button(action: { loadNextPuzzle() }) {
                        Image(systemName: viewModel.isFailed ? "arrow.counterclockwise" : "arrow.right")
                            .font(.system(size: 22))
                            .foregroundColor(CryptogramTheme.Colors.text)
                    }
                    .opacity(showNextButton ? 1 : 0)
                    .offset(y: showNextButton ? 0 : 15)
                }
                .padding(.bottom, 120)  // Increased padding to push everything higher
            }
            .padding(CryptogramTheme.Layout.gridPadding)
        }
        .onAppear {
            startAnimationSequence()
        }
    }
    
    func startAnimationSequence() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.4)) {
            showQuote = true
        }
        
        // Start typewriter effect after quote container appears
        if let quoteText = viewModel.currentPuzzle?.solution {
            // Delay the start of typing to ensure container is visible first
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                startTypewriterAnimation(for: quoteText)
            }
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
    
    func startTypewriterAnimation(for text: String) {
        displayedQuote = ""
        quoteToType = text
        currentCharacterIndex = 0
        
        // Cancel any existing timer
        typingTimer?.invalidate()
        
        // Create a timer that adds one character at a time
        typingTimer = Timer.scheduledTimer(withTimeInterval: typingSpeed, repeats: true) { timer in
            if currentCharacterIndex < quoteToType.count {
                let index = quoteToType.index(quoteToType.startIndex, offsetBy: currentCharacterIndex)
                displayedQuote += String(quoteToType[index])
                currentCharacterIndex += 1
            } else {
                timer.invalidate()
                typingTimer = nil
                
                // Bold the author name after quote is typed
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation {
                        authorIsBold = true
                    }
                }
            }
        }
    }
    
    func loadNextPuzzle() {
        // Hide the completion view first
        withAnimation(.easeOut(duration: 0.3)) {
            showCompletionView = false
        }
        
        // Reset current session and load next puzzle
        viewModel.reset()
        
        if viewModel.isFailed && viewModel.currentPuzzle != nil {
            // For "Try Again": reuse the same puzzle but apply difficulty settings
            viewModel.startNewPuzzle(puzzle: viewModel.currentPuzzle!)
        } else {
            // For "Next Puzzle": get a new puzzle with current settings
            viewModel.refreshPuzzleWithCurrentSettings()
        }
    }
} 