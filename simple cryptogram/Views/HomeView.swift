import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var viewModel: PuzzleViewModel
    @EnvironmentObject private var appSettings: AppSettings
    @EnvironmentObject private var themeManager: ThemeManager
    @State private var showSettings = false
    @State private var showStats = false
    @State private var navigateToPuzzle = false
    @State private var selectedMode: PuzzleMode = .random
    
    enum PuzzleMode {
        case random
        case daily
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                CryptogramTheme.Colors.background
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Main content
                    VStack(spacing: 20) {
                        // Main buttons
                        VStack(spacing: 12) {
                            modeButton(.random, title: "Play")
                            modeButton(.daily, title: "Daily Puzzle")
                        }
                        .padding(.horizontal, 40)
                        .padding(.top, 100)
                        
                        // Settings box
                        VStack(spacing: 15) {
                            // Difficulty toggle
                            ToggleOptionRow(
                                leftOption: (DifficultyMode.normal, DifficultyMode.normal.displayName.lowercased()),
                                rightOption: (DifficultyMode.expert, DifficultyMode.expert.displayName.lowercased()),
                                selection: Binding(
                                    get: { appSettings.difficultyMode },
                                    set: { appSettings.difficultyMode = $0 }
                                )
                            )
                            
                            // Quote length checkboxes
                            HStack(spacing: 4) {
                                MultiCheckboxRow(
                                    title: "short",
                                    isSelected: appSettings.selectedDifficulties.contains("easy"),
                                    action: { toggleLength("easy") }
                                )
                                MultiCheckboxRow(
                                    title: "medium",
                                    isSelected: appSettings.selectedDifficulties.contains("medium"),
                                    action: { toggleLength("medium") }
                                )
                                MultiCheckboxRow(
                                    title: "long",
                                    isSelected: appSettings.selectedDifficulties.contains("hard"),
                                    action: { toggleLength("hard") }
                                )
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(CryptogramTheme.Colors.border.opacity(0.3), lineWidth: 1)
                        )
                        .padding(.horizontal, 40)
                        .padding(.top, 20)
                        
                        Spacer()
                    }
                    
                    // Bottom bar
                    HStack {
                        // Stats button
                        Button(action: {
                            showStats.toggle()
                        }) {
                            Image(systemName: "chart.bar")
                                .font(.system(size: PuzzleViewConstants.Sizes.statsIconSize))
                                .foregroundColor(CryptogramTheme.Colors.text)
                                .opacity(PuzzleViewConstants.Colors.iconOpacity)
                                .frame(width: PuzzleViewConstants.Sizes.iconButtonFrame, height: PuzzleViewConstants.Sizes.iconButtonFrame)
                        }
                        
                        Spacer()
                        
                        // Settings button
                        Button(action: {
                            showSettings.toggle()
                        }) {
                            Image(systemName: "gearshape")
                                .font(.system(size: PuzzleViewConstants.Sizes.settingsIconSize))
                                .foregroundColor(CryptogramTheme.Colors.text)
                                .opacity(PuzzleViewConstants.Colors.iconOpacity)
                                .frame(width: PuzzleViewConstants.Sizes.iconButtonFrame, height: PuzzleViewConstants.Sizes.iconButtonFrame)
                        }
                    }
                    .frame(height: PuzzleViewConstants.Spacing.bottomBarHeight)
                    .padding(.horizontal, PuzzleViewConstants.Spacing.bottomBarHorizontalPadding)
                }
                
                // Settings overlay
                if showSettings {
                    CryptogramTheme.Colors.surface
                        .opacity(0.95)
                        .edgesIgnoringSafeArea(.all)
                        .onTapGesture {
                            showSettings = false
                        }
                        .overlay(
                            SettingsContentView()
                                .padding(.horizontal, PuzzleViewConstants.Overlay.overlayHorizontalPadding)
                                .padding(.vertical, 20)
                                .environmentObject(viewModel)
                                .environmentObject(themeManager)
                        )
                        .zIndex(OverlayZIndex.statsSettings)
                }
                
                // Stats overlay
                if showStats {
                    CryptogramTheme.Colors.surface
                        .opacity(0.95)
                        .ignoresSafeArea()
                        .onTapGesture { showStats = false }
                        .overlay(
                            VStack(spacing: 0) {
                                Spacer(minLength: 0)
                                UserStatsView(viewModel: viewModel)
                                    .padding(.top, 24)
                            }
                        )
                        .transition(.opacity)
                        .animation(.easeInOut(duration: PuzzleViewConstants.Animation.overlayDuration), value: showStats)
                        .zIndex(OverlayZIndex.statsSettings)
                }
            }
            .navigationDestination(isPresented: $navigateToPuzzle) {
                PuzzleView()
                    .navigationBarHidden(true)
            }
        }
    }
    
    private func modeButton(_ mode: PuzzleMode, title: String) -> some View {
        Button(action: {
            selectMode(mode)
        }) {
            Text(title)
                .font(.footnote)
                .foregroundColor(CryptogramTheme.Colors.text)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func toggleLength(_ difficulty: String) {
        var newSelection = appSettings.selectedDifficulties
        if newSelection.contains(difficulty) {
            newSelection.removeAll { $0 == difficulty }
        } else {
            newSelection.append(difficulty)
        }
        
        // Ensure at least one difficulty is selected
        if !newSelection.isEmpty {
            appSettings.selectedDifficulties = newSelection
        }
    }
    
    private func selectMode(_ mode: PuzzleMode) {
        selectedMode = mode
        
        // Update difficulty settings based on mode
        switch mode {
        case .random:
            // Keep current selected difficulties
            if appSettings.selectedDifficulties.isEmpty {
                appSettings.selectedDifficulties = ["easy", "medium", "hard"]
            }
        case .daily:
            viewModel.loadDailyPuzzle()
            navigateToPuzzle = true
            return
        }
        
        // Load new puzzle and navigate
        viewModel.loadNewPuzzle()
        navigateToPuzzle = true
    }
}

#Preview {
    HomeView()
        .environmentObject(PuzzleViewModel())
        .environmentObject(AppSettings())
        .environmentObject(ThemeManager())
}