import XCTest
@testable import MeetingManager

final class MeetingTests: XCTestCase {

    // MARK: - Test Data

    let organizationId = UUID()
    let creatorId = UUID()
    let now = Date()
    lazy var futureDate = Calendar.current.date(byAdding: .hour, value: 2, to: now)!
    lazy var pastDate = Calendar.current.date(byAdding: .hour, value: -2, to: now)!

    // MARK: - isActive Tests

    func testIsActiveWhenStartedButNotEnded() {
        let meeting = Meeting(
            organizationId: organizationId,
            title: "Team Meeting",
            scheduledAt: pastDate,
            startedAt: now,
            endedAt: nil,
            createdById: creatorId
        )
        XCTAssertTrue(meeting.isActive, "Meeting should be active when started but not ended")
    }

    func testIsNotActiveWhenNotStarted() {
        let meeting = Meeting(
            organizationId: organizationId,
            title: "Team Meeting",
            scheduledAt: futureDate,
            startedAt: nil,
            endedAt: nil,
            createdById: creatorId
        )
        XCTAssertFalse(meeting.isActive, "Meeting should not be active when not started")
    }

    func testIsNotActiveWhenEnded() {
        let meeting = Meeting(
            organizationId: organizationId,
            title: "Team Meeting",
            scheduledAt: pastDate,
            startedAt: pastDate,
            endedAt: now,
            createdById: creatorId
        )
        XCTAssertFalse(meeting.isActive, "Meeting should not be active when ended")
    }

    func testIsNotActiveWhenNeitherStartedNorEnded() {
        let meeting = Meeting(
            organizationId: organizationId,
            title: "Team Meeting",
            scheduledAt: futureDate,
            startedAt: nil,
            endedAt: nil,
            createdById: creatorId
        )
        XCTAssertFalse(meeting.isActive, "Meeting should not be active when neither started nor ended")
    }

    // MARK: - isUpcoming Tests

    func testIsUpcomingWhenScheduledInFutureAndNotStarted() {
        let meeting = Meeting(
            organizationId: organizationId,
            title: "Team Meeting",
            scheduledAt: futureDate,
            startedAt: nil,
            endedAt: nil,
            createdById: creatorId
        )
        XCTAssertTrue(meeting.isUpcoming, "Meeting should be upcoming when scheduled in future and not started")
    }

    func testIsNotUpcomingWhenScheduledInPast() {
        let meeting = Meeting(
            organizationId: organizationId,
            title: "Team Meeting",
            scheduledAt: pastDate,
            startedAt: nil,
            endedAt: nil,
            createdById: creatorId
        )
        XCTAssertFalse(meeting.isUpcoming, "Meeting should not be upcoming when scheduled in past")
    }

    func testIsNotUpcomingWhenAlreadyStarted() {
        let meeting = Meeting(
            organizationId: organizationId,
            title: "Team Meeting",
            scheduledAt: futureDate,
            startedAt: now,
            endedAt: nil,
            createdById: creatorId
        )
        XCTAssertFalse(meeting.isUpcoming, "Meeting should not be upcoming when already started")
    }

    func testIsNotUpcomingWhenEnded() {
        let meeting = Meeting(
            organizationId: organizationId,
            title: "Team Meeting",
            scheduledAt: futureDate,
            startedAt: pastDate,
            endedAt: now,
            createdById: creatorId
        )
        XCTAssertFalse(meeting.isUpcoming, "Meeting should not be upcoming when ended")
    }

    // MARK: - isPast Tests

    func testIsPastWhenEnded() {
        let meeting = Meeting(
            organizationId: organizationId,
            title: "Team Meeting",
            scheduledAt: pastDate,
            startedAt: pastDate,
            endedAt: now,
            createdById: creatorId
        )
        XCTAssertTrue(meeting.isPast, "Meeting should be past when ended")
    }

    func testIsNotPastWhenNotEnded() {
        let meeting = Meeting(
            organizationId: organizationId,
            title: "Team Meeting",
            scheduledAt: pastDate,
            startedAt: now,
            endedAt: nil,
            createdById: creatorId
        )
        XCTAssertFalse(meeting.isPast, "Meeting should not be past when not ended")
    }

    func testIsNotPastWhenUpcoming() {
        let meeting = Meeting(
            organizationId: organizationId,
            title: "Team Meeting",
            scheduledAt: futureDate,
            startedAt: nil,
            endedAt: nil,
            createdById: creatorId
        )
        XCTAssertFalse(meeting.isPast, "Meeting should not be past when upcoming")
    }

    // MARK: - State Transition Tests

    func testMeetingLifecycle() {
        var meeting = Meeting(
            organizationId: organizationId,
            title: "Team Meeting",
            scheduledAt: futureDate,
            createdById: creatorId
        )

        // Initial state: upcoming
        XCTAssertTrue(meeting.isUpcoming, "New meeting should be upcoming")
        XCTAssertFalse(meeting.isActive, "New meeting should not be active")
        XCTAssertFalse(meeting.isPast, "New meeting should not be past")

        // Start the meeting
        meeting.startedAt = now
        XCTAssertFalse(meeting.isUpcoming, "Started meeting should not be upcoming")
        XCTAssertTrue(meeting.isActive, "Started meeting should be active")
        XCTAssertFalse(meeting.isPast, "Started meeting should not be past")

        // End the meeting
        meeting.endedAt = Date()
        XCTAssertFalse(meeting.isUpcoming, "Ended meeting should not be upcoming")
        XCTAssertFalse(meeting.isActive, "Ended meeting should not be active")
        XCTAssertTrue(meeting.isPast, "Ended meeting should be past")
    }

    // MARK: - Codable Tests

    func testMeetingEncodingAndDecoding() throws {
        let original = Meeting(
            id: UUID(),
            organizationId: organizationId,
            title: "Test Meeting",
            scheduledAt: now,
            startedAt: pastDate,
            endedAt: nil,
            googleDocsUrl: "https://docs.google.com/document/d/123",
            summary: "Test summary",
            attendeeIds: [UUID(), UUID()],
            createdById: creatorId,
            documentText: "Test document text",
            documentUrl: "https://example.com/doc.pdf",
            uploadedAt: now
        )

        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let decoded = try decoder.decode(Meeting.self, from: data)

        XCTAssertEqual(decoded.id, original.id, "IDs should match")
        XCTAssertEqual(decoded.organizationId, original.organizationId, "Organization IDs should match")
        XCTAssertEqual(decoded.title, original.title, "Titles should match")
        XCTAssertEqual(decoded.googleDocsUrl, original.googleDocsUrl, "Google Docs URLs should match")
        XCTAssertEqual(decoded.summary, original.summary, "Summaries should match")
        XCTAssertEqual(decoded.attendeeIds, original.attendeeIds, "Attendee IDs should match")
        XCTAssertEqual(decoded.createdById, original.createdById, "Creator IDs should match")
        XCTAssertEqual(decoded.documentText, original.documentText, "Document text should match")
        XCTAssertEqual(decoded.documentUrl, original.documentUrl, "Document URLs should match")
    }

    func testMeetingEncodingWithNilOptionalFields() throws {
        let original = Meeting(
            organizationId: organizationId,
            title: "Minimal Meeting",
            scheduledAt: now,
            createdById: creatorId
        )

        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let decoded = try decoder.decode(Meeting.self, from: data)

        XCTAssertNil(decoded.startedAt, "startedAt should be nil")
        XCTAssertNil(decoded.endedAt, "endedAt should be nil")
        XCTAssertNil(decoded.googleDocsUrl, "googleDocsUrl should be nil")
        XCTAssertNil(decoded.summary, "summary should be nil")
        XCTAssertNil(decoded.documentText, "documentText should be nil")
        XCTAssertNil(decoded.documentUrl, "documentUrl should be nil")
        XCTAssertNil(decoded.uploadedAt, "uploadedAt should be nil")
        XCTAssertTrue(decoded.attendeeIds.isEmpty, "attendeeIds should be empty")
    }

    // MARK: - Initialization Tests

    func testDefaultInitialization() {
        let meeting = Meeting(
            organizationId: organizationId,
            title: "Default Meeting",
            scheduledAt: now,
            createdById: creatorId
        )

        XCTAssertNotNil(meeting.id, "ID should be generated")
        XCTAssertEqual(meeting.organizationId, organizationId, "Organization ID should match")
        XCTAssertEqual(meeting.title, "Default Meeting", "Title should match")
        XCTAssertEqual(meeting.scheduledAt, now, "Scheduled date should match")
        XCTAssertEqual(meeting.createdById, creatorId, "Creator ID should match")
        XCTAssertNil(meeting.startedAt, "startedAt should default to nil")
        XCTAssertNil(meeting.endedAt, "endedAt should default to nil")
        XCTAssertTrue(meeting.attendeeIds.isEmpty, "attendeeIds should default to empty array")
        XCTAssertNil(meeting.summary, "summary should default to nil")
    }

    // MARK: - Equatable Tests

    func testMeetingEquality() {
        let id = UUID()
        let meeting1 = Meeting(
            id: id,
            organizationId: organizationId,
            title: "Meeting 1",
            scheduledAt: now,
            createdById: creatorId
        )
        let meeting2 = Meeting(
            id: id,
            organizationId: organizationId,
            title: "Meeting 1",
            scheduledAt: now,
            createdById: creatorId
        )

        XCTAssertEqual(meeting1, meeting2, "Meetings with same properties should be equal")
    }

    func testMeetingInequality() {
        let meeting1 = Meeting(
            organizationId: organizationId,
            title: "Meeting 1",
            scheduledAt: now,
            createdById: creatorId
        )
        let meeting2 = Meeting(
            organizationId: organizationId,
            title: "Meeting 2",
            scheduledAt: now,
            createdById: creatorId
        )

        XCTAssertNotEqual(meeting1, meeting2, "Meetings with different IDs should not be equal")
    }
}
