import SwiftUI

/// Comprehensive task list view showing all organization tasks with filtering and sorting
struct TaskListView: View {
    // MARK: - Properties

    /// Organization ID to load tasks for
    let organizationId: UUID

    /// Meeting state for task data
    @Environment(MeetingState.self) private var meetingState

    /// Organization state for member names
    @Environment(OrganizationState.self) private var organizationState

    /// Auth state for current user ID
    @Environment(AuthState.self) private var authState

    /// Assignee filter selection
    @State private var assigneeFilter: AssigneeFilter = .all

    /// Completion filter selection
    @State private var completionFilter: CompletionFilter = .active

    /// Error alert presentation
    @State private var showError = false
    @State private var errorMessage = ""

    /// Member name cache for task display
    @State private var memberNames: [UUID: String] = [:]

    // MARK: - Filter Enums

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

    // MARK: - Computed Properties

    /// Filtered tasks based on current filter selections
    private var filteredTasks: [MeetingTask] {
        var tasks = meetingState.organizationTasks

        // Apply assignee filter
        if let currentUserId = authState.currentUser?.id {
            switch assigneeFilter {
            case .all:
                break // No filter
            case .myTasks:
                tasks = tasks.filter { $0.assigneeId == currentUserId }
            case .unassigned:
                tasks = tasks.filter { $0.assigneeId == nil }
            }
        }

        // Apply completion filter
        switch completionFilter {
        case .all:
            break // No filter
        case .active:
            tasks = tasks.filter { !$0.isCompleted }
        case .completed:
            tasks = tasks.filter { $0.isCompleted }
        }

        return tasks
    }

    /// Tasks grouped by date sections
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
                // No due date
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
            // Sort completed by due date descending
            let sortedCompleted = completed.sorted { task1, task2 in
                guard let date1 = task1.dueDate else { return false }
                guard let date2 = task2.dueDate else { return true }
                return date1 > date2
            }
            sections.append(("Completed", sortedCompleted))
        }

        return sections
    }

    // MARK: - Body

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
            Label("No tasks yet", systemImage: "checkmark.circle")
        } description: {
            Text("Tasks will appear here when created from meeting documents")
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

    // MARK: - Methods

    /// Load tasks for the organization
    private func loadTasks() async {
        do {
            try await meetingState.loadOrganizationTasks(organizationId: organizationId)
        } catch {
            errorMessage = "Failed to load tasks: \(error.localizedDescription)"
            showError = true
        }
    }

    /// Load member names for assignee display
    private func loadMemberNames() async {
        // Fetch member details
        do {
            let members = try await OrganizationService().fetchMembers(organizationId: organizationId)

            // Build name cache
            var names: [UUID: String] = [:]
            for member in members {
                names[member.id] = member.email
            }

            memberNames = names
        } catch {
            // Silently fail - member names are optional
            print("Failed to load member names: \(error)")
        }
    }

    /// Toggle task completion status
    private func toggleTaskCompletion(_ task: MeetingTask) async {
        do {
            try await meetingState.toggleTaskCompletion(taskId: task.id)
        } catch {
            errorMessage = "Failed to update task: \(error.localizedDescription)"
            showError = true
        }
    }

    /// Delete a task
    private func deleteTask(_ task: MeetingTask) async {
        do {
            try await meetingState.deleteTask(taskId: task.id)
        } catch {
            errorMessage = "Failed to delete task: \(error.localizedDescription)"
            showError = true
        }
    }

    /// Check if current user can delete a task
    /// For now, allow anyone to delete (will be refined based on permissions)
    private func canDeleteTask(_ task: MeetingTask) -> Bool {
        return true
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        TaskListView(organizationId: UUID())
            .environment(MeetingState())
            .environment(OrganizationState())
            .environment(AuthState(authService: AuthService()))
    }
}
