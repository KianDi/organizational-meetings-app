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
    @State private var organizationState = OrganizationState()
    @State private var meetingState = MeetingState()
    @StateObject private var coordinator: AppCoordinator

    init(authService: AuthService = AuthService()) {
        _authState = State(wrappedValue: AuthState(authService: authService))
        _coordinator = StateObject(wrappedValue: AppCoordinator())
    }

    var body: some View {
        Group {
            if authState.isAuthenticated {
                // Logged in - show main tab view
                MainTabView()
                    .environment(authState)
                    .environment(organizationState)
                    .environment(meetingState)
                    .id("authenticated") // Force view recreation on auth change
            } else {
                // Logged out - show auth screens
                AuthContainerView()
                    .environment(authState)
                    .id("unauthenticated") // Force view recreation on auth change
            }
        }
        .onChange(of: authState.isAuthenticated) { oldValue, newValue in
            if !newValue {
                // User logged out - reset state
                organizationState = OrganizationState()
                meetingState = MeetingState()
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
