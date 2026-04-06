import SwiftUI

// MARK: - Data types

private struct Era: Identifiable {
    let id = UUID()
    let name: String
    let startYear: Int
    let endYear: Int
    let color: Color
}

private struct TimelineAuthor: Identifiable {
    let id: Int
    let name: String
    let fullName: String?
    let birthYear: Int
    let deathYear: Int?
    let summary: String?
    let birthDate: String?
    let deathDate: String?
}

// MARK: - Constants

private let eras: [Era] = [
    Era(name: "Ancient", startYear: -600, endYear: 500, color: .brown.opacity(0.15)),
    Era(name: "Medieval", startYear: 500, endYear: 1400, color: .purple.opacity(0.12)),
    Era(name: "Renaissance", startYear: 1400, endYear: 1600, color: .orange.opacity(0.12)),
    Era(name: "Enlightenment", startYear: 1600, endYear: 1800, color: .yellow.opacity(0.15)),
    Era(name: "Industrial", startYear: 1800, endYear: 1900, color: .blue.opacity(0.1)),
    Era(name: "Modern", startYear: 1900, endYear: 1970, color: .green.opacity(0.1)),
    Era(name: "Contemporary", startYear: 1970, endYear: 2030, color: .cyan.opacity(0.1)),
]

private let pointsPerYear: CGFloat = 3.0

// MARK: - Year parsing

private func parseYear(from dateString: String?) -> Int? {
    guard var s = dateString else { return nil }
    if s.lowercased().hasPrefix("unknown") { return nil }
    if s.hasPrefix("c.") {
        s = String(s.dropFirst(2)).trimmingCharacters(in: .whitespaces)
    }
    let isBC = s.contains("BC")
    if isBC {
        s = s.replacingOccurrences(of: "BCE", with: "")
            .replacingOccurrences(of: "BC", with: "")
            .trimmingCharacters(in: .whitespaces)
    }
    if s.hasPrefix("-") {
        let rest = s.dropFirst()
        let yearPart = rest.prefix(while: { $0.isNumber })
        if let y = Int(yearPart) { return -y }
        return nil
    }
    let yearPart = s.prefix(while: { $0.isNumber })
    guard let y = Int(yearPart), y < 2100 else { return nil }
    return isBC ? -y : y
}

private func yForYear(_ year: Int) -> CGFloat {
    CGFloat(year - (eras.first?.startYear ?? -600)) * pointsPerYear
}

// MARK: - Timeline View

struct TimelineView: View {
    @Environment(\.typography) private var typography
    @State private var authors: [TimelineAuthor] = []

    private var totalHeight: CGFloat {
        let span = (eras.last?.endYear ?? 2030) - (eras.first?.startYear ?? -600)
        return CGFloat(span) * pointsPerYear
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical, showsIndicators: false) {
                ZStack(alignment: .top) {
                    // Era backgrounds
                    VStack(spacing: 0) {
                        ForEach(eras) { era in
                            let height = CGFloat(era.endYear - era.startYear) * pointsPerYear
                            ZStack {
                                Rectangle().fill(era.color)
                                Text(era.name)
                                    .font(.system(size: 14, weight: .medium, design: typography.fontOption.design))
                                    .foregroundColor(CryptogramTheme.Colors.text.opacity(0.3))
                            }
                            .frame(height: height)
                        }
                    }

                    // Center line
                    Rectangle()
                        .fill(CryptogramTheme.Colors.text.opacity(0.15))
                        .frame(width: 1, height: totalHeight)

                    // Author markers
                    ForEach(Array(authors.enumerated()), id: \.element.id) { index, author in
                        let y = yForYear(author.birthYear)
                        let isLeft = index % 2 == 0
                        authorRow(author, isLeft: isLeft)
                            .offset(y: y)
                    }
                }
                .frame(height: totalHeight)
                .id("timeline")
            }
            .onAppear {
                // Scroll to ~1800 on appear
                proxy.scrollTo("timeline", anchor: UnitPoint(x: 0.5, y: yForYear(1800) / totalHeight))
            }
        }
        .task { loadAuthors() }
    }

    // MARK: - Author row

    private func authorRow(_ author: TimelineAuthor, isLeft: Bool) -> some View {
        HStack(spacing: 4) {
            if !isLeft { Spacer() }

            // Dot
            if !isLeft {
                Rectangle()
                    .fill(CryptogramTheme.Colors.text.opacity(0.2))
                    .frame(height: 0.5)
                Circle()
                    .fill(CryptogramTheme.Colors.text.opacity(0.5))
                    .frame(width: 5, height: 5)
            }

            Text(author.name)
                .font(.system(size: 9, design: typography.fontOption.design))
                .foregroundColor(CryptogramTheme.Colors.text.opacity(0.6))
                .lineLimit(1)

            if isLeft {
                Circle()
                    .fill(CryptogramTheme.Colors.text.opacity(0.5))
                    .frame(width: 5, height: 5)
                Rectangle()
                    .fill(CryptogramTheme.Colors.text.opacity(0.2))
                    .frame(height: 0.5)
            }

            if isLeft { Spacer() }
        }
        .frame(height: 14)
        .padding(.horizontal, 20)
    }

    // MARK: - Data

    private func loadAuthors() {
        do {
            let all = try DatabaseService.shared.fetchAllAuthors()
            authors = all.compactMap { a in
                guard let birth = parseYear(from: a.birthDate) else { return nil }
                return TimelineAuthor(
                    id: a.id, name: a.name, fullName: a.fullName,
                    birthYear: birth, deathYear: parseYear(from: a.deathDate),
                    summary: a.summary, birthDate: a.birthDate, deathDate: a.deathDate
                )
            }
            .sorted { $0.birthYear < $1.birthYear }
        } catch {}
    }
}
