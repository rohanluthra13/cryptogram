# Refactoring to a Single EnvironmentObject: Implementation Plan

## Core Purpose & What This Enables

The core purpose of this refactor is to establish a **single source of truth** for all shared app state (such as `PuzzleViewModel`, `ThemeManager`, and `SettingsViewModel`) using SwiftUI's `@EnvironmentObject` mechanism. This eliminates bugs and inconsistencies caused by multiple, out-of-sync model instances, and enables:
- **Consistent state and animation logic** across all screens, overlays, and modals
- **Simpler, more maintainable code** with less boilerplate and fewer manual dependencies
- **Easier scaling and feature addition** as the app grows
- **Preview-friendly architecture** for robust SwiftUI previews
- **Alignment with modern SwiftUI best practices**

---

## Why Refactor?
- **Current Problem:** Multiple instances of shared models (e.g., `PuzzleViewModel`, `ThemeManager`, `SettingsViewModel`) are created in different views (`App`, `ContentView`, `PuzzleView`, overlays, etc.), causing bugs such as missed animation triggers, inconsistent state, and unpredictable UI updates.
- **Best Practice:** SwiftUI apps should provide shared state at the root using `.environmentObject` and access it via `@EnvironmentObject` in all child views.

---

## Implementation Plan

### 1. **Audit and Identify All Shared Models and StateObject Usages**
- Locate all usages of `@StateObject` for **all shared models** (`PuzzleViewModel`, `ThemeManager`, `SettingsViewModel`) in views below the app root.
- Common candidates: `ContentView`, `PuzzleView`, overlays, modals, settings, and completion screens.
- Search for any `@ObservedObject` usages that should be replaced by `@EnvironmentObject` for shared models.

### 2. **Update Property Declarations**
- Change `@StateObject private var ...` to `@EnvironmentObject var ...` in all views except the app root (`@main` struct).
- Remove any initializers that create or inject new shared model instances in child views.
- If a view needs an initial value, pass it via function/environment, not by creating a new model instance.

### 3. **Remove Redundant Initializations**
- Delete code that creates new model instances (`PuzzleViewModel()`, `ThemeManager()`, etc.) in child views.
- Ensure overlays, sheets, and modals receive their environment objects from the root. If presented outside the main hierarchy, inject explicitly.

### 4. **Propagate EnvironmentObject to All Children**
- Ensure all subviews, overlays, and modals that need access to shared models use `@EnvironmentObject`.
- Remove unnecessary `.environmentObject()` modifiers in the view hierarchy (only needed at the root, unless previewing or presenting a new root).

### 5. **Update and Test SwiftUI Previews**
- For previews, inject `.environmentObject(...)` for each required model.
- For overlays, modals, and settings, ensure previews use a mock or default model to prevent crashes.
- Audit that all views using `@EnvironmentObject` have working previews.

### 6. **Test All User Interactions and State Consistency**
- Run the app and verify:
    - Animations trigger correctly on all user actions (tap, keyboard, hint, etc.)
    - State is consistent across all UI components, overlays, and modals
    - Settings, overlays, and completion screens reflect the correct state
- Use debug prints, breakpoints, or lightweight runtime assertions to confirm only one instance of each shared model exists at runtime.
- (Optional) Add automated tests to catch multiple instance creation.

### 7. **Legacy Code and Global State Audit**
- Audit for any legacy code, singletons, or global state that could conflict with the new architecture, and refactor or remove as needed.

---

## Modern SwiftUI Practices Emphasized
- **Single Source of Truth:** Root-level `.environmentObject` for shared state.
- **Minimal Boilerplate:** Avoid unnecessary view initializers or manual dependency passing.
- **Preview-Friendly:** Maintain previewability by injecting mocks as needed.
- **No Overkill:** Do not introduce unnecessary dependency injection frameworks or patterns unless the app grows significantly.

---

## Phasing and Context Considerations
- For a codebase of this size, this refactor can likely be done in a single pass, assuming a reasonable number of affected files (ContentView, PuzzleView, overlays, direct children, etc.).
- If the context window is exceeded, break the work into logical chunks:
    1. Refactor `ContentView`, `PuzzleView`, and root-level views.
    2. Update overlays, modals, settings, and completion views.
    3. Audit and fix all SwiftUI previews.
    4. Test and finalize.

---

## Summary
This refactor will:
- Eliminate bugs from multiple model instances
- Simplify state management and code maintenance
- Enable consistent, reliable state and animation logic across the entire app
- Make the codebase more robust, scalable, and aligned with top-tier SwiftUI architecture

**After this change, all state and animation logic will be consistent and reliable across the entire app.**
