//
//  HomeMainContent.swift
//  simple cryptogram
//
//  Created on 29/05/2025.
//

import SwiftUI

/// The main content area of HomeView containing game selection buttons
struct HomeMainContent: View {
    @EnvironmentObject private var viewModel: PuzzleViewModel
    @Environment(AppSettings.self) private var appSettings
    @EnvironmentObject private var navigationCoordinator: NavigationCoordinator
    @Environment(\.typography) private var typography
    
    @Binding var showLengthSelection: Bool
    @Binding var selectedMode: HomeView.PuzzleMode
    @Binding var showCalendar: Bool

    var isDailyPuzzleCompleted: Bool
    
    var body: some View {
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
        VStack(spacing: 36) {
            Button(action: {
                selectMode(.daily)
            }) {
                HStack(spacing: 8) {
                    Text("daily puzzle")
                        .font(typography.body)
                        .foregroundColor(CryptogramTheme.Colors.text)
                        .padding(.vertical, 8)
                    
                    if isDailyPuzzleCompleted {
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Color(hex: "#01780F").opacity(0.5))
                    }
                }
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
    
    private func selectMode(_ mode: HomeView.PuzzleMode) {
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
            if let puzzle = viewModel.currentPuzzle {
                navigationCoordinator.navigateToPuzzle(puzzle)
            }
            return
        }
        
        // Load new puzzle and navigate
        viewModel.loadNewPuzzle()
        if let puzzle = viewModel.currentPuzzle {
            navigationCoordinator.navigateToPuzzle(puzzle)
        }
    }
}