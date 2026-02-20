import SwiftUI

struct QuotebookView: View {
    @Environment(AppSettings.self) private var appSettings
    @Environment(\.typography) private var typography

    @State private var quotes: [QuoteMetadata] = []
    @State private var currentPage: Int = 0

    private var completedQuotes: [QuoteMetadata] {
        quotes
            .filter { appSettings.completedQuoteIds.contains($0.id) }
            .sorted { a, b in
                if a.author != b.author { return a.author < b.author }
                return a.id < b.id
            }
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 60)

            if completedQuotes.isEmpty {
                emptyState
            } else {
                carousel
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

    private var carousel: some View {
        VStack(spacing: 16) {
            TabView(selection: $currentPage) {
                ForEach(Array(completedQuotes.enumerated()), id: \.element.id) { index, quote in
                    quoteCard(quote)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(maxHeight: 300)

            // Page dots
            if completedQuotes.count > 1 {
                pageDots
            }
        }
        .padding(.top, 20)
    }

    private func quoteCard(_ quote: QuoteMetadata) -> some View {
        VStack(spacing: 0) {
            Spacer(minLength: 16)

            Text("\"\(quote.quoteText)\"")
                .font(typography.body)
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
            ForEach(0..<min(completedQuotes.count, 7), id: \.self) { i in
                let dotIndex = dotIndexFor(position: i)
                Circle()
                    .fill(CryptogramTheme.Colors.text.opacity(dotIndex == currentPage ? 0.6 : 0.15))
                    .frame(width: 6, height: 6)
            }
            if completedQuotes.count > 7 {
                Text("...")
                    .font(.system(size: 8))
                    .foregroundColor(CryptogramTheme.Colors.text.opacity(0.2))
            }
        }
    }

    private func dotIndexFor(position: Int) -> Int {
        let total = completedQuotes.count
        if total <= 7 { return position }
        let half = 3
        let start = max(0, min(currentPage - half, total - 7))
        return start + position
    }

    private func loadQuotes() {
        do {
            quotes = try DatabaseService.shared.fetchAllQuotes()
        } catch {
            quotes = []
        }
    }
}
