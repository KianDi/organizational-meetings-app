import Foundation

struct AnthropicConfig {
    // MARK: - Properties

    /// Anthropic API key for Claude access
    /// Get your key at: https://console.anthropic.com/settings/keys
    static let apiKey = "YOUR_ANTHROPIC_API_KEY_HERE"

    /// Claude model to use for processing
    static let model = "claude-3-5-sonnet-20241022"

    /// Max tokens for AI responses (4K sufficient for summaries)
    static let maxTokens = 4096

    // MARK: - Validation

    static var isConfigured: Bool {
        return !apiKey.isEmpty && apiKey != "YOUR_ANTHROPIC_API_KEY_HERE"
    }
}

enum AnthropicError: LocalizedError {
    case notConfigured
    case apiKeyInvalid
    case rateLimitExceeded
    case networkError(Error)
    case parsingError

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "Anthropic API key not configured. Set AnthropicConfig.apiKey in Services/AnthropicConfig.swift"
        case .apiKeyInvalid:
            return "Invalid Anthropic API key. Check your key at console.anthropic.com"
        case .rateLimitExceeded:
            return "API rate limit exceeded. Please wait a moment and try again."
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .parsingError:
            return "Failed to parse AI response. Please try again."
        }
    }
}
