import SwiftUI

struct CreateOrganizationView: View {
    @Environment(\.authState) private var authState
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
            let service = OrganizationService()
            let organization = try await service.createOrganization(
                name: organizationName.trimmingCharacters(in: .whitespacesAndNewlines),
                adminId: currentUser.id
            )
            createdOrganization = organization
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
