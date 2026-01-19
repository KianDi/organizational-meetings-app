import Supabase
import Foundation

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
            createdById: meeting.createdById
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
                createdById: dto.createdById
            )
        }
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
            createdById: dto.createdById
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
            createdById: dto.createdById
        )
    }

    /// Check in a user to a meeting
    /// - Parameters:
    ///   - meetingId: The meeting ID to check in to
    ///   - userId: The user ID checking in
    /// - Returns: Updated Meeting model with user added to attendeeIds
    /// - Throws: Supabase database errors
    func checkIn(meetingId: UUID, userId: UUID) async throws -> Meeting {
        // Fetch current meeting state
        let meeting = try await fetchMeeting(id: meetingId)

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
