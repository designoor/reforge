import Testing
@testable import Reforge

@Suite(.serialized)
struct KeychainServiceTests {

    // MARK: - Helpers

    /// Ensures a clean Keychain state before each test.
    private func cleanUp() throws {
        try KeychainService.deleteAPIKey()
    }

    // MARK: - Save and Retrieve

    @Test func saveAndRetrieve_roundTrip() throws {
        try cleanUp()
        let testKey = "sk-ant-test-key-12345"
        try KeychainService.saveAPIKey(testKey)
        let retrieved = try KeychainService.getAPIKey()
        #expect(retrieved == testKey)
        try cleanUp()
    }

    @Test func getAPIKey_returnsNilWhenEmpty() throws {
        try cleanUp()
        let result = try KeychainService.getAPIKey()
        #expect(result == nil)
    }

    @Test func saveAPIKey_overwritesExistingKey() throws {
        try cleanUp()
        let firstKey = "sk-ant-first-key"
        let secondKey = "sk-ant-second-key"
        try KeychainService.saveAPIKey(firstKey)
        try KeychainService.saveAPIKey(secondKey)
        let retrieved = try KeychainService.getAPIKey()
        #expect(retrieved == secondKey)
        try cleanUp()
    }

    // MARK: - Delete

    @Test func deleteAPIKey_removesStoredKey() throws {
        try cleanUp()
        try KeychainService.saveAPIKey("sk-ant-to-delete")
        try KeychainService.deleteAPIKey()
        let result = try KeychainService.getAPIKey()
        #expect(result == nil)
    }

    @Test func deleteAPIKey_doesNotThrowWhenEmpty() throws {
        try cleanUp()
        try KeychainService.deleteAPIKey()
    }

    // MARK: - Full Lifecycle

    @Test func fullLifecycle_saveDeleteSave() throws {
        try cleanUp()
        let firstKey = "sk-ant-lifecycle-1"
        let secondKey = "sk-ant-lifecycle-2"

        try KeychainService.saveAPIKey(firstKey)
        #expect(try KeychainService.getAPIKey() == firstKey)

        try KeychainService.deleteAPIKey()
        #expect(try KeychainService.getAPIKey() == nil)

        try KeychainService.saveAPIKey(secondKey)
        #expect(try KeychainService.getAPIKey() == secondKey)

        try cleanUp()
    }

    // MARK: - Edge Cases

    @Test func saveAPIKey_emptyString() throws {
        try cleanUp()
        try KeychainService.saveAPIKey("")
        let retrieved = try KeychainService.getAPIKey()
        #expect(retrieved == "")
        try cleanUp()
    }

    @Test func saveAPIKey_longKey() throws {
        try cleanUp()
        let longKey = String(repeating: "a", count: 1000)
        try KeychainService.saveAPIKey(longKey)
        let retrieved = try KeychainService.getAPIKey()
        #expect(retrieved == longKey)
        try cleanUp()
    }

    @Test func saveAPIKey_specialCharacters() throws {
        try cleanUp()
        let specialKey = "sk-ant-api03-key/with+special=chars&more!"
        try KeychainService.saveAPIKey(specialKey)
        let retrieved = try KeychainService.getAPIKey()
        #expect(retrieved == specialKey)
        try cleanUp()
    }
}
