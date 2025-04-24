import SwiftUI

// MARK: - Button Modifier
struct CryptogramButton: ViewModifier {
    let isSelected: Bool
    let isEnabled: Bool
    
    init(isSelected: Bool = false, isEnabled: Bool = true) {
        self.isSelected = isSelected
        self.isEnabled = isEnabled
    }
    
    func body(content: Content) -> some View {
        content
            .padding()
            .background(isSelected ? CryptogramTheme.Colors.primary : CryptogramTheme.Colors.secondary)
            .foregroundColor(.white)
            .cornerRadius(CryptogramTheme.Layout.buttonCornerRadius)
            .shadow(radius: CryptogramTheme.Layout.shadowRadius)
            .opacity(isEnabled ? 1.0 : 0.5)
    }
}

// MARK: - Cell Modifier
struct CryptogramCellStyle: ViewModifier {
    let isSelected: Bool
    let isRevealed: Bool
    let isError: Bool
    
    init(isSelected: Bool = false, isRevealed: Bool = false, isError: Bool = false) {
        self.isSelected = isSelected
        self.isRevealed = isRevealed
        self.isError = isError
    }
    
    func body(content: Content) -> some View {
        content
            .frame(width: CryptogramTheme.Layout.cellSize, height: CryptogramTheme.Layout.cellSize)
            .background(isSelected ? CryptogramTheme.Colors.primary : .clear)
            .border(
                isError ? CryptogramTheme.Colors.error :
                    isRevealed ? CryptogramTheme.Colors.success :
                    CryptogramTheme.Colors.secondary,
                width: 2
            )
            .cornerRadius(CryptogramTheme.Layout.cellCornerRadius)
    }
}

// MARK: - Grid Modifier
struct CryptogramGrid: ViewModifier {
    let columns: Int
    
    func body(content: Content) -> some View {
        content
            .padding(CryptogramTheme.Layout.gridPadding)
    }
}

// MARK: - Settings Modifiers
struct SettingsToggleStyle: ViewModifier {
    let isSelected: Bool
    
    func body(content: Content) -> some View {
        content
            .font(.footnote)
            .fontWeight(isSelected ? .bold : .regular)
            .foregroundColor(isSelected ? 
                          CryptogramTheme.Colors.text : 
                          CryptogramTheme.Colors.text.opacity(0.4))
    }
}

struct SettingsSectionStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.subheadline)
            .foregroundColor(CryptogramTheme.Colors.text)
            .frame(maxWidth: .infinity, alignment: .center)
    }
}

// MARK: - Info Overlay Modifier
struct InfoOverlayTextStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.system(size: 13, weight: .medium))
            .foregroundColor(CryptogramTheme.Colors.text)
            .multilineTextAlignment(.leading)
            .padding(.horizontal, 16)
            .lineSpacing(8)
    }
}

// MARK: - View Extensions
extension View {
    func cryptogramButton(isSelected: Bool = false, isEnabled: Bool = true) -> some View {
        modifier(CryptogramButton(isSelected: isSelected, isEnabled: isEnabled))
    }
    
    func cryptogramCell(isSelected: Bool = false, isRevealed: Bool = false, isError: Bool = false) -> some View {
        modifier(CryptogramCellStyle(isSelected: isSelected, isRevealed: isRevealed, isError: isError))
    }
    
    func cryptogramGrid(columns: Int) -> some View {
        modifier(CryptogramGrid(columns: columns))
    }
    
    func settingsToggleStyle(isSelected: Bool) -> some View {
        modifier(SettingsToggleStyle(isSelected: isSelected))
    }
    
    func settingsSectionStyle() -> some View {
        modifier(SettingsSectionStyle())
    }
    
    func infoOverlayTextStyle() -> some View {
        modifier(InfoOverlayTextStyle())
    }
}