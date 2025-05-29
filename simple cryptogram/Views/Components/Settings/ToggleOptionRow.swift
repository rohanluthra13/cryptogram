import SwiftUI

struct ToggleOptionRow<T: Equatable>: View {
    let leftOption: (value: T, label: String)
    let rightOption: (value: T, label: String)
    @Binding var selection: T
    var showInfoButton: Bool = false
    var onInfoButtonTap: (() -> Void)? = nil
    var onSelectionChanged: (() -> Void)? = nil
    @Environment(\.typography) private var typography
    @State private var hapticTrigger = 0
    
    var body: some View {
        HStack {
            Spacer()
            
            // Left option button
            Button(action: {
                hapticTrigger += 1
                selection = leftOption.value
                onSelectionChanged?()
            }) {
                Text(leftOption.label)
                    .settingsToggleStyle(isSelected: selection == leftOption.value)
            }
            .buttonStyle(PlainButtonStyle())
            .accessibilityLabel("Switch to \(leftOption.label)")
            .padding(.trailing, 6)
            
            // Toggle arrow
            Button(action: {
                hapticTrigger += 1
                selection = selection == leftOption.value ? rightOption.value : leftOption.value
                onSelectionChanged?()
            }) {
                Image(systemName: selection == leftOption.value ? "arrow.right" : "arrow.left")
                    .font(.system(size: 13, weight: .medium, design: typography.fontOption.design))
                    .foregroundColor(CryptogramTheme.Colors.text)
            }
            .accessibilityLabel("Toggle between \(leftOption.label) and \(rightOption.label)")
            .padding(.horizontal, 6)
            
            // Right option button
            Button(action: {
                hapticTrigger += 1
                selection = rightOption.value
                onSelectionChanged?()
            }) {
                Text(rightOption.label)
                    .settingsToggleStyle(isSelected: selection == rightOption.value)
            }
            .buttonStyle(PlainButtonStyle())
            .accessibilityLabel("Switch to \(rightOption.label)")
            .padding(.leading, 6)
            
            Spacer()
            
            // Optional info button
            if showInfoButton {
                Button(action: {
                    onInfoButtonTap?()
                }) {
                    Text("i")
                        .font(.system(size: 15, weight: .medium, design: typography.fontOption.design))
                        .foregroundColor(CryptogramTheme.Colors.text)
                }
                .accessibilityLabel("Information")
                .padding(.trailing, 5)
            }
        }
        .frame(height: 44) // Fixed height for consistency
        .sensoryFeedback(.impact(flexibility: .soft, intensity: 0.5), trigger: hapticTrigger)
    }
}

struct ToggleOptionRowPreview: View {
    @State private var selection = "Option1"
    @State private var showInfo = false
    @Environment(\.typography) private var typography
    
    var body: some View {
        VStack(spacing: 20) {
            ToggleOptionRow(
                leftOption: (value: "Option1", label: "ABC"),
                rightOption: (value: "Option2", label: "123"),
                selection: $selection
            )
            
            ToggleOptionRow(
                leftOption: (value: "Option1", label: "Left"),
                rightOption: (value: "Option2", label: "Right"),
                selection: $selection,
                showInfoButton: true,
                onInfoButtonTap: { showInfo.toggle() }
            )
            
            if showInfo {
                Text("This is info content")
                    .font(typography.footnote)
                    .foregroundColor(CryptogramTheme.Colors.text)
                    .padding()
            }
        }
    }
}

#Preview {
    ToggleOptionRowPreview()
        .padding()
        .background(CryptogramTheme.Colors.background)
} 