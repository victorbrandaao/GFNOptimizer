import Foundation

enum MouseProfile: Double {
    case rawFPS     = 0.0   // 0.0 disables acceleration; -1.0 is undefined on some macOS versions
    case fastMOBA   = 2.5
    case defaultMac = 1.5
    
    var title: String {
        switch self {
        case .rawFPS: return "Mouse: FPS (Raw Input)"
        case .fastMOBA: return "Mouse: MOBA (Fast)"
        case .defaultMac: return "Mouse: Default"
        }
    }
}

struct MouseManager {
    static func apply(profile: MouseProfile) {
        let process = Process()
        process.launchPath = "/bin/sh"
        process.arguments = ["-c", "defaults write .GlobalPreferences com.apple.mouse.scaling \(profile.rawValue)"]
        process.launch()
    }
}