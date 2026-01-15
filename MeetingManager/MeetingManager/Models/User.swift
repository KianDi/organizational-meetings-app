import Foundation

/// Represents a user in the meeting management system.
/// Users can belong to multiple organizations and participate in meetings.
struct User: Identifiable, Codable, Equatable {
    // MARK: - Properties

    /// Unique identifier for the user
    let id: UUID

    /// User's email address for authentication
    let email: String

    /// User's display name
    let name: String

    /// Timestamp when the user account was created
    let createdAt: Date

    /// List of organization IDs this user belongs to
    var organizationIds: [UUID]

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        email: String,
        name: String,
        createdAt: Date = Date(),
        organizationIds: [UUID] = []
    ) {
        self.id = id
        self.email = email
        self.name = name
        self.createdAt = createdAt
        self.organizationIds = organizationIds
    }

    // MARK: - Validation

    /// Validates if the email address is in a proper format
    var isValidEmail: Bool {
        let emailRegex = #"^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
}
