import WidgetKit
import SwiftUI

// Minimal decode-only mirror of the app's DailyPuzzleProgress struct.
// Only the fields the widget needs are included; unknown keys are ignored by Codable.
private struct DailyPuzzleProgress: Codable {
    let isCompleted: Bool
    let solutionText: String?
    let author: String?
}

struct DailyPuzzleEntry: TimelineEntry {
    let date: Date
    let isCompleted: Bool
    let solutionText: String?
    let author: String?
}

struct Provider: TimelineProvider {
    private let sharedDefaults = UserDefaults(suiteName: "group.twRL.simple-cryptogram")!

    func placeholder(in context: Context) -> DailyPuzzleEntry {
        DailyPuzzleEntry(date: .now, isCompleted: false, solutionText: nil, author: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping (DailyPuzzleEntry) -> Void) {
        completion(todayEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<DailyPuzzleEntry>) -> Void) {
        let entry = todayEntry()

        // Refresh at midnight when the daily puzzle changes
        let midnight = Calendar.current.startOfDay(for: Calendar.current.date(byAdding: .day, value: 1, to: .now)!)
        let timeline = Timeline(entries: [entry], policy: .after(midnight))
        completion(timeline)
    }

    private func todayEntry() -> DailyPuzzleEntry {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = .current
        let key = "dailyPuzzleProgress-\(formatter.string(from: .now))"

        guard let data = sharedDefaults.data(forKey: key),
              let progress = try? JSONDecoder().decode(DailyPuzzleProgress.self, from: data) else {
            return DailyPuzzleEntry(date: .now, isCompleted: false, solutionText: nil, author: nil)
        }

        return DailyPuzzleEntry(
            date: .now,
            isCompleted: progress.isCompleted,
            solutionText: progress.solutionText,
            author: progress.author
        )
    }
}

struct DailyPuzzleWidgetEntryView: View {
    var entry: DailyPuzzleEntry

    var body: some View {
        if entry.isCompleted, let quote = entry.solutionText {
            VStack(alignment: .leading, spacing: 4) {
                Text(quote)
                    .font(.caption)
                    .minimumScaleFactor(0.5)
                if let author = entry.author {
                    Text("— \(author)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
        } else {
            VStack(spacing: 8) {
                Image(systemName: "lock.fill")
                    .font(.title2)
                    .foregroundStyle(.secondary)
                Text("Daily Puzzle")
                    .font(.caption)
                    .fontWeight(.medium)
                Text("Incomplete")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

struct DailyPuzzleWidget: Widget {
    let kind: String = "DailyPuzzleWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            if #available(iOS 17.0, *) {
                DailyPuzzleWidgetEntryView(entry: entry)
                    .containerBackground(.fill.tertiary, for: .widget)
            } else {
                DailyPuzzleWidgetEntryView(entry: entry)
                    .padding()
                    .background()
            }
        }
        .configurationDisplayName("Daily Puzzle")
        .description("See today's daily puzzle status.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

#Preview(as: .systemSmall) {
    DailyPuzzleWidget()
} timeline: {
    DailyPuzzleEntry(date: .now, isCompleted: false, solutionText: nil, author: nil)
    DailyPuzzleEntry(date: .now, isCompleted: true, solutionText: "The only way to do great work is to love what you do.", author: "Steve Jobs")
}
