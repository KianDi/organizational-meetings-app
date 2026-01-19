import SwiftUI

/// View displaying all meetings for an organization categorized by status.
/// Shows active, upcoming, and past meetings with navigation to detail view.
struct MeetingListView: View {
    // MARK: - Properties

    /// The organization whose meetings to display
    let organization: Organization

    /// Error message if meeting fetch fails
    @State private var errorMessage: String?

    /// Controls create meeting sheet presentation
    @State private var showingCreateSheet: Bool = false

    /// Authentication state for current user
    @Environment(AuthState.self) private var authState

    /// Meeting state for centralized meeting management
    @Environment(MeetingState.self) private var meetingState

    // MARK: - Body

    var body: some View {
        Group {
            if meetingState.isLoading {
                ProgressView("Loading meetings...")
            } else if let error = errorMessage {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundColor(.red)
                    Text(error)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    Button("Try Again") {
                        Task {
                            await loadMeetings()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
            } else if meetings.isEmpty {
                ContentUnavailableView(
                    "No meetings scheduled",
                    systemImage: "calendar.badge.plus",
                    description: Text("Tap + to create a meeting")
                )
            } else {
                List {
                    // Active meetings section
                    if !activeMeetings.isEmpty {
                        Section {
                            ForEach(activeMeetings) { meeting in
                                MeetingRowView(meeting: meeting, organization: organization)
                            }
                        } header: {
                            Text("Active")
                                .font(.headline)
                        }
                    }

                    // Upcoming meetings section
                    if !upcomingMeetings.isEmpty {
                        Section {
                            ForEach(upcomingMeetings) { meeting in
                                MeetingRowView(meeting: meeting, organization: organization)
                            }
                        } header: {
                            Text("Upcoming")
                                .font(.headline)
                        }
                    }

                    // Past meetings section
                    if !pastMeetings.isEmpty {
                        Section {
                            ForEach(pastMeetings) { meeting in
                                MeetingRowView(meeting: meeting, organization: organization)
                            }
                        } header: {
                            Text("Past")
                                .font(.headline)
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle("Meetings")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            if let currentUserId = authState.currentUser?.id,
               organization.isAdmin(userId: currentUserId) {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingCreateSheet = true
                    } label: {
                        Label("Create Meeting", systemImage: "plus")
                    }
                }
            }
        }
        .sheet(isPresented: $showingCreateSheet) {
            CreateMeetingView(organization: organization)
        }
        .task(id: organization.id) {
            await loadMeetings()
        }
        .refreshable {
            await loadMeetings()
        }
    }

    // MARK: - Computed Properties

    /// Meetings that are currently active (started but not ended)
    private var activeMeetings: [Meeting] {
        meetings.filter { $0.isActive }
    }

    /// Meetings that are scheduled in the future
    private var upcomingMeetings: [Meeting] {
        meetings.filter { $0.isUpcoming }
    }

    /// Meetings that have concluded
    private var pastMeetings: [Meeting] {
        meetings.filter { $0.isPast }
    }

    // MARK: - Methods

    /// Load meetings from service
    private func loadMeetings() async {
        isLoading = true
        errorMessage = nil

        defer {
            isLoading = false
        }

        do {
            let fetchedMeetings = try await MeetingService().fetchMeetingsForOrganization(organizationId: organization.id)
            meetings = fetchedMeetings
        } catch {
            errorMessage = "Failed to load meetings: \(error.localizedDescription)"
        }
    }
}

// MARK: - Meeting Row View

/// Individual row view for displaying a meeting in the list
private struct MeetingRowView: View {
    let meeting: Meeting
    let organization: Organization

    @Environment(AuthState.self) private var authState

    var body: some View {
        NavigationLink {
            if let currentUserId = authState.currentUser?.id {
                MeetingDetailView(meeting: meeting, currentUserId: currentUserId)
            }
        } label: {
            HStack {
                // Active indicator dot
                if meeting.isActive {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 8, height: 8)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(meeting.title)
                        .font(.headline)

                    Text(formattedScheduledTime(meeting.scheduledAt))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Attendance badge
                Text("\(meeting.attendeeIds.count) checked in")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color.secondary.opacity(0.2))
                    )
            }
            .padding(.vertical, 4)
        }
    }

    /// Format scheduled time with relative dates
    private func formattedScheduledTime(_ date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()

        // Check if today
        if calendar.isDateInToday(date) {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            return "Today \(formatter.string(from: date))"
        }

        // Check if tomorrow
        if calendar.isDateInTomorrow(date) {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            return "Tomorrow \(formatter.string(from: date))"
        }

        // Otherwise use full date
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d h:mm a"
        return formatter.string(from: date)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        MeetingListView(
            organization: Organization(
                id: UUID(),
                name: "Sample Organization",
                adminId: UUID(),
                createdAt: Date(),
                inviteCode: "ABC123",
                memberIds: [UUID(), UUID()]
            )
        )
        .environment(AuthState(authService: AuthService()))
    }
}
