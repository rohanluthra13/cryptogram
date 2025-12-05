import SwiftUI

struct ContentView: View {
    @Environment(PuzzleViewModel.self) private var viewModel
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
        .onChange(of: viewModel.currentError) { _, newError in
            if newError != nil {
                showError = true
            }
        }
        .alert("Puzzle Error", isPresented: $showError) {
            Button("OK", role: .cancel) {
                viewModel.currentError = nil
            }
            
            // Show recovery action if available
            if let error = viewModel.currentError,
               let recoveryAction = ErrorRecoveryService.shared.recoveryAction(for: error) {
                switch recoveryAction {
                case .retry:
                    Button(recoveryAction.title) {
                        viewModel.currentError = nil
                        viewModel.loadNewPuzzle()
                    }
                case .resetProgress:
                    Button(recoveryAction.title) {
                        viewModel.currentError = nil
                        viewModel.resetAllProgress()
                    }
                default:
                    // For other actions, just dismiss
                    EmptyView()
                }
            }
        } message: {
            if let error = viewModel.currentError {
                let message = error.userFriendlyMessage
                if let recoveryAction = ErrorRecoveryService.shared.recoveryAction(for: error) {
                    Text("\(message)\n\n\(recoveryAction.instructions)")
                } else {
                    Text(message)
                }
            }
        }
    }
}

#Preview {
    ContentView()
        .environment(PuzzleViewModel())
        .environment(AppSettings())
        .environment(ThemeManager())
        .environment(SettingsViewModel())
}
