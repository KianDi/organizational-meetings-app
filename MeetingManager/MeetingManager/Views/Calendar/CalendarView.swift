import SwiftUI

/// View displaying meetings and task deadlines in monthly calendar grid format.
/// Shows indicator dots for meetings (blue) and tasks (green) on each day.
struct CalendarView: View {
    // MARK: - Properties

    let organizationId: UUID

    @Environment(MeetingState.self) private var meetingState
    @Environment(OrganizationState.self) private var organizationState

    @State private var selectedDate: Date = Date()
    @State private var displayMonth: Date = Date()
    @State private var isLoading: Bool = false

    // MARK: - Computed Properties

    /// Array of dates for the calendar grid (42 cells for 6 weeks)
    private var daysInMonth: [Date] {
        let calendar = Calendar.current

        // Get first day of display month
        guard let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: displayMonth)) else {
            return []
        }

        // Get weekday of first day (1 = Sunday, 7 = Saturday)
        let firstWeekday = calendar.component(.weekday, from: monthStart)

        // Calculate offset (days from previous month to show)
        let offset = firstWeekday - 1

        // Generate 42 dates (6 weeks)
        var dates: [Date] = []
        for day in 0..<42 {
            if let date = calendar.date(byAdding: .day, value: day - offset, to: monthStart) {
                dates.append(date)
            }
        }

        return dates
    }

    /// Dictionary of meetings grouped by date (ignoring time)
    private var meetingsForDate: [Date: [Meeting]] {
        let calendar = Calendar.current
        var grouped: [Date: [Meeting]] = [:]

        for meeting in meetingState.meetings {
            let dateKey = calendar.startOfDay(for: meeting.scheduledAt)
            grouped[dateKey, default: []].append(meeting)
        }

        return grouped
    }

    /// Dictionary of tasks grouped by due date (ignoring time)
    private var tasksForDate: [Date: [MeetingTask]] {
        let calendar = Calendar.current
        var grouped: [Date: [MeetingTask]] = [:]

        for task in meetingState.organizationTasks {
            guard let dueDate = task.dueDate else { continue }
            let dateKey = calendar.startOfDay(for: dueDate)
            grouped[dateKey, default: []].append(task)
        }

        return grouped
    }

    /// Meetings for selected date
    private var selectedMeetings: [Meeting] {
        let calendar = Calendar.current
        let dateKey = calendar.startOfDay(for: selectedDate)
        return meetingsForDate[dateKey] ?? []
    }

    /// Tasks for selected date
    private var selectedTasks: [MeetingTask] {
        let calendar = Calendar.current
        let dateKey = calendar.startOfDay(for: selectedDate)
        return tasksForDate[dateKey] ?? []
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Month navigation header
                HStack {
                    Button {
                        changeMonth(by: -1)
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.title2)
                            .foregroundStyle(.blue)
                    }

                    Spacer()

                    Text(monthYearString)
                        .font(.title2)
                        .fontWeight(.semibold)

                    Spacer()

                    Button {
                        changeMonth(by: 1)
                    } label: {
                        Image(systemName: "chevron.right")
                            .font(.title2)
                            .foregroundStyle(.blue)
                    }
                }
                .padding(.horizontal)

                // Weekday headers
                HStack(spacing: 0) {
                    ForEach(["S", "M", "T", "W", "T", "F", "S"], id: \.self) { day in
                        Text(day)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal)

                // Calendar grid
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 8) {
                    ForEach(daysInMonth, id: \.self) { date in
                        DayCell(
                            date: date,
                            isSelected: isSameDay(date, selectedDate),
                            isToday: isSameDay(date, Date()),
                            isCurrentMonth: isInCurrentMonth(date),
                            hasMeetings: hasMeetings(on: date),
                            hasTasks: hasTasks(on: date)
                        )
                        .onTapGesture {
                            selectedDate = date
                        }
                    }
                }
                .padding(.horizontal)

                // Selected day detail
                CalendarDayView(
                    date: selectedDate,
                    meetings: selectedMeetings,
                    tasks: selectedTasks
                )
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .navigationTitle("Calendar")
        .navigationBarTitleDisplayMode(.large)
        .refreshable {
            await loadData()
        }
        .task {
            await loadData()
        }
        .overlay {
            if isLoading {
                ProgressView("Loading...")
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
            }
        }
    }

    // MARK: - Helper Methods

    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: displayMonth)
    }

    private func changeMonth(by months: Int) {
        let calendar = Calendar.current
        if let newMonth = calendar.date(byAdding: .month, value: months, to: displayMonth) {
            displayMonth = newMonth
        }
    }

    private func isSameDay(_ date1: Date, _ date2: Date) -> Bool {
        Calendar.current.isDate(date1, inSameDayAs: date2)
    }

    private func isInCurrentMonth(_ date: Date) -> Bool {
        let calendar = Calendar.current
        return calendar.isDate(date, equalTo: displayMonth, toGranularity: .month)
    }

    private func hasMeetings(on date: Date) -> Bool {
        let calendar = Calendar.current
        let dateKey = calendar.startOfDay(for: date)
        return meetingsForDate[dateKey] != nil
    }

    private func hasTasks(on date: Date) -> Bool {
        let calendar = Calendar.current
        let dateKey = calendar.startOfDay(for: date)
        return tasksForDate[dateKey] != nil
    }

    private func loadData() async {
        isLoading = true
        defer { isLoading = false }

        do {
            // Load both meetings and tasks
            try await meetingState.loadMeetings(organizationId: organizationId)
            try await meetingState.loadOrganizationTasks(organizationId: organizationId)
        } catch {
            print("Failed to load calendar data: \(error)")
        }
    }
}

// MARK: - Day Cell

struct DayCell: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let isCurrentMonth: Bool
    let hasMeetings: Bool
    let hasTasks: Bool

    private var dayNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }

    var body: some View {
        VStack(spacing: 4) {
            Text(dayNumber)
                .font(.body)
                .foregroundStyle(isCurrentMonth ? .primary : .secondary)

            // Indicator dots
            HStack(spacing: 2) {
                if hasMeetings {
                    Circle()
                        .fill(.blue)
                        .frame(width: 4, height: 4)
                }
                if hasTasks {
                    Circle()
                        .fill(.green)
                        .frame(width: 4, height: 4)
                }
            }
            .frame(height: 4)
        }
        .frame(height: 44)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ? Color.blue.opacity(0.2) : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isToday ? Color.blue : Color.clear, lineWidth: 2)
        )
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        CalendarView(organizationId: UUID())
            .environment(MeetingState())
            .environment(OrganizationState(organizationService: OrganizationService()))
    }
}
