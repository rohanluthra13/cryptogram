import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var viewModel: PuzzleViewModel
    @State private var showError = false
    @StateObject private var navigationCoordinator = NavigationCoordinator()
    
    var body: some View {
        Group {
            if FeatureFlag.newNavigation.isEnabled {
                // New navigation system using NavigationStack
                NavigationStack(path: $navigationCoordinator.navigationPath) {
                    HomeView()
                        .navigationDestination(for: Puzzle.self) { puzzle in
                            PuzzleView(showPuzzle: .constant(true))
                                .environmentObject(viewModel)
                        }
                }
                .environmentObject(navigationCoordinator)
            } else {
                // Legacy navigation system
                NavigationStack {
                    HomeView()
                }
                .environmentObject(navigationCoordinator)
            }
        }
        .injectTypography()
        .onChange(of: viewModel.currentError) { _, newError in
            if let error = newError {
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
    let viewModel = PuzzleViewModel()
    return ContentView()
        .environmentObject(viewModel)
        .environment(AppSettings())
}
