import Foundation
import SwiftAnthropic

actor AIService {
    // MARK: - Properties

    private let client: AnthropicServiceProtocol

    // MARK: - Initialization

    init(apiKey: String = AnthropicConfig.apiKey) {
        self.client = AnthropicServiceFactory.service(apiKey: apiKey)
    }

    // MARK: - Public Methods

    /// Generate meeting summary from document text
    /// Returns structured summary with key points
    func generateSummary(from documentText: String) async throws -> String {
        guard AnthropicConfig.isConfigured else {
            throw AnthropicError.notConfigured
        }

        return try await callWithRetry {
            let request = MessageParameter(
                model: .claude35Sonnet,
                maxTokens: AnthropicConfig.maxTokens,
                messages: [
                    Message(role: .user, content: [
                        .text("""
                        Analyze this meeting document and create a concise summary.

                        Document:
                        \(documentText)

                        Provide:
                        1. Brief overview (2-3 sentences)
                        2. Key decisions made
                        3. Important topics discussed
                        4. Next steps

                        Format as readable paragraphs, not bullet points.
                        """)
                    ])
                ],
                system: [
                    .text("You are a meeting minutes analyzer. Create clear, concise summaries."),
                    .cacheControl(.init(type: .ephemeral)) // Enable prompt caching for cost savings
                ]
            )

            let response = try await self.client.createMessage(request)

            guard let textContent = response.content.first(where: {
                if case .text = $0 { return true }
                return false
            }) else {
                throw AnthropicError.parsingError
            }

            if case .text(let summary) = textContent {
                return summary
            } else {
                throw AnthropicError.parsingError
            }
        }
    }

    /// Extract tasks and action items from document text
    /// Returns array of structured tasks with assignees and due dates
    func extractTasks(from documentText: String, organizationMembers: [User]) async throws -> [ExtractedTaskData] {
        // TODO: Implement in Plan 05-04
        // Will use structured outputs to extract action items with assignees
        return []
    }

    // MARK: - Private Helpers

    /// Call Claude API with exponential backoff retry logic
    private func callWithRetry<T>(
        maxRetries: Int = 3,
        operation: @escaping () async throws -> T
    ) async throws -> T {
        var lastError: Error?

        for attempt in 0..<maxRetries {
            do {
                return try await operation()
            } catch let error as NSError where error.domain == NSURLErrorDomain {
                // Network error - retry
                lastError = error
                let delay = Double(1 << attempt) // 1s, 2s, 4s
                let jitter = Double.random(in: 0...0.1) // Add jitter
                try await Task.sleep(nanoseconds: UInt64((delay + jitter) * 1_000_000_000))
            } catch {
                // API error or parsing error - don't retry
                throw error
            }
        }

        throw AnthropicError.networkError(lastError ?? NSError(domain: "Unknown", code: -1))
    }
}

/// Structured data for extracted task (before persisting to database)
struct ExtractedTaskData: Codable {
    let title: String
    let assigneeName: String?  // Name from document, will be matched to User
    let dueDate: String?       // ISO8601 string or natural language
    let priority: String?      // "high", "medium", "low"
    let context: String?       // Source text where task was mentioned
}
