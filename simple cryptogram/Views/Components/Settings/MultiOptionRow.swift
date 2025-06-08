import SwiftUI

struct MultiOptionRow<T: Hashable & Identifiable>: View {
    let options: [T]
    @Binding var selection: T
    var labelProvider: (T) -> String
    var showInfoButton: Bool = false
    var onInfoButtonTap: (() -> Void)? = nil
    var onSelectionChanged: (() -> Void)? = nil
    
    var body: some View {
        HStack {
            Spacer()
            
            // Multi-button implementation
            HStack(spacing: 12) {
                ForEach(options) { option in
                    Button(action: {
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
                        selection = option
                        onSelectionChanged?()
                    }) {
                        Text(labelProvider(option))
                            .settingsToggleStyle(isSelected: selection.id == option.id)
                            .background(Color.clear) // Remove fill/background
                    }
                    .buttonStyle(PlainButtonStyle())
                    .accessibilityLabel("Switch to \(labelProvider(option))")
                }
            }
            
            Spacer()
            
            // Optional info button
            if showInfoButton {
                Button(action: {
                    onInfoButtonTap?()
                }) {
                    Text("i")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(CryptogramTheme.Colors.text)
                }
                .accessibilityLabel("Information")
                .padding(.trailing, 5)
            }
        }
        .frame(height: 44) // Fixed height for consistency
    }
}

// Alternative implementation with segmented picker
struct DropdownOptionRow<T: Hashable & Identifiable>: View {
    let options: [T]
    @Binding var selection: T
    var labelProvider: (T) -> String
    var showInfoButton: Bool = false
    var onInfoButtonTap: (() -> Void)? = nil
    var onSelectionChanged: (() -> Void)? = nil
    
    var body: some View {
        HStack {
            Spacer()
            
            // Picker implementation
            Picker("", selection: $selection) {
                ForEach(options) { option in
                    Text(labelProvider(option))
                        .tag(option)
                        .background(Color.clear) // Ensure no background for dropdown buttons
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .onChange(of: selection) {
                onSelectionChanged?()
            }
            .frame(maxWidth: 240)
            .accessibilityLabel("Select option")
            
            Spacer()
            
            // Optional info button
            if showInfoButton {
                Button(action: {
                    onInfoButtonTap?()
                }) {
                    Text("i")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(CryptogramTheme.Colors.text)
                }
                .accessibilityLabel("Information")
                .padding(.trailing, 5)
            }
        }
        .frame(height: 44) // Fixed height for consistency
    }
}

// For Preview
struct SampleOption: Identifiable, Hashable {
    let id: String
    let name: String
}

struct MultiOptionRowPreview: View {
    let options = [
        SampleOption(id: "left", name: "Left"),
        SampleOption(id: "center", name: "Center"),
        SampleOption(id: "right", name: "Right")
    ]
    
    @State private var selection = SampleOption(id: "center", name: "Center")
    @State private var dropdownSelection = SampleOption(id: "center", name: "Center")
    
    var body: some View {
        VStack(spacing: 30) {
            Text("Multi Option Buttons")
                .font(.caption)
            
            MultiOptionRow(
                options: options, 
                selection: $selection,
                labelProvider: { $0.name }
            )
            
            Text("Dropdown/Segmented Style")
                .font(.caption)
            
            DropdownOptionRow(
                options: options,
                selection: $dropdownSelection,
                labelProvider: { $0.name }
            )
        }
    }
}

#Preview {
    MultiOptionRowPreview()
        .padding()
        .background(CryptogramTheme.Colors.background)
} 