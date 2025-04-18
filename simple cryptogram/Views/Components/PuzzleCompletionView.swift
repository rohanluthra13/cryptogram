import SwiftUI

struct PuzzleCompletionView: View {
    @EnvironmentObject private var viewModel: PuzzleViewModel
    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject private var settingsViewModel: SettingsViewModel
    @Binding var showCompletionView: Bool
    @State private var showSettings = false
    @AppStorage("isDarkMode") private var isDarkMode = false
    
    // Animation states
    @State private var showQuote = false
    @State private var showAttribution = false
    @State private var showStats = false
    @State private var showNextButton = false
    @State private var displayedQuote = ""
    @State private var authorIsBold = false
    @State private var isAuthorVisible = false
    
    // Typewriter animation properties
    var typingSpeed: Double = 0.09
    @State private var typingTimer: Timer?
    @State private var currentCharacterIndex = 0
    @State private var quoteToType = ""
    // Author summary typewriter animation
    @State private var displayedSummary = ""
    @State private var summaryTypingTimer: Timer?
    @State private var summaryCharacterIndex = 0
    @State private var isSummaryTyping = false
    
    // Helper for summary typing speed
    var summaryTypingSpeed: Double { 0.015 }
    
    var body: some View {
        ZStack {
            // Background
            CryptogramTheme.Colors.background
                .edgesIgnoringSafeArea(.all)

            VStack(spacing: 0) {
                Spacer(minLength: 0)
                // Main content (quote, author, summary)
                VStack(spacing: 24) {
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
                            .onTapGesture {
                                skipTypingAnimation()
                            }
                    }
                    // Author attribution - removed the redundant attribution with dash
                    Spacer().frame(height: 8).opacity(showAttribution ? 1 : 0)
                    // Source/hint
                    if let source = viewModel.currentPuzzle?.hint, !source.isEmpty {
                        let processedSource = source.hasPrefix("Author:") ? 
                            source.replacingOccurrences(of: "Author:", with: "").trimmingCharacters(in: .whitespacesAndNewlines) : 
                            source
                        Text(processedSource)
                            .font(.caption)
                            .foregroundColor(CryptogramTheme.Colors.text)
                            .fontWeight(isAuthorVisible ? .bold : .regular)
                            .padding(.top, 4)
                            .opacity(showAttribution ? 1 : 0)
                            .onTapGesture {
                                guard let name = viewModel.currentPuzzle?.authorName else { return }
                                viewModel.loadAuthorIfNeeded(name: name)
                                withAnimation { isAuthorVisible.toggle() }
                                if !isAuthorVisible {
                                    summaryTypingTimer?.invalidate()
                                    displayedSummary = ""
                                    summaryCharacterIndex = 0
                                    isSummaryTyping = false
                                } else {
                                    startSummaryTyping()
                                }
                            }
                    }
                    // Author summary area (fixed height to prevent shifting)
                    ZStack(alignment: .top) {
                        if isAuthorVisible {
                            VStack(spacing: 0) {
                                Text(verbatim: displayedSummary.isEmpty ? "\u{00a0}" : displayedSummary)
                                    .font(.caption)
                                    .foregroundColor(CryptogramTheme.Colors.text)
                                    .padding(.top, 2)
                                    .padding(.horizontal, 6)
                                    .frame(maxWidth: .infinity, alignment: .top)
                                    .onTapGesture { skipSummaryTyping() }
                                    .animation(.easeOut(duration: 0.13), value: displayedSummary)
                                Spacer()
                            }
                        } else {
                            Text(verbatim: "\u{00a0}")
                                .font(.caption)
                                .padding(.top, 2)
                                .padding(.horizontal, 6)
                                .hidden()
                        }
                    }
                    .frame(height: 180)
                    .overlay(
                        Rectangle()
                            .frame(height: 1)
                            .foregroundColor(Color.gray.opacity(0.4)),
                        alignment: .bottom
                    )
                    .onChange(of: viewModel.currentAuthor?.summary) { newSummary in
                        if isAuthorVisible, let summary = newSummary, summary != displayedSummary, summary != "Loading author summary..." {
                            startSummaryTyping()
                        }
                    }
                }
                .padding(.horizontal)
                // Stats and button container (fixed at bottom)
                VStack(spacing: 8) {
                    if viewModel.isFailed {
                        Text("Too many mistakes!")
                            .font(.headline)
                            .foregroundColor(CryptogramTheme.Colors.error)
                            .padding(.vertical, 5)
                            .opacity(showStats ? 1 : 0)
                    }
                    CompletionStatsView()
                        .environmentObject(viewModel)
                        .opacity(showStats ? 1 : 0)
                        .offset(y: showStats ? 0 : 20)
                    Button(action: { loadNextPuzzle() }) {
                        Image(systemName: viewModel.isFailed ? "arrow.counterclockwise" : "arrow.right")
                            .font(.system(size: 22))
                            .foregroundColor(CryptogramTheme.Colors.text)
                    }
                    .opacity(showNextButton ? 1 : 0)
                    .offset(y: showNextButton ? 0 : 15)
                }
                .padding(.bottom, 120)
            }
            .padding(CryptogramTheme.Layout.gridPadding)

            // Settings button at top right
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Spacer()
                    Button(action: { 
                        showSettings.toggle() 
                    }) {
                        Image(systemName: "gearshape")
                            .font(.title3)
                            .foregroundColor(CryptogramTheme.Colors.text)
                            .padding(.trailing, 16)
                            .padding(.top, 8)
                            .accessibilityLabel("Settings")
                    }
                }
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .zIndex(101)

            // Settings overlay
            if showSettings {
                ZStack {
                    CryptogramTheme.Colors.surface
                        .opacity(0.95)
                        .edgesIgnoringSafeArea(.all)
                        .onTapGesture {
                            showSettings = false
                        }
                    SettingsContentView()
                        .environmentObject(settingsViewModel)
                        .environmentObject(themeManager)
                        .frame(maxWidth: 500)
                        .padding(.top, 50)
                        .transition(.move(edge: .top))
                }
                .zIndex(200)
            }
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
    
    func skipTypingAnimation() {
        // Cancel the typing timer
        typingTimer?.invalidate()
        typingTimer = nil
        
        // Complete the quote immediately
        displayedQuote = quoteToType
        
        // Bold the author name immediately
        withAnimation {
            authorIsBold = true
        }
    }
    
    // MARK: - Author Summary Typewriter Animation
    func startSummaryTyping() {
        summaryTypingTimer?.invalidate()
        guard let summary = viewModel.currentAuthor?.summary else {
            displayedSummary = "Loading author summary..."
            return
        }
        displayedSummary = ""
        summaryCharacterIndex = 0
        isSummaryTyping = true
        summaryTypingTimer = Timer.scheduledTimer(withTimeInterval: summaryTypingSpeed, repeats: true) { timer in
            if summaryCharacterIndex < summary.count {
                let idx = summary.index(summary.startIndex, offsetBy: summaryCharacterIndex + 1)
                displayedSummary = String(summary[..<idx])
                summaryCharacterIndex += 1
            } else {
                isSummaryTyping = false
                timer.invalidate()
            }
        }
    }
    
    func skipSummaryTyping() {
        guard isSummaryTyping, let summary = viewModel.currentAuthor?.summary else { return }
        summaryTypingTimer?.invalidate()
        displayedSummary = summary
        summaryCharacterIndex = summary.count
        isSummaryTyping = false
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

#if DEBUG
struct PuzzleCompletionView_Previews: PreviewProvider {
    @State static var showCompletionView = true
    static var previews: some View {
        PuzzleCompletionView(showCompletionView: $showCompletionView)
            .environmentObject(PuzzleViewModel())
            .environmentObject(ThemeManager())
            .environmentObject(SettingsViewModel())
    }
}
#endif