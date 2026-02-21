import SwiftUI

struct PuzzleCompletionView: View {
    @Environment(PuzzleViewModel.self) private var viewModel
    @Environment(ThemeManager.self) private var themeManager
    @Environment(AppSettings.self) private var appSettings
    @Environment(NavigationCoordinator.self) private var navigationCoordinator
    @Environment(\.typography) private var typography
    @Binding var showCompletionView: Bool

    // Overlay state (was PuzzleViewState)
    @State private var showSettings = false
    @State private var showStats = false
    @State private var showCalendar = false
    @State private var showInfo = false

    // Bottom bar auto-hide
    @State private var isBottomBarVisible = true
    @State private var bottomBarHideTask: Task<Void, Never>?

    // Animation states
    @State private var showQuote = false
    @State private var showAttribution = false
    @State private var showStatsAnim = false
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

    var summaryTypingSpeed: Double { 0.015 }

    var hideStats: Bool = false
    var isDailyPuzzle: Bool = false

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
        return dateString
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
                    Spacer().frame(height: 8).opacity(showAttribution ? 1 : 0)
                    // Source/hint with info button
                    if let source = viewModel.currentPuzzle?.hint, !source.isEmpty {
                        let processedSource = source.hasPrefix("Author:") ?
                            source.replacingOccurrences(of: "Author:", with: "").trimmingCharacters(in: .whitespacesAndNewlines) :
                            source

                        ZStack {
                            Text(processedSource)
                                .font(typography.caption)
                                .foregroundColor(CryptogramTheme.Colors.text)
                                .fontWeight(isAuthorVisible ? .bold : .regular)
                                .padding(.top, 4)
                                .opacity(showAttribution ? 1 : 0)
                                .onTapGesture {
                                    guard viewModel.currentPuzzle?.authorName != nil else { return }
                                    withAnimation { isAuthorVisible.toggle() }
                                }

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
                                .padding(.trailing, 60)
                            }
                            .padding(.top, 4)
                        }
                    }
                    // Author summary area
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
                                            summaryTypingTask?.cancel()
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
                            .opacity(showStatsAnim ? 1 : 0)
                            .offset(y: showStatsAnim ? 0 : 20)
                    }
                    HStack(spacing: 40) {
                        if isDailyPuzzle {
                            Button(action: { goToCalendar() }) {
                                Image(systemName: "calendar")
                                    .font(.system(size: 22))
                                    .foregroundColor(CryptogramTheme.Colors.text)
                                    .frame(width: 44, height: 44)
                            }
                        }

                        Button(action: { loadNextPuzzle() }) {
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

            // Bottom bar
            completionBottomBar
                .opacity(showNextButton ? 1 : 0)
                .animation(.easeInOut(duration: 0.5), value: showNextButton)

            // Overlays
            if showSettings {
                FullScreenOverlay(isPresented: $showSettings) {
                    SettingsContentView()
                        .padding(.horizontal, PuzzleViewConstants.Overlay.overlayHorizontalPadding)
                        .padding(.vertical, 20)
                        .background(Color.clear)
                        .environment(viewModel)
                        .environment(themeManager)
                        .environment(appSettings)
                }
                .zIndex(150)
            }

            if showStats {
                FullScreenOverlay(isPresented: $showStats) {
                    VStack(spacing: 0) {
                        Spacer(minLength: 0)
                        UserStatsView(viewModel: viewModel)
                            .padding(.top, 24)
                    }
                }
                .zIndex(150)
            }

            if showCalendar {
                FullScreenOverlay(isPresented: $showCalendar) {
                    ContinuousCalendarView(
                        showCalendar: $showCalendar,
                        onSelectDate: { date in
                            viewModel.loadDailyPuzzle(for: date)
                            if let puzzle = viewModel.currentPuzzle {
                                navigationCoordinator.navigateToPuzzle(puzzle)
                            }
                        }
                    )
                    .id(viewModel.dailyCompletionVersion)
                    .environment(viewModel)
                    .environment(appSettings)
                }
                .zIndex(150)
            }

            if showInfo {
                FullScreenOverlay(isPresented: $showInfo) {
                    VStack {
                        Spacer(minLength: PuzzleViewConstants.Overlay.infoOverlayTopSpacing)
                        ScrollView {
                            InfoOverlayView()
                        }
                        .padding(.horizontal, PuzzleViewConstants.Overlay.overlayHorizontalPadding)
                        Spacer()
                    }
                }
                .zIndex(125)
            }
        }
        .gesture(
            DragGesture()
                .onEnded { value in
                    if value.translation.width > 100 && abs(value.translation.height) < 100 {
                        navigationCoordinator.navigateBack()
                    }
                }
        )
        .onAppear {
            isAuthorVisible = false
            summaryTyped = ""
            bornTyped = ""
            diedTyped = ""
            showSummaryLine = false
            showBornLine = false
            showDiedLine = false
            startAnimationSequence()
            showBottomBarTemporarily()
        }
    }

    // MARK: - Bottom Bar

    @ViewBuilder
    private var completionBottomBar: some View {
        let shouldShowBar = isBottomBarVisible || showSettings || showStats
        let shouldShowTapArea = !(isBottomBarVisible || showSettings || showStats)

        ZStack {
            if shouldShowBar {
                VStack {
                    Spacer()
                    HStack {
                        Button(action: { toggleStats() }) {
                            Image(systemName: "chart.bar")
                                .font(.system(size: PuzzleViewConstants.Sizes.statsIconSize))
                                .foregroundColor(CryptogramTheme.Colors.text)
                                .opacity(PuzzleViewConstants.Colors.iconOpacity)
                                .frame(width: PuzzleViewConstants.Sizes.iconButtonFrame, height: PuzzleViewConstants.Sizes.iconButtonFrame)
                                .accessibilityLabel("Stats/Chart")
                        }

                        Spacer()

                        Button(action: {
                            navigationCoordinator.navigateToHome()
                        }) {
                            Image(systemName: "house")
                                .font(.title3)
                                .foregroundColor(CryptogramTheme.Colors.text)
                                .opacity(PuzzleViewConstants.Colors.iconOpacity)
                                .frame(width: PuzzleViewConstants.Sizes.iconButtonFrame, height: PuzzleViewConstants.Sizes.iconButtonFrame)
                                .accessibilityLabel("Return to Home")
                        }

                        Spacer()

                        Button(action: { toggleSettings() }) {
                            Image(systemName: "gearshape")
                                .font(.system(size: PuzzleViewConstants.Sizes.settingsIconSize))
                                .foregroundColor(CryptogramTheme.Colors.text)
                                .opacity(PuzzleViewConstants.Colors.iconOpacity)
                                .frame(width: PuzzleViewConstants.Sizes.iconButtonFrame, height: PuzzleViewConstants.Sizes.iconButtonFrame)
                                .accessibilityLabel("Settings")
                        }
                    }
                    .frame(height: PuzzleViewConstants.Spacing.bottomBarHeight, alignment: .bottom)
                    .padding(.horizontal, PuzzleViewConstants.Spacing.bottomBarHorizontalPadding)
                    .frame(maxWidth: .infinity)
                    .ignoresSafeArea(edges: .bottom)
                    .contentShape(Rectangle())
                    .onTapGesture { showBottomBarTemporarily() }
                }
                .zIndex(190)
            }

            if shouldShowTapArea {
                VStack {
                    Spacer()
                    Rectangle()
                        .fill(Color.clear)
                        .frame(height: PuzzleViewConstants.Spacing.bottomBarHeight)
                        .frame(maxWidth: .infinity)
                        .ignoresSafeArea(edges: .bottom)
                        .contentShape(Rectangle())
                        .onTapGesture { showBottomBarTemporarily() }
                }
                .zIndex(189)
            }
        }
    }

    // MARK: - Bottom Bar Helpers

    private func showBottomBarTemporarily() {
        isBottomBarVisible = true
        bottomBarHideTask?.cancel()
        bottomBarHideTask = Task {
            try? await Task.sleep(for: .seconds(PuzzleViewConstants.Animation.bottomBarAutoHideDelay))
            guard !Task.isCancelled else { return }
            withAnimation { isBottomBarVisible = false }
        }
    }

    private func toggleSettings() {
        withAnimation {
            showSettings.toggle()
            showStats = false
        }
        showBottomBarTemporarily()
    }

    private func toggleStats() {
        withAnimation {
            showStats.toggle()
            showSettings = false
        }
        showBottomBarTemporarily()
    }

    // MARK: - Animation

    func startAnimationSequence() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.4)) {
            showQuote = true
        }

        if let quoteText = viewModel.currentPuzzle?.solution {
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
            showStatsAnim = true
        }

        withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(2.3)) {
            showNextButton = true
        }
    }

    func startTypewriterAnimation(for text: String) {
        displayedQuote = ""
        quoteToType = text
        currentCharacterIndex = 0
        typingTimer?.invalidate()

        typingTimer = Timer.scheduledTimer(withTimeInterval: typingSpeed, repeats: true) { timer in
            if currentCharacterIndex < quoteToType.count {
                let index = quoteToType.index(quoteToType.startIndex, offsetBy: currentCharacterIndex)
                displayedQuote += String(quoteToType[index])
                currentCharacterIndex += 1
            } else {
                timer.invalidate()
                typingTimer = nil

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
        typingTimer?.invalidate()
        typingTimer = nil
        displayedQuote = quoteToType
        withAnimation {
            authorIsBold = true
        }
    }

    func loadNextPuzzle() {
        if appSettings.isRandomThemeEnabled {
            appSettings.applyRandomTheme()
        }
        withAnimation(.easeOut(duration: 0.3)) {
            showCompletionView = false
        }
        viewModel.refreshPuzzleWithCurrentSettings()
    }

    func goHome() {
        navigationCoordinator.navigateToHome()
    }

    func goToCalendar() {
        appSettings.shouldShowCalendarOnReturn = true
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
