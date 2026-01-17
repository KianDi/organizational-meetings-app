import Supabase
import Foundation

/// Actor-based organization service for thread-safe database operations.
/// Manages organization creation, updates, and queries with Supabase backend.
actor OrganizationService {
    // MARK: - Properties

    private let supabase: SupabaseClient

    // MARK: - Database Models

    /// Database representation of Organization with snake_case column names
    private struct OrganizationDTO: Codable {
        let id: UUID
        let name: String
        let adminId: UUID
        let createdAt: Date
        let inviteCode: String?
        let memberIds: [UUID]

        enum CodingKeys: String, CodingKey {
            case id
            case name
            case adminId = "admin_id"
            case createdAt = "created_at"
            case inviteCode = "invite_code"
            case memberIds = "member_ids"
        }
    }

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

        // Map to database format
        let dto = OrganizationDTO(
            id: organization.id,
            name: organization.name,
            adminId: organization.adminId,
            createdAt: organization.createdAt,
            inviteCode: organization.inviteCode,
            memberIds: organization.memberIds
        )

        // Insert into Supabase organizations table
        try await supabase
            .from("organizations")
            .insert(dto)
            .execute()

        return organization
    }
}
