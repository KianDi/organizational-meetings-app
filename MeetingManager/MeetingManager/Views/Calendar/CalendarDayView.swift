import SwiftUI

/// View displaying meetings and tasks for a selected calendar date.
/// Shows meetings with time and tasks due on the selected day.
struct CalendarDayView: View {
    // MARK: - Properties

    let date: Date
    let meetings: [Meeting]
    let tasks: [MeetingTask]

    @Environment(OrganizationState.self) private var organizationState
    @Environment(AuthState.self) private var authState
    @Environment(MeetingState.self) private var meetingState

    // MARK: - Computed Properties

    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter.string(from: date)
    }

    private var hasEvents: Bool {
        !meetings.isEmpty || !tasks.isEmpty
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Date header
            Text(dateString)
                .font(.headline)
                .foregroundStyle(.primary)

            Divider()

            if !hasEvents {
                // Empty state
                Text("No events for this day")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 24)
            } else {
                // Meetings section
                if !meetings.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Meetings")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)

                        ForEach(meetings) { meeting in
                            if let currentUserId = authState.currentUser?.id {
                                NavigationLink {
                                    MeetingDetailView(meeting: meeting, currentUserId: currentUserId)
                                } label: {
                                    HStack(spacing: 12) {
                                        Image(systemName: "calendar")
                                            .foregroundStyle(.blue)
                                            .font(.title3)

                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(meeting.title)
                                                .font(.body)
                                                .foregroundStyle(.primary)

                                            Text(formatTime(meeting.scheduledAt))
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }

                                        Spacer()

                                        Image(systemName: "chevron.right")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    .padding()
                                    .background(Color(.tertiarySystemBackground))
                                    .cornerRadius(8)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }

                // Tasks section
                if !tasks.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Tasks Due")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)

                        ForEach(tasks) { task in
                            if let currentUserId = authState.currentUser?.id,
                               let meeting = meetingState.meetings.first(where: { $0.id == task.meetingId }) {
                                NavigationLink {
                                    MeetingDetailView(meeting: meeting, currentUserId: currentUserId)
                                } label: {
                                    TaskRowView(
                                        task: task,
                                        assigneeName: assigneeName(for: task.assigneeId)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }

    // MARK: - Helper Methods

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }

    private func assigneeName(for userId: UUID?) -> String? {
        guard let userId = userId else { return nil }

        // Try to find member in current organization
        if let org = organizationState.organizations.first,
           org.memberIds.first(where: { $0 == userId }) != nil {
            // In a real implementation, we would fetch the user's name
            // For now, return nil and let TaskRowView show "Unassigned"
            return nil
        }

        return nil
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ScrollView {
            CalendarDayView(
                date: Date(),
                meetings: [
                    Meeting(
                        organizationId: UUID(),
                        title: "Team Standup",
                        scheduledAt: Date(),
                        createdById: UUID()
                    ),
                    Meeting(
                        organizationId: UUID(),
                        title: "Project Review",
                        scheduledAt: Date().addingTimeInterval(3600),
                        createdById: UUID()
                    )
                ],
                tasks: [
                    MeetingTask(
                        meetingId: UUID(),
                        organizationId: UUID(),
                        title: "Complete budget proposal",
                        assigneeId: UUID(),
                        dueDate: Date(),
                        isCompleted: false
                    ),
                    MeetingTask(
                        meetingId: UUID(),
                        organizationId: UUID(),
                        title: "Review design mockups",
                        assigneeId: nil,
                        dueDate: Date(),
                        isCompleted: false
                    )
                ]
            )
            .padding()
        }
        .environment(OrganizationState(organizationService: OrganizationService()))
        .environment(AuthState(authService: AuthService()))
        .environment(MeetingState())
    }
}
