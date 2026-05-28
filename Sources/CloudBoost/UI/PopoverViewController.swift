import AppKit

// MARK: - PopoverViewController

/// Rich popover UI for the CloudBoost menu bar item.
/// All business logic lives in AppDelegate; this view only holds callbacks and state display.
final class PopoverViewController: NSViewController {

    // MARK: - Nested: gradient boost button

    private final class GradientButton: NSButton {
        private let gradientLayer = CAGradientLayer()
        private var pulseLayer: CAGradientLayer?

        var isActiveState: Bool = false { didSet { refreshAppearance() } }
        var isLoadingState: Bool = false {
            didSet { isEnabled = !isLoadingState; refreshAppearance() }
        }

        override init(frame: NSRect) { super.init(frame: frame); setup() }
        required init?(coder: NSCoder) { super.init(coder: coder); setup() }

        private func setup() {
            isBordered = false
            wantsLayer = true
            layer?.cornerRadius  = 9
            layer?.masksToBounds = true
            gradientLayer.startPoint = CGPoint(x: 0, y: 0.5)
            gradientLayer.endPoint   = CGPoint(x: 1, y: 0.5)
            layer?.insertSublayer(gradientLayer, at: 0)
            setAccessibilityLabel("Toggle CloudBoost")
            refreshAppearance()
        }

        override func layout() {
            super.layout()
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            gradientLayer.frame = bounds
            pulseLayer?.frame = bounds
            CATransaction.commit()
        }

        private func refreshAppearance() {
            let start, end: NSColor
            if isLoadingState {
                start = NSColor(white: 0.28, alpha: 1)
                end   = NSColor(white: 0.22, alpha: 1)
            } else if isActiveState {
                start = NSColor(calibratedRed: 0.88, green: 0.14, blue: 0.19, alpha: 1)
                end   = NSColor(calibratedRed: 0.65, green: 0.08, blue: 0.13, alpha: 1)
            } else {
                start = NSColor(calibratedRed: 0.08, green: 0.68, blue: 0.45, alpha: 1)
                end   = NSColor(calibratedRed: 0.05, green: 0.48, blue: 0.82, alpha: 1)
            }
            gradientLayer.colors = [start.cgColor, end.cgColor]

            let label: String
            if isLoadingState      { label = "Applying..." }
            else if isActiveState  { label = "Disable CloudBoost" }
            else                   { label = "Enable CloudBoost" }

            attributedTitle = NSAttributedString(string: label, attributes: [
                .foregroundColor: NSColor.white.withAlphaComponent(isLoadingState ? 0.5 : 1.0),
                .font: NSFont.systemFont(ofSize: 13, weight: .semibold)
            ])

            if isActiveState, !isLoadingState {
                startPulse()
            } else {
                stopPulse()
            }
        }

        private func startPulse() {
            guard pulseLayer == nil else { return }
            let p = CAGradientLayer()
            p.startPoint = CGPoint(x: 0, y: 0.5)
            p.endPoint   = CGPoint(x: 1, y: 0.5)
            p.colors = [
                NSColor(calibratedRed: 1.0, green: 0.3, blue: 0.3, alpha: 0.25).cgColor,
                NSColor(calibratedRed: 0.8, green: 0.15, blue: 0.2, alpha: 0.15).cgColor
            ]
            p.frame = bounds
            p.opacity = 0
            layer?.addSublayer(p)
            pulseLayer = p

            let anim = CABasicAnimation(keyPath: "opacity")
            anim.fromValue   = 0.0
            anim.toValue     = 1.0
            anim.duration    = 1.4
            anim.autoreverses = true
            anim.repeatCount = .infinity
            anim.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            p.add(anim, forKey: "pulse")
        }

        private func stopPulse() {
            pulseLayer?.removeAllAnimations()
            pulseLayer?.removeFromSuperlayer()
            pulseLayer = nil
        }
    }

    // MARK: - Nested: HoverButton

    private final class HoverButton: NSButton {
        private var trackingArea: NSTrackingArea?
        var normalBgColor: NSColor? { didSet { layer?.backgroundColor = normalBgColor?.cgColor } }
        var hoverBgColor: NSColor?
        var isLockedState: Bool = false

        override func updateTrackingAreas() {
            super.updateTrackingAreas()
            if let ta = trackingArea { removeTrackingArea(ta) }
            let options: NSTrackingArea.Options = [.activeAlways, .mouseEnteredAndExited]
            trackingArea = NSTrackingArea(rect: bounds, options: options, owner: self, userInfo: nil)
            addTrackingArea(trackingArea!)
        }

        override func mouseEntered(with event: NSEvent) {
            super.mouseEntered(with: event)
            guard isEnabled, !isLockedState, let h = hoverBgColor else { return }
            NSAnimationContext.runAnimationGroup { ctx in
                ctx.duration = 0.12
                self.animator().layer?.backgroundColor = h.cgColor
            }
        }

        override func mouseExited(with event: NSEvent) {
            super.mouseExited(with: event)
            guard let n = normalBgColor else { return }
            NSAnimationContext.runAnimationGroup { ctx in
                ctx.duration = 0.18
                self.animator().layer?.backgroundColor = n.cgColor
            }
        }
    }

    // MARK: - Color palette

    private enum Palette {
        static let green        = NSColor(calibratedRed: 0.16, green: 0.84, blue: 0.54, alpha: 1.0)
        static let card         = NSColor(calibratedRed: 0.12, green: 0.13, blue: 0.16, alpha: 1.0)
        static let cardHover    = NSColor(calibratedRed: 0.16, green: 0.17, blue: 0.21, alpha: 1.0)
        static let cardSelected = NSColor(calibratedRed: 0.05, green: 0.28, blue: 0.34, alpha: 0.72)
        static let separator    = NSColor(calibratedRed: 1.0, green: 1.0, blue: 1.0, alpha: 0.08)
        static let muted        = NSColor(calibratedRed: 0.50, green: 0.50, blue: 0.56, alpha: 1.0)
        static let textSecondary = NSColor(calibratedRed: 0.68, green: 0.68, blue: 0.72, alpha: 1.0)
        static let blue         = NSColor(calibratedRed: 0.35, green: 0.60, blue: 1.00, alpha: 1.0)
        static let amber        = NSColor(calibratedRed: 0.95, green: 0.70, blue: 0.22, alpha: 1.0)
        static let red          = NSColor(calibratedRed: 0.95, green: 0.26, blue: 0.32, alpha: 1.0)
        static let bg           = NSColor(calibratedRed: 0.10, green: 0.10, blue: 0.12, alpha: 1.0)
        static let panel        = NSColor(calibratedRed: 0.09, green: 0.10, blue: 0.13, alpha: 0.95)
    }

    // MARK: - State

    private var isBoosterActive  = false
    private var selectedPlatform: CloudPlatform = .geforceNow
    private var cachedVersion: String?

    // MARK: - Callbacks (set by AppDelegate)

    var onToggleBoost:        (() -> Void)?
    var onPlatformChanged:    ((CloudPlatform) -> Void)?
    var onPresetChanged:      ((PresetName) -> Void)?
    var onToggleAutoDetect:   (() -> Void)?
    var onToggleHUD:          (() -> Void)?
    var onToggleNotifications:(() -> Void)?
    var onToggleKeepAlive:    (() -> Void)?
    var onToggleAdaptiveIntelligence: (() -> Void)?
    var onExportDiagnostics:  (() -> Void)?
    var onCheckUpdates:       (() -> Void)?
    var onQuit:               (() -> Void)?
    var onOpenPlatform:       (() -> Void)?

    // MARK: - UI references

    private var headerIconView:    NSImageView!
    private var statusPillView:    NSView!
    private var statusPillLabel:   NSTextField!
    private var planPillLabel:     NSTextField!
    private var cpuStat:           NSTextField!
    private var pingStat:          NSTextField!
    private var niceStat:          NSTextField!
    private var pathStat:          NSTextField!
    private var jitterStat:        NSTextField!
    private var healthStat:        NSTextField!
    private var awdlStat:          NSTextField!
    private var boostButton:       GradientButton!
    private var platformButtons:   [CloudPlatform: NSButton] = [:]
    private var presetButtons:     [PresetName: HoverButton] = [:]
    private var autoDetectSwitch:  NSSwitch!
    private var hudSwitch:         NSSwitch!
    private var notifSwitch:       NSSwitch!
    private var keepAliveSwitch:   NSSwitch!
    private var adaptiveSwitch:    NSSwitch!

    private var autoDetectLabel:   NSTextField?
    private var keepAliveLabel:    NSTextField?
    private var adaptiveLabel:     NSTextField?

    // MARK: - Lifecycle

    override func loadView() {
        let root = NSVisualEffectView(frame: NSRect(x: 0, y: 0, width: 340, height: 656))
        root.material     = .hudWindow
        root.blendingMode = .behindWindow
        root.state        = .active
        view = root

        let stack = NSStackView()
        stack.orientation = .vertical
        stack.spacing     = 0
        stack.alignment   = .centerX
        stack.translatesAutoresizingMaskIntoConstraints = false
        root.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: root.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: root.trailingAnchor),
            stack.topAnchor.constraint(equalTo: root.topAnchor),
            stack.bottomAnchor.constraint(equalTo: root.bottomAnchor)
        ])

        stack.addArrangedSubview(buildHeader())
        stack.addArrangedSubview(buildTelemetryPanel())
        stack.addArrangedSubview(buildBoostSection())
        stack.addArrangedSubview(buildPlatformSection())
        stack.addArrangedSubview(buildPresetSection())
        stack.addArrangedSubview(buildSettingsSection())
        stack.addArrangedSubview(buildFooter())

        preferredContentSize = NSSize(width: 340, height: 656)
    }

    override func viewWillAppear() {
        super.viewWillAppear()
        syncSwitches()
        refreshAll()

        NotificationCenter.default.addObserver(self, selector: #selector(refreshAll), name: .proStatusChanged, object: nil)
    }

    override func viewDidDisappear() {
        super.viewDidDisappear()
        NotificationCenter.default.removeObserver(self, name: .proStatusChanged, object: nil)
    }

    // MARK: - Section builders

    private func buildHeader() -> NSView {
        let container = fixedHeight(64)
        container.widthAnchor.constraint(equalToConstant: 340).isActive = true

        let iconConfig = NSImage.SymbolConfiguration(pointSize: 18, weight: .semibold)
        let iconView   = NSImageView()
        iconView.image = NSImage(systemSymbolName: "cloud.fill",
                                 accessibilityDescription: "CloudBoost")?
                                .withSymbolConfiguration(iconConfig)
        iconView.contentTintColor = .white
        iconView.translatesAutoresizingMaskIntoConstraints = false
        headerIconView = iconView

        let appLabel = label("CloudBoost", size: 14, weight: .bold, color: .white)
        let verLabel = label("v\(resolveVersion())", size: 10, weight: .medium, color: Palette.muted)
        let titleStack = NSStackView(views: [appLabel, verLabel])
        titleStack.orientation = .vertical
        titleStack.spacing     = 2
        titleStack.alignment   = .leading
        titleStack.translatesAutoresizingMaskIntoConstraints = false

        // Status pill
        let pill = NSView()
        pill.wantsLayer              = true
        pill.layer?.cornerRadius     = 10
        pill.layer?.backgroundColor  = Palette.card.cgColor
        pill.translatesAutoresizingMaskIntoConstraints = false
        statusPillView = pill

        let pillText = label("OFFLINE", size: 9, weight: .bold, color: Palette.muted)
        pillText.alignment = .center
        pillText.translatesAutoresizingMaskIntoConstraints = false
        statusPillLabel = pillText
        pill.addSubview(pillText)

        let planPill = NSView()
        planPill.wantsLayer = true
        planPill.layer?.cornerRadius = 9
        planPill.layer?.backgroundColor = Palette.card.cgColor
        planPill.translatesAutoresizingMaskIntoConstraints = false

        let planText = label(ProManager.shared.isProUnlocked ? "PRO" : "FREE", size: 8, weight: .bold, color: ProManager.shared.isProUnlocked ? Palette.green : Palette.muted)
        planText.alignment = .center
        planText.translatesAutoresizingMaskIntoConstraints = false
        planPillLabel = planText
        planPill.addSubview(planText)

        NSLayoutConstraint.activate([
            pillText.centerXAnchor.constraint(equalTo: pill.centerXAnchor),
            pillText.centerYAnchor.constraint(equalTo: pill.centerYAnchor),
            pill.heightAnchor.constraint(equalToConstant: 22),
            pill.widthAnchor.constraint(greaterThanOrEqualToConstant: 80),
            pillText.leadingAnchor.constraint(equalTo: pill.leadingAnchor, constant: 10),
            pillText.trailingAnchor.constraint(equalTo: pill.trailingAnchor, constant: -10),

            planText.centerXAnchor.constraint(equalTo: planPill.centerXAnchor),
            planText.centerYAnchor.constraint(equalTo: planPill.centerYAnchor),
            planPill.heightAnchor.constraint(equalToConstant: 20),
            planPill.widthAnchor.constraint(equalToConstant: 46),
        ])

        container.addSubview(iconView)
        container.addSubview(titleStack)
        container.addSubview(pill)
        container.addSubview(planPill)

        NSLayoutConstraint.activate([
            iconView.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            iconView.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 22),

            titleStack.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 10),
            titleStack.centerYAnchor.constraint(equalTo: container.centerYAnchor),

            pill.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            pill.topAnchor.constraint(equalTo: container.topAnchor, constant: 12),

            planPill.trailingAnchor.constraint(equalTo: pill.trailingAnchor),
            planPill.topAnchor.constraint(equalTo: pill.bottomAnchor, constant: 5),
        ])

        return container
    }

    private func buildPlatformSection() -> NSView {
        let outer = vstack(insets: NSEdgeInsets(top: 10, left: 16, bottom: 8, right: 16), spacing: 8)

        outer.addArrangedSubview(sectionLabel("PLATFORM"))

        let row = NSStackView()
        row.orientation  = .horizontal
        row.distribution = .fillEqually
        row.spacing      = 6
        row.translatesAutoresizingMaskIntoConstraints = false
        row.widthAnchor.constraint(equalToConstant: 308).isActive = true

        for platform in CloudPlatform.allCases {
            let btn = makePlatformCard(platform)
            platformButtons[platform] = btn
            row.addArrangedSubview(btn)
        }
        outer.addArrangedSubview(row)

        let openBtn = NSButton()
        openBtn.isBordered = false
        openBtn.target     = self
        openBtn.action     = #selector(openPlatformClicked)
        openBtn.attributedTitle = NSAttributedString(
            string: "↗  Open selected platform",
            attributes: [.foregroundColor: Palette.blue,
                         .font: NSFont.systemFont(ofSize: 11, weight: .medium)]
        )
        openBtn.setAccessibilityLabel("Open selected platform in browser or app")
        
        let centerWrapper = NSStackView(views: [openBtn])
        centerWrapper.alignment = .centerX
        outer.addArrangedSubview(centerWrapper)

        return outer
    }

    private func makePlatformCard(_ platform: CloudPlatform) -> NSButton {
        let btn = HoverButton(frame: .zero)
        btn.isBordered = false
        btn.wantsLayer = true
        btn.layer?.cornerRadius    = 8

        btn.normalBgColor = Palette.card
        btn.hoverBgColor  = Palette.cardHover

        let cfg = NSImage.SymbolConfiguration(pointSize: 14, weight: .medium)
        if let img = NSImage(systemSymbolName: platform.iconSymbol,
                             accessibilityDescription: nil)?
                             .withSymbolConfiguration(cfg) {
            btn.image         = img
            btn.imagePosition = .imageAbove
        }
        btn.attributedTitle = NSAttributedString(
            string: platform.shortName,
            attributes: [.foregroundColor: Palette.textSecondary,
                         .font: NSFont.systemFont(ofSize: 9, weight: .semibold)]
        )
        btn.contentTintColor = NSColor(white: 0.72, alpha: 1)
        btn.identifier       = NSUserInterfaceItemIdentifier(platform.rawValue)
        btn.target           = self
        btn.action           = #selector(platformCardClicked(_:))
        btn.heightAnchor.constraint(equalToConstant: 58).isActive = true
        btn.setAccessibilityLabel("Select \(platform.rawValue)")
        return btn
    }

    private func buildTelemetryPanel() -> NSView {
        let outer = vstack(insets: NSEdgeInsets(top: 8, left: 16, bottom: 8, right: 16), spacing: 8)

        let panel = NSView()
        panel.wantsLayer = true
        panel.layer?.cornerRadius = 10
        panel.layer?.backgroundColor = Palette.panel.cgColor
        panel.translatesAutoresizingMaskIntoConstraints = false
        panel.widthAnchor.constraint(equalToConstant: 308).isActive = true

        let title = label("Session Monitor", size: 11, weight: .bold, color: .white)
        title.alignment = .left
        title.translatesAutoresizingMaskIntoConstraints = false

        let detail = label("Realtime system and network signal", size: 9, weight: .medium, color: Palette.muted)
        detail.alignment = .left
        detail.translatesAutoresizingMaskIntoConstraints = false

        cpuStat = statLabel("--")
        pingStat = statLabel("--")
        niceStat = statLabel("--")
        pathStat = statLabel("--")
        jitterStat = statLabel("--")
        healthStat = statLabel("--")
        awdlStat = statLabel("Inactive")

        let topRow = NSStackView()
        topRow.orientation = .horizontal
        topRow.distribution = .fillEqually
        topRow.spacing = 6
        topRow.translatesAutoresizingMaskIntoConstraints = false

        let bottomRow = NSStackView()
        bottomRow.orientation = .horizontal
        bottomRow.distribution = .fillEqually
        bottomRow.spacing = 6
        bottomRow.translatesAutoresizingMaskIntoConstraints = false

        let topMetrics: [(String, NSTextField)] = [("CPU", cpuStat), ("PING", pingStat), ("NICE", niceStat)]
        for item in topMetrics {
            topRow.addArrangedSubview(compactMetric(title: item.0, value: item.1))
        }

        let bottomMetrics: [(String, NSTextField)] = [("PATH", pathStat), ("JITTER", jitterStat), ("HEALTH", healthStat), ("AWDL", awdlStat)]
        for item in bottomMetrics {
            bottomRow.addArrangedSubview(compactMetric(title: item.0, value: item.1))
        }

        panel.addSubview(title)
        panel.addSubview(detail)
        panel.addSubview(topRow)
        panel.addSubview(bottomRow)

        NSLayoutConstraint.activate([
            title.leadingAnchor.constraint(equalTo: panel.leadingAnchor, constant: 12),
            title.topAnchor.constraint(equalTo: panel.topAnchor, constant: 10),
            detail.leadingAnchor.constraint(equalTo: title.leadingAnchor),
            detail.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 2),

            topRow.leadingAnchor.constraint(equalTo: panel.leadingAnchor, constant: 10),
            topRow.trailingAnchor.constraint(equalTo: panel.trailingAnchor, constant: -10),
            topRow.topAnchor.constraint(equalTo: detail.bottomAnchor, constant: 10),

            bottomRow.leadingAnchor.constraint(equalTo: topRow.leadingAnchor),
            bottomRow.trailingAnchor.constraint(equalTo: topRow.trailingAnchor),
            bottomRow.topAnchor.constraint(equalTo: topRow.bottomAnchor, constant: 6),
            bottomRow.bottomAnchor.constraint(equalTo: panel.bottomAnchor, constant: -10)
        ])

        outer.addArrangedSubview(panel)
        return outer
    }

    private func compactMetric(title: String, value: NSTextField) -> NSView {
        let container = NSView()
        container.wantsLayer = true
        container.layer?.cornerRadius = 7
        container.layer?.backgroundColor = Palette.card.cgColor
        container.translatesAutoresizingMaskIntoConstraints = false
        container.heightAnchor.constraint(equalToConstant: 40).isActive = true

        let titleLabel = label(title, size: 8, weight: .bold, color: Palette.muted)
        titleLabel.alignment = .center
        value.alignment = .center
        value.font = .monospacedDigitSystemFont(ofSize: 10, weight: .bold)
        value.lineBreakMode = .byTruncatingTail

        let stack = NSStackView(views: [titleLabel, value])
        stack.orientation = .vertical
        stack.spacing = 2
        stack.alignment = .centerX
        stack.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 4),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -4),
            stack.centerYAnchor.constraint(equalTo: container.centerYAnchor)
        ])

        return container
    }

    private func buildStatsRow() -> NSView {
        let row = NSStackView()
        row.orientation  = .horizontal
        row.distribution = .fillEqually
        row.spacing      = 6
        row.edgeInsets   = NSEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
        row.translatesAutoresizingMaskIntoConstraints = false
        row.widthAnchor.constraint(equalToConstant: 320).isActive = true

        cpuStat  = statLabel("—")
        pingStat = statLabel("—")
        niceStat = statLabel("—")

        let configs: [(NSTextField, String, String)] = [
            (cpuStat,  "cpu",          "CPU"),
            (pingStat, "bolt.fill",    "PING"),
            (niceStat, "dial.low",     "NICE"),
        ]

        for (stat, icon, title) in configs {
            let card = NSView()
            card.wantsLayer = true
            card.layer?.cornerRadius    = 8
            card.layer?.backgroundColor = Palette.card.cgColor
            card.translatesAutoresizingMaskIntoConstraints = false
            card.heightAnchor.constraint(equalToConstant: 36).isActive = true

            // Icon
            let iconCfg = NSImage.SymbolConfiguration(pointSize: 9, weight: .medium)
            let iconView = NSImageView()
            iconView.image = NSImage(systemSymbolName: icon, accessibilityDescription: nil)?
                                    .withSymbolConfiguration(iconCfg)
            iconView.contentTintColor = Palette.muted
            iconView.translatesAutoresizingMaskIntoConstraints = false

            // Title
            let titleLabel = label(title, size: 8, weight: .bold, color: Palette.muted)
            titleLabel.alignment = .center
            titleLabel.translatesAutoresizingMaskIntoConstraints = false

            // Value
            stat.alignment = .center
            stat.translatesAutoresizingMaskIntoConstraints = false

            let innerStack = NSStackView(views: [titleLabel, stat])
            innerStack.orientation = .horizontal
            innerStack.spacing = 4
            innerStack.alignment = .centerY
            innerStack.translatesAutoresizingMaskIntoConstraints = false

            card.addSubview(iconView)
            card.addSubview(innerStack)
            
            NSLayoutConstraint.activate([
                iconView.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 10),
                iconView.centerYAnchor.constraint(equalTo: card.centerYAnchor),
                innerStack.centerXAnchor.constraint(equalTo: card.centerXAnchor, constant: 8),
                innerStack.centerYAnchor.constraint(equalTo: card.centerYAnchor)
            ])

            stat.setAccessibilityLabel("\(title) statistic")
            row.addArrangedSubview(card)
        }
        return row
    }

    private func buildSessionSection() -> NSView {
        let outer = vstack(insets: NSEdgeInsets(top: 8, left: 16, bottom: 8, right: 16), spacing: 6)
        outer.addArrangedSubview(sectionLabel("SESSION"))

        pathStat = statLabel("--")
        jitterStat = statLabel("--")
        healthStat = statLabel("--")
        awdlStat = statLabel("Off")

        let row = NSStackView()
        row.orientation = .horizontal
        row.distribution = .fillEqually
        row.spacing = 6
        row.translatesAutoresizingMaskIntoConstraints = false
        row.widthAnchor.constraint(equalToConstant: 288).isActive = true

        let metrics: [(String, NSTextField)] = [
            ("PATH", pathStat),
            ("JITTER", jitterStat),
            ("HEALTH", healthStat),
            ("AWDL", awdlStat),
        ]

        for (title, value) in metrics {
            row.addArrangedSubview(sessionMetric(title: title, value: value))
        }

        outer.addArrangedSubview(row)
        return outer
    }

    private func sessionMetric(title: String, value: NSTextField) -> NSView {
        let card = NSView()
        card.wantsLayer = true
        card.layer?.cornerRadius = 8
        card.layer?.backgroundColor = Palette.card.cgColor
        card.translatesAutoresizingMaskIntoConstraints = false
        card.heightAnchor.constraint(equalToConstant: 42).isActive = true

        let titleLabel = label(title, size: 8, weight: .bold, color: Palette.muted)
        titleLabel.alignment = .center
        value.alignment = .center
        value.font = .systemFont(ofSize: 10, weight: .bold)
        value.lineBreakMode = .byTruncatingTail

        let stack = NSStackView(views: [titleLabel, value])
        stack.orientation = .vertical
        stack.spacing = 2
        stack.alignment = .centerX
        stack.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 4),
            stack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -4),
            stack.centerYAnchor.constraint(equalTo: card.centerYAnchor)
        ])

        return card
    }

    private func buildBoostSection() -> NSView {
        let container = fixedHeight(58)
        container.widthAnchor.constraint(equalToConstant: 340).isActive = true
        boostButton = GradientButton(frame: .zero)
        boostButton.translatesAutoresizingMaskIntoConstraints = false
        boostButton.target = self
        boostButton.action = #selector(boostClicked)
        container.addSubview(boostButton)
        NSLayoutConstraint.activate([
            boostButton.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            boostButton.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            boostButton.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            boostButton.heightAnchor.constraint(equalToConstant: 42),
        ])
        return container
    }

    private func buildPresetSection() -> NSView {
        let outer = vstack(insets: NSEdgeInsets(top: 10, left: 16, bottom: 10, right: 16), spacing: 8)
        outer.addArrangedSubview(sectionLabel("PRESET"))

        let row = NSStackView()
        row.orientation  = .horizontal
        row.distribution = .fillEqually
        row.spacing      = 6
        row.translatesAutoresizingMaskIntoConstraints = false
        row.widthAnchor.constraint(equalToConstant: 308).isActive = true

        let isPro = ProManager.shared.isProUnlocked
        for preset in PresetName.allCases {
            let btn = makePresetPill(preset, isPro: isPro)
            presetButtons[preset] = btn
            row.addArrangedSubview(btn)
        }

        outer.addArrangedSubview(row)
        return outer
    }

    private func makePresetPill(_ preset: PresetName, isPro: Bool) -> HoverButton {
        let btn = HoverButton(frame: .zero)
        btn.isBordered = false
        btn.wantsLayer = true
        btn.layer?.cornerRadius = 7

        btn.normalBgColor = Palette.card
        btn.hoverBgColor  = Palette.cardHover

        let isLocked = preset.isPro && !isPro
        var title = preset.rawValue
        if isLocked { title += " 🔒" }

        btn.attributedTitle = NSAttributedString(
            string: title,
            attributes: [
                .foregroundColor: Palette.textSecondary,
                .font: NSFont.systemFont(ofSize: 11, weight: .medium)
            ]
        )
        btn.heightAnchor.constraint(equalToConstant: 28).isActive = true
        btn.target = self
        btn.action = #selector(presetPillClicked(_:))
        btn.identifier = NSUserInterfaceItemIdentifier(preset.rawValue)
        btn.setAccessibilityLabel("Preset: \(preset.rawValue)")
        return btn
    }

    private func buildSettingsSection() -> NSView {
        autoDetectSwitch = makeSwitch(Preferences.autoDetectEnabled, action: #selector(autoDetectToggled))
        hudSwitch        = makeSwitch(Preferences.hudEnabled,        action: #selector(hudToggled))
        notifSwitch      = makeSwitch(Preferences.notificationsEnabled, action: #selector(notifToggled))
        keepAliveSwitch  = makeSwitch(Preferences.keepAliveEnabled,  action: #selector(keepAliveToggled))
        adaptiveSwitch   = makeSwitch(Preferences.adaptiveIntelligenceEnabled, action: #selector(adaptiveToggled))

        let outer = vstack(insets: NSEdgeInsets(top: 8, left: 16, bottom: 8, right: 16), spacing: 6)
        outer.addArrangedSubview(sectionLabel("SETTINGS"))

        let card = NSView()
        card.wantsLayer = true
        card.layer?.cornerRadius    = 10
        card.layer?.backgroundColor = Palette.card.cgColor
        card.translatesAutoresizingMaskIntoConstraints = false
        card.widthAnchor.constraint(equalToConstant: 308).isActive = true

        let isPro = ProManager.shared.isProUnlocked
        let rows: [(String, String, NSSwitch)] = [
            ("Auto-detect Platform" + (isPro ? "" : " 🔒"), "wand.and.stars",  autoDetectSwitch),
            ("Adaptive Intelligence" + (isPro ? "" : " 🔒"), "sparkles", adaptiveSwitch),
            ("HUD Overlay",          "gauge.open.with.lines.needle.33percent", hudSwitch),
            ("Notifications",        "bell.badge",       notifSwitch),
            ("Keep Alive" + (isPro ? "" : " 🔒"),           "timer",            keepAliveSwitch),
        ]

        let cardStack = NSStackView()
        cardStack.orientation = .vertical
        cardStack.spacing     = 0
        cardStack.alignment   = .centerX
        cardStack.translatesAutoresizingMaskIntoConstraints = false

        var rowIndex = 0
        for (title, icon, toggle) in rows {
            let rowView = toggleRow(title: title, icon: icon, toggle: toggle)

            if rowIndex == 0 { autoDetectLabel = rowView.label }
            if rowIndex == 1 { adaptiveLabel = rowView.label }
            if rowIndex == 4 { keepAliveLabel = rowView.label }

            cardStack.addArrangedSubview(rowView.view)

            if rowIndex < rows.count - 1 {
                let sep = NSView()
                sep.wantsLayer = true
                sep.layer?.backgroundColor = Palette.separator.cgColor
                sep.translatesAutoresizingMaskIntoConstraints = false
                sep.heightAnchor.constraint(equalToConstant: 1).isActive = true
                sep.widthAnchor.constraint(equalToConstant: 284).isActive = true
                cardStack.addArrangedSubview(sep)
            }
            rowIndex += 1
        }

        card.addSubview(cardStack)
        NSLayoutConstraint.activate([
            cardStack.topAnchor.constraint(equalTo: card.topAnchor, constant: 4),
            cardStack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -4),
            cardStack.centerXAnchor.constraint(equalTo: card.centerXAnchor)
        ])

        outer.addArrangedSubview(card)
        return outer
    }

    private func toggleRow(title: String, icon: String, toggle: NSSwitch) -> (view: NSView, label: NSTextField) {
        let row = NSStackView()
        row.orientation = .horizontal
        row.spacing     = 8
        row.alignment   = .centerY
        row.edgeInsets  = NSEdgeInsets(top: 0, left: 12, bottom: 0, right: 12)
        row.translatesAutoresizingMaskIntoConstraints = false
        row.heightAnchor.constraint(equalToConstant: 32).isActive = true
        row.widthAnchor.constraint(equalToConstant: 308).isActive = true

        let iconCfg = NSImage.SymbolConfiguration(pointSize: 11, weight: .medium)
        let iconImg = NSImageView()
        iconImg.image = NSImage(systemSymbolName: icon, accessibilityDescription: nil)?
                                .withSymbolConfiguration(iconCfg)
        iconImg.contentTintColor = Palette.muted
        iconImg.translatesAutoresizingMaskIntoConstraints = false
        iconImg.widthAnchor.constraint(equalToConstant: 16).isActive = true

        let lbl    = label(title, size: 12, weight: .regular, color: .white)
        let spacer = NSView()
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)

        toggle.controlSize = .small
        toggle.setAccessibilityLabel(title)

        row.addArrangedSubview(iconImg)
        row.addArrangedSubview(lbl)
        row.addArrangedSubview(spacer)
        row.addArrangedSubview(toggle)
        return (row, lbl)
    }

    private func buildFooter() -> NSView {
        let row = NSStackView()
        row.orientation  = .horizontal
        row.distribution = .fillEqually
        row.spacing      = 6
        row.edgeInsets   = NSEdgeInsets(top: 8, left: 16, bottom: 12, right: 16)
        row.translatesAutoresizingMaskIntoConstraints = false
        row.widthAnchor.constraint(equalToConstant: 340).isActive = true

        let isPro = ProManager.shared.isProUnlocked
        var items: [(String, String, Selector)] = [
            ("Update",  "arrow.down.circle",  #selector(updateClicked)),
            ("Quit",    "power",              #selector(quitClicked)),
        ]
        
        if !isPro {
            items.insert(("Buy PRO", "star.fill", #selector(buyLicense)), at: 0)
        } else {
            items.insert(("Log", "doc.text", #selector(exportClicked)), at: 0)
        }
        
        for (title, icon, action) in items {
            row.addArrangedSubview(footerButton(title: title, icon: icon, action: action))
        }
        return row
    }

    private func footerButton(title: String, icon: String, action: Selector) -> NSButton {
        let btn = HoverButton()
        btn.isBordered = false
        btn.wantsLayer = true
        btn.layer?.cornerRadius    = 8
        btn.normalBgColor = Palette.card
        btn.hoverBgColor  = Palette.cardHover
        btn.target = self
        btn.action = action

        let cfg = NSImage.SymbolConfiguration(pointSize: 13, weight: .regular)
        btn.image         = NSImage(systemSymbolName: icon, accessibilityDescription: nil)?
                                    .withSymbolConfiguration(cfg)
        btn.imagePosition = .imageAbove
        btn.contentTintColor = Palette.muted
        btn.attributedTitle  = NSAttributedString(
            string: title,
            attributes: [.foregroundColor: Palette.muted,
                         .font: NSFont.systemFont(ofSize: 10, weight: .medium)]
        )
        btn.heightAnchor.constraint(equalToConstant: 48).isActive = true
        btn.setAccessibilityLabel(title)
        return btn
    }

    // MARK: - Actions

    @objc private func platformCardClicked(_ sender: NSButton) {
        guard let id = sender.identifier,
              let platform = CloudPlatform(rawValue: id.rawValue) else { return }

        if platform.isPro && !showProPrompt(featureName: platform.rawValue) {
            return
        }

        selectedPlatform = platform
        refreshPlatformCards()
        onPlatformChanged?(platform)
    }

    @objc private func boostClicked()        { onToggleBoost?() }
    @objc private func openPlatformClicked() { onOpenPlatform?() }
    @objc private func exportClicked()       { onExportDiagnostics?() }
    @objc private func updateClicked()       { onCheckUpdates?() }
    @objc private func quitClicked()         { onQuit?() }

    @objc private func presetPillClicked(_ sender: NSButton) {
        guard let id = sender.identifier,
              let preset = PresetName(rawValue: id.rawValue) else { return }
        if preset.isPro && !showProPrompt(featureName: preset.rawValue) {
            return
        }
        onPresetChanged?(preset)
    }

    @objc private func autoDetectToggled() {
        if autoDetectSwitch.state == .on && !showProPrompt(featureName: "Auto-Detect") {
            autoDetectSwitch.state = .off
            return
        }
        onToggleAutoDetect?()
    }

    @objc private func hudToggled()        { onToggleHUD?() }
    @objc private func notifToggled()      { onToggleNotifications?() }

    @objc private func adaptiveToggled() {
        if adaptiveSwitch.state == .on && !showProPrompt(featureName: "Adaptive Intelligence") {
            adaptiveSwitch.state = .off
            return
        }
        onToggleAdaptiveIntelligence?()
    }

    @objc private func keepAliveToggled()  {
        if keepAliveSwitch.state == .on && !showProPrompt(featureName: "Keep Alive") {
            keepAliveSwitch.state = .off
            return
        }
        onToggleKeepAlive?()
    }

    // MARK: - License UI

    private var licenseOverlay: NSView?
    private var licenseTextField: NSTextField?
    private var licenseErrorLabel: NSTextField?

    private func showProPrompt(featureName: String) -> Bool {
        if ProManager.shared.isProUnlocked { return true }

        if !Thread.isMainThread {
            DispatchQueue.main.async { _ = self.showProPrompt(featureName: featureName) }
            return false
        }

        DiagnosticsManager.shared.log("showProPrompt: \(featureName)")

        let alert = NSAlert()
        alert.messageText = "Unlock CloudBoost PRO"
        alert.informativeText = "'\(featureName)' is a PRO feature.\nPurchase a license to unlock Auto-Detect,\nAdaptive Intelligence, Extreme Presets, and additional platforms."
        alert.alertStyle = .informational

        let tf = NSTextField(string: "")
        tf.placeholderString = "Paste License Key here..."
        tf.frame = NSRect(x: 0, y: 0, width: 280, height: 24)
        alert.accessoryView = tf

        alert.addButton(withTitle: "Unlock")
        alert.addButton(withTitle: "Buy License")
        alert.addButton(withTitle: "Cancel")

        let handleResponse: (NSApplication.ModalResponse) -> Void = { [weak self] response in
            guard let self else { return }
            if response == .alertFirstButtonReturn {
                let key = tf.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
                if !key.isEmpty { self.performUnlock(key: key) }
            } else if response == .alertSecondButtonReturn {
                self.buyLicense()
            }
        }

        if let window = view.window {
            alert.beginSheetModal(for: window, completionHandler: handleResponse)
        } else {
            let response = alert.runModal()
            handleResponse(response)
        }

        return false
    }

    @objc private func performUnlock() {
        guard let key = licenseTextField?.stringValue.trimmingCharacters(in: .whitespacesAndNewlines), !key.isEmpty else { return }

        licenseTextField?.isEnabled = false
        licenseErrorLabel?.isHidden = true

        DiagnosticsManager.shared.log("performUnlock invoked")
        performUnlock(key: key)
    }

    private func performUnlock(key: String) {
        ProManager.shared.validateLicense(key: key) { [weak self] success, errorMsg in
            guard let self = self else { return }

            DispatchQueue.main.async {
                let alert = NSAlert()
                alert.messageText = success ? "Unlocked" : "License Error"
                alert.informativeText = success ? "CloudBoost PRO is now unlocked." : (errorMsg ?? "Invalid License Key.")
                alert.alertStyle = success ? .informational : .warning
                alert.addButton(withTitle: "OK")

                if let window = self.view.window {
                    alert.beginSheetModal(for: window, completionHandler: nil)
                } else {
                    alert.runModal()
                }

                if success {
                    self.dismissOverlay()
                    self.refreshAll()
                }
            }
        }
    }

    @objc private func buyLicense() {
        if let url = URL(string: "https://victorbrandao0.gumroad.com/l/CloudBoost") {
            NSWorkspace.shared.open(url)
        }
    }

    @objc private func dismissOverlay() {
        guard let overlay = licenseOverlay else { return }
        DiagnosticsManager.shared.log("dismissOverlay invoked")
        NSAnimationContext.runAnimationGroup({ ctx in
            ctx.duration = 0.2
            overlay.animator().alphaValue = 0
        }, completionHandler: {
            overlay.removeFromSuperview()
            self.licenseOverlay = nil
            self.licenseTextField = nil
        })
    }

    // MARK: - Public update API

    func updateState(isBoosterActive: Bool, selectedPlatform: CloudPlatform) {
        self.isBoosterActive  = isBoosterActive
        self.selectedPlatform = selectedPlatform
        refreshBoostButton()
        refreshPlatformCards()
        refreshStatusPill()
        refreshHeaderIcon()
    }

    func updateStats(cpu: String, ping: String, nice: String) {
        cpuStat?.stringValue  = "\(cpu)%"
        pingStat?.stringValue = "\(ping)"
        niceStat?.stringValue = "\(nice)"
    }

    func updateSession(path: String, jitter: String, health: String, awdl: String) {
        pathStat?.stringValue = path
        jitterStat?.stringValue = jitter
        healthStat?.stringValue = health
        awdlStat?.stringValue = awdl

        switch health {
        case "Optimal", "Active":
            healthStat?.textColor = Palette.green
        case "Watch":
            healthStat?.textColor = Palette.amber
        case "Degraded", "Critical":
            healthStat?.textColor = Palette.red
        default:
            healthStat?.textColor = .white
        }

        jitterStat?.textColor = jitter == "PRO" ? Palette.amber : .white
        pathStat?.textColor = path == "Basic" ? Palette.textSecondary : .white
        awdlStat?.textColor = awdl == AWDLGuardStatus.guarded.rawValue ? Palette.green : Palette.muted
    }

    func updatePreset(_ preset: PresetName) {
        for (p, btn) in presetButtons {
            btn.normalBgColor = (p == preset) ? Palette.cardSelected : Palette.card
        }
    }

    func setLoading(_ loading: Bool) {
        boostButton?.isLoadingState = loading
    }

    @objc private func refreshAll() {
        refreshPlatformCards()
        refreshPresetCards()
        refreshSettingsLabels()
    }

    private func refreshBoostButton() {
        boostButton?.isActiveState  = isBoosterActive
        boostButton?.isLoadingState = false
    }

    private func refreshPlatformCards() {
        let isPro = ProManager.shared.isProUnlocked
        for (platform, btn) in platformButtons {
            let sel = platform == selectedPlatform

            let isLocked = platform.isPro && !isPro
            let hoverBtn = btn as! HoverButton
            hoverBtn.isLockedState = isLocked

            var title = platform.shortName
            if isLocked { title += " 🔒" }

            hoverBtn.normalBgColor = sel ? Palette.cardSelected : Palette.card

            btn.layer?.borderWidth     = sel ? 1.5 : 0
            btn.layer?.borderColor     = sel ? Palette.green.cgColor : nil
            btn.contentTintColor       = sel ? Palette.green : NSColor(white: 0.72, alpha: 1)
            btn.alphaValue             = isLocked ? 0.4 : 1.0
            btn.attributedTitle        = NSAttributedString(
                string: title,
                attributes: [
                    .foregroundColor: sel ? Palette.green : Palette.textSecondary,
                    .font: NSFont.systemFont(ofSize: 9, weight: sel ? .semibold : .medium)
                ]
            )
        }
    }

    private func refreshPresetCards() {
        let isPro = ProManager.shared.isProUnlocked
        let current = Preferences.selectedPreset
        for (preset, btn) in presetButtons {
            let sel = preset == current
            let isLocked = preset.isPro && !isPro

            var title = preset.rawValue
            if isLocked { title += " 🔒" }

            btn.normalBgColor = sel ? Palette.cardSelected : Palette.card

            btn.layer?.borderWidth = sel ? 1.5 : 0
            btn.layer?.borderColor = sel ? Palette.blue.cgColor : nil
            btn.alphaValue         = isLocked ? 0.5 : 1.0
            btn.attributedTitle    = NSAttributedString(
                string: title,
                attributes: [
                    .foregroundColor: sel ? Palette.blue : Palette.textSecondary,
                    .font: NSFont.systemFont(ofSize: 11, weight: sel ? .semibold : .medium)
                ]
            )
        }
    }

    private func refreshSettingsLabels() {
        let isPro = ProManager.shared.isProUnlocked
        autoDetectLabel?.stringValue = isPro ? "Auto-detect Platform" : "Auto-detect Platform 🔒"
        adaptiveLabel?.stringValue = isPro ? "Adaptive Intelligence" : "Adaptive Intelligence 🔒"
        keepAliveLabel?.stringValue = isPro ? "Keep Alive" : "Keep Alive 🔒"
        planPillLabel?.stringValue = isPro ? "PRO" : "FREE"
        planPillLabel?.textColor = isPro ? Palette.green : Palette.muted
    }

    private func refreshStatusPill() {
        if isBoosterActive {
            statusPillLabel?.textColor           = Palette.green
            statusPillLabel?.stringValue         = "● ACTIVE"
            statusPillView?.layer?.backgroundColor =
                NSColor(calibratedRed: 0.0, green: 0.6, blue: 0.35, alpha: 0.18).cgColor
        } else {
            statusPillLabel?.textColor           = Palette.muted
            statusPillLabel?.stringValue         = "OFFLINE"
            statusPillView?.layer?.backgroundColor = Palette.card.cgColor
        }
    }

    private func refreshHeaderIcon() {
        let sym = isBoosterActive ? "bolt.fill" : "cloud.fill"
        let cfg = NSImage.SymbolConfiguration(pointSize: 18, weight: .semibold)
        headerIconView?.image = NSImage(systemSymbolName: sym,
                                        accessibilityDescription: nil)?
                                       .withSymbolConfiguration(cfg)
        headerIconView?.contentTintColor = isBoosterActive ? Palette.green : .white
    }

    private func syncSwitches() {
        autoDetectSwitch?.state = Preferences.autoDetectEnabled ? .on : .off
        adaptiveSwitch?.state   = (ProManager.shared.isProUnlocked && Preferences.adaptiveIntelligenceEnabled) ? .on : .off
        hudSwitch?.state        = Preferences.hudEnabled        ? .on : .off
        notifSwitch?.state      = Preferences.notificationsEnabled ? .on : .off
        keepAliveSwitch?.state  = Preferences.keepAliveEnabled  ? .on : .off
    }

    // MARK: - Factory helpers

    private func fixedHeight(_ h: CGFloat) -> NSView {
        let v = NSView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.heightAnchor.constraint(equalToConstant: h).isActive = true
        return v
    }

    private func hairline() -> NSView {
        let v = NSView()
        v.wantsLayer = true
        v.layer?.backgroundColor = Palette.separator.cgColor
        v.translatesAutoresizingMaskIntoConstraints = false
        v.heightAnchor.constraint(equalToConstant: 1).isActive = true
        v.widthAnchor.constraint(equalToConstant: 340).isActive = true
        return v
    }

    private func vstack(insets: NSEdgeInsets, spacing: CGFloat) -> NSStackView {
        let s = NSStackView()
        s.orientation = .vertical
        s.spacing     = spacing
        s.alignment   = .centerX
        s.edgeInsets  = insets
        s.translatesAutoresizingMaskIntoConstraints = false
        s.widthAnchor.constraint(equalToConstant: 340).isActive = true
        return s
    }

    private func label(_ text: String, size: CGFloat, weight: NSFont.Weight,
                        color: NSColor) -> NSTextField {
        let tf = NSTextField(labelWithString: text)
        tf.font      = .systemFont(ofSize: size, weight: weight)
        tf.textColor = color
        tf.alignment = .center
        return tf
    }

    private func sectionLabel(_ text: String) -> NSTextField {
        let tf = label(text, size: 10, weight: .bold, color: Palette.muted)
        tf.alignment = .center
        return tf
    }

    private func statLabel(_ text: String) -> NSTextField {
        let tf = label(text, size: 11, weight: .bold, color: .white)
        tf.alignment = .center
        return tf
    }

    private func makeSwitch(_ value: Bool, action: Selector) -> NSSwitch {
        let s = NSSwitch()
        s.state = value ? .on : .off
        s.target = self
        s.action = action
        return s
    }

    private func resolveVersion() -> String {
        if let v = cachedVersion { return v }
        let cwd = FileManager.default.currentDirectoryPath
        let candidates = [
            "/Applications/CloudBoost.app/Contents/Info.plist",
            (Bundle.main.bundlePath as NSString).appendingPathComponent("Contents/Info.plist"),
            "\(cwd)/CloudBoost/Info.plist",
            "\(cwd)/.release/CloudBoost.app/Contents/Info.plist",
            "\(cwd)/CloudBoost.app/Contents/Info.plist"
        ]

        for path in candidates {
            guard let data = try? Data(contentsOf: URL(fileURLWithPath: path)) else { continue }
            if let plist = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil),
               let dict = plist as? [String: Any],
               let v = dict["CFBundleShortVersionString"] as? String,
               !v.isEmpty {
                cachedVersion = v
                return v
            }
        }
        cachedVersion = "3.0.4"
        return "3.0.4"
    }
}
