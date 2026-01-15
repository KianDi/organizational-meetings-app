import Supabase
import Foundation

/// Actor-based authentication service for thread-safe auth operations.
/// Prevents race conditions in token refresh and concurrent auth operations.
actor AuthService {
    // MARK: - Properties

    private let supabase: SupabaseClient
    private var currentSession: Session?

    // MARK: - Initialization

    init(supabaseClient: SupabaseClient = SupabaseConfig.shared) {
        self.supabase = supabaseClient
    }

    // MARK: - Authentication Methods

    /// Sign up a new user with email and password
    /// - Parameters:
    ///   - email: User's email address
    ///   - password: User's password
    /// - Returns: User model with populated data
    /// - Throws: Supabase auth errors
    func signUp(email: String, password: String) async throws -> User {
        let response = try await supabase.auth.signUp(
            email: email,
            password: password
        )
        currentSession = response.session

        // Map Supabase user to our User model
        return User(
            id: UUID(uuidString: response.user.id.uuidString) ?? UUID(),
            email: email,
            name: email.components(separatedBy: "@").first ?? "",
            organizationIds: [],
            createdAt: Date()
        )
    }

    /// Sign in an existing user with email and password
    /// - Parameters:
    ///   - email: User's email address
    ///   - password: User's password
    /// - Returns: Session with access and refresh tokens
    /// - Throws: Supabase auth errors
    func signIn(email: String, password: String) async throws -> Session {
        let session = try await supabase.auth.signIn(
            email: email,
            password: password
        )
        currentSession = session
        return session
    }

    /// Sign out the current user
    /// Clears the current session
    /// - Throws: Supabase auth errors
    func signOut() async throws {
        try await supabase.auth.signOut()
        currentSession = nil
    }

    /// Get the current session
    /// - Returns: Current session if user is authenticated, nil otherwise
    func session() async -> Session? {
        return currentSession
    }
}
