import SwiftUI

struct NavigationBarView: View {
    var onMoveLeft: () -> Void
    var onMoveRight: () -> Void
    var onTogglePause: () -> Void
    var onNextPuzzle: () -> Void
    
    var isPaused: Bool
    var showCenterButtons: Bool = true
    var isDailyPuzzle: Bool = false
    
    @Binding var layout: NavigationBarLayout
    @Environment(\.typography) private var typography
    
    private let buttonSize: CGFloat = 44
    private let spacing: CGFloat = 16
    
    var body: some View {
        HStack(spacing: 0) {
            layoutContent
        }
        .padding(.top, 8)
        .padding(.bottom, 4)
        .frame(maxWidth: .infinity)
    }
    
    @ViewBuilder
    private var layoutContent: some View {
        switch layout {
        case .leftLayout:
            navGroup.padding(.leading, 60)
            Spacer()
            if showCenterButtons { actionGroup.padding(.trailing, 60) }
            
        case .centerLayout:
            navButton(.left).padding(.leading, 10)
            Spacer()
            if showCenterButtons { actionGroup }
            Spacer()
            navButton(.right).padding(.trailing, 10)
            
        case .rightLayout:
            if showCenterButtons { actionGroup.padding(.leading, 60) }
            Spacer()
            navGroup.padding(.trailing, 60)
        }
    }
    
    private var navGroup: some View {
        HStack(spacing: spacing) {
            navButton(.left)
            navButton(.right)
        }
    }
    
    private var actionGroup: some View {
        HStack(spacing: spacing) {
            actionButton(.pause(isPaused: isPaused))
            if !isDailyPuzzle {
                actionButton(.nextPuzzle)
            }
        }
    }
    
    private func navButton(_ direction: NavDirection) -> some View {
        Button(action: direction == .left ? onMoveLeft : onMoveRight) {
            Image(systemName: direction.icon)
                .font(typography.button)
                .frame(width: buttonSize, height: buttonSize)
                .foregroundColor(CryptogramTheme.Colors.text)
                .accessibilityLabel(direction.label)
        }
    }
    
    private func actionButton(_ type: ActionType) -> some View {
        Button(action: {
            switch type {
            case .pause: onTogglePause()
            case .nextPuzzle: onNextPuzzle()
            }
        }) {
            Image(systemName: type.icon)
                .font(typography.button)
                .frame(width: buttonSize, height: buttonSize)
                .foregroundColor(CryptogramTheme.Colors.text)
                .accessibilityLabel(type.label)
        }
    }
    
    private enum NavDirection {
        case left, right
        var icon: String { self == .left ? "chevron.left" : "chevron.right" }
        var label: String { self == .left ? "Move Left" : "Move Right" }
    }
    
    private enum ActionType {
        case pause(isPaused: Bool)
        case nextPuzzle
        
        var icon: String {
            switch self {
            case .pause(let isPaused): return isPaused ? "play" : "pause"
            case .nextPuzzle: return "arrow.2.circlepath"
            }
        }
        
        var label: String {
            switch self {
            case .pause(let isPaused): return isPaused ? "Resume" : "Pause"
            case .nextPuzzle: return "New Puzzle"
            }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        ForEach(NavigationBarLayout.allCases) { layout in
            NavigationBarView(
                onMoveLeft: {},
                onMoveRight: {},
                onTogglePause: {},
                onNextPuzzle: {},
                isPaused: false,
                layout: .constant(layout)
            )
        }
        NavigationBarView(
            onMoveLeft: {},
            onMoveRight: {},
            onTogglePause: {},
            onNextPuzzle: {},
            isPaused: true,
            layout: .constant(.centerLayout)
        )
    }
}