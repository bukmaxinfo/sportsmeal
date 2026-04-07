import Foundation
import Security

enum APIConfig {
    static let anthropicBaseURL = "https://api.anthropic.com/v1/messages"
    static let model = "claude-sonnet-4-20250514"

    // Store API key in Keychain so it never touches disk in plain text
    private static let keychainService = "com.sportsmeal.apikey"
    private static let keychainAccount = "anthropic"

    static var anthropicAPIKey: String? {
        get { readKeychain() }
        set {
            if let value = newValue, !value.isEmpty {
                saveKeychain(value)
            } else {
                deleteKeychain()
            }
        }
    }

    static var hasAPIKey: Bool {
        guard let key = anthropicAPIKey else { return false }
        return !key.isEmpty
    }

    // MARK: - Keychain helpers

    private static func saveKeychain(_ value: String) {
        deleteKeychain()
        let data = Data(value.utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount,
            kSecValueData as String: data
        ]
        SecItemAdd(query as CFDictionary, nil)
    }

    private static func readKeychain() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private static func deleteKeychain() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount
        ]
        SecItemDelete(query as CFDictionary)
    }
}
