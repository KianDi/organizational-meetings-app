import SwiftUI
import Observation
import Foundation

@Observable
final class MeetingState {
    private(set) var meetings: [Meeting] = []
    private(set) var isLoading: Bool = false

    private let meetingService: MeetingService

    init(meetingService: MeetingService = MeetingService()) {
        self.meetingService = meetingService
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
}
