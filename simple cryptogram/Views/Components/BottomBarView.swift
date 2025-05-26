import SwiftUI

struct BottomBarView: View {
    @ObservedObject var uiState: PuzzleViewState
    @Environment(\.dismiss) private var dismiss
    
    private var shouldShowBar: Bool {
        !uiState.showInfoOverlay && 
        (uiState.isBottomBarVisible || uiState.showSettings || uiState.showStatsOverlay)
    }
    
    private var shouldShowInvisibleTapArea: Bool {
        !uiState.showInfoOverlay && 
        !(uiState.isBottomBarVisible || uiState.showSettings || uiState.showStatsOverlay)
    }
    
    var body: some View {
        ZStack {
            // Visible bottom bar with icons
            if shouldShowBar {
                VStack {
                    Spacer()
                    HStack {
                        // Stats button
                        Button(action: {
                            uiState.toggleStats()
                        }) {
                            Image(systemName: "chart.bar")
                                .font(.system(size: PuzzleViewConstants.Sizes.statsIconSize))
                                .foregroundColor(CryptogramTheme.Colors.text)
                                .opacity(PuzzleViewConstants.Colors.iconOpacity)
                                .frame(width: PuzzleViewConstants.Sizes.iconButtonFrame, height: PuzzleViewConstants.Sizes.iconButtonFrame)
                                .accessibilityLabel("Stats/Chart")
                        }
                        
                        Spacer()
                        
                        // Home button (center)
                        Button(action: {
                            dismiss()
                        }) {
                            Image(systemName: "house")
                                .font(.title3)
                                .foregroundColor(CryptogramTheme.Colors.text)
                                .opacity(PuzzleViewConstants.Colors.iconOpacity)
                                .frame(width: PuzzleViewConstants.Sizes.iconButtonFrame, height: PuzzleViewConstants.Sizes.iconButtonFrame)
                                .accessibilityLabel("Return to Home")
                        }
                        
                        Spacer()
                        
                        // Settings button
                        Button(action: {
                            uiState.toggleSettings()
                        }) {
                            Image(systemName: "gearshape")
                                .font(.system(size: PuzzleViewConstants.Sizes.settingsIconSize))
                                .foregroundColor(CryptogramTheme.Colors.text)
                                .opacity(PuzzleViewConstants.Colors.iconOpacity)
                                .frame(width: PuzzleViewConstants.Sizes.iconButtonFrame, height: PuzzleViewConstants.Sizes.iconButtonFrame)
                                .accessibilityLabel("Settings")
                        }
                    }
                    .frame(height: PuzzleViewConstants.Spacing.bottomBarHeight, alignment: .bottom)
                    .padding(.horizontal, PuzzleViewConstants.Spacing.bottomBarHorizontalPadding)
                    .frame(maxWidth: .infinity)
                    .ignoresSafeArea(edges: .bottom)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        uiState.showBottomBarTemporarily()
                    }
                }
                .zIndex(190)
            }
            
            // Invisible tap area to bring back bottom bar
            if shouldShowInvisibleTapArea {
                VStack {
                    Spacer()
                    Rectangle()
                        .fill(Color.clear)
                        .frame(height: PuzzleViewConstants.Spacing.bottomBarHeight)
                        .frame(maxWidth: .infinity)
                        .ignoresSafeArea(edges: .bottom)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            uiState.showBottomBarTemporarily()
                        }
                }
                .zIndex(189)
            }
        }
    }
}

#Preview {
    BottomBarView(uiState: PuzzleViewState())
}