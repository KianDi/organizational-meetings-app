import SwiftUI

struct JoinOrganizationView: View {
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
                        .disabled(isJoining)
                        .onChange(of: inviteCode) { _, newValue in
                            // Limit to 6 characters and uppercase
                            inviteCode = String(newValue.prefix(6)).uppercased()
                        }
                } header: {
                    Text("Enter Code")
                } footer: {
                    Text("Enter the 6-character invite code shared by your organization admin")
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
                                .font(.title2)
                                .fontWeight(.bold)

                            Text("You're now a member of this organization")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Section {
                    Button {
                        Task {
                            await joinWithCode()
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

    private func joinWithCode() async {
        errorMessage = nil
        isJoining = true
        defer { isJoining = false }

        guard let currentUser = authState.currentUser else {
            errorMessage = "You must be logged in to join an organization"
            return
        }

        do {
            let service = OrganizationService()

            // Find organization by invite code
            guard let organization = try await service.findByInviteCode(code: inviteCode) else {
                errorMessage = "Invalid invite code"
                return
            }

            // Join the organization
            let updatedOrganization = try await service.joinOrganization(
                organizationId: organization.id,
                userId: currentUser.id
            )

            // Update user's organization list
            try await service.updateUserOrganizations(
                userId: currentUser.id,
                organizationId: organization.id
            )

            joinedOrganization = updatedOrganization
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
