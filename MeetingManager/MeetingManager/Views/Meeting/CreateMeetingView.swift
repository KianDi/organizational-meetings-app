import SwiftUI

struct CreateMeetingView: View {
    let organization: Organization

    @Environment(AuthState.self) private var authState
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var scheduledAt: Date
    @State private var errorMessage: String?
    @State private var isSubmitting = false

    init(organization: Organization) {
        self.organization = organization
        // Default scheduled time: 1 hour from now
        _scheduledAt = State(initialValue: Date().addingTimeInterval(3600))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Meeting Title", text: $title)
                        .textInputAutocapitalization(.words)
                        .disabled(isSubmitting)
                } header: {
                    Text("Details")
                } footer: {
                    Text("Enter a descriptive title for the meeting")
                        .font(.caption)
                }

                Section {
                    DatePicker(
                        "Scheduled Time",
                        selection: $scheduledAt,
                        in: Date()...,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    .disabled(isSubmitting)
                } header: {
                    Text("Schedule")
                } footer: {
                    Text("Choose when this meeting will take place")
                        .font(.caption)
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                            .font(.caption)
                    }
                }

                Section {
                    Button {
                        Task {
                            await submitMeeting()
                        }
                    } label: {
                        HStack {
                            Spacer()
                            if isSubmitting {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                            } else {
                                Text("Create Meeting")
                            }
                            Spacer()
                        }
                    }
                    .disabled(isSubmitting || !isFormValid)
                }
            }
            .navigationTitle("New Meeting")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(isSubmitting)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        Task {
                            await submitMeeting()
                        }
                    }
                    .disabled(isSubmitting || !isFormValid)
                }
            }
        }
    }

    private var isFormValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func submitMeeting() async {
        errorMessage = nil
        isSubmitting = true
        defer { isSubmitting = false }

        guard let currentUser = authState.currentUser else {
            errorMessage = "You must be logged in to create a meeting"
            return
        }

        do {
            let service = MeetingService()
            _ = try await service.createMeeting(
                organizationId: organization.id,
                title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                scheduledAt: scheduledAt,
                createdById: currentUser.id
            )
            // Dismiss on success
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
