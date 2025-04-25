# Implementation Plan: Author Info Card in Puzzle Completion View

## Overview
This plan details how to integrate author summaries (from your new `authors` table) into the puzzle completion view. The goal is to allow users to view an "author info card" by tapping a button below the quote, with the card displaying the author's summary and related metadata. The solution is scalable for future author metadata (photo, links, etc.) and follows best iOS/MVVM practices.

---

## 1. Data Layer Changes

### 1.1. Define Author Model
- Create `Models/Author.swift`:

```swift
import Foundation

struct Author: Identifiable, Codable {
    let id: Int
    let name: String
    let fullName: String?
    let birthDate: String?
    let deathDate: String?
    let placeOfBirth: String?
    let placeOfDeath: String?
    let summary: String?
}
```

- Fields: `id`, `name`, `fullName`, `birthDate`, `deathDate`, `placeOfBirth`, `placeOfDeath`, `summary` (matching DB schema).

### 1.2. Extend DatabaseService
- Add a method to fetch an `Author` by name:
  - Query the `authors` table for the matching name.
  - Return an `Author?` instance.
- Add SQL index on `authors(name)`:

```sql
-- Data/migrations/01_add_index_authors.sql
CREATE INDEX IF NOT EXISTS idx_authors_name ON authors(name);
```

- Implement async fetch:

```swift
// Services/DatabaseService.swift
import SQLite3

extension DatabaseService {
    func fetchAuthor(byName name: String) async -> Author? {
        let sql = """
        SELECT id, name, full_name, birth_date, death_date,
               place_of_birth, place_of_death, summary
        FROM authors
        WHERE name = ?
        """
        // prepare stmt, bind name, step, map to Author, finalize
    }
}
```

### 1.3. Update PuzzleViewModel
- Add `@Published var currentAuthor: Author?` + caching.
- Load on tap or prefetch in `onAppear`:

```swift
// ViewModels/PuzzleViewModel.swift
class PuzzleViewModel: ObservableObject {
    @Published var currentAuthor: Author?
    private var lastAuthorName: String?

    func loadAuthorIfNeeded(name: String) {
        guard name != lastAuthorName else { return }
        lastAuthorName = name
        Task {
            let author = await databaseService.fetchAuthor(byName: name)
            DispatchQueue.main.async {
                self.currentAuthor = author
            }
        }
    }
}
```

---

## 2. UI Layer Changes

### 2.1. AuthorInfoView (transparent background)
- New `Views/Components/AuthorInfoView.swift`:

```swift
import SwiftUI

struct AuthorInfoView: View {
    let author: Author

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                Text(author.fullName ?? author.name)
                    .font(.headline)
                Text(author.summary ?? "No summary available")
                    .font(.body)
            }
            .padding()
            .onAppear {
                UIAccessibility.post(notification: .layoutChanged, argument: nil)
            }
        }
        .frame(maxHeight: UIScreen.main.bounds.height * 0.5)
    }
}
```

- Displays the author's full name, summary, and (optionally) other metadata.
- **Styling:** No background, outline, or shadow. Use theme colors and typography.
- Design for easy extension (e.g., add photo or links later).

### 2.2. PuzzleCompletionView integration
- Make the author’s name text (hint) tappable to reveal the author info inline.

```swift
// Views/Components/PuzzleCompletionView.swift
{{ existing completion view code }}

// Source/hint Text now handles tap
Text(processedSource)
    .font(.caption)
    .foregroundColor(CryptogramTheme.Colors.text)
    .fontWeight(isAuthorVisible ? .bold : .regular)
    .padding(.top, 4)
    .opacity(showAttribution ? 1 : 0)
    .onTapGesture {
        guard let name = viewModel.currentPuzzle?.authorName else { return }
        viewModel.loadAuthorIfNeeded(name: name)
        withAnimation { isAuthorVisible.toggle() }
    }

if isAuthorVisible, let author = viewModel.currentAuthor {
    AuthorInfoView(author: author)
        .transition(.move(edge: .bottom).combined(with: .opacity))
}

{{ ... }}

- Tap on the author name to toggle the `AuthorInfoView` inline (no modal).
- Animate appearance with slide+fade.
- Show only when `currentAuthor` is available.
- Ensure accessibility focus moves into the card when revealed.
{{ ... }}

---

## 3. Testing & QA

- Test with quotes that have and do not have author info.
- Ensure the UI works in both light and dark mode.
- Confirm that the info card does not disrupt the existing completion view animations or layout.
- (Optional) Add unit tests for the DB fetch logic.
- Unit test for `fetchAuthor(byName:)` logic.
- Snapshot tests for `AuthorInfoView` in light/dark and dynamic type.

---

## 4. Scalability & Future Enhancements

- The architecture supports adding more author metadata (photo, links, works, etc.).
- The `AuthorInfoView` can be reused elsewhere (e.g., author search, stats).
- The `DatabaseService` can be extended for batch queries or caching if needed.
- Renamed to `AuthorInfoView` for transparent style.
- Consider `AuthorInfoViewModel` if metadata grows.

---

## 5. File/Module Checklist
- [ ] `Models/Author.swift`
- [ ] `Data/migrations/01_add_index_authors.sql`
- [ ] `Services/DatabaseService.swift` – async `fetchAuthor(byName:)`
- [ ] `ViewModels/PuzzleViewModel.swift` – `currentAuthor` + `loadAuthorIfNeeded`
- [ ] `Views/Components/AuthorInfoView.swift`
- [ ] `Views/Components/PuzzleCompletionView.swift` – button + inline view

---

## 6. Rollout Steps
1. Implement the data layer changes.
2. Create the `AuthorInfoView` UI.
3. Integrate into the completion view.
4. Test and polish the UX.
5. Commit and review.

---

## 7. Optional: Refactoring
- If you plan to show more author info elsewhere, consider moving author logic to a dedicated view model or service.
- Review the theme system for any additional typography or color needs.

---

## End of Plan
