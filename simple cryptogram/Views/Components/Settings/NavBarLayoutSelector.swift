import SwiftUI

struct NavBarLayoutSelector: View {
    @Binding var selection: NavigationBarLayout
    
    // Get sorted layout options
    private var sortedLayouts: [NavigationBarLayout] {
        NavigationBarLayout.allCases.sorted { $0.rawValue < $1.rawValue }
    }
    
    var body: some View {
        VStack(spacing: 6) {
            // Button options row
            MultiOptionRow(
                options: sortedLayouts,
                selection: $selection,
                labelProvider: { $0.displayName }
            )
            
            // Only show the selected layout's preview
            NavBarLayoutPreview(layout: selection)
                .padding(.horizontal, 10)
                .padding(.bottom, 5)
        }
    }
}

#Preview {
    @State var selection = NavigationBarLayout.centerLayout
    
    return NavBarLayoutSelector(selection: $selection)
        .padding()
        .background(CryptogramTheme.Colors.background)
} 