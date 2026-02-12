import SwiftUI

struct PuzzleCompletionView: View {
    @Environment(PuzzleViewModel.self) private var viewModel
    @Environment(ThemeManager.self) private var themeManager
    @Environment(AppSettings.self) private var appSettings
    @Environment(NavigationCoordinator.self) private var navigationCoordinator
    @Environment(\.typography) private var typography
    @Binding var showCompletionView: Bool

    // Bottom bar state
    @State private var uiState = PuzzleViewState()
    
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
    var isDailyPuzzle: Bool = false

    // State for managing typing animation
    @State private var summaryTypingTask: Task<Void, Never>?
    
    // MARK: - Helper for line typing animation
    private func typeLine(line: String, setter: @escaping (String) -> Void) async {
        let characters = Array(line)

        for currentIndex in 0...characters.count {
            guard !Task.isCancelled else { return }
            setter(String(characters.prefix(currentIndex)))
            if currentIndex < characters.count {
                try? await Task.sleep(for: .seconds(summaryTypingSpeed))
            }
        }
    }

    private func skipSummaryTyping() {
        // Cancel ongoing animation
        summaryTypingTask?.cancel()
        
        showSummaryLine = true
        showBornLine = true
        showDiedLine = true
        if let author = viewModel.currentAuthor {
            summaryTyped = (author.summary ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            if let birthDate = formattedDate(author.birthDate) {
                bornTyped = (author.placeOfBirth?.isEmpty == false) ? " \(birthDate) (\(author.placeOfBirth!))" : " \(birthDate)"
            } else {
                bornTyped = ""
            }
            if let deathDate = formattedDate(author.deathDate) {
                diedTyped = (author.placeOfDeath?.isEmpty == false) ? " \(deathDate) (\(author.placeOfDeath!))" : " \(deathDate)"
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
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Main content (quote, author, summary)
                VStack(spacing: 24) {
                    // Quote
                    if viewModel.currentPuzzle?.solution != nil {
                        Text(displayedQuote.uppercased())
                            .font(typography.body)
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
                    // Source/hint with info button
                    if let source = viewModel.currentPuzzle?.hint, !source.isEmpty {
                        let processedSource = source.hasPrefix("Author:") ? 
                            source.replacingOccurrences(of: "Author:", with: "").trimmingCharacters(in: .whitespacesAndNewlines) : 
                            source
                        
                        // Container to keep author centered while adding info button
                        ZStack {
                            // Centered author name
                            Text(processedSource)
                                .font(typography.caption)
                                .foregroundColor(CryptogramTheme.Colors.text)
                                .fontWeight(isAuthorVisible ? .bold : .regular)
                                .padding(.top, 4)
                                .opacity(showAttribution ? 1 : 0)
                                .onTapGesture {
                                    guard let name = viewModel.currentPuzzle?.authorName else { return }
                                    withAnimation { isAuthorVisible.toggle() }
                                }

                            // Info button positioned to the right
                            HStack {
                                Spacer()
                                Button(action: {
                                    withAnimation { isAuthorVisible.toggle() }
                                }) {
                                    Text("i")
                                        .font(.system(size: 14, weight: .medium, design: .rounded))
                                        .foregroundColor(CryptogramTheme.Colors.text.opacity(0.6))
                                        .frame(width: 18, height: 18)
                                }
                                .opacity(showAttribution ? 1 : 0)
                                .padding(.trailing, 60) // Position it more to the right
                            }
                            .padding(.top, 4)
                        }
                    }
                    // Author summary area (fixed height to prevent shifting)
                    ZStack(alignment: .top) {
                        if isAuthorVisible {
                            ScrollView(.vertical, showsIndicators: false) {
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
                                                    .font(typography.caption)
                                                    .foregroundColor(CryptogramTheme.Colors.text)
                                                    .frame(maxWidth: .infinity, alignment: .leading)
                                                    .transition(.opacity)
                                            }
                                            if bornLine != nil, showBornLine {
                                                HStack(alignment: .top, spacing: 0) {
                                                    Text("Born:")
                                                        .bold()
                                                        .font(typography.caption)
                                                        .foregroundColor(CryptogramTheme.Colors.text)
                                                    Text(bornTyped)
                                                        .font(typography.caption)
                                                        .foregroundColor(CryptogramTheme.Colors.text)
                                                }
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                                .transition(.opacity)
                                            }
                                            if let _ = diedLine, showDiedLine {
                                                HStack(alignment: .top, spacing: 0) {
                                                    Text("Died:")
                                                        .bold()
                                                        .font(typography.caption)
                                                        .foregroundColor(CryptogramTheme.Colors.text)
                                                    Text(diedTyped)
                                                        .font(typography.caption)
                                                        .foregroundColor(CryptogramTheme.Colors.text)
                                                }
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                                .transition(.opacity)
                                            }
                                        }
                                        .padding(.horizontal, 10)
                                        .onTapGesture {
                                            skipSummaryTyping()
                                        }
                                        .onAppear {
                                            showSummaryLine = false; showBornLine = false; showDiedLine = false
                                            summaryTyped = ""; bornTyped = ""; diedTyped = ""
                                            // Cancel any existing animation
                                            summaryTypingTask?.cancel()
                                            // Animate all lines sequentially using async/await
                                            summaryTypingTask = Task {
                                                withAnimation(.easeOut(duration: 0.3)) { showSummaryLine = true }
                                                await typeLine(line: summaryText, setter: { summaryTyped = $0 })
                                                guard !Task.isCancelled else { return }

                                                if bornLine != nil {
                                                    withAnimation(.easeOut(duration: 0.3)) { showBornLine = true }
                                                    await typeLine(line: " " + String(bornLine!.dropFirst(5)), setter: { bornTyped = $0 })
                                                    guard !Task.isCancelled else { return }
                                                }

                                                if diedLine != nil {
                                                    if bornLine != nil {
                                                        try? await Task.sleep(for: .seconds(0.2))
                                                        guard !Task.isCancelled else { return }
                                                    }
                                                    withAnimation(.easeOut(duration: 0.3)) { showDiedLine = true }
                                                    await typeLine(line: " " + String(diedLine!.dropFirst(5)), setter: { diedTyped = $0 })
                                                }
                                            }
                                        }
                                        .onDisappear {
                                            // Cancel ongoing animation
                                            summaryTypingTask?.cancel()
                                            showSummaryLine = false; showBornLine = false; showDiedLine = false
                                            summaryTyped = ""; bornTyped = ""; diedTyped = ""
                                        }
                                        .animation(.easeOut(duration: 0.13), value: showSummaryLine)
                                        .animation(.easeOut(duration: 0.13), value: showBornLine)
                                        .animation(.easeOut(duration: 0.13), value: showDiedLine)
                                        Spacer()
                                    } else {
                                        Text(verbatim: summaryTyped.isEmpty ? "\u{00a0}" : summaryTyped)
                                            .font(typography.caption)
                                            .foregroundColor(CryptogramTheme.Colors.text)
                                            .padding(.horizontal, 6)
                                            .frame(maxWidth: .infinity, alignment: .top)
                                            .onTapGesture { skipSummaryTyping() }
                                            .animation(.easeOut(duration: 0.13), value: summaryTyped)
                                        Spacer()
                                    }
                                }
                            }
                        } else {
                            Text(verbatim: "\u{00a0}")
                                .font(typography.caption)
                                .foregroundColor(CryptogramTheme.Colors.text)
                                .padding(.horizontal, 6)
                                .frame(maxWidth: .infinity, alignment: .top)
                                .animation(.easeOut(duration: 0.13), value: showSummaryLine)
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
                    if !hideStats {
                        CompletionStatsView()
                            .environment(viewModel)
                            .opacity(showStats ? 1 : 0)
                            .offset(y: showStats ? 0 : 20)
                    }
                    // Action buttons: Calendar for daily, Next for regular
                    HStack(spacing: 40) {
                        if isDailyPuzzle {
                            Button(action: {
                                goToCalendar()
                            }) {
                                Image(systemName: "calendar")
                                    .font(.system(size: 22))
                                    .foregroundColor(CryptogramTheme.Colors.text)
                                    .frame(width: 44, height: 44)
                            }
                        }
                        
                        Button(action: { 
                            loadNextPuzzle()
                        }) {
                            Image(systemName: "arrow.right")
                                .font(.system(size: 22))
                                .foregroundColor(CryptogramTheme.Colors.text)
                                .frame(width: 44, height: 44)
                        }
                    }
                    .opacity(showNextButton ? 1 : 0)
                    .offset(y: showNextButton ? 0 : 15)
                }
                .padding(.bottom, 120)
            }
            .frame(maxHeight: .infinity)
            .padding(CryptogramTheme.Layout.gridPadding)
            
            // Bottom bar with three icons (for all completion views)
            BottomBarView(uiState: uiState)
                .environment(navigationCoordinator)
                .opacity(showNextButton ? 1 : 0)
                .animation(.easeInOut(duration: 0.5), value: showNextButton)
            
            // Unified overlays handled by commonOverlays modifier below
            
        }
        .gesture(
            DragGesture()
                .onEnded { value in
                    // Swipe right to go back (natural back navigation)
                    if value.translation.width > 100 && abs(value.translation.height) < 100 {
                        navigationCoordinator.navigateBack()
                    }
                }
        )
        .commonOverlays(
            showSettings: $uiState.showSettings,
            showStats: $uiState.showStatsOverlay,
            showCalendar: $uiState.showCalendar,
            showInfoOverlay: $uiState.showInfoOverlay
        )
        .onAppear {
            // Reset author summary state on appear
            isAuthorVisible = false
            summaryTyped = ""
            bornTyped = ""
            diedTyped = ""
            showSummaryLine = false
            showBornLine = false
            showDiedLine = false
            startAnimationSequence()
            
            // Show bottom bar and start auto-hide timer
            uiState.showBottomBarTemporarily()
        }
    }
    
    func startAnimationSequence() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.4)) {
            showQuote = true
        }

        // Start typewriter effect after quote container appears
        if let quoteText = viewModel.currentPuzzle?.solution {
            // Delay the start of typing to ensure container is visible first
            Task {
                try? await Task.sleep(for: .seconds(0.8))
                guard !Task.isCancelled else { return }
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
                Task { @MainActor in
                    try? await Task.sleep(for: .seconds(0.3))
                    guard !Task.isCancelled else { return }
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
        // Hide the completion view and immediately load next puzzle
        withAnimation(.easeOut(duration: 0.3)) {
            showCompletionView = false
        }
        
        // Reset and load next puzzle without delay
        viewModel.reset()
        viewModel.refreshPuzzleWithCurrentSettings()
    }
    
    func goHome() {
        // Navigate directly without hiding the view first
        navigationCoordinator.navigateToHome()
    }
    
    func goToCalendar() {
        // Set flag to show calendar when we return to home
        appSettings.shouldShowCalendarOnReturn = true
        
        // Navigate directly without hiding the view first
        navigationCoordinator.navigateToHome()
    }
}

#if DEBUG
struct PuzzleCompletionView_Previews: PreviewProvider {
    @State static var showCompletionView = true
    static var previews: some View {
        PuzzleCompletionView(showCompletionView: $showCompletionView)
            .environment(PuzzleViewModel())
            .environment(ThemeManager())
            .environment(AppSettings())
            .environment(NavigationCoordinator())
    }
}
#endif