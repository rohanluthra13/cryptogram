import SwiftUI

struct NavBarLayoutPreview: View {
    let layout: NavigationBarLayout
    
    // Scale for the preview - increased to 0.75
    private let scale: CGFloat = 0.75
    
    // Increased size for preview icons
    private let iconSize: CGFloat = 22
    private let iconSpacing: CGFloat = 8
    
    var body: some View {
        // Just show the layout preview with no background or border
        Group {
            switch layout {
            case .leftLayout:
                leftLayoutPreview
            case .centerLayout:
                centerLayoutPreview
            case .rightLayout:
                rightLayoutPreview
            }
        }
        .scaleEffect(scale)
    }
    
    // Left layout preview - arrows on left, action buttons on right
    private var leftLayoutPreview: some View {
        HStack {
            // Left side - navigation arrows
            HStack(spacing: iconSpacing) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14))
                    .frame(width: iconSize, height: iconSize)
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .frame(width: iconSize, height: iconSize)
            }
            .padding(.leading, 8)
            
            Spacer()
            
            // Right side - action buttons
            HStack(spacing: iconSpacing) {
                Image(systemName: "pause")
                    .font(.system(size: 14))
                    .frame(width: iconSize, height: iconSize)
                
                Image(systemName: "arrow.2.circlepath")
                    .font(.system(size: 14))
                    .frame(width: iconSize, height: iconSize)
            }
            .padding(.trailing, 8)
        }
        .frame(width: 160, height: 40)
        .foregroundColor(CryptogramTheme.Colors.text)
    }
    
    // Center layout preview - arrows on sides, action buttons in center
    private var centerLayoutPreview: some View {
        HStack {
            // Left arrow
            Image(systemName: "chevron.left")
                .font(.system(size: 14))
                .frame(width: iconSize, height: iconSize)
                .padding(.leading, 5)
            
            Spacer()
            
            // Center action buttons
            HStack(spacing: iconSpacing) {
                Image(systemName: "pause")
                    .font(.system(size: 14))
                    .frame(width: iconSize, height: iconSize)
                
                Image(systemName: "arrow.2.circlepath")
                    .font(.system(size: 14))
                    .frame(width: iconSize, height: iconSize)
            }
            
            Spacer()
            
            // Right arrow
            Image(systemName: "chevron.right")
                .font(.system(size: 14))
                .frame(width: iconSize, height: iconSize)
                .padding(.trailing, 5)
        }
        .frame(width: 160, height: 40)
        .foregroundColor(CryptogramTheme.Colors.text)
    }
    
    // Right layout preview - action buttons on left, arrows on right
    private var rightLayoutPreview: some View {
        HStack {
            // Left side - action buttons
            HStack(spacing: iconSpacing) {
                Image(systemName: "pause")
                    .font(.system(size: 14))
                    .frame(width: iconSize, height: iconSize)
                
                Image(systemName: "arrow.2.circlepath")
                    .font(.system(size: 14))
                    .frame(width: iconSize, height: iconSize)
            }
            .padding(.leading, 8)
            
            Spacer()
            
            // Right side - navigation arrows
            HStack(spacing: iconSpacing) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14))
                    .frame(width: iconSize, height: iconSize)
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .frame(width: iconSize, height: iconSize)
            }
            .padding(.trailing, 8)
        }
        .frame(width: 160, height: 40)
        .foregroundColor(CryptogramTheme.Colors.text)
    }
}

// Preview
struct NavBarLayoutPreviewSet: View {
    var body: some View {
        VStack(spacing: 20) {
            ForEach(NavigationBarLayout.allCases.sorted { $0.rawValue < $1.rawValue }) { layout in
                HStack {
                    Text(layout.displayName)
                        .frame(width: 60, alignment: .leading)
                    
                    NavBarLayoutPreview(layout: layout)
                }
            }
        }
        .padding()
    }
}

#Preview {
    NavBarLayoutPreviewSet()
        .background(CryptogramTheme.Colors.background)
} 