import Foundation

/// Represents a meeting within an organization.
/// Meetings have a lifecycle: scheduled → started → ended.
struct Meeting: Identifiable, Codable, Equatable {
    // MARK: - Properties

    /// Unique identifier for the meeting
    let id: UUID

    /// Organization ID this meeting belongs to
    let organizationId: UUID

    /// Meeting title/name
    let title: String

    /// When the meeting is scheduled to occur
    let scheduledAt: Date

    /// When the organizer actually started the meeting (nil if not started)
    var startedAt: Date?

    /// When the meeting concluded (nil if not ended)
    var endedAt: Date?

    /// URL to uploaded Google Docs meeting minutes (optional)
    var googleDocsUrl: String?

    /// AI-generated summary of the meeting (added in Phase 5)
    var summary: String?

    /// User IDs of members who checked in to this meeting
    var attendeeIds: [UUID]

    /// User ID of the organizer who created this meeting
    let createdById: UUID

    /// Extracted plain text from uploaded document (added in Phase 5)
    var documentText: String?

    /// Original document URL or identifier (added in Phase 5)
    var documentUrl: String?

    /// Timestamp when document was uploaded (added in Phase 5)
    var uploadedAt: Date?

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        organizationId: UUID,
        title: String,
        scheduledAt: Date,
        startedAt: Date? = nil,
        endedAt: Date? = nil,
        googleDocsUrl: String? = nil,
        summary: String? = nil,
        attendeeIds: [UUID] = [],
        createdById: UUID
    ) {
        self.id = id
        self.organizationId = organizationId
        self.title = title
        self.scheduledAt = scheduledAt
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.googleDocsUrl = googleDocsUrl
        self.summary = summary
        self.attendeeIds = attendeeIds
        self.createdById = createdById
    }

    // MARK: - Computed Properties

    /// Whether the meeting is currently active (started but not ended)
    var isActive: Bool {
        return startedAt != nil && endedAt == nil
    }

    /// Whether the meeting is scheduled in the future
    var isUpcoming: Bool {
        let now = Date()
        return scheduledAt > now && startedAt == nil
    }

    /// Whether the meeting has concluded
    var isPast: Bool {
        return endedAt != nil
    }
}
