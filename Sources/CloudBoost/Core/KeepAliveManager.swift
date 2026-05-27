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

    /// Nudges the cursor by 1px and back to prevent idle sleep.
    /// Converts from AppKit's bottom-left coordinate system to
    /// Core Graphics' top-left system used by CGEvent.
    private func wiggleMouse() {
        let nsPoint = DispatchQueue.main.sync { NSEvent.mouseLocation }

        // Convert from AppKit (origin bottom-left) to CG (origin top-left).
        guard let screenHeight = DispatchQueue.main.sync(execute: { NSScreen.main?.frame.height }) else { return }
        let cgPoint = CGPoint(x: nsPoint.x, y: screenHeight - nsPoint.y)
        let nudged  = CGPoint(x: cgPoint.x + 1, y: cgPoint.y + 1)

        postMouseMove(to: nudged)
        postMouseMove(to: cgPoint)
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
