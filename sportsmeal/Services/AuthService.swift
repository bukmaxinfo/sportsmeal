import Foundation
import AuthenticationServices
import CloudKit
import Security
import UIKit
import Observation

// MARK: - AuthService

/// Manages Sign in with Apple authentication state,
/// Keychain session persistence, and best-effort CloudKit profile sync.
@Observable
final class AuthService {

    enum AuthState {
        case checking          // Initial launch — verifying saved session
        case unauthenticated   // No valid session; show LoginView
        case authenticated(userID: String, displayName: String?)
    }

    private(set) var authState: AuthState = .checking

    // MARK: - Keychain Constants

    private static let keychainService  = "com.sportsmeal.auth"
    private static let appleUserIDKey   = "appleUserID"
    private static let displayNameKey   = "displayName"

    /// Must match the CloudKit container in sportsmeal.entitlements and Xcode Capabilities.
    static let cloudKitContainerID = "iCloud.BK.sportsmeal"

    // MARK: - Convenience Accessors

    var currentUserID: String? {
        guard case .authenticated(let id, _) = authState else { return nil }
        return id
    }

    var currentDisplayName: String? {
        guard case .authenticated(_, let name) = authState else { return nil }
        return name
    }

    // MARK: - Simulator Detection

    static var isSimulator: Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        return false
        #endif
    }

    // MARK: - Session Check on Launch

    func checkExistingSession() async {
        // On Simulator, bypass Sign in with Apple (it doesn't work) and auto-authenticate
        if Self.isSimulator {
            await MainActor.run {
                self.authState = .authenticated(userID: "simulator-user", displayName: "Simulator User")
            }
            return
        }

        guard let savedUserID = readKeychain(key: Self.appleUserIDKey) else {
            await MainActor.run { authState = .unauthenticated }
            return
        }

        let provider = ASAuthorizationAppleIDProvider()
        let credentialState: ASAuthorizationAppleIDProvider.CredentialState
        do {
            credentialState = try await withCheckedThrowingContinuation { cont in
                provider.getCredentialState(forUserID: savedUserID) { state, error in
                    if let error { cont.resume(throwing: error) }
                    else         { cont.resume(returning: state) }
                }
            }
        } catch {
            await MainActor.run { self.clearSession(); self.authState = .unauthenticated }
            return
        }

        await MainActor.run {
            switch credentialState {
            case .authorized:
                let name = self.readKeychain(key: Self.displayNameKey)
                self.authState = .authenticated(userID: savedUserID, displayName: name)
            case .revoked, .notFound, .transferred:
                self.clearSession()
                self.authState = .unauthenticated
            @unknown default:
                self.clearSession()
                self.authState = .unauthenticated
            }
        }
    }

    // MARK: - Sign In with Apple

    /// Call with the result from `SignInWithAppleButton`'s `onCompletion` closure.
    func handleAppleSignIn(_ result: Result<ASAuthorization, Error>) async {
        guard case .success(let authorization) = result,
              let credential = authorization.credential as? ASAuthorizationAppleIDCredential
        else {
            await MainActor.run { self.authState = .unauthenticated }
            return
        }

        let userID = credential.user

        // Apple only delivers fullName/email on the very first sign-in; cache in Keychain.
        var displayName: String? = nil
        if let components = credential.fullName {
            let formatted = PersonNameComponentsFormatter().string(from: components)
                .trimmingCharacters(in: .whitespaces)
            if !formatted.isEmpty { displayName = formatted }
        }

        saveKeychain(key: Self.appleUserIDKey, value: userID)
        if let name = displayName { saveKeychain(key: Self.displayNameKey, value: name) }

        await syncToCloudKit(userID: userID, displayName: displayName, email: credential.email)

        let cachedName = displayName ?? readKeychain(key: Self.displayNameKey)
        await MainActor.run {
            self.authState = .authenticated(userID: userID, displayName: cachedName)
        }
    }

    // MARK: - Sign Out

    func signOut() {
        clearSession()
        authState = .unauthenticated
    }

    // MARK: - CloudKit

    private func syncToCloudKit(
        userID: String,
        displayName: String?,
        email: String?
    ) async {
        let container = CKContainer(identifier: Self.cloudKitContainerID)
        let db        = container.privateCloudDatabase
        let recordID  = CKRecord.ID(recordName: "user_\(userID)")

        do {
            let record: CKRecord
            do {
                record = try await db.record(for: recordID)
            } catch {
                record = CKRecord(recordType: "UserAccount", recordID: recordID)
                record["createdAt"]   = Date() as CKRecordValue
                record["appleUserID"] = userID as CKRecordValue
            }

            if let name  = displayName { record["displayName"] = name  as CKRecordValue }
            if let email = email       { record["email"]       = email as CKRecordValue }
            record["lastSeenAt"] = Date() as CKRecordValue

            try await db.save(record)
        } catch {
            // CloudKit unavailable / iCloud not signed in — best-effort, auth still succeeds.
        }
    }

    // MARK: - Keychain Helpers

    private func saveKeychain(key: String, value: String) {
        guard let data = value.data(using: .utf8) else { return }
        let query: [CFString: Any] = [
            kSecClass:       kSecClassGenericPassword,
            kSecAttrService: Self.keychainService,
            kSecAttrAccount: key
        ]
        let update: [CFString: Any] = [kSecValueData: data]
        if SecItemUpdate(query as CFDictionary, update as CFDictionary) == errSecItemNotFound {
            var insert = query
            insert[kSecValueData] = data
            SecItemAdd(insert as CFDictionary, nil)
        }
    }

    private func readKeychain(key: String) -> String? {
        let query: [CFString: Any] = [
            kSecClass:       kSecClassGenericPassword,
            kSecAttrService: Self.keychainService,
            kSecAttrAccount: key,
            kSecReturnData:  kCFBooleanTrue!,
            kSecMatchLimit:  kSecMatchLimitOne
        ]
        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data
        else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private func deleteKeychain(key: String) {
        let query: [CFString: Any] = [
            kSecClass:       kSecClassGenericPassword,
            kSecAttrService: Self.keychainService,
            kSecAttrAccount: key
        ]
        SecItemDelete(query as CFDictionary)
    }

    private func clearSession() {
        deleteKeychain(key: Self.appleUserIDKey)
        deleteKeychain(key: Self.displayNameKey)
    }
}
