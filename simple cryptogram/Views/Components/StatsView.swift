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
                                    ? Color.red.opacity(0.9) 
                                    : CryptogramTheme.Colors.secondary.opacity(0.3))
            }
        }
        .padding(8)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Mistakes: \(mistakeCount) of \(maxMistakes)")
    }
}

// HintsView component - interactive hint system
struct HintsView: View {
    let hintCount: Int
    var onRequestHint: () -> Void
    var maxHints: Int = Int.max  // Set to essentially unlimited
    
    // Create a custom muted green color that's darker than the cell highlight
    private let hintIconColor = Color.green.opacity(0.4)
    
    var body: some View {
        HStack(spacing: 6) {
            // Show lightbulbs representing used hints - show max 5
            ForEach(0..<min(5, hintCount + 1), id: \.self) { index in
                Image(systemName: "lightbulb.fill")
                    .rotationEffect(.degrees(45))
                    .foregroundColor(index < hintCount 
                                    ? hintIconColor 
                                    : CryptogramTheme.Colors.secondary.opacity(0.3))
                    .font(.system(size: 16))
            }
            
            // If more than 5 hints used, show a count
            if hintCount >= 5 {
                Text("+\(hintCount - 4)")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(hintIconColor)
            }
            
            // Plus button to request a hint - always enabled
            Button(action: onRequestHint) {
                Image(systemName: "plus")
                    .foregroundColor(CryptogramTheme.Colors.text)
                    .font(.system(size: 18))
            }
        }
        .padding(8)
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
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top) {
                MistakesView(mistakeCount: mistakeCount)
                
                Spacer()
            }
            
            HStack {
                HintsView(hintCount: hintCount, onRequestHint: onRequestHint)
                
                Spacer()
            }
            
            TimerView(startTime: startTime, isPaused: isPaused)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 8)
        }
    }
}

#Preview {
    VStack {
        StatsView(
            hintCount: 2,
            maxHints: 5,
            mistakeCount: 1,
            startTime: Date().addingTimeInterval(-125), // 2 minutes and 5 seconds ago
            onRequestHint: {},
            isPaused: false
        )
        
        Text("Preview of individual components:").padding(.top, 20)
        
        TimerView(startTime: Date().addingTimeInterval(-125), isPaused: false)
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