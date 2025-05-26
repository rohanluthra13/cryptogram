import SwiftUI

struct InfoOverlayView: View {
    @Environment(\.typography) private var typography
    
    var body: some View {
        SettingsSection(title: "SOLVE THE ENCODED PUZZLE TO REVEAL THE QUOTE") {
            VStack(alignment: .leading, spacing: 26) {
                HStack(alignment: .top, spacing: 12) {
                    Text("X")
                        .font(.system(size: 18, weight: .bold, design: typography.fontOption.design))
                        .foregroundColor(Color(hex: "#9B0303"))
                        .frame(width: 22, height: 22, alignment: .center)
                    Text("you only get 3 mistakes")
                }
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "lightbulb.fill")
                        .rotationEffect(.degrees(45))
                        .foregroundColor(Color(hex: "#01780F").opacity(0.5))
                        .font(.system(size: 16, design: typography.fontOption.design))
                        .frame(width: 22, height: 22, alignment: .center)
                    Text("but you can use as many hints as you want")
                }
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .font(typography.body)
                        .foregroundColor(CryptogramTheme.Colors.text)
                        .frame(width: 22, height: 22, alignment: .center)
                    Text("and the magnifying glass shows your remaining letters")
                }
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "calendar")
                        .font(typography.body)
                        .foregroundColor(CryptogramTheme.Colors.text)
                        .frame(width: 22, height: 22, alignment: .center)
                    Text("each day has a new exclusive daily puzzle")
                }
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "gearshape")
                        .font(typography.body)
                        .foregroundColor(CryptogramTheme.Colors.text)
                        .frame(width: 22, height: 22, alignment: .center)
                    Text("settings lets you customise gameplay, theme and layout")
                }
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "chart.bar")
                        .font(typography.body)
                        .foregroundColor(CryptogramTheme.Colors.text)
                        .frame(width: 22, height: 22, alignment: .center)
                    Text("and you can see your stats as you go")
                }
            }
            .padding(.top, 20)
            .infoOverlayTextStyle()
            .foregroundColor(CryptogramTheme.Colors.text)
            .multilineTextAlignment(.leading)
            .padding(.horizontal, 24)
            Spacer(minLength: 0)
            DisclaimersSection()
        }
        .padding(.horizontal, 24)
    }
}

#Preview {
    InfoOverlayView()
        .background(Color(.systemBackground))
}
