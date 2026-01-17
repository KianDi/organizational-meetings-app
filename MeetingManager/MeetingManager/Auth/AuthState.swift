import SwiftUI
import Observation
import Foundation

@Observable
final class AuthState {
    private(set) var currentUser: User?
    private(set) var isAuthenticated: Bool = false
    private(set) var isLoading: Bool = false

    private let authService: AuthService
    private let keychainManager: KeychainManager

    init(authService: AuthService, keychainManager: KeychainManager = .shared) {
        self.authService = authService
        self.keychainManager = keychainManager
    }

    @MainActor
    func signIn(email: String, password: String) async throws {
        isLoading = true
        defer { isLoading = false }

        let session = try await authService.signIn(email: email, password: password)

        // Store tokens in Keychain
        try await keychainManager.save(
            accessToken: session.accessToken,
            refreshToken: session.refreshToken
        )

        // Map Supabase user to our User model
        currentUser = User(
            id: UUID(uuidString: session.user.id.uuidString) ?? UUID(),
            email: session.user.email ?? "",
            name: session.user.email?.components(separatedBy: "@").first ?? "",
            createdAt: Date(),
            organizationIds: []
        )
        isAuthenticated = true
    }

    @MainActor
    func signUp(email: String, password: String) async throws {
        isLoading = true
        defer { isLoading = false }

        let user = try await authService.signUp(email: email, password: password)

        // Get session for token storage
        if let session = await authService.session() {
            try await keychainManager.save(
                accessToken: session.accessToken,
                refreshToken: session.refreshToken
            )
        }

        currentUser = user
        isAuthenticated = true
    }

    @MainActor
    func signOut() async {
        isLoading = true
        defer { isLoading = false }

        try? await authService.signOut()
        try? await keychainManager.deleteAll()

        currentUser = nil
        isAuthenticated = false
    }

    @MainActor
    func restoreSession() async {
        isLoading = true
        defer { isLoading = false }

        // Attempt to restore from Keychain
        guard let accessToken = try? await keychainManager.retrieve(forKey: "accessToken"),
              let refreshToken = try? await keychainManager.retrieve(forKey: "refreshToken") else {
            return
        }

        // Restore session in Supabase with stored tokens
        do {
            let session = try await authService.restoreSession(
                accessToken: accessToken,
                refreshToken: refreshToken
            )

            currentUser = User(
                id: UUID(uuidString: session.user.id.uuidString) ?? UUID(),
                email: session.user.email ?? "",
                name: session.user.email?.components(separatedBy: "@").first ?? "",
                createdAt: Date(),
                organizationIds: []
            )
            isAuthenticated = true
        } catch {
            // Tokens invalid or expired - clear them
            try? await keychainManager.deleteAll()
        }
    }
}
