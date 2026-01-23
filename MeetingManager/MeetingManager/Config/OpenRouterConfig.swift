import Foundation

struct OpenRouterConfig {
  // MARK: - Properties

  /// OpenRouter API key
  /// Get your key at: https://openrouter.ai/keys
  static let apiKey = "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"

  /// API endpoint
  static let endpoint = "https://openrouter.ai/api/v1/chat/completions"

  /// Model to use for processing (DeepSeek is cost-effective)
  static let model = "tngtech/deepseek-r1t2-chimera:free"

  /// Max tokens for AI responses (4K sufficient for summaries)
  static let maxTokens = 4096

  /// App identifier for OpenRouter
  static let appName = "MeetingManager"

  // MARK: - Validation

  static var isConfigured: Bool {
    return !apiKey.isEmpty && apiKey != "YOUR_OPENROUTER_API_KEY_HERE"
  }
}

enum AIError: LocalizedError {
  case notConfigured
  case apiKeyInvalid
  case rateLimitExceeded
  case networkError(Error)
  case parsingError

  var errorDescription: String? {
    switch self {
    case .notConfigured:
      return
        "OpenRouter API key not configured. Set OpenRouterConfig.apiKey in Config/OpenRouterConfig.swift"
    case .apiKeyInvalid:
      return "Invalid OpenRouter API key. Check your key at openrouter.ai/keys"
    case .rateLimitExceeded:
      return "API rate limit exceeded. Please wait a moment and try again."
    case .networkError(let error):
      return "Network error: \(error.localizedDescription)"
    case .parsingError:
      return "Failed to parse AI response. Please try again."
    }
  }
}
