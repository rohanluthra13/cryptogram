import SwiftUI

struct GameOverOverlay: View {
    @Environment(PuzzleViewModel.self) private var viewModel
    @Environment(NavigationCoordinator.self) private var navigationCoordinator
    @Environment(\.typography) private var typography

    @Binding var showSettings: Bool
    @Binding var showStats: Bool
    @Binding var showInfoOverlay: Bool

    // Game over typing animation state
    @State private var gameOverTypedText = ""
    @State private var showGameOverButtons = false
    @State private var currentGameOverMessage = ""
    @State private var gameOverTypingTimer: Timer?
    @State private var showContinueFriction = false
    @State private var frictionTypedText = ""
    @State private var frictionTypingTimer: Timer?

    // Bottom bar auto-hide
    @State private var isBottomBarVisible = false
    @State private var bottomBarHideTask: Task<Void, Never>?

    private let gameOverMessages = [
        "uh oh that's 3 mistakes.",
        "oh no game over.",
        "sucks to suck huh.",
        "oops you made a whoopsie.",
        "third strike, you're out!",
        "better luck next time.",
        "so close yet so far.",
        "practice makes perfect."
    ]

    var body: some View {
        ZStack {
            CryptogramTheme.Colors.background
                .ignoresSafeArea()
                .opacity(0.98)
                .onTapGesture { }

            // Info button in top-right corner
            VStack {
                HStack {
                    Spacer()
                    Button(action: {
                        withAnimation {
                            showInfoOverlay.toggle()
                        }
                    }) {
                        Image(systemName: "questionmark")
                            .font(.system(size: PuzzleViewConstants.Sizes.questionMarkSize, design: typography.fontOption.design))
                            .foregroundColor(CryptogramTheme.Colors.text)
                            .opacity(showInfoOverlay ? PuzzleViewConstants.Colors.activeIconOpacity : PuzzleViewConstants.Colors.iconOpacity)
                            .frame(width: PuzzleViewConstants.Sizes.iconButtonFrame, height: PuzzleViewConstants.Sizes.iconButtonFrame)
                            .accessibilityLabel("About / Info")
                    }
                    .padding(.trailing, PuzzleViewConstants.Spacing.topBarPadding)
                }
                Spacer()
            }
            .padding(.top, 0)

            VStack(spacing: 48) {
                Spacer()

                Text(gameOverTypedText)
                    .font(typography.body)
                    .foregroundColor(CryptogramTheme.Colors.text)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 12)

                // Button container - always present to maintain layout
                VStack(spacing: 32) {
                    if showGameOverButtons && !showContinueFriction {
                        Button(action: { startContinueFriction() }) {
                            Text("continue")
                                .font(typography.caption)
                                .foregroundColor(CryptogramTheme.Colors.text)
                        }
                        .transition(.opacity)

                        Button(action: { viewModel.refreshPuzzleWithCurrentSettings() }) {
                            Text("new puzzle")
                                .font(typography.caption)
                                .foregroundColor(CryptogramTheme.Colors.text)
                        }
                        .transition(.opacity)

                        Button(action: {
                            viewModel.reset()
                            if let currentPuzzle = viewModel.currentPuzzle {
                                viewModel.startNewPuzzle(puzzle: currentPuzzle)
                            }
                        }) {
                            Text("try again")
                                .font(typography.caption)
                                .foregroundColor(CryptogramTheme.Colors.text)
                        }
                        .transition(.opacity)
                    } else if showContinueFriction {
                        Text(frictionTypedText)
                            .font(typography.caption)
                            .foregroundColor(CryptogramTheme.Colors.text)
                            .padding(.horizontal, 32)
                            .multilineTextAlignment(.center)
                            .transition(.opacity)

                        Text("new puzzle").font(typography.caption).foregroundColor(.clear)
                        Text("try again").font(typography.caption).foregroundColor(.clear)
                    } else {
                        Text("continue").font(typography.caption).foregroundColor(.clear)
                        Text("new puzzle").font(typography.caption).foregroundColor(.clear)
                        Text("try again").font(typography.caption).foregroundColor(.clear)
                    }
                }
                .padding(.bottom, 180)
                .animation(.easeIn(duration: 0.3), value: showGameOverButtons)
                .animation(.easeIn(duration: 0.3), value: showContinueFriction)
            }

            // Bottom bar
            if showGameOverButtons && !showContinueFriction {
                if isBottomBarVisible {
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
                                navigationCoordinator.navigationPath = NavigationPath()
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
                        .onTapGesture { showBottomBarTemporarily() }
                    }
                    .transition(.opacity)
                    .animation(.easeInOut(duration: PuzzleViewConstants.Animation.overlayDuration), value: isBottomBarVisible)
                } else {
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
                }
            }
        }
        .transition(.opacity)
        .animation(.easeInOut(duration: PuzzleViewConstants.Animation.overlayDuration), value: viewModel.isFailed)
        .onAppear { startGameOverTyping() }
        .onDisappear { resetGameOverAnimation() }
    }

    // MARK: - Bottom Bar

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

    // MARK: - Game Over Animation

    private func startGameOverTyping() {
        gameOverTypedText = ""
        showGameOverButtons = false
        currentGameOverMessage = gameOverMessages.randomElement() ?? "game over"

        Task {
            try? await Task.sleep(for: .seconds(0.7))
            guard !Task.isCancelled else { return }
            typeGameOverMessage()
        }
    }

    private func typeGameOverMessage() {
        gameOverTypingTimer?.invalidate()
        let characters = Array(currentGameOverMessage)
        var currentIndex = 0

        gameOverTypingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            if currentIndex < characters.count {
                gameOverTypedText.append(characters[currentIndex])
                currentIndex += 1
            } else {
                timer.invalidate()
                withAnimation { showGameOverButtons = true }
                Task { @MainActor in showBottomBarTemporarily() }
            }
        }
    }

    private func resetGameOverAnimation() {
        gameOverTypingTimer?.invalidate()
        frictionTypingTimer?.invalidate()
        gameOverTypedText = ""
        showGameOverButtons = false
        currentGameOverMessage = ""
        showContinueFriction = false
        frictionTypedText = ""
    }

    private func startContinueFriction() {
        withAnimation {
            showGameOverButtons = false
            showContinueFriction = true
        }
        frictionTypedText = ""

        Task {
            try? await Task.sleep(for: .seconds(0.3))
            guard !Task.isCancelled else { return }
            typeFrictionMessage()
        }
    }

    private func typeFrictionMessage() {
        frictionTypingTimer?.invalidate()
        let message = "since there are no ads this is a bit of friction cause, well, you did make 3 mistakes..."
        let characters = Array(message)
        var currentIndex = 0

        frictionTypingTimer = Timer.scheduledTimer(withTimeInterval: 0.08, repeats: true) { timer in
            if currentIndex < characters.count {
                frictionTypedText.append(characters[currentIndex])
                currentIndex += 1
            } else {
                timer.invalidate()
                Task { @MainActor in
                    try? await Task.sleep(for: .seconds(1.0))
                    guard !Task.isCancelled else { return }
                    viewModel.continueAfterFailure()
                }
            }
        }
    }
}
