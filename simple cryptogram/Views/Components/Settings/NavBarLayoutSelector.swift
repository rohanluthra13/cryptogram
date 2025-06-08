import SwiftUI

struct NavBarLayoutSelector: View {
    @Binding var selection: NavigationBarLayout
    @State private var isExpanded = false
    
    // Get sorted layout options
    private var sortedLayouts: [NavigationBarLayout] {
        NavigationBarLayout.allCases.sorted { $0.rawValue < $1.rawValue }
    }
    
    var body: some View {
        VStack(spacing: 6) {
            // Expandable button
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    Spacer()
                    
                    Text("button layout: ")
                        .font(.footnote)
                        .foregroundColor(CryptogramTheme.Colors.text) +
                    Text(selection.displayName)
                        .font(.footnote)
                        .fontWeight(.bold)
                        .foregroundColor(CryptogramTheme.Colors.text)
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(CryptogramTheme.Colors.text)
                        .padding(.leading, 4)
                    
                    Spacer()
                }
                .background(Color.clear) // Ensure no background
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            
            // Expanded options
            if isExpanded {
                VStack(spacing: 10) {
                    // Button options row
                    MultiOptionRow(
                        options: sortedLayouts,
                        selection: $selection,
                        labelProvider: { $0.displayName }
                    )
                    
                    // Layout preview
                    NavBarLayoutPreview(layout: selection)
                        .padding(.horizontal, 10)
                        .padding(.bottom, 5)
                }
                .transition(.move(edge: .top).combined(with: .opacity))
                .padding(.top, 8)
            }
        }
    }
}

#Preview {
    @Previewable @State var selection = NavigationBarLayout.centerLayout
    
    return NavBarLayoutSelector(selection: $selection)
        .padding()
        // .background(CryptogramTheme.Colors.background)
} 