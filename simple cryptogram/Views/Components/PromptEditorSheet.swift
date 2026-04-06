import SwiftUI

struct PromptEditorSheet: View {
    @Environment(AppSettings.self) private var appSettings
    @Environment(\.typography) private var typography
    @Environment(\.dismiss) private var dismiss

    @State private var showPreview = false
    @State private var showInfo = false
    @State private var editingPromptId: String?
    @State private var editBuffer: String = ""
    @FocusState private var isEditFocused: Bool

    private let exampleQuote = "Know thyself"
    private let exampleAuthor = "Socrates"

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

                    ForEach(appSettings.activePrompts) { prompt in
                        promptRow(prompt: prompt)
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

    // MARK: - Prompt Row

    @ViewBuilder
    private func promptRow(prompt: LLMPrompt) -> some View {
        let isEditing = editingPromptId == prompt.id

        VStack(alignment: .leading, spacing: 12) {
            // Title row: label + action buttons
            HStack {
                Label(prompt.label, systemImage: prompt.icon)
                    .font(typography.footnote)
                    .fontWeight(.bold)
                    .foregroundColor(CryptogramTheme.Colors.text)

                Spacer()

                if isEditing {
                    // Save
                    Button {
                        savePrompt(original: prompt)
                    } label: {
                        Text("save")
                            .font(typography.caption)
                            .fontWeight(.bold)
                            .foregroundColor(CryptogramTheme.Colors.text)
                    }
                    .buttonStyle(PlainButtonStyle())

                    // Revert
                    Button {
                        revertPrompt(id: prompt.id)
                    } label: {
                        Text("revert")
                            .font(typography.caption)
                            .foregroundColor(CryptogramTheme.Colors.text.opacity(0.5))
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.leading, 10)
                } else {
                    // Edit
                    Button {
                        beginEditing(prompt: prompt)
                    } label: {
                        Text("edit")
                            .font(typography.caption)
                            .foregroundColor(CryptogramTheme.Colors.text.opacity(0.5))
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }

            // Text box — editable when isEditing
            if isEditing {
                TextEditor(text: $editBuffer)
                    .font(typography.caption)
                    .foregroundColor(CryptogramTheme.Colors.text)
                    .scrollContentBackground(.hidden)
                    .padding(6)
                    .frame(minHeight: 80)
                    .background(Color(white: 0.97))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .strokeBorder(CryptogramTheme.Colors.border, lineWidth: 1)
                    )
                    .focused($isEditFocused)
            } else {
                promptTextView(template: prompt.template)
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

    // MARK: - Edit Actions

    private func beginEditing(prompt: LLMPrompt) {
        editBuffer = prompt.template
        editingPromptId = prompt.id
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            isEditFocused = true
        }
    }

    private func savePrompt(original: LLMPrompt) {
        var updated = original
        updated.template = editBuffer
        appSettings.updatePrompt(updated)
        editingPromptId = nil
        isEditFocused = false
    }

    private func revertPrompt(id: String) {
        appSettings.revertPrompt(id: id)
        editingPromptId = nil
        isEditFocused = false
    }

    /// Render a template string, highlighting `[quote]` and `[author]` placeholders
    /// in bold. When `showPreview` is true, placeholders swap to example values.
    private func promptTextView(template: String) -> Text {
        let textColor = CryptogramTheme.Colors.text
        let segments = parseTemplate(template)
        return segments.reduce(Text("")) { combined, segment in
            switch segment {
            case .text(let str):
                return combined + Text(str)
                    .font(typography.caption)
                    .foregroundColor(textColor.opacity(0.7))
            case .quotePlaceholder:
                let value = showPreview ? "\"\(exampleQuote)\"" : "[quote]"
                return combined + Text(value)
                    .font(typography.caption)
                    .bold()
                    .foregroundColor(textColor)
            case .authorPlaceholder:
                let value = showPreview ? exampleAuthor : "[author]"
                return combined + Text(value)
                    .font(typography.caption)
                    .bold()
                    .foregroundColor(textColor)
            }
        }
    }

    private enum TemplateSegment {
        case text(String)
        case quotePlaceholder
        case authorPlaceholder
    }

    /// Walks the template, splitting it into literal text and placeholder segments.
    private func parseTemplate(_ template: String) -> [TemplateSegment] {
        var segments: [TemplateSegment] = []
        var remainder = template[...]

        while !remainder.isEmpty {
            if let quoteRange = remainder.range(of: "[quote]"),
               let authorRange = remainder.range(of: "[author]") {
                // Pick whichever comes first
                if quoteRange.lowerBound < authorRange.lowerBound {
                    appendSlice(&segments, slice: remainder[..<quoteRange.lowerBound])
                    segments.append(.quotePlaceholder)
                    remainder = remainder[quoteRange.upperBound...]
                } else {
                    appendSlice(&segments, slice: remainder[..<authorRange.lowerBound])
                    segments.append(.authorPlaceholder)
                    remainder = remainder[authorRange.upperBound...]
                }
            } else if let quoteRange = remainder.range(of: "[quote]") {
                appendSlice(&segments, slice: remainder[..<quoteRange.lowerBound])
                segments.append(.quotePlaceholder)
                remainder = remainder[quoteRange.upperBound...]
            } else if let authorRange = remainder.range(of: "[author]") {
                appendSlice(&segments, slice: remainder[..<authorRange.lowerBound])
                segments.append(.authorPlaceholder)
                remainder = remainder[authorRange.upperBound...]
            } else {
                appendSlice(&segments, slice: remainder)
                break
            }
        }
        return segments
    }

    private func appendSlice(_ segments: inout [TemplateSegment], slice: Substring) {
        if !slice.isEmpty {
            segments.append(.text(String(slice)))
        }
    }
}
