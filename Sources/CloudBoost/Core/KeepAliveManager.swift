import AppKit

final class KeepAliveManager {
    static let shared = KeepAliveManager()

    private let queue = DispatchQueue(label: "cloudboost.keepalive")
    private var timer: DispatchSourceTimer?
    private var intervalSeconds: TimeInterval = 0

    private init() {}

    func start(intervalSeconds: TimeInterval) {
        guard intervalSeconds > 0 else {
            stop()
            return
        }

        if timer != nil, abs(self.intervalSeconds - intervalSeconds) < 0.1 {
            return
        }

        stop()
        self.intervalSeconds = intervalSeconds

        let timer = DispatchSource.makeTimerSource(queue: queue)
        timer.schedule(deadline: .now() + intervalSeconds, repeating: intervalSeconds)
        timer.setEventHandler { [weak self] in
            self?.wiggleMouse()
        }
        timer.resume()
        self.timer = timer
    }

    func stop() {
        timer?.cancel()
        timer = nil
    }

    private func wiggleMouse() {
        let currentLocation = DispatchQueue.main.sync { NSEvent.mouseLocation }
        let nudgedLocation = CGPoint(x: currentLocation.x + 1, y: currentLocation.y + 1)
        postMouseMove(to: nudgedLocation)
        postMouseMove(to: currentLocation)
    }

    private func postMouseMove(to point: CGPoint) {
        guard let event = CGEvent(
            mouseEventSource: nil,
            mouseType: .mouseMoved,
            mouseCursorPosition: point,
            mouseButton: .left
        ) else { return }
        event.post(tap: .cghidEventTap)
    }
}
