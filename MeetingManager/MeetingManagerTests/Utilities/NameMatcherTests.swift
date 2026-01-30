import XCTest
@testable import MeetingManager

final class NameMatcherTests: XCTestCase {

    // MARK: - Test Data

    let testUsers = [
        User(id: UUID(), email: "john.doe@example.com", name: "John Doe", createdAt: Date(), organizationIds: []),
        User(id: UUID(), email: "jane.doe@example.com", name: "Jane Doe", createdAt: Date(), organizationIds: []),
        User(id: UUID(), email: "john.smith@example.com", name: "John Smith", createdAt: Date(), organizationIds: []),
        User(id: UUID(), email: "jose.garcia@example.com", name: "José García", createdAt: Date(), organizationIds: []),
        User(id: UUID(), email: "mary.jane@example.com", name: "Mary-Jane Watson", createdAt: Date(), organizationIds: [])
    ]

    // MARK: - Exact Match Tests

    func testExactMatchReturnsCorrectUser() {
        let result = NameMatcher.matchAssignee(name: "John Doe", candidates: testUsers)
        XCTAssertEqual(result, testUsers[0].id, "Should match exact name 'John Doe'")
    }

    func testExactMatchCaseInsensitive() {
        let result = NameMatcher.matchAssignee(name: "john doe", candidates: testUsers)
        XCTAssertEqual(result, testUsers[0].id, "Should match 'john doe' case-insensitively")
    }

    func testExactMatchWithUpperCase() {
        let result = NameMatcher.matchAssignee(name: "JANE DOE", candidates: testUsers)
        XCTAssertEqual(result, testUsers[1].id, "Should match 'JANE DOE' case-insensitively")
    }

    // MARK: - Email Prefix Tests

    func testEmailPrefixMatch() {
        let result = NameMatcher.matchAssignee(name: "john.doe", candidates: testUsers)
        XCTAssertEqual(result, testUsers[0].id, "Should match email prefix 'john.doe'")
    }

    func testPartialEmailMatch() {
        let result = NameMatcher.matchAssignee(name: "jane", candidates: testUsers)
        XCTAssertEqual(result, testUsers[1].id, "Should match partial email prefix 'jane'")
    }

    // MARK: - Partial Name Match Tests

    func testFirstNameOnlyMatch() {
        let result = NameMatcher.matchAssignee(name: "John", candidates: testUsers)
        XCTAssertNotNil(result, "Should find a match for first name 'John'")
        // Should match either John Doe or John Smith - both valid
        XCTAssertTrue(result == testUsers[0].id || result == testUsers[2].id, "Should match one of the Johns")
    }

    func testLastNameOnlyMatch() {
        let result = NameMatcher.matchAssignee(name: "Doe", candidates: testUsers)
        XCTAssertNotNil(result, "Should find a match for last name 'Doe'")
        // Should match either John Doe or Jane Doe - both valid
        XCTAssertTrue(result == testUsers[0].id || result == testUsers[1].id, "Should match one of the Does")
    }

    func testPartialFirstNameMatch() {
        let result = NameMatcher.matchAssignee(name: "Jo", candidates: testUsers)
        XCTAssertNotNil(result, "Should find a match for partial name 'Jo'")
    }

    // MARK: - Whitespace Handling Tests

    func testMultipleSpacesInInput() {
        let result = NameMatcher.matchAssignee(name: "John  Doe", candidates: testUsers)
        XCTAssertNotNil(result, "Should handle multiple spaces in input")
    }

    func testLeadingWhitespace() {
        let result = NameMatcher.matchAssignee(name: " John Doe", candidates: testUsers)
        XCTAssertEqual(result, testUsers[0].id, "Should trim leading whitespace")
    }

    func testTrailingWhitespace() {
        let result = NameMatcher.matchAssignee(name: "John Doe ", candidates: testUsers)
        XCTAssertEqual(result, testUsers[0].id, "Should trim trailing whitespace")
    }

    func testLeadingAndTrailingWhitespace() {
        let result = NameMatcher.matchAssignee(name: "  Jane Doe  ", candidates: testUsers)
        XCTAssertEqual(result, testUsers[1].id, "Should trim both leading and trailing whitespace")
    }

    // MARK: - Unicode Tests

    func testUnicodeExactMatch() {
        let result = NameMatcher.matchAssignee(name: "José García", candidates: testUsers)
        XCTAssertEqual(result, testUsers[3].id, "Should match unicode name exactly")
    }

    func testUnicodePartialMatch() {
        let result = NameMatcher.matchAssignee(name: "jose", candidates: testUsers)
        XCTAssertEqual(result, testUsers[3].id, "Should match unicode name via email prefix")
    }

    // MARK: - Special Character Tests

    func testHyphenatedNameMatch() {
        let result = NameMatcher.matchAssignee(name: "Mary-Jane", candidates: testUsers)
        XCTAssertNotNil(result, "Should handle hyphenated names")
    }

    func testNameWithoutHyphenMatchesHyphenatedName() {
        let result = NameMatcher.matchAssignee(name: "Mary", candidates: testUsers)
        XCTAssertEqual(result, testUsers[4].id, "Should match first part of hyphenated name")
    }

    // MARK: - No Match Tests

    func testNoMatchForUnknownName() {
        let result = NameMatcher.matchAssignee(name: "Bob Smith", candidates: testUsers)
        XCTAssertNil(result, "Should return nil for unknown name")
    }

    func testEmptyInputReturnsNil() {
        let result = NameMatcher.matchAssignee(name: "", candidates: testUsers)
        XCTAssertNil(result, "Should return nil for empty input")
    }

    func testWhitespaceOnlyInputReturnsNil() {
        let result = NameMatcher.matchAssignee(name: "   ", candidates: testUsers)
        XCTAssertNil(result, "Should return nil for whitespace-only input")
    }

    func testEmptyCandidatesReturnsNil() {
        let result = NameMatcher.matchAssignee(name: "John Doe", candidates: [])
        XCTAssertNil(result, "Should return nil when candidates list is empty")
    }

    // MARK: - Edge Cases

    func testSingleCharacterName() {
        let singleCharUser = User(id: UUID(), email: "a@example.com", name: "A", createdAt: Date(), organizationIds: [])
        let result = NameMatcher.matchAssignee(name: "A", candidates: [singleCharUser])
        XCTAssertEqual(result, singleCharUser.id, "Should match single character name")
    }

    func testVeryLongName() {
        let longName = "John Jacob Jingleheimer Schmidt The Third"
        let longNameUser = User(id: UUID(), email: "john@example.com", name: longName, createdAt: Date(), organizationIds: [])
        let result = NameMatcher.matchAssignee(name: longName, candidates: [longNameUser])
        XCTAssertEqual(result, longNameUser.id, "Should match very long name exactly")
    }

    func testPartialMatchWithMultipleComponents() {
        let result = NameMatcher.matchAssignee(name: "J. Doe", candidates: testUsers)
        XCTAssertNotNil(result, "Should match 'J. Doe' to a Doe")
    }
}
