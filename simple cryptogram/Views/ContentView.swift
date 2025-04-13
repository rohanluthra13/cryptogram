import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = PuzzleViewModel()
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        TabView {
            PuzzleView()
                .environmentObject(viewModel)
                .tabItem {
                    Label("Puzzles", systemImage: "puzzlepiece.fill")
                }
            
            SettingsView()
                .environmentObject(viewModel)
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
}

#Preview {
    let viewModel = PuzzleViewModel()
    return ContentView()
        .environmentObject(viewModel)
}

