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

    init(meetingService: MeetingService = MeetingService(), aiService: AIService = AIService()) {
        self.meetingService = meetingService
        self.aiService = aiService
    }

    @MainActor
    func loadMeetings(organizationId: UUID) async throws {
        isLoading = true
        defer { isLoading = false }

        let fetchedMeetings = try await meetingService.fetchMeetingsForOrganization(organizationId: organizationId)
        meetings = fetchedMeetings
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
            if regenerateSummary || currentMeeting.summary == nil {
                processingState = .generatingSummary
                let summary = try await aiService.generateSummary(from: documentText)

            // Step 4: Save summary
            let updatedMeeting = try await meetingService.updateSummary(
                meetingId: meetingId,
                summary: summary
            )

            // Step 5: Update local state
            if let index = meetings.firstIndex(where: { $0.id == meetingId }) {
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
