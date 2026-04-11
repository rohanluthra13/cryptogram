import WidgetKit
import SwiftUI
import AppIntents

// MARK: - Daily Progress (decode-only mirror)

private struct DailyPuzzleProgress: Codable {
    let isCompleted: Bool
    let solutionText: String?
    let author: String?
}

// MARK: - Widget Theme & Font Enums

enum WidgetTheme: String, CaseIterable, AppEnum {
    case light, dark, cream, ocean, sage, rose, lavender, slate

    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Theme")
    static var caseDisplayRepresentations: [WidgetTheme: DisplayRepresentation] {
        [
            .light: "Light", .dark: "Dark", .cream: "Cream", .ocean: "Ocean",
            .sage: "Sage", .rose: "Rose", .lavender: "Lavender", .slate: "Slate"
        ]
    }

    var hue: Double {
        switch self {
        case .light:    return 0
        case .dark:     return 0
        case .cream:    return 0.08
        case .ocean:    return 0.58
        case .sage:     return 0.35
        case .rose:     return 0.95
        case .lavender: return 0.75
        case .slate:    return 0.60
        }
    }

    var saturation: Double {
        switch self {
        case .light:    return 0
        case .dark:     return 0
        case .slate:    return 0.5
        default:        return 0.8
        }
    }

    var isDark: Bool { self == .dark }

    var backgroundColor: Color {
        let s = saturation
        if isDark {
            return Color(hue: hue, saturation: s * 0.18, brightness: 0.14)
        } else {
            return Color(hue: hue, saturation: s * 0.14, brightness: 0.97)
        }
    }

    var textColor: Color {
        let s = saturation
        if isDark {
            return Color(hue: hue, saturation: s * 0.08, brightness: 0.83)
        } else {
            return Color(hue: hue, saturation: s * 0.15, brightness: 0.33)
        }
    }

    var secondaryTextColor: Color {
        let s = saturation
        if isDark {
            return Color(hue: hue, saturation: s * 0.08, brightness: 0.55)
        } else {
            return Color(hue: hue, saturation: s * 0.10, brightness: 0.55)
        }
    }
}

enum WidgetFont: String, CaseIterable, AppEnum {
    case system = "System"
    case rounded = "Rounded"
    case serif = "Serif"
    case monospaced = "Monospaced"

    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Font")
    static var caseDisplayRepresentations: [WidgetFont: DisplayRepresentation] {
        [.system: "System", .rounded: "Rounded", .serif: "Serif", .monospaced: "Monospaced"]
    }

    var design: Font.Design {
        switch self {
        case .system:     return .default
        case .rounded:    return .rounded
        case .serif:      return .serif
        case .monospaced: return .monospaced
        }
    }
}

// MARK: - Configuration Intent

struct DailyPuzzleWidgetIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Daily Puzzle Widget"
    static var description = IntentDescription("Configure the widget appearance.")

    @Parameter(title: "Theme", default: .light)
    var theme: WidgetTheme

    @Parameter(title: "Font", default: .system)
    var font: WidgetFont

    @Parameter(title: "Show Author", default: true)
    var showAuthor: Bool
}

// MARK: - Timeline

private let incompleteMessages = [
    "you haven't done your daily puzzle yet!",
    "do the daily puzzle!",
    "daily puzzle?",
    "what's the quote?",
    "get it done mate.",
    "today's puzzle. go.",
    "still waiting...",
    "we're waiting...",
    "... ... ...",
]

struct DailyPuzzleEntry: TimelineEntry {
    let date: Date
    let isCompleted: Bool
    let solutionText: String?
    let author: String?
    let theme: WidgetTheme
    let font: WidgetFont
    let showAuthor: Bool
    let incompleteMessage: String
}

struct Provider: AppIntentTimelineProvider {
    private var sharedDefaults: UserDefaults { UserDefaults(suiteName: "group.twRL.simple-cryptogram")! }

    func placeholder(in context: Context) -> DailyPuzzleEntry {
        DailyPuzzleEntry(date: .now, isCompleted: false, solutionText: nil, author: nil, theme: .light, font: .system, showAuthor: true, incompleteMessage: incompleteMessages[0])
    }

    func snapshot(for configuration: DailyPuzzleWidgetIntent, in context: Context) async -> DailyPuzzleEntry {
        todayEntry(configuration: configuration)
    }

    func timeline(for configuration: DailyPuzzleWidgetIntent, in context: Context) async -> Timeline<DailyPuzzleEntry> {
        let entry = todayEntry(configuration: configuration)
        let midnight = Calendar.current.startOfDay(for: Calendar.current.date(byAdding: .day, value: 1, to: .now)!)

        if entry.isCompleted {
            return Timeline(entries: [entry], policy: .after(midnight))
        }

        // Rotate incomplete messages every 2 hours
        var entries: [DailyPuzzleEntry] = []
        var shuffled = incompleteMessages.shuffled()
        for i in 0..<12 {
            if shuffled.isEmpty { shuffled = incompleteMessages.shuffled() }
            let entryDate = Calendar.current.date(byAdding: .hour, value: i * 2, to: .now)!
            entries.append(DailyPuzzleEntry(
                date: entryDate, isCompleted: false, solutionText: nil, author: nil,
                theme: configuration.theme, font: configuration.font,
                showAuthor: configuration.showAuthor, incompleteMessage: shuffled.removeFirst()
            ))
        }
        return Timeline(entries: entries, policy: .after(midnight))
    }

    private func todayEntry(configuration: DailyPuzzleWidgetIntent) -> DailyPuzzleEntry {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = .current
        let key = "dailyPuzzleProgress-\(formatter.string(from: .now))"

        let message = incompleteMessages.randomElement()!

        guard let data = sharedDefaults.data(forKey: key),
              let progress = try? JSONDecoder().decode(DailyPuzzleProgress.self, from: data) else {
            return DailyPuzzleEntry(date: .now, isCompleted: false, solutionText: nil, author: nil,
                                    theme: configuration.theme, font: configuration.font, showAuthor: configuration.showAuthor, incompleteMessage: message)
        }

        return DailyPuzzleEntry(
            date: .now,
            isCompleted: progress.isCompleted,
            solutionText: progress.solutionText,
            author: progress.author,
            theme: configuration.theme,
            font: configuration.font,
            showAuthor: configuration.showAuthor,
            incompleteMessage: message
        )
    }
}

// MARK: - Widget View

struct DailyPuzzleWidgetEntryView: View {
    var entry: DailyPuzzleEntry

    private var theme: WidgetTheme { entry.theme }
    private var fontDesign: Font.Design { entry.font.design }

    var body: some View {
        Group {
            if entry.isCompleted, let quote = entry.solutionText {
                completedView(quote: quote, author: entry.author)
            } else {
                incompleteView
            }
        }
        .containerBackground(theme.backgroundColor, for: .widget)
    }

    private func completedView(quote: String, author: String?) -> some View {
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

    @Environment(\.widgetFamily) private var widgetFamily

    private var incompleteView: some View {
        Group {
            if widgetFamily == .systemSmall {
                VStack(alignment: .leading, spacing: 8) {
                    lockIcon
                    incompleteText
                }
            } else {
                HStack(spacing: 10) {
                    lockIcon
                    incompleteText
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
    }

    private var lockIcon: some View {
        Image(systemName: "lock.fill")
            .font(.title2)
            .foregroundStyle(theme.secondaryTextColor)
    }

    private var incompleteText: some View {
        Text(entry.incompleteMessage)
            .font(.system(.caption, design: fontDesign))
            .foregroundStyle(theme.textColor)
    }
}

// MARK: - Widget Definition

struct DailyPuzzleWidget: Widget {
    let kind: String = "DailyPuzzleWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: DailyPuzzleWidgetIntent.self, provider: Provider()) { entry in
            DailyPuzzleWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Daily Puzzle")
        .description("See today's daily puzzle status.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Preview

#Preview(as: .systemSmall) {
    DailyPuzzleWidget()
} timeline: {
    DailyPuzzleEntry(date: .now, isCompleted: false, solutionText: nil, author: nil, theme: .ocean, font: .serif, showAuthor: true, incompleteMessage: "you haven't done your daily puzzle yet!")
    DailyPuzzleEntry(date: .now, isCompleted: true, solutionText: "The only way to do great work is to love what you do.", author: "Steve Jobs", theme: .ocean, font: .serif, showAuthor: true, incompleteMessage: "")
}
