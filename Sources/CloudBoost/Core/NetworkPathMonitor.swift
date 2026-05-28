import Foundation
import Network

final class NetworkPathMonitor {
    static let shared = NetworkPathMonitor()

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "com.cloudboost.network-path", qos: .utility)
    private let lock = NSLock()
    private var latest = NetworkPathSnapshot(status: "unknown",
                                             interface: .unavailable,
                                             isExpensive: false,
                                             isConstrained: false)
    private var started = false

    private init() {}

    func start() {
        lock.lock()
        defer { lock.unlock() }
        guard !started else { return }
        started = true

        monitor.pathUpdateHandler = { [weak self] path in
            let snapshot = NetworkPathSnapshot(status: Self.statusLabel(path.status),
                                               interface: Self.interfaceKind(for: path),
                                               isExpensive: path.isExpensive,
                                               isConstrained: path.isConstrained)
            self?.lock.lock()
            self?.latest = snapshot
            self?.lock.unlock()
        }
        monitor.start(queue: queue)
    }

    func snapshot() -> NetworkPathSnapshot {
        lock.lock()
        defer { lock.unlock() }
        return latest
    }

    private static func statusLabel(_ status: NWPath.Status) -> String {
        switch status {
        case .satisfied: return "online"
        case .unsatisfied: return "offline"
        case .requiresConnection: return "requires connection"
        @unknown default: return "unknown"
        }
    }

    private static func interfaceKind(for path: NWPath) -> NetworkInterfaceKind {
        if path.usesInterfaceType(.wifi) { return .wifi }
        if path.usesInterfaceType(.wiredEthernet) { return .wired }
        if path.usesInterfaceType(.cellular) { return .cellular }
        if path.usesInterfaceType(.loopback) { return .loopback }
        if path.status != .satisfied { return .unavailable }
        return .other
    }
}
