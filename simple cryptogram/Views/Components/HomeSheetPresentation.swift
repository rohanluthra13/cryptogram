//
//  HomeSheetPresentation.swift
//  simple cryptogram
//
//  Created on 29/05/2025.
//

import SwiftUI

/// A view modifier that handles sheet presentations for HomeView
struct HomeSheetPresentation: ViewModifier {
    @EnvironmentObject private var navigationCoordinator: NavigationCoordinator
    @EnvironmentObject private var viewModel: PuzzleViewModel
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(AppSettings.self) private var appSettings
    @Binding var puzzleOpenedFromCalendar: Bool
    
    func body(content: Content) -> some View {
        content
            .sheet(item: Binding(
                get: { FeatureFlag.modernSheets.isEnabled ? navigationCoordinator.activeSheet : nil },
                set: { _ in navigationCoordinator.dismissSheet() }
            )) { sheetType in
                sheetContent(for: sheetType)
            }
    }
    
    @ViewBuilder
    private func sheetContent(for sheetType: NavigationCoordinator.SheetType) -> some View {
        switch sheetType {
        case .settings:
            StandardSheet(title: "Settings", dismissAction: {
                navigationCoordinator.dismissSheet()
            }) {
                SettingsContentView()
                    .environmentObject(viewModel)
                    .environmentObject(themeManager)
            }
        case .statistics:
            StandardSheet(title: "Statistics", dismissAction: {
                navigationCoordinator.dismissSheet()
            }) {
                UserStatsView(viewModel: viewModel)
            }
        case .calendar:
            StandardSheet(title: "Calendar", dismissAction: {
                navigationCoordinator.dismissSheet()
            }) {
                ContinuousCalendarView(
                    showCalendar: Binding(
                        get: { navigationCoordinator.activeSheet == .calendar },
                        set: { _ in navigationCoordinator.dismissSheet() }
                    ),
                    onSelectDate: { date in
                        viewModel.loadDailyPuzzle(for: date)
                        puzzleOpenedFromCalendar = true
                        navigationCoordinator.dismissSheet()
                        if let puzzle = viewModel.currentPuzzle {
                            navigationCoordinator.navigateToPuzzle(puzzle, difficulty: nil)
                        }
                    }
                )
                .environmentObject(viewModel)
                .environment(appSettings)
            }
        case .info:
            CompactSheet(title: "About", dismissAction: {
                navigationCoordinator.dismissSheet()
            }, detents: [.medium, .large]) {
                ScrollView {
                    InfoOverlayView()
                        .padding()
                }
            }
        case .authorInfo(let author):
            CompactSheet(title: "Author Info", dismissAction: {
                navigationCoordinator.dismissSheet()
            }, detents: [.medium]) {
                AuthorInfoView(author: author)
                    .padding()
            }
        }
    }
}

extension View {
    func homeSheetPresentation(puzzleOpenedFromCalendar: Binding<Bool>) -> some View {
        self.modifier(HomeSheetPresentation(puzzleOpenedFromCalendar: puzzleOpenedFromCalendar))
    }
}