import AppKit

public class AppDelegate: NSObject, NSApplicationDelegate {

    // MARK: - Properties

    var statusItem:      NSStatusItem!
    var popoverCtrl:     PopoverController!
    private var hudController:    HUDWindowController?
    private var autoDetectTimer:  Timer?
    private var statsSampleTimer: Timer?
    private var isStatsSampleInFlight = false

    // App state (single source of truth)
    private var isBoosterActive = false
    private var selectedPlatform: CloudPlatform = {
        if let raw = UserDefaults.standard.string(forKey: "SelectedPlatform"),
           let p   = CloudPlatform(rawValue: raw) { return p }
        return .geforceNow
    }()

    // MARK: - Launch

    public func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem  = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        popoverCtrl = PopoverController(statusItem: statusItem)

        bindPopoverCallbacks()

        NotificationManager.shared.requestIfNeeded()
        SystemManager.shared.restoreIfNeeded()
        DiagnosticsManager.shared.log("App launched")

        // Push initial state to the popover view
        popoverCtrl.viewController.updateState(isBoosterActive: false,
                                               selectedPlatform: selectedPlatform)

        configureAutoDetectTimer()
        configureHud()

        UpdateManager.shared.checkForUpdates(silent: true)
    }

    public func applicationWillTerminate(_ notification: Notification) {
        SystemManager.shared.disableGamingMode {}
    }

    // MARK: - Callback binding

    private func bindPopoverCallbacks() {
        let vc = popoverCtrl.viewController

        vc.onToggleBoost = { [weak self] in self?.toggleBooster() }

        vc.onPlatformChanged = { [weak self] platform in
            guard let self else { return }
            let previousPlatform = selectedPlatform
            selectedPlatform = platform
            UserDefaults.standard.set(platform.rawValue, forKey: "SelectedPlatform")
            popoverCtrl.viewController.updateState(isBoosterActive: isBoosterActive,
                                                   selectedPlatform: platform)
            DiagnosticsManager.shared.log("Platform changed: \(platform.rawValue)")

            // Re-apply renice to the new platform's processes if boost is active.
            if isBoosterActive, platform != previousPlatform {
                SystemManager.shared.reapplyRenice(processNames: platform.processNames)
            }
        }

        vc.onPresetChanged = { [weak self] preset in
            Preferences.selectedPreset = preset
            self?.popoverCtrl.viewController.updatePreset(preset)
            DiagnosticsManager.shared.log("Preset changed: \(preset.rawValue)")
        }

        vc.onToggleAutoDetect = { [weak self] in
            Preferences.autoDetectEnabled.toggle()
            self?.configureAutoDetectTimer()
            DiagnosticsManager.shared.log("Auto-detect: \(Preferences.autoDetectEnabled)")
        }

        vc.onToggleHUD = { [weak self] in
            Preferences.hudEnabled.toggle()
            self?.configureHud()
            DiagnosticsManager.shared.log("HUD: \(Preferences.hudEnabled)")
        }

        vc.onToggleNotifications = {
            Preferences.notificationsEnabled.toggle()
            NotificationManager.shared.requestIfNeeded()
            DiagnosticsManager.shared.log("Notifications: \(Preferences.notificationsEnabled)")
        }

        vc.onToggleKeepAlive = { [weak self] in
            Preferences.keepAliveEnabled.toggle()
            self?.updateKeepAliveIfNeeded()
            DiagnosticsManager.shared.log("Keep-alive: \(Preferences.keepAliveEnabled)")
        }

        vc.onToggleAdaptiveIntelligence = {
            Preferences.adaptiveIntelligenceEnabled.toggle()
            DiagnosticsManager.shared.log("Adaptive Intelligence: \(Preferences.adaptiveIntelligenceEnabled)")
        }

        vc.onExportDiagnostics = { [weak self] in
            guard let self else { return }
            DiagnosticsManager.shared.exportDiagnostics(
                selectedPlatform: selectedPlatform,
                targetProcessNames: selectedPlatform.processNames
            )
        }

        vc.onCheckUpdates = { UpdateManager.shared.checkForUpdates(silent: false) }

        vc.onQuit = { NSApplication.shared.terminate(nil) }

        vc.onOpenPlatform = { [weak self] in self?.openSelectedPlatform() }
    }

    // MARK: - Boost toggle

    private func toggleBooster() {
        popoverCtrl.viewController.setLoading(true)

        if isBoosterActive {
            SystemManager.shared.disableGamingMode { [weak self] in
                guard let self else { return }
                isBoosterActive = false
                MouseManager.apply(profile: .defaultMac)
                finishBoostTransition()
                NotificationManager.shared.notify(title: "CloudBoost", body: "Boost disabled")
                DiagnosticsManager.shared.log("Boost disabled")
            }
        } else {
            SystemManager.shared.enableGamingMode(
                processNames: selectedPlatform.processNames,
                openBundleId: selectedPlatform.openBundleId
            ) { [weak self] success in
                guard let self else { return }
                isBoosterActive = success
                if success {
                    MouseManager.apply(profile: .rawFPS)
                    NotificationManager.shared.notify(title: "CloudBoost", body: "Boost enabled")
                    DiagnosticsManager.shared.log("Boost enabled")
                } else {
                    NotificationManager.shared.notify(title: "CloudBoost", body: "Boost failed or cancelled")
                    DiagnosticsManager.shared.log("Boost failed or cancelled")
                }
                finishBoostTransition()
            }
        }
    }

    private func finishBoostTransition() {
        popoverCtrl.setBoostActive(isBoosterActive)
        popoverCtrl.viewController.updateState(isBoosterActive: isBoosterActive,
                                               selectedPlatform: selectedPlatform)
        updateKeepAliveIfNeeded()
        updateStatsSampling()
    }

    // MARK: - Platform launcher

    private func openSelectedPlatform() {
        let platform = selectedPlatform
        if let bundleId = platform.openBundleId,
           let appURL   = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleId) {
            let cfg = NSWorkspace.OpenConfiguration()
            NSWorkspace.shared.openApplication(at: appURL, configuration: cfg) { _, error in
                if error != nil, let webURL = platform.webURL {
                    NSWorkspace.shared.open(webURL)
                }
            }
        } else if let webURL = platform.webURL {
            NSWorkspace.shared.open(webURL)
        }
    }

    // MARK: - Auto-detect timer

    private func configureAutoDetectTimer() {
        autoDetectTimer?.invalidate()
        autoDetectTimer = nil
        guard Preferences.autoDetectEnabled else { return }
        autoDetectTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            guard let self,
                  let detected = PlatformDetector.detectActivePlatform(),
                  detected != self.selectedPlatform else { return }
            let previous = self.selectedPlatform
            self.selectedPlatform = detected
            UserDefaults.standard.set(detected.rawValue, forKey: "SelectedPlatform")
            self.popoverCtrl.viewController.updateState(isBoosterActive: self.isBoosterActive,
                                                   selectedPlatform: detected)
            NotificationManager.shared.notify(title: "CloudBoost",
                                              body: "Auto-detected: \(detected.rawValue)")
            DiagnosticsManager.shared.log("Auto-detected platform: \(detected.rawValue)")

            // Re-apply renice to the newly detected platform if boost is active.
            if self.isBoosterActive, detected != previous {
                SystemManager.shared.reapplyRenice(processNames: detected.processNames)
            }
        }
    }

    // MARK: - HUD

    private func configureHud() {
        if Preferences.hudEnabled {
            if hudController == nil { hudController = HUDWindowController() }
            hudController?.showWindow(nil)
        } else {
            hudController?.close()
            hudController = nil
        }
        updateStatsSampling()
    }

    // MARK: - Stats sampling (feeds both HUD and popover)

    private func updateStatsSampling() {
        if isBoosterActive {
            startStatsSampling()
        } else {
            stopStatsSampling()
            popoverCtrl.viewController.updateStats(cpu: "—", ping: "—", nice: "—")
            popoverCtrl.viewController.updateSession(path: "--", jitter: "--", health: "--", awdl: SystemManager.shared.awdlGuardStatus().rawValue)
            hudController?.update(text: "CloudBoost · Boost OFF")
        }
    }

    private func startStatsSampling() {
        stopStatsSampling()
        statsSampleTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.sampleStats()
        }
        sampleStats()
    }

    private func stopStatsSampling() {
        statsSampleTimer?.invalidate()
        statsSampleTimer = nil
    }

    private func sampleStats() {
        guard !isStatsSampleInFlight else { return }
        isStatsSampleInFlight = true

        let platform     = selectedPlatform
        let processNames = platform.processNames
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self else { return }
            let pid   = SystemManager.shared.firstMatchingPid(processNames)
            let cpu   = pid.flatMap { SystemManager.shared.readCpuUsage(pid: $0)  } ?? "—"
            let nice  = pid.flatMap { SystemManager.shared.readNiceValue(pid: $0) } ?? "—"
            let awdlStatus = SystemManager.shared.awdlGuardStatus().rawValue
            let useAdaptive = ProManager.shared.isProUnlocked && Preferences.adaptiveIntelligenceEnabled

            let ping: String
            let path: String
            let jitter: String
            let health: String

            if useAdaptive {
                let metrics = SystemObservabilityManager.shared.sample()
                let assessment = OptimizationEngine.shared.assess(metrics: metrics)
                ping = metrics.latency.displayLatency
                path = metrics.networkPath.interface.rawValue
                jitter = metrics.latency.displayJitter
                health = assessment.health.rawValue
            } else {
                ping = SystemManager.shared.pingStats()
                path = "Basic"
                jitter = ProManager.shared.isProUnlocked ? "Off" : "PRO"
                health = isBoosterActive ? "Active" : "--"
            }

            let hudText = "\(platform.shortName) CPU \(cpu)%  \(ping)  \(jitter)  n\(nice)  \(health)  AWDL \(awdlStatus)"
            DispatchQueue.main.async {
                self.isStatsSampleInFlight = false
                self.popoverCtrl.viewController.updateStats(cpu: cpu, ping: ping, nice: nice)
                self.popoverCtrl.viewController.updateSession(path: path,
                                                              jitter: jitter,
                                                              health: health,
                                                              awdl: awdlStatus)
                self.hudController?.update(text: hudText)
            }
        }
    }

    // MARK: - Keep Alive

    private func updateKeepAliveIfNeeded() {
        if isBoosterActive, Preferences.keepAliveEnabled {
            let seconds = TimeInterval(Preferences.keepAliveIntervalMinutes * 60)
            KeepAliveManager.shared.start(intervalSeconds: seconds)
        } else {
            KeepAliveManager.shared.stop()
        }
    }
}
