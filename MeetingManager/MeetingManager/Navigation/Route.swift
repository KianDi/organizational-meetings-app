//
//  Route.swift
//  MeetingManager
//
//  Created by Claude on 2026-01-14.
//

import Foundation

/// Defines all navigation routes in the app
enum Route: Hashable, Identifiable {
    case auth
    case organizationList
    case organizationDetail(id: UUID)
    case meetingList(orgId: UUID)
    case meetingDetail(id: UUID)
    case taskList(orgId: UUID)
    case calendar(orgId: UUID)
    case profile

    var id: String {
        switch self {
        case .auth:
            return "auth"
        case .organizationList:
            return "organizationList"
        case .organizationDetail(let id):
            return "organizationDetail-\(id.uuidString)"
        case .meetingList(let orgId):
            return "meetingList-\(orgId.uuidString)"
        case .meetingDetail(let id):
            return "meetingDetail-\(id.uuidString)"
        case .taskList(let orgId):
            return "taskList-\(orgId.uuidString)"
        case .calendar(let orgId):
            return "calendar-\(orgId.uuidString)"
        case .profile:
            return "profile"
        }
    }
}
