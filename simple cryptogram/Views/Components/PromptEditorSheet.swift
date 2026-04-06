import SwiftUI

struct PromptEditorSheet: View {
    @Environment(AppSettings.self) private var appSettings
    @Environment(\.typography) private var typography
    @Environment(\.dismiss) private var dismiss

    @State private var showPreview = false
    @State private var showInfo = false

    private let exampleQuote = "Know thyself"
    private let exampleAuthor = "Socrates"

    private struct PromptTemplate: Identifiable {
        let id: String
        let label: String
        let icon: String
        let segments: [Segment]

        enum Segment {
            case text(String)
            case placeholder(PlaceholderType)
        }

        enum PlaceholderType {
            case quote, author
        }
    }

    private let prompts: [PromptTemplate] = [
        PromptTemplate(
            id: "explain",
            label: "explain quote",
            icon: "text.quote",
            segments: [
                .text("Explain this quote: "),
                .placeholder(.quote),
                .text(" — "),
                .placeholder(.author),
            ]
        ),
        PromptTemplate(
            id: "author",
            label: "about author",
            icon: "person.text.rectangle",
            segments: [
                .text("Tell me about "),
                .placeholder(.author),
                .text(" — who were they, why are they notable, and what was the historical context of their time?"),
            ]
        ),
    ]

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            CryptogramTheme.Colors.background
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 30) {
                    // Title
                    Text("prompts")
                        .font(typography.footnote)
                        .fontWeight(.bold)
                        .foregroundColor(CryptogramTheme.Colors.text)
                        .frame(maxWidth: .infinity)

                    // Info dropdown
                    VStack(alignment: .leading, spacing: 8) {
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                showInfo.toggle()
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Text("what are these for")
                                    .font(typography.caption)
                                    .foregroundColor(CryptogramTheme.Colors.text.opacity(0.5))
                                Image(systemName: showInfo ? "chevron.up" : "chevron.down")
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(CryptogramTheme.Colors.text.opacity(0.5))
                            }
                        }
                        .buttonStyle(PlainButtonStyle())

                        if showInfo {
                            Text("These prompts are copied to your clipboard when you tap an AI app icon after completing a puzzle. Paste them into the app to start a conversation about the quote or author. You can edit existing prompts, add new ones, or revert to the originals.")
                                .font(typography.caption)
                                .foregroundColor(CryptogramTheme.Colors.text.opacity(0.5))
                                .transition(.opacity)
                        }
                    }

                    ForEach(prompts) { prompt in
                        VStack(alignment: .leading, spacing: 12) {
                            Label(prompt.label, systemImage: prompt.icon)
                                .font(typography.footnote)
                                .fontWeight(.bold)
                                .foregroundColor(CryptogramTheme.Colors.text)

                            promptTextView(for: prompt)
                                .padding(10)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .strokeBorder(CryptogramTheme.Colors.border, lineWidth: 1)
                                )
                                .onTapGesture {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        showPreview.toggle()
                                    }
                                }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)
                .padding(.bottom, 80)
            }

            // Close button — bottom right
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(CryptogramTheme.Colors.text)
                    .frame(width: 36, height: 36)
                    .background(
                        Circle()
                            .strokeBorder(CryptogramTheme.Colors.border, lineWidth: 1)
                    )
            }
            .padding(.trailing, 20)
            .padding(.bottom, 20)
        }
        .presentationDragIndicator(.visible)
    }

    private func promptTextView(for prompt: PromptTemplate) -> Text {
        let textColor = CryptogramTheme.Colors.text
        return prompt.segments.reduce(Text("")) { combined, segment in
            switch segment {
            case .text(let str):
                return combined + Text(str)
                    .font(typography.caption)
                    .foregroundColor(textColor.opacity(0.7))
            case .placeholder(let type):
                let value = pillText(for: type)
                return combined + Text(value)
                    .font(typography.caption)
                    .bold()
                    .foregroundColor(textColor)
            }
        }
    }

    private func pillText(for type: PromptTemplate.PlaceholderType) -> String {
        switch type {
        case .quote:
            return showPreview ? "\"\(exampleQuote)\"" : "[quote]"
        case .author:
            return showPreview ? exampleAuthor : "[author]"
        }
    }
}
