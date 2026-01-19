import Supabase
import Foundation

/// Errors that can occur during meeting operations
enum MeetingError: Error, LocalizedError {
    case notStarted
    case alreadyEnded
    case notAMember

    var errorDescription: String? {
        switch self {
        case .notStarted:
            return "This meeting has not started yet. Only active meetings allow check-in."
        case .alreadyEnded:
            return "This meeting has already ended. Check-in is no longer available."
        case .notAMember:
            return "You are not a member of this organization and cannot check in to this meeting."
        }
    }
}

/// Actor-based meeting service for thread-safe database operations.
/// Manages meeting creation, updates, and queries with Supabase backend.
actor MeetingService {
    // MARK: - Properties

    private let supabase: SupabaseClient

    // MARK: - Database Models

    /// Database representation of Meeting with snake_case column names
    private struct MeetingDTO: Codable {
        let id: UUID
        let organizationId: UUID
        let title: String
        let scheduledAt: Date
        let startedAt: Date?
        let endedAt: Date?
        let googleDocsUrl: String?
        let summary: String?
        let attendeeIds: [UUID]
        let createdById: UUID
        let documentText: String?
        let documentUrl: String?
        let uploadedAt: Date?

        enum CodingKeys: String, CodingKey {
            case id
            case organizationId = "organization_id"
            case title
            case scheduledAt = "scheduled_at"
            case startedAt = "started_at"
            case endedAt = "ended_at"
            case googleDocsUrl = "google_docs_url"
            case summary
            case attendeeIds = "attendee_ids"
            case createdById = "created_by_id"
            case documentText = "document_text"
            case documentUrl = "document_url"
            case uploadedAt = "uploaded_at"
        }
    }

    // MARK: - Initialization

    init(supabaseClient: SupabaseClient = SupabaseConfig.shared) {
        self.supabase = supabaseClient
    }

    // MARK: - Meeting Methods

    /// Create a new meeting for an organization
    /// - Parameters:
    ///   - organizationId: Organization ID this meeting belongs to
    ///   - title: Meeting title/name
    ///   - scheduledAt: When the meeting is scheduled to occur
    ///   - createdById: User ID of the organizer creating the meeting
    /// - Returns: Newly created Meeting model
    /// - Throws: Supabase database errors
    func createMeeting(
        organizationId: UUID,
        title: String,
        scheduledAt: Date,
        createdById: UUID
    ) async throws -> Meeting {
        // Generate unique ID
        let meetingId = UUID()

        // Create meeting model
        let meeting = Meeting(
            id: meetingId,
            organizationId: organizationId,
            title: title,
            scheduledAt: scheduledAt,
            startedAt: nil,
            endedAt: nil,
            googleDocsUrl: nil,
            summary: nil,
            attendeeIds: [],
            createdById: createdById
        )

        // Map to database format
        let dto = MeetingDTO(
            id: meeting.id,
            organizationId: meeting.organizationId,
            title: meeting.title,
            scheduledAt: meeting.scheduledAt,
            startedAt: meeting.startedAt,
            endedAt: meeting.endedAt,
            googleDocsUrl: meeting.googleDocsUrl,
            summary: meeting.summary,
            attendeeIds: meeting.attendeeIds,
            createdById: meeting.createdById,
            documentText: meeting.documentText,
            documentUrl: meeting.documentUrl,
            uploadedAt: meeting.uploadedAt
        )

        // Insert into Supabase meetings table
        try await supabase
            .from("meetings")
            .insert(dto)
            .execute()

        return meeting
    }

    /// Fetch all meetings for an organization, ordered by scheduled date descending
    /// - Parameter organizationId: The organization ID
    /// - Returns: Array of Meeting models ordered by scheduledAt descending
    /// - Throws: Supabase database errors
    func fetchMeetingsForOrganization(organizationId: UUID) async throws -> [Meeting] {
        let dtos: [MeetingDTO] = try await supabase
            .from("meetings")
            .select()
            .eq("organization_id", value: organizationId)
            .order("scheduled_at", ascending: false)
            .execute()
            .value

        // Map to Meeting models
        return dtos.map { dto in
            Meeting(
                id: dto.id,
                organizationId: dto.organizationId,
                title: dto.title,
                scheduledAt: dto.scheduledAt,
                startedAt: dto.startedAt,
                endedAt: dto.endedAt,
                googleDocsUrl: dto.googleDocsUrl,
                summary: dto.summary,
                attendeeIds: dto.attendeeIds,
                createdById: dto.createdById,
                documentText: dto.documentText,
                documentUrl: dto.documentUrl,
                uploadedAt: dto.uploadedAt
            )
        }
    }

    /// Upload document to a meeting
    /// - Parameters:
    ///   - meetingId: Meeting ID to update
    ///   - documentText: Extracted plain text from document
    ///   - documentUrl: Original file URL or identifier
    ///   - uploadedAt: Timestamp of document upload
    /// - Returns: Updated Meeting model
    /// - Throws: Supabase database errors
    func uploadDocument(
        meetingId: UUID,
        documentText: String,
        documentUrl: String,
        uploadedAt: Date = Date()
    ) async throws -> Meeting {
        // Create update DTO with document fields
        struct DocumentUpdateDTO: Codable {
            let documentText: String
            let documentUrl: String
            let uploadedAt: Date

            enum CodingKeys: String, CodingKey {
                case documentText = "document_text"
                case documentUrl = "document_url"
                case uploadedAt = "uploaded_at"
            }
        }

        let updateDTO = DocumentUpdateDTO(
            documentText: documentText,
            documentUrl: documentUrl,
            uploadedAt: uploadedAt
        )

        // Update meeting in database
        let dto: MeetingDTO = try await supabase
            .from("meetings")
            .update(updateDTO)
            .eq("id", value: meetingId)
            .select()
            .single()
            .execute()
            .value

        return Meeting(
            id: dto.id,
            organizationId: dto.organizationId,
            title: dto.title,
            scheduledAt: dto.scheduledAt,
            startedAt: dto.startedAt,
            endedAt: dto.endedAt,
            googleDocsUrl: dto.googleDocsUrl,
            summary: dto.summary,
            attendeeIds: dto.attendeeIds,
            createdById: dto.createdById,
            documentText: dto.documentText,
            documentUrl: dto.documentUrl,
            uploadedAt: dto.uploadedAt
        )
    }

    /// Fetch a specific meeting by ID
    /// - Parameter id: The meeting ID to fetch
    /// - Returns: Meeting model
    /// - Throws: Supabase database errors if not found
    func fetchMeeting(id: UUID) async throws -> Meeting {
        let dto: MeetingDTO = try await supabase
            .from("meetings")
            .select()
            .eq("id", value: id)
            .single()
            .execute()
            .value

        return Meeting(
            id: dto.id,
            organizationId: dto.organizationId,
            title: dto.title,
            scheduledAt: dto.scheduledAt,
            startedAt: dto.startedAt,
            endedAt: dto.endedAt,
            googleDocsUrl: dto.googleDocsUrl,
            summary: dto.summary,
            attendeeIds: dto.attendeeIds,
            createdById: dto.createdById,
            documentText: dto.documentText,
            documentUrl: dto.documentUrl,
            uploadedAt: dto.uploadedAt
        )
    }

    /// Update a meeting's started_at or ended_at timestamps
    /// - Parameters:
    ///   - id: The meeting ID to update
    ///   - startedAt: Optional started timestamp to set
    ///   - endedAt: Optional ended timestamp to set
    /// - Returns: Updated Meeting model
    /// - Throws: Supabase database errors
    func updateMeeting(
        id: UUID,
        startedAt: Date? = nil,
        endedAt: Date? = nil
    ) async throws -> Meeting {
        // Create update DTO with only the fields to update
        struct MeetingUpdateDTO: Codable {
            let startedAt: Date?
            let endedAt: Date?

            enum CodingKeys: String, CodingKey {
                case startedAt = "started_at"
                case endedAt = "ended_at"
            }
        }

        let updateDTO = MeetingUpdateDTO(
            startedAt: startedAt,
            endedAt: endedAt
        )

        // Update meeting in database
        let dto: MeetingDTO = try await supabase
            .from("meetings")
            .update(updateDTO)
            .eq("id", value: id)
            .select()
            .single()
            .execute()
            .value

        return Meeting(
            id: dto.id,
            organizationId: dto.organizationId,
            title: dto.title,
            scheduledAt: dto.scheduledAt,
            startedAt: dto.startedAt,
            endedAt: dto.endedAt,
            googleDocsUrl: dto.googleDocsUrl,
            summary: dto.summary,
            attendeeIds: dto.attendeeIds,
            createdById: dto.createdById,
            documentText: dto.documentText,
            documentUrl: dto.documentUrl,
            uploadedAt: dto.uploadedAt
        )
    }

    /// Check in a user to a meeting
    /// - Parameters:
    ///   - meetingId: The meeting ID to check in to
    ///   - userId: The user ID checking in
    /// - Returns: Updated Meeting model with user added to attendeeIds
    /// - Throws: MeetingError for validation failures, Supabase database errors
    func checkIn(meetingId: UUID, userId: UUID) async throws -> Meeting {
        // Fetch current meeting state
        let meeting = try await fetchMeeting(id: meetingId)

        // Validate meeting state - must be started
        if meeting.startedAt == nil {
            throw MeetingError.notStarted
        }

        // Validate meeting hasn't ended
        if meeting.endedAt != nil {
            throw MeetingError.alreadyEnded
        }

        // Fetch organization to verify membership
        let organizationService = OrganizationService()
        let organization = try await organizationService.fetchOrganization(id: meeting.organizationId)

        // Validate user is a member of the organization
        if !organization.memberIds.contains(userId) {
            throw MeetingError.notAMember
        }

        // Early return if user already checked in (idempotent)
        if meeting.attendeeIds.contains(userId) {
            return meeting
        }

        // Add user to attendee list
        var updatedAttendeeIds = meeting.attendeeIds
        updatedAttendeeIds.append(userId)

        // Create update DTO with only attendee_ids field
        struct AttendeeUpdateDTO: Codable {
            let attendeeIds: [UUID]

            enum CodingKeys: String, CodingKey {
                case attendeeIds = "attendee_ids"
            }
        }

        let updateDTO = AttendeeUpdateDTO(attendeeIds: updatedAttendeeIds)

        // Update database with new attendee list
        let dto: MeetingDTO = try await supabase
            .from("meetings")
            .update(updateDTO)
            .eq("id", value: meetingId)
            .select()
            .single()
            .execute()
            .value

        return Meeting(
            id: dto.id,
            organizationId: dto.organizationId,
            title: dto.title,
            scheduledAt: dto.scheduledAt,
            startedAt: dto.startedAt,
            endedAt: dto.endedAt,
            googleDocsUrl: dto.googleDocsUrl,
            summary: dto.summary,
            attendeeIds: dto.attendeeIds,
            createdById: dto.createdById
        )
    }
}
