import Foundation
import AppKit

final class SystemObservabilityManager {
    static let shared = SystemObservabilityManager()

    private let shellQueue = DispatchQueue(label: "com.cloudboost.observability-shell", qos: .utility)
    private let interferenceCandidates = [
        "backupd": "Time Machine",
        "mds": "Spotlight",
        "mdworker": "Spotlight",
        "bird": "iCloud Drive",
        "photolibraryd": "Photos",
        "Dropbox": "Dropbox",
        "OneDrive": "OneDrive"
    ]

    private init() {
        NetworkPathMonitor.shared.start()
    }

    func sample() -> SessionMetrics {
        let path = NetworkPathMonitor.shared.snapshot()
        let latency = measureLatency()
        let system = SystemHealthSnapshot(
            thermalState: ProcessInfo.processInfo.thermalState,
            lowPowerModeEnabled: ProcessInfo.processInfo.isLowPowerModeEnabled,
            interferingProcesses: detectInterferingProcesses()
        )
        return SessionMetrics(networkPath: path, latency: latency, system: system)
    }

    private func measureLatency() -> LatencySnapshot {
        let output = runShell("ping -c 3 -W 1000 1.1.1.1 2>/dev/null")
        let packetLoss = parsePacketLoss(output)
        let stats = parseRoundTripStats(output)
        return LatencySnapshot(averageMilliseconds: stats.average,
                               jitterMilliseconds: stats.stddev,
                               packetLossPercent: packetLoss)
    }

    private func detectInterferingProcesses() -> [String] {
        var found: [String] = []
        for (process, label) in interferenceCandidates {
            let escaped = shellQuote(process)
            let result = runShell("pgrep -x \(escaped) >/dev/null && echo 1 || echo 0")
            if result == "1", !found.contains(label) {
                found.append(label)
            }
        }
        return found
    }

    private func parsePacketLoss(_ output: String) -> Double? {
        guard let percentRange = output.range(of: "% packet loss") else { return nil }
        let prefix = output[..<percentRange.lowerBound]
        guard let comma = prefix.lastIndex(of: ",") else { return nil }
        let value = prefix[prefix.index(after: comma)...]
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return Double(value)
    }

    private func parseRoundTripStats(_ output: String) -> (average: Double?, stddev: Double?) {
        let markers = ["round-trip min/avg/max/stddev = ", "rtt min/avg/max/mdev = "]
        for marker in markers {
            guard let range = output.range(of: marker) else { continue }
            let tail = output[range.upperBound...]
            let line = tail.split(separator: "\n").first.map(String.init) ?? ""
            let values = line
                .replacingOccurrences(of: " ms", with: "")
                .split(separator: "/")
                .compactMap { Double($0.trimmingCharacters(in: .whitespacesAndNewlines)) }
            if values.count >= 4 {
                return (values[1], values[3])
            }
        }
        return (nil, nil)
    }

    private func runShell(_ command: String, timeout: TimeInterval = 4.0) -> String {
        shellQueue.sync {
            let process = Process()
            let pipe = Pipe()
            let semaphore = DispatchSemaphore(value: 0)
            process.launchPath = "/bin/sh"
            process.arguments = ["-c", command]
            process.standardOutput = pipe
            process.standardError = Pipe()
            process.terminationHandler = { _ in semaphore.signal() }
            process.launch()

            if semaphore.wait(timeout: .now() + timeout) == .timedOut {
                process.terminate()
                DiagnosticsManager.shared.log("Observability command timed out: \(command)")
                return ""
            }

            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            return String(data: data, encoding: .utf8)?
                .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        }
    }

    private func shellQuote(_ value: String) -> String {
        "'\(value.replacingOccurrences(of: "'", with: "'\\''" ))'"
    }
}
