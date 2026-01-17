import Supabase
import Foundation

/// Actor-based organization service for thread-safe database operations.
/// Manages organization creation, updates, and queries with Supabase backend.
actor OrganizationService {
    // MARK: - Properties

    private let supabase: SupabaseClient

    // MARK: - Initialization

    init(supabaseClient: SupabaseClient = SupabaseConfig.shared) {
        self.supabase = supabaseClient
    }

    // MARK: - Organization Methods

    /// Create a new organization with the given name and admin user
    /// - Parameters:
    ///   - name: Organization's display name
    ///   - adminId: User ID of the organization creator/admin
    /// - Returns: Newly created Organization model
    /// - Throws: Supabase database errors
    func createOrganization(name: String, adminId: UUID) async throws -> Organization {
        // Generate unique ID and invite code
        let orgId = UUID()
        let inviteCode = String(orgId.uuidString.prefix(6)).uppercased()

        // Create organization with admin auto-included in memberIds
        let organization = Organization(
            id: orgId,
            name: name,
            adminId: adminId,
            createdAt: Date(),
            inviteCode: inviteCode,
            memberIds: [adminId]
        )

        // Map to database format (snake_case columns)
        let dbOrganization: [String: Any] = [
            "id": organization.id.uuidString,
            "name": organization.name,
            "admin_id": organization.adminId.uuidString,
            "created_at": ISO8601DateFormatter().string(from: organization.createdAt),
            "invite_code": organization.inviteCode ?? "",
            "member_ids": organization.memberIds.map { $0.uuidString }
        ]

        // Insert into Supabase organizations table
        try await supabase
            .from("organizations")
            .insert(dbOrganization)
            .execute()

        return organization
    }
}
