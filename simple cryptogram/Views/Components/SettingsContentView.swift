import SwiftUI

struct SettingsContentView: View {
    @AppStorage("encodingType") private var selectedEncodingType = "Letters"
    @EnvironmentObject private var puzzleViewModel: PuzzleViewModel
    
    let encodingTypes = ["Letters", "Numbers"]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Encoding Type toggle
            VStack(spacing: 8) {
                HStack {
                    Spacer()
                    
                    // Left side - Letters option
                    Button(action: {
                        if selectedEncodingType != "Letters" {
                            selectedEncodingType = "Letters"
                            puzzleViewModel.refreshPuzzleWithCurrentSettings()
                        }
                    }) {
                        Text("ABC")
                            .font(.footnote)
                            .fontWeight(selectedEncodingType == "Letters" ? .bold : .regular)
                            .foregroundColor(selectedEncodingType == "Letters" ? 
                                            CryptogramTheme.Colors.text : 
                                            CryptogramTheme.Colors.text.opacity(0.4))
                    }
                    .buttonStyle(PlainButtonStyle())
                    .accessibilityLabel("Switch to Letters encoding")
                    .padding(.trailing, 6)
                    
                    // Center - Toggle switch with arrows
                    Button(action: {
                        selectedEncodingType = selectedEncodingType == "Letters" ? "Numbers" : "Letters"
                        puzzleViewModel.refreshPuzzleWithCurrentSettings()
                    }) {
                        Image(systemName: "arrow.left.arrow.right")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(CryptogramTheme.Colors.text)
                    }
                    .accessibilityLabel("Toggle encoding type")
                    .padding(.horizontal, 6)
                    
                    // Right side - Numbers option
                    Button(action: {
                        if selectedEncodingType != "Numbers" {
                            selectedEncodingType = "Numbers"
                            puzzleViewModel.refreshPuzzleWithCurrentSettings()
                        }
                    }) {
                        Text("123")
                            .font(.footnote)
                            .fontWeight(selectedEncodingType == "Numbers" ? .bold : .regular)
                            .foregroundColor(selectedEncodingType == "Numbers" ? 
                                            CryptogramTheme.Colors.text : 
                                            CryptogramTheme.Colors.text.opacity(0.4))
                    }
                    .buttonStyle(PlainButtonStyle())
                    .accessibilityLabel("Switch to Numbers encoding")
                    .padding(.leading, 6)
                    
                    Spacer()
                }
                
                // Thin line under the toggle
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(Color.gray.opacity(0.3))
            }
        }
    }
}

#Preview {
    SettingsContentView()
        .padding()
        .background(Color(hex: "#f8f8f8"))
        .previewLayout(.sizeThatFits)
        .environmentObject(PuzzleViewModel())
} 