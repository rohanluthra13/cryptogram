# SettingsContentView Refactoring Plan

## Current Analysis

The current `SettingsContentView` has several issues:
- Inconsistent spacing and structure
- Custom toggle implementations that could be more modular
- Hard-coded layout values that make maintenance difficult
- Mixed styling approaches
- Complex nested view hierarchy
- Info panel implementation that only works for one toggle

## Refactoring Goals

1. Create a consistent, modular section-based design
2. Implement reusable toggle components with info support
3. Ensure info panels can expand without shifting other content
4. Maintain all current functionality including typewriter animation
5. Support future extensibility for additional info panels
6. Clean up the visual hierarchy and spacing
7. Remove auto-refresh when encoding type changes
8. Leverage existing theme structure and ViewModifiers

## Theme Extensions

### New ViewModifiers for Settings

We'll create new ViewModifiers to extend the existing theme system for settings components:

```swift
// Add to ViewModifiers.swift
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

// Add to View extensions
extension View {
    func settingsToggleStyle(isSelected: Bool) -> some View {
        modifier(SettingsToggleStyle(isSelected: isSelected))
    }
    
    func settingsSectionStyle() -> some View {
        modifier(SettingsSectionStyle())
    }
}
```

## Component Architecture

### Core Components

#### 1. `SettingsSection`
A container for each main section with consistent styling:

```swift
struct SettingsSection: View {
    let title: String
    @ViewBuilder let content: () -> some View
    
    var body: some View {
        VStack(alignment: .center, spacing: 12) {
            Text(title)
                .settingsSectionStyle()
                .padding(.bottom, 5)
            
            content()
                .padding(.bottom, 8)
        }
        .padding(.vertical, 12)
    }
}
```

#### 2. `ToggleOptionRow`
A reusable toggle component for binary choices that supports optional info buttons:

```swift
struct ToggleOptionRow<T: Equatable>: View {
    let leftOption: (value: T, label: String)
    let rightOption: (value: T, label: String)
    @Binding var selection: T
    var showInfoButton: Bool = false
    var onInfoButtonTap: (() -> Void)? = nil
    var onSelectionChanged: (() -> Void)? = nil
    
    var body: some View {
        HStack {
            Spacer()
            
            // Left option button
            Button(action: {
                selection = leftOption.value
                onSelectionChanged?()
            }) {
                Text(leftOption.label)
                    .settingsToggleStyle(isSelected: selection == leftOption.value)
            }
            .buttonStyle(PlainButtonStyle())
            .accessibilityLabel("Switch to \(leftOption.label)")
            .padding(.trailing, 6)
            
            // Toggle arrow
            Button(action: {
                selection = selection == leftOption.value ? rightOption.value : leftOption.value
                onSelectionChanged?()
            }) {
                Image(systemName: selection == leftOption.value ? "arrow.right" : "arrow.left")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(CryptogramTheme.Colors.text)
            }
            .accessibilityLabel("Toggle between \(leftOption.label) and \(rightOption.label)")
            .padding(.horizontal, 6)
            
            // Right option button
            Button(action: {
                selection = rightOption.value
                onSelectionChanged?()
            }) {
                Text(rightOption.label)
                    .settingsToggleStyle(isSelected: selection == rightOption.value)
            }
            .buttonStyle(PlainButtonStyle())
            .accessibilityLabel("Switch to \(rightOption.label)")
            .padding(.leading, 6)
            
            Spacer()
            
            // Optional info button
            if showInfoButton {
                Button(action: {
                    onInfoButtonTap?()
                }) {
                    Text("i")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(CryptogramTheme.Colors.text)
                }
                .accessibilityLabel("Information")
                .padding(.trailing, 5)
            }
        }
        .frame(height: 44) // Fixed height for consistency
    }
}
```

#### 3. `MultiOptionRow`
A component for selections with more than two options:

```swift
struct MultiOptionRow<T: Hashable & Identifiable>: View {
    let options: [T]
    @Binding var selection: T
    var labelProvider: (T) -> String
    var showInfoButton: Bool = false
    var onInfoButtonTap: (() -> Void)? = nil
    var onSelectionChanged: (() -> Void)? = nil
    
    var body: some View {
        HStack {
            Spacer()
            
            // Multi-button implementation
            HStack(spacing: 12) {
                ForEach(options) { option in
                    Button(action: {
                        selection = option
                        onSelectionChanged?()
                    }) {
                        Text(labelProvider(option))
                            .settingsToggleStyle(isSelected: selection.id == option.id)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .accessibilityLabel("Switch to \(labelProvider(option))")
                }
            }
            
            Spacer()
            
            // Optional info button
            if showInfoButton {
                Button(action: {
                    onInfoButtonTap?()
                }) {
                    Text("i")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(CryptogramTheme.Colors.text)
                }
                .accessibilityLabel("Information")
                .padding(.trailing, 5)
            }
        }
        .frame(height: 44) // Fixed height for consistency
    }
}

// Alternative implementation using a dropdown/picker
struct DropdownOptionRow<T: Hashable & Identifiable>: View {
    let options: [T]
    @Binding var selection: T
    var labelProvider: (T) -> String
    var showInfoButton: Bool = false
    var onInfoButtonTap: (() -> Void)? = nil
    var onSelectionChanged: (() -> Void)? = nil
    
    var body: some View {
        HStack {
            Spacer()
            
            // Picker implementation
            Picker("", selection: $selection) {
                ForEach(options) { option in
                    Text(labelProvider(option))
                        .tag(option)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .onChange(of: selection) { _ in
                onSelectionChanged?()
            }
            .frame(maxWidth: 240)
            .accessibilityLabel("Select option")
            
            Spacer()
            
            // Optional info button
            if showInfoButton {
                Button(action: {
                    onInfoButtonTap?()
                }) {
                    Text("i")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(CryptogramTheme.Colors.text)
                }
                .accessibilityLabel("Information")
                .padding(.trailing, 5)
            }
        }
        .frame(height: 44) // Fixed height for consistency
    }
}
```

#### 4. `InfoPanel`
A component for displaying expandable info content with typewriter animation:

```swift
struct InfoPanel: View {
    let infoText: String
    @Binding var isVisible: Bool
    
    // Typewriter animation properties
    @State private var displayedInfoText = ""
    @State private var typingTimer: Timer?
    @State private var currentCharacterIndex = 0
    @State private var isTypingComplete = false
    let typingSpeed: Double = 0.04
    
    var body: some View {
        VStack {
            if isVisible {
                Text(attributedInfoText)
                    .font(.footnote)
                    .foregroundColor(CryptogramTheme.Colors.text)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .transition(.opacity)
                    .onAppear {
                        startTypewriterAnimation()
                    }
                    .onDisappear {
                        resetTypewriterAnimation()
                    }
            }
        }
        .frame(maxWidth: .infinity)
        .animation(.easeInOut(duration: 0.3), value: isVisible)
    }
    
    // Format the displayed text with bold words
    private var attributedInfoText: AttributedString {
        // Same implementation as current code
        guard !displayedInfoText.isEmpty else { return AttributedString("") }
        
        var attributed = AttributedString(displayedInfoText)
        
        // Find and bold specific words
        if let normalRange = displayedInfoText.range(of: "normal") {
            let nsNormalRange = NSRange(normalRange, in: displayedInfoText)
            let attributedRange = Range<AttributedString.Index>(nsNormalRange, in: attributed)!
            attributed[attributedRange].font = .boldSystemFont(ofSize: UIFont.systemFontSize)
        }
        
        if let expertRange = displayedInfoText.range(of: "expert") {
            let nsExpertRange = NSRange(expertRange, in: displayedInfoText)
            let attributedRange = Range<AttributedString.Index>(nsExpertRange, in: attributed)!
            attributed[attributedRange].font = .boldSystemFont(ofSize: UIFont.systemFontSize)
        }
        
        return attributed
    }
    
    // Start typing animation
    private func startTypewriterAnimation() {
        // Same implementation as current code
        displayedInfoText = ""
        currentCharacterIndex = 0
        isTypingComplete = false
        
        // Cancel any existing timer
        typingTimer?.invalidate()
        
        // Create a timer that adds one character at a time
        typingTimer = Timer.scheduledTimer(withTimeInterval: typingSpeed, repeats: true) { timer in
            if currentCharacterIndex < infoText.count {
                let index = infoText.index(infoText.startIndex, offsetBy: currentCharacterIndex)
                displayedInfoText += String(infoText[index])
                currentCharacterIndex += 1
            } else {
                timer.invalidate()
                typingTimer = nil
                isTypingComplete = true
            }
        }
    }
    
    private func resetTypewriterAnimation() {
        typingTimer?.invalidate()
        typingTimer = nil
        displayedInfoText = ""
        currentCharacterIndex = 0
        isTypingComplete = false
    }
}
```

#### 5. `IconToggleButton`
A specialized toggle button for icon-based toggles (like dark/light mode):

```swift
struct IconToggleButton: View {
    let iconName: String
    let isSelected: Bool
    let action: () -> Void
    let accessibilityLabel: String
    
    var body: some View {
        Button(action: action) {
            Image(systemName: iconName)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(isSelected ? 
                               CryptogramTheme.Colors.text : 
                               CryptogramTheme.Colors.text.opacity(0.4))
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel(accessibilityLabel)
    }
}
```

### Main View Structure

```swift
struct SettingsContentView: View {
    // Existing properties and bindings
    @AppStorage("encodingType") private var selectedEncodingType = "Letters"
    @AppStorage("isDarkMode") private var isDarkMode = false
    @EnvironmentObject private var puzzleViewModel: PuzzleViewModel
    @EnvironmentObject private var themeManager: ThemeManager
    @StateObject private var settingsViewModel = SettingsViewModel()
    
    // State properties for info panels
    @State private var showDifficultyInfo = false
    
    var body: some View {
        VStack(spacing: 20) {
            // Top spacing to position content as needed
            Spacer()
                .frame(height: 260)
            
            // Gameplay Section
            SettingsSection(title: "Gameplay") {
                VStack(spacing: 15) {
                    // Difficulty toggle with info support
                    ZStack(alignment: .top) {
                        VStack(spacing: 0) {
                            ToggleOptionRow(
                                leftOption: (DifficultyMode.normal, DifficultyMode.normal.displayName.lowercased()),
                                rightOption: (DifficultyMode.expert, DifficultyMode.expert.displayName.lowercased()),
                                selection: $settingsViewModel.selectedMode,
                                showInfoButton: true,
                                onInfoButtonTap: {
                                    withAnimation {
                                        showDifficultyInfo.toggle()
                                    }
                                }
                            )
                            
                            // Info panel for difficulty (fixed position)
                            InfoPanel(
                                infoText: "normal mode gives you some starting letters.\nexpert mode does not.",
                                isVisible: $showDifficultyInfo
                            )
                        }
                    }
                    
                    // Encoding toggle (no auto-refresh)
                    ToggleOptionRow(
                        leftOption: ("Letters", "ABC"),
                        rightOption: ("Numbers", "123"),
                        selection: $selectedEncodingType
                    )
                }
            }
            
            // Appearance Section
            SettingsSection(title: "Appearance") {
                VStack(spacing: 15) {
                    // Dark mode toggle with icons
                    HStack {
                        Spacer()
                        
                        // Light mode
                        IconToggleButton(
                            iconName: "sun.max",
                            isSelected: !isDarkMode,
                            action: {
                                if isDarkMode {
                                    isDarkMode = false
                                    themeManager.applyTheme()
                                }
                            },
                            accessibilityLabel: "Switch to Light mode"
                        )
                        .padding(.trailing, 6)
                        
                        // Toggle arrow
                        Button(action: {
                            isDarkMode.toggle()
                            themeManager.applyTheme()
                        }) {
                            Image(systemName: !isDarkMode ? "arrow.right" : "arrow.left")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(CryptogramTheme.Colors.text)
                        }
                        .accessibilityLabel("Toggle dark mode")
                        .padding(.horizontal, 6)
                        
                        // Dark mode
                        IconToggleButton(
                            iconName: "moon.stars",
                            isSelected: isDarkMode,
                            action: {
                                if !isDarkMode {
                                    isDarkMode = true
                                    themeManager.applyTheme()
                                }
                            },
                            accessibilityLabel: "Switch to Dark mode"
                        )
                        .padding(.leading, 6)
                        
                        Spacer()
                    }
                    
                    // Layout selection buttons - using multi-option approach
                    // Option 1: Keep the existing 3-button setup
                    MultiOptionRow(
                        options: NavigationBarLayout.allCases.sorted { $0.rawValue < $1.rawValue },
                        selection: $settingsViewModel.selectedNavBarLayout,
                        labelProvider: { $0.displayName }
                    )
                    
                    // Option 2: Use dropdown/segmented control
                    /*
                    DropdownOptionRow(
                        options: NavigationBarLayout.allCases.sorted { $0.rawValue < $1.rawValue },
                        selection: $settingsViewModel.selectedNavBarLayout,
                        labelProvider: { $0.displayName }
                    )
                    */
                }
            }
            
            Spacer() // Fill remaining space
        }
    }
}
```

## Implementation Plan

### Phase 1: Extend Theme System

1. Add new view modifiers for settings components to the existing ViewModifiers.swift:
   - `SettingsToggleStyle` - For styling toggle text
   - `SettingsSectionStyle` - For styling section headers
   
2. Ensure that these modifiers integrate with the existing theme system, using colors from CryptogramTheme

### Phase 2: Create Base Components

1. Create the new component files, leveraging the new ViewModifiers:
   - `SettingsSection.swift`
   - `ToggleOptionRow.swift`
   - `MultiOptionRow.swift` (and/or `DropdownOptionRow.swift`)
   - `InfoPanel.swift`
   - `IconToggleButton.swift`

2. Implement the base functionality for each component:
   - Apply proper styling using the new modifiers
   - Implement proper behavior and state management
   - Add accessibility labels

### Phase 3: Refactor Main View

1. Update the `SettingsContentView.swift` file:
   - Remove existing complex nested view structure
   - Add new state variables for info panel visibility
   - Implement the new section-based layout
   - Connect existing bindings to new components
   - Remove auto-refresh when encoding type changes

2. Refine the structure to use the new components:
   - Connect the difficulty toggle to the info panel
   - Implement the navigation bar layout using either MultiOptionRow or DropdownOptionRow
   - Ensure consistent spacing and alignment

### Phase 4: Implement Info Panel

1. Move typewriter animation logic to the `InfoPanel` component:
   - Extract existing animation code
   - Ensure proper animation triggers
   - Handle appearance/disappearance correctly

2. Set up the info panel to display without shifting layout:
   - Use fixed height containers
   - Implement smooth transitions

### Phase 5: Test and Refine

1. Test all functionality:
   - Verify toggles work correctly
   - Test info panel appearance and animation
   - Ensure dark mode toggle functions properly
   - Verify layout option selection works
   - Confirm encoding type changes don't auto-refresh

2. Polish animations and transitions:
   - Fine-tune timing
   - Test on different device sizes
   - Ensure no layout shifts occur

## Technical Considerations

### 1. Integration with Existing Theme
- Leverage the existing `CryptogramTheme` for colors and layout values
- Extend rather than replace the existing ViewModifiers
- Maintain consistency with the app's overall design language

### 2. Animation System
- Use SwiftUI's built-in animation system for transitions
- Combine with custom timers for typewriter effects
- Ensure animations don't cause layout shifts

### 3. Layout Stability
- Use fixed heights for toggles to prevent layout shifts
- Consider using `ZStack` with proper alignment for overlaying info content
- Implement proper transitions that don't affect surrounding content

### 4. Component Design
- Keep components focused on single responsibilities
- Use generics where appropriate to support different value types
- Make components reusable for future extension
- Provide flexibility for 2-option toggles vs multi-option selectors

### 5. State Management
- Use proper binding propagation
- Consider adding derived state properties for complex conditions
- Ensure state changes trigger appropriate UI updates
- Use onSelectionChanged callbacks instead of direct side effects

## Extension Points

The new architecture is designed to be extensible for future enhancements:

1. Additional Info Panels
   - The modular design allows adding info buttons to any toggle row
   - Each info panel can have unique content and styling

2. New Toggle Types
   - The generic toggle design supports different value types
   - Additional toggle varieties can be added with consistent styling

3. Multi-option Selectors
   - Both button group and dropdown approaches are provided
   - Can be extended to support additional layout options or different styling

4. Theming Improvements
   - Components use theme colors for consistent styling
   - Easy to update for new theme options

## Timeline

This refactoring can be completed in a single PR with the following timeline:

1. Phase 1 (Extend Theme System): 1 hour
2. Phase 2 (Base Components): 2 hours
3. Phase 3 (Main View): 2 hours
4. Phase 4 (Info Panel): 1 hour
5. Phase 5 (Testing/Refinement): 1-2 hours

Total estimated time: 7-8 hours of development work. 