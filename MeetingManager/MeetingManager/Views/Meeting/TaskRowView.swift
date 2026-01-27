import SwiftUI

struct TaskRowView: View {
    // MARK: - Properties

    let task: MeetingTask

    // For displaying assignee name (passed from parent)
    var assigneeName: String?

    // Callback when task completion is toggled
    var onToggle: ((MeetingTask) -> Void)?

    // MARK: - Body

    var body: some View {
        Button {
            onToggle?(task)
        } label: {
            HStack(alignment: .top, spacing: 12) {
                // Completion indicator
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(task.isCompleted ? .green : .gray)
                    .font(.title3)

            // Task content
            VStack(alignment: .leading, spacing: 4) {
                // Title
                Text(task.title)
                    .font(.body)
                    .foregroundStyle(.primary)
                    .strikethrough(task.isCompleted)

                // Metadata row
                HStack(spacing: 12) {
                    // Assignee
                    if let assigneeName {
                        Label(assigneeName, systemImage: "person.fill")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Label("Unassigned", systemImage: "person.fill.questionmark")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }

                    // Due date
                    if let dueDate = task.dueDate {
                        Label(formatDate(dueDate), systemImage: "calendar")
                            .font(.caption)
                            .foregroundStyle(isOverdue(dueDate) ? .red : .secondary)
                    }
                }
            }

            Spacer()
        }
        .padding()
        .background(Color(.tertiarySystemBackground))
        .cornerRadius(8)
    }

    // MARK: - Helpers

    private func formatDate(_ date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()

        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInTomorrow(date) {
            return "Tomorrow"
        } else if calendar.isDate(date, equalTo: now, toGranularity: .weekOfYear) {
            // This week - show day name
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE"
            return formatter.string(from: date)
        } else {
            // Future - show full date
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            return formatter.string(from: date)
        }
    }

    private func isOverdue(_ date: Date) -> Bool {
        return date < Date() && !task.isCompleted
    }
}

#Preview {
    VStack(spacing: 8) {
        TaskRowView(
            task: MeetingTask(
                meetingId: UUID(),
                organizationId: UUID(),
                title: "Prepare budget proposal",
                assigneeId: UUID(),
                dueDate: Date().addingTimeInterval(86400), // Tomorrow
                isCompleted: false
            ),
            assigneeName: "John Smith"
        )

        TaskRowView(
            task: MeetingTask(
                meetingId: UUID(),
                organizationId: UUID(),
                title: "Review design mockups",
                assigneeId: nil,
                dueDate: nil,
                isCompleted: false
            ),
            assigneeName: nil
        )

        TaskRowView(
            task: MeetingTask(
                meetingId: UUID(),
                organizationId: UUID(),
                title: "Update documentation",
                assigneeId: UUID(),
                dueDate: Date().addingTimeInterval(-86400), // Yesterday (overdue)
                isCompleted: false
            ),
            assigneeName: "Sarah Johnson"
        )
    }
    .padding()
}
