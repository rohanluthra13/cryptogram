import SwiftUI

private enum QuotebookLayout { case carousel, list }
private enum QuotebookSort { case author, length, shuffle }
private enum FilterSection { case sort, filter }

struct QuotebookView: View {
    @Environment(AppSettings.self) private var appSettings
    @Environment(\.typography) private var typography

    @State private var quotes: [QuoteMetadata] = []
    @State private var currentPage: Int = 0
    @State private var layout: QuotebookLayout = .carousel
    @State private var sortMode: QuotebookSort = .author
    @State private var selectedLengths: Set<String> = ["easy", "medium", "hard"]
    @State private var selectedAuthor: String? = nil
    @State private var shuffledOrder: [QuoteMetadata] = []
    @State private var sortAscending = true
    @State private var expandedSection: FilterSection? = nil
    @State private var hapticTrigger = 0

    private var completedQuotes: [QuoteMetadata] {
        quotes.filter { appSettings.completedQuoteIds.contains($0.id) }
    }

    private var uniqueAuthors: [String] {
        Array(Set(completedQuotes.map(\.author))).sorted()
    }

    private var displayedQuotes: [QuoteMetadata] {
        var result = completedQuotes
            .filter { selectedLengths.contains($0.difficulty) }

        if let author = selectedAuthor {
            result = result.filter { $0.author == author }
        }

        switch sortMode {
        case .author:
            result.sort {
                if $0.author != $1.author {
                    return sortAscending ? $0.author < $1.author : $0.author > $1.author
                }
                return $0.id < $1.id
            }
        case .length:
            result.sort {
                if $0.length != $1.length {
                    return sortAscending ? $0.length < $1.length : $0.length > $1.length
                }
                return $0.author < $1.author
            }
        case .shuffle:
            let ids = Set(result.map(\.id))
            let ordered = shuffledOrder.filter { ids.contains($0.id) }
            if ordered.count == result.count {
                result = ordered
            }
        }

        return result
    }

    var body: some View {
        VStack(spacing: 0) {
            if completedQuotes.isEmpty {
                Spacer(minLength: 85)
                emptyState
            } else {
                // Fixed icon bar just below close button
                iconBar
                    .padding(.top, 85)
                    .padding(.bottom, 8)

                // Expandable sections (sort / filter)
                if expandedSection != nil {
                    filterPanel
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }

                Spacer().frame(height: 25)

                // Content
                if displayedQuotes.isEmpty {
                    noMatchesState
                } else if layout == .carousel {
                    carousel
                } else {
                    listView
                }
            }

            Spacer()

            if quotes.count > 0 {
                Text("\(completedQuotes.count) completed")
                    .font(typography.caption)
                    .foregroundColor(CryptogramTheme.Colors.text.opacity(0.3))
                    .padding(.bottom, 40)
            }
        }
        .onAppear {
            loadQuotes()
        }
    }

    // MARK: - Controls

    private var hasActiveFilters: Bool {
        selectedLengths.count < 3 || selectedAuthor != nil
    }

    private var iconBar: some View {
        VStack(spacing: 10) {
            // Layout icons left-aligned
            HStack(spacing: 16) {
                IconToggleButton(
                    iconName: "rectangle.on.rectangle",
                    isSelected: layout == .carousel,
                    action: { layout = .carousel },
                    accessibilityLabel: "Carousel layout"
                )
                IconToggleButton(
                    iconName: "list.bullet",
                    isSelected: layout == .list,
                    action: { layout = .list },
                    accessibilityLabel: "List layout"
                )
                Spacer()
            }
            .padding(.horizontal, 32)

            // Sort by (left) / Filter (right)
            HStack {
                Button(action: {
                    hapticTrigger += 1
                    withAnimation(.easeInOut(duration: 0.2)) {
                        expandedSection = expandedSection == .sort ? nil : .sort
                    }
                }) {
                    Text("sort by")
                        .settingsToggleStyle(isSelected: expandedSection == .sort)
                }
                .buttonStyle(PlainButtonStyle())
                .sensoryFeedback(.impact(flexibility: .soft, intensity: 0.5), trigger: hapticTrigger)

                Spacer()

                Button(action: {
                    hapticTrigger += 1
                    withAnimation(.easeInOut(duration: 0.2)) {
                        expandedSection = expandedSection == .filter ? nil : .filter
                    }
                }) {
                    HStack(spacing: 4) {
                        Text("filter")
                            .settingsToggleStyle(isSelected: expandedSection == .filter || hasActiveFilters)
                        if hasActiveFilters {
                            Circle()
                                .fill(CryptogramTheme.Colors.text)
                                .frame(width: 4, height: 4)
                        }
                    }
                }
                .buttonStyle(PlainButtonStyle())
                .sensoryFeedback(.impact(flexibility: .soft, intensity: 0.5), trigger: hapticTrigger)
            }
            .padding(.horizontal, 32)
        }
    }

    private var filterPanel: some View {
        Group {
            if expandedSection == .sort {
                sortPanel
            } else if expandedSection == .filter {
                filterOptions
            }
        }
    }

    // MARK: - Sort Panel

    private var sortPanel: some View {
        VStack(spacing: 8) {
            sortRow("author", mode: .author)
            sortRow("length", mode: .length)
            sortRow("shuffle", mode: .shuffle)
        }
    }

    private func sortRow(_ label: String, mode: QuotebookSort) -> some View {
        Button(action: {
            hapticTrigger += 1
            if sortMode == mode && mode != .shuffle {
                sortAscending.toggle()
            } else {
                sortMode = mode
                sortAscending = true
                if mode == .shuffle { reshuffleOrder() }
            }
            currentPage = 0
        }) {
            HStack(spacing: 6) {
                Text(label)
                    .settingsToggleStyle(isSelected: sortMode == mode)
                if sortMode == mode && mode != .shuffle {
                    Image(systemName: sortAscending ? "chevron.up" : "chevron.down")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(CryptogramTheme.Colors.text)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .sensoryFeedback(.impact(flexibility: .soft, intensity: 0.5), trigger: hapticTrigger)
    }

    // MARK: - Filter Options

    private var filterOptions: some View {
        VStack(spacing: 10) {
            if uniqueAuthors.count > 1 {
                authorRow
            }
            lengthRow
        }
    }

    private var authorRow: some View {
        HStack(spacing: 8) {
            Text("author:")
                .font(typography.caption)
                .foregroundColor(CryptogramTheme.Colors.text.opacity(0.3))
                .padding(.leading, 32)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    authorChip("all", author: nil)
                    ForEach(uniqueAuthors, id: \.self) { author in
                        authorChip(author, author: author)
                    }
                }
                .padding(.trailing, 24)
            }
        }
    }

    private func authorChip(_ label: String, author: String?) -> some View {
        Button(action: {
            hapticTrigger += 1
            selectedAuthor = author
            currentPage = 0
            if sortMode == .shuffle { reshuffleOrder() }
        }) {
            Text(label)
                .font(typography.caption)
                .fontWeight(selectedAuthor == author ? .bold : .regular)
                .foregroundColor(selectedAuthor == author ?
                    CryptogramTheme.Colors.text :
                    CryptogramTheme.Colors.text.opacity(0.4))
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(CryptogramTheme.Colors.text.opacity(selectedAuthor == author ? 0.08 : 0.04))
                )
        }
        .buttonStyle(PlainButtonStyle())
        .sensoryFeedback(.impact(flexibility: .soft, intensity: 0.5), trigger: hapticTrigger)
    }

    private var allLengthsSelected: Bool {
        selectedLengths.count == 3
    }

    private var lengthRow: some View {
        HStack(spacing: 12) {
            Text("length:")
                .font(typography.caption)
                .foregroundColor(CryptogramTheme.Colors.text.opacity(0.3))
            Button(action: {
                hapticTrigger += 1
                selectedLengths = ["easy", "medium", "hard"]
                currentPage = 0
                if sortMode == .shuffle { reshuffleOrder() }
            }) {
                Text("all")
                    .settingsToggleStyle(isSelected: allLengthsSelected)
            }
            .buttonStyle(PlainButtonStyle())
            .sensoryFeedback(.impact(flexibility: .soft, intensity: 0.5), trigger: hapticTrigger)
            lengthToggle("short", difficulty: "easy")
            lengthToggle("medium", difficulty: "medium")
            lengthToggle("long", difficulty: "hard")
        }
        .padding(.horizontal, 32)
    }

    private func lengthToggle(_ label: String, difficulty: String) -> some View {
        Button(action: {
            hapticTrigger += 1
            if allLengthsSelected {
                // Switching from "all" to a single selection
                selectedLengths = [difficulty]
            } else if selectedLengths.contains(difficulty) {
                // Toggle off — if last one, snap back to all
                var updated = selectedLengths
                updated.remove(difficulty)
                selectedLengths = updated.isEmpty ? ["easy", "medium", "hard"] : updated
            } else {
                // Add to selection
                selectedLengths.insert(difficulty)
            }
            currentPage = 0
            if sortMode == .shuffle { reshuffleOrder() }
        }) {
            Text(label)
                .settingsToggleStyle(isSelected: !allLengthsSelected && selectedLengths.contains(difficulty))
        }
        .buttonStyle(PlainButtonStyle())
        .sensoryFeedback(.impact(flexibility: .soft, intensity: 0.5), trigger: hapticTrigger)
    }

    // MARK: - Content Views

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "book.closed")
                .font(.system(size: 32))
                .foregroundColor(CryptogramTheme.Colors.text.opacity(0.2))
            Text("complete puzzles to\ncollect quotes here")
                .font(typography.footnote)
                .foregroundColor(CryptogramTheme.Colors.text.opacity(0.3))
                .multilineTextAlignment(.center)
            Spacer()
        }
    }

    private var noMatchesState: some View {
        VStack(spacing: 16) {
            Spacer()
            Text("no quotes match filters")
                .font(typography.footnote)
                .foregroundColor(CryptogramTheme.Colors.text.opacity(0.3))
                .multilineTextAlignment(.center)
            Spacer()
        }
    }

    private var carousel: some View {
        VStack(spacing: 16) {
            TabView(selection: $currentPage) {
                ForEach(Array(displayedQuotes.enumerated()), id: \.element.id) { index, quote in
                    quoteCard(quote)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(maxHeight: 300)

            if displayedQuotes.count > 1 {
                pageDots
            }
        }
        .padding(.top, 20)
    }

    private var listView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(displayedQuotes, id: \.id) { quote in
                    quoteCard(quote)
                }
            }
            .padding(.top, 20)
        }
    }

    private func quoteCard(_ quote: QuoteMetadata) -> some View {
        VStack(spacing: 0) {
            Spacer(minLength: 16)

            Text("\"\(quote.quoteText)\"")
                .font(.system(size: 15, design: typography.fontOption.design))
                .foregroundColor(CryptogramTheme.Colors.text)
                .italic()
                .multilineTextAlignment(.center)
                .lineSpacing(6)

            Spacer(minLength: 16)

            Text("— \(quote.author)")
                .font(typography.footnote)
                .foregroundColor(CryptogramTheme.Colors.text.opacity(0.5))

            Spacer(minLength: 16)
        }
        .padding(.horizontal, 32)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(CryptogramTheme.Colors.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(CryptogramTheme.Colors.text.opacity(0.08), lineWidth: 1)
        )
        .padding(.horizontal, 24)
    }

    private var pageDots: some View {
        HStack(spacing: 6) {
            ForEach(0..<min(displayedQuotes.count, 7), id: \.self) { i in
                let dotIndex = dotIndexFor(position: i)
                Circle()
                    .fill(CryptogramTheme.Colors.text.opacity(dotIndex == currentPage ? 0.6 : 0.15))
                    .frame(width: 6, height: 6)
            }
            if displayedQuotes.count > 7 {
                Text("...")
                    .font(.system(size: 8))
                    .foregroundColor(CryptogramTheme.Colors.text.opacity(0.2))
            }
        }
    }

    private func dotIndexFor(position: Int) -> Int {
        let total = displayedQuotes.count
        if total <= 7 { return position }
        let half = 3
        let start = max(0, min(currentPage - half, total - 7))
        return start + position
    }

    // MARK: - Helpers

    private func reshuffleOrder() {
        shuffledOrder = completedQuotes.shuffled()
    }

    private func loadQuotes() {
        do {
            quotes = try DatabaseService.shared.fetchAllQuotes()
            reshuffleOrder()
        } catch {
            quotes = []
        }
    }
}
