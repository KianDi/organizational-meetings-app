import Security
import Foundation

actor KeychainManager {
    static let shared = KeychainManager()

    private init() {}

    // Save tokens to Keychain
    func save(accessToken: String, refreshToken: String) async throws {
        let accessTokenData = Data(accessToken.utf8)
        let refreshTokenData = Data(refreshToken.utf8)

        try await save(data: accessTokenData, forKey: "accessToken")
        try await save(data: refreshTokenData, forKey: "refreshToken")
    }

    // Save single item to Keychain
    private func save(data: Data, forKey key: String) async throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]

        // Delete existing entry first
        SecItemDelete(query as CFDictionary)

        // Add new entry
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.unableToSave
        }
    }

    // Retrieve token from Keychain
    func retrieve(forKey key: String) async throws -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let token = String(data: data, encoding: .utf8) else {
            return nil
        }

        return token
    }

    // Delete all stored credentials
    func deleteAll() async throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword
        ]
        SecItemDelete(query as CFDictionary)
    }
}

enum KeychainError: Error {
    case unableToSave
    case unableToRetrieve
}
