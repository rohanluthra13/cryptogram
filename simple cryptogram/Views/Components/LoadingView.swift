import SwiftUI

struct LoadingView: View {
    let message: String
    
    var body: some View {
        VStack(spacing: 20) {
            Text(message)
                .font(CryptogramTheme.Typography.body)
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