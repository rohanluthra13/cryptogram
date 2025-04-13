import SwiftUI

struct SettingsContentView: View {
    @AppStorage("encodingType") private var selectedEncodingType = "Letters"
    @EnvironmentObject private var puzzleViewModel: PuzzleViewModel
    
    let encodingTypes = ["Letters", "Numbers"]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Encoding Type toggle
            HStack {
                // Left side - Letters option
                HStack(spacing: 8) {
                    Image(systemName: "character.cursor.ibeam")
                        .font(.system(size: 16))
                        .foregroundColor(selectedEncodingType == "Letters" ? 
                                        CryptogramTheme.Colors.text : 
                                        CryptogramTheme.Colors.text.opacity(0.4))
                    
                    Text("Letters")
                        .font(.subheadline)
                        .foregroundColor(selectedEncodingType == "Letters" ? 
                                        CryptogramTheme.Colors.text : 
                                        CryptogramTheme.Colors.text.opacity(0.4))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(selectedEncodingType == "Letters" ? 
                              Color.blue.opacity(0.2) : 
                              Color.gray.opacity(0.1))
                )
                .onTapGesture {
                    if selectedEncodingType != "Letters" {
                        selectedEncodingType = "Letters"
                        puzzleViewModel.refreshPuzzleWithCurrentSettings()
                    }
                }
                
                Spacer().frame(width: 12)
                
                // Right side - Numbers option
                HStack(spacing: 8) {
                    Image(systemName: "number")
                        .font(.system(size: 16))
                        .foregroundColor(selectedEncodingType == "Numbers" ? 
                                        CryptogramTheme.Colors.text : 
                                        CryptogramTheme.Colors.text.opacity(0.4))
                    
                    Text("Numbers")
                        .font(.subheadline)
                        .foregroundColor(selectedEncodingType == "Numbers" ? 
                                        CryptogramTheme.Colors.text : 
                                        CryptogramTheme.Colors.text.opacity(0.4))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(selectedEncodingType == "Numbers" ? 
                              Color.blue.opacity(0.2) : 
                              Color.gray.opacity(0.1))
                )
                .onTapGesture {
                    if selectedEncodingType != "Numbers" {
                        selectedEncodingType = "Numbers"
                        puzzleViewModel.refreshPuzzleWithCurrentSettings()
                    }
                }
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