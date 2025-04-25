# Random Quote Widget Implementation Plan

## Overview
Add an iOS Home-Screen widget that displays a random quote from `quotes.db` on each refresh. The widget will be built with WidgetKit and SwiftUI, sharing data via an App Group.

## Dependencies & Setup

- **Database**: `quotes.db` in the shared container (App Group)
- **Models**: `Quote` struct mirroring `quotes` table schema
- **Data Access**: SQLite.swift wrapper (`QuoteStore.shared`) in shared container (leveraging existing SQLite.swift integration)
- **App Group**: Create and enable for both app & widget extension
- **Targets**: New Widget Extension target in Xcode

## Detailed Steps

1. Create Widget Extension
   - Xcode → File → New → Target → iOS → Widget Extension
   - Name: `RandomQuoteWidget`
   - Language: Swift, Interface: SwiftUI
   - Activate scheme for widget

2. Configure App Group
   - In project settings → Signing & Capabilities, add same App Group ID (e.g. `group.com.example.cryptogram`) to both app and widget
   - Move or copy `quotes.db` into `FileManager.default.containerURL(forSecurityApplicationGroupIdentifier:)`
   - On first launch of both app & widget, copy the bundled `quotes.db` into the App Group container and track a schema/version in UserDefaults to avoid overwriting migrations.

3. Shared Data Layer
   - Use `QuoteStore.shared` (SQLite.swift) pointing to `quotes.db` in the App Group container (no Core Data).
   - Implement `func fetchAllQuotes() -> [Quote]` via a simple `SELECT` query.
   - Wrap SQLite access on a serial dispatch queue for thread safety.
   - Inject `QuoteStore` into SwiftUI via an EnvironmentKey to enable previews & unit tests.

4. TimelineProvider Implementation
   - In `RandomQuoteWidget.swift`, update `TimelineProvider`:
     ```swift
     struct QuoteEntry: TimelineEntry {
       let date: Date
       let quote: Quote?
     }
     
     struct Provider: TimelineProvider {
       func placeholder(in:) -> QuoteEntry { /* static sample quote */ }
       func getSnapshot(in:, completion:) { /* quick fetch or cached quote */ }
       func getTimeline(in:, completion:) {
         let all: [Quote]
         do {
           all = try QuoteStore.shared.fetchAllQuotes()
         } catch {
           all = [] // Fallback on error
         }
         let random = all.randomElement()
         let entry = QuoteEntry(date: .now, quote: random)
         let midnight = Calendar.current.nextDate(after: .now, matching: DateComponents(hour: 0), matchingPolicy: .strict)!
         let timeline = Timeline(entries: [entry], policy: .after(midnight))
         completion(timeline)
       }
     }
     ```
   - Refresh policy: daily at midnight; custom intervals require IntentDefinition (optional future enhancement)
   - For live updates when the DB changes at runtime, call `WidgetCenter.shared.reloadAllTimelines()` after writes.

5. Widget View
   - Design `RandomQuoteWidgetEntryView: View`:
     ```swift
     VStack(alignment: .leading) {
       Text(entry.quote?.quoteText ?? "– No Quote –")
         .font(CryptogramTheme.Typography.body)
         .lineLimit(3)
       Spacer()
       Text(entry.quote?.author ?? "Unknown")
         .font(CryptogramTheme.Typography.footnote)
         .foregroundColor(CryptogramTheme.Colors.text)
     }
     .padding()
     .background(CryptogramTheme.Colors.background)
     ```
   - Add `widgetURL(_:)` to deep-link back into the puzzle/home view (e.g. `cryptogram://home`)
   - Consider deep-linking to the specific quote ID (e.g. `cryptogram://quote/<id>`) for precise navigation.

6. Widget Configuration
   - In `@main` widget struct, define `.systemSmall`, `.systemMedium`, etc.
   - Optionally support `.systemLarge` to display multiple quotes or a grid layout.
   - Supply `Provider()` and `RandomQuoteWidgetEntryView`

7. Preview & Testing
   - Add `PreviewProvider` with static entries for `.systemSmall` & `.systemMedium`
   - Run widget in simulator’s Gallery
   - Test App Group path by writing test quotes to shared DB

8. Release & UI Polish
   - Ensure colors use theme assets (e.g. `Color("WidgetBackground")`) so light (#f8f8f8) and dark variants match your CryptogramTheme.
   - Respect Dynamic Type with `.scaledFont()`, `.minimumScaleFactor(0.75)` and `.accessibilityLabel(...)`.
   - Localize static strings in `Localizable.strings`.
   - Add error logging/analytics for DB‐read failures and include a bundled JSON fallback so users don’t see an empty quote.

## File Mapping

- **DB Access**: `Sources/Common/QuoteStore.swift` (new)
- **Models**: `Sources/Common/Quote.swift` (new)
- **Widget**:
  - `RandomQuoteWidget.swift` (scaffolded)
  - `RandomQuoteWidgetEntryView.swift` (new)

## Summary
This plan sets up a WidgetKit extension that reads from your shared quotes database, picks a random quote each day at midnight, and renders it in a SwiftUI view. It covers App Group configuration, data access patterns, timeline updates, UI layout, previews, and testing to ensure a smooth integration into your Cryptogram app.
- Adds DB versioned copy, thread-safe store, injectable data layer, live & daily reload support, deep-link to individual quotes, theme reuse, and error logging/analytics.
