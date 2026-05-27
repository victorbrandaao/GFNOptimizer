import Foundation
import Security

final class KeychainHelper {
    static let shared = KeychainHelper()
    private init() {}

    @discardableResult
    func save(_ data: Data, service: String, account: String) -> Bool {
        let query = [
            kSecValueData: data,
            kSecAttrService: service,
            kSecAttrAccount: account,
            kSecClass: kSecClassGenericPassword
        ] as CFDictionary

        let status = SecItemAdd(query, nil)

        if status == errSecDuplicateItem {
            let searchQuery = [
                kSecAttrService: service,
                kSecAttrAccount: account,
                kSecClass: kSecClassGenericPassword
            ] as CFDictionary
            let attrs = [kSecValueData: data] as CFDictionary
            let updateStatus = SecItemUpdate(searchQuery, attrs)
            if updateStatus != errSecSuccess {
                DiagnosticsManager.shared.log("Keychain update failed: \(updateStatus)")
            }
            return updateStatus == errSecSuccess
        }

        if status != errSecSuccess {
            DiagnosticsManager.shared.log("Keychain save failed: \(status)")
        }
        return status == errSecSuccess
    }

    func read(service: String, account: String) -> Data? {
        let query = [
            kSecAttrService: service,
            kSecAttrAccount: account,
            kSecClass: kSecClassGenericPassword,
            kSecReturnData: true
        ] as CFDictionary

        var result: AnyObject?
        let status = SecItemCopyMatching(query, &result)

        if status != errSecSuccess, status != errSecItemNotFound {
            DiagnosticsManager.shared.log("Keychain read failed: \(status)")
        }

        return result as? Data
    }

    @discardableResult
    func delete(service: String, account: String) -> Bool {
        let query = [
            kSecAttrService: service,
            kSecAttrAccount: account,
            kSecClass: kSecClassGenericPassword
        ] as CFDictionary

        let status = SecItemDelete(query)
        if status != errSecSuccess, status != errSecItemNotFound {
            DiagnosticsManager.shared.log("Keychain delete failed: \(status)")
        }
        return status == errSecSuccess || status == errSecItemNotFound
    }
}
