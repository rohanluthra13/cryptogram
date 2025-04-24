import SwiftUI

struct InfoOverlayView: View {
    var body: some View {
        SettingsSection(title: "solve the cryptogram to reveal the quote") {
            VStack(alignment: .leading, spacing: 26) {
                HStack(alignment: .top, spacing: 12) {
                    Text("X")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(Color(hex: "#9B0303"))
                        .frame(width: 22, height: 22, alignment: .center)
                    Text("you only get 3 mistakes")
                }
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "lightbulb.fill")
                        .rotationEffect(.degrees(45))
                        .foregroundColor(Color.green.opacity(0.4))
                        .font(.system(size: 16))
                        .frame(width: 22, height: 22, alignment: .center)
                    Text("but you can use as many hints as you want")
                }
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "calendar")
                        .font(.subheadline)
                        .foregroundColor(CryptogramTheme.Colors.text)
                        .frame(width: 22, height: 22, alignment: .center)
                    Text("each day has a new exclusive daily puzzle")
                }
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "gearshape")
                        .font(.subheadline)
                        .foregroundColor(CryptogramTheme.Colors.text)
                        .frame(width: 22, height: 22, alignment: .center)
                    Text("use settings to customise gameplay, theme and layout")
                }
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "chart.bar")
                        .font(.subheadline)
                        .foregroundColor(CryptogramTheme.Colors.text)
                        .frame(width: 22, height: 22, alignment: .center)
                    Text("see your stats and track your progress")
                }
            }
            .padding(.top, 20)
            .infoOverlayTextStyle()
            .foregroundColor(CryptogramTheme.Colors.text)
            .multilineTextAlignment(.leading)
            .padding(.horizontal, 24)
        }
        .padding(.horizontal, 24)
    }
}

#Preview {
    InfoOverlayView()
        .background(Color(.systemBackground))
}
