import Foundation

/// Structured data for extracted task (before persisting to database)
struct ExtractedTaskData: Codable {
    let title: String
    let assigneeName: String?  // Name from document, will be matched to User
    let dueDate: String?       // ISO8601 string or natural language
    let priority: String?      // "high", "medium", "low"
    let context: String?       // Source text where task was mentioned
}

/// Thread-safe service for OpenRouter API calls using URLSession
actor AIService {
    // MARK: - Properties

    private let session: URLSession

    // MARK: - Initialization

    init(session: URLSession = .shared) {
        self.session = session
    }

    // MARK: - Public Methods

    /// Generate meeting summary from document text
    /// Returns structured summary with key points
    func generateSummary(from documentText: String) async throws -> String {
        guard OpenRouterConfig.isConfigured else {
            throw AIError.notConfigured
        }

        return try await callWithRetry {
            let messages = [
                [
                    "role": "system",
                    "content": "You are a meeting minutes analyzer. Create clear, concise summaries in 200-400 words."
                ],
                [
                    "role": "user",
                    "content": """
                    Analyze this meeting document and create a concise summary.

                    Document:
                    \(documentText)

                    Provide:
                    1. Brief overview (2-3 sentences)
                    2. Key decisions made
                    3. Important topics discussed
                    4. Next steps

                    Format as readable paragraphs, not bullet points.
                    """
                ]
            ]

            return try await self.makeRequest(messages: messages, jsonMode: false)
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

    /// Call OpenRouter API with exponential backoff retry logic
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

        throw AIError.networkError(lastError ?? NSError(domain: "Unknown", code: -1))
    }

    /// Make HTTP request to OpenRouter
    private func makeRequest(messages: [[String: String]], jsonMode: Bool) async throws -> String {
        var request = URLRequest(url: URL(string: OpenRouterConfig.endpoint)!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(OpenRouterConfig.apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(OpenRouterConfig.appName, forHTTPHeaderField: "X-Title")

        var body: [String: Any] = [
            "model": OpenRouterConfig.model,
            "messages": messages,
            "max_tokens": OpenRouterConfig.maxTokens
        ]

        if jsonMode {
            body["response_format"] = ["type": "json_object"]
        }

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIError.networkError(NSError(domain: "Invalid response", code: -1))
        }

        if httpResponse.statusCode == 429 {
            throw AIError.rateLimitExceeded
        }

        guard httpResponse.statusCode == 200 else {
            throw AIError.apiKeyInvalid
        }

        struct OpenRouterResponse: Codable {
            struct Choice: Codable {
                struct Message: Codable {
                    let content: String
                }
                let message: Message
            }
            let choices: [Choice]
        }

        let decoded = try JSONDecoder().decode(OpenRouterResponse.self, from: data)
        guard let content = decoded.choices.first?.message.content else {
            throw AIError.parsingError
        }

        return content
    }
}
