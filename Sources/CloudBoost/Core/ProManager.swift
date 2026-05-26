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
    
    init() {
        // Upon initialization, if we have a key, we assume it's valid for the session 
        // (or we could re-validate it online). For now, if it exists, unlock it.
        if let _ = KeychainHelper.shared.read(service: service, account: account) {
            isProUnlocked = true
        }
    }
    
    /// Validates the license key online with Lemon Squeezy API
    func validateLicense(key: String, completion: @escaping (Bool, String?) -> Void) {
        guard let url = URL(string: "https://api.lemonsqueezy.com/v1/licenses/validate") else {
            completion(false, "Invalid URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let bodyString = "license_key=\(key)"
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
                    // Lemon Squeezy returns 'valid': true/false in 'valid' or 'meta' field usually
                    if let valid = json["valid"] as? Bool, valid == true {
                        // Success! Save to keychain and unlock
                        if let keyData = key.data(using: .utf8) {
                            KeychainHelper.shared.save(keyData, service: self.service, account: self.account)
                        }
                        DispatchQueue.main.async {
                            self.isProUnlocked = true
                            completion(true, nil)
                        }
                    } else {
                        // Invalid key
                        let errorMsg = json["error"] as? String ?? "Invalid License Key"
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
    
    /// Unlinks the current license
    func unlinkLicense() {
        KeychainHelper.shared.delete(service: service, account: account)
        isProUnlocked = false
    }
}

extension Notification.Name {
    static let proStatusChanged = Notification.Name("proStatusChanged")
}
