import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = PuzzleViewModel()
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            PuzzleView()
                .environmentObject(viewModel)
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

