import XCTest
@testable import MeetingManager

final class KeychainManagerTests: XCTestCase {
    let keychain = KeychainManager.shared

    override func tearDown() async throws {
        try await keychain.deleteAll()
    }

    func testSaveAndRetrieveTokens() async throws {
        let accessToken = "test_access_token"
        let refreshToken = "test_refresh_token"

        try await keychain.save(accessToken: accessToken, refreshToken: refreshToken)

        let retrievedAccess = try await keychain.retrieve(forKey: "accessToken")
        let retrievedRefresh = try await keychain.retrieve(forKey: "refreshToken")

        XCTAssertEqual(retrievedAccess, accessToken)
        XCTAssertEqual(retrievedRefresh, refreshToken)
    }

    func testDeleteAll() async throws {
        try await keychain.save(accessToken: "test1", refreshToken: "test2")
        try await keychain.deleteAll()

        let retrieved = try await keychain.retrieve(forKey: "accessToken")
        XCTAssertNil(retrieved)
    }

    func testOverwriteExisting() async throws {
        // Save initial tokens
        try await keychain.save(accessToken: "first_access", refreshToken: "first_refresh")

        // Overwrite with new tokens
        try await keychain.save(accessToken: "second_access", refreshToken: "second_refresh")

        let retrievedAccess = try await keychain.retrieve(forKey: "accessToken")
        let retrievedRefresh = try await keychain.retrieve(forKey: "refreshToken")

        XCTAssertEqual(retrievedAccess, "second_access")
        XCTAssertEqual(retrievedRefresh, "second_refresh")
    }
}
