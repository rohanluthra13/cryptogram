import SwiftUI

struct SettingsView: View {
    @AppStorage("difficulty") private var selectedDifficulty = "Medium"
    @AppStorage("encodingType") private var selectedEncodingType = "Letters"
    @EnvironmentObject private var puzzleViewModel: PuzzleViewModel
    
    let difficulties = ["Easy", "Medium", "Hard"]
    let encodingTypes = ["Letters", "Numbers"]
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Game Settings")) {
                    Picker("Difficulty", selection: $selectedDifficulty) {
                        ForEach(difficulties, id: \.self) {
                            Text($0)
                        }
                    }
                    
                    Picker("Encoding Type", selection: $selectedEncodingType) {
                        ForEach(encodingTypes, id: \.self) {
                            Text($0)
                        }
                    }
                    .onChange(of: selectedEncodingType) { newValue in
                        puzzleViewModel.refreshPuzzleWithCurrentSettings()
                    }
                }
                
                Section(header: Text("About")) {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(PuzzleViewModel())
} 
