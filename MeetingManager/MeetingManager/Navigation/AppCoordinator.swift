//
//  AppCoordinator.swift
//  MeetingManager
//
//  Created by Claude on 2026-01-14.
//

import Foundation
import SwiftUI

/// Coordinator pattern for centralized navigation management
@MainActor
class AppCoordinator: ObservableObject {
    @Published var navigationPath = NavigationPath()
    @Published var isAuthenticated: Bool = false

    /// Navigate to a specific route
    func navigate(to route: Route) {
        navigationPath.append(route)
    }

    /// Pop to root (clear entire navigation stack)
    func popToRoot() {
        navigationPath.removeLast(navigationPath.count)
    }

    /// Pop one level back
    func pop() {
        guard !navigationPath.isEmpty else { return }
        navigationPath.removeLast()
    }
}
