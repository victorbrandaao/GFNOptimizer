import Foundation

enum NetworkInterfaceKind: String {
    case wifi = "Wi-Fi"
    case wired = "Ethernet"
    case cellular = "Cellular"
    case loopback = "Loopback"
    case other = "Other"
    case unavailable = "Offline"
}

struct NetworkPathSnapshot {
    let status: String
    let interface: NetworkInterfaceKind
    let isExpensive: Bool
    let isConstrained: Bool
}

struct LatencySnapshot {
    let averageMilliseconds: Double?
    let jitterMilliseconds: Double?
    let packetLossPercent: Double?

    var displayLatency: String {
        guard let averageMilliseconds else { return "--" }
        return "\(Int(averageMilliseconds.rounded()))ms"
    }

    var displayJitter: String {
        guard let jitterMilliseconds else { return "--" }
        return "j\(Int(jitterMilliseconds.rounded()))"
    }
}

struct SystemHealthSnapshot {
    let thermalState: ProcessInfo.ThermalState
    let lowPowerModeEnabled: Bool
    let interferingProcesses: [String]

    var thermalLabel: String {
        switch thermalState {
        case .nominal: return "nominal"
        case .fair: return "warm"
        case .serious: return "hot"
        case .critical: return "critical"
        @unknown default: return "unknown"
        }
    }
}

struct SessionMetrics {
    let networkPath: NetworkPathSnapshot
    let latency: LatencySnapshot
    let system: SystemHealthSnapshot
}
