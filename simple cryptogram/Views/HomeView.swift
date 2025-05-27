import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var viewModel: PuzzleViewModel
    @EnvironmentObject private var appSettings: AppSettings
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.typography) private var typography
    @State private var showSettings = false
    @State private var showStats = false
    @State private var navigateToPuzzle = false
    @State private var selectedMode: PuzzleMode = .random
    @State private var showLengthSelection = false
    @State private var isBottomBarVisible = true
    @State private var bottomBarHideWorkItem: DispatchWorkItem?
    @State private var showCalendar = false
    
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
                        Spacer()
                        Spacer()
                        Spacer() // Additional spacer to push content lower
                        
                        // Main buttons positioned in bottom third
                        if !showLengthSelection {
                            VStack(spacing: 50) {
                                playButton
                                
                                dailyPuzzleButton
                            }
                            .transition(.opacity.combined(with: .scale))
                        } else {
                            // Length selection
                            VStack(spacing: 20) {
                                randomButton
                                
                                Text("or select length")
                                    .font(typography.footnote)
                                    .italic()
                                    .foregroundColor(CryptogramTheme.Colors.text.opacity(0.7))
                                    .padding(.vertical, 4)
                                
                                HStack(spacing: 30) {
                                    lengthButton("short", difficulty: "easy")
                                    lengthButton("medium", difficulty: "medium")
                                    lengthButton("long", difficulty: "hard")
                                }
                            }
                            .transition(.opacity.combined(with: .scale))
                        }
                        
                        Spacer()
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if showLengthSelection {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                showLengthSelection = false
                            }
                        }
                    }
                    
                    // Bottom bar
                    ZStack {
                        // Visible bottom bar with icons
                        if isBottomBarVisible || showSettings || showStats {
                            HStack {
                                // Stats button
                                Button(action: {
                                    showStats.toggle()
                                    showBottomBarTemporarily()
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
                                    showBottomBarTemporarily()
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
                            .transition(.opacity)
                        }
                        
                        // Invisible tap area to bring back bottom bar
                        if !isBottomBarVisible && !showSettings && !showStats {
                            Rectangle()
                                .fill(Color.clear)
                                .frame(height: PuzzleViewConstants.Spacing.bottomBarHeight)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    showBottomBarTemporarily()
                                }
                        }
                    }
                    .frame(height: PuzzleViewConstants.Spacing.bottomBarHeight)
                }
                
                // Settings overlay
                if showSettings {
                    ZStack {
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
                                    .background(Color.clear)
                                    .contentShape(Rectangle())
                                    .onTapGesture {}  // Empty gesture to prevent tap-through
                                    .environmentObject(viewModel)
                                    .environmentObject(themeManager)
                            )
                        
                        // X button positioned at screen level
                        VStack {
                            HStack {
                                Spacer()
                                Button(action: { showSettings = false }) {
                                    Image(systemName: "xmark")
                                        .font(.system(size: 10, weight: .medium))
                                        .foregroundColor(CryptogramTheme.Colors.text.opacity(0.6))
                                        .frame(width: 22, height: 22)
                                }
                                .padding(.top, 50)
                                .padding(.trailing, 20)
                            }
                            Spacer()
                        }
                    }
                    .zIndex(OverlayZIndex.statsSettings)
                }
                
                // Stats overlay
                if showStats {
                    ZStack {
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
                        
                        // X button positioned at screen level
                        VStack {
                            HStack {
                                Spacer()
                                Button(action: { showStats = false }) {
                                    Image(systemName: "xmark")
                                        .font(.system(size: 10, weight: .medium))
                                        .foregroundColor(CryptogramTheme.Colors.text.opacity(0.6))
                                        .frame(width: 22, height: 22)
                                }
                                .padding(.top, 50)
                                .padding(.trailing, 20)
                            }
                            Spacer()
                        }
                    }
                    .transition(.opacity)
                    .animation(.easeInOut(duration: PuzzleViewConstants.Animation.overlayDuration), value: showStats)
                    .zIndex(OverlayZIndex.statsSettings)
                }
                
                // Calendar overlay
                if showCalendar {
                    ZStack {
                        CryptogramTheme.Colors.surface
                            .opacity(0.95)
                            .ignoresSafeArea()
                            .onTapGesture { showCalendar = false }
                            .overlay(
                                CalendarView(
                                    showCalendar: $showCalendar,
                                    onSelectDate: { date in
                                        viewModel.loadDailyPuzzle(for: date)
                                        navigateToPuzzle = true
                                    }
                                )
                                .environmentObject(viewModel)
                                .environmentObject(appSettings)
                            )
                        
                        // X button positioned at screen level
                        VStack {
                            HStack {
                                Spacer()
                                Button(action: { showCalendar = false }) {
                                    Image(systemName: "xmark")
                                        .font(.system(size: 10, weight: .medium))
                                        .foregroundColor(CryptogramTheme.Colors.text.opacity(0.6))
                                        .frame(width: 22, height: 22)
                                }
                                .padding(.top, 50)
                                .padding(.trailing, 20)
                            }
                            Spacer()
                        }
                    }
                    .transition(.opacity)
                    .animation(.easeInOut(duration: PuzzleViewConstants.Animation.overlayDuration), value: showCalendar)
                    .zIndex(OverlayZIndex.statsSettings)
                }
            }
            .navigationDestination(isPresented: $navigateToPuzzle) {
                PuzzleView()
                    .navigationBarHidden(true)
            }
            .onAppear {
                showBottomBarTemporarily()
                // Reset to initial state when returning to HomeView
                showLengthSelection = false
            }
        }
    }
    
    private var playButton: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
                showLengthSelection = true
            }
        }) {
            Text("play")
                .font(typography.body)
                .foregroundColor(CryptogramTheme.Colors.text)
                .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var dailyPuzzleButton: some View {
        VStack(spacing: 12) {
            Button(action: {
                selectMode(.daily)
            }) {
                Text("daily puzzle")
                    .font(typography.body)
                    .foregroundColor(CryptogramTheme.Colors.text)
                    .padding(.vertical, 8)
            }
            .buttonStyle(PlainButtonStyle())
            
            Button(action: {
                showCalendar = true
            }) {
                Image(systemName: "calendar")
                    .font(.system(size: 24))
                    .foregroundColor(CryptogramTheme.Colors.text.opacity(0.8))
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    private var randomButton: some View {
        Button(action: {
            appSettings.selectedDifficulties = ["easy", "medium", "hard"]
            selectMode(.random)
        }) {
            HStack(spacing: 4) {
                Text("just play")
                    .font(typography.body)
                    .foregroundColor(CryptogramTheme.Colors.text)
                Image(systemName: "dice")
                    .font(typography.caption)
                    .foregroundColor(CryptogramTheme.Colors.text)
                    .rotationEffect(.degrees(30))
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func lengthButton(_ title: String, difficulty: String) -> some View {
        Button(action: {
            appSettings.selectedDifficulties = [difficulty]
            selectMode(.random)
        }) {
            Text(title)
                .font(typography.body)
                .foregroundColor(CryptogramTheme.Colors.text)
                .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
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
    
    private func showBottomBarTemporarily() {
        withAnimation {
            isBottomBarVisible = true
        }
        bottomBarHideWorkItem?.cancel()
        
        let workItem = DispatchWorkItem {
            withAnimation {
                self.isBottomBarVisible = false
            }
        }
        bottomBarHideWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + PuzzleViewConstants.Animation.bottomBarAutoHideDelay, execute: workItem)
    }
}

#Preview {
    HomeView()
        .environmentObject(PuzzleViewModel())
        .environmentObject(AppSettings())
        .environmentObject(ThemeManager())
}
