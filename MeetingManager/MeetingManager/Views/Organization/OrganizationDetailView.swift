import SwiftUI

/// View displaying detailed information about an organization.
/// Shows organization details and provides navigation to member list.
/// Admin users can share the invite code.
struct OrganizationDetailView: View {
    // MARK: - Properties

    /// The ID of the organization to display
    let organizationId: UUID

    /// The loaded organization
    @State private var organization: Organization?

    /// Loading state while fetching organization
    @State private var isLoading: Bool = false

    /// Error message if organization fetch fails
    @State private var errorMessage: String?

    /// Controls share sheet presentation
    @State private var showingShareSheet: Bool = false

    /// Authentication state for current user
    @Environment(AuthState.self) private var authState

    /// Meeting state for task data
    @Environment(MeetingState.self) private var meetingState

    /// Computed property for incomplete task count
    private var incompleteTaskCount: Int {
        meetingState.organizationTasks.filter { !$0.isCompleted }.count
    }

    // MARK: - Body

    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading organization...")
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
                            await loadOrganization()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
            } else if let org = organization {
                List {
                    Section("Details") {
                        LabeledContent("Name", value: org.name)
                        LabeledContent("Invite Code", value: org.inviteCode ?? "N/A")
                        LabeledContent("Created", value: formattedDate(org.createdAt))
                    }

                    Section("Members") {
                        NavigationLink {
                            MemberListView(organization: org)
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("View all members")
                                        .font(.body)
                                    Text("\(org.memberIds.count) member\(org.memberIds.count == 1 ? "" : "s")")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }

                    Section("Meetings") {
                        NavigationLink {
                            MeetingListView(organization: org)
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("View meetings")
                                        .font(.body)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }

                    Section("Tasks") {
                        NavigationLink {
                            TaskListView(organizationId: org.id)
                        } label: {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                                    .font(.system(size: 24))

                                VStack(alignment: .leading, spacing: 4) {
                                    Text("View tasks")
                                        .font(.body)

                                    if incompleteTaskCount > 0 {
                                        Text("\(incompleteTaskCount) incomplete")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }

                                Spacer()

                                if incompleteTaskCount > 0 {
                                    Text("\(incompleteTaskCount)")
                                        .font(.caption)
                                        .foregroundStyle(.white)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(.green)
                                        .clipShape(Capsule())
                                }

                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle(organization?.name ?? "Organization")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            if let org = organization,
               let currentUserId = authState.currentUser?.id,
               org.isAdmin(userId: currentUserId),
               let inviteCode = org.inviteCode {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingShareSheet = true
                    } label: {
                        Label("Share Invite Code", systemImage: "square.and.arrow.up")
                    }
                }
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            if let org = organization, let inviteCode = org.inviteCode {
                ShareSheet(items: [
                    "Join \(org.name) with invite code: \(inviteCode)"
                ])
            }
        }
        .task {
            await loadOrganization()
            await loadOrganizationTasks()
        }
    }

    // MARK: - Methods

    /// Load organization from service
    private func loadOrganization() async {
        isLoading = true
        errorMessage = nil

        defer {
            isLoading = false
        }

        do {
            let fetchedOrg = try await OrganizationService().fetchOrganization(id: organizationId)
            organization = fetchedOrg
        } catch {
            errorMessage = "Failed to load organization: \(error.localizedDescription)"
        }
    }

    /// Format date for display
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    /// Load organization tasks for badge count
    private func loadOrganizationTasks() async {
        do {
            try await meetingState.loadOrganizationTasks(organizationId: organizationId)
        } catch {
            // Silently fail - task count is optional UI enhancement
            print("Failed to load organization tasks: \(error)")
        }
    }
}

// MARK: - Share Sheet

/// UIKit share sheet wrapper for SwiftUI
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // No updates needed
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        OrganizationDetailView(organizationId: UUID())
            .environment(AuthState(authService: AuthService()))
    }
}
