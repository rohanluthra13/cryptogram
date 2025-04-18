import SwiftUI
import Combine

struct PuzzleView: View {
    @EnvironmentObject private var viewModel: PuzzleViewModel
    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject private var settingsViewModel: SettingsViewModel
    @State private var showSettings = false
    @State private var showCompletionView = false
    @State private var showStatsOverlay = false
    @Namespace private var statsOverlayNamespace
    @AppStorage("isDarkMode") private var isDarkMode = false
    
    // Create a custom binding for the layout
    private var layoutBinding: Binding<NavigationBarLayout> {
        Binding(
            get: { UserSettings.navigationBarLayout },
            set: { UserSettings.navigationBarLayout = $0 }
        )
    }
    
    var body: some View {
        ZStack {
            // --- Persistent Top Bar (always visible) ---
            VStack {
                HStack(alignment: .top) {
                    // Left column: Mistakes above Hints
                    VStack(alignment: .leading, spacing: 4) {
                        MistakesView(mistakeCount: viewModel.mistakeCount)
                        HintsView(
                            hintCount: viewModel.hintCount,
                            onRequestHint: { viewModel.revealCell() },
                            maxHints: viewModel.nonSymbolCells.count / 4
                        )
                    }
                    .padding(.leading, 16)
                    .padding(.top, 8)

                    Spacer()

                    // Right column: Settings above Stats
                    VStack(alignment: .trailing, spacing: 2) {
                        Button(action: {
                            withAnimation {
                                if showStatsOverlay {
                                    showStatsOverlay = false
                                    showSettings = true
                                } else {
                                    showSettings.toggle()
                                }
                            }
                        }) {
                            Image(systemName: "gearshape")
                                .font(.title3)
                                .foregroundColor(CryptogramTheme.Colors.text)
                                .frame(width: 44, height: 44)
                                .accessibilityLabel("Settings")
                        }
                        Button(action: {
                            withAnimation {
                                if showSettings {
                                    showSettings = false
                                    showStatsOverlay = true
                                } else {
                                    showStatsOverlay.toggle()
                                }
                            }
                        }) {
                            Image(systemName: "chart.bar")
                                .font(.system(size: 17)) // 0.9x of .title3 (19)
                                .foregroundColor(CryptogramTheme.Colors.text)
                                .frame(width: 44, height: 44)
                                .accessibilityLabel("Puzzle Stats")
                        }
                    }
                    .padding(.trailing, 16)
                    .padding(.top, 2)
                }
                .padding(.top, 8)
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .zIndex(100)

            // --- Main Content ---
            if viewModel.currentPuzzle != nil {
                VStack(spacing: 0) {
                    // Timer moved to top bar, no longer needed here
                    // Puzzle Grid in ScrollView with flexible height
                    ScrollView {
                        WordAwarePuzzleGrid()
                            .environmentObject(viewModel)
                            .padding(.horizontal, 16)
                    }
                    .layoutPriority(1)
                    .frame(maxWidth: .infinity)
                    .frame(maxHeight: UIScreen.main.bounds.height * 0.45)
                    .padding(.horizontal, 12)
                    .padding(.top, 40) // Increased top padding to account for hints/mistakes views
                    .padding(.bottom, 12)

                    // Fixed height spacer (modern approach - non-collapsible)
                    Rectangle()
                        .fill(Color.clear)
                        .frame(height: 20) // Adjust this value to control spacing precisely
                        .allowsHitTesting(false) // Ensures touches pass through

                    // Navigation Bar with all controls in a single layer
                    NavigationBarView(
                        onMoveLeft: { viewModel.moveToAdjacentCell(direction: -1) },
                        onMoveRight: { viewModel.moveToAdjacentCell(direction: 1) },
                        onTogglePause: viewModel.togglePause,
                        onNextPuzzle: { viewModel.refreshPuzzleWithCurrentSettings() },
                        onTryAgain: { 
                            viewModel.reset()
                            // Re-apply difficulty settings to the same puzzle
                            if let currentPuzzle = viewModel.currentPuzzle {
                                viewModel.startNewPuzzle(puzzle: currentPuzzle)
                            }
                        },
                        isPaused: viewModel.isPaused,
                        isFailed: viewModel.isFailed,
                        showCenterButtons: true, // Show all buttons in the nav bar
                        layout: layoutBinding
                    )
                    // Keyboard View - fixed at bottom
                    KeyboardView(
                        onLetterPress: { letter in
                            if let index = viewModel.selectedCellIndex {
                                viewModel.inputLetter(String(letter), at: index)
                            }
                        },
                        onBackspacePress: { 
                            if let index = viewModel.selectedCellIndex {
                                viewModel.handleDelete(at: index)
                            }
                        },
                        completedLetters: viewModel.completedLetters
                    )
                    .padding(.bottom, 4)
                    .padding(.horizontal, 4)
                    .frame(maxWidth: .infinity)
                    .disabled(viewModel.isPaused || viewModel.isComplete) // Disable keyboard when game is paused or complete
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(CryptogramTheme.Colors.background)
                .opacity(showCompletionView ? 0 : 1)
                .zIndex(10)
                .overlay(
                    // Overlay for paused state (not completion which is handled separately)
                    Group {
                        if viewModel.isPaused && !showSettings {
                            ZStack {
                                // Semi-transparent overlay that allows clicks to pass through to navigation bar
                                Color.black.opacity(0.5)
                                    .edgesIgnoringSafeArea(.all)
                                    .allowsHitTesting(false)  // This lets clicks pass through
                                // Pause text
                                Button(action: { viewModel.togglePause() }) {
                                    Text("paused")
                                        .font(.headline)
                                        .foregroundColor(CryptogramTheme.Colors.text)
                                }
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                                .padding(.bottom, 265)
                            }
                        } else if viewModel.isFailed && !showSettings {
                            ZStack {
                                // Semi-transparent overlay for game over
                                Color.black.opacity(0.5)
                                    .edgesIgnoringSafeArea(.all)
                                    .allowsHitTesting(false)  // This lets clicks pass through to navigation bar
                                // Game over text - without dedicated icon
                                Text("game over")
                                    .font(.headline)
                                    .foregroundColor(CryptogramTheme.Colors.text)
                                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                                    .padding(.bottom, 265)
                            }
                        } else if showSettings {
                            // Full-screen settings overlay
                            ZStack {
                                // Background that covers the entire screen and can be tapped to dismiss
                                CryptogramTheme.Colors.surface
                                    .opacity(0.95) // Same opacity for both modes
                                    .edgesIgnoringSafeArea(.all)
                                    .onTapGesture {
                                        print("Tapped background, closing settings")
                                        showSettings = false
                                    }
                                    .zIndex(10) // Ensure overlay is above other elements
                                // Settings content centered on the overlay
                                SettingsContentView()
                                    .padding(.horizontal, 24)
                                    .padding(.vertical, 20)
                                    .contentShape(Rectangle()) // Prevent dismissal when tapping content
                                    .onTapGesture { 
                                        print("Tapped settings content")
                                    }
                                    .environmentObject(viewModel)
                                    .environmentObject(themeManager)
                                    .environmentObject(settingsViewModel)
                                    .zIndex(11) // Above the background
                            }
                            .zIndex(50) // Below top bar
                        }
                    }
                )
            } else {
                LoadingView(message: "Loading your puzzle...")
            }
            // Completion overlay - conditionally shown
            if showCompletionView {
                PuzzleCompletionView(showCompletionView: $showCompletionView)
                    .environmentObject(themeManager)
                    .environmentObject(viewModel)
            }
            // --- Stats Overlay (custom ZStack, slides from top) ---
            if showStatsOverlay {
                ZStack(alignment: .top) {
                    CryptogramTheme.Colors.background
                        .ignoresSafeArea()
                        .opacity(0.98)
                        .onTapGesture { showStatsOverlay = false }
                    VStack(spacing: 0) {
                        Spacer(minLength: 0)
                        UserStatsView(viewModel: viewModel)
                            .padding(.top, 24)
                    }
                }
                .matchedGeometryEffect(id: "statsOverlay", in: statsOverlayNamespace)
                .transition(.opacity)
                .zIndex(50) // Below top bar
                .animation(.easeInOut(duration: 0.3), value: showStatsOverlay)
            }
        }
        .onChange(of: viewModel.isComplete) { oldValue, isComplete in
            if isComplete {
                // Add haptic feedback for completion
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
                
                // First trigger wiggle animation
                viewModel.triggerCompletionWiggle()
                
                // Then transition to completion view with a slight delay
                withAnimation(.easeOut(duration: 0.5).delay(0.7)) {
                    showCompletionView = true
                }
            }
        }
        .navigationBarHidden(true)
    }
    
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

#Preview {
    NavigationView {
        PuzzleView()
            .environmentObject(PuzzleViewModel())
            .environmentObject(ThemeManager())
            .environmentObject(SettingsViewModel())
    }
}
