import XCTest
@testable import MeetingManager

final class ProcessingStateTests: XCTestCase {

    // MARK: - isProcessing Tests

    func testIsProcessingForUploadingDocument() {
        let state = ProcessingState.uploadingDocument
        XCTAssertTrue(state.isProcessing, "uploadingDocument should be processing")
    }

    func testIsProcessingForParsingDocument() {
        let state = ProcessingState.parsingDocument
        XCTAssertTrue(state.isProcessing, "parsingDocument should be processing")
    }

    func testIsProcessingForGeneratingSummary() {
        let state = ProcessingState.generatingSummary
        XCTAssertTrue(state.isProcessing, "generatingSummary should be processing")
    }

    func testIsProcessingForExtractingTasks() {
        let state = ProcessingState.extractingTasks
        XCTAssertTrue(state.isProcessing, "extractingTasks should be processing")
    }

    func testIsNotProcessingForIdle() {
        let state = ProcessingState.idle
        XCTAssertFalse(state.isProcessing, "idle should not be processing")
    }

    func testIsNotProcessingForCompleted() {
        let state = ProcessingState.completed
        XCTAssertFalse(state.isProcessing, "completed should not be processing")
    }

    func testIsNotProcessingForFailed() {
        let state = ProcessingState.failed("Error message")
        XCTAssertFalse(state.isProcessing, "failed should not be processing")
    }

    // MARK: - displayText Tests

    func testDisplayTextForIdle() {
        let state = ProcessingState.idle
        XCTAssertEqual(state.displayText, "", "idle should have empty display text")
    }

    func testDisplayTextForUploadingDocument() {
        let state = ProcessingState.uploadingDocument
        XCTAssertEqual(state.displayText, "Uploading document...", "uploadingDocument should have correct display text")
    }

    func testDisplayTextForParsingDocument() {
        let state = ProcessingState.parsingDocument
        XCTAssertEqual(state.displayText, "Parsing document...", "parsingDocument should have correct display text")
    }

    func testDisplayTextForGeneratingSummary() {
        let state = ProcessingState.generatingSummary
        XCTAssertEqual(state.displayText, "Generating AI summary...", "generatingSummary should have correct display text")
    }

    func testDisplayTextForExtractingTasks() {
        let state = ProcessingState.extractingTasks
        XCTAssertEqual(state.displayText, "Extracting action items...", "extractingTasks should have correct display text")
    }

    func testDisplayTextForCompleted() {
        let state = ProcessingState.completed
        XCTAssertEqual(state.displayText, "Processing complete", "completed should have correct display text")
    }

    func testDisplayTextForFailed() {
        let errorMessage = "Network timeout"
        let state = ProcessingState.failed(errorMessage)
        XCTAssertEqual(state.displayText, "Error: \(errorMessage)", "failed should include error message in display text")
    }

    func testDisplayTextForFailedWithEmptyMessage() {
        let state = ProcessingState.failed("")
        XCTAssertEqual(state.displayText, "Error: ", "failed with empty message should still prefix with 'Error: '")
    }

    // MARK: - Equatable Tests

    func testIdleEquality() {
        let state1 = ProcessingState.idle
        let state2 = ProcessingState.idle
        XCTAssertEqual(state1, state2, "Two idle states should be equal")
    }

    func testUploadingEquality() {
        let state1 = ProcessingState.uploadingDocument
        let state2 = ProcessingState.uploadingDocument
        XCTAssertEqual(state1, state2, "Two uploadingDocument states should be equal")
    }

    func testParsingEquality() {
        let state1 = ProcessingState.parsingDocument
        let state2 = ProcessingState.parsingDocument
        XCTAssertEqual(state1, state2, "Two parsingDocument states should be equal")
    }

    func testGeneratingEquality() {
        let state1 = ProcessingState.generatingSummary
        let state2 = ProcessingState.generatingSummary
        XCTAssertEqual(state1, state2, "Two generatingSummary states should be equal")
    }

    func testExtractingEquality() {
        let state1 = ProcessingState.extractingTasks
        let state2 = ProcessingState.extractingTasks
        XCTAssertEqual(state1, state2, "Two extractingTasks states should be equal")
    }

    func testCompletedEquality() {
        let state1 = ProcessingState.completed
        let state2 = ProcessingState.completed
        XCTAssertEqual(state1, state2, "Two completed states should be equal")
    }

    func testFailedEqualityWithSameMessage() {
        let state1 = ProcessingState.failed("Network error")
        let state2 = ProcessingState.failed("Network error")
        XCTAssertEqual(state1, state2, "Two failed states with same message should be equal")
    }

    func testFailedInequalityWithDifferentMessages() {
        let state1 = ProcessingState.failed("Network error")
        let state2 = ProcessingState.failed("API error")
        XCTAssertNotEqual(state1, state2, "Two failed states with different messages should not be equal")
    }

    func testDifferentStatesInequality() {
        let idle = ProcessingState.idle
        let uploading = ProcessingState.uploadingDocument
        let parsing = ProcessingState.parsingDocument
        let generating = ProcessingState.generatingSummary
        let extracting = ProcessingState.extractingTasks
        let completed = ProcessingState.completed
        let failed = ProcessingState.failed("Error")

        XCTAssertNotEqual(idle, uploading, "idle and uploadingDocument should not be equal")
        XCTAssertNotEqual(uploading, parsing, "uploadingDocument and parsingDocument should not be equal")
        XCTAssertNotEqual(parsing, generating, "parsingDocument and generatingSummary should not be equal")
        XCTAssertNotEqual(generating, extracting, "generatingSummary and extractingTasks should not be equal")
        XCTAssertNotEqual(extracting, completed, "extractingTasks and completed should not be equal")
        XCTAssertNotEqual(completed, failed, "completed and failed should not be equal")
    }

    // MARK: - State Transition Tests

    func testTypicalProcessingFlow() {
        var state = ProcessingState.idle
        XCTAssertFalse(state.isProcessing, "Should start in non-processing state")

        state = .uploadingDocument
        XCTAssertTrue(state.isProcessing, "Should be processing during upload")

        state = .parsingDocument
        XCTAssertTrue(state.isProcessing, "Should be processing during parsing")

        state = .generatingSummary
        XCTAssertTrue(state.isProcessing, "Should be processing during summary generation")

        state = .extractingTasks
        XCTAssertTrue(state.isProcessing, "Should be processing during task extraction")

        state = .completed
        XCTAssertFalse(state.isProcessing, "Should not be processing when completed")
    }

    func testFailedStateFlow() {
        var state = ProcessingState.parsingDocument
        XCTAssertTrue(state.isProcessing, "Should be processing")

        state = .failed("Parse error")
        XCTAssertFalse(state.isProcessing, "Should not be processing after failure")
        XCTAssertTrue(state.displayText.contains("Parse error"), "Should display error message")
    }

    // MARK: - Edge Cases

    func testFailedWithVeryLongErrorMessage() {
        let longError = String(repeating: "Error ", count: 100)
        let state = ProcessingState.failed(longError)
        XCTAssertTrue(state.displayText.contains("Error: Error Error"), "Should handle long error messages")
        XCTAssertFalse(state.isProcessing, "Should not be processing")
    }

    func testFailedWithSpecialCharacters() {
        let specialError = "Error: <script>alert('XSS')</script>"
        let state = ProcessingState.failed(specialError)
        XCTAssertEqual(state.displayText, "Error: \(specialError)", "Should preserve special characters in error message")
    }

    func testFailedWithUnicode() {
        let unicodeError = "Erreur: échec de téléchargement 🚫"
        let state = ProcessingState.failed(unicodeError)
        XCTAssertEqual(state.displayText, "Error: \(unicodeError)", "Should preserve unicode in error message")
    }

    func testMultilineErrorMessage() {
        let multilineError = "Network error\nConnection timeout\nRetry failed"
        let state = ProcessingState.failed(multilineError)
        XCTAssertEqual(state.displayText, "Error: \(multilineError)", "Should preserve multiline error messages")
    }
}
