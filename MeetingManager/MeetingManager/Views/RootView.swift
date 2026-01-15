//
//  RootView.swift
//  MeetingManager
//
//  Created by Claude on 2026-01-14.
//

import SwiftUI

/// Root view that manages NavigationStack with AppCoordinator and auth routing
struct RootView: View {
    @State private var authState: AuthState
    @StateObject private var coordinator: AppCoordinator

    init(authService: AuthService = AuthService()) {
        _authState = State(wrappedValue: AuthState(authService: authService))
        _coordinator = StateObject(wrappedValue: AppCoordinator())
    }

    var body: some View {
        Group {
            if authState.isAuthenticated {
                // Logged in - show main app
                NavigationStack(path: $coordinator.navigationPath) {
                    ContentView()
                        .navigationDestination(for: Route.self) { route in
                            destinationView(for: route)
                        }
                }
                .environment(authState)
                .environmentObject(coordinator)
            } else {
                // Logged out - show auth screens
                AuthContainerView()
                    .environment(authState)
            }
        }
        .task {
            // Attempt to restore session on app launch
            await authState.restoreSession()
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
