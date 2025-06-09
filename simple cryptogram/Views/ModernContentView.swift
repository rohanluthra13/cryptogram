import SwiftUI

/// Modern ContentView using the refactored architecture
/// This demonstrates the new NavigationState and BusinessLogicCoordinator pattern
struct ModernContentView: View {
    @StateObject private var navigationState = NavigationState()
    @StateObject private var businessLogic = BusinessLogicCoordinator()
    @StateObject private var navigationCoordinator = NavigationCoordinator()
    
    @EnvironmentObject private var deepLinkManager: DeepLinkManager
    @Environment(AppSettings.self) private var appSettings
    
    @State private var showError = false
    @State private var isInitialized = false
    
    var body: some View {
        NavigationStack(path: $navigationCoordinator.navigationPath) {
            ModernHomeView()
                .navigationDestination(for: Puzzle.self) { puzzle in
                    ModernPuzzleView(puzzle: puzzle)
                        .navigationTransition()
                }
        }
        .environmentObject(navigationState)
        .environmentObject(businessLogic)
        .environmentObject(navigationCoordinator)
        .overlay {
            // Global overlay management
            if let overlay = navigationState.presentedOverlay {
                overlayContent(for: overlay)
                    .overlayTransition()
            }
        }
        .navigationPersistence(navigationState: navigationState, businessLogic: businessLogic)
        .onChange(of: businessLogic.currentError) { _, newError in
            if newError != nil {
                showError = true
            }
        }
        .alert("Puzzle Error", isPresented: $showError) {
            Button("OK", role: .cancel) {
                businessLogic.currentError = nil
            }
            
            if let error = businessLogic.currentError,
               let recoveryAction = ErrorRecoveryService.shared.recoveryAction(for: error) {
                switch recoveryAction {
                case .retry:
                    Button(recoveryAction.title) {
                        businessLogic.currentError = nil
                        Task {
                            await businessLogic.loadNewPuzzle()
                        }
                    }
                case .resetProgress:
                    Button(recoveryAction.title) {
                        businessLogic.currentError = nil
                        businessLogic.resetAllProgress()
                    }
                default:
                    EmptyView()
                }
            }
        } message: {
            if let error = businessLogic.currentError {
                let message = error.userFriendlyMessage
                if let recoveryAction = ErrorRecoveryService.shared.recoveryAction(for: error) {
                    Text("\(message)\n\n\(recoveryAction.instructions)")
                } else {
                    Text(message)
                }
            }
        }
        .task {
            // Initialize deep link manager
            if !isInitialized {
                deepLinkManager.configure(
                    navigationState: navigationState,
                    businessLogic: businessLogic
                )
                deepLinkManager.processPendingDeepLink()
                isInitialized = true
            }
        }
    }
    
    // MARK: - Overlay Content
    
    @ViewBuilder
    private func overlayContent(for overlay: OverlayType) -> some View {
        switch overlay {
        case .settings:
            SettingsContentView()
                .environmentObject(SettingsViewModel())
            
        case .stats:
            // For now, skip stats in modern view - requires adaptation
            Text("Stats View")
                .foregroundColor(.primary)
            
        case .calendar:
            Text("Calendar View")
                .foregroundColor(.primary)
            
        case .info:
            Text("Info View")
                .foregroundColor(.primary)
            
        case .completion(let state):
            Text("Completion View: \(String(describing: state))")
                .foregroundColor(.primary)
            
        case .gameOver:
            // Game over is handled differently in PuzzleView
            EmptyView()
            
        case .pause:
            // Pause is handled differently in PuzzleView
            EmptyView()
        }
    }
}

// MARK: - Preview

#Preview {
    ModernContentView()
        .environment(AppSettings())
        .environmentObject(ThemeManager())
        .environmentObject(DeepLinkManager())
}