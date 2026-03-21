# Daily Puzzle Widget — Scope

## What the widget does
- **Incomplete:** Shows "Incomplete" (or motivational prompt)
- **Completed:** Shows the decoded quote + author

## Current state
Daily puzzle progress is stored in `UserDefaults.standard` with keys like `dailyPuzzleProgress-2026-03-20`, as a JSON-encoded `DailyPuzzleProgress` struct. That struct has `isCompleted`, `userInputs`, timing data, etc. — but **does not** currently store the solution text or author. The solution lives only in the SQLite database.

## The main challenge: data sharing
Widget extensions run in a **separate process** and cannot access the app's `UserDefaults.standard`. The app has no App Group configured today. This means:

1. **An App Group is required** (e.g., `group.twRL.simple-cryptogram`) — shared container both the app and widget can access
2. **All daily progress reads/writes must move** from `UserDefaults.standard` to `UserDefaults(suiteName: "group.twRL.simple-cryptogram")`
3. **Existing users need a one-time migration** of their `dailyPuzzleProgress-*` keys to the new shared suite

## Refactoring needed (4 files)

| File | Change |
|---|---|
| `DailyPuzzleProgress.swift` | Add optional `solutionText: String?` and `author: String?` fields |
| `PuzzleViewModel.swift` | Switch to shared UserDefaults; include solution/author when saving; call `WidgetCenter.shared.reloadAllTimelines()` on completion |
| `ContinuousCalendarView.swift` | Switch 2 `UserDefaults.standard` reads to shared suite |
| `AppSettings.swift` | Switch `backfillCompletedDailyPuzzles()` to shared suite; add one-time migration |

## Why we don't need to share the database
By storing the solution text directly in `DailyPuzzleProgress`, the widget only needs shared UserDefaults — **no SQLite access, no extra dependencies**. This is much simpler and avoids concurrent database access between two processes.

## New files/targets needed
- **Widget Extension target** (`DailyPuzzleWidget`) — created via Xcode's File > New > Target > Widget Extension
- **Widget code** — `TimelineProvider`, entry struct, and SwiftUI view (~1 file)
- **Entitlements files** — for both the main app and widget (App Group capability)
- `DailyPuzzleProgress.swift` gets added to the widget target's compile sources (it's a simple Codable struct with no dependencies)

## Implementation order
1. Add App Group capability in Xcode (main app target)
2. Add `solutionText`/`author` to `DailyPuzzleProgress` (optional, backward-compatible)
3. Create a shared UserDefaults accessor constant
4. Update all 4 files to use shared UserDefaults
5. Add one-time migration from `.standard` → shared suite
6. Create widget extension target in Xcode + add App Group
7. Implement the widget (TimelineProvider + view)
8. Add `WidgetCenter.shared.reloadAllTimelines()` after daily save
9. Optional: deep link so tapping widget opens daily puzzle

## Risks/gotchas
- **Migration timing** — if widget loads before the app migrates data, it shows "Incomplete" for already-completed puzzles (minor, self-resolving)
- **Old completions** won't have `solutionText` stored (it'll be `nil`) — only affects puzzles completed before the update, which is fine since the widget only shows today's
- **App Group ID must match exactly** in both entitlements and be registered in your Apple Developer portal
- Step 1 (App Group) and step 6 (widget target creation) must be done manually in Xcode — can't be scripted
