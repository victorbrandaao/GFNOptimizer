import Foundation

struct SystemState: Codable {
    let awdlEnabled: Bool
    let timeMachineEnabled: Bool
    let mouseScaling: String
    let timestamp: Date
}
