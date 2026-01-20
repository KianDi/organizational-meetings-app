import SwiftUI

struct OrganizationListView: View {
    @Environment(AuthState.self) private var authState
    @Environment(OrganizationState.self) private var organizationState

    @State private var showCreateSheet = false
    @State private var showJoinSheet = false

    var body: some View {
        NavigationStack {
            Group {
                if organizationState.isLoading && organizationState.organizations.isEmpty {
                    ProgressView()
                } else if organizationState.organizations.isEmpty {
                    ContentUnavailableView(
                        "No Organizations",
                        systemImage: "person.3",
                        description: Text("Create or join an organization to get started")
                    )
                } else {
                    List {
                        ForEach(organizationState.organizations) { organization in
                            NavigationLink(value: organization) {
                                OrganizationRow(organization: organization)
                            }
                        }
                    }
                    .refreshable {
                        guard let userId = authState.currentUser?.id else { return }
                        await organizationState.refresh(userId: userId)
                    }
                }
            }
            .navigationTitle("Organizations")
            .navigationDestination(for: Organization.self) { organization in
                OrganizationDetailView(organizationId: organization.id)
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button {
                            showCreateSheet = true
                        } label: {
                            Label("Create Organization", systemImage: "plus.circle")
                        }

                        Button {
                            showJoinSheet = true
                        } label: {
                            Label("Join Organization", systemImage: "person.badge.plus")
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                }

                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        Task {
                            await authState.signOut()
                        }
                    } label: {
                        Label("Logout", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                }
            }
            .sheet(isPresented: $showCreateSheet) {
                CreateOrganizationViewWrapper()
            }
            .sheet(isPresented: $showJoinSheet) {
                JoinOrganizationViewWrapper()
            }
            .task {
                guard let userId = authState.currentUser?.id else { return }
                do {
                    try await organizationState.loadUserOrganizations(userId: userId)
                } catch {
                    // Handle error silently - user can try refreshing
                    print("Error loading organizations: \(error)")
                }
            }
        }
    }
}

// MARK: - Organization Row

struct OrganizationRow: View {
    let organization: Organization

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(organization.name)
                    .font(.headline)

                Text("\(organization.memberIds.count) member\(organization.memberIds.count == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Wrapper Views for State Integration

struct CreateOrganizationViewWrapper: View {
    @Environment(OrganizationState.self) private var organizationState
    @Environment(AuthState.self) private var authState
    @Environment(\.dismiss) private var dismiss

    @State private var organizationName = ""
    @State private var errorMessage: String?
    @State private var isCreating = false
    @State private var createdOrganization: Organization?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Organization Name", text: $organizationName)
                        .textInputAutocapitalization(.words)
                        .disabled(isCreating)
                } header: {
                    Text("Details")
                } footer: {
                    Text("Choose a name for your organization (e.g., your club or group name)")
                        .font(.caption)
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                            .font(.caption)
                    }
                }

                if let organization = createdOrganization {
                    Section {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Organization Created!")
                                .font(.headline)
                                .foregroundStyle(.green)

                            Text("Invite Code: \(organization.inviteCode ?? "")")
                                .font(.title2)
                                .fontWeight(.bold)

                            Text("Share this code with members to join")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Section {
                    Button {
                        Task {
                            await createOrganization()
                        }
                    } label: {
                        HStack {
                            Spacer()
                            if isCreating {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                            } else {
                                Text("Create Organization")
                            }
                            Spacer()
                        }
                    }
                    .disabled(isCreating || !isFormValid)
                }
            }
            .navigationTitle("New Organization")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(isCreating)
                }

                if createdOrganization != nil {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") {
                            dismiss()
                        }
                    }
                }
            }
        }
    }

    private var isFormValid: Bool {
        !organizationName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func createOrganization() async {
        errorMessage = nil
        isCreating = true
        defer { isCreating = false }

        guard let currentUser = authState.currentUser else {
            errorMessage = "You must be logged in to create an organization"
            return
        }

        do {
            let organization = try await organizationState.createOrganization(
                name: organizationName.trimmingCharacters(in: .whitespacesAndNewlines),
                adminId: currentUser.id
            )
            createdOrganization = organization
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

struct JoinOrganizationViewWrapper: View {
    @Environment(OrganizationState.self) private var organizationState
    @Environment(AuthState.self) private var authState
    @Environment(\.dismiss) private var dismiss

    @State private var inviteCode = ""
    @State private var errorMessage: String?
    @State private var isJoining = false
    @State private var joinedOrganization: Organization?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Invite Code", text: $inviteCode)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                        .disabled(isJoining)
                        .onChange(of: inviteCode) { _, newValue in
                            // Auto-format: uppercase and limit to 6 characters
                            let filtered = newValue.uppercased().prefix(6)
                            if inviteCode != filtered {
                                inviteCode = String(filtered)
                            }
                        }
                } header: {
                    Text("Invite Code")
                } footer: {
                    Text("Enter the 6-character code provided by the organization admin")
                        .font(.caption)
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                            .font(.caption)
                    }
                }

                if let organization = joinedOrganization {
                    Section {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Successfully Joined!")
                                .font(.headline)
                                .foregroundStyle(.green)

                            Text(organization.name)
                                .font(.title3)
                                .fontWeight(.semibold)

                            Text("You can now access meetings and tasks")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Section {
                    Button {
                        Task {
                            await joinOrganization()
                        }
                    } label: {
                        HStack {
                            Spacer()
                            if isJoining {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                            } else {
                                Text("Join Organization")
                            }
                            Spacer()
                        }
                    }
                    .disabled(isJoining || !isFormValid)
                }
            }
            .navigationTitle("Join Organization")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(isJoining)
                }

                if joinedOrganization != nil {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") {
                            dismiss()
                        }
                    }
                }
            }
        }
    }

    private var isFormValid: Bool {
        inviteCode.count == 6
    }

    private func joinOrganization() async {
        errorMessage = nil
        isJoining = true
        defer { isJoining = false }

        guard let currentUser = authState.currentUser else {
            errorMessage = "You must be logged in to join an organization"
            return
        }

        do {
            let organization = try await organizationState.joinOrganization(
                inviteCode: inviteCode,
                userId: currentUser.id
            )
            joinedOrganization = organization
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
