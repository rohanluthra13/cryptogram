# Refactor & Scalability Implementation Plan

**Summary:** No large rewrite required. We’ll incrementally refactor for modularity, maintainability, and readiness for new features.

## 1. Modularize Architecture
- Extract domain logic from `PuzzleViewModel`:
  - `CryptogramMappingService`
  - `PuzzleSessionViewModel`
  - `StatsViewModel`
  - `AuthorViewModel` or `AuthorService`
- Define protocols (e.g. `PuzzleProgressStoreProtocol`) and inject concrete implementations.

- **Detailed Steps for Phase 1 – Modularize Architecture**
  1. Extract `CryptogramMappingService`  
     - Define `MappingServiceProtocol` in `Services/Protocols`  
     - Create `CryptogramMappingService.swift` under `Services/Mapping`  
     - Move `letterMapping`/`letterUsage` and encoding/decoding logic here  
     - Inject into `PuzzleSessionViewModel` and use in `PuzzleViewModel`  
  2. Create `PuzzleSessionViewModel`  
     - Create `PuzzleSessionViewModel.swift` in `ViewModels`  
     - Move session management (`startNewPuzzle`, `reset`, `togglePause`, `revealCell`, etc.)  
     - Expose `@Published var session` and helper methods  
     - Update `PuzzleView` to observe this VM instead of direct session  
  3. Build `StatsViewModel`  
     - Define `StatsViewModel` in `ViewModels`  
     - Inject `PuzzleProgressStoreProtocol`  
     - Migrate all stats/computed properties (`totalAttempts`, `winRatePercentage`, etc.)  
  4. Create `AuthorService`  
     - Define `AuthorServiceProtocol` in `Services/Protocols`  
     - Create `AuthorService.swift` in `Services/Author`  
     - Move `loadAuthorIfNeeded` and DB calls here as async `fetchAuthor(name:) async -> Author?`  
  5. Organize Protocols  
     - Create `Services/Protocols` folder  
     - Place `PuzzleProgressStoreProtocol`, `MappingServiceProtocol`, `AuthorServiceProtocol` here  
  6. Refactor `PuzzleViewModel`  
     - Inject the above services in its initializer  
     - Remove moved logic (`letterMapping`, `session` methods, stats, author loading)  
     - Simplify to orchestration only  

## 2. Migrate to Structured Concurrency
- Convert database fetch APIs to `async`/`await`.
- Remove unnecessary `AnyCancellable` in favor of async tasks.
- Annotate view models/services with `@MainActor`.

## 3. Adopt Modern SwiftUI Patterns
- Use `LazyVGrid` (or `Grid` on iOS 17) for puzzle grid layout.
- Replace manual `selectedCellIndex` with `@FocusState`.
- Simplify overlays via `.disabled()`/conditional `.opacity()` + `.zIndex`.
- Use `@Environment(\.scenePhase)` to auto‑pause/resume on background.

## 4. Code Conventions & Cleanup
- Rename types/files to PascalCase (e.g. `SimpleCryptogramApp`).
- Remove all `import UIKit` from SwiftUI code.
- Centralize `@AppStorage` keys in a struct or property wrapper.
- Localize user‑facing strings via `.strings` files.

## 5. Performance Optimizations
- Cache heavy computed properties (e.g. nonSymbol cell counts).
- Compute `wordGroups` on puzzle load; update incrementally.
- Avoid filtering full arrays each render.

## 6. Testing & Dependency Injection
- Define protocols for services & stores.
- Inject dependencies for easier mocking in tests.
- Cover view models/services with unit tests.

## 7. Theming & Styling
- Centralize colors/fonts in extensions or design tokens.
- Make `ThemeManager` pluggable for seasonal or custom puzzles.

## 8. Future‑Proofing
- Extract puzzles into a standalone framework for new types.
- Consider unidirectional data flow (e.g. TCA) for complex features.
- Plan for cloud sync/multiplayer by isolating state management.

## Proposed Timeline
- **Phase 1:** Conventions & cleanup (1–2 days)
- **Phase 2:** Modularization & DI (2–3 days)
- **Phase 3:** Async migration & SwiftUI patterns (2–3 days)
- **Phase 4:** Testing & theming (2 days)
- **Phase 5:** Future enhancements & cloud (ongoing)

---

Feel free to break down phases further or adjust priorities as needed.
