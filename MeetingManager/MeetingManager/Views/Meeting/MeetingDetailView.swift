import SwiftUI

/// View displaying detailed information about a meeting.
/// Shows meeting details, attendance list, check-in button, and admin actions.
struct MeetingDetailView: View {
    // MARK: - Properties

    /// The meeting to display
    let meeting: Meeting

    /// Current user's ID for check-in and admin checks
    let currentUserId: UUID

    /// List of attendees (User models)
    @State private var attendees: [User] = []

    /// Loading states
    @State private var isLoadingAttendees: Bool = false
    @State private var isStarting: Bool = false
    @State private var isEnding: Bool = false

    /// Error messages
    @State private var errorMessage: String?

    /// Meeting state for centralized meeting management
    @Environment(MeetingState.self) private var meetingState

    // MARK: - Initialization

    init(meeting: Meeting, currentUserId: UUID) {
        self.meeting = meeting
        self.currentUserId = currentUserId
        self._refreshedMeeting = State(initialValue: meeting)
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header section
                VStack(alignment: .leading, spacing: 8) {
                    Text(refreshedMeeting.title)
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    statusBadge
                }

                // Details section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Details")
                        .font(.headline)
                        .foregroundColor(.secondary)

                    VStack(spacing: 12) {
                        LabeledContent("Scheduled") {
                            Text(formattedDate(refreshedMeeting.scheduledAt))
                        }

                        LabeledContent("Started") {
                            if let startedAt = refreshedMeeting.startedAt {
                                Text(formattedDate(startedAt))
                            } else {
                                Text("Not started")
                                    .foregroundColor(.secondary)
                            }
                        }

                        LabeledContent("Ended") {
                            if let endedAt = refreshedMeeting.endedAt {
                                Text(formattedDate(endedAt))
                            } else if refreshedMeeting.startedAt != nil {
                                Text("Ongoing")
                                    .foregroundColor(.secondary)
                            } else {
                                Text("Not started")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }

                Divider()

                // Attendance section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Attendance")
                        .font(.headline)
                        .foregroundColor(.secondary)

                    if isLoadingAttendees {
                        HStack {
                            Spacer()
                            ProgressView("Loading attendees...")
                            Spacer()
                        }
                    } else if refreshedMeeting.attendeeIds.isEmpty {
                        Text("No attendees yet")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                    } else {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(refreshedMeeting.attendeeIds.count) checked in")
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                            ForEach(attendees) { attendee in
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                        .font(.caption)
                                    Text(attendee.name)
                                        .font(.body)
                                    Spacer()
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                }

                Divider()

                // Check-in button section
                if refreshedMeeting.isActive && !refreshedMeeting.attendeeIds.contains(currentUserId) {
                    CheckInButton(meeting: refreshedMeeting, userId: currentUserId)
                        .onChange(of: refreshedMeeting.id) {
                            // Refresh meeting when check-in completes
                            Task {
                                await refreshMeeting()
                            }
                        }
                }

                // Admin actions section
                if let organization = refreshedMeeting.organizationId as UUID?,
                   isAdmin(userId: currentUserId) {
                    Divider()

                    VStack(alignment: .leading, spacing: 16) {
                        Text("Admin Actions")
                            .font(.headline)
                            .foregroundColor(.secondary)

                        VStack(spacing: 12) {
                            // Start meeting button
                            if refreshedMeeting.startedAt == nil {
                                Button {
                                    Task {
                                        await startMeeting()
                                    }
                                } label: {
                                    HStack {
                                        if isStarting {
                                            ProgressView()
                                                .progressViewStyle(CircularProgressViewStyle())
                                        } else {
                                            Text("Start Meeting")
                                        }
                                    }
                                    .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.borderedProminent)
                                .disabled(isStarting)
                            }

                            // End meeting button
                            if refreshedMeeting.startedAt != nil && refreshedMeeting.endedAt == nil {
                                Button {
                                    Task {
                                        await endMeeting()
                                    }
                                } label: {
                                    HStack {
                                        if isEnding {
                                            ProgressView()
                                                .progressViewStyle(CircularProgressViewStyle())
                                        } else {
                                            Text("End Meeting")
                                        }
                                    }
                                    .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.bordered)
                                .tint(.red)
                                .disabled(isEnding)
                            }
                        }
                    }
                }

                // Error message
                if let errorMessage {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                        .font(.caption)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.red.opacity(0.1))
                        )
                }
            }
            .padding()
        }
        .navigationTitle("Meeting Details")
        .navigationBarTitleDisplayMode(.inline)
        .refreshable {
            await refreshMeeting()
        }
        .task {
            await loadAttendees()
        }
    }

    // MARK: - Computed Properties

    /// Status badge view
    private var statusBadge: some View {
        Group {
            if refreshedMeeting.isActive {
                Text("Active")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color.green)
                    )
            } else if refreshedMeeting.isUpcoming {
                Text("Upcoming")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color.blue)
                    )
            } else {
                Text("Past")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color.gray)
                    )
            }
        }
    }

    // MARK: - Methods

    /// Load attendees from service
    private func loadAttendees() async {
        if refreshedMeeting.attendeeIds.isEmpty {
            attendees = []
            return
        }

        isLoadingAttendees = true
        defer {
            isLoadingAttendees = false
        }

        do {
            // Fetch users using the same pattern as OrganizationService.fetchMembers
            struct UserDTO: Codable {
                let id: UUID
                let email: String
                let name: String
                let createdAt: Date
                let organizationIds: [UUID]

                enum CodingKeys: String, CodingKey {
                    case id
                    case email
                    case name
                    case createdAt = "created_at"
                    case organizationIds = "organization_ids"
                }
            }

            let supabase = SupabaseConfig.shared
            let dtos: [UserDTO] = try await supabase
                .from("users")
                .select()
                .in("id", values: refreshedMeeting.attendeeIds)
                .execute()
                .value

            attendees = dtos.map { dto in
                User(
                    id: dto.id,
                    email: dto.email,
                    name: dto.name,
                    createdAt: dto.createdAt,
                    organizationIds: dto.organizationIds
                )
            }.sorted { $0.name.lowercased() < $1.name.lowercased() }

        } catch {
            errorMessage = "Failed to load attendees: \(error.localizedDescription)"
        }
    }

    /// Refresh meeting data from service
    private func refreshMeeting() async {
        do {
            let service = MeetingService()
            let updated = try await service.fetchMeeting(id: refreshedMeeting.id)
            refreshedMeeting = updated
            await loadAttendees()
        } catch {
            errorMessage = "Failed to refresh meeting: \(error.localizedDescription)"
        }
    }

    /// Start the meeting (admin only)
    private func startMeeting() async {
        errorMessage = nil
        isStarting = true
        defer { isStarting = false }

        do {
            let service = MeetingService()
            let updated = try await service.updateMeeting(
                id: refreshedMeeting.id,
                startedAt: Date()
            )
            refreshedMeeting = updated
        } catch {
            errorMessage = "Failed to start meeting: \(error.localizedDescription)"
        }
    }

    /// End the meeting (admin only)
    private func endMeeting() async {
        errorMessage = nil
        isEnding = true
        defer { isEnding = false }

        do {
            let service = MeetingService()
            let updated = try await service.updateMeeting(
                id: refreshedMeeting.id,
                endedAt: Date()
            )
            refreshedMeeting = updated
        } catch {
            errorMessage = "Failed to end meeting: \(error.localizedDescription)"
        }
    }

    /// Check if user is admin (simplified - would need to fetch organization)
    /// For now, we'll check if user is the meeting creator
    private func isAdmin(userId: UUID) -> Bool {
        // TODO: Fetch organization and check adminId properly
        // For now, treat meeting creator as admin
        return refreshedMeeting.createdById == userId
    }

    /// Format date for display
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        MeetingDetailView(
            meeting: Meeting(
                id: UUID(),
                organizationId: UUID(),
                title: "Sample Meeting",
                scheduledAt: Date(),
                startedAt: Date(),
                createdById: UUID()
            ),
            currentUserId: UUID()
        )
    }
}
