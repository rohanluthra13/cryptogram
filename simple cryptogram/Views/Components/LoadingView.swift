import SwiftUI

struct LoadingView: View {
    let message: String
    @Environment(\.typography) private var typography
    
    var body: some View {
        VStack(spacing: 20) {
            Text(message)
                .font(typography.body)
                .foregroundColor(CryptogramTheme.Colors.text)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(CryptogramTheme.Colors.background)
    }
}

#Preview {
    LoadingView(message: "Loading your puzzle...")
} 