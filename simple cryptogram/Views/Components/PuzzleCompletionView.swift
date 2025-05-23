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
    
    // MARK: - Author Summary Animated Display
    @State private var showSummaryLine = false
    @State private var showBornLine = false
    @State private var showDiedLine = false
    @State private var summaryTyped = ""
    @State private var bornTyped = ""
    @State private var diedTyped = ""

    // Helper for summary typing speed
    var summaryTypingSpeed: Double { 0.015 }

    var hideStats: Bool = false

    // MARK: - Helper for line typing animation
    private func typeLine(line: String, setter: @escaping (String) -> Void, completion: @escaping () -> Void) {
        let characters = Array(line)
        var currentIndex = 0
        func typeNext() {
            if currentIndex <= characters.count {
                setter(String(characters.prefix(currentIndex)))
                currentIndex += 1
                if currentIndex <= characters.count {
                    DispatchQueue.main.asyncAfter(deadline: .now() + summaryTypingSpeed) {
                        typeNext()
                    }
                } else {
                    completion()
                }
            }
        }
        typeNext()
    }

    private func skipSummaryTyping() {
        showSummaryLine = true
        showBornLine = true
        showDiedLine = true
        if let author = viewModel.currentAuthor {
            summaryTyped = (author.summary ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            if let birthDate = formattedDate(author.birthDate) {
                bornTyped = (author.placeOfBirth?.isEmpty == false) ? "\(birthDate) (\(author.placeOfBirth!))" : birthDate
            } else {
                bornTyped = ""
            }
            if let deathDate = formattedDate(author.deathDate) {
                diedTyped = (author.placeOfDeath?.isEmpty == false) ? "\(deathDate) (\(author.placeOfDeath!))" : deathDate
            } else {
                diedTyped = ""
            }
        } else {
            summaryTyped = ""
            bornTyped = ""
            diedTyped = ""
        }
    }

    // MARK: - Date Formatting Helper
    private func formattedDate(_ dateString: String?) -> String? {
        guard let dateString = dateString, !dateString.isEmpty else { return nil }
        let formats = ["yyyy-MM-dd", "yyyy-MM", "yyyy"]
        let outputFormatter = DateFormatter()
        outputFormatter.locale = Locale(identifier: "en_US_POSIX")
        outputFormatter.dateFormat = "d MMM yyyy"
        for format in formats {
            let inputFormatter = DateFormatter()
            inputFormatter.locale = Locale(identifier: "en_US_POSIX")
            inputFormatter.dateFormat = format
            if let date = inputFormatter.date(from: dateString) {
                return outputFormatter.string(from: date)
            }
        }
        return dateString // fallback to raw if parsing fails
    }

    var body: some View {
        ZStack {
            // Background
            CryptogramTheme.Colors.background
                .edgesIgnoringSafeArea(.all)

            VStack(spacing: 0) {
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
                            }
                    }
                    // Author summary area (fixed height to prevent shifting)
                    ZStack(alignment: .top) {
                        if isAuthorVisible {
                            VStack(spacing: 0) {
                                if let author = viewModel.currentAuthor {
                                    let summaryText = (author.summary ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                                    let bornDate = formattedDate(author.birthDate)
                                    let diedDate = formattedDate(author.deathDate)
                                    let bornLine = (bornDate != nil) ? "Born: \(bornDate!)" + (author.placeOfBirth?.isEmpty == false ? " (\(author.placeOfBirth!))" : "") : nil
                                    let diedLine = (diedDate != nil) ? "Died: \(diedDate!)" + (author.placeOfDeath?.isEmpty == false ? " (\(author.placeOfDeath!))" : "") : nil
                                    VStack(alignment: .leading, spacing: 8) {
                                        if showSummaryLine {
                                            Text(summaryTyped)
                                                .font(.caption)
                                                .foregroundColor(CryptogramTheme.Colors.text)
                                                .transition(.opacity)
                                        }
                                        if let bornLine = bornLine, showBornLine {
                                            HStack(alignment: .top, spacing: 0) {
                                                Text("Born:")
                                                    .bold()
                                                    .font(.caption)
                                                    .foregroundColor(CryptogramTheme.Colors.text)
                                                Text(bornTyped)
                                                    .font(.caption)
                                                    .foregroundColor(CryptogramTheme.Colors.text)
                                            }
                                            .transition(.opacity)
                                        }
                                        if let diedLine = diedLine, showDiedLine {
                                            HStack(alignment: .top, spacing: 0) {
                                                Text("Died:")
                                                    .bold()
                                                    .font(.caption)
                                                    .foregroundColor(CryptogramTheme.Colors.text)
                                                Text(diedTyped)
                                                    .font(.caption)
                                                    .foregroundColor(CryptogramTheme.Colors.text)
                                            }
                                            .transition(.opacity)
                                        }
                                    }
                                    .padding(.horizontal, 10)
                                    .onAppear {
                                        showSummaryLine = false; showBornLine = false; showDiedLine = false
                                        summaryTyped = ""; bornTyped = ""; diedTyped = ""
                                        // Animate summary line typing
                                        withAnimation(.easeOut(duration: 0.3)) { showSummaryLine = true }
                                        typeLine(line: summaryText, setter: { summaryTyped = $0 }) {
                                            if bornLine != nil {
                                                withAnimation(.easeOut(duration: 0.3)) { showBornLine = true }
                                                typeLine(line: String(bornLine!.dropFirst(5)), setter: { bornTyped = $0 }) {
                                                    if diedLine != nil {
                                                        let diedDelay = (bornLine != nil) ? 0.2 : 0.0
                                                        DispatchQueue.main.asyncAfter(deadline: .now() + diedDelay) {
                                                            withAnimation(.easeOut(duration: 0.3)) { showDiedLine = true }
                                                            typeLine(line: String(diedLine!.dropFirst(5)), setter: { diedTyped = $0 }, completion: {})
                                                        }
                                                    }
                                                }
                                            } else if diedLine != nil {
                                                withAnimation(.easeOut(duration: 0.3)) { showDiedLine = true }
                                                typeLine(line: String(diedLine!.dropFirst(5)), setter: { diedTyped = $0 }, completion: {})
                                            }
                                        }
                                    }
                                    .onDisappear {
                                        showSummaryLine = false; showBornLine = false; showDiedLine = false
                                        summaryTyped = ""; bornTyped = ""; diedTyped = ""
                                    }
                                    .animation(.easeOut(duration: 0.13), value: showSummaryLine)
                                    .animation(.easeOut(duration: 0.13), value: showBornLine)
                                    .animation(.easeOut(duration: 0.13), value: showDiedLine)
                                    Spacer()
                                } else {
                                    Text(verbatim: summaryTyped.isEmpty ? "\u{00a0}" : summaryTyped)
                                        .font(.caption)
                                        .foregroundColor(CryptogramTheme.Colors.text)
                                        .padding(.horizontal, 6)
                                        .frame(maxWidth: .infinity, alignment: .top)
                                        .onTapGesture { skipSummaryTyping() }
                                        .animation(.easeOut(duration: 0.13), value: summaryTyped)
                                    Spacer()
                                }
                            }
                        } else {
                            Text(verbatim: "\u{00a0}")
                                .font(.caption)
                                .foregroundColor(CryptogramTheme.Colors.text)
                                .padding(.horizontal, 6)
                                .frame(maxWidth: .infinity, alignment: .top)
                                .animation(.easeOut(duration: 0.13))
                            Spacer()
                        }
                    }
                    .frame(height: 150)
                }
                .padding(.top, 120)
                .frame(maxWidth: .infinity, alignment: .top)

                Spacer()

                // Stats and button container
                VStack(spacing: 8) {
                    if viewModel.isFailed {
                        Text("Too many mistakes!")
                            .font(.headline)
                            .foregroundColor(CryptogramTheme.Colors.error)
                            .padding(.vertical, 5)
                            .opacity(showStats ? 1 : 0)
                    }
                    if !hideStats {
                        CompletionStatsView()
                            .environmentObject(viewModel)
                            .opacity(showStats ? 1 : 0)
                            .offset(y: showStats ? 0 : 20)
                    }
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
            .frame(maxHeight: .infinity)
            .padding(CryptogramTheme.Layout.gridPadding)
        }
        .onAppear {
            // Reset author summary state on appear
            viewModel.currentAuthor = nil
            isAuthorVisible = false
            summaryTyped = ""
            bornTyped = ""
            diedTyped = ""
            showSummaryLine = false
            showBornLine = false
            showDiedLine = false
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