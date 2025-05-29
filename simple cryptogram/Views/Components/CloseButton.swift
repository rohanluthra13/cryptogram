//
//  CloseButton.swift
//  simple cryptogram
//
//  Created on 29/05/2025.
//

import SwiftUI

/// A reusable close button with consistent styling
struct CloseButton: View {
    let action: () -> Void
    var size: CGFloat = 30
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Button(action: action) {
            Image(systemName: "xmark.circle.fill")
                .resizable()
                .frame(width: size, height: size)
                .foregroundColor(foregroundColor)
                .background(Circle().fill(backgroundColor))
        }
        .accessibilityLabel("Close")
        .accessibilityHint("Dismiss this screen")
    }
    
    private var foregroundColor: Color {
        colorScheme == .dark ? .white : .black
    }
    
    private var backgroundColor: Color {
        colorScheme == .dark ? Color(white: 0.2) : Color(white: 0.9)
    }
}

/// A variant close button for inline toolbar use
struct ToolbarCloseButton: View {
    let action: () -> Void
    
    var body: some View {
        Button("Done", action: action)
            .font(.body.weight(.medium))
    }
}

#if DEBUG
struct CloseButton_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            CloseButton(action: {})
            
            CloseButton(action: {}, size: 40)
            
            ToolbarCloseButton(action: {})
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
#endif