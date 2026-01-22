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
    @State private var isUploadingDocument: Bool = false

    /// Document picker state
    @State private var showDocumentPicker: Bool = false
    @State private var showReuploadConfirmation: Bool = false
    @State private var pendingDocumentUrl: URL?

    /// Error messages
    @State private var errorMessage: String?
    @State private var successMessage: String?

    /// Meeting state for centralized meeting management
    @Environment(MeetingState.self) private var meetingState

    // MARK: - Initialization

    init(meeting: Meeting, currentUserId: UUID) {
        self.meeting = meeting
        self.currentUserId = currentUserId
    }

    // MARK: - Computed Properties

    /// Get the current meeting state from MeetingState
    private var currentMeeting: Meeting {
        meetingState.meetings.first(where: { $0.id == meeting.id }) ?? meeting
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header section
                VStack(alignment: .leading, spacing: 8) {
                    Text(currentMeeting.title)
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    statusBadge
                }

                // Processing status section (if processing or just completed)
                if meetingState.processingState.isProcessing || meetingState.processingState == .completed {
                    processingStatusView
                }

                // Details section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Details")
                        .font(.headline)
                        .foregroundColor(.secondary)

                    VStack(spacing: 12) {
                        LabeledContent("Scheduled") {
                            Text(formattedDate(currentMeeting.scheduledAt))
                        }

                        LabeledContent("Started") {
                            if let startedAt = currentMeeting.startedAt {
                                Text(formattedDate(startedAt))
                            } else {
                                Text("Not started")
                                    .foregroundColor(.secondary)
                            }
                        }

                        LabeledContent("Ended") {
                            if let endedAt = currentMeeting.endedAt {
                                Text(formattedDate(endedAt))
                            } else if currentMeeting.startedAt != nil {
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

                // Document section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Document")
                        .font(.headline)
                        .foregroundColor(.secondary)

                    if let uploadedAt = currentMeeting.uploadedAt {
                        HStack {
                            Image(systemName: "doc.text.fill")
                                .foregroundColor(.green)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Uploaded")
                                    .font(.body)
                                    .fontWeight(.medium)
                                Text("Uploaded \(formattedDate(uploadedAt))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.green.opacity(0.1))
                        )
                    } else {
                        HStack {
                            Image(systemName: "doc.badge.plus")
                                .foregroundColor(.secondary)
                            Text("Not uploaded")
                                .font(.body)
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.gray.opacity(0.1))
                        )
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
                    } else if currentMeeting.attendeeIds.isEmpty {
                        Text("No attendees yet")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                    } else {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(currentMeeting.attendeeIds.count) checked in")
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

                // Summary section
                if let summary = currentMeeting.summary {
                    summarySection(summary)

                    Divider()
                }

                // Check-in button section
                if currentMeeting.isActive && !currentMeeting.attendeeIds.contains(currentUserId) {
                    CheckInButton(meeting: currentMeeting, userId: currentUserId)
                }

                // Admin actions section
                if isAdmin(userId: currentUserId) {
                    Divider()

                    VStack(alignment: .leading, spacing: 16) {
                        Text("Admin Actions")
                            .font(.headline)
                            .foregroundColor(.secondary)

                        VStack(spacing: 12) {
                            // Start meeting button
                            if currentMeeting.startedAt == nil {
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
                            if currentMeeting.startedAt != nil && currentMeeting.endedAt == nil {
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

                            // Upload/Re-upload document button
                            Button {
                                showDocumentPicker = true
                            } label: {
                                HStack {
                                    if isUploadingDocument {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle())
                                    } else {
                                        Image(systemName: currentMeeting.documentText == nil ? "doc.badge.plus" : "arrow.clockwise.circle")
                                        Text(currentMeeting.documentText == nil ? "Upload Document" : "Re-upload Document")
                                    }
                                }
                                .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                            .disabled(isUploadingDocument)
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

                // Success message
                if let successMessage {
                    Text(successMessage)
                        .foregroundStyle(.green)
                        .font(.caption)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.green.opacity(0.1))
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
        .sheet(isPresented: $showDocumentPicker) {
            DocumentPickerView { url in
                // If document already exists, show confirmation dialog
                if currentMeeting.documentText != nil {
                    pendingDocumentUrl = url
                    showReuploadConfirmation = true
                } else {
                    // First upload - process immediately
                    Task {
                        await meetingState.processDocument(
                            meetingId: currentMeeting.id,
                            documentUrl: url
                        )
                    }
                }
            }
        }
        .alert("Re-upload Document?", isPresented: $showReuploadConfirmation) {
            Button("Cancel", role: .cancel) {
                pendingDocumentUrl = nil
            }
            Button("Re-upload") {
                if let url = pendingDocumentUrl {
                    Task {
                        await meetingState.processDocument(
                            meetingId: currentMeeting.id,
                            documentUrl: url,
                            regenerateSummary: true
                        )
                        pendingDocumentUrl = nil
                    }
                }
            }
        } message: {
            Text("Re-uploading will regenerate the AI summary. Continue?")
        }
    }

    /// Summary section view
    @ViewBuilder
    private func summarySection(_ summary: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("AI Summary")
                .font(.headline)

            Text(summary)
                .font(.body)
                .foregroundStyle(.primary)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(8)
        }
    }

    /// Processing status view
    @ViewBuilder
    private var processingStatusView: some View {
        HStack(spacing: 12) {
            if meetingState.processingState.isProcessing {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
            } else if meetingState.processingState == .completed {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            }

            Text(meetingState.processingState.displayText)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(8)
    }

    /// Status badge view
    private var statusBadge: some View {
        Group {
            if currentMeeting.isActive {
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
            } else if currentMeeting.isUpcoming {
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
        if currentMeeting.attendeeIds.isEmpty {
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
                .in("id", values: currentMeeting.attendeeIds)
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
            try await meetingState.loadMeetings(organizationId: currentMeeting.organizationId)
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
            try await meetingState.startMeeting(meetingId: currentMeeting.id)
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
            try await meetingState.endMeeting(meetingId: currentMeeting.id)
        } catch {
            errorMessage = "Failed to end meeting: \(error.localizedDescription)"
        }
    }

    /// Handle document selection from picker
    private func handleDocumentPicked(url: URL) async {
        errorMessage = nil
        successMessage = nil
        isUploadingDocument = true
        defer { isUploadingDocument = false }

        do {
            // Parse document using DocumentService
            let documentService = DocumentService()
            let extractedText = try await documentService.parseDocument(url: url)

            // Upload to meeting via DocumentService
            _ = try await documentService.uploadDocumentToMeeting(
                meetingId: currentMeeting.id,
                documentText: extractedText,
                documentUrl: url.lastPathComponent
            )

            // Refresh meeting state
            try await meetingState.loadMeetings(organizationId: currentMeeting.organizationId)

            successMessage = "Document uploaded successfully"

            // Clear success message after 3 seconds
            Task {
                try? await Task.sleep(nanoseconds: 3_000_000_000)
                successMessage = nil
            }

        } catch let error as DocumentError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = "Failed to upload document: \(error.localizedDescription)"
        }
    }

    /// Check if user is admin (simplified - would need to fetch organization)
    /// For now, we'll check if user is the meeting creator
    private func isAdmin(userId: UUID) -> Bool {
        // TODO: Fetch organization and check adminId properly
        // For now, treat meeting creator as admin
        return currentMeeting.createdById == userId
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
