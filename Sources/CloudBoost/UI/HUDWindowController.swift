import AppKit

/// Floating HUD panel shown as a pill in the top-right corner of the screen.
/// Uses NSVisualEffectView for a frosted-glass "hudWindow" look.
/// Automatically repositions when the user switches monitors or changes resolution.
final class HUDWindowController: NSWindowController {
    private let statusLabel = NSTextField(labelWithString: "CloudBoost")

    init() {
        let width: CGFloat  = 340
        let height: CGFloat = 26

        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: width, height: height),
            styleMask:   [.borderless, .nonactivatingPanel],
            backing:     .buffered,
            defer:       false
        )
        panel.isFloatingPanel    = true
        panel.level              = .statusBar
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.isOpaque           = false
        panel.backgroundColor    = .clear
        panel.hasShadow          = true
        panel.ignoresMouseEvents = true

        // Visual effect "pill" background
        let effect = NSVisualEffectView(frame: NSRect(x: 0, y: 0, width: width, height: height))
        effect.material      = .hudWindow
        effect.blendingMode  = .behindWindow
        effect.state         = .active
        effect.wantsLayer    = true
        effect.layer?.cornerRadius   = height / 2
        effect.layer?.masksToBounds  = true
        panel.contentView = effect

        // Monospaced label inside the pill
        statusLabel.frame         = NSRect(x: 14, y: 5, width: width - 28, height: 16)
        statusLabel.font          = NSFont.monospacedDigitSystemFont(ofSize: 10, weight: .medium)
        statusLabel.textColor     = .white
        statusLabel.lineBreakMode = .byTruncatingTail
        effect.addSubview(statusLabel)

        super.init(window: panel)

        positionPanel(panel)

        // Reposition when display configuration changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(repositionHUD),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
    }

    required init?(coder: NSCoder) { nil }

    // MARK: - Public API

    func update(text: String) {
        statusLabel.stringValue = text
    }

    // MARK: - Private

    @objc private func repositionHUD() {
        guard let panel = window as? NSPanel else { return }
        positionPanel(panel)
    }

    private func positionPanel(_ panel: NSPanel) {
        guard let screenFrame = NSScreen.main?.visibleFrame else { return }
        let x = screenFrame.maxX - panel.frame.width - 20
        let y = screenFrame.maxY - panel.frame.height - 20
        panel.setFrameOrigin(NSPoint(x: x, y: y))
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
