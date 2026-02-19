# SwiftUI Best Practice Remediation

## 1. Remove `AnyView` type erasure in KeyboardView

**File:** `simple cryptogram/Views/KeyboardView.swift:90-97`

**Current:**
```swift
.background(
    isRemaining ? AnyView(
        RoundedRectangle(cornerRadius: 8)
            .fill(CryptogramTheme.Colors.success.opacity(0.2))
            .frame(width: keyHeight * 0.55, height: keyHeight * 0.7)
            .shadow(color: Color.black.opacity(0.13), radius: 2, x: 0, y: 1)
    ) : AnyView(Color.clear)
)
```

**Fix:** Use `@ViewBuilder` or conditional opacity:
```swift
.background(
    RoundedRectangle(cornerRadius: 8)
        .fill(CryptogramTheme.Colors.success.opacity(0.2))
        .frame(width: keyHeight * 0.55, height: keyHeight * 0.7)
        .shadow(color: Color.black.opacity(0.13), radius: 2, x: 0, y: 1)
        .opacity(isRemaining ? 1 : 0)
)
```

**Why:** `AnyView` defeats SwiftUI's diffing — causes unnecessary view identity resets and potential animation issues.

---

## 2. Replace deprecated `UIScreen.main.bounds`

**File:** `simple cryptogram/Views/PuzzleView.swift:232`

**Current:**
```swift
.frame(maxHeight: UIScreen.main.bounds.height * PuzzleViewConstants.Sizes.puzzleGridMaxHeightRatio)
```

**Fix:** Use `GeometryReader` to get available height:
```swift
// In PuzzleView body, wrap content or use a GeometryReader at the top level
GeometryReader { geometry in
    // ...
    .frame(maxHeight: geometry.size.height * PuzzleViewConstants.Sizes.puzzleGridMaxHeightRatio)
}
```

**Why:** `UIScreen.main` is deprecated in iOS 16+. `GeometryReader` provides the actual available space (respects multitasking, Dynamic Island, etc.).

---

## 3. Replace `DispatchQueue.main.asyncAfter` with structured concurrency

**File:** `simple cryptogram/Views/Components/PuzzleCell.swift:95-103`

**Current:**
```swift
DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
    withAnimation {
        if !effectiveCompleted {
            cellHighlightAmount = 0.0
        }
        animateCompletionBorder = false
    }
    onAnimationComplete?()
}
```

**Fix:**
```swift
Task { @MainActor in
    try? await Task.sleep(for: .seconds(0.3))
    withAnimation {
        if !effectiveCompleted {
            cellHighlightAmount = 0.0
        }
        animateCompletionBorder = false
    }
    onAnimationComplete?()
}
```

**Why:** `DispatchQueue.main.asyncAfter` is GCD/legacy pattern. `Task.sleep` integrates with structured concurrency and Swift's cooperative threading model.

---

## 4. Remove redundant ThemeManager UIKit appearance override

**File:** `simple cryptogram/Views/Theme/ThemeManager.swift:26-35`

**Current:** ThemeManager manually overrides UIKit window appearance:
```swift
func applyTheme() {
    setSystemAppearance(isDark: AppSettings.shared.isDarkMode)
}

private func setSystemAppearance(isDark: Bool) {
    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
       let window = windowScene.windows.first {
        window.overrideUserInterfaceStyle = isDark ? .dark : .light
    }
}
```

**But** `simple_cryptogramApp.swift:26` already does this the SwiftUI way:
```swift
.preferredColorScheme(appSettings.isDarkMode ? .dark : .light)
```

**Fix:** Remove `applyTheme()` and `setSystemAppearance()` from ThemeManager. The `.preferredColorScheme()` modifier is the correct SwiftUI approach and already handles it. ThemeManager then becomes just a toggle wrapper — consider whether it's still needed at all, or if `appSettings.isDarkMode` can be used directly.

---

## 5. Use `.sensoryFeedback()` modifier instead of `UINotificationFeedbackGenerator`

**File:** `simple cryptogram/Views/PuzzleView.swift:186-188, 198-199`

**Current:**
```swift
let generator = UINotificationFeedbackGenerator()
generator.notificationOccurred(.success)
```

**Fix:** Use the SwiftUI `.sensoryFeedback()` modifier (iOS 17+):
```swift
.sensoryFeedback(.success, trigger: viewModel.isComplete)
.sensoryFeedback(.error, trigger: viewModel.isFailed)
```

**Why:** Declarative, no UIKit import needed, automatically handles the feedback generator lifecycle. Attach to the ZStack or any view in PuzzleView body.

---

## Implementation Notes

- Items 1-5 are all independent of each other
- Item 1 touches KeyboardView.swift — coordinate with any keyboard visual changes
- Items 2-5 touch PuzzleView, PuzzleCell, ThemeManager, App — no keyboard overlap
- All are safe, non-breaking changes — no logic changes, just modernization
- Build and test after each change to verify no regressions
