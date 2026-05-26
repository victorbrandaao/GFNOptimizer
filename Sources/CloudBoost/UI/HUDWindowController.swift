import AppKit

final class HUDWindowController: NSWindowController {
    private let statusLabel = NSTextField(labelWithString: "CloudBoost HUD")
    private let detailsLabel = NSTextField(labelWithString: "")
    private var timer: Timer?

    override init(window: NSWindow?) {
        let panel = NSPanel(contentRect: NSRect(x: 0, y: 0, width: 360, height: 160),
                            styleMask: [.titled, .utilityWindow, .nonactivatingPanel],
                            backing: .buffered,
                            defer: false)
        panel.title = "CloudBoost HUD"
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        super.init(window: panel)

        let contentView = NSView(frame: panel.contentRect(forFrameRect: panel.frame))
        panel.contentView = contentView

        statusLabel.frame = NSRect(x: 16, y: 110, width: 328, height: 20)
        detailsLabel.frame = NSRect(x: 16, y: 20, width: 328, height: 80)
        detailsLabel.maximumNumberOfLines = 4

        contentView.addSubview(statusLabel)
        contentView.addSubview(detailsLabel)
    }

    required init?(coder: NSCoder) {
        return nil
    }

    func startUpdating(statusProvider: @escaping () -> (String, String)) {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
            let result = statusProvider()
            self.statusLabel.stringValue = result.0
            self.detailsLabel.stringValue = result.1
        }
        let result = statusProvider()
        statusLabel.stringValue = result.0
        detailsLabel.stringValue = result.1
    }

    func stopUpdating() {
        timer?.invalidate()
        timer = nil
    }
}
