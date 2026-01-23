import Supabase
import Foundation

/// Actor-based task service for thread-safe database operations.
/// Manages task creation, updates, and queries with Supabase backend.
actor TaskService {
    // MARK: - Properties

    private let supabase: SupabaseClient

    // MARK: - Database Models

    /// Database representation of MeetingTask with snake_case column names
    private struct TaskDTO: Codable {
        let id: UUID
        let meetingId: UUID
        let organizationId: UUID
        let title: String
        let assigneeId: UUID?
        let dueDate: Date?
        let isCompleted: Bool
        let createdAt: Date
        let extractedFrom: String?
        let priority: String?

        enum CodingKeys: String, CodingKey {
            case id
            case meetingId = "meeting_id"
            case organizationId = "organization_id"
            case title
            case assigneeId = "assignee_id"
            case dueDate = "due_date"
            case isCompleted = "is_completed"
            case createdAt = "created_at"
            case extractedFrom = "extracted_from"
            case priority
        }
    }

    // MARK: - Initialization

    init(supabaseClient: SupabaseClient = SupabaseConfig.shared) {
        self.supabase = supabaseClient
    }

    // MARK: - Task Methods

    /// Create multiple tasks for a meeting (used after AI extraction)
    /// - Parameter tasks: Array of MeetingTask models to create
    /// - Returns: Array of created MeetingTask models with database IDs
    /// - Throws: Supabase database errors
    func createTasks(_ tasks: [MeetingTask]) async throws -> [MeetingTask] {
        // Map to DTOs for database insertion
        let dtos = tasks.map { task in
            TaskDTO(
                id: task.id,
                meetingId: task.meetingId,
                organizationId: task.organizationId,
                title: task.title,
                assigneeId: task.assigneeId,
                dueDate: task.dueDate,
                isCompleted: task.isCompleted,
                createdAt: task.createdAt,
                extractedFrom: task.extractedFrom,
                priority: nil  // Priority not in MeetingTask model yet
            )
        }

        // Insert into Supabase tasks table
        let responseDTOs: [TaskDTO] = try await supabase
            .from("tasks")
            .insert(dtos)
            .select()
            .execute()
            .value

        // Map back to MeetingTask models
        return responseDTOs.map { dto in
            MeetingTask(
                id: dto.id,
                meetingId: dto.meetingId,
                organizationId: dto.organizationId,
                title: dto.title,
                assigneeId: dto.assigneeId,
                dueDate: dto.dueDate,
                isCompleted: dto.isCompleted,
                createdAt: dto.createdAt,
                extractedFrom: dto.extractedFrom
            )
        }
    }

    /// Fetch all tasks for an organization, ordered by due date
    /// - Parameter organizationId: The organization ID
    /// - Returns: Array of MeetingTask models ordered by due date (soonest first)
    /// - Throws: Supabase database errors
    func fetchTasksForOrganization(organizationId: UUID) async throws -> [MeetingTask] {
        let dtos: [TaskDTO] = try await supabase
            .from("tasks")
            .select()
            .eq("organization_id", value: organizationId)
            .order("due_date", ascending: true)
            .execute()
            .value

        return dtos.map { dto in
            MeetingTask(
                id: dto.id,
                meetingId: dto.meetingId,
                organizationId: dto.organizationId,
                title: dto.title,
                assigneeId: dto.assigneeId,
                dueDate: dto.dueDate,
                isCompleted: dto.isCompleted,
                createdAt: dto.createdAt,
                extractedFrom: dto.extractedFrom
            )
        }
    }

    /// Fetch tasks for a specific meeting
    /// - Parameter meetingId: The meeting ID
    /// - Returns: Array of MeetingTask models ordered by creation time
    /// - Throws: Supabase database errors
    func fetchTasksForMeeting(meetingId: UUID) async throws -> [MeetingTask] {
        let dtos: [TaskDTO] = try await supabase
            .from("tasks")
            .select()
            .eq("meeting_id", value: meetingId)
            .order("created_at", ascending: true)
            .execute()
            .value

        return dtos.map { dto in
            MeetingTask(
                id: dto.id,
                meetingId: dto.meetingId,
                organizationId: dto.organizationId,
                title: dto.title,
                assigneeId: dto.assigneeId,
                dueDate: dto.dueDate,
                isCompleted: dto.isCompleted,
                createdAt: dto.createdAt,
                extractedFrom: dto.extractedFrom
            )
        }
    }

    /// Update task completion status
    /// - Parameters:
    ///   - taskId: The task ID to update
    ///   - isCompleted: New completion status
    /// - Returns: Updated MeetingTask model
    /// - Throws: Supabase database errors
    func updateTaskCompletion(taskId: UUID, isCompleted: Bool) async throws -> MeetingTask {
        // Create update DTO with only is_completed field
        struct CompletionUpdateDTO: Codable {
            let isCompleted: Bool

            enum CodingKeys: String, CodingKey {
                case isCompleted = "is_completed"
            }
        }

        let updateDTO = CompletionUpdateDTO(isCompleted: isCompleted)

        let dto: TaskDTO = try await supabase
            .from("tasks")
            .update(updateDTO)
            .eq("id", value: taskId)
            .select()
            .single()
            .execute()
            .value

        return MeetingTask(
            id: dto.id,
            meetingId: dto.meetingId,
            organizationId: dto.organizationId,
            title: dto.title,
            assigneeId: dto.assigneeId,
            dueDate: dto.dueDate,
            isCompleted: dto.isCompleted,
            createdAt: dto.createdAt,
            extractedFrom: dto.extractedFrom
        )
    }

    /// Delete a task
    /// - Parameter taskId: The task ID to delete
    /// - Throws: Supabase database errors
    func deleteTask(taskId: UUID) async throws {
        try await supabase
            .from("tasks")
            .delete()
            .eq("id", value: taskId)
            .execute()
    }
}
