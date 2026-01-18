import Foundation

/// Represents an organization (student group) in the meeting management system.
/// Organizations have an admin/leader and can have multiple members.
struct Organization: Identifiable, Codable, Equatable, Hashable {
    // MARK: - Properties

    /// Unique identifier for the organization
    let id: UUID

    /// Organization's display name
    let name: String

    /// User ID of the organization creator/leader/admin
    let adminId: UUID

    /// Timestamp when the organization was created
    let createdAt: Date

    /// Optional invite code for members to join the organization
    var inviteCode: String?

    /// List of all member user IDs (including admin)
    var memberIds: [UUID]

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        name: String,
        adminId: UUID,
        createdAt: Date = Date(),
        inviteCode: String? = nil,
        memberIds: [UUID] = []
    ) {
        self.id = id
        self.name = name
        self.adminId = adminId
        self.createdAt = createdAt
        self.inviteCode = inviteCode
        // Ensure admin is always included in memberIds
        self.memberIds = memberIds.contains(adminId) ? memberIds : memberIds + [adminId]
    }

    // MARK: - Computed Properties

    /// Checks if a given user ID is the admin of this organization
    func isAdmin(userId: UUID) -> Bool {
        return userId == adminId
    }
}
