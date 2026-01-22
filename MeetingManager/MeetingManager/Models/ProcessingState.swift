import Foundation

/// Tracks the state of AI processing for a meeting
enum ProcessingState: Equatable {
    case idle
    case uploadingDocument
    case parsingDocument
    case generatingSummary
    case extractingTasks  // Used in 05-04
    case completed
    case failed(String)   // Error message

    var isProcessing: Bool {
        switch self {
        case .uploadingDocument, .parsingDocument, .generatingSummary, .extractingTasks:
            return true
        default:
            return false
        }
    }

    var displayText: String {
        switch self {
        case .idle:
            return ""
        case .uploadingDocument:
            return "Uploading document..."
        case .parsingDocument:
            return "Parsing document..."
        case .generatingSummary:
            return "Generating AI summary..."
        case .extractingTasks:
            return "Extracting action items..."
        case .completed:
            return "Processing complete"
        case .failed(let message):
            return "Error: \(message)"
        }
    }
}
