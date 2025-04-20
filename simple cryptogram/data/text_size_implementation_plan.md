# Text Size Implementation Plan

This plan outlines steps to add user‑selectable text size options (Small, Medium, Large) for puzzle cells.

## 1. Define TextSizeOption enum
- Create a new file `Models/TextSizeOption.swift` with:

```swift
import SwiftUI

enum TextSizeOption: String, CaseIterable, Identifiable {
  case small, medium, large
  var id: String { rawValue }

  var inputSize: CGFloat {
    switch self {
    case .small:  return 13
    case .medium: return 15
    case .large:  return 17
    }
  }

  var encodedSize: CGFloat {
    switch self {
    case .small:  return 10
    case .medium: return 12
    case .large:  return 14
    }
  }
}
```

## 2. Add AppStorage binding
- In `ViewModels/SettingsViewModel.swift` (create if needed):

```swift
import SwiftUI

class SettingsViewModel: ObservableObject {
  @AppStorage("textSize") private var textSizeRaw: String = TextSizeOption.small.rawValue
  @Published var textSize: TextSizeOption {
    get { TextSizeOption(rawValue: textSizeRaw) ?? .small }
    set { textSizeRaw = newValue.rawValue }
  }
}
```
- Inject into `SettingsContentView` and `PuzzleView` via `.environmentObject(SettingsViewModel())`.

## 3. Update Settings UI
- In `Views/Components/SettingsContentView.swift`, add a new section:

```swift
Section(header: Text("Text Size")) {
  Picker("Text Size", selection: $settingsVM.textSizeRaw) {
    ForEach(TextSizeOption.allCases) { opt in
      Text(opt.rawValue.capitalized).tag(opt.rawValue)
    }
  }
  .pickerStyle(.segmented)
}
```

## 4. Apply in PuzzleCell
- In `Views/Components/PuzzleCell.swift`:
  - Inject `@EnvironmentObject var settingsVM: SettingsViewModel`.
  - Replace hard‑coded fonts:

```swift
Text(cell.userInput)
  .font(.system(size: settingsVM.textSize.inputSize,
                weight: .medium,
                design: .monospaced))

Text(cell.encodedChar)
  .font(.system(size: settingsVM.textSize.encodedSize,
                weight: .medium,
                design: .monospaced))
```

## 5. (Optional) Integrate with CryptogramTheme
- Optionally, add dynamic typography in `CryptogramTheme.Typography` to reference `TextSizeOption` values.

## 6. Testing
- Verify the picker updates font sizes in real time.
- Add UI tests to assert correct font sizes for each option.
