import SwiftUI

struct SettingsSection<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .center, spacing: 20) {
            Text(title)
                .settingsSectionStyle()
                .padding(.bottom, 5)
            
            content
                .padding(.bottom, 8)
        }
        .padding(.vertical, 12)
    }
}

#Preview {
    SettingsSection(title: "Sample Section") {
        Text("Content goes here")
            .foregroundColor(CryptogramTheme.Colors.text)
    }
    .padding()
    .background(CryptogramTheme.Colors.background)
} 