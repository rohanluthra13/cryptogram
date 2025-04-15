import SwiftUI

struct NavBarLayoutDropdown: View {
    @Binding var selection: NavigationBarLayout
    @State private var isDropdownOpen = false
    
    var body: some View {
        dropdownContent
    }
    
    private var dropdownContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Selected option display with dropdown arrow
            selectionButton
            
            // Dropdown options
            if isDropdownOpen {
                optionsListView
            }
        }
        .accessibilityLabel("Button layout options")
    }
    
    private var selectionButton: some View {
        Button(action: {
            withAnimation {
                isDropdownOpen.toggle()
            }
        }) {
            HStack {
                // Split text with different styling
                Text("button layout = ")
                    .foregroundColor(CryptogramTheme.Colors.text)
                    .font(.system(size: 14))
                    .fontWeight(.bold)
                
                Text(selection.displayName.lowercased())
                    .foregroundColor(CryptogramTheme.Colors.text)
                    .font(.system(size: 14))
                    .fontWeight(.regular)
                
                Image(systemName: "chevron.down")
                    .font(.system(size: 10))
                    .foregroundColor(CryptogramTheme.Colors.text)
                    .rotationEffect(isDropdownOpen ? .degrees(180) : .degrees(0))
            }
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.vertical, 6)
    }
    
    private var optionsListView: some View {
        VStack(alignment: .trailing, spacing: 10) {
            ForEach(NavigationBarLayout.allCases.sorted { $0.rawValue < $1.rawValue }) { option in
                optionButton(for: option)
            }
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
        .padding(.top, 4)
        .transition(.opacity)
    }
    
    private func optionButton(for option: NavigationBarLayout) -> some View {
        let isSelected = selection == option
        // Use same text color for all options
        let fontWeight = isSelected ? Font.Weight.semibold : Font.Weight.regular
        
        return Button(action: {
            selection = option
            withAnimation {
                isDropdownOpen = false
            }
        }) {
            Text(option.displayName)
                .foregroundColor(CryptogramTheme.Colors.text)
                .font(.system(size: 14))
                .fontWeight(fontWeight)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    @State var selection = NavigationBarLayout.centerLayout
    
    return NavBarLayoutDropdown(selection: $selection)
        .padding()
        .background(CryptogramTheme.Colors.background)
} 