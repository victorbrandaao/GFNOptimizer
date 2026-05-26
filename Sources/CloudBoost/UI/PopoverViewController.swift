import AppKit

// MARK: - PopoverViewController

/// Rich popover UI for the CloudBoost menu bar item.
/// All business logic lives in AppDelegate; this view only holds callbacks and state display.
final class PopoverViewController: NSViewController {

    // MARK: - Nested: gradient boost button

    private final class GradientButton: NSButton {
        private let gradientLayer = CAGradientLayer()

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
            refreshAppearance()
        }

        override func layout() {
            super.layout()
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            gradientLayer.frame = bounds
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
                start = NSColor(calibratedRed: 0.00, green: 0.72, blue: 0.43, alpha: 1)
                end   = NSColor(calibratedRed: 0.00, green: 0.50, blue: 0.84, alpha: 1)
            }
            gradientLayer.colors = [start.cgColor, end.cgColor]

            let label: String
            if isLoadingState      { label = "Applying…" }
            else if isActiveState  { label = "✕  Disable CloudBoost" }
            else                   { label = "⚡  Enable CloudBoost" }

            attributedTitle = NSAttributedString(string: label, attributes: [
                .foregroundColor: NSColor.white.withAlphaComponent(isLoadingState ? 0.55 : 1.0),
                .font: NSFont.systemFont(ofSize: 13, weight: .semibold)
            ])
        }
    }

    // MARK: - Palette

    private enum Palette {
        static let green        = NSColor(calibratedRed: 0.00, green: 0.85, blue: 0.51, alpha: 1.0)
        static let card         = NSColor(calibratedRed: 0.17, green: 0.17, blue: 0.21, alpha: 1.0)
        static let cardSelected = NSColor(calibratedRed: 0.00, green: 0.43, blue: 0.85, alpha: 0.28)
        static let separator    = NSColor(calibratedRed: 0.22, green: 0.22, blue: 0.28, alpha: 1.0)
        static let muted        = NSColor(calibratedRed: 0.45, green: 0.45, blue: 0.52, alpha: 1.0)
        static let blue         = NSColor(calibratedRed: 0.25, green: 0.58, blue: 1.00, alpha: 1.0)
    }

    // MARK: - State

    private var isBoosterActive  = false
    private var selectedPlatform: CloudPlatform = .geforceNow

    // MARK: - Callbacks (set by AppDelegate)

    var onToggleBoost:        (() -> Void)?
    var onPlatformChanged:    ((CloudPlatform) -> Void)?
    var onPresetChanged:      ((PresetName) -> Void)?
    var onToggleAutoDetect:   (() -> Void)?
    var onToggleHUD:          (() -> Void)?
    var onToggleNotifications:(() -> Void)?
    var onToggleKeepAlive:    (() -> Void)?
    var onExportDiagnostics:  (() -> Void)?
    var onCheckUpdates:       (() -> Void)?
    var onQuit:               (() -> Void)?
    var onOpenPlatform:       (() -> Void)?

    // MARK: - UI references

    private var headerIconView:    NSImageView!
    private var statusPillView:    NSView!
    private var statusPillLabel:   NSTextField!
    private var cpuStat:           NSTextField!
    private var pingStat:          NSTextField!
    private var niceStat:          NSTextField!
    private var boostButton:       GradientButton!
    private var platformButtons:   [CloudPlatform: NSButton] = [:]
    private var presetControl:     NSSegmentedControl!
    private var autoDetectSwitch:  NSSwitch!
    private var hudSwitch:         NSSwitch!
    private var notifSwitch:       NSSwitch!
    private var keepAliveSwitch:   NSSwitch!

    // MARK: - Lifecycle

    override func loadView() {
        let root = NSVisualEffectView(frame: NSRect(x: 0, y: 0, width: 320, height: 548))
        root.material     = .hudWindow
        root.blendingMode = .behindWindow
        root.state        = .active
        view = root

        let stack = NSStackView()
        stack.orientation = .vertical
        stack.spacing     = 0
        stack.alignment   = .leading
        stack.translatesAutoresizingMaskIntoConstraints = false
        root.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: root.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: root.trailingAnchor),
            stack.topAnchor.constraint(equalTo: root.topAnchor),
        ])

        stack.addArrangedSubview(buildHeader())
        stack.addArrangedSubview(hairline())
        stack.addArrangedSubview(buildPlatformSection())
        stack.addArrangedSubview(hairline())
        stack.addArrangedSubview(buildStatsRow())
        stack.addArrangedSubview(hairline())
        stack.addArrangedSubview(buildBoostSection())
        stack.addArrangedSubview(hairline())
        stack.addArrangedSubview(buildPresetSection())
        stack.addArrangedSubview(hairline())
        stack.addArrangedSubview(buildSettingsSection())
        stack.addArrangedSubview(hairline())
        stack.addArrangedSubview(buildFooter())

        preferredContentSize = NSSize(width: 320, height: 548)
    }

    override func viewWillAppear() {
        super.viewWillAppear()
        syncSwitches()
    }

    // MARK: - Section builders

    private func buildHeader() -> NSView {
        let container = fixedHeight(56)

        let iconConfig = NSImage.SymbolConfiguration(pointSize: 18, weight: .semibold)
        let iconView   = NSImageView()
        iconView.image = NSImage(systemSymbolName: "cloud.fill",
                                 accessibilityDescription: nil)?
                                .withSymbolConfiguration(iconConfig)
        iconView.contentTintColor = .white
        iconView.translatesAutoresizingMaskIntoConstraints = false
        headerIconView = iconView

        let appLabel = label("CloudBoost", size: 14, weight: .bold, color: .white)
        let verLabel = label(appVersion(), size: 10, weight: .regular, color: Palette.muted)
        let titleStack = NSStackView(views: [appLabel, verLabel])
        titleStack.orientation = .vertical
        titleStack.spacing     = 1
        titleStack.alignment   = .leading
        titleStack.translatesAutoresizingMaskIntoConstraints = false

        // Status pill
        let pill = NSView()
        pill.wantsLayer              = true
        pill.layer?.cornerRadius     = 9
        pill.layer?.backgroundColor  = Palette.card.cgColor
        pill.translatesAutoresizingMaskIntoConstraints = false
        statusPillView = pill

        let pillText = label("OFFLINE", size: 10, weight: .bold, color: Palette.muted)
        pillText.translatesAutoresizingMaskIntoConstraints = false
        statusPillLabel = pillText
        pill.addSubview(pillText)

        NSLayoutConstraint.activate([
            pillText.centerXAnchor.constraint(equalTo: pill.centerXAnchor),
            pillText.centerYAnchor.constraint(equalTo: pill.centerYAnchor),
            pill.heightAnchor.constraint(equalToConstant: 22),
            pill.widthAnchor.constraint(greaterThanOrEqualToConstant: 78),
            pillText.leadingAnchor.constraint(equalTo: pill.leadingAnchor, constant: 9),
            pillText.trailingAnchor.constraint(equalTo: pill.trailingAnchor, constant: -9),
        ])

        container.addSubview(iconView)
        container.addSubview(titleStack)
        container.addSubview(pill)

        NSLayoutConstraint.activate([
            iconView.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 14),
            iconView.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 22),

            titleStack.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 9),
            titleStack.centerYAnchor.constraint(equalTo: container.centerYAnchor),

            pill.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -14),
            pill.centerYAnchor.constraint(equalTo: container.centerYAnchor),
        ])

        return container
    }

    private func buildPlatformSection() -> NSView {
        let outer = vstack(insets: NSEdgeInsets(top: 10, left: 14, bottom: 8, right: 14), spacing: 7)

        outer.addArrangedSubview(sectionLabel("PLATFORM"))

        let row = NSStackView()
        row.orientation  = .horizontal
        row.distribution = .fillEqually
        row.spacing      = 5
        row.translatesAutoresizingMaskIntoConstraints = false

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
                         .font: NSFont.systemFont(ofSize: 11)]
        )
        outer.addArrangedSubview(openBtn)

        return outer
    }

    private func makePlatformCard(_ platform: CloudPlatform) -> NSButton {
        let btn = NSButton(frame: .zero)
        btn.isBordered = false
        btn.wantsLayer = true
        btn.layer?.cornerRadius    = 8
        btn.layer?.backgroundColor = Palette.card.cgColor

        let cfg = NSImage.SymbolConfiguration(pointSize: 15, weight: .medium)
        if let img = NSImage(systemSymbolName: platform.iconSymbol,
                             accessibilityDescription: nil)?
                             .withSymbolConfiguration(cfg) {
            btn.image         = img
            btn.imagePosition = .imageAbove
        }
        btn.attributedTitle = NSAttributedString(
            string: platform.shortName,
            attributes: [.foregroundColor: NSColor(white: 0.68, alpha: 1),
                         .font: NSFont.systemFont(ofSize: 8.5, weight: .semibold)]
        )
        btn.contentTintColor = NSColor(white: 0.78, alpha: 1)
        btn.identifier       = NSUserInterfaceItemIdentifier(platform.rawValue)
        btn.target           = self
        btn.action           = #selector(platformCardClicked(_:))
        btn.heightAnchor.constraint(equalToConstant: 56).isActive = true
        return btn
    }

    private func buildStatsRow() -> NSView {
        let row = NSStackView()
        row.orientation  = .horizontal
        row.distribution = .fillEqually
        row.spacing      = 6
        row.edgeInsets   = NSEdgeInsets(top: 8, left: 14, bottom: 8, right: 14)
        row.translatesAutoresizingMaskIntoConstraints = false

        cpuStat  = statLabel("CPU —")
        pingStat = statLabel("⚡ —")
        niceStat = statLabel("n —")

        for stat in [cpuStat!, pingStat!, niceStat!] {
            let card = NSView()
            card.wantsLayer = true
            card.layer?.cornerRadius    = 6
            card.layer?.backgroundColor = Palette.card.cgColor
            card.translatesAutoresizingMaskIntoConstraints = false
            card.heightAnchor.constraint(equalToConstant: 28).isActive = true
            stat.translatesAutoresizingMaskIntoConstraints = false
            card.addSubview(stat)
            NSLayoutConstraint.activate([
                stat.centerXAnchor.constraint(equalTo: card.centerXAnchor),
                stat.centerYAnchor.constraint(equalTo: card.centerYAnchor),
            ])
            row.addArrangedSubview(card)
        }
        return row
    }

    private func buildBoostSection() -> NSView {
        let container = fixedHeight(60)
        boostButton = GradientButton(frame: .zero)
        boostButton.translatesAutoresizingMaskIntoConstraints = false
        boostButton.target = self
        boostButton.action = #selector(boostClicked)
        container.addSubview(boostButton)
        NSLayoutConstraint.activate([
            boostButton.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 14),
            boostButton.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -14),
            boostButton.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            boostButton.heightAnchor.constraint(equalToConstant: 42),
        ])
        return container
    }

    private func buildPresetSection() -> NSView {
        let row = NSStackView()
        row.orientation = .horizontal
        row.spacing     = 8
        row.alignment   = .centerY
        row.edgeInsets  = NSEdgeInsets(top: 10, left: 14, bottom: 10, right: 14)
        row.translatesAutoresizingMaskIntoConstraints = false

        row.addArrangedSubview(sectionLabel("PRESET"))

        let spacer = NSView()
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        row.addArrangedSubview(spacer)

        let labels = PresetName.allCases.map { $0.shortLabel }
        presetControl = NSSegmentedControl(labels: labels, trackingMode: .selectOne,
                                           target: self, action: #selector(presetChanged(_:)))
        presetControl.controlSize      = .small
        presetControl.selectedSegment  = PresetName.allCases.firstIndex(of: Preferences.selectedPreset) ?? 0
        row.addArrangedSubview(presetControl)

        return row
    }

    private func buildSettingsSection() -> NSView {
        autoDetectSwitch = makeSwitch(Preferences.autoDetectEnabled, action: #selector(autoDetectToggled))
        hudSwitch        = makeSwitch(Preferences.hudEnabled,        action: #selector(hudToggled))
        notifSwitch      = makeSwitch(Preferences.notificationsEnabled, action: #selector(notifToggled))
        keepAliveSwitch  = makeSwitch(Preferences.keepAliveEnabled,  action: #selector(keepAliveToggled))

        let outer = vstack(insets: NSEdgeInsets(top: 8, left: 14, bottom: 10, right: 14), spacing: 2)
        outer.addArrangedSubview(sectionLabel("SETTINGS"))

        let rows: [(String, String, NSSwitch)] = [
            ("Auto-detect Platform", "wand.and.stars",  autoDetectSwitch),
            ("HUD Overlay",          "gauge",            hudSwitch),
            ("Notifications",        "bell.badge",       notifSwitch),
            ("Keep Alive",           "timer",            keepAliveSwitch),
        ]
        for (title, icon, toggle) in rows {
            outer.addArrangedSubview(toggleRow(title: title, icon: icon, toggle: toggle))
        }
        return outer
    }

    private func toggleRow(title: String, icon: String, toggle: NSSwitch) -> NSView {
        let row = NSStackView()
        row.orientation = .horizontal
        row.spacing     = 8
        row.alignment   = .centerY
        row.translatesAutoresizingMaskIntoConstraints = false
        row.heightAnchor.constraint(equalToConstant: 30).isActive = true

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

        row.addArrangedSubview(iconImg)
        row.addArrangedSubview(lbl)
        row.addArrangedSubview(spacer)
        row.addArrangedSubview(toggle)
        return row
    }

    private func buildFooter() -> NSView {
        let row = NSStackView()
        row.orientation  = .horizontal
        row.distribution = .fillEqually
        row.spacing      = 6
        row.edgeInsets   = NSEdgeInsets(top: 8, left: 14, bottom: 14, right: 14)
        row.translatesAutoresizingMaskIntoConstraints = false

        let items: [(String, String, Selector)] = [
            ("Diagnostics",   "doc.text",          #selector(exportClicked)),
            ("Check Update",  "arrow.down.circle",  #selector(updateClicked)),
            ("Quit",          "power",              #selector(quitClicked)),
        ]
        for (title, icon, action) in items {
            row.addArrangedSubview(footerButton(title: title, icon: icon, action: action))
        }
        return row
    }

    private func footerButton(title: String, icon: String, action: Selector) -> NSButton {
        let btn = NSButton()
        btn.isBordered = false
        btn.wantsLayer = true
        btn.layer?.cornerRadius    = 7
        btn.layer?.backgroundColor = Palette.card.cgColor
        btn.target = self
        btn.action = action

        let cfg = NSImage.SymbolConfiguration(pointSize: 11, weight: .regular)
        btn.image         = NSImage(systemSymbolName: icon, accessibilityDescription: nil)?
                                    .withSymbolConfiguration(cfg)
        btn.imagePosition = .imageAbove
        btn.contentTintColor = Palette.muted
        btn.attributedTitle  = NSAttributedString(
            string: title,
            attributes: [.foregroundColor: Palette.muted,
                         .font: NSFont.systemFont(ofSize: 9)]
        )
        btn.heightAnchor.constraint(equalToConstant: 46).isActive = true
        return btn
    }

    // MARK: - Actions

    @objc private func platformCardClicked(_ sender: NSButton) {
        guard let id = sender.identifier,
              let platform = CloudPlatform(rawValue: id.rawValue) else { return }
        selectedPlatform = platform
        refreshPlatformCards()
        onPlatformChanged?(platform)
    }

    @objc private func boostClicked()        { onToggleBoost?() }
    @objc private func openPlatformClicked() { onOpenPlatform?() }
    @objc private func exportClicked()       { onExportDiagnostics?() }
    @objc private func updateClicked()       { onCheckUpdates?() }
    @objc private func quitClicked()         { onQuit?() }

    @objc private func presetChanged(_ sender: NSSegmentedControl) {
        let preset = PresetName.allCases[sender.selectedSegment]
        onPresetChanged?(preset)
    }
    @objc private func autoDetectToggled() { onToggleAutoDetect?() }
    @objc private func hudToggled()        { onToggleHUD?() }
    @objc private func notifToggled()      { onToggleNotifications?() }
    @objc private func keepAliveToggled()  { onToggleKeepAlive?() }

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
        cpuStat?.stringValue  = "CPU \(cpu)%"
        pingStat?.stringValue = "⚡ \(ping)"
        niceStat?.stringValue = "n \(nice)"
    }

    func updatePreset(_ preset: PresetName) {
        presetControl?.selectedSegment = PresetName.allCases.firstIndex(of: preset) ?? 0
    }

    func setLoading(_ loading: Bool) {
        boostButton?.isLoadingState = loading
    }

    // MARK: - Refresh helpers

    private func refreshBoostButton() {
        boostButton?.isActiveState  = isBoosterActive
        boostButton?.isLoadingState = false
    }

    private func refreshPlatformCards() {
        for (platform, btn) in platformButtons {
            let sel = platform == selectedPlatform
            btn.layer?.backgroundColor = sel ? Palette.cardSelected.cgColor : Palette.card.cgColor
            btn.layer?.borderWidth     = sel ? 1.5 : 0
            btn.layer?.borderColor     = sel ? Palette.green.cgColor : nil
            btn.contentTintColor       = sel ? Palette.green : NSColor(white: 0.78, alpha: 1)
            btn.attributedTitle        = NSAttributedString(
                string: platform.shortName,
                attributes: [
                    .foregroundColor: sel ? Palette.green : NSColor(white: 0.68, alpha: 1),
                    .font: NSFont.systemFont(ofSize: 8.5, weight: .semibold)
                ]
            )
        }
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
        hudSwitch?.state        = Preferences.hudEnabled        ? .on : .off
        notifSwitch?.state      = Preferences.notificationsEnabled ? .on : .off
        keepAliveSwitch?.state  = Preferences.keepAliveEnabled  ? .on : .off
        presetControl?.selectedSegment = PresetName.allCases.firstIndex(of: Preferences.selectedPreset) ?? 0
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
        return v
    }

    private func vstack(insets: NSEdgeInsets, spacing: CGFloat) -> NSStackView {
        let s = NSStackView()
        s.orientation = .vertical
        s.spacing     = spacing
        s.alignment   = .leading
        s.edgeInsets  = insets
        s.translatesAutoresizingMaskIntoConstraints = false
        return s
    }

    private func label(_ text: String, size: CGFloat, weight: NSFont.Weight,
                        color: NSColor) -> NSTextField {
        let tf = NSTextField(labelWithString: text)
        tf.font      = .systemFont(ofSize: size, weight: weight)
        tf.textColor = color
        return tf
    }

    private func sectionLabel(_ text: String) -> NSTextField {
        label(text, size: 10, weight: .semibold, color: Palette.muted)
    }

    private func statLabel(_ text: String) -> NSTextField {
        let tf = NSTextField(labelWithString: text)
        tf.font      = NSFont.monospacedDigitSystemFont(ofSize: 11, weight: .regular)
        tf.textColor = .white
        tf.alignment = .center
        return tf
    }

    private func makeSwitch(_ on: Bool, action: Selector) -> NSSwitch {
        let s = NSSwitch()
        s.state  = on ? .on : .off
        s.target = self
        s.action = action
        return s
    }

    private func appVersion() -> String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "—"
    }
}

// MARK: - PresetName shortLabel

private extension PresetName {
    var shortLabel: String {
        switch self {
        case .competitive:  return "Max"
        case .balanced:     return "Balanced"
        case .streamQuality: return "Quality"
        }
    }
}
