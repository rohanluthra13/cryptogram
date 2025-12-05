import SwiftUI

struct FloatingInfoButton: View {
    @Environment(PuzzleViewModel.self) private var viewModel
    var uiState: PuzzleViewState
    
    private var shouldShow: Bool {
        viewModel.currentPuzzle != nil && uiState.isMainUIVisible
    }
    
    var body: some View {
        if shouldShow {
            VStack {
                HStack {
                    Spacer()
                    Button(action: {
                        withAnimation {
                            uiState.showInfoOverlay.toggle()
                        }
                    }) {
                        Image(systemName: "questionmark")
                            .font(.system(size: PuzzleViewConstants.Sizes.questionMarkSize))
                            .foregroundColor(CryptogramTheme.Colors.text)
                            .opacity(uiState.showInfoOverlay ? PuzzleViewConstants.Colors.activeIconOpacity : PuzzleViewConstants.Colors.iconOpacity)
                            .frame(width: PuzzleViewConstants.Sizes.floatingInfoButtonSize, height: PuzzleViewConstants.Sizes.floatingInfoButtonSize)
                            .accessibilityLabel("About / Info")
                    }
                    .offset(x: PuzzleViewConstants.Sizes.floatingInfoButtonOffset.width, y: PuzzleViewConstants.Sizes.floatingInfoButtonOffset.height)
                    .padding(.trailing, 16)
                }
                Spacer()
            }
            .zIndex(OverlayZIndex.floatingInfo)
        }
    }
}

#Preview {
    FloatingInfoButton(uiState: PuzzleViewState())
        .environment(PuzzleViewModel())
}