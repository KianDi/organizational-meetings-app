#!/usr/bin/env swift

import Foundation
import PDFKit

// Mock User struct for testing
struct User: Codable {
    let id: UUID
    let name: String
    let email: String
}

// From AIService.swift
struct ExtractedTaskData: Codable {
    let title: String
    let assigneeName: String?
    let dueDate: String?
    let priority: String
    let context: String?
}

private struct TaskExtractionSchema: Codable {
    let tasks: [ExtractedTaskData]
}

enum AIError: Error {
    case notConfigured
    case parsingError
    case apiKeyInvalid
    case rateLimitExceeded
    case networkError(Error)
}

struct OpenRouterConfig {
    static let endpoint = "https://openrouter.ai/api/v1/chat/completions"
    static let apiKey = "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"
    static let model = "tngtech/deepseek-r1t2-chimera:free"
    static let maxTokens = 4096
    static let appName = "MeetingManager"

    static var isConfigured: Bool {
        !apiKey.isEmpty && apiKey != "YOUR_OPENROUTER_API_KEY_HERE"
    }
}

// Document extraction
func extractTextFromPDF(url: URL) throws -> String {
    guard let document = PDFDocument(url: url) else {
        throw NSError(domain: "PDFExtraction", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to open PDF"])
    }

    var fullText = ""
    for i in 0..<document.pageCount {
        if let page = document.page(at: i) {
            if let pageText = page.string {
                fullText += pageText + "\n"
            }
        }
    }

    return fullText.trimmingCharacters(in: .whitespacesAndNewlines)
}

// AI Service methods
func makeRequest(messages: [[String: String]], jsonMode: Bool) async throws -> String {
    print("📡 [AIService.makeRequest] Preparing request...")
    print("   Endpoint: \(OpenRouterConfig.endpoint)")
    print("   Model: \(OpenRouterConfig.model)")
    print("   JSON Mode: \(jsonMode)")

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
    print("📤 [AIService.makeRequest] Sending request...")

    let (data, response) = try await URLSession.shared.data(for: request)
    print("📥 [AIService.makeRequest] Received response")

    guard let httpResponse = response as? HTTPURLResponse else {
        print("❌ [AIService.makeRequest] Invalid HTTP response type")
        throw AIError.networkError(NSError(domain: "Invalid response", code: -1))
    }

    print("📊 [AIService.makeRequest] HTTP Status: \(httpResponse.statusCode)")

    if httpResponse.statusCode == 429 {
        print("❌ [AIService.makeRequest] Rate limit exceeded")
        throw AIError.rateLimitExceeded
    }

    guard httpResponse.statusCode == 200 else {
        print("❌ [AIService.makeRequest] Non-200 status code: \(httpResponse.statusCode)")
        if let errorBody = String(data: data, encoding: .utf8) {
            print("❌ [AIService.makeRequest] Error response body: \(errorBody)")
        }
        throw AIError.apiKeyInvalid
    }

    print("🔍 [AIService.makeRequest] Decoding OpenRouter response...")
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
        print("❌ [AIService.makeRequest] No content in choices")
        throw AIError.parsingError
    }

    print("✅ [AIService.makeRequest] Successfully extracted content (\(content.count) chars)")
    return content
}

func generateSummary(from documentText: String) async throws -> String {
    print("🔍 [AIService] generateSummary called with \(documentText.count) characters")

    guard OpenRouterConfig.isConfigured else {
        print("❌ [AIService] API key not configured")
        throw AIError.notConfigured
    }

    print("✅ [AIService] API key configured, calling OpenRouter...")
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

    print("📡 [AIService] Sending summary generation request...")
    let summary = try await makeRequest(messages: messages, jsonMode: false)
    print("✅ [AIService] Summary generated (\(summary.count) chars)")
    return summary
}

func extractTasks(from documentText: String, organizationMembers: [User]) async throws -> [ExtractedTaskData] {
    guard OpenRouterConfig.isConfigured else {
        throw AIError.notConfigured
    }

    let memberContext = organizationMembers
        .map { "\($0.name) (email: \($0.email))" }
        .joined(separator: "\n")

    let messages = [
        [
            "role": "system",
            "content": """
            You are a task extraction specialist. Extract action items from meeting documents.
            Match assignee names to the provided member list, handling typos and nicknames.
            If no assignee mentioned, leave assigneeName as null.
            If no due date mentioned, leave dueDate as null.
            Infer priority from urgency language (urgent/ASAP = high, normal = medium, backlog/someday = low).
            """
        ],
        [
            "role": "user",
            "content": """
            Extract all action items and tasks from this meeting document.

            Organization members:
            \(memberContext)

            Document:
            \(documentText)

            For each task, extract:
            - title: Clear, actionable task description
            - assigneeName: Person assigned (match to members list above, or null if unclear)
            - dueDate: Deadline in ISO8601 format if mentioned (YYYY-MM-DD), or null
            - priority: "high", "medium", or "low" based on urgency language
            - context: Original text snippet where task was mentioned

            Return JSON with a "tasks" array containing these fields.
            """
        ]
    ]

    print("🔍 [AIService] Calling extractTasks API...")
    let jsonString = try await makeRequest(messages: messages, jsonMode: true)
    print("✅ [AIService] Received JSON response (\(jsonString.count) chars)")
    print("📄 [AIService] JSON Preview: \(String(jsonString.prefix(200)))...")

    guard let data = jsonString.data(using: .utf8) else {
        print("❌ [AIService] Failed to convert JSON string to data")
        throw AIError.parsingError
    }

    print("🔧 [AIService] Attempting to decode TaskExtractionSchema...")
    do {
        let schema = try JSONDecoder().decode(TaskExtractionSchema.self, from: data)
        print("✅ [AIService] Successfully decoded \(schema.tasks.count) tasks")
        return schema.tasks
    } catch {
        print("❌ [AIService] JSON decoding failed: \(error)")
        print("📋 [AIService] Raw JSON that failed to decode:")
        print(jsonString)
        throw AIError.parsingError
    }
}

// Main test
print("\n========================================")
print("🚀 Starting Document Processing Test")
print("========================================\n")

let pdfPath = "/Users/kian/projects/Business Retreat Jan 18 2026 (1).pdf"
let pdfUrl = URL(fileURLWithPath: pdfPath)

do {
    // Step 1: Parse document
    print("📄 Step 1: Parsing PDF document...")
    let documentText = try extractTextFromPDF(url: pdfUrl)
    print("✅ Document parsed: \(documentText.count) characters\n")

    // Step 2: Generate summary
    print("🤖 Step 2: Generating AI summary...")
    let summary = try await generateSummary(from: documentText)
    print("✅ Summary generated:")
    print("---")
    print(summary)
    print("---\n")

    // Step 3: Extract tasks
    print("🎯 Step 3: Extracting tasks...")
    let mockMembers = [
        User(id: UUID(), name: "John Smith", email: "john@example.com"),
        User(id: UUID(), name: "Sarah Johnson", email: "sarah@example.com"),
        User(id: UUID(), name: "Mike Chen", email: "mike@example.com")
    ]
    let tasks = try await extractTasks(from: documentText, organizationMembers: mockMembers)
    print("✅ Extracted \(tasks.count) tasks:\n")

    for (index, task) in tasks.enumerated() {
        print("Task \(index + 1):")
        print("  Title: \(task.title)")
        print("  Assignee: \(task.assigneeName ?? "None")")
        print("  Due Date: \(task.dueDate ?? "None")")
        print("  Priority: \(task.priority)")
        if let context = task.context {
            print("  Context: \(context)")
        }
        print("")
    }

    print("✅ ========================================")
    print("✅ TEST COMPLETED SUCCESSFULLY!")
    print("✅ ========================================\n")

} catch {
    print("\n❌ ========================================")
    print("❌ ERROR OCCURRED!")
    print("❌ Error: \(error)")
    print("❌ Localized: \(error.localizedDescription)")
    if let nsError = error as NSError? {
        print("❌ Domain: \(nsError.domain)")
        print("❌ Code: \(nsError.code)")
        print("❌ UserInfo: \(nsError.userInfo)")
    }
    print("❌ ========================================\n")
    exit(1)
}
