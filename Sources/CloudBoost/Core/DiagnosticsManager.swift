import AppKit

/// Thread-safe diagnostics log.
/// All mutations to `events` happen on a private serial queue to prevent
/// data races when `log(_:)` is called from multiple GCD threads simultaneously.
final class DiagnosticsManager {
    static let shared = DiagnosticsManager()

    private var events: [String] = []
    private let maxEvents = 200
    private let queue = DispatchQueue(label: "com.cloudboost.diagnostics", qos: .utility)

    private init() {}

    func log(_ message: String) {
        queue.async {
            let timestamp = ISO8601DateFormatter().string(from: Date())
            let line = "[\(timestamp)] \(message)"
            self.events.append(line)
            if self.events.count > self.maxEvents {
                self.events.removeFirst(self.events.count - self.maxEvents)
            }
        }
    }

    func exportDiagnostics(selectedPlatform: CloudPlatform, targetProcessNames: [String]) {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = "cloudboost-diagnostics.txt"
        panel.allowedContentTypes = [.plainText]
        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }
            let content = self.buildReport(selectedPlatform: selectedPlatform, targetProcessNames: targetProcessNames)
            try? content.write(to: url, atomically: true, encoding: .utf8)
        }
    }

    func buildReport(selectedPlatform: CloudPlatform, targetProcessNames: [String]) -> String {
        // queue.sync is safe here: the caller must NOT be on the same serial queue.
        queue.sync {
            var lines: [String] = []
            lines.append("CloudBoost Diagnostics")
            lines.append("Date: \(Date())")
            lines.append("Platform: \(selectedPlatform.rawValue)")
            lines.append("Target processes: \(targetProcessNames.joined(separator: ", "))")
            lines.append("Preset: \(Preferences.selectedPreset.rawValue)")
            lines.append("Auto-detect: \(Preferences.autoDetectEnabled)")
            lines.append("HUD: \(Preferences.hudEnabled)")
            lines.append("Notifications: \(Preferences.notificationsEnabled)")
            lines.append("Keep-alive: \(Preferences.keepAliveEnabled)")
            lines.append("Keep-alive interval (min): \(Preferences.keepAliveIntervalMinutes)")
            lines.append("Allowlist: \(Preferences.allowlist.joined(separator: ", "))")
            lines.append("Blocklist: \(Preferences.blocklist.joined(separator: ", "))")
            lines.append("\nRecent Events:")
            lines.append(contentsOf: events)
            return lines.joined(separator: "\n")
        }
    }
}
