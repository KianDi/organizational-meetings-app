import SwiftUI
import Observation
import Foundation

@Observable
final class OrganizationState {
    private(set) var organizations: [Organization] = []
    private(set) var isLoading: Bool = false
    private(set) var error: Error?

    private let organizationService: OrganizationService

    init(organizationService: OrganizationService = OrganizationService()) {
        self.organizationService = organizationService
    }

    @MainActor
    func loadUserOrganizations(userId: UUID) async throws {
        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            // Define UserDTO for database mapping
            struct UserDTO: Codable {
                let organizationIds: [UUID]

                enum CodingKeys: String, CodingKey {
                    case organizationIds = "organization_ids"
                }
            }

            // Fetch user's organization_ids from users table
            let user: UserDTO = try await SupabaseConfig.shared
                .from("users")
                .select("organization_ids")
                .eq("id", value: userId)
                .single()
                .execute()
                .value

            // Fetch full Organization objects for each org ID
            var fetchedOrganizations: [Organization] = []
            for orgId in user.organizationIds {
                do {
                    let organization = try await organizationService.fetchOrganization(id: orgId)
                    fetchedOrganizations.append(organization)
                } catch {
                    // Skip organizations that can't be fetched (may have been deleted)
                    continue
                }
            }

            organizations = fetchedOrganizations
        } catch {
            self.error = error
            throw error
        }
    }

    @MainActor
    func createOrganization(name: String, adminId: UUID) async throws -> Organization {
        error = nil

        do {
            let organization = try await organizationService.createOrganization(
                name: name,
                adminId: adminId
            )

            // Update user's organization_ids
            try await organizationService.updateUserOrganizations(
                userId: adminId,
                organizationId: organization.id
            )

            // Append to local organizations array
            organizations.append(organization)

            return organization
        } catch {
            self.error = error
            throw error
        }
    }

    @MainActor
    func joinOrganization(inviteCode: String, userId: UUID) async throws -> Organization {
        error = nil

        do {
            // Find organization by invite code
            guard let organization = try await organizationService.findByInviteCode(code: inviteCode) else {
                throw OrganizationError.invalidInviteCode
            }

            // Join the organization
            let updatedOrganization = try await organizationService.joinOrganization(
                organizationId: organization.id,
                userId: userId
            )

            // Update user's organization_ids
            try await organizationService.updateUserOrganizations(
                userId: userId,
                organizationId: organization.id
            )

            // Append to organizations array if not already present
            if !organizations.contains(where: { $0.id == updatedOrganization.id }) {
                organizations.append(updatedOrganization)
            }

            return updatedOrganization
        } catch {
            self.error = error
            throw error
        }
    }

    @MainActor
    func refresh(userId: UUID) async {
        // Reload organizations for user, ignoring errors
        try? await loadUserOrganizations(userId: userId)
    }
}

// MARK: - Error Types

enum OrganizationError: LocalizedError {
    case invalidInviteCode

    var errorDescription: String? {
        switch self {
        case .invalidInviteCode:
            return "Invalid invite code. Please check and try again."
        }
    }
}
