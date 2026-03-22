import WidgetKit
import SwiftUI
import AppIntents

// MARK: - Shared Model (mirror of app's CompletedQuote)

struct CompletedQuote: Codable, Identifiable {
    let id: String
    let solution: String
    let author: String
}

// MARK: - Quote Entity for selection

struct QuoteEntity: AppEntity {
    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Quote")
    static var defaultQuery = QuoteEntityQuery()

    var id: String
    var solution: String
    var author: String

    var displayRepresentation: DisplayRepresentation {
        let preview = solution.prefix(60) + (solution.count > 60 ? "..." : "")
        return DisplayRepresentation(title: "\(preview)", subtitle: "— \(author)")
    }
}

struct QuoteEntityQuery: EntityQuery {
    private let sharedDefaults = UserDefaults(suiteName: "group.twRL.simple-cryptogram")!

    func entities(for identifiers: [String]) async throws -> [QuoteEntity] {
        let quotes = loadQuotes()
        return quotes.filter { identifiers.contains($0.id) }
            .map { QuoteEntity(id: $0.id, solution: $0.solution, author: $0.author) }
    }

    func suggestedEntities() async throws -> [QuoteEntity] {
        loadQuotes().map { QuoteEntity(id: $0.id, solution: $0.solution, author: $0.author) }
    }

    private func loadQuotes() -> [CompletedQuote] {
        guard let data = sharedDefaults.data(forKey: "completedQuotes") else { return [] }
        return (try? JSONDecoder().decode([CompletedQuote].self, from: data)) ?? []
    }
}

// MARK: - Configuration Intent

struct QuotebookWidgetIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Quotebook Widget"
    static var description = IntentDescription("Display a quote from your completed puzzles.")

    @Parameter(title: "Randomize", default: true)
    var randomize: Bool

    @Parameter(title: "Quote")
    var selectedQuote: QuoteEntity?

    @Parameter(title: "Theme", default: .light)
    var theme: WidgetTheme

    @Parameter(title: "Font", default: .system)
    var font: WidgetFont

    @Parameter(title: "Show Author", default: true)
    var showAuthor: Bool
}

// MARK: - Timeline

struct QuotebookEntry: TimelineEntry {
    let date: Date
    let solution: String?
    let author: String?
    let theme: WidgetTheme
    let font: WidgetFont
    let showAuthor: Bool
    let isEmpty: Bool
}

struct QuotebookProvider: AppIntentTimelineProvider {
    private let sharedDefaults = UserDefaults(suiteName: "group.twRL.simple-cryptogram")!

    func placeholder(in context: Context) -> QuotebookEntry {
        QuotebookEntry(date: .now, solution: "The only way to do great work is to love what you do.",
                       author: "Steve Jobs", theme: .light, font: .system, showAuthor: true, isEmpty: false)
    }

    func snapshot(for configuration: QuotebookWidgetIntent, in context: Context) async -> QuotebookEntry {
        entry(for: configuration)
    }

    func timeline(for configuration: QuotebookWidgetIntent, in context: Context) async -> Timeline<QuotebookEntry> {
        if !configuration.randomize, configuration.selectedQuote != nil {
            // Specific quote selected — static, refresh tomorrow
            let entry = entry(for: configuration)
            let midnight = Calendar.current.startOfDay(for: Calendar.current.date(byAdding: .day, value: 1, to: .now)!)
            return Timeline(entries: [entry], policy: .after(midnight))
        } else {
            // Random mode — generate hourly entries with different quotes
            let quotes = loadQuotes()
            guard !quotes.isEmpty else {
                let empty = QuotebookEntry(date: .now, solution: nil, author: nil,
                                           theme: configuration.theme, font: configuration.font,
                                           showAuthor: configuration.showAuthor, isEmpty: true)
                return Timeline(entries: [empty], policy: .after(
                    Calendar.current.startOfDay(for: Calendar.current.date(byAdding: .day, value: 1, to: .now)!)))
            }

            var entries: [QuotebookEntry] = []
            var shuffled = quotes.shuffled()
            for hour in 0..<24 {
                if shuffled.isEmpty { shuffled = quotes.shuffled() }
                let quote = shuffled.removeFirst()
                let entryDate = Calendar.current.date(byAdding: .hour, value: hour, to: .now)!
                entries.append(QuotebookEntry(
                    date: entryDate, solution: quote.solution, author: quote.author,
                    theme: configuration.theme, font: configuration.font,
                    showAuthor: configuration.showAuthor, isEmpty: false
                ))
            }
            return Timeline(entries: entries, policy: .atEnd)
        }
    }

    private func entry(for configuration: QuotebookWidgetIntent) -> QuotebookEntry {
        if !configuration.randomize, let selected = configuration.selectedQuote {
            return QuotebookEntry(date: .now, solution: selected.solution, author: selected.author,
                                  theme: configuration.theme, font: configuration.font,
                                  showAuthor: configuration.showAuthor, isEmpty: false)
        }

        // Random
        let quotes = loadQuotes()
        guard let quote = quotes.randomElement() else {
            return QuotebookEntry(date: .now, solution: nil, author: nil,
                                  theme: configuration.theme, font: configuration.font,
                                  showAuthor: configuration.showAuthor, isEmpty: true)
        }
        return QuotebookEntry(date: .now, solution: quote.solution, author: quote.author,
                              theme: configuration.theme, font: configuration.font,
                              showAuthor: configuration.showAuthor, isEmpty: false)
    }

    private func loadQuotes() -> [CompletedQuote] {
        guard let data = sharedDefaults.data(forKey: "completedQuotes") else { return [] }
        return (try? JSONDecoder().decode([CompletedQuote].self, from: data)) ?? []
    }
}

// MARK: - Widget View

struct QuotebookWidgetEntryView: View {
    var entry: QuotebookEntry

    private var theme: WidgetTheme { entry.theme }
    private var fontDesign: Font.Design { entry.font.design }

    var body: some View {
        Group {
            if entry.isEmpty {
                emptyView
            } else if let quote = entry.solution {
                quoteView(quote: quote, author: entry.author)
            }
        }
        .containerBackground(theme.backgroundColor, for: .widget)
    }

    private func quoteView(quote: String, author: String?) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(quote)
                .font(.system(.caption, design: fontDesign))
                .foregroundStyle(theme.textColor)
                .minimumScaleFactor(0.5)
            if entry.showAuthor, let author {
                Text("— \(author)")
                    .font(.system(.caption2, design: fontDesign))
                    .foregroundStyle(theme.secondaryTextColor)
            }
        }
        .padding()
    }

    private var emptyView: some View {
        VStack(spacing: 8) {
            Image(systemName: "book.closed")
                .font(.title2)
                .foregroundStyle(theme.secondaryTextColor)
            Text("Quotebook")
                .font(.system(.caption, design: fontDesign))
                .fontWeight(.medium)
                .foregroundStyle(theme.textColor)
            Text("Complete puzzles to fill your quotebook")
                .font(.system(.caption2, design: fontDesign))
                .foregroundStyle(theme.secondaryTextColor)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

// MARK: - Widget Definition

struct QuotebookWidget: Widget {
    let kind: String = "QuotebookWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: QuotebookWidgetIntent.self, provider: QuotebookProvider()) { entry in
            QuotebookWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Quotebook")
        .description("Display a quote from your completed puzzles.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Preview

#Preview(as: .systemMedium) {
    QuotebookWidget()
} timeline: {
    QuotebookEntry(date: .now, solution: nil, author: nil, theme: .light, font: .system, showAuthor: true, isEmpty: true)
    QuotebookEntry(date: .now, solution: "The only way to do great work is to love what you do.", author: "Steve Jobs", theme: .ocean, font: .serif, showAuthor: true, isEmpty: false)
}
