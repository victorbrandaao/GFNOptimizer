import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var menuBuilder: MenuBuilder!
    private var autoDetectTimer: Timer?
    private var hudController: HUDWindowController?
    private var hudSnapshot: String = "CloudBoost HUD"
    private var hudSampleTimer: Timer?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        menuBuilder = MenuBuilder(statusItem: statusItem)

        NotificationManager.shared.requestIfNeeded()
        SystemManager.shared.restoreIfNeeded()
        DiagnosticsManager.shared.log("App launched")

        NotificationCenter.default.addObserver(self, selector: #selector(handleHudToggle), name: .hudToggle, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleAutoDetectToggle), name: .autoDetectToggle, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeepAliveToggle), name: .keepAliveToggle, object: nil)
        configureAutoDetectTimer()
        configureHud()
        
        UpdateManager.shared.checkForUpdates(silent: true)
    }
    
    @objc func toggleBooster() {
        menuBuilder.setLoading()
        
        if menuBuilder.isBoosterActive {
            SystemManager.shared.disableGamingMode {
                self.menuBuilder.updateState(isActive: false)
                self.updateKeepAliveIfNeeded()
                NotificationManager.shared.notify(title: "CloudBoost", body: "Boost disabled")
                DiagnosticsManager.shared.log("Boost disabled")
            }
        } else {
            SystemManager.shared.enableGamingMode(
                processNames: menuBuilder.targetProcessNames,
                openBundleId: menuBuilder.targetOpenBundleId
            ) { success in
                if success {
                    MouseManager.apply(profile: .rawFPS)
                    self.menuBuilder.updateState(isActive: true)
                    self.updateKeepAliveIfNeeded()
                    NotificationManager.shared.notify(title: "CloudBoost", body: "Boost enabled")
                    DiagnosticsManager.shared.log("Boost enabled")
                } else {
                    self.menuBuilder.updateState(isActive: false)
                    self.updateKeepAliveIfNeeded()
                    NotificationManager.shared.notify(title: "CloudBoost", body: "Boost failed or was cancelled")
                    DiagnosticsManager.shared.log("Boost failed or was cancelled")
                }
            }
        }
    }
    
    @objc func setPlatform(_ sender: NSMenuItem) {
        if let platform = sender.representedObject as? CloudPlatform {
            menuBuilder.changePlatform(platform)
        }
    }

    @objc func openSelectedPlatform() {
        let platform = menuBuilder.selectedPlatform
        let useBrowser = UserDefaults.standard.bool(forKey: "BoosteroidUseBrowser")
        switch platform {
        case .geforceNow:
            openAppOrUrl(bundleId: "com.nvidia.gfnpc.mac", url: URL(string: "https://play.geforcenow.com/") )
        case .boosteroid:
            if useBrowser {
                openUrl(URL(string: "https://cloud.boosteroid.com/") )
            } else {
                openAppOrUrl(bundleId: "com.boosteroid.mac.client", url: URL(string: "https://cloud.boosteroid.com/") )
            }
        case .xcloud:
            openUrl(URL(string: "https://www.xbox.com/play"))
        case .moonlight:
            openAppOrUrl(bundleId: "com.moonlight-stream.Moonlight", url: nil)
        case .voidlink:
            openUrl(URL(string: "https://voidlink.com"))
        }
    }

    private func openUrl(_ url: URL?) {
        guard let url else { return }
        NSWorkspace.shared.open(url)
    }

    private func openAppOrUrl(bundleId: String, url: URL?) {
        if let appUrl = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleId) {
            let config = NSWorkspace.OpenConfiguration()
            NSWorkspace.shared.openApplication(at: appUrl, configuration: config) { _, error in
                if error != nil {
                    self.openUrl(url)
                }
            }
        } else {
            openUrl(url)
        }
    }
    
    @objc func setFPSMouse() { MouseManager.apply(profile: .rawFPS) }
    @objc func setMOBAMouse() { MouseManager.apply(profile: .fastMOBA) }
    
    @objc func checkUpdatesManual() {
        UpdateManager.shared.checkForUpdates(silent: false)
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        SystemManager.shared.disableGamingMode {}
    }

    @objc private func handleHudToggle() {
        configureHud()
    }

    @objc private func handleAutoDetectToggle() {
        configureAutoDetectTimer()
    }

    @objc private func handleKeepAliveToggle() {
        updateKeepAliveIfNeeded()
    }

    private func configureAutoDetectTimer() {
        autoDetectTimer?.invalidate()
        autoDetectTimer = nil
        guard Preferences.autoDetectEnabled else { return }
        autoDetectTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
            guard let detected = PlatformDetector.detectActivePlatform() else { return }
            if detected != self.menuBuilder.selectedPlatform {
                self.menuBuilder.changePlatform(detected)
                NotificationManager.shared.notify(title: "CloudBoost", body: "Auto-detected: \(detected.rawValue)")
                DiagnosticsManager.shared.log("Auto-detected platform: \(detected.rawValue)")
            }
        }
    }

    private func configureHud() {
        if Preferences.hudEnabled {
            if hudController == nil {
                hudController = HUDWindowController()
            }
            hudController?.showWindow(nil)
            startHudSampling()
            hudController?.startUpdating(interval: 2.0, statusProvider: { self.hudSnapshot })
        } else {
            hudController?.stopUpdating()
            hudController?.close()
            hudController = nil
            stopHudSampling()
        }
    }

    private func updateKeepAliveIfNeeded() {
        if menuBuilder.isBoosterActive, Preferences.keepAliveEnabled {
            let seconds = TimeInterval(Preferences.keepAliveIntervalMinutes * 60)
            KeepAliveManager.shared.start(intervalSeconds: seconds)
        } else {
            KeepAliveManager.shared.stop()
        }
    }

    private func startHudSampling() {
        hudSampleTimer?.invalidate()
        hudSampleTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            self.refreshHudSnapshot()
        }
        refreshHudSnapshot()
    }

    private func stopHudSampling() {
        hudSampleTimer?.invalidate()
        hudSampleTimer = nil
    }

    private func refreshHudSnapshot() {
        let platform = menuBuilder.selectedPlatform
        let processNames = menuBuilder.targetProcessNames
        DispatchQueue.global(qos: .userInitiated).async {
            let details = self.buildHudDetails(processNames: processNames, platform: platform)
            DispatchQueue.main.async {
                self.hudSnapshot = details
            }
        }
    }

    private func buildHudDetails(processNames: [String], platform: CloudPlatform) -> String {
        let pid = SystemManager.shared.firstMatchingPid(processNames)
        let cpu = pid.flatMap { SystemManager.shared.readCpuUsage(pid: $0) } ?? "n/a"
        let nice = pid.flatMap { SystemManager.shared.readNiceValue(pid: $0) } ?? "n/a"
        let ping = SystemManager.shared.pingStats()
        let platformTag = hudPlatformTag(platform)
        let presetTag = hudPresetTag(Preferences.selectedPreset)
        return "\(platformTag) \(presetTag) CPU\(cpu)% \(ping) n\(nice)"
    }

    private func hudPlatformTag(_ platform: CloudPlatform) -> String {
        switch platform {
        case .geforceNow: return "GFN"
        case .boosteroid: return "BST"
        case .xcloud: return "XCL"
        case .moonlight: return "MOON"
        case .voidlink: return "VOID"
        }
    }

    private func hudPresetTag(_ preset: PresetName) -> String {
        switch preset {
        case .competitive: return "COMP"
        case .balanced: return "BAL"
        case .streamQuality: return "QUAL"
        }
    }
}