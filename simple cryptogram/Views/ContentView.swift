import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var viewModel: PuzzleViewModel
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            PuzzleView()
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
