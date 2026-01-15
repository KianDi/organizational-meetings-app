//
//  RootView.swift
//  MeetingManager
//
//  Created by Claude on 2026-01-14.
//

import SwiftUI

/// Root view that manages NavigationStack with AppCoordinator
struct RootView: View {
    @EnvironmentObject var coordinator: AppCoordinator

    var body: some View {
        NavigationStack(path: $coordinator.navigationPath) {
            // Placeholder root view - will be replaced with auth/org list in Phase 2
            ContentView()
                .navigationDestination(for: Route.self) { route in
                    destinationView(for: route)
                }
        }
    }

    @ViewBuilder
    private func destinationView(for route: Route) -> some View {
        switch route {
        case .auth:
            Text("Auth Screen - Phase 2")
        case .organizationList:
            Text("Organization List - Phase 2")
        case .organizationDetail(let id):
            Text("Organization Detail: \(id.uuidString)")
        case .meetingList(let orgId):
            Text("Meeting List for org: \(orgId.uuidString)")
        case .meetingDetail(let id):
            Text("Meeting Detail: \(id.uuidString)")
        case .taskList(let orgId):
            Text("Task List for org: \(orgId.uuidString)")
        case .calendar(let orgId):
            Text("Calendar for org: \(orgId.uuidString)")
        case .profile:
            Text("Profile - Phase 2")
        }
    }
}
