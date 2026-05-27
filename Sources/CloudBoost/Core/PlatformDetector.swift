import AppKit

struct PlatformDetector {

    /// Returns the first cloud gaming platform whose native app is running.
    ///
    /// - Note: **xCloud** runs inside the system browser, so it cannot be
    ///   distinguished from normal browsing. Auto-detection for xCloud is
    ///   intentionally omitted — users must select it manually.
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
