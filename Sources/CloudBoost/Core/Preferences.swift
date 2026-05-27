import Foundation

enum PresetName: String, CaseIterable {
    case competitive = "Competitive"
    case balanced = "Balanced"
    case streamQuality = "Stream Quality"

    var isPro: Bool {
        switch self {
        case .competitive, .streamQuality: return true
        case .balanced: return false
        }
    }
}

struct PerformancePreset {
    let name: PresetName
    let disableAwdl: Bool
    let flushDns: Bool
    let disableTimeMachine: Bool
    let purgeMemory: Bool
    let keepAwake: Bool
}

struct Preferences {
    private static let defaults = UserDefaults.standard

    private enum Keys {
        static let autoDetectEnabled = "AutoDetectEnabled"
        static let notificationsEnabled = "NotificationsEnabled"
        static let hudEnabled = "HudEnabled"
        static let keepAliveEnabled = "KeepAliveEnabled"
        static let keepAliveIntervalMinutes = "KeepAliveIntervalMinutes"
        static let selectedPreset = "SelectedPreset"
        static let allowlist = "ProcessAllowlist"
        static let blocklist = "ProcessBlocklist"
        static let lastSnapshot = "LastSystemSnapshot"
        static let lastBoostActive = "LastBoostActive"
    }

    static var autoDetectEnabled: Bool {
        get { defaults.object(forKey: Keys.autoDetectEnabled) as? Bool ?? true }
        set { defaults.set(newValue, forKey: Keys.autoDetectEnabled) }
    }

    static var notificationsEnabled: Bool {
        get { defaults.object(forKey: Keys.notificationsEnabled) as? Bool ?? true }
        set { defaults.set(newValue, forKey: Keys.notificationsEnabled) }
    }

    static var hudEnabled: Bool {
        get { defaults.object(forKey: Keys.hudEnabled) as? Bool ?? false }
        set { defaults.set(newValue, forKey: Keys.hudEnabled) }
    }

    static var keepAliveEnabled: Bool {
        get { defaults.object(forKey: Keys.keepAliveEnabled) as? Bool ?? false }
        set { defaults.set(newValue, forKey: Keys.keepAliveEnabled) }
    }

    static var keepAliveIntervalMinutes: Int {
        get { defaults.object(forKey: Keys.keepAliveIntervalMinutes) as? Int ?? 4 }
        set { defaults.set(newValue, forKey: Keys.keepAliveIntervalMinutes) }
    }

    static var selectedPreset: PresetName {
        get {
            if let raw = defaults.string(forKey: Keys.selectedPreset),
               let preset = PresetName(rawValue: raw) {
                return preset
            }
            return .balanced
        }
        set { defaults.set(newValue.rawValue, forKey: Keys.selectedPreset) }
    }

    static var allowlist: [String] {
        get { defaults.stringArray(forKey: Keys.allowlist) ?? [] }
        set { defaults.set(newValue, forKey: Keys.allowlist) }
    }

    static var blocklist: [String] {
        get { defaults.stringArray(forKey: Keys.blocklist) ?? [] }
        set { defaults.set(newValue, forKey: Keys.blocklist) }
    }

    static var lastSnapshot: Data? {
        get { defaults.data(forKey: Keys.lastSnapshot) }
        set { defaults.set(newValue, forKey: Keys.lastSnapshot) }
    }

    static var lastBoostActive: Bool {
        get { defaults.object(forKey: Keys.lastBoostActive) as? Bool ?? false }
        set { defaults.set(newValue, forKey: Keys.lastBoostActive) }
    }

    static func presetConfig() -> PerformancePreset {
        switch selectedPreset {
        case .competitive:
            // Max performance: every tweak enabled.
            return PerformancePreset(name: .competitive,
                                    disableAwdl: true, flushDns: true,
                                    disableTimeMachine: true, purgeMemory: true,
                                    keepAwake: true)
        case .balanced:
            // Network-only: kills ping spikes without aggressive system changes.
            return PerformancePreset(name: .balanced,
                                    disableAwdl: true, flushDns: true,
                                    disableTimeMachine: false, purgeMemory: false,
                                    keepAwake: true)
        case .streamQuality:
            // Stream-stable: AWDL + DNS + no Time Machine I/O, but skips RAM
            // purge to avoid the memory-pressure spike that causes decoder hitches.
            return PerformancePreset(name: .streamQuality,
                                    disableAwdl: true, flushDns: true,
                                    disableTimeMachine: true, purgeMemory: false,
                                    keepAwake: true)
        }
    }
}
