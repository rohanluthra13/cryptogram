import SwiftUI
import Combine

struct PuzzleView: View {
    @EnvironmentObject private var viewModel: PuzzleViewModel
    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject private var settingsViewModel: SettingsViewModel
    @State private var showSettings = false
    @State private var showCompletionView = false
    @State private var showStatsView = false
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
                            .zIndex(100) // Ensure settings overlay is above everything
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
            
            // Top bar with Settings, Timer, and Mistakes
            if !showCompletionView {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        // Mistakes view at top left with fixed width container
                        MistakesView(mistakeCount: viewModel.mistakeCount)
                            .padding(.leading, 16)
                            .padding(.top, 8)
                            .frame(width: 100, alignment: .leading) // Fixed width container
                        
                        Spacer()
                        
                        // Timer centered at top aligned with mistakes and settings
                        TimerView(startTime: viewModel.startTime ?? Date(), isPaused: viewModel.isPaused)
                            .opacity(viewModel.startTime == nil ? 0 : 1) // Hide if not started
                            .padding(.top, 8)
                        
                        Spacer()
                        
                        // Settings and Stats buttons with matching fixed width container
                        VStack(spacing: 2) {
                            Button(action: {
                                print("Settings button pressed, toggling showSettings to \(!showSettings)")
                                showSettings.toggle()
                            }) {
                                Image(systemName: "gearshape")
                                    .font(.title3)
                                    .foregroundColor(CryptogramTheme.Colors.text)
                                    .padding(.trailing, 16)
                                    .padding(.top, 8)
                                    .accessibilityLabel("Settings")
                            }
                            .frame(width: 100, alignment: .trailing)
                            // --- Stats Icon ---
                            Button(action: {
                                showStatsView = true
                            }) {
                                Image(systemName: "chart.bar.xaxis")
                                    .font(.title3)
                                    .foregroundColor(.accentColor)
                                    .padding(.trailing, 16)
                                    .padding(.top, 2)
                                    .accessibilityLabel("Puzzle Stats")
                            }
                            .frame(width: 100, alignment: .trailing)
                        }
                    }
                    
                    // Hints view under the mistakes
                    HintsView(
                        hintCount: viewModel.hintCount,
                        onRequestHint: { viewModel.revealCell() },
                        maxHints: viewModel.nonSymbolCells.count / 4 // Use approximately 1/4 of the cells as max hints
                    )
                    .padding(.horizontal, 16)
                    
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .zIndex(2) // Ensure top bar is above other layers
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
        .sheet(isPresented: $showStatsView) {
            UserStatsView(viewModel: viewModel)
                .presentationDetents([.medium, .large])
        }
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
