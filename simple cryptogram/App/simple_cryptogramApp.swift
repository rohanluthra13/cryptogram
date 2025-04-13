import SwiftUI

@main
struct simple_cryptogramApp: App {
    @StateObject private var viewModel = PuzzleViewModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(viewModel)
        }
    }
}

