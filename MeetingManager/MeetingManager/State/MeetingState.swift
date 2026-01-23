import SwiftUI
import Observation
import Foundation

@Observable
final class MeetingState {
    private(set) var meetings: [Meeting] = []
    private(set) var isLoading: Bool = false
    private(set) var processingState: ProcessingState = .idle

    private let meetingService: MeetingService
    private let aiService: AIService
    private let taskService: TaskService
    private let organizationService: OrganizationService

    init(
        meetingService: MeetingService = MeetingService(),
        aiService: AIService = AIService(),
        taskService: TaskService = TaskService(),
        organizationService: OrganizationService = OrganizationService()
    ) {
        self.meetingService = meetingService
        self.aiService = aiService
        self.taskService = taskService
        self.organizationService = organizationService
    }

    @MainActor
    func loadMeetings(organizationId: UUID) async throws {
        isLoading = true
        defer { isLoading = false }

        let fetchedMeetings = try await meetingService.fetchMeetingsForOrganization(organizationId: organizationId)
        meetings = fetchedMeetings
    }

    @MainActor
    func loadMeetingWithTasks(meetingId: UUID) async throws -> Meeting {
        // Fetch meeting
        var meeting = try await meetingService.fetchMeeting(id: meetingId)

        // Fetch associated tasks
        let tasks = try await taskService.fetchTasksForMeeting(meetingId: meetingId)
        meeting.tasks = tasks

        // Update local cache
        if let index = meetings.firstIndex(where: { $0.id == meetingId }) {
            meetings[index] = meeting
        }

        return meeting
    }

    @MainActor
    func createMeeting(
        organizationId: UUID,
        title: String,
        scheduledAt: Date,
        createdById: UUID
    ) async throws -> Meeting {
        let meeting = try await meetingService.createMeeting(
            organizationId: organizationId,
            title: title,
            scheduledAt: scheduledAt,
            createdById: createdById
        )

        // Append to local meetings array for instant UI update
        meetings.append(meeting)

        return meeting
    }

    @MainActor
    func checkIn(meetingId: UUID, userId: UUID) async throws {
        let updatedMeeting = try await meetingService.checkIn(meetingId: meetingId, userId: userId)

        // Update meeting in local array
        if let index = meetings.firstIndex(where: { $0.id == meetingId }) {
            meetings[index] = updatedMeeting
        }
    }

    @MainActor
    func startMeeting(meetingId: UUID) async throws {
        let updatedMeeting = try await meetingService.updateMeeting(
            id: meetingId,
            startedAt: Date()
        )

        // Update meeting in local array
        if let index = meetings.firstIndex(where: { $0.id == meetingId }) {
            meetings[index] = updatedMeeting
        }
    }

    @MainActor
    func endMeeting(meetingId: UUID) async throws {
        let updatedMeeting = try await meetingService.updateMeeting(
            id: meetingId,
            endedAt: Date()
        )

        // Update meeting in local array
        if let index = meetings.firstIndex(where: { $0.id == meetingId }) {
            meetings[index] = updatedMeeting
        }
    }

    @MainActor
    func processDocument(
        meetingId: UUID,
        documentUrl: URL,
        organizationId: UUID,
        regenerateSummary: Bool = true
    ) async {
        processingState = .uploadingDocument

        do {
            // Step 1: Parse document
            processingState = .parsingDocument
            let documentService = DocumentService()
            let documentText = try await documentService.parseDocument(url: documentUrl)

            // Step 2: Upload to meeting
            let urlString = documentUrl.lastPathComponent
            _ = try await meetingService.uploadDocument(
                meetingId: meetingId,
                documentText: documentText,
                documentUrl: urlString
            )

            // Get current meeting to check if summary exists
            guard let currentMeeting = meetings.first(where: { $0.id == meetingId }) else {
                throw NSError(domain: "MeetingState", code: -1, userInfo: [NSLocalizedDescriptionKey: "Meeting not found"])
            }

            // Step 3: Generate summary (only if needed)
            var updatedMeeting: Meeting?
            if regenerateSummary || currentMeeting.summary == nil {
                processingState = .generatingSummary
                let summary = try await aiService.generateSummary(from: documentText)

                // Step 4: Save summary
                updatedMeeting = try await meetingService.updateSummary(
                    meetingId: meetingId,
                    summary: summary
                )
            }

            // Step 5: Extract tasks
            processingState = .extractingTasks

            // Fetch organization members for name matching
            let members = try await organizationService.fetchMembers(organizationId: organizationId)

            let extractedTasks = try await aiService.extractTasks(
                from: documentText,
                organizationMembers: members
            )

            // Convert extracted data to MeetingTask models
            let tasks = extractedTasks.map { extracted -> MeetingTask in
                let assigneeId = extracted.assigneeName.flatMap {
                    NameMatcher.matchAssignee(name: $0, candidates: members)
                }

                let dueDate = extracted.dueDate.flatMap {
                    NameMatcher.parseDate(from: $0)
                }

                return MeetingTask(
                    meetingId: meetingId,
                    organizationId: organizationId,
                    title: extracted.title,
                    assigneeId: assigneeId,
                    dueDate: dueDate,
                    isCompleted: false,
                    createdAt: Date(),
                    extractedFrom: extracted.context
                )
            }

            // Save tasks to database
            if !tasks.isEmpty {
                _ = try await taskService.createTasks(tasks)
            }

            // Step 6: Update local state
            if let updatedMeeting = updatedMeeting,
               let index = meetings.firstIndex(where: { $0.id == meetingId }) {
                meetings[index] = updatedMeeting
            }

            processingState = .completed

            // Auto-clear completed state after 2 seconds
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            processingState = .idle

        } catch {
            processingState = .failed(error.localizedDescription)

            // Auto-clear error after 5 seconds
            try? await Task.sleep(nanoseconds: 5_000_000_000)
            processingState = .idle
        }
    }
}
