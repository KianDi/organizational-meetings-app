import SwiftUI

/// View displaying all members of an organization with role indicators.
/// Shows admin badge for organization admin and loads members from OrganizationService.
struct MemberListView: View {
    // MARK: - Properties

    /// The organization whose members to display
    let organization: Organization

    /// List of organization members
    @State private var members: [User] = []

    /// Loading state while fetching members
    @State private var isLoading: Bool = false

    /// Error message if member fetch fails
    @State private var errorMessage: String?

    /// Authentication state for current user
    @Environment(AuthState.self) private var authState

    // MARK: - Body

    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading members...")
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
                            await loadMembers()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
            } else {
                List {
                    ForEach(sortedMembers) { member in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(member.name)
                                    .font(.headline)
                                Text(member.email)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            if organization.isAdmin(userId: member.id) {
                                Text("Admin")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(
                                        Capsule()
                                            .fill(Color.secondary.opacity(0.2))
                                    )
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle("Members (\(members.count))")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadMembers()
        }
    }

    // MARK: - Computed Properties

    /// Members sorted with admin first, then alphabetically by name
    private var sortedMembers: [User] {
        members.sorted { lhs, rhs in
            let lhsIsAdmin = organization.isAdmin(userId: lhs.id)
            let rhsIsAdmin = organization.isAdmin(userId: rhs.id)

            // Admin comes first
            if lhsIsAdmin && !rhsIsAdmin {
                return true
            } else if !lhsIsAdmin && rhsIsAdmin {
                return false
            } else {
                // Otherwise sort alphabetically
                return lhs.name.lowercased() < rhs.name.lowercased()
            }
        }
    }

    // MARK: - Methods

    /// Load organization members from service
    private func loadMembers() async {
        isLoading = true
        errorMessage = nil

        defer {
            isLoading = false
        }

        do {
            let fetchedMembers = try await OrganizationService().fetchMembers(organizationId: organization.id)
            members = fetchedMembers
        } catch {
            errorMessage = "Failed to load members: \(error.localizedDescription)"
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        MemberListView(
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
