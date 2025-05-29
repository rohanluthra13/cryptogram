//
//  HomeLegacyOverlays.swift
//  simple cryptogram
//
//  Created on 29/05/2025.
//

import SwiftUI

/// A view that contains all legacy overlay presentations for HomeView
struct HomeLegacyOverlays: View {
    @EnvironmentObject private var viewModel: PuzzleViewModel
    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject private var navigationCoordinator: NavigationCoordinator
    @Environment(AppSettings.self) private var appSettings
    @Environment(\.typography) private var typography
    
    @Binding var showSettings: Bool
    @Binding var showStats: Bool
    @Binding var showCalendar: Bool
    @Binding var showInfoOverlay: Bool
    @Binding var puzzleOpenedFromCalendar: Bool
    
    var body: some View {
        ZStack {
            settingsOverlay
            statsOverlay
            infoOverlay
            calendarOverlay
        }
    }
    
    @ViewBuilder
    private var settingsOverlay: some View {
        if showSettings && !FeatureFlag.modernSheets.isEnabled {
            ZStack {
                CryptogramTheme.Colors.surface
                    .opacity(0.98)
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
                            .onTapGesture {}
                            .environmentObject(viewModel)
                            .environmentObject(themeManager)
                    )
                
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
    }
    
    @ViewBuilder
    private var statsOverlay: some View {
        if showStats && !FeatureFlag.modernSheets.isEnabled {
            ZStack {
                CryptogramTheme.Colors.surface
                    .opacity(0.98)
                    .ignoresSafeArea()
                    .onTapGesture { showStats = false }
                    .overlay(
                        VStack(spacing: 0) {
                            Spacer(minLength: 0)
                            UserStatsView(viewModel: viewModel)
                                .padding(.top, 24)
                        }
                    )
                
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
    }
    
    @ViewBuilder
    private var infoOverlay: some View {
        if showInfoOverlay && !FeatureFlag.modernSheets.isEnabled {
            ZStack(alignment: .top) {
                CryptogramTheme.Colors.background
                    .ignoresSafeArea()
                    .opacity(PuzzleViewConstants.Overlay.backgroundOpacity)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation {
                            showInfoOverlay = false
                        }
                    }
                
                VStack {
                    Spacer(minLength: PuzzleViewConstants.Overlay.infoOverlayTopSpacing)
                    ScrollView {
                        InfoOverlayView()
                    }
                    .padding(.horizontal, PuzzleViewConstants.Overlay.overlayHorizontalPadding)
                    Spacer()
                }
                
                VStack {
                    HStack {
                        Spacer()
                        Button(action: { showInfoOverlay = false }) {
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
            .animation(.easeInOut(duration: PuzzleViewConstants.Animation.overlayDuration), value: showInfoOverlay)
            .zIndex(OverlayZIndex.info)
        }
    }
    
    @ViewBuilder
    private var calendarOverlay: some View {
        if showCalendar && !FeatureFlag.modernSheets.isEnabled {
            ZStack {
                CryptogramTheme.Colors.surface
                    .opacity(0.98)
                    .ignoresSafeArea()
                    .onTapGesture { showCalendar = false }
                    .overlay(
                        ContinuousCalendarView(
                            showCalendar: $showCalendar,
                            onSelectDate: { date in
                                viewModel.loadDailyPuzzle(for: date)
                                puzzleOpenedFromCalendar = true
                                if FeatureFlag.newNavigation.isEnabled {
                                    if let puzzle = viewModel.currentPuzzle {
                                        navigationCoordinator.navigateToPuzzle(puzzle, difficulty: nil)
                                    }
                                } else {
                                    NotificationCenter.default.post(name: .navigateToPuzzleFromCalendar, object: nil)
                                    // Don't hide calendar - keep it open in background
                                }
                            }
                        )
                        .environmentObject(viewModel)
                        .environment(appSettings)
                    )
                
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
}