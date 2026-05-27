import AppKit

class UpdateManager {
    static let shared = UpdateManager()

    // In `swift run` the executable has no Info.plist bundle.
    // Skip version comparison to avoid false "outdated" alerts.
    private var currentVersion: String? {
        guard let v = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String,
              !v.isEmpty else { return nil }
        return v
    }

    private let releaseURL = URL(string: "https://api.github.com/repos/victorbrandaao/CloudBoost/releases/latest")!

    func checkForUpdates(silent: Bool = false) {
        guard let currentVersion else {
            if !silent {
                showError("Update check is unavailable in dev builds. Use a signed .app bundle to check updates.")
            }
            return
        }

        let task = URLSession.shared.dataTask(with: releaseURL) { data, _, error in
            guard let data, error == nil else {
                if !silent { self.showError("Failed to check for updates. Check your connection.") }
                return
            }
            do {
                if let json     = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let tagName  = json["tag_name"]  as? String,
                   let htmlUrl  = json["html_url"]  as? String {

                    let latestVersion = tagName.replacingOccurrences(of: "v", with: "")
                    // Parse release notes from the GitHub API response body field.
                    let releaseNotes  = json["body"] as? String ?? "No release notes available."

                    if latestVersion.compare(currentVersion, options: .numeric) == .orderedDescending {
                        DispatchQueue.main.async {
                            self.showUpdatePrompt(latestVersion: latestVersion,
                                                  currentVersion: currentVersion,
                                                  downloadUrl: htmlUrl,
                                                  releaseNotes: releaseNotes)
                        }
                    } else if !silent {
                        DispatchQueue.main.async { self.showUpToDate(currentVersion: currentVersion) }
                    }
                }
            } catch {
                if !silent { self.showError("Failed to parse update data.") }
            }
        }
        task.resume()
    }

    // MARK: - Dialogs

    private func showUpdatePrompt(latestVersion: String,
                                  currentVersion: String,
                                  downloadUrl: String,
                                  releaseNotes: String) {
        let alert = NSAlert()
        alert.messageText    = "Update Available — v\(latestVersion)"
        alert.informativeText = "You are running v\(currentVersion). Would you like to download v\(latestVersion)?"
        alert.alertStyle     = .informational
        alert.addButton(withTitle: "Download")
        alert.addButton(withTitle: "Release Notes")   // Now shows actual notes from the API
        alert.addButton(withTitle: "Later")

        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            if let url = URL(string: downloadUrl) { NSWorkspace.shared.open(url) }
        } else if response == .alertSecondButtonReturn {
            showReleaseNotes(releaseNotes, version: latestVersion, downloadUrl: downloadUrl)
        }
    }

    /// Displays the actual markdown release notes fetched from the GitHub API.
    private func showReleaseNotes(_ notes: String, version: String, downloadUrl: String) {
        let alert = NSAlert()
        alert.messageText = "Release Notes — v\(version)"
        alert.alertStyle  = .informational

        let scrollView = NSScrollView(frame: NSRect(x: 0, y: 0, width: 440, height: 220))
        let textView   = NSTextView(frame: scrollView.bounds)
        textView.string    = notes
        textView.isEditable = false
        textView.drawsBackground = false
        textView.font = NSFont.monospacedSystemFont(ofSize: 11, weight: .regular)
        scrollView.documentView = textView
        scrollView.hasVerticalScroller = true
        alert.accessoryView = scrollView

        alert.addButton(withTitle: "Download")
        alert.addButton(withTitle: "Close")
        if alert.runModal() == .alertFirstButtonReturn,
           let url = URL(string: downloadUrl) {
            NSWorkspace.shared.open(url)
        }
    }

    private func showUpToDate(currentVersion: String) {
        let alert = NSAlert()
        alert.messageText     = "Up to Date"
        alert.informativeText = "You are running the latest version of CloudBoost (v\(currentVersion))."
        alert.alertStyle      = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    private func showError(_ message: String) {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText     = "Update Error"
            alert.informativeText = message
            alert.alertStyle      = .warning
            alert.addButton(withTitle: "OK")
            alert.runModal()
        }
    }
}