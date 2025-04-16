import SwiftUI

struct IconToggleButton: View {
    let iconName: String
    let isSelected: Bool
    let action: () -> Void
    let accessibilityLabel: String
    
    var body: some View {
        Button(action: {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            action()
        }) {
            Image(systemName: iconName)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(isSelected ? 
                               CryptogramTheme.Colors.text : 
                               CryptogramTheme.Colors.text.opacity(0.4))
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel(accessibilityLabel)
    }
}

struct IconToggleButtonPreview: View {
    @State private var isDarkMode = false
    
    var body: some View {
        HStack(spacing: 20) {
            IconToggleButton(
                iconName: "sun.max",
                isSelected: !isDarkMode,
                action: { isDarkMode = false },
                accessibilityLabel: "Light Mode"
            )
            
            Button(action: { isDarkMode.toggle() }) {
                Image(systemName: !isDarkMode ? "arrow.right" : "arrow.left")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(CryptogramTheme.Colors.text)
            }
            
            IconToggleButton(
                iconName: "moon.stars",
                isSelected: isDarkMode,
                action: { isDarkMode = true },
                accessibilityLabel: "Dark Mode"
            )
        }
    }
}

#Preview {
    IconToggleButtonPreview()
        .padding()
        .background(CryptogramTheme.Colors.background)
} 