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
                .font(.subheadline)
                .foregroundColor(CryptogramTheme.Colors.text)
                .frame(maxWidth: .infinity, alignment: .center)
            
            content()
                .padding(.bottom, 8)
        }
        .padding(.vertical, 12)
    }
}
```

#### 2. `ToggleOptionRow`
A reusable toggle component that supports optional info buttons:

```swift
struct ToggleOptionRow<T: Equatable>: View {
    let leftOption: (value: T, label: String)
    let rightOption: (value: T, label: String)
    @Binding var selection: T
    var showInfoButton: Bool = false
    var onInfoButtonTap: (() -> Void)? = nil
    
    var body: some View {
        HStack {
            Spacer()
            
            // Left option button
            Button(action: {
                selection = leftOption.value
            }) {
                Text(leftOption.label)
                    .font(.footnote)
                    .fontWeight(selection == leftOption.value ? .bold : .regular)
                    .foregroundColor(selection == leftOption.value ? 
                                   CryptogramTheme.Colors.text : 
                                   CryptogramTheme.Colors.text.opacity(0.4))
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.trailing, 6)
            
            // Toggle arrow
            Button(action: {
                selection = selection == leftOption.value ? rightOption.value : leftOption.value
            }) {
                Image(systemName: selection == leftOption.value ? "arrow.right" : "arrow.left")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(CryptogramTheme.Colors.text)
            }
            .padding(.horizontal, 6)
            
            // Right option button
            Button(action: {
                selection = rightOption.value
            }) {
                Text(rightOption.label)
                    .font(.footnote)
                    .fontWeight(selection == rightOption.value ? .bold : .regular)
                    .foregroundColor(selection == rightOption.value ? 
                                   CryptogramTheme.Colors.text : 
                                   CryptogramTheme.Colors.text.opacity(0.4))
            }
            .buttonStyle(PlainButtonStyle())
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
                .padding(.trailing, 5)
            }
        }
        .frame(height: 44) // Fixed height for consistency
    }
}
```

#### 3. `InfoPanel`
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

#### 4. `IconToggleButton`
A specialized toggle button for icon-based toggles (like dark/light mode):

```swift
struct IconToggleButton: View {
    let iconName: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: iconName)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(isSelected ? 
                               CryptogramTheme.Colors.text : 
                               CryptogramTheme.Colors.text.opacity(0.4))
        }
        .buttonStyle(PlainButtonStyle())
    }
}
```

### Main View Structure

```swift
struct SettingsContentView: View {
    // Existing properties and bindings
    
    // New state properties for info panels
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
                    
                    // Encoding toggle
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
                            }
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
                            }
                        )
                        .padding(.leading, 6)
                        
                        Spacer()
                    }
                    
                    // Layout selection buttons
                    ToggleOptionRow(
                        leftOption: (NavBarLayout.leftLayout, "Left"),
                        rightOption: (NavBarLayout.rightLayout, "Right"),
                        selection: $settingsViewModel.selectedNavBarLayout
                    )
                }
            }
            
            Spacer() // Fill remaining space
        }
    }
}
```

## Implementation Plan

### Phase 1: Setup Base Components

1. Create the new component files:
   - `SettingsSection.swift`
   - `ToggleOptionRow.swift`
   - `InfoPanel.swift`
   - `IconToggleButton.swift`

2. Implement the base functionality for each component as outlined above
   - Ensure components maintain fixed heights where needed
   - Implement proper styling and theming
   - Set up animation hooks

### Phase 2: Refactor Main View

1. Update the `SettingsContentView.swift` file:
   - Remove existing complex nested view structure
   - Add new state variables for info panel visibility
   - Implement the new section-based layout
   - Connect existing bindings to new components

2. Refine the structure to use the new components:
   - Connect the difficulty toggle to the info panel
   - Set up proper layout constraints
   - Ensure all existing functionality is preserved

### Phase 3: Implement Info Panel

1. Move typewriter animation logic to the `InfoPanel` component:
   - Extract existing animation code
   - Ensure proper animation triggers
   - Handle appearance/disappearance correctly

2. Set up the info panel to display without shifting layout:
   - Use fixed height containers
   - Implement smooth transitions

### Phase 4: Test and Refine

1. Test all functionality:
   - Verify toggles work correctly
   - Test info panel appearance and animation
   - Ensure dark mode toggle functions properly
   - Verify layout option selection works

2. Polish animations and transitions:
   - Fine-tune timing
   - Test on different device sizes
   - Ensure no layout shifts occur

## Technical Considerations

### 1. Animation System
- Use SwiftUI's built-in animation system for transitions
- Combine with custom timers for typewriter effects
- Ensure animations don't cause layout shifts

### 2. Layout Stability
- Use fixed heights for toggles to prevent layout shifts
- Consider using `ZStack` with proper alignment for overlaying info content
- Implement proper transitions that don't affect surrounding content

### 3. Component Design
- Keep components focused on single responsibilities
- Use generics where appropriate to support different value types
- Make components reusable for future extension

### 4. State Management
- Use proper binding propagation
- Consider adding derived state properties for complex conditions
- Ensure state changes trigger appropriate UI updates

## Extension Points

The new architecture is designed to be extensible for future enhancements:

1. Additional Info Panels
   - The modular design allows adding info buttons to any toggle row
   - Each info panel can have unique content and styling

2. New Toggle Types
   - The generic toggle design supports different value types
   - Additional toggle varieties can be added with consistent styling

3. Theming Improvements
   - Components use theme colors for consistent styling
   - Easy to update for new theme options

## Timeline

This refactoring can be completed in a single PR with the following timeline:

1. Phase 1 (Base Components): 2-3 hours
2. Phase 2 (Main View): 2-3 hours
3. Phase 3 (Info Panel): 1-2 hours
4. Phase 4 (Testing/Refinement): 1-2 hours

Total estimated time: 6-10 hours of development work. 