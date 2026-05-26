import AppKit

/// Domain type representing a supported cloud gaming platform.
/// Centralises all platform-specific metadata in one place so UI and
/// business-logic layers never have to duplicate switch statements.
enum CloudPlatform: String, CaseIterable {
    case geforceNow = "GeForce NOW"
    case boosteroid = "Boosteroid"
    case xcloud     = "Xbox Cloud Gaming"
    case moonlight  = "Moonlight"
    case voidlink   = "VoidLink Extreme"

    // MARK: - Display

    var shortName: String {
        switch self {
        case .geforceNow: return "GFN"
        case .boosteroid: return "BST"
        case .xcloud:     return "XCL"
        case .moonlight:  return "MOON"
        case .voidlink:   return "VOID"
        }
    }

    var iconSymbol: String {
        switch self {
        case .geforceNow: return "cloud.fill"
        case .boosteroid: return "speedometer"
        case .xcloud:     return "gamecontroller"
        case .moonlight:  return "moon.stars.fill"
        case .voidlink:   return "bolt.horizontal.circle.fill"
        }
    }

    // MARK: - URLs & Bundle IDs

    /// App bundle ID (nil for browser-only platforms).
    var appBundleId: String? {
        switch self {
        case .geforceNow: return "com.nvidia.gfnpc.mac"
        case .boosteroid: return "com.boosteroid.mac.client"
        case .moonlight:  return "com.moonlight-stream.Moonlight"
        case .xcloud, .voidlink: return nil
        }
    }

    var webURL: URL? {
        switch self {
        case .geforceNow: return URL(string: "https://play.geforcenow.com/")
        case .boosteroid: return URL(string: "https://cloud.boosteroid.com/")
        case .xcloud:     return URL(string: "https://www.xbox.com/play")
        case .moonlight:  return nil
        case .voidlink:   return URL(string: "https://voidlink.app")
        }
    }

    // MARK: - Process targeting

    /// Process names used by `renice` and pid-lookup.
    var processNames: [String] {
        switch self {
        case .geforceNow: return ["NVIDIA GeForce NOW"]
        case .boosteroid:
            let useBrowser = UserDefaults.standard.bool(forKey: "BoosteroidUseBrowser")
            return useBrowser ? [CloudPlatform.systemBrowserName()] : ["Boosteroid"]
        case .xcloud:    return [CloudPlatform.systemBrowserName()]
        case .moonlight: return ["Moonlight"]
        case .voidlink:  return ["VoidLink", "VoidLink Extreme"]
        }
    }

    /// Bundle ID to open when triggering the platform launch.
    var openBundleId: String? {
        switch self {
        case .geforceNow: return appBundleId
        case .boosteroid:
            let useBrowser = UserDefaults.standard.bool(forKey: "BoosteroidUseBrowser")
            return useBrowser ? CloudPlatform.systemBrowserBundleId() : appBundleId
        case .xcloud:    return CloudPlatform.systemBrowserBundleId()
        case .moonlight: return appBundleId
        case .voidlink:  return nil
        }
    }

    // MARK: - Browser helpers

    static func systemBrowserName() -> String {
        guard let url = URL(string: "https://"),
              let browserURL = NSWorkspace.shared.urlForApplication(toOpen: url) else {
            return "Safari"
        }
        return browserURL.lastPathComponent.replacingOccurrences(of: ".app", with: "")
    }

    static func systemBrowserBundleId() -> String? {
        guard let url = URL(string: "https://"),
              let browserURL = NSWorkspace.shared.urlForApplication(toOpen: url),
              let bundle = Bundle(url: browserURL) else { return nil }
        return bundle.bundleIdentifier
    }
}
