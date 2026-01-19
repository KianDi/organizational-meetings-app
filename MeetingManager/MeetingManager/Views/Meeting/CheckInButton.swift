import SwiftUI
import UIKit

struct CheckInButton: View {
    // MARK: - Properties

    let meeting: Meeting
    let userId: UUID

    @State private var isCheckedIn: Bool
    @State private var isSubmitting = false
    @State private var errorMessage: String?

    // MARK: - Initialization

    init(meeting: Meeting, userId: UUID) {
        self.meeting = meeting
        self.userId = userId
        self._isCheckedIn = State(initialValue: meeting.attendeeIds.contains(userId))
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                Task {
                    await checkIn()
                }
            } label: {
                HStack {
                    if isSubmitting {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                    } else {
                        Text(isCheckedIn ? "Checked In ✓" : "Check In")
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(isCheckedIn ? .bordered : .borderedProminent)
            .tint(isCheckedIn ? .green : .blue)
            .disabled(isCheckedIn || isSubmitting)

            if let errorMessage {
                Text(errorMessage)
                    .foregroundStyle(.red)
                    .font(.caption)
            }
        }
    }

    // MARK: - Methods

    private func checkIn() async {
        errorMessage = nil
        isSubmitting = true
        defer { isSubmitting = false }

        do {
            let service = MeetingService()
            _ = try await service.checkIn(meetingId: meeting.id, userId: userId)

            // Update local state on success
            isCheckedIn = true

            // Haptic feedback for successful check-in
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)

        } catch {
            errorMessage = error.localizedDescription

            // Auto-dismiss error after 3 seconds
            Task {
                try? await Task.sleep(nanoseconds: 3_000_000_000)
                errorMessage = nil
            }
        }
    }
}
