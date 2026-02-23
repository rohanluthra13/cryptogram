import SwiftUI

struct ContentView: View {
    @Environment(PuzzleViewModel.self) private var viewModel
    @Environment(\.scenePhase) private var scenePhase
    @State private var showError = false
    @State private var navigationCoordinator = NavigationCoordinator()

    var body: some View {
        @Bindable var navCoordinator = navigationCoordinator

        NavigationStack(path: $navCoordinator.navigationPath) {
            HomeView()
                .navigationDestination(for: Puzzle.self) { puzzle in
                    PuzzleView(showPuzzle: .constant(true))
                }
        }
        .environment(navigationCoordinator)
        .injectTypography()
        .onChange(of: viewModel.currentError) { newError in
            if newError != nil {
                showError = true
            }
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .background || newPhase == .inactive {
                viewModel.flushPendingDailySave()
            }
        }
        .alert("Puzzle Error", isPresented: $showError) {
            Button("OK", role: .cancel) {
                viewModel.currentError = nil
            }
            Button("Try Again") {
                viewModel.currentError = nil
                viewModel.loadNewPuzzle()
            }
        } message: {
            if let error = viewModel.currentError {
                Text(error.userFriendlyMessage)
            }
        }
    }
}

#Preview {
    ContentView()
        .environment(PuzzleViewModel())
        .environment(AppSettings())
        .environment(ThemeManager())
}
