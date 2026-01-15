//
//  MeetingManagerApp.swift
//  MeetingManager
//
//  Created on 2026-01-14.
//

import SwiftUI

@main
struct MeetingManagerApp: App {
    @StateObject private var coordinator = AppCoordinator()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(coordinator)
        }
    }
}
