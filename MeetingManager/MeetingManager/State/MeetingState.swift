import SwiftUI
import Observation
import Foundation

@Observable
final class MeetingState {
    private(set) var meetings: [Meeting] = []
    private(set) var isLoading: Bool = false
    private(set) var processingState: ProcessingState = .idle
    private(set) var organizationTasks: [MeetingTask] = []
    private(set) var isLoadingTasks: Bool = false
    private(set) var error: Error?
    private(set) var isLoadingMeetings: Bool = false

    // Multi-organization aggregated data
    private(set) var allMeetings: [Meeting] = []
    private(set) var allUserTasks: [MeetingTask] = []

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
        isLoadingMeetings = true
        isLoading = true
        error = nil
        defer {
            isLoadingMeetings = false
            isLoading = false
        }

        do {
            let fetchedMeetings = try await meetingService.fetchMeetingsForOrganization(organizationId: organizationId)
            meetings = fetchedMeetings
        } catch {
            self.error = error
            throw error
        }
    }

    @MainActor
    func loadMeetingWithTasks(meetingId: UUID) async throws -> Meeting {
        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
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
        } catch {
            self.error = error
            throw error
        }
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
    func updateTaskCompletion(meetingId: UUID, taskId: UUID, isCompleted: Bool) async throws {
        // Update in database
        let updatedTask = try await taskService.updateTaskCompletion(
            taskId: taskId,
            isCompleted: isCompleted
        )

        // Update local state
        if let meetingIndex = meetings.firstIndex(where: { $0.id == meetingId }),
           var tasks = meetings[meetingIndex].tasks,
           let taskIndex = tasks.firstIndex(where: { $0.id == taskId }) {
            tasks[taskIndex] = updatedTask
            meetings[meetingIndex].tasks = tasks
        }
    }

    @MainActor
    func processDocument(
        meetingId: UUID,
        documentUrl: URL,
        organizationId: UUID,
        regenerateSummary: Bool = true
    ) async {
        print("\n========================================")
        print("🚀 [MeetingState] Starting document processing")
        print("   Meeting ID: \(meetingId)")
        print("   Document: \(documentUrl.lastPathComponent)")
        print("========================================\n")

        processingState = .uploadingDocument

        do {
            // Step 1: Parse document
            print("📄 [MeetingState] Step 1: Parsing document...")
            processingState = .parsingDocument
            let documentService = DocumentService()
            let documentText = try await documentService.parseDocument(url: documentUrl)
            print("✅ [MeetingState] Document parsed: \(documentText.count) characters")

            // Step 2: Upload to meeting
            print("\n💾 [MeetingState] Step 2: Uploading to database...")
            let urlString = documentUrl.lastPathComponent
            _ = try await meetingService.uploadDocument(
                meetingId: meetingId,
                documentText: documentText,
                documentUrl: urlString
            )
            print("✅ [MeetingState] Document uploaded to database")

            // Get current meeting to check if summary exists
            guard let currentMeeting = meetings.first(where: { $0.id == meetingId }) else {
                print("❌ [MeetingState] Meeting not found in local state")
                throw NSError(domain: "MeetingState", code: -1, userInfo: [NSLocalizedDescriptionKey: "Meeting not found"])
            }

            // Step 3: Generate summary (only if needed)
            var updatedMeeting: Meeting?
            if regenerateSummary || currentMeeting.summary == nil {
                print("\n🤖 [MeetingState] Step 3: Generating AI summary...")
                processingState = .generatingSummary
                let summary = try await aiService.generateSummary(from: documentText)
                print("✅ [MeetingState] Summary received from AI")

                // Step 4: Save summary
                print("💾 [MeetingState] Step 4: Saving summary to database...")
                updatedMeeting = try await meetingService.updateSummary(
                    meetingId: meetingId,
                    summary: summary
                )
                print("✅ [MeetingState] Summary saved")
            } else {
                print("⏭️  [MeetingState] Step 3-4: Skipping summary (already exists)")
            }

            // Step 5: Extract tasks
            print("\n🎯 [MeetingState] Step 5: Extracting tasks...")
            processingState = .extractingTasks

            // Fetch organization members for name matching
            print("👥 [MeetingState] Fetching organization members...")
            let members = try await organizationService.fetchMembers(organizationId: organizationId)
            print("✅ [MeetingState] Loaded \(members.count) members for name matching")

            print("🤖 [MeetingState] Calling AI to extract tasks...")
            let extractedTasks = try await aiService.extractTasks(
                from: documentText,
                organizationMembers: members
            )
            print("✅ [MeetingState] AI extracted \(extractedTasks.count) tasks")

            // Convert extracted data to MeetingTask models
            print("🔄 [MeetingState] Converting extracted tasks to MeetingTask models...")
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
            print("✅ [MeetingState] Converted \(tasks.count) tasks")

            // Save tasks to database
            var createdTasks: [MeetingTask] = []
            if !tasks.isEmpty {
                print("💾 [MeetingState] Saving \(tasks.count) tasks to database...")
                createdTasks = try await taskService.createTasks(tasks)
                print("✅ [MeetingState] Tasks saved to database")
            } else {
                print("ℹ️  [MeetingState] No tasks to save")
            }

            // Step 6: Update local state
            print("\n🔄 [MeetingState] Step 6: Updating local state...")
            if let index = meetings.firstIndex(where: { $0.id == meetingId }) {
                var meetingToUpdate = meetings[index]

                // Update summary if it was generated in Step 3-4
                if let newSummary = updatedMeeting?.summary {
                    meetingToUpdate.summary = newSummary
                }

                // Attach tasks to meeting
                meetingToUpdate.tasks = createdTasks

                meetings[index] = meetingToUpdate
                print("✅ [MeetingState] Local meeting state updated with \(createdTasks.count) tasks")
            } else {
                print("ℹ️  [MeetingState] No meeting state update needed")
            }

            processingState = .completed
            print("\n✅ [MeetingState] ========================================")
            print("✅ [MeetingState] PROCESSING COMPLETE!")
            print("✅ [MeetingState] ========================================\n")

            // Auto-clear completed state after 2 seconds
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            processingState = .idle

        } catch {
            print("\n❌ [MeetingState] ========================================")
            print("❌ [MeetingState] ERROR OCCURRED!")
            print("❌ [MeetingState] Error: \(error)")
            print("❌ [MeetingState] Localized: \(error.localizedDescription)")
            if let nsError = error as NSError? {
                print("❌ [MeetingState] Domain: \(nsError.domain)")
                print("❌ [MeetingState] Code: \(nsError.code)")
                print("❌ [MeetingState] UserInfo: \(nsError.userInfo)")
            }
            print("❌ [MeetingState] ========================================\n")

            processingState = .failed(error.localizedDescription)

            // Auto-clear error after 5 seconds
            try? await Task.sleep(nanoseconds: 5_000_000_000)
            processingState = .idle
        }
    }

    @MainActor
    func loadOrganizationTasks(organizationId: UUID) async throws {
        isLoadingTasks = true
        error = nil
        defer { isLoadingTasks = false }

        do {
            let fetchedTasks = try await taskService.fetchTasksForOrganization(organizationId: organizationId)
            organizationTasks = fetchedTasks
        } catch {
            self.error = error
            throw error
        }
    }

    @MainActor
    func toggleTaskCompletion(taskId: UUID) async throws {
        // Find task in organizationTasks or allUserTasks
        let currentTask: MeetingTask?
        if let taskIndex = organizationTasks.firstIndex(where: { $0.id == taskId }) {
            currentTask = organizationTasks[taskIndex]
        } else if let taskIndex = allUserTasks.firstIndex(where: { $0.id == taskId }) {
            currentTask = allUserTasks[taskIndex]
        } else {
            return
        }

        guard let task = currentTask else { return }

        // Update in database
        let updatedTask = try await taskService.updateTaskCompletion(
            taskId: taskId,
            isCompleted: !task.isCompleted
        )

        // Update local organizationTasks array
        if let taskIndex = organizationTasks.firstIndex(where: { $0.id == taskId }) {
            organizationTasks[taskIndex] = updatedTask
        }

        // Update local allUserTasks array
        if let taskIndex = allUserTasks.firstIndex(where: { $0.id == taskId }) {
            allUserTasks[taskIndex] = updatedTask
        }

        // Also update in meeting's tasks array if present
        if let meetingIndex = meetings.firstIndex(where: { $0.id == updatedTask.meetingId }),
           var meetingTasks = meetings[meetingIndex].tasks,
           let meetingTaskIndex = meetingTasks.firstIndex(where: { $0.id == taskId }) {
            meetingTasks[meetingTaskIndex] = updatedTask
            meetings[meetingIndex].tasks = meetingTasks
        }
    }

    @MainActor
    func deleteTask(taskId: UUID) async throws {
        // Delete from database
        try await taskService.deleteTask(taskId: taskId)

        // Remove from organizationTasks array
        organizationTasks.removeAll { $0.id == taskId }

        // Remove from allUserTasks array
        allUserTasks.removeAll { $0.id == taskId }

        // Remove from any meeting's tasks array
        for (index, var meeting) in meetings.enumerated() {
            if var tasks = meeting.tasks {
                tasks.removeAll { $0.id == taskId }
                meeting.tasks = tasks
                meetings[index] = meeting
            }
        }
    }

    @MainActor
    func loadAllMeetings(organizationIds: [UUID]) async throws {
        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            var aggregatedMeetings: [Meeting] = []

            for organizationId in organizationIds {
                let fetchedMeetings = try await meetingService.fetchMeetingsForOrganization(organizationId: organizationId)
                aggregatedMeetings.append(contentsOf: fetchedMeetings)
            }

            allMeetings = aggregatedMeetings
        } catch {
            self.error = error
            throw error
        }
    }

    @MainActor
    func loadAllUserTasks(organizationIds: [UUID]) async throws {
        isLoadingTasks = true
        error = nil
        defer { isLoadingTasks = false }

        do {
            var aggregatedTasks: [MeetingTask] = []

            for organizationId in organizationIds {
                let fetchedTasks = try await taskService.fetchTasksForOrganization(organizationId: organizationId)
                aggregatedTasks.append(contentsOf: fetchedTasks)
            }

            allUserTasks = aggregatedTasks
        } catch {
            self.error = error
            throw error
        }
    }
}
