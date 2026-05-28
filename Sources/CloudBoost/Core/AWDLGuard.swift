import Foundation

enum AWDLGuardStatus: String {
    case inactive = "Inactive"
    case guarded = "Guarded"
    case restoring = "Restoring"
}

final class AWDLGuard {
    static let shared = AWDLGuard()

    private let heartbeatPath = "/tmp/cloudboost-awdl.guard"
    private let lock = NSLock()
    private var status: AWDLGuardStatus = .inactive

    private init() {}

    var currentStatus: AWDLGuardStatus {
        lock.lock()
        defer { lock.unlock() }
        return status
    }

    func markGuarded() {
        setStatus(.guarded)
        refreshHeartbeat()
    }

    func markRestoring() {
        setStatus(.restoring)
    }

    func markInactive() {
        setStatus(.inactive)
        try? FileManager.default.removeItem(atPath: heartbeatPath)
    }

    func refreshHeartbeat() {
        let payload = "\(Date().timeIntervalSince1970)\n"
        try? payload.write(toFile: heartbeatPath, atomically: true, encoding: .utf8)
    }

    func startCommand(originallyEnabled: Bool) -> String {
        let heartbeat = shellQuote(heartbeatPath)
        let restoreDirection = originallyEnabled ? "up" : "down"
        return """
        /bin/mkdir -p /tmp || true; \
        /usr/bin/touch \(heartbeat) || true; \
        /bin/chmod 666 \(heartbeat) || true; \
        /sbin/ifconfig awdl0 down >/dev/null 2>&1 || true; \
        /bin/sh -c 'HEARTBEAT="$1"; RESTORE="$2"; while /bin/sleep 15; do if [ ! -f "$HEARTBEAT" ]; then break; fi; NOW=$(/bin/date +%s); MOD=$(/usr/bin/stat -f %m "$HEARTBEAT" 2>/dev/null || /bin/echo 0); AGE=$((NOW - MOD)); if [ "$AGE" -gt 45 ]; then break; fi; done; if [ "$RESTORE" = "up" ]; then /sbin/ifconfig awdl0 up >/dev/null 2>&1 || true; else /sbin/ifconfig awdl0 down >/dev/null 2>&1 || true; fi; /bin/rm -f "$HEARTBEAT" >/dev/null 2>&1 || true' cloudboost-awdl-guard \(heartbeat) \(shellQuote(restoreDirection)) >/dev/null 2>&1 &
        """
    }

    func restoreCommand(originallyEnabled: Bool) -> String {
        let heartbeat = shellQuote(heartbeatPath)
        let restore = originallyEnabled ? "/sbin/ifconfig awdl0 up" : "/sbin/ifconfig awdl0 down"
        return "/bin/rm -f \(heartbeat) >/dev/null 2>&1 || true; \(restore) >/dev/null 2>&1 || true"
    }

    private func setStatus(_ status: AWDLGuardStatus) {
        lock.lock()
        self.status = status
        lock.unlock()
    }

    private func shellQuote(_ value: String) -> String {
        "'\(value.replacingOccurrences(of: "'", with: "'\\''" ))'"
    }
}
