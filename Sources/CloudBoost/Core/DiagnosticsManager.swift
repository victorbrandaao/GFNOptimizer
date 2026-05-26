import AppKit

final class DiagnosticsManager {
    static let shared = DiagnosticsManager()

    private var events: [String] = []
    private let maxEvents = 200

    private init() {}

    func log(_ message: String) {
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let line = "[\(timestamp)] \(message)"
        events.append(line)
        if events.count > maxEvents {
            events.removeFirst(events.count - maxEvents)
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
        var lines: [String] = []
        lines.append("CloudBoost Diagnostics")
        lines.append("Date: \(Date())")
        lines.append("Platform: \(selectedPlatform.rawValue)")
        lines.append("Target processes: \(targetProcessNames.joined(separator: ", "))")
        lines.append("Preset: \(Preferences.selectedPreset.rawValue)")
        lines.append("Auto-detect: \(Preferences.autoDetectEnabled)")
        lines.append("HUD: \(Preferences.hudEnabled)")
        lines.append("Notifications: \(Preferences.notificationsEnabled)")
        lines.append("Allowlist: \(Preferences.allowlist.joined(separator: ", "))")
        lines.append("Blocklist: \(Preferences.blocklist.joined(separator: ", "))")
        lines.append("\nRecent Events:")
        lines.append(contentsOf: events)
        return lines.joined(separator: "\n")
    }
}
