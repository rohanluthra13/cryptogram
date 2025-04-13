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
struct CryptogramCell: ViewModifier {
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

// MARK: - View Extensions
extension View {
    func cryptogramButton(isSelected: Bool = false, isEnabled: Bool = true) -> some View {
        modifier(CryptogramButton(isSelected: isSelected, isEnabled: isEnabled))
    }
    
    func cryptogramCell(isSelected: Bool = false, isRevealed: Bool = false, isError: Bool = false) -> some View {
        modifier(CryptogramCell(isSelected: isSelected, isRevealed: isRevealed, isError: isError))
    }
    
    func cryptogramGrid(columns: Int) -> some View {
        modifier(CryptogramGrid(columns: columns))
    }
} 