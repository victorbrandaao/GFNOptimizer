import AppKit

class UpdateManager {
    static let shared = UpdateManager()
    
    // Atualizado para a versão 1.3.0
    private let currentVersion = "1.3.1" 
    
    // URL atualizada para o novo repositório CloudBoost
    private let releaseURL = URL(string: "https://api.github.com/repos/victorbrandaao/CloudBoost/releases/latest")!
    
    func checkForUpdates(silent: Bool = false) {
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
                    
                    if latestVersion.compare(self.currentVersion, options: .numeric) == .orderedDescending {
                        DispatchQueue.main.async {
                            self.showUpdatePrompt(latestVersion: latestVersion, url: htmlUrl)
                        }
                    } else if !silent {
                        DispatchQueue.main.async {
                            self.showUpToDate()
                        }
                    }
                }
            } catch {
                if !silent { self.showError("Failed to parse update data.") }
            }
        }
        task.resume()
    }
    
    private func showUpdatePrompt(latestVersion: String, url: String) {
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
    
    private func showUpToDate() {
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