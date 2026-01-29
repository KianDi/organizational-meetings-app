import SwiftUI

/// Main tab bar view with four tabs: Organizations, Calendar, Tasks, and Profile
struct MainTabView: View {
    // MARK: - Properties

    @Environment(AuthState.self) private var authState
    @Environment(OrganizationState.self) private var organizationState
    @Environment(MeetingState.self) private var meetingState

    @State private var selectedTab: Tab = .organizations

    // MARK: - Tab Enum

    enum Tab {
        case organizations
        case calendar
        case tasks
        case profile
    }

    // MARK: - Computed Properties

    /// Count of incomplete tasks for badge
    private var incompleteTaskCount: Int {
        meetingState.organizationTasks.filter { !$0.isCompleted }.count
    }

    // MARK: - Body

    var body: some View {
        TabView(selection: $selectedTab) {
            // Tab 1: Organizations
            NavigationStack {
                OrganizationListView()
                    .environment(authState)
                    .environment(organizationState)
                    .environment(meetingState)
            }
            .tabItem {
                Label("Organizations", systemImage: "person.3.fill")
            }
            .tag(Tab.organizations)

            // Tab 2: Calendar
            NavigationStack {
                CalendarAggregateView()
                    .environment(authState)
                    .environment(organizationState)
                    .environment(meetingState)
            }
            .tabItem {
                Label("Calendar", systemImage: "calendar")
            }
            .tag(Tab.calendar)

            // Tab 3: Tasks
            NavigationStack {
                TaskAggregateView()
                    .environment(authState)
                    .environment(organizationState)
                    .environment(meetingState)
            }
            .tabItem {
                Label("Tasks", systemImage: "checkmark.circle.fill")
            }
            .badge(incompleteTaskCount > 0 ? incompleteTaskCount : 0)
            .tag(Tab.tasks)

            // Tab 4: Profile
            NavigationStack {
                ProfileView()
                    .environment(authState)
                    .environment(organizationState)
                    .environment(meetingState)
            }
            .tabItem {
                Label("Profile", systemImage: "person.fill")
            }
            .tag(Tab.profile)
        }
    }
}

// MARK: - Calendar Aggregate View

/// View showing calendar events from all organizations
struct CalendarAggregateView: View {
    @Environment(AuthState.self) private var authState
    @Environment(OrganizationState.self) private var organizationState
    @Environment(MeetingState.self) private var meetingState

    @State private var selectedDate: Date = Date()
    @State private var displayMonth: Date = Date()
    @State private var isLoading: Bool = false
    @State private var errorMessage: String? = nil
    @State private var showError: Bool = false

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
                            .frame(width: 44, height: 44)
                    }

                    Spacer()

                    Text(monthYearString)
                        .font(.title2)
                        .fontWeight(.bold)

                    Spacer()

                    Button {
                        changeMonth(by: 1)
                    } label: {
                        Image(systemName: "chevron.right")
                            .font(.title2)
                            .foregroundStyle(.blue)
                            .frame(width: 44, height: 44)
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
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 2), count: 7), spacing: 8) {
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
                .animation(.easeInOut(duration: 0.2), value: selectedDate)

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
            await loadAllData()
        }
        .task {
            await loadAllData()
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            if let error = errorMessage {
                Text(error)
            }
        }
        .overlay {
            if isLoading {
                ProgressView("Loading calendar...")
                    .padding()
                    .background(Color(.systemBackground).opacity(0.9))
                    .cornerRadius(12)
                    .shadow(radius: 4)
            }
        }
    }

    // MARK: - Computed Properties

    private var daysInMonth: [Date] {
        let calendar = Calendar.current
        guard let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: displayMonth)) else {
            return []
        }
        let firstWeekday = calendar.component(.weekday, from: monthStart)
        let offset = firstWeekday - 1
        var dates: [Date] = []
        for day in 0..<42 {
            if let date = calendar.date(byAdding: .day, value: day - offset, to: monthStart) {
                dates.append(date)
            }
        }
        return dates
    }

    private var meetingsForDate: [Date: [Meeting]] {
        let calendar = Calendar.current
        var grouped: [Date: [Meeting]] = [:]
        for meeting in meetingState.allMeetings {
            let dateKey = calendar.startOfDay(for: meeting.scheduledAt)
            grouped[dateKey, default: []].append(meeting)
        }
        return grouped
    }

    private var tasksForDate: [Date: [MeetingTask]] {
        let calendar = Calendar.current
        var grouped: [Date: [MeetingTask]] = [:]
        for task in meetingState.allUserTasks {
            guard let dueDate = task.dueDate else { continue }
            let dateKey = calendar.startOfDay(for: dueDate)
            grouped[dateKey, default: []].append(task)
        }
        return grouped
    }

    private var selectedMeetings: [Meeting] {
        let calendar = Calendar.current
        let dateKey = calendar.startOfDay(for: selectedDate)
        return meetingsForDate[dateKey] ?? []
    }

    private var selectedTasks: [MeetingTask] {
        let calendar = Calendar.current
        let dateKey = calendar.startOfDay(for: selectedDate)
        return tasksForDate[dateKey] ?? []
    }

    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: displayMonth)
    }

    // MARK: - Helper Methods

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

    private func loadAllData() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let organizationIds = organizationState.organizations.map { $0.id }
            if !organizationIds.isEmpty {
                try await meetingState.loadAllMeetings(organizationIds: organizationIds)
                try await meetingState.loadAllUserTasks(organizationIds: organizationIds)
            }
        } catch {
            errorMessage = "Failed to load calendar data: \(error.localizedDescription)"
            showError = true
        }
    }
}

// MARK: - Task Aggregate View

/// View showing tasks from all organizations
struct TaskAggregateView: View {
    @Environment(AuthState.self) private var authState
    @Environment(OrganizationState.self) private var organizationState
    @Environment(MeetingState.self) private var meetingState

    @State private var assigneeFilter: AssigneeFilter = .all
    @State private var completionFilter: CompletionFilter = .active
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var memberNames: [UUID: String] = [:]

    enum AssigneeFilter: String, CaseIterable {
        case all = "All Tasks"
        case myTasks = "My Tasks"
        case unassigned = "Unassigned"
    }

    enum CompletionFilter: String, CaseIterable {
        case all = "All"
        case active = "Active"
        case completed = "Completed"
    }

    var body: some View {
        mainContent
            .navigationTitle("Tasks")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    filterMenu
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .task {
                await loadTasks()
                await loadMemberNames()
            }
    }

    @ViewBuilder
    private var mainContent: some View {
        if meetingState.isLoadingTasks {
            ProgressView("Loading tasks...")
        } else if groupedTasks.isEmpty {
            emptyState
        } else {
            taskList
        }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No Tasks Yet", systemImage: "checkmark.circle")
        } description: {
            Text("Tasks will appear here when extracted from meeting documents")
        }
    }

    private var taskList: some View {
        List {
            ForEach(groupedTasks, id: \.0) { section in
                Section(section.0) {
                    ForEach(section.1) { task in
                        taskRow(for: task)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .refreshable {
            await loadTasks()
        }
    }

    private func taskRow(for task: MeetingTask) -> some View {
        TaskRowView(
            task: task,
            assigneeName: task.assigneeId.flatMap { memberNames[$0] }
        ) { toggledTask in
            Task {
                await toggleTaskCompletion(toggledTask)
            }
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            if canDeleteTask(task) {
                Button(role: .destructive) {
                    Task {
                        await deleteTask(task)
                    }
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
    }

    private var filterMenu: some View {
        Menu {
            Picker("Assignee", selection: $assigneeFilter) {
                ForEach(AssigneeFilter.allCases, id: \.self) { filter in
                    Text(filter.rawValue).tag(filter)
                }
            }

            Picker("Status", selection: $completionFilter) {
                ForEach(CompletionFilter.allCases, id: \.self) { filter in
                    Text(filter.rawValue).tag(filter)
                }
            }
        } label: {
            Label("Filter", systemImage: "line.3.horizontal.decrease.circle")
        }
    }

    // MARK: - Computed Properties

    private var filteredTasks: [MeetingTask] {
        var tasks = meetingState.allUserTasks

        if let currentUserId = authState.currentUser?.id {
            switch assigneeFilter {
            case .all:
                break
            case .myTasks:
                tasks = tasks.filter { $0.assigneeId == currentUserId }
            case .unassigned:
                tasks = tasks.filter { $0.assigneeId == nil }
            }
        }

        switch completionFilter {
        case .all:
            break
        case .active:
            tasks = tasks.filter { !$0.isCompleted }
        case .completed:
            tasks = tasks.filter { $0.isCompleted }
        }

        return tasks
    }

    private var groupedTasks: [(String, [MeetingTask])] {
        let calendar = Calendar.current
        let now = Date()
        let today = calendar.startOfDay(for: now)
        let weekFromNow = calendar.date(byAdding: .day, value: 7, to: today)!

        var overdue: [MeetingTask] = []
        var todayTasks: [MeetingTask] = []
        var thisWeek: [MeetingTask] = []
        var later: [MeetingTask] = []
        var completed: [MeetingTask] = []

        for task in filteredTasks {
            if task.isCompleted {
                completed.append(task)
            } else if let dueDate = task.dueDate {
                if dueDate < today {
                    overdue.append(task)
                } else if calendar.isDate(dueDate, inSameDayAs: today) {
                    todayTasks.append(task)
                } else if dueDate <= weekFromNow {
                    thisWeek.append(task)
                } else {
                    later.append(task)
                }
            } else {
                later.append(task)
            }
        }

        var sections: [(String, [MeetingTask])] = []

        if !overdue.isEmpty {
            sections.append(("Overdue", overdue))
        }
        if !todayTasks.isEmpty {
            sections.append(("Today", todayTasks))
        }
        if !thisWeek.isEmpty {
            sections.append(("This Week", thisWeek))
        }
        if !later.isEmpty {
            sections.append(("Later", later))
        }
        if !completed.isEmpty {
            let sortedCompleted = completed.sorted { task1, task2 in
                guard let date1 = task1.dueDate else { return false }
                guard let date2 = task2.dueDate else { return true }
                return date1 > date2
            }
            sections.append(("Completed", sortedCompleted))
        }

        return sections
    }

    // MARK: - Methods

    private func loadTasks() async {
        do {
            let organizationIds = organizationState.organizations.map { $0.id }
            if !organizationIds.isEmpty {
                try await meetingState.loadAllUserTasks(organizationIds: organizationIds)
            }
        } catch {
            errorMessage = "Failed to load tasks: \(error.localizedDescription)"
            showError = true
        }
    }

    private func loadMemberNames() async {
        do {
            var names: [UUID: String] = [:]
            for organization in organizationState.organizations {
                let members = try await OrganizationService().fetchMembers(organizationId: organization.id)
                for member in members {
                    names[member.id] = member.email
                }
            }
            memberNames = names
        } catch {
            print("Failed to load member names: \(error)")
        }
    }

    private func toggleTaskCompletion(_ task: MeetingTask) async {
        do {
            try await meetingState.toggleTaskCompletion(taskId: task.id)
        } catch {
            errorMessage = "Failed to update task: \(error.localizedDescription)"
            showError = true
            await loadTasks()
        }
    }

    private func deleteTask(_ task: MeetingTask) async {
        do {
            try await meetingState.deleteTask(taskId: task.id)
        } catch {
            errorMessage = "Failed to delete task: \(error.localizedDescription)"
            showError = true
        }
    }

    private func canDeleteTask(_ task: MeetingTask) -> Bool {
        return true
    }
}

// MARK: - Preview

#Preview {
    MainTabView()
        .environment(AuthState(authService: AuthService()))
        .environment(OrganizationState())
        .environment(MeetingState())
}
