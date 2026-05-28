import Foundation

public enum CloudBoostSelfTest {
    public static func run() -> Int32 {
        Thread.sleep(forTimeInterval: 0.5)

        let metrics = SystemObservabilityManager.shared.sample()
        let assessment = OptimizationEngine.shared.assess(metrics: metrics)

        print("CloudBoost Self-Test")
        print("Network path: \(metrics.networkPath.status)")
        print("Interface: \(metrics.networkPath.interface.rawValue)")
        print("Constrained: \(metrics.networkPath.isConstrained)")
        print("Expensive: \(metrics.networkPath.isExpensive)")
        print("Latency: \(metrics.latency.displayLatency)")
        print("Jitter: \(metrics.latency.displayJitter)")
        print("Packet loss: \(formatPercent(metrics.latency.packetLossPercent))")
        print("Thermal: \(metrics.system.thermalLabel)")
        print("Low Power Mode: \(metrics.system.lowPowerModeEnabled)")
        print("Interference: \(metrics.system.interferingProcesses.isEmpty ? "none" : metrics.system.interferingProcesses.joined(separator: ", "))")
        print("AWDL Guard: \(AWDLGuard.shared.currentStatus.rawValue)")
        print("Assessment: \(assessment.summary)")

        if !assessment.recommendations.isEmpty {
            print("Recommendations:")
            for recommendation in assessment.recommendations {
                print("- \(recommendation)")
            }
        }

        return 0
    }

    private static func formatPercent(_ value: Double?) -> String {
        guard let value else { return "--" }
        if value.rounded() == value {
            return "\(Int(value))%"
        }
        return String(format: "%.1f%%", value)
    }
}
