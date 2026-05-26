import AppKit

final class HUDWindowController: NSWindowController {
    private let statusLabel = NSTextField(labelWithString: "CloudBoost HUD")
    private var timer: Timer?

    override init(window: NSWindow?) {
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 320, height: 20),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.isFloatingPanel = true
        panel.level = .statusBar
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.ignoresMouseEvents = true
        super.init(window: panel)

        let contentView = NSView(frame: panel.contentRect(forFrameRect: panel.frame))
        panel.contentView = contentView

        statusLabel.frame = NSRect(x: 6, y: 3, width: 308, height: 14)
        statusLabel.font = NSFont.monospacedDigitSystemFont(ofSize: 10, weight: .regular)
        statusLabel.textColor = .white
        statusLabel.lineBreakMode = .byTruncatingTail
        let shadow = NSShadow()
        shadow.shadowColor = NSColor.black.withAlphaComponent(0.5)
        shadow.shadowBlurRadius = 1.5
        shadow.shadowOffset = NSSize(width: 0, height: -1)
        statusLabel.shadow = shadow
        contentView.addSubview(statusLabel)

        positionPanel(panel)
    }

    required init?(coder: NSCoder) {
        return nil
    }

    func startUpdating(interval: TimeInterval = 2.0, statusProvider: @escaping () -> String) {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
            self.statusLabel.stringValue = statusProvider()
        }
        statusLabel.stringValue = statusProvider()
    }

    func stopUpdating() {
        timer?.invalidate()
        timer = nil
    }

    private func positionPanel(_ panel: NSPanel) {
        guard let screenFrame = NSScreen.main?.visibleFrame else { return }
        let x = screenFrame.maxX - panel.frame.width - 16
        let y = screenFrame.maxY - panel.frame.height - 16
        panel.setFrameOrigin(NSPoint(x: x, y: y))
    }

    deinit {
        stopUpdating()
    }
}
