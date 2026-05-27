import Foundation
import AppKit

final class ProManager {
    static let shared = ProManager()

    private let service = "com.victorbrandaao.CloudBoost"
    private let account = "license_key"

    var isProUnlocked: Bool = false {
        didSet {
            NotificationCenter.default.post(name: .proStatusChanged, object: nil)
        }
    }

    private init() {
        // On launch, unlock if a stored key exists (offline-first).
        // Then attempt a background re-validation against Gumroad.
        if let keyData = KeychainHelper.shared.read(service: service, account: account),
           let key = String(data: keyData, encoding: .utf8), !key.isEmpty {
            isProUnlocked = true
            revalidateInBackground(key: key)
        }
    }

    // MARK: - Online validation

    /// Validates the license key online with Gumroad API.
    func validateLicense(key: String, completion: @escaping (Bool, String?) -> Void) {
        guard let url = URL(string: "https://api.gumroad.com/v2/licenses/verify") else {
            completion(false, "Invalid URL")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let productPermalink = "CloudBoost"
        let encodedKey = key.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? key
        let bodyString = "product_permalink=\(productPermalink)&license_key=\(encodedKey)"
        request.httpBody = bodyString.data(using: .utf8)

        let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }

            if let error = error {
                DispatchQueue.main.async { completion(false, error.localizedDescription) }
                return
            }

            guard let data = data else {
                DispatchQueue.main.async { completion(false, "No data received") }
                return
            }

            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    if let valid = json["success"] as? Bool, valid == true {
                        if let keyData = key.data(using: .utf8) {
                            KeychainHelper.shared.save(keyData, service: self.service, account: self.account)
                        }
                        DispatchQueue.main.async {
                            self.isProUnlocked = true
                            completion(true, nil)
                        }
                    } else {
                        let errorMsg = json["message"] as? String ?? "Invalid License Key"
                        DispatchQueue.main.async { completion(false, errorMsg) }
                    }
                } else {
                    DispatchQueue.main.async { completion(false, "Invalid response format") }
                }
            } catch {
                DispatchQueue.main.async { completion(false, "Failed to parse response") }
            }
        }
        task.resume()
    }

    /// Unlinks the current license.
    func unlinkLicense() {
        KeychainHelper.shared.delete(service: service, account: account)
        isProUnlocked = false
    }

    // MARK: - Background re-validation

    /// Silently re-validates the stored key at startup.
    /// If the Gumroad server confirms the key is revoked, the license is removed.
    /// Network errors are ignored (offline-first: keep the unlock until proven invalid).
    private func revalidateInBackground(key: String) {
        guard let url = URL(string: "https://api.gumroad.com/v2/licenses/verify") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let productPermalink = "CloudBoost"
        let encodedKey = key.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? key
        let bodyString = "product_permalink=\(productPermalink)&license_key=\(encodedKey)"
        request.httpBody = bodyString.data(using: .utf8)

        let task = URLSession.shared.dataTask(with: request) { [weak self] data, _, error in
            guard let self = self else { return }

            // Network errors → keep the license (offline-first).
            guard error == nil, let data = data else {
                DiagnosticsManager.shared.log("PRO re-validation skipped (offline)")
                return
            }

            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let valid = json["success"] as? Bool else { return }

            if !valid {
                // Key was revoked or is no longer valid.
                DiagnosticsManager.shared.log("PRO license revoked by server")
                DispatchQueue.main.async {
                    self.isProUnlocked = false
                    KeychainHelper.shared.delete(service: self.service, account: self.account)
                }
            } else {
                DiagnosticsManager.shared.log("PRO license re-validated OK")
            }
        }
        task.resume()
    }
}
