import Foundation

enum MouseProfile: Double {
    case rawFPS     = 0.0   // 0.0 disables acceleration; -1.0 is undefined on some macOS versions
    case fastMOBA   = 2.5
    case defaultMac = 1.5

    var title: String {
        switch self {
        case .rawFPS:     return "Mouse: FPS (Raw Input)"
        case .fastMOBA:   return "Mouse: MOBA (Fast)"
        case .defaultMac: return "Mouse: Default"
        }
    }
}

struct MouseManager {
    /// Applies a mouse acceleration profile via `defaults write -g`.
    /// Blocks until the write completes to guarantee ordering with subsequent calls.
    static func apply(profile: MouseProfile) {
        let process = Process()
        process.launchPath = "/bin/sh"
        process.arguments  = ["-c", "defaults write -g com.apple.mouse.scaling \(profile.rawValue)"]
        process.standardOutput = FileHandle.nullDevice
        process.standardError  = FileHandle.nullDevice
        process.launch()
        process.waitUntilExit()
        if process.terminationStatus != 0 {
            DiagnosticsManager.shared.log("MouseManager: defaults write failed (exit \(process.terminationStatus))")
        }
    }
}