import AppKit

class UpdateManager {
    static let shared = UpdateManager()

    // Em `swift run`, o executável não tem Info.plist de bundle.
    // Nesse caso, não tentamos comparar versões para evitar cair em 0.0.0.
    private var currentVersion: String? {
        if let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String,
           !version.isEmpty {
            return version
        }
        return nil
    }
    
    private let releaseURL = URL(string: "https://api.github.com/repos/victorbrandaao/CloudBoost/releases/latest")!
    
    func checkForUpdates(silent: Bool = false) {
        guard let currentVersion else {
            return
        }

        let task = URLSession.shared.dataTask(with: releaseURL) { data, response, error in
            guard let data = data, error == nil else {
                if !silent { self.showError("Failed to check for updates. Check your connection.") }
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let tagName = json["tag_name"] as? String,
                   let htmlUrl = json["html_url"] as? String {
                    
                    let latestVersion = tagName.replacingOccurrences(of: "v", with: "")
                    
                    if latestVersion.compare(currentVersion, options: .numeric) == .orderedDescending {
                        DispatchQueue.main.async {
                            self.showUpdatePrompt(latestVersion: latestVersion, currentVersion: currentVersion, url: htmlUrl)
                        }
                    } else if !silent {
                        DispatchQueue.main.async {
                            self.showUpToDate(currentVersion: currentVersion)
                        }
                    }
                }
            } catch {
                if !silent { self.showError("Failed to parse update data.") }
            }
        }
        task.resume()
    }
    
    private func showUpdatePrompt(latestVersion: String, currentVersion: String, url: String) {
        let alert = NSAlert()
        alert.messageText = "Update Available"
        alert.informativeText = "A new version of CloudBoost (v\(latestVersion)) is available. You are currently running v\(currentVersion).\n\nWould you like to download it?"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Download")
        alert.addButton(withTitle: "Cancel")
        
        if alert.runModal() == .alertFirstButtonReturn {
            if let downloadURL = URL(string: url) {
                NSWorkspace.shared.open(downloadURL)
            }
        }
    }
    
    private func showUpToDate(currentVersion: String) {
        let alert = NSAlert()
        alert.messageText = "Up to Date"
        alert.informativeText = "You are running the latest version of CloudBoost (v\(currentVersion))."
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
    
    private func showError(_ message: String) {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = "Update Error"
            alert.informativeText = message
            alert.alertStyle = .warning
            alert.addButton(withTitle: "OK")
            alert.runModal()
        }
    }
}