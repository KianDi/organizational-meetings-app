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

    /// Find an organization by invite code
    /// - Parameter code: The invite code to search for
    /// - Returns: Organization if found, nil if not found
    /// - Throws: Supabase database errors
    func findByInviteCode(code: String) async throws -> Organization? {
        do {
            let dto: OrganizationDTO = try await supabase
                .from("organizations")
                .select()
                .eq("invite_code", value: code)
                .single()
                .execute()
                .value

            return Organization(
                id: dto.id,
                name: dto.name,
                adminId: dto.adminId,
                createdAt: dto.createdAt,
                inviteCode: dto.inviteCode,
                memberIds: dto.memberIds
            )
        } catch {
            // If no matching invite code, return nil
            // Other errors will be thrown
            return nil
        }
    }

    /// Join an organization by adding a user to its member list
    /// - Parameters:
    ///   - organizationId: The organization to join
    ///   - userId: The user joining the organization
    /// - Returns: Updated Organization model
    /// - Throws: Supabase database errors
    func joinOrganization(organizationId: UUID, userId: UUID) async throws -> Organization {
        // Fetch current organization
        let currentOrg: OrganizationDTO = try await supabase
            .from("organizations")
            .select()
            .eq("id", value: organizationId)
            .single()
            .execute()
            .value

        // Check if user is already a member
        if currentOrg.memberIds.contains(userId) {
            // User already a member, return current organization
            return Organization(
                id: currentOrg.id,
                name: currentOrg.name,
                adminId: currentOrg.adminId,
                createdAt: currentOrg.createdAt,
                inviteCode: currentOrg.inviteCode,
                memberIds: currentOrg.memberIds
            )
        }

        // Append user to member list
        var updatedMemberIds = currentOrg.memberIds
        updatedMemberIds.append(userId)

        // Update organization in database
        let updatedDTO: OrganizationDTO = try await supabase
            .from("organizations")
            .update(["member_ids": updatedMemberIds])
            .eq("id", value: organizationId)
            .select()
            .single()
            .execute()
            .value

        return Organization(
            id: updatedDTO.id,
            name: updatedDTO.name,
            adminId: updatedDTO.adminId,
            createdAt: updatedDTO.createdAt,
            inviteCode: updatedDTO.inviteCode,
            memberIds: updatedDTO.memberIds
        )
    }

    /// Update user's organization list
    /// - Parameters:
    ///   - userId: The user to update
    ///   - organizationId: The organization to add to user's list
    /// - Throws: Supabase database errors
    func updateUserOrganizations(userId: UUID, organizationId: UUID) async throws {
        // Define UserDTO for database mapping
        struct UserDTO: Codable {
            let organizationIds: [UUID]

            enum CodingKeys: String, CodingKey {
                case organizationIds = "organization_ids"
            }
        }

        // Fetch current user's organization list
        let currentUser: UserDTO = try await supabase
            .from("users")
            .select("organization_ids")
            .eq("id", value: userId)
            .single()
            .execute()
            .value

        // Check if organization is already in user's list
        if currentUser.organizationIds.contains(organizationId) {
            return
        }

        // Append organization to user's list
        var updatedOrgIds = currentUser.organizationIds
        updatedOrgIds.append(organizationId)

        // Update user in database
        try await supabase
            .from("users")
            .update(["organization_ids": updatedOrgIds])
            .eq("id", value: userId)
            .execute()
    }
}
