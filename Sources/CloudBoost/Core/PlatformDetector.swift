import AppKit

struct PlatformDetector {
    static func detectActivePlatform() -> CloudPlatform? {
        let running = NSWorkspace.shared.runningApplications
        let bundleIds = Set(running.compactMap { $0.bundleIdentifier })
        let names = Set(running.compactMap { $0.localizedName })

        if bundleIds.contains("com.nvidia.gfnpc.mac") || names.contains("NVIDIA GeForce NOW") {
            return .geforceNow
        }
        if bundleIds.contains("com.boosteroid.mac.client") || names.contains("Boosteroid") {
            return .boosteroid
        }
        if bundleIds.contains("com.moonlight-stream.Moonlight") || names.contains("Moonlight") {
            return .moonlight
        }
        if names.contains("VoidLink") || names.contains("VoidLink Extreme") {
            return .voidlink
        }

        return nil
    }
}
