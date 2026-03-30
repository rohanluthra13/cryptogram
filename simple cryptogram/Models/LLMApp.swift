import Foundation
import UIKit

enum LLMApp: String, CaseIterable, Identifiable {
    case claude = "Claude"
    case chatgpt = "ChatGPT"
    case gemini = "Gemini"

    var id: String { rawValue }

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

    /// URL schemes that need to be declared in Info.plist LSApplicationQueriesSchemes
    static var urlSchemes: [String] {
        ["chatgpt", "claude", "googlegemini"]
    }
}
