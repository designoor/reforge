import Foundation
import Security

// MARK: - KeychainError

/// Errors that can occur during Keychain operations.
enum KeychainError: Error, LocalizedError {
    /// The item could not be saved because a duplicate already exists.
    case duplicateItem
    /// The requested item was not found in the Keychain.
    case itemNotFound
    /// The data retrieved from the Keychain could not be decoded as a UTF-8 string.
    case invalidData
    /// An unexpected Keychain error occurred.
    case unexpectedError(OSStatus)

    var errorDescription: String? {
        switch self {
        case .duplicateItem:
            return "A Keychain item with this key already exists."
        case .itemNotFound:
            return "The requested Keychain item was not found."
        case .invalidData:
            return "The Keychain item data could not be read."
        case .unexpectedError(let status):
            return "Keychain error: \(status)"
        }
    }
}

// MARK: - KeychainService

/// Static utility for securely storing and retrieving the API key in the iOS Keychain.
/// Uses `kSecClassGenericPassword` with a fixed service identifier.
enum KeychainService {

    // MARK: - Constants

    private static let service = "com.reforge.healthcoach.apikey"
    private static let account = "anthropic-api-key"

    // MARK: - Public API

    /// Saves the API key to the Keychain.
    /// If a key already exists, it is replaced.
    /// - Parameter key: The API key string to store.
    /// - Throws: `KeychainError` if the save operation fails.
    static func saveAPIKey(_ key: String) throws {
        guard let data = key.data(using: .utf8) else {
            throw KeychainError.invalidData
        }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data,
        ]

        let status = SecItemAdd(query as CFDictionary, nil)

        if status == errSecDuplicateItem {
            let searchQuery: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: service,
                kSecAttrAccount as String: account,
            ]
            let updateAttributes: [String: Any] = [
                kSecValueData as String: data,
            ]
            let updateStatus = SecItemUpdate(
                searchQuery as CFDictionary,
                updateAttributes as CFDictionary
            )
            guard updateStatus == errSecSuccess else {
                throw KeychainError.unexpectedError(updateStatus)
            }
        } else if status != errSecSuccess {
            throw KeychainError.unexpectedError(status)
        }
    }

    /// Retrieves the API key from the Keychain.
    /// - Returns: The stored API key, or `nil` if no key has been saved.
    /// - Throws: `KeychainError` if a Keychain error occurs (other than item not found).
    static func getAPIKey() throws -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        if status == errSecItemNotFound {
            return nil
        }

        guard status == errSecSuccess else {
            throw KeychainError.unexpectedError(status)
        }

        guard let data = result as? Data,
              let key = String(data: data, encoding: .utf8) else {
            throw KeychainError.invalidData
        }

        return key
    }

    /// Deletes the API key from the Keychain.
    /// Does nothing if no key exists (idempotent delete).
    /// - Throws: `KeychainError` if a Keychain error occurs (other than item not found).
    static func deleteAPIKey() throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]

        let status = SecItemDelete(query as CFDictionary)

        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unexpectedError(status)
        }
    }
}
