import SwiftUI

// TimerView component - positioned under the island
struct TimerView: View {
    let startTime: Date
    @State private var displayTime: TimeInterval = 0
    var isPaused: Bool = false
    
    var body: some View {
        VStack {
            Text(timeFormatted)
                .font(CryptogramTheme.Typography.body)
                .foregroundColor(CryptogramTheme.Colors.text)
                .padding(.vertical, 8)
                .padding(.horizontal, 16)
                .cornerRadius(CryptogramTheme.Layout.buttonCornerRadius)
        }
        .onAppear {
            updateDisplayTime()
        }
        .onReceive(Timer.publish(every: 0.25, on: .main, in: .common).autoconnect()) { _ in
            updateDisplayTime()
        }
    }
    
    private func updateDisplayTime() {
        if !isPaused {
            let timeInterval = Date().timeIntervalSince(startTime)
            // If startTime is in the future (game hasn't started), show 00:00
            displayTime = timeInterval < 0 ? 0 : timeInterval
        }
    }
    
    private var timeFormatted: String {
        let minutes = Int(displayTime) / 60
        let seconds = Int(displayTime) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

// MistakesView component - shows X icons in top left
struct MistakesView: View {
    let mistakeCount: Int
    let maxMistakes: Int = 3
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<maxMistakes, id: \.self) { index in
                Text("X")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(index < mistakeCount 
                                    ? Color(hex: "#9B0303") 
                                    : CryptogramTheme.Colors.secondary.opacity(0.3))
            }
        }
        .padding(8)
        .padding(.top, 10)
        .frame(width: 125, height: 32, alignment: .leading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Mistakes: \(mistakeCount) of \(maxMistakes)")
    }
}

// HintsView component - interactive hint system
struct HintsView: View {
    let hintCount: Int
    var onRequestHint: () -> Void
    var maxHints: Int = Int.max  // Set to essentially unlimited
    
    private let hintIconColor = Color.green.opacity(0.4)
    
    var body: some View {
        HStack(alignment: .center, spacing: 6) {
            if hintCount == 0 {
                Image(systemName: "lightbulb.fill")
                    .rotationEffect(.degrees(45))
                    .foregroundColor(CryptogramTheme.Colors.secondary.opacity(0.3))
                    .font(.system(size: 16))
            } else if hintCount == 1 {
                Image(systemName: "lightbulb.fill")
                    .rotationEffect(.degrees(45))
                    .foregroundColor(hintIconColor)
                    .font(.system(size: 16))
            } else if hintCount == 2 {
                ForEach(0..<2, id: \.self) { _ in
                    Image(systemName: "lightbulb.fill")
                        .rotationEffect(.degrees(45))
                        .foregroundColor(hintIconColor)
                        .font(.system(size: 16))
                }
            } else if hintCount == 3 {
                ForEach(0..<3, id: \.self) { _ in
                    Image(systemName: "lightbulb.fill")
                        .rotationEffect(.degrees(45))
                        .foregroundColor(hintIconColor)
                        .font(.system(size: 16))
                }
            } else if hintCount > 3 {
                ForEach(0..<3, id: \.self) { _ in
                    Image(systemName: "lightbulb.fill")
                        .rotationEffect(.degrees(45))
                        .foregroundColor(hintIconColor)
                        .font(.system(size: 16))
                }
                Text("+\(hintCount - 3)")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(hintIconColor)
                    .frame(minWidth: 18, maxWidth: 32, alignment: .leading)
                    .lineLimit(1)
            }
            Button(action: onRequestHint) {
                Image(systemName: "plus")
                    .foregroundColor(CryptogramTheme.Colors.text)
                    .font(.system(size: 18))
            }
        }
        .padding(8)
        .padding(.top, 28)
        .frame(width: 125, height: 32, alignment: .leading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Hints used: \(hintCount)")
        .accessibilityAddTraits(.isButton)
    }
}

// Legacy StatsView remains for backward compatibility if needed
struct StatsView: View {
    let hintCount: Int
    let maxHints: Int
    let mistakeCount: Int
    let startTime: Date
    var onRequestHint: () -> Void = {}
    var isPaused: Bool = false
    @ObservedObject var viewModel: PuzzleViewModel // required for UserStatsView

    var body: some View {
        VStack(spacing: 0) {
            // Row 1: Mistakes | Timer | Settings (gear icon)
            HStack(alignment: .center) {
                MistakesView(mistakeCount: mistakeCount)
                Spacer()
                TimerView(startTime: startTime, isPaused: isPaused)
                Spacer()
                Button(action: { /* settings action here */ }) {
                    Image(systemName: "gearshape")
                        .font(.system(size: 20, weight: .regular))
                        .foregroundColor(CryptogramTheme.Colors.text)
                }
                .accessibilityLabel("Settings")
            }
            // Row 2: Hints | (empty center) | User Stats (chart icon)
            HStack(alignment: .center) {
                HintsView(hintCount: hintCount, onRequestHint: onRequestHint)
                Spacer()
                // (empty center)
                Spacer()
                Button(action: { /* user stats action here */ }) {
                    Image(systemName: "chart.bar.xaxis")
                        .font(.system(size: 20, weight: .regular))
                        .foregroundColor(CryptogramTheme.Colors.text)
                }
                .accessibilityLabel("User Stats")
                // Or, to show the full stats view as a sheet:
                // UserStatsView(viewModel: viewModel)
            }
        }
    }
}

#Preview {
    VStack {
        StatsView(
            hintCount: 2,
            maxHints: 5,
            mistakeCount: 1,
            startTime: Date(),
            onRequestHint: {},
            isPaused: false,
            viewModel: PuzzleViewModel() // required for UserStatsView
        )
        
        Text("Preview of individual components:").padding(.top, 20)
        
        TimerView(startTime: Date(), isPaused: false)
            .padding()
        
        MistakesView(mistakeCount: 2)
            .padding()
        
        HintsView(hintCount: 1, onRequestHint: {})
            .padding()
    }
    .background(CryptogramTheme.Colors.background)
}

// Helper for previewing Binding properties
struct StatefulPreviewWrapper<Value, Content: View>: View {
    @State var value: Value
    var content: (Binding<Value>) -> Content

    init(_ value: Value, content: @escaping (Binding<Value>) -> Content) {
        _value = State(initialValue: value)
        self.content = content
    }

    var body: some View {
        content($value)
    }
} 