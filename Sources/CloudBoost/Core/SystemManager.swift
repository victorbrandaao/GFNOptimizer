import Foundation

class SystemManager {
    static let shared = SystemManager()
    private var caffeinateProcess: Process?
    
    private init() {}

    func enableGamingMode(processNames: [String], openBundleId: String?, completion: @escaping (Bool) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            let preset = Preferences.presetConfig()
            self.captureSnapshotIfNeeded()
            
            // 1. Abre o aplicativo via Bundle ID, se conhecido
            if let bundleId = openBundleId, !bundleId.isEmpty {
                let openProcess = Process()
                openProcess.launchPath = "/bin/sh"
                openProcess.arguments = ["-c", "open -b \"\(self.shellEscape(bundleId))\""]
                openProcess.launch()
            }
            
            // Aguarda 4 segundos para o aplicativo carregar na tela
            Thread.sleep(forTimeInterval: 4.0)

            let filteredNames = self.filterProcessNames(processNames)
            let escapedNames = filteredNames.map { "\"\(self.shellEscape($0))\"" }.joined(separator: " ")
            let awdlCommand = preset.disableAwdl ? "ifconfig awdl0 down" : "true"
            let dnsCommand = preset.flushDns ? "dscacheutil -flushcache; killall -HUP mDNSResponder" : "true"
            let tmCommand = preset.disableTimeMachine ? "tmutil disable" : "true"
            let purgeCommand = preset.purgeMemory ? "command -v purge >/dev/null && purge || true" : "true"
            let reniceCommand = filteredNames.isEmpty ? "true" : "for name in \(escapedNames); do PID=$(pgrep -x \"$name\" | head -n 1); if [ -n \"$PID\" ]; then renice -20 -p \"$PID\"; fi; done"

            let enableScript = """
            \(awdlCommand); \
            \(dnsCommand); \
            \(tmCommand); \
            \(purgeCommand); \
            \(reniceCommand)
            """
            
            let success = self.executePrivileged(enableScript)
            Preferences.lastBoostActive = success
            if success {
                if preset.keepAwake {
                    self.startCaffeinate()
                }
            } else {
                self.stopCaffeinate()
            }
            DispatchQueue.main.async { completion(success) }
        }
    }

    func disableGamingMode(completion: @escaping () -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            self.restoreSnapshotIfNeeded()
            self.stopCaffeinate()
            MouseManager.apply(profile: .defaultMac)
            Preferences.lastBoostActive = false
            DispatchQueue.main.async { completion() }
        }
    }

    func restoreIfNeeded() {
        DispatchQueue.global(qos: .userInitiated).async {
            guard Preferences.lastBoostActive else { return }
            self.restoreSnapshotIfNeeded()
            Preferences.lastBoostActive = false
            NotificationManager.shared.notify(title: "CloudBoost", body: "Safe restore applied")
            DiagnosticsManager.shared.log("Safe restore applied")
        }
    }

    private func startCaffeinate() {
        stopCaffeinate()
        let process = Process()
        process.launchPath = "/usr/bin/caffeinate"
        process.arguments = ["-d", "-i"]
        process.launch()
        caffeinateProcess = process
    }
    
    private func stopCaffeinate() {
        if let process = caffeinateProcess, process.isRunning {
            process.terminate()
            caffeinateProcess = nil
        }
    }

    private func executePrivileged(_ command: String) -> Bool {
        let script = "do shell script \"\(command)\" with administrator privileges"
        var error: NSDictionary?
        if let appleScript = NSAppleScript(source: script) {
            appleScript.executeAndReturnError(&error)
            return error == nil
        }
        return false
    }

    private func captureSnapshotIfNeeded() {
        guard Preferences.lastSnapshot == nil else { return }
        let awdlEnabled = runShell("ifconfig awdl0 2>/dev/null | grep -q 'status: active' && echo 1 || echo 0") == "1"
        let tmEnabled = runShell("tmutil status 2>/dev/null | grep -q 'Running = 1' && echo 1 || echo 0") == "1"
        let mouseScaling = runShell("defaults read -g com.apple.mouse.scaling 2>/dev/null || echo 1.5")
        let state = SystemState(awdlEnabled: awdlEnabled, timeMachineEnabled: tmEnabled, mouseScaling: mouseScaling, timestamp: Date())
        if let data = try? JSONEncoder().encode(state) {
            Preferences.lastSnapshot = data
        }
    }

    private func restoreSnapshotIfNeeded() {
        guard let data = Preferences.lastSnapshot,
              let state = try? JSONDecoder().decode(SystemState.self, from: data) else {
            return
        }
        let awdlCommand = state.awdlEnabled ? "ifconfig awdl0 up" : "ifconfig awdl0 down"
        let tmCommand = state.timeMachineEnabled ? "tmutil enable" : "tmutil disable"
        let mouseCommand = "defaults write -g com.apple.mouse.scaling \(state.mouseScaling)"
        let script = "\(awdlCommand); \(tmCommand); \(mouseCommand)"
        if executePrivileged(script) {
            Preferences.lastSnapshot = nil
        } else {
            DiagnosticsManager.shared.log("Safe restore failed")
        }
    }

    private func filterProcessNames(_ names: [String]) -> [String] {
        var result = names
        let allowlist = Preferences.allowlist
        let blocklist = Preferences.blocklist
        if !allowlist.isEmpty {
            result = result.filter { allowlist.contains($0) }
        }
        if !blocklist.isEmpty {
            result = result.filter { !blocklist.contains($0) }
        }
        return result
    }

    private func runShell(_ command: String) -> String {
        let process = Process()
        let pipe = Pipe()
        process.launchPath = "/bin/sh"
        process.arguments = ["-c", command]
        process.standardOutput = pipe
        process.standardError = Pipe()
        process.launch()
        process.waitUntilExit()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        return String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }

    func firstMatchingPid(_ names: [String]) -> String? {
        for name in names {
            let escaped = shellEscape(name)
            let exactPid = runShell("pgrep -x \"\(escaped)\" | head -n 1")
            if !exactPid.isEmpty {
                return exactPid
            }
            let fuzzyPid = runShell("pgrep -f \"\(escaped)\" | head -n 1")
            if !fuzzyPid.isEmpty {
                return fuzzyPid
            }
        }
        return nil
    }

    func readCpuUsage(pid: String) -> String {
        runShell("ps -p \(pid) -o %cpu= | tr -d ' '")
    }

    func readNiceValue(pid: String) -> String {
        runShell("ps -p \(pid) -o nice= | tr -d ' '")
    }

    func pingStats() -> String {
        let output = runShell("ping -c 1 -W 1000 1.1.1.1")
        if let range = output.range(of: "time=") {
            let after = output[range.upperBound...]
            if let end = after.range(of: " ms") {
                let value = after[..<end.lowerBound].trimmingCharacters(in: .whitespaces)
                if !value.isEmpty {
                    return "\(value)ms"
                }
            }
        }
        return "n/a"
    }

    private func shellEscape(_ value: String) -> String {
        value.replacingOccurrences(of: "\"", with: "\\\"")
    }
}