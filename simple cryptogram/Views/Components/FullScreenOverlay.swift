import SwiftUI

struct FullScreenOverlay<Content: View>: View {
    @Binding var isPresented: Bool
    var backgroundColor: Color = CryptogramTheme.Colors.background
    var backgroundOpacity: Double = 0.98
    @ViewBuilder let content: () -> Content

    var body: some View {
        ZStack {
            backgroundColor
                .opacity(backgroundOpacity)
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .onTapGesture {
                    withAnimation {
                        isPresented = false
                    }
                }

            content()
                .contentShape(Rectangle())
                .onTapGesture {}

            VStack {
                HStack {
                    Spacer()
                    Button(action: {
                        withAnimation {
                            isPresented = false
                        }
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(CryptogramTheme.Colors.text.opacity(0.6))
                            .frame(width: 22, height: 22)
                    }
                    .padding(.top, 50)
                    .padding(.trailing, 20)
                }
                Spacer()
            }
        }
        .transition(.opacity)
        .animation(.easeInOut(duration: PuzzleViewConstants.Animation.overlayDuration), value: isPresented)
    }
}
