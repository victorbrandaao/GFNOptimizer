import Foundation

enum SessionHealth: String {
    case optimal = "Optimal"
    case watch = "Watch"
    case degraded = "Degraded"
    case critical = "Critical"
}

struct OptimizationAssessment {
    let health: SessionHealth
    let summary: String
    let recommendations: [String]
}

final class OptimizationEngine {
    static let shared = OptimizationEngine()

    private let lock = NSLock()
    private var lastSummary: String?
    private var lastRecommendations: [String] = []

    private init() {}

    var diagnosticsSummary: String {
        lock.lock()
        defer { lock.unlock() }
        if let lastSummary {
            let recs = lastRecommendations.isEmpty ? "none" : lastRecommendations.joined(separator: "; ")
            return "\(lastSummary) | recommendations: \(recs)"
        }
        return "No active session metrics yet"
    }

    func assess(metrics: SessionMetrics) -> OptimizationAssessment {
        var score = 0
        var recommendations: [String] = []

        if metrics.networkPath.status != "online" {
            score += 4
            recommendations.append("Network path is offline or unstable")
        }

        if metrics.networkPath.interface == .wifi {
            recommendations.append("Wi-Fi path active")
        } else if metrics.networkPath.interface == .wired {
            score -= 1
        }

        if metrics.networkPath.isConstrained {
            score += 2
            recommendations.append("Low data mode is constraining the path")
        }

        if metrics.networkPath.isExpensive {
            score += 1
            recommendations.append("Network path is marked expensive")
        }

        if let jitter = metrics.latency.jitterMilliseconds, jitter >= 20 {
            score += 3
            recommendations.append("High jitter detected")
        } else if let jitter = metrics.latency.jitterMilliseconds, jitter >= 10 {
            score += 1
            recommendations.append("Moderate jitter detected")
        }

        if let loss = metrics.latency.packetLossPercent, loss > 0 {
            score += loss >= 10 ? 4 : 2
            recommendations.append("Packet loss detected")
        }

        switch metrics.system.thermalState {
        case .serious:
            score += 2
            recommendations.append("Thermal pressure is serious")
        case .critical:
            score += 4
            recommendations.append("Thermal pressure is critical")
        default:
            break
        }

        if metrics.system.lowPowerModeEnabled {
            score += 1
            recommendations.append("Low Power Mode is enabled")
        }

        if !metrics.system.interferingProcesses.isEmpty {
            score += min(metrics.system.interferingProcesses.count, 3)
            recommendations.append("Background interference: \(metrics.system.interferingProcesses.joined(separator: ", "))")
        }

        let health: SessionHealth
        if score >= 7 {
            health = .critical
        } else if score >= 4 {
            health = .degraded
        } else if score >= 2 {
            health = .watch
        } else {
            health = .optimal
        }

        let summary = "\(health.rawValue) · \(metrics.networkPath.interface.rawValue) · \(metrics.latency.displayLatency) \(metrics.latency.displayJitter) · thermal \(metrics.system.thermalLabel)"
        lock.lock()
        let shouldLog = summary != lastSummary
        lastSummary = summary
        lastRecommendations = recommendations
        lock.unlock()

        if shouldLog {
            DiagnosticsManager.shared.log("Session Intelligence: \(summary)")
        }

        return OptimizationAssessment(health: health,
                                      summary: summary,
                                      recommendations: recommendations)
    }
}
