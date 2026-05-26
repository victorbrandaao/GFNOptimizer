import AppKit

/// Manages the NSPopover lifecycle for the CloudBoost menu bar item.
/// Shows the popover on left-click and closes it when the user clicks outside.
final class PopoverController: NSObject, NSPopoverDelegate {
    let viewController: PopoverViewController
    private let popover:    NSPopover
    private let statusItem: NSStatusItem
    private var clickMonitor: Any?

    init(statusItem: NSStatusItem) {
        self.statusItem     = statusItem
        self.viewController = PopoverViewController()

        popover                        = NSPopover()
        popover.contentViewController  = viewController
        popover.behavior               = .applicationDefined   // Manual control for reliability
        popover.animates               = true

        super.init()
        popover.delegate = self

        // Force dark appearance so the popover looks consistent regardless of
        // the user's system appearance setting.
        popover.appearance = NSAppearance(named: .darkAqua)

        if let button = statusItem.button {
            let cfg   = NSImage.SymbolConfiguration(pointSize: 14, weight: .medium)
            let image = NSImage(systemSymbolName: "cloud.fill",
                                accessibilityDescription: "CloudBoost")?
                               .withSymbolConfiguration(cfg)
            image?.isTemplate = true
            button.image  = image
            button.target = self
            button.action = #selector(togglePopover(_:))
        }
    }

    // MARK: - Toggle

    @objc func togglePopover(_ sender: NSButton) {
        if popover.isShown {
            close()
        } else {
            popover.show(relativeTo: sender.bounds, of: sender, preferredEdge: .minY)
        }
    }

    func close() {
        popover.performClose(nil)
    }

    // MARK: - Status-item icon updates

    func setBoostActive(_ active: Bool) {
        guard let button = statusItem.button else { return }
        let sym = active ? "bolt.fill" : "cloud.fill"
        let cfg = NSImage.SymbolConfiguration(pointSize: 14, weight: .medium)
        let img = NSImage(systemSymbolName: sym, accessibilityDescription: "CloudBoost")?
                         .withSymbolConfiguration(cfg)
        img?.isTemplate = true
        button.image = img
    }

    // MARK: - Outside-click monitor

    func popoverWillShow(_ notification: Notification) {
        clickMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.leftMouseDown, .rightMouseDown]
        ) { [weak self] _ in
            self?.close()
        }
    }

    func popoverDidClose(_ notification: Notification) {
        if let monitor = clickMonitor {
            NSEvent.removeMonitor(monitor)
            clickMonitor = nil
        }
    }
}
