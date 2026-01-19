import Foundation
import PDFKit

/// Errors that can occur during document operations
enum DocumentError: Error, LocalizedError {
    case unsupportedFormat
    case emptyDocument
    case parsingFailed
    case securityScopedAccessDenied
    case fileSizeLimitExceeded

    var errorDescription: String? {
        switch self {
        case .unsupportedFormat:
            return "This file format is not supported. Please upload a PDF or plain text file."
        case .emptyDocument:
            return "The document appears to be empty or contains no readable text."
        case .parsingFailed:
            return "Failed to extract text from the document. Please try a different file."
        case .securityScopedAccessDenied:
            return "Unable to access the file. Please try selecting it again."
        case .fileSizeLimitExceeded:
            return "File size exceeds 10MB limit. Please upload a smaller document."
        }
    }
}

/// Actor-based document service for thread-safe document parsing.
/// Handles PDF and plain text document extraction with PDFKit.
actor DocumentService {
    // MARK: - Constants

    /// Maximum file size in bytes (10MB)
    private let maxFileSizeBytes: Int = 10 * 1024 * 1024

    // MARK: - Document Parsing

    /// Extract text from a document URL (supports PDF and plain text)
    /// - Parameter url: File URL from document picker (must be security-scoped)
    /// - Returns: Extracted plain text content
    /// - Throws: DocumentError for unsupported formats, empty documents, or parsing failures
    func parseDocument(url: URL) async throws -> String {
        // Start accessing security-scoped resource
        guard url.startAccessingSecurityScopedResource() else {
            throw DocumentError.securityScopedAccessDenied
        }
        defer { url.stopAccessingSecurityScopedResource() }

        // Check file size
        let fileAttributes = try FileManager.default.attributesOfItem(atPath: url.path)
        guard let fileSize = fileAttributes[.size] as? Int else {
            throw DocumentError.parsingFailed
        }

        if fileSize > maxFileSizeBytes {
            throw DocumentError.fileSizeLimitExceeded
        }

        // Determine file type and parse accordingly
        let pathExtension = url.pathExtension.lowercased()

        switch pathExtension {
        case "pdf":
            return try await parsePDF(url: url)
        case "txt", "text":
            return try await parseTextFile(url: url)
        default:
            throw DocumentError.unsupportedFormat
        }
    }

    /// Extract text from PDF document using PDFKit
    /// - Parameter url: PDF file URL
    /// - Returns: Extracted text content
    /// - Throws: DocumentError if PDF cannot be read or is empty
    private func parsePDF(url: URL) async throws -> String {
        guard let pdfDocument = PDFDocument(url: url) else {
            throw DocumentError.parsingFailed
        }

        var extractedText = ""

        // Iterate through all pages and extract text
        for pageIndex in 0..<pdfDocument.pageCount {
            guard let page = pdfDocument.page(at: pageIndex),
                  let pageText = page.string else {
                continue
            }
            extractedText += pageText + "\n"
        }

        // Trim whitespace and validate content
        let trimmedText = extractedText.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmedText.isEmpty {
            throw DocumentError.emptyDocument
        }

        return trimmedText
    }

    /// Extract text from plain text file
    /// - Parameter url: Text file URL
    /// - Returns: File content as string
    /// - Throws: DocumentError if file cannot be read or is empty
    private func parseTextFile(url: URL) async throws -> String {
        guard let content = try? String(contentsOf: url, encoding: .utf8) else {
            throw DocumentError.parsingFailed
        }

        let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmedContent.isEmpty {
            throw DocumentError.emptyDocument
        }

        return trimmedContent
    }

    // MARK: - Database Integration

    /// Upload parsed document to a meeting record
    /// - Parameters:
    ///   - meetingId: Meeting ID to update
    ///   - documentText: Extracted text content
    ///   - documentUrl: Original file URL or identifier
    /// - Returns: Updated Meeting model
    /// - Throws: Database errors from MeetingService
    func uploadDocumentToMeeting(
        meetingId: UUID,
        documentText: String,
        documentUrl: String
    ) async throws -> Meeting {
        let meetingService = MeetingService()
        return try await meetingService.uploadDocument(
            meetingId: meetingId,
            documentText: documentText,
            documentUrl: documentUrl,
            uploadedAt: Date()
        )
    }
}
