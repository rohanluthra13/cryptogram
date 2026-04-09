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

    /// Copies prompt to clipboard if needed and returns whether it was copied.
    /// Does NOT open the app — call `openApp()` separately after showing feedback.
    @MainActor
    func copyPrompt(_ prompt: String) -> Bool {
        let encoded = prompt.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""

        switch self {
        case .chatgpt:
            // ChatGPT supports prompt parameter via custom URL scheme — no copy needed
            if let url = URL(string: "chatgpt://chat?prompt=\(encoded)"),
               UIApplication.shared.canOpenURL(url) {
                return false
            }
            // Fallback: copy for web
            UIPasteboard.general.string = prompt
            return true

        case .claude, .gemini:
            UIPasteboard.general.string = prompt
            return true
        }
    }

    /// Opens the app (or web fallback). Call after showing copy feedback.
    @MainActor
    func openApp(with prompt: String) {
        let encoded = prompt.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""

        switch self {
        case .chatgpt:
            if let url = URL(string: "chatgpt://chat?prompt=\(encoded)"),
               UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            } else if let url = URL(string: "https://chat.openai.com") {
                UIApplication.shared.open(url)
            }

        case .claude:
            if let url = URL(string: "claude://"),
               UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            } else if let url = URL(string: "https://claude.ai/new") {
                UIApplication.shared.open(url)
            }

        case .gemini:
            if let url = URL(string: "googlegemini://"),
               UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            } else if let url = URL(string: "https://gemini.google.com") {
                UIApplication.shared.open(url)
            }
        }
    }
}
