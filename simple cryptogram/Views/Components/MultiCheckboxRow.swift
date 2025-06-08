import SwiftUI

struct MultiCheckboxRow: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            action()
        }) {
            Text(title)
                .settingsToggleStyle(isSelected: isSelected)
                .padding(.horizontal, 6)
                .contentShape(Rectangle())
                .frame(height: 44)
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel("\(title) quote length")
        .accessibilityValue(isSelected ? "selected" : "not selected")
        .accessibilityHint("Double tap to \(isSelected ? "deselect" : "select")")
    }
}

#Preview {
    VStack(spacing: 0) {
        MultiCheckboxRow(title: "< 50", isSelected: true, action: {})
        MultiCheckboxRow(title: "50 - 99", isSelected: false, action: {})
        MultiCheckboxRow(title: "100 +", isSelected: true, action: {})
    }
    .padding()
} 