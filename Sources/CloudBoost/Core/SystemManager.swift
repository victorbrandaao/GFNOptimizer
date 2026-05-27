import Foundation

final class SystemManager {
    static let shared = SystemManager()
    private var caffeinateProcess: Process?

    private init() {}

    // MARK: - Public API

    func enableGamingMode(processNames: [String],
                          openBundleId: String?,
                          completion: @escaping (Bool) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            let preset = Preferences.presetConfig()
            self.captureSnapshotIfNeeded()

            // 1. Launch the platform app if a bundle ID is known.
            if let bundleId = openBundleId, !bundleId.isEmpty {
                let openProcess = Process()
                openProcess.launchPath = "/bin/sh"
                openProcess.arguments = ["-c", "open -b \(self.shellQuote(bundleId))"]
                openProcess.launch()
            }

            // 2. Give the app time to initialise before renicing.
            //    asyncAfter releases the current thread back to the GCD pool
            //    during the wait, unlike Thread.sleep.
            DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + 4.0) {
                let filteredNames = self.filterProcessNames(processNames)

                let awdlCmd   = preset.disableAwdl        ? "ifconfig awdl0 down"                                        : "true"
                let dnsCmd    = preset.flushDns           ? "dscacheutil -flushcache && killall -HUP mDNSResponder"      : "true"
                let tmCmd     = preset.disableTimeMachine ? "tmutil disable"                                             : "true"
                let purgeCmd  = preset.purgeMemory        ? "command -v purge >/dev/null && purge || true"               : "true"

                var reniceCmd = "true"
                if !filteredNames.isEmpty {
                    let quoted = filteredNames.map { self.shellQuote($0) }.joined(separator: " ")
                    reniceCmd = """
                    for name in \(quoted); do \
                      PID=$(pgrep -x "$name" | head -n 1); \
                      if [ -n "$PID" ]; then renice -20 -p "$PID"; fi; \
                    done
                    """
                }

                let script = [awdlCmd, dnsCmd, tmCmd, purgeCmd, reniceCmd].joined(separator: "; ")
                let success = self.executePrivileged(script)

                Preferences.lastBoostActive = success
                if success, preset.keepAwake {
                    self.startCaffeinate()
                } else if !success {
                    self.stopCaffeinate()
                }

                DispatchQueue.main.async { completion(success) }
            }
        }
    }

    /// Re-applies renice to the given process names using existing admin session.
    /// Called when the user switches platform while boost is active.
    func reapplyRenice(processNames: [String]) {
        DispatchQueue.global(qos: .userInitiated).async {
            let filteredNames = self.filterProcessNames(processNames)
            guard !filteredNames.isEmpty else { return }

            let quoted = filteredNames.map { self.shellQuote($0) }.joined(separator: " ")
            let reniceCmd = """
            for name in \(quoted); do \
              PID=$(pgrep -x "$name" | head -n 1); \
              if [ -n "$PID" ]; then renice -20 -p "$PID"; fi; \
            done
            """
            let success = self.executePrivileged(reniceCmd)
            DiagnosticsManager.shared.log("reapplyRenice: \(success ? "OK" : "failed")")
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
            DiagnosticsManager.shared.log("Safe restore applied on launch")
        }
    }

    // MARK: - Privileged execution

    /// Executes a shell script with administrator privileges via AppleScript.
    ///
    /// The command is **base64-encoded** before embedding in the AppleScript
    /// string literal. Because base64 output is restricted to `[A-Za-z0-9+/=]`,
    /// it is impossible for user-supplied data to escape the string and inject
    /// arbitrary AppleScript or shell commands.
    private func executePrivileged(_ command: String) -> Bool {
        let encoded = Data(command.utf8).base64EncodedString()
        let src = "do shell script \"echo \(encoded) | base64 -d | sh\" with administrator privileges"
        var error: NSDictionary?
        guard let script = NSAppleScript(source: src) else { return false }
        script.executeAndReturnError(&error)
        if let err = error {
            DiagnosticsManager.shared.log("executePrivileged error: \(err)")
        }
        return error == nil
    }

    // MARK: - Caffeinate

    private func startCaffeinate() {
        stopCaffeinate()
        let p = Process()
        p.launchPath = "/usr/bin/caffeinate"
        p.arguments  = ["-d", "-i"]
        p.launch()
        caffeinateProcess = p
    }

    private func stopCaffeinate() {
        guard let p = caffeinateProcess else { return }
        if p.isRunning { p.terminate() }
        caffeinateProcess = nil
    }

    // MARK: - System snapshot

    private func captureSnapshotIfNeeded() {
        guard Preferences.lastSnapshot == nil else { return }

        let awdlActive   = runShell("ifconfig awdl0 2>/dev/null | grep -q 'status: active' && echo 1 || echo 0") == "1"
        let tmActive     = runShell("tmutil status 2>/dev/null | grep -q 'Running = 1' && echo 1 || echo 0")    == "1"
        // Use -g (GlobalPreferences) flag so the read domain is consistent
        // with the `defaults write -g` call used during restore.
        let mouseScaling = runShell("defaults read -g com.apple.mouse.scaling 2>/dev/null || echo 1.5")

        let state = SystemState(awdlEnabled: awdlActive,
                                timeMachineEnabled: tmActive,
                                mouseScaling: mouseScaling,
                                timestamp: Date())
        if let data = try? JSONEncoder().encode(state) {
            Preferences.lastSnapshot = data
        }
    }

    private func restoreSnapshotIfNeeded() {
        guard let data  = Preferences.lastSnapshot,
              let state = try? JSONDecoder().decode(SystemState.self, from: data) else { return }

        let awdlCmd  = state.awdlEnabled        ? "ifconfig awdl0 up"   : "ifconfig awdl0 down"
        let tmCmd    = state.timeMachineEnabled  ? "tmutil enable"       : "tmutil disable"
        let mouseCmd = "defaults write -g com.apple.mouse.scaling \(shellQuote(state.mouseScaling))"
        let script   = "\(awdlCmd); \(tmCmd); \(mouseCmd)"

        if executePrivileged(script) {
            Preferences.lastSnapshot = nil
        } else {
            DiagnosticsManager.shared.log("Safe restore failed — snapshot retained for next launch")
        }
    }

    // MARK: - Process helpers

    private func filterProcessNames(_ names: [String]) -> [String] {
        var result = names
        let allow  = Preferences.allowlist
        let block  = Preferences.blocklist
        if !allow.isEmpty { result = result.filter {  allow.contains($0) } }
        if !block.isEmpty { result = result.filter { !block.contains($0) } }
        return result
    }

    // MARK: - Shell helpers

    /// Returns `value` enclosed in single quotes, safe for POSIX shell embedding.
    /// Any literal single-quote inside the value is replaced with `'\''`.
    func shellQuote(_ value: String) -> String {
        "'\(value.replacingOccurrences(of: "'", with: "'\\''" ))'"
    }

    private func runShell(_ command: String) -> String {
        let process = Process()
        let pipe    = Pipe()
        process.launchPath      = "/bin/sh"
        process.arguments       = ["-c", command]
        process.standardOutput  = pipe
        process.standardError   = Pipe()
        process.launch()
        process.waitUntilExit()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        return String(data: data, encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }

    // MARK: - HUD data sources

    func firstMatchingPid(_ names: [String]) -> String? {
        for name in names {
            let q = shellQuote(name)
            let exact = runShell("pgrep -x \(q) | head -n 1")
            if !exact.isEmpty { return exact }
            let fuzzy = runShell("pgrep -f \(q) | head -n 1")
            if !fuzzy.isEmpty { return fuzzy }
        }
        return nil
    }

    func readCpuUsage(pid: String) -> String? {
        let safePid = pid.filter { $0.isNumber }
        guard !safePid.isEmpty else { return nil }
        let v = runShell("ps -p \(safePid) -o %cpu= | tr -d ' '")
        return v.isEmpty ? nil : v
    }

    func readNiceValue(pid: String) -> String? {
        let safePid = pid.filter { $0.isNumber }
        guard !safePid.isEmpty else { return nil }
        let v = runShell("ps -p \(safePid) -o nice= | tr -d ' '")
        return v.isEmpty ? nil : v
    }

    func pingStats() -> String {
        let output = runShell("ping -c 1 -W 1000 1.1.1.1 2>/dev/null")
        if let range = output.range(of: "time=") {
            let after = output[range.upperBound...]
            if let end = after.range(of: " ms") {
                let value = String(after[..<end.lowerBound]).trimmingCharacters(in: .whitespaces)
                if !value.isEmpty { return "\(value)ms" }
            }
        }
        return "—"
    }
}