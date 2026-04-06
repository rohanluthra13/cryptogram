import Foundation
import UIKit

// MARK: - Prompt Templates

struct LLMPrompt: Identifiable, Codable, Equatable {
    let id: String
    var label: String
    var icon: String
    /// Template string with `[quote]` and `[author]` placeholders.
    var template: String

    /// Fills the template by replacing placeholders with actual values.
    func buildPrompt(quote: String, author: String) -> String {
        template
            .replacingOccurrences(of: "[quote]", with: "\"\(quote)\"")
            .replacingOccurrences(of: "[author]", with: author)
    }

    static let explainQuote = LLMPrompt(
        id: "explain",
        label: "explain quote",
        icon: "text.quote",
        template: "Explain this quote: [quote] — [author]"
    )

    static let aboutAuthor = LLMPrompt(
        id: "author",
        label: "about author",
        icon: "person.text.rectangle",
        template: "Tell me about [author] — who were they, why are they notable, and what was the historical context of their time?"
    )

    /// The original built-in prompts. Used as defaults and for revert-to-original.
    static let defaults: [LLMPrompt] = [.explainQuote, .aboutAuthor]

    /// Look up the default version of a prompt by id.
    static func defaultPrompt(id: String) -> LLMPrompt? {
        defaults.first { $0.id == id }
    }
}

// MARK: - LLM App

enum LLMApp: String, CaseIterable, Identifiable {
    case claude = "Claude"
    case chatgpt = "ChatGPT"
    case gemini = "Gemini"

    var id: String { rawValue }

    /// Asset catalog image name
    var iconName: String {
        switch self {
        case .claude: "claude"
        case .chatgpt: "chatgpt"
        case .gemini: "gemini"
        }
    }

    /// Opens the app with a prompt if supported, otherwise copies prompt and opens app.
    /// Returns true if the prompt was copied to clipboard (so caller can show a toast).
    @MainActor
    func open(with prompt: String) -> Bool {
        let encoded = prompt.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""

        switch self {
        case .chatgpt:
            // ChatGPT supports prompt parameter via custom URL scheme
            if let url = URL(string: "chatgpt://chat?prompt=\(encoded)"),
               UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
                return false
            }
            // Fallback to web
            UIPasteboard.general.string = prompt
            if let url = URL(string: "https://chat.openai.com") {
                UIApplication.shared.open(url)
            }
            return true

        case .claude:
            // Claude app doesn't support prompt parameter — copy and open
            UIPasteboard.general.string = prompt
            if let url = URL(string: "claude://"),
               UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            } else if let url = URL(string: "https://claude.ai/new") {
                UIApplication.shared.open(url)
            }
            return true

        case .gemini:
            // Gemini app — copy and open
            UIPasteboard.general.string = prompt
            if let url = URL(string: "googlegemini://"),
               UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            } else if let url = URL(string: "https://gemini.google.com") {
                UIApplication.shared.open(url)
            }
            return true
        }
    }
}
