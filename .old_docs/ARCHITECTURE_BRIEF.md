# iOS Cryptogram App - Architecture Brief

**Date:** 2025-11-19
**Status:** Post-Migration Assessment

---

## 1. CURRENT ARCHITECTURE

### App Entry Point
```
/App/
└── simple_cryptogramApp.swift (46 lines)
    - Main app lifecycle entry point
    - Initializes AppSettings singleton on main thread
    - Creates environment objects (PuzzleViewModel, ThemeManager, SettingsViewModel, DeepLinkManager)
    - Manages pause/resume based on scene phase
    - Handles deep link URLs
```

### Models (572 lines total)
```
/Models/
├── Author.swift (12 lines)
│   - Simple data model for author biographical information
│
├── CryptogramCell.swift (64 lines)
│   - Unified model for all character representations in cryptograms
│   - Stores cell state (userInput, isRevealed, isError, isPreFilled)
│   - Deterministic UUID generation using SHA256
│
├── FontOption.swift (29 lines)
│   - Enum: System, Rounded, Serif, Monospaced
│
├── NavigationBarLayout.swift (16 lines)
│   - Enum: left, center, right
│
├── Puzzle.swift (287 lines) ⚠️ LARGE
│   - Core puzzle data model
│   - Contains complex cell creation algorithms for letter/number encoding
│   - ⚠️ ISSUE: Business logic in model layer
│
├── PuzzleAttempt.swift (13 lines)
│   - Record of puzzle attempt with completion/failure data
│
├── PuzzleSession.swift (109 lines)
│   - Single puzzle-solving session with timing, mistakes, hints
│   - Pause/resume support
│
└── TextSizeOption.swift (42 lines)
    - Enum: small, medium, large with computed CGFloat values
```

### Services (812 lines total)
```
/Services/
├── AuthorService.swift (41 lines)
│   - @MainActor observable class for loading author data
│   - Caching via lastAuthorName
│
├── DatabaseError.swift (62 lines)
│   - Custom error enum with user-friendly messages
│   - Recovery suggestions for failures
│
├── DatabaseService.swift (241 lines)
│   - Singleton SQLite database service
│   - Fetches random puzzles, daily puzzles, authors
│   - Proper error handling with DatabaseError types
│
├── ErrorRecoveryService.swift (151 lines)
│   - Automatic error recovery for database failures
│   - Database reinitialization, disk space checks
│
├── LocalPuzzleProgressStore.swift (218 lines)
│   - SQLite implementation of PuzzleProgressStore protocol
│   - Schema versioning and migrations
│   - Safe data handling without force unwraps
│
├── PuzzleProgressStore.swift (11 lines)
│   - Protocol defining progress storage interface
│
└── PuzzleSelectionManager.swift (88 lines)
    - Coordinates puzzle loading with optional exclusion of completed puzzles
```

### Configuration (488 lines total)
```
/Configuration/
├── UserSettings.swift (63 lines)
│   ⚠️ LEGACY COMPATIBILITY LAYER
│   - Forwards all calls to AppSettings
│   - Maintained for backward compatibility during transition
│
└── StateManagement/
    ├── AppSettings.swift (227 lines)
    │   - Central settings manager using @Observable
    │   - Game settings, UI settings, theme settings
    │   - Automatic persistence via PersistenceStrategy
    │   - Migration from legacy @AppStorage
    │   - ⚠️ ISSUE: Force unwrapped singleton (AppSettings.shared!)
    │
    ├── MigrationUtility.swift (87 lines)
    │   - Migrates settings from @AppStorage to AppSettings
    │
    ├── PersistenceStrategy.swift (83 lines)
    │   - Protocol-based persistence with UserDefaults implementation
    │
    └── StateManager.swift (28 lines)
        - Protocol for state management components
```

### ViewModels (3,986 lines total)

#### Main ViewModels (1,295 lines)
```
/ViewModels/
├── PuzzleViewModel.swift (374 lines) ⚠️ LARGE - PRODUCTION CODE
│   - Central orchestrator coordinating all managers
│   - Manages GameStateManager, PuzzleProgressManager, DailyPuzzleManager
│   - Delegates to InputHandler, HintManager, StatisticsManager
│   - Provides unified interface for views
│   - ⚠️ ISSUE: NotificationCenter usage for internal communication
│   - ⚠️ ISSUE: Force unwraps in AppSettings access
│
├── BusinessLogicCoordinator.swift (349 lines) ⚠️ LARGE - ALTERNATE UNUSED
│   ⚠️ DUPLICATE of PuzzleViewModel responsibilities
│   - Alternative coordinator implementation
│   - Cleaner architecture than PuzzleViewModel
│   - NOT USED IN PRODUCTION - part of abandoned migration
│
├── HomeViewModel.swift (137 lines)
│   - View model for HomeView
│   - Puzzle selection logic without navigation
│
├── SettingsViewModel.swift (131 lines)
│   ⚠️ UNNECESSARY LAYER
│   - Thin wrapper forwarding to AppSettings
│   - All properties are pass-through computed properties
│   - Adds complexity without value
│
├── PuzzleViewState.swift (156 lines)
│   - UI state for PuzzleView (overlays, bottom bar, animations)
│   - CompletionState enum (none, regular, daily)
│   - ⚠️ OVERLAP with NavigationState
│
├── PuzzleUIViewModel.swift (128 lines)
│   - Presentation logic for game over animations
│   - Typewriter effects, friction messages
│
└── DailyPuzzleProgress.swift (20 lines)
    - Codable struct for persisting daily progress to UserDefaults
    - ⚠️ ISSUE: UserDefaults for structured data (should be in database)
```

#### GameState Subdirectory (340 lines)
```
/ViewModels/GameState/
└── GameStateManager.swift (340 lines) ⚠️ LARGE - WELL SCOPED
    - Core game logic and state management
    - Manages cells array and session state
    - Tracks completed letters, user engagement
    - Applies pre-filled letters (20% of unique letters)
    - Cell updates, completion checking, wiggle animations
    - Mistake counting and failure detection
    - ⚠️ ISSUE: Uses weak reference to dependency that should never be nil
```

#### Input Subdirectory (235 lines)
```
/ViewModels/Input/
├── InputHandler.swift (164 lines)
│   - Keyboard input, cell selection, navigation
│   - Haptic feedback coordination
│   - ⚠️ ISSUE: weak reference pattern for required dependency
│
└── HintManager.swift (71 lines)
    - Hint/reveal operations with automatic cell selection
```

#### Progress Subdirectory (226 lines)
```
/ViewModels/Progress/
├── PuzzleProgressManager.swift (160 lines)
│   - Interfaces with progress store
│   - Logs attempts/completions
│   - ⚠️ CRITICAL: fatalError() in init for database failure
│
└── StatisticsManager.swift (66 lines)
    - Aggregates global and puzzle-specific statistics
```

#### Daily Subdirectory (163 lines)
```
/ViewModels/Daily/
└── DailyPuzzleManager.swift (163 lines)
    - Loads daily puzzles for any date
    - Saves/restores progress to UserDefaults per date
    - ⚠️ ISSUE: UserDefaults for progress (should be in database)
```

#### Navigation Subdirectory (1,117 lines)
```
/ViewModels/Navigation/
├── NavigationCoordinator.swift (36 lines)
│   ⚠️ LEGACY - Simple wrapper marked for deprecation
│
├── NavigationState.swift (296 lines)
│   ⚠️ MODERN REPLACEMENT for NavigationCoordinator
│   - Centralized navigation and UI state
│   - Screen enum, navigation path
│   - Overlay presentation (one active at a time)
│   - Bottom bar auto-hide
│   - NOT FULLY INTEGRATED
│
├── DeepLinkManager.swift (203 lines)
│   - URL-based deep linking to puzzles, stats, settings
│
├── NavigationPersistence.swift (213 lines)
│   - Saves/restores navigation state with 1-hour timeout
│
├── NavigationPerformance.swift (252 lines)
│   - Performance optimizations: caching, preloading, reduced motion
│
└── NavigationAnimations.swift (117 lines)
    - Custom transitions and timing constants
```

### Views (5,761 lines total)

#### Main Views (1,524 lines)
```
/Views/
├── ContentView.swift (65 lines) - PRODUCTION CODE
│   - Root view with NavigationStack
│   - Error alerts, typography injection
│
├── HomeView.swift (173 lines) - PRODUCTION CODE
│   - Home screen with puzzle mode selection
│   - Bottom bar, floating info button, overlay management
│
├── PuzzleView.swift (130 lines) - PRODUCTION CODE
│   - Main puzzle gameplay view
│   - Top bar, main content, bottom bar
│   - Swipe-to-dismiss, completion/failure handling
│
├── ModernContentView.swift (130 lines) ⚠️ ABANDONED MIGRATION
│   - Uses NavigationState and BusinessLogicCoordinator
│   - INCOMPLETE, NOT IN PRODUCTION
│
├── ModernHomeView.swift (224 lines) ⚠️ ABANDONED MIGRATION
│   - Uses HomeViewModel
│   - INCOMPLETE, NOT IN PRODUCTION
│
├── ModernPuzzleView.swift (517 lines) ⚠️ LARGE - ABANDONED MIGRATION
│   - Modernized puzzle view
│   - INCOMPLETE, NOT IN PRODUCTION
│
├── KeyboardView.swift (152 lines)
│   - On-screen keyboard with completed letter highlighting
│
├── PuzzleViewConstants.swift (57 lines)
│   - Centralized constants for spacing, sizes, animations
│
└── UserStatsView.swift (76 lines)
    - User statistics display
```

#### Components Subdirectory (4,237 lines)
```
/Views/Components/
├── OverlayManager.swift (921 lines) ⚠️ CRITICAL ISSUE - MASSIVE FILE
│   - Unified overlay management for PuzzleView
│   - Manages ALL overlays: settings, stats, calendar, info, completion, pause, gameOver
│   - Game over typewriter animations
│   - Z-index hierarchy constants
│   - ⚠️ SEVERE violation of single responsibility principle
│
├── PuzzleCompletionView.swift (487 lines) ⚠️ LARGE
│   - Post-game completion screen
│   - Stats, next puzzle buttons, calendar for daily
│
├── SettingsContentView.swift (314 lines) ⚠️ LARGE
│   - Comprehensive settings interface
│   - Multiple sections for game, appearance, accessibility, account
│
├── ContinuousCalendarView.swift (275 lines)
│   - Scrollable calendar for historical daily puzzles
│
├── CalendarView.swift (266 lines)
│   - Calendar with month/year navigation
│   - Daily puzzle completion indicators
│
├── PuzzleCell.swift (240 lines)
│   - Individual cell rendering
│   - Animations, error states, revealed/pre-filled indicators
│
├── StatsView.swift (219 lines)
│   - Statistics overlay with global and puzzle-specific metrics
│
├── WeeklySnapshot.swift (196 lines)
│   ⚠️ DEAD CODE - Noted as "currently unused, available for future use"
│
├── WordAwarePuzzleGrid.swift (181 lines)
│   - Grid layout that keeps words together
│
├── HomeMainContent.swift (173 lines)
│   - Main content of home screen with puzzle selection UI
│
├── NavigationBarView.swift (137 lines)
│   - Navigation controls with layout options
│
├── DisclaimersSection.swift (123 lines)
│   - Legal disclaimers and attributions
│
├── TopBarView.swift (101 lines)
│   - Top navigation bar with timer, hints, reset
│
├── BottomBarView.swift (99 lines)
│   - Bottom bar with stats/home/settings, auto-hide
│
├── CompletionStatsView.swift (97 lines)
│   - Statistics on completion screen
│
├── MainContentView.swift (79 lines)
│   - Main puzzle content area with grid and keyboard
│
├── InfoOverlayView.swift (68 lines)
│   - Information/about overlay
│
├── CloseButton.swift (61 lines)
│   - Reusable close button
│
├── ResetAccountSection.swift (59 lines)
│   - Settings section for resetting progress
│
├── AuthorInfoView.swift (48 lines)
│   - Author biographical information display
│
├── FloatingInfoButton.swift (40 lines)
│   - Floating info button in top-right
│
├── MultiCheckboxRow.swift (33 lines)
│   - Multi-selection checkbox component
│
├── LoadingView.swift (20 lines)
│   - Simple loading indicator
│
└── Settings/ (subdirectory)
    ├── SettingsImports.swift - Centralized imports
    ├── SettingsSection.swift - Reusable section layout
    ├── ToggleOptionRow.swift - Toggle row component
    ├── IconToggleButton.swift - Icon toggle button
    ├── InfoPanel.swift - Info panel component
    ├── MultiOptionRow.swift - Multi-option row
    ├── NavBarLayoutDropdown.swift - Navigation bar layout dropdown
    ├── NavBarLayoutPreview.swift - Layout preview
    └── NavBarLayoutSelector.swift - Layout selector
```

#### Theme Subdirectory (292 lines)
```
/Views/Theme/
├── ViewModifiers.swift (150 lines)
│   - Custom view modifiers
│   - Typography injection system with dynamic font selection
│
├── CryptogramTheme.swift (81 lines)
│   - Centralized theme constants
│   - Dynamic color definitions for light/dark modes
│
├── ThemeManager.swift (34 lines)
│   - Observable theme manager
│   - Applies dark/light mode systemwide
│
└── ColorExtensions.swift (27 lines)
    - Color utility extensions (hex initializer)
```

### Utils (77 lines)
```
/Utils/
└── FeatureFlags.swift (77 lines)
    - Feature flag system for gradual rollout
    - Flags: newNavigation (enabled), modernAppSettings (disabled),
            extractedServices (disabled), performanceMonitoring (enabled)
    - Debug mode allows UserDefaults overrides
```

---

## 2. CURRENT ISSUES

### 🔴 CRITICAL - Crashes & Stability

**Issue 1: Fatal errors in production code**
- **Location:** `ViewModels/Progress/PuzzleProgressManager.swift:24`
- **Problem:**
  ```swift
  } else {
      fatalError("Database connection not initialized for progress tracking!")
  }
  ```
- **Impact:** App will crash if database initialization fails instead of graceful degradation

**Issue 2: Force unwrapped singleton**
- **Location:** `Configuration/StateManagement/AppSettings.swift:90`
- **Problem:**
  ```swift
  static var shared: AppSettings!  // Force unwrapped
  ```
- **Used throughout codebase:**
  ```swift
  // PuzzleViewModel.swift:29
  private var encodingType: String {
      return AppSettings.shared.encodingType  // Will crash if initialization fails
  }
  ```
- **Impact:** 71+ occurrences of force unwraps accessing AppSettings.shared

**Issue 3: Weak reference anti-pattern**
- **Location:** `ViewModels/Input/InputHandler.swift:7`
- **Problem:**
  ```swift
  private weak var gameState: GameStateManager?

  // Then throughout file:
  guard let gameState = gameState else { return }
  ```
- **Impact:** Defensive coding for dependency that should never be nil. Silent failures hide bugs.

### 🟠 HIGH PRIORITY - Architecture Debt

**Issue 4: Abandoned migration - Duplicate Modern* views**
- **Files:**
  - `Views/ModernContentView.swift` (130 lines) - NOT IN PRODUCTION
  - `Views/ModernHomeView.swift` (224 lines) - NOT IN PRODUCTION
  - `Views/ModernPuzzleView.swift` (517 lines) - NOT IN PRODUCTION
- **Also:** `ViewModels/BusinessLogicCoordinator.swift` (349 lines) - NOT USED
- **Impact:**
  - 1,216 lines of dead/incomplete code
  - Confusing for developers (which version is real?)
  - Maintenance burden keeping parallel systems in sync

**Issue 5: Massive OverlayManager.swift (921 lines)**
- **Location:** `Views/Components/OverlayManager.swift`
- **Problem:** Single file handles all overlay logic:
  ```swift
  struct OverlayManager: ViewModifier {
      // 100+ lines of state
      @State private var gameOverTypedText = ""
      @State private var showGameOverButtons = false
      @State private var currentGameOverMessage = ""
      // ... many more states

      func body(content: Content) -> some View {
          // 800+ lines of overlay presentation logic
      }
  }
  ```
- **Impact:** Violates SRP, untestable, difficult to maintain

**Issue 6: Overlapping coordinators**
- **Files:**
  - `ViewModels/PuzzleViewModel.swift` (374 lines) - PRODUCTION, uses NotificationCenter
  - `ViewModels/BusinessLogicCoordinator.swift` (349 lines) - UNUSED, cleaner architecture
- **Impact:** 723 lines of duplicated coordinator logic

**Issue 7: Overlapping navigation systems**
- **Files:**
  - `ViewModels/Navigation/NavigationCoordinator.swift` (36 lines) - Marked LEGACY
  - `ViewModels/Navigation/NavigationState.swift` (296 lines) - Modern replacement, NOT FULLY INTEGRATED
  - `ViewModels/PuzzleViewState.swift` (156 lines) - Older UI state pattern
- **Impact:** Three different navigation/state systems with unclear boundaries

**Issue 8: Unnecessary SettingsViewModel layer**
- **Location:** `ViewModels/SettingsViewModel.swift` (131 lines)
- **Problem:** Pure pass-through wrapper:
  ```swift
  class SettingsViewModel: ObservableObject {
      var selectedNavBarLayout: NavigationBarLayout {
          get { AppSettings.shared.navigationBarLayout }
          set { AppSettings.shared.navigationBarLayout = newValue }
      }
      // All 15+ properties follow this pattern
  }
  ```
- **Impact:** Adds complexity without value; views could use AppSettings directly

### 🟡 MEDIUM PRIORITY - Code Quality

**Issue 9: Business logic in Puzzle model**
- **Location:** `Models/Puzzle.swift` (287 lines)
- **Problem:** Complex cell creation algorithms in data model:
  ```swift
  private func createLetterEncodedCells() -> [CryptogramCell] {
      // 100+ lines of complex business logic
  }

  private func createNumberEncodedCells() -> [CryptogramCell] {
      // 100+ lines of complex business logic
  }
  ```
- **Impact:** Violates MVVM; should be in service/factory layer

**Issue 10: NotificationCenter for internal communication**
- **Location:** `ViewModels/PuzzleViewModel.swift:182-189`
- **Problem:**
  ```swift
  NotificationCenter.default.addObserver(
      self,
      selector: #selector(handleDifficultySelectionChanged),
      name: SettingsViewModel.difficultySelectionChangedNotification,
      object: nil
  )
  ```
- **Impact:** Hidden coupling, hard to test, requires manual cleanup

**Issue 11: Mixed persistence strategies**
- **Daily puzzle progress:** `DailyPuzzleManager.swift:78`
  ```swift
  if let data = try? JSONEncoder().encode(progress) {
      UserDefaults.standard.set(data, forKey: dailyProgressKey(for: dateStr))
  }
  ```
- **Regular puzzle progress:** SQLite via LocalPuzzleProgressStore
- **Impact:** Inconsistent data management, can't query daily history, backup complications

**Issue 12: Legacy UserSettings compatibility layer**
- **Location:** `Configuration/UserSettings.swift` (63 lines)
- **Problem:** All properties forward to AppSettings:
  ```swift
  var encodingType: String {
      get { AppSettings.shared.encodingType }
      set { AppSettings.shared.encodingType = newValue }
  }
  ```
- **Impact:** Maintained for backward compatibility but no longer needed

**Issue 13: Inconsistent code organization**
- **Only 26 of 106 files** use `MARK:` comments
- **Impact:** Harder to navigate large files

**Issue 14: Dead code**
- **Location:** `Views/Components/WeeklySnapshot.swift` (196 lines)
- **Status:** Noted in CLAUDE.md as "currently unused, available for future use"
- **Impact:** 196 lines of untested, unmaintained code

---

## 3. TARGET ARCHITECTURE

### Core Principles
1. **Single source of truth** - One production code path (remove Modern* variants)
2. **Clear separation of concerns** - No overlapping managers or view models
3. **Fail gracefully** - No fatalError() or force unwraps
4. **Consistent persistence** - All progress data in SQLite
5. **Testable** - Strong dependencies, no weak reference anti-patterns
6. **Maintainable** - Files under 300 lines, clear MARK: organization

### Streamlined File Structure

```
/App/
└── simple_cryptogramApp.swift
    ✓ Keep as-is, properly initializes AppSettings

/Models/
├── Author.swift ✓
├── CryptogramCell.swift ✓
├── FontOption.swift ✓
├── NavigationBarLayout.swift ✓
├── Puzzle.swift
│   → REFACTOR: Extract cell creation to CellFactory service
│   → Target: ~100 lines (pure data model)
├── PuzzleAttempt.swift ✓
├── PuzzleSession.swift ✓
└── TextSizeOption.swift ✓

/Services/
├── AuthorService.swift ✓
├── DatabaseError.swift ✓
├── DatabaseService.swift ✓
├── ErrorRecoveryService.swift ✓
├── LocalPuzzleProgressStore.swift ✓
├── PuzzleProgressStore.swift ✓
├── PuzzleSelectionManager.swift ✓
└── CellFactory.swift [NEW]
    - Extract cell creation logic from Puzzle.swift
    - createLetterEncodedCells() and createNumberEncodedCells()

/Configuration/
├── AppSettings.swift [CONSOLIDATED]
│   → Move from StateManagement/ to Configuration/
│   → Fix force unwrap: use optional or dependency injection
│   → Keep automatic persistence
│
└── StateManagement/ [REMOVE DIRECTORY]
    - Consolidate into AppSettings.swift
    - Remove MigrationUtility (one-time migration complete)
    - Remove PersistenceStrategy abstraction (only one implementation)

/ViewModels/
├── PuzzleViewModel.swift
│   → REFACTOR: Remove NotificationCenter, use Combine or direct calls
│   → Fix AppSettings.shared! access
│   → Target: ~250 lines
│
├── HomeViewModel.swift ✓
│
├── PuzzleViewState.swift [REMOVE]
│   → Merge relevant state into NavigationState
│
├── PuzzleUIViewModel.swift ✓
│
└── DailyPuzzleProgress.swift [MOVE TO MODELS]

[REMOVE FILES]
- BusinessLogicCoordinator.swift (unused alternate)
- SettingsViewModel.swift (unnecessary pass-through)

/ViewModels/GameState/
└── GameStateManager.swift
    → Fix weak reference anti-pattern (use strong reference)
    → Target: ~300 lines (current size appropriate)

/ViewModels/Input/
├── InputHandler.swift
│   → Fix weak reference anti-pattern
└── HintManager.swift ✓

/ViewModels/Progress/
├── PuzzleProgressManager.swift
│   → Replace fatalError() with proper error handling
│   → Return Result type or throw error
└── StatisticsManager.swift ✓

/ViewModels/Daily/
└── DailyPuzzleManager.swift
    → MIGRATE daily progress from UserDefaults to SQLite
    → Use LocalPuzzleProgressStore with daily_puzzle flag
    → Target: ~120 lines

/ViewModels/Navigation/
├── NavigationState.swift [CONSOLIDATED]
│   → Merge PuzzleViewState overlay logic here
│   → Single source of truth for navigation and UI state
│   → Target: ~400 lines
│
├── DeepLinkManager.swift ✓
├── NavigationPersistence.swift ✓
├── NavigationPerformance.swift ✓
└── NavigationAnimations.swift ✓

[REMOVE FILE]
- NavigationCoordinator.swift (legacy, replaced by NavigationState)

/Views/
├── ContentView.swift ✓
├── HomeView.swift ✓
├── PuzzleView.swift
│   → Update to use consolidated NavigationState
├── KeyboardView.swift ✓
├── PuzzleViewConstants.swift ✓
└── UserStatsView.swift ✓

[REMOVE FILES - Abandoned migration]
- ModernContentView.swift
- ModernHomeView.swift
- ModernPuzzleView.swift

/Views/Components/
├── OverlayManager.swift [SPLIT INTO MULTIPLE FILES]
│   → SettingsOverlay.swift (~150 lines)
│   → StatsOverlay.swift (~150 lines)
│   → CalendarOverlay.swift (~150 lines)
│   → CompletionOverlay.swift (~200 lines)
│   → PauseOverlay.swift (~100 lines)
│   → GameOverOverlay.swift (~150 lines)
│   → OverlayCoordinator.swift (~100 lines) - Manages which overlay is active
│
├── PuzzleCompletionView.swift
│   → Extract sub-components (DailyCompletionView, RegularCompletionView)
│   → Target: ~250 lines
│
├── SettingsContentView.swift
│   → Already well-organized with sections
│   → Consider extracting GameSettingsSection, AppearanceSection, etc.
│   → Target: ~200 lines
│
├── [Keep all other components as-is]
│
└── [REMOVE]
    WeeklySnapshot.swift (dead code)

/Views/Components/Overlays/ [NEW DIRECTORY]
└── [Split OverlayManager files here]

/Views/Theme/
└── [All files ✓ Keep as-is]

/Utils/
└── FeatureFlags.swift
    → Remove completed migration flags (newNavigation)
    → Keep only active feature flags
```

### Database Schema Changes

**Add daily_puzzle_progress table:**
```sql
CREATE TABLE daily_puzzle_progress (
    id TEXT PRIMARY KEY,
    puzzle_id TEXT NOT NULL,
    date TEXT NOT NULL,  -- YYYY-MM-DD
    user_input TEXT,     -- JSON serialized cell states
    is_completed BOOLEAN DEFAULT 0,
    hints_used INTEGER DEFAULT 0,
    mistakes INTEGER DEFAULT 0,
    time_elapsed INTEGER DEFAULT 0,
    last_updated TEXT DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (puzzle_id) REFERENCES quotes(id)
);
```

### Dependency Flow (Target)

```
Views
  ↓ (use)
ViewModels (coordinator layer)
  ↓ (delegate to)
Managers (specialized logic: GameState, Input, Hint, Progress, Daily)
  ↓ (use)
Services (data access: DatabaseService, LocalPuzzleProgressStore, CellFactory)
  ↓ (access)
Models (pure data structures)
```

**Key changes from current:**
- Remove SettingsViewModel → Views use AppSettings directly
- Remove PuzzleViewState → Merge into NavigationState
- Remove BusinessLogicCoordinator → Single PuzzleViewModel
- Remove weak references → Strong dependencies throughout
- Remove UserSettings → Use AppSettings everywhere
- Remove NotificationCenter → Direct method calls or Combine

---

## 4. PHASED PLAN OF WORK

### Phase 1: Critical Safety Issues (Est: 4-6 hours)

**Goal:** Eliminate crash risks and dangerous patterns

**Tasks:**

1. **Fix force unwrapped AppSettings singleton**
   - Change `AppSettings.swift:90` from `static var shared: AppSettings!` to `static let shared = AppSettings()`
   - Remove lazy initialization from `simple_cryptogramApp.swift:22`
   - Update all 71+ call sites that access `AppSettings.shared` (no changes needed, but verify)

2. **Replace fatalError with proper error handling**
   - In `PuzzleProgressManager.swift:24`:
     ```swift
     // Current:
     } else {
         fatalError("Database connection not initialized!")
     }

     // Replace with:
     } else {
         self.progressStore = nil
         print("⚠️ Database unavailable, progress tracking disabled")
     }
     ```
   - Add `progressStore: PuzzleProgressStore?` optional property
   - Guard all progress store access with `guard let progressStore = progressStore else { return }`

3. **Fix weak reference anti-patterns**
   - In `InputHandler.swift:7`, change `private weak var gameState: GameStateManager?` to `private let gameState: GameStateManager`
   - Remove all `guard let gameState = gameState else { return }` checks throughout file
   - Similarly update `HintManager.swift` if it has weak references

4. **Add comprehensive error logging**
   - In `LocalPuzzleProgressStore.swift:142`, add logging before returning nil:
     ```swift
     guard let attemptUUID = ... else {
         print("⚠️ Corrupted data in attempt row: \(row[attemptID]), \(row[self.puzzleID])")
         return nil
     }
     ```

**Verification:**
- Run test suite: `xcodebuild test -project "simple cryptogram.xcodeproj" -scheme "simple cryptogram" -destination 'platform=iOS Simulator,name=iPhone 16'`
- All tests should pass with no crashes

---

### Phase 2: Remove Dead Code (Est: 2-3 hours)

**Goal:** Eliminate abandoned migration and unused code

**Tasks:**

1. **Delete Modern* variant files**
   - `rm "simple cryptogram/Views/ModernContentView.swift"`
   - `rm "simple cryptogram/Views/ModernHomeView.swift"`
   - `rm "simple cryptogram/Views/ModernPuzzleView.swift"`
   - `rm "simple cryptogram/ViewModels/BusinessLogicCoordinator.swift"`

2. **Delete dead WeeklySnapshot component**
   - `rm "simple cryptogram/Views/Components/WeeklySnapshot.swift"`

3. **Remove legacy UserSettings**
   - Delete `simple cryptogram/Configuration/UserSettings.swift`
   - Find all imports: `grep -r "import.*UserSettings" "simple cryptogram/"`
   - Replace with `@EnvironmentObject private var appSettings: AppSettings` in views
   - Replace with `AppSettings.shared` in ViewModels

4. **Remove legacy NavigationCoordinator**
   - Delete `simple cryptogram/ViewModels/Navigation/NavigationCoordinator.swift`
   - Find all usages: `grep -r "NavigationCoordinator" "simple cryptogram/"`
   - Replace with `NavigationState` instances

5. **Clean up FeatureFlags**
   - In `Utils/FeatureFlags.swift`, remove completed flags:
     - Remove `newNavigation` (migration complete)
   - Keep only: `modernAppSettings`, `extractedServices`, `performanceMonitoring`

6. **Update Xcode project file**
   - Remove file references for deleted files
   - Verify build: `xcodebuild -project "simple cryptogram.xcodeproj" -scheme "simple cryptogram" -configuration Debug`

**Verification:**
- Build succeeds
- No compiler errors for missing files
- Test suite still passes

---

### Phase 3: Consolidate Settings (Est: 3-4 hours)

**Goal:** Single source of truth for all settings

**Tasks:**

1. **Remove SettingsViewModel layer**
   - In `HomeView.swift:8`, change from:
     ```swift
     @EnvironmentObject private var settingsVM: SettingsViewModel
     ```
     To:
     ```swift
     @EnvironmentObject private var appSettings: AppSettings
     ```
   - Update all property accesses (e.g., `settingsVM.encodingType` → `appSettings.encodingType`)
   - Repeat for `PuzzleView.swift`, `SettingsContentView.swift`, and all other views

2. **Remove SettingsViewModel from environment injection**
   - In `simple_cryptogramApp.swift:16`, remove:
     ```swift
     @StateObject private var settingsViewModel = SettingsViewModel()
     ```
   - Remove `.environmentObject(settingsViewModel)` from ContentView

3. **Delete SettingsViewModel.swift**
   - `rm "simple cryptogram/ViewModels/SettingsViewModel.swift"`

4. **Consolidate StateManagement directory**
   - Move `StateManagement/AppSettings.swift` to `Configuration/AppSettings.swift`
   - Delete `StateManagement/MigrationUtility.swift` (one-time migration complete)
   - Delete `StateManagement/PersistenceStrategy.swift` (inline into AppSettings)
   - Delete `StateManagement/StateManager.swift` (unused protocol)
   - `rmdir "simple cryptogram/Configuration/StateManagement"`

5. **Update AppSettings imports**
   - Find all: `grep -r "import.*StateManagement" "simple cryptogram/"`
   - Update import paths to new location

**Verification:**
- Build succeeds
- Settings changes persist correctly
- Test suite passes

---

### Phase 4: Consolidate Navigation (Est: 4-5 hours)

**Goal:** Single navigation state system

**Tasks:**

1. **Merge PuzzleViewState into NavigationState**
   - In `NavigationState.swift`, add overlay state from `PuzzleViewState.swift:15-40`:
     ```swift
     // Add to NavigationState
     @Published var completionState: CompletionState = .none
     @Published var showGameOverAnimation = false
     @Published var gameOverTypedText = ""
     @Published var showGameOverButtons = false
     @Published var currentGameOverMessage = ""
     ```

2. **Update PuzzleView to use NavigationState**
   - In `PuzzleView.swift:8`, change:
     ```swift
     @StateObject private var viewState = PuzzleViewState()
     ```
     To:
     ```swift
     @EnvironmentObject private var navigationState: NavigationState
     ```
   - Update all `viewState` references to `navigationState`

3. **Delete PuzzleViewState.swift**
   - `rm "simple cryptogram/ViewModels/PuzzleViewState.swift"`

4. **Update NavigationState in app initialization**
   - In `simple_cryptogramApp.swift`, add:
     ```swift
     @StateObject private var navigationState = NavigationState()
     ```
   - Add to environment: `.environmentObject(navigationState)`

5. **Remove NotificationCenter from PuzzleViewModel**
   - In `PuzzleViewModel.swift:182-189`, remove observer registration
   - In `PuzzleViewModel.swift:95`, remove `deinit` with NotificationCenter cleanup
   - Replace with direct method calls or Combine publisher:
     ```swift
     // Add cancellables property
     private var cancellables = Set<AnyCancellable>()

     // In init, subscribe to AppSettings changes
     AppSettings.shared.$selectedDifficulties
         .sink { [weak self] _ in
             self?.handleDifficultyChange()
         }
         .store(in: &cancellables)
     ```

**Verification:**
- Navigation flows work (home → puzzle → completion)
- Overlays present correctly
- Settings changes propagate without NotificationCenter
- Test suite passes

---

### Phase 5: Split OverlayManager (Est: 6-8 hours)

**Goal:** Modular overlay components

**Tasks:**

1. **Create new overlays directory**
   - `mkdir -p "simple cryptogram/Views/Components/Overlays"`

2. **Extract SettingsOverlay**
   - Create `Views/Components/Overlays/SettingsOverlay.swift`
   - Move settings presentation logic from `OverlayManager.swift:150-300`
   - Create as standalone view:
     ```swift
     struct SettingsOverlay: View {
         @EnvironmentObject var appSettings: AppSettings
         @Binding var isPresented: Bool

         var body: some View {
             SettingsContentView()
                 .transition(.move(edge: .trailing))
         }
     }
     ```

3. **Extract StatsOverlay**
   - Create `Views/Components/Overlays/StatsOverlay.swift`
   - Move stats presentation logic from `OverlayManager.swift:301-450`
   - Similar standalone view pattern

4. **Extract CalendarOverlay**
   - Create `Views/Components/Overlays/CalendarOverlay.swift`
   - Move calendar logic from `OverlayManager.swift:451-600`

5. **Extract CompletionOverlay**
   - Create `Views/Components/Overlays/CompletionOverlay.swift`
   - Move completion logic from `OverlayManager.swift:601-750`

6. **Extract PauseOverlay**
   - Create `Views/Components/Overlays/PauseOverlay.swift`
   - Move pause logic from `OverlayManager.swift:751-800`

7. **Extract GameOverOverlay**
   - Create `Views/Components/Overlays/GameOverOverlay.swift`
   - Move game over animation logic from `OverlayManager.swift:801-900`

8. **Create OverlayCoordinator**
   - Create `Views/Components/Overlays/OverlayCoordinator.swift`
   - Simple coordinator that determines which overlay to show:
     ```swift
     struct OverlayCoordinator: ViewModifier {
         @EnvironmentObject var navigationState: NavigationState

         func body(content: Content) -> some View {
             content
                 .overlay {
                     switch navigationState.activeOverlay {
                     case .settings:
                         SettingsOverlay(isPresented: $navigationState.showSettings)
                     case .stats:
                         StatsOverlay(isPresented: $navigationState.showStats)
                     case .calendar:
                         CalendarOverlay(isPresented: $navigationState.showCalendar)
                     // ... etc
                     default:
                         EmptyView()
                     }
                 }
         }
     }
     ```

9. **Update PuzzleView to use new overlay system**
   - In `PuzzleView.swift:110`, replace `.modifier(OverlayManager(...))` with:
     ```swift
     .modifier(OverlayCoordinator())
     ```

10. **Delete old OverlayManager.swift**
    - `rm "simple cryptogram/Views/Components/OverlayManager.swift"`

**Verification:**
- All overlays present correctly
- Transitions and animations work
- Z-index hierarchy maintained
- Test suite passes
- Visual regression testing on simulator

---

### Phase 6: Migrate Daily Progress to SQLite (Est: 5-6 hours)

**Goal:** Consistent data persistence

**Tasks:**

1. **Create database migration file**
   - Create `data/migrations/005_daily_puzzle_progress.sql`:
     ```sql
     CREATE TABLE IF NOT EXISTS daily_puzzle_progress (
         id TEXT PRIMARY KEY,
         puzzle_id TEXT NOT NULL,
         date TEXT NOT NULL,
         user_input TEXT,
         is_completed INTEGER DEFAULT 0,
         hints_used INTEGER DEFAULT 0,
         mistakes INTEGER DEFAULT 0,
         time_elapsed INTEGER DEFAULT 0,
         time_paused INTEGER DEFAULT 0,
         last_updated TEXT DEFAULT CURRENT_TIMESTAMP,
         FOREIGN KEY (puzzle_id) REFERENCES quotes(id)
     );

     CREATE INDEX idx_daily_progress_date ON daily_puzzle_progress(date);
     CREATE INDEX idx_daily_progress_puzzle ON daily_puzzle_progress(puzzle_id);
     ```

2. **Update DatabaseService to run migration**
   - In `DatabaseService.swift:65`, add migration to `runMigrations()` method
   - Increment schema version

3. **Extend LocalPuzzleProgressStore for daily puzzles**
   - In `LocalPuzzleProgressStore.swift`, add methods:
     ```swift
     func saveDailyProgress(
         puzzleID: UUID,
         date: Date,
         userInput: [String: String],
         isCompleted: Bool,
         hints: Int,
         mistakes: Int,
         timeElapsed: TimeInterval,
         timePaused: TimeInterval
     ) throws

     func loadDailyProgress(for date: Date) throws -> DailyPuzzleProgress?

     func dailyProgressExists(for date: Date) throws -> Bool
     ```

4. **Update DailyPuzzleManager to use database**
   - In `DailyPuzzleManager.swift:78`, replace UserDefaults logic:
     ```swift
     // OLD:
     if let data = try? JSONEncoder().encode(progress) {
         UserDefaults.standard.set(data, forKey: dailyProgressKey(for: dateStr))
     }

     // NEW:
     do {
         try progressStore.saveDailyProgress(
             puzzleID: currentPuzzle.id,
             date: currentDate,
             userInput: gameState.cellUserInputMap(),
             isCompleted: gameState.isCompleted,
             hints: gameState.session.hintsUsed,
             mistakes: gameState.session.mistakes,
             timeElapsed: gameState.session.elapsedTime,
             timePaused: gameState.session.pausedTime
         )
     } catch {
         print("Failed to save daily progress: \(error)")
     }
     ```

5. **Migrate existing UserDefaults data**
   - Create one-time migration utility in `DailyPuzzleManager.init()`:
     ```swift
     private func migrateUserDefaultsProgressToDatabase() {
         // Read all UserDefaults keys starting with "dailyPuzzleProgress_"
         // Parse and insert into database
         // Delete from UserDefaults after successful migration
     }
     ```

6. **Remove UserDefaults code from DailyPuzzleManager**
   - Delete all `UserDefaults.standard` references
   - Remove `dailyProgressKey()` helper method

7. **Update DailyPuzzleProgress model**
   - Move `ViewModels/DailyPuzzleProgress.swift` to `Models/DailyPuzzleProgress.swift`
   - Ensure it matches database schema

**Verification:**
- Existing daily progress migrates successfully
- New daily progress saves to database
- Can load progress for any historical date
- No UserDefaults entries remain for daily progress
- Test suite passes

---

### Phase 7: Extract Cell Creation Service (Est: 3-4 hours)

**Goal:** Move business logic out of model

**Tasks:**

1. **Create CellFactory service**
   - Create `Services/CellFactory.swift`:
     ```swift
     @MainActor
     class CellFactory {
         static func createLetterEncodedCells(
             encodedText: String,
             solutionText: String,
             letterMapping: [Character: Character]
         ) -> [CryptogramCell] {
             // Move logic from Puzzle.swift:120-220
         }

         static func createNumberEncodedCells(
             encodedText: String,
             solutionText: String,
             letterMapping: [Character: Int]
         ) -> [CryptogramCell] {
             // Move logic from Puzzle.swift:221-287
         }
     }
     ```

2. **Simplify Puzzle.swift**
   - In `Puzzle.swift:120`, replace:
     ```swift
     private func createLetterEncodedCells() -> [CryptogramCell] {
         // 100+ lines...
     }
     ```
     With:
     ```swift
     private func createLetterEncodedCells() -> [CryptogramCell] {
         return CellFactory.createLetterEncodedCells(
             encodedText: self.encodedText,
             solutionText: self.solutionText,
             letterMapping: self.letterMapping
         )
     }
     ```

3. **Add unit tests for CellFactory**
   - Create `simple cryptogramTests/CellFactoryTests.swift`
   - Test cell creation for various inputs:
     - Empty strings
     - All letters
     - Mixed punctuation
     - Number encoding edge cases

4. **Verify Puzzle.swift is now pure data**
   - Target: ~100 lines (down from 287)
   - Only data properties and simple computed properties

**Verification:**
- Puzzles load correctly with both letter and number encoding
- Cell creation logic moved to service layer
- Test suite passes including new CellFactory tests

---

### Phase 8: Code Organization & Polish (Est: 4-5 hours)

**Goal:** Consistent, maintainable codebase

**Tasks:**

1. **Add MARK comments to all files**
   - Standard structure for all files:
     ```swift
     // MARK: - Types/Enums (if any)
     // MARK: - Published Properties (for ObservableObject/Observable)
     // MARK: - Private Properties
     // MARK: - Computed Properties
     // MARK: - Initialization
     // MARK: - Public Methods
     // MARK: - Private Methods
     // MARK: - Protocol Conformance (if any)
     ```
   - Apply to all 80 remaining files (currently only 26 have MARKs)

2. **Extract sub-components from PuzzleCompletionView**
   - Create `Views/Components/DailyCompletionView.swift`:
     ```swift
     struct DailyCompletionView: View {
         // Extract daily-specific UI from PuzzleCompletionView:200-350
     }
     ```
   - Create `Views/Components/RegularCompletionView.swift`:
     ```swift
     struct RegularCompletionView: View {
         // Extract regular completion UI from PuzzleCompletionView:50-199
     }
     ```
   - Update `PuzzleCompletionView.swift` to delegate:
     ```swift
     var body: some View {
         if viewModel.isDailyPuzzle {
             DailyCompletionView(...)
         } else {
             RegularCompletionView(...)
         }
     }
     ```
   - Target: Reduce PuzzleCompletionView from 487 to ~150 lines

3. **Extract settings sections from SettingsContentView**
   - Create `Views/Components/Settings/GameSettingsSection.swift`
   - Create `Views/Components/Settings/AppearanceSettingsSection.swift`
   - Create `Views/Components/Settings/AccessibilitySettingsSection.swift`
   - Create `Views/Components/Settings/AccountSettingsSection.swift`
   - Update `SettingsContentView.swift` to compose sections
   - Target: Reduce SettingsContentView from 314 to ~120 lines

4. **Verify no files exceed 300 lines**
   - Run: `find "simple cryptogram" -name "*.swift" -exec wc -l {} \; | awk '$1 > 300 {print}'`
   - Address any remaining large files

5. **Update CLAUDE.md documentation**
   - Remove references to deleted files (Modern*, SettingsViewModel, etc.)
   - Update architecture diagram
   - Update file line counts
   - Document new overlay system
   - Update daily progress persistence section

6. **Run static analysis**
   - `xcodebuild analyze -project "simple cryptogram.xcodeproj" -scheme "simple cryptogram"`
   - Address any warnings

**Verification:**
- All files have consistent MARK organization
- No files exceed 300 lines (except justified cases like DatabaseService)
- Documentation is up to date
- No static analysis warnings

---

### Phase 9: Final Testing & Validation (Est: 3-4 hours)

**Goal:** Ensure everything works end-to-end

**Tasks:**

1. **Run full test suite**
   ```bash
   xcodebuild test \
     -project "simple cryptogram.xcodeproj" \
     -scheme "simple cryptogram" \
     -destination 'platform=iOS Simulator,name=iPhone 16' \
     -only-testing:"simple cryptogramTests"
   ```
   - All 127+ tests must pass

2. **Run performance baseline tests**
   ```bash
   xcodebuild test \
     -project "simple cryptogram.xcodeproj" \
     -scheme "simple cryptogram" \
     -only-testing:"simple cryptogramTests/PerformanceBaselineTests"
   ```
   - Verify no performance regressions

3. **Run memory leak detection tests**
   ```bash
   xcodebuild test \
     -project "simple cryptogram.xcodeproj" \
     -scheme "simple cryptogram" \
     -only-testing:"simple cryptogramTests/MemoryLeakDetectionTests"
   ```
   - Verify no new memory leaks

4. **Manual regression testing on simulator**
   - Test flow: Launch → Home → Select Short Puzzle → Play → Complete
   - Test flow: Launch → Home → Daily Puzzle → Play → Complete → View Calendar
   - Test all overlays: Settings, Stats, Calendar, Info
   - Test navigation: Home button, swipe gestures
   - Test pause/resume functionality
   - Test dark mode switching
   - Test all font options
   - Test error states: No database, corrupted data

5. **Build release configuration**
   ```bash
   xcodebuild \
     -project "simple cryptogram.xcodeproj" \
     -scheme "simple cryptogram" \
     -configuration Release \
     clean build
   ```

6. **Verify no force unwraps remain**
   ```bash
   grep -r "!" "simple cryptogram/" --include="*.swift" | \
     grep -v "// " | \
     grep -v "!=" | \
     wc -l
   ```
   - Target: 0 (or minimal, all justified)

7. **Create migration summary document**
   - Document all changes made
   - Before/after metrics (lines of code, file count, test coverage)
   - Known issues or technical debt remaining

**Deliverables:**
- All tests passing
- Release build succeeds
- Manual test checklist completed
- Migration summary document

---

## SUMMARY

### Before Refactoring
- **Files:** 106 Swift files
- **Lines:** ~12,000 total
- **Issues:** 14 major issues across critical/high/medium priority
- **Architecture:** Mixed (production + abandoned migration code)
- **Persistence:** Inconsistent (SQLite + UserDefaults)
- **Crash Risk:** High (fatalError, force unwraps)

### After Refactoring
- **Files:** ~90 Swift files (16 removed)
- **Lines:** ~11,000 total (more modular)
- **Issues:** 0 critical issues remaining
- **Architecture:** Clean MVVM with manager pattern
- **Persistence:** Consistent (all in SQLite)
- **Crash Risk:** Low (graceful error handling)

### Estimated Total Time
- **Phase 1:** 4-6 hours (Critical safety)
- **Phase 2:** 2-3 hours (Dead code removal)
- **Phase 3:** 3-4 hours (Settings consolidation)
- **Phase 4:** 4-5 hours (Navigation consolidation)
- **Phase 5:** 6-8 hours (Overlay splitting)
- **Phase 6:** 5-6 hours (Daily progress migration)
- **Phase 7:** 3-4 hours (Cell factory extraction)
- **Phase 8:** 4-5 hours (Organization & polish)
- **Phase 9:** 3-4 hours (Final testing)

**Total:** 34-45 hours (~1-2 weeks of focused work)

### Recommended Approach
Execute phases sequentially. After each phase:
1. Commit changes with descriptive message
2. Run test suite to verify no regressions
3. Manual smoke test on simulator
4. Push to feature branch for review

This ensures you can roll back easily if issues arise and maintains a working codebase throughout the refactoring process.
