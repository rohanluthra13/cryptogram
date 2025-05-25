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
        case short
        case medium
        case long
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
                    VStack(spacing: 30) {
                        // Header
                        Text("Select mode to play")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(CryptogramTheme.Colors.text)
                            .padding(.top, 50)
                        
                        // Puzzle mode options
                        VStack(spacing: 20) {
                            modeButton(.short, title: "Short")
                            modeButton(.medium, title: "Medium")
                            modeButton(.long, title: "Long")
                            
                            Divider()
                                .padding(.horizontal, 40)
                            
                            modeButton(.random, title: "Random")
                            modeButton(.daily, title: "Daily Puzzle")
                        }
                        .padding(.horizontal, 40)
                        
                        // Expert mode toggle
                        HStack {
                            Text("Expert Mode")
                                .foregroundColor(CryptogramTheme.Colors.text)
                            
                            Spacer()
                            
                            Toggle("", isOn: Binding(
                                get: { appSettings.difficultyMode == .expert },
                                set: { appSettings.difficultyMode = $0 ? .expert : .normal }
                            ))
                            .labelsHidden()
                        }
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
                                .font(.system(size: 22))
                                .foregroundColor(CryptogramTheme.Colors.text)
                                .opacity(0.8)
                                .frame(width: 44, height: 44)
                        }
                        
                        Spacer()
                        
                        // Settings button
                        Button(action: {
                            showSettings.toggle()
                        }) {
                            Image(systemName: "gearshape")
                                .font(.system(size: 22))
                                .foregroundColor(CryptogramTheme.Colors.text)
                                .opacity(0.8)
                                .frame(width: 44, height: 44)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(CryptogramTheme.Colors.surface)
                }
                
                // Settings overlay
                if showSettings {
                    ZStack {
                        // Background that dismisses overlay
                        Color.black.opacity(0.5)
                            .ignoresSafeArea()
                            .onTapGesture {
                                showSettings = false
                            }
                        
                        // Settings content
                        VStack {
                            Spacer()
                            SettingsContentView()
                                .background(CryptogramTheme.Colors.surface)
                                .cornerRadius(20)
                                .padding(.horizontal, 16)
                                .frame(maxHeight: UIScreen.main.bounds.height * 0.9)
                        }
                    }
                }
                
                // Stats overlay
                if showStats {
                    ZStack {
                        // Background that dismisses overlay
                        Color.black.opacity(0.5)
                            .ignoresSafeArea()
                            .onTapGesture {
                                showStats = false
                            }
                        
                        // Stats content
                        VStack {
                            Spacer()
                            UserStatsView(viewModel: viewModel)
                                .background(CryptogramTheme.Colors.surface)
                                .cornerRadius(20)
                                .padding(.horizontal, 16)
                                .frame(maxHeight: UIScreen.main.bounds.height * 0.9)
                        }
                    }
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
            HStack {
                Text(title)
                    .font(.title3)
                    .foregroundColor(CryptogramTheme.Colors.text)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(CryptogramTheme.Colors.text.opacity(0.5))
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 20)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(CryptogramTheme.Colors.surface)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func selectMode(_ mode: PuzzleMode) {
        selectedMode = mode
        
        // Update difficulty settings based on mode
        switch mode {
        case .short:
            appSettings.selectedDifficulties = ["easy"]
        case .medium:
            appSettings.selectedDifficulties = ["medium"]
        case .long:
            appSettings.selectedDifficulties = ["hard"]
        case .random:
            appSettings.selectedDifficulties = ["easy", "medium", "hard"]
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