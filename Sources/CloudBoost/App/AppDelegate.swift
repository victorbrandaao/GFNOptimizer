import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var menuBuilder: MenuBuilder!
    private var autoDetectTimer: Timer?
    private var hudController: HUDWindowController?
    private var hudSnapshot: (String, String) = ("CloudBoost HUD", "")
    private var hudSampleTimer: Timer?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        menuBuilder = MenuBuilder(statusItem: statusItem)
        menuBuilder.updateState(isActive: false)

        NotificationManager.shared.requestIfNeeded()
        SystemManager.shared.restoreIfNeeded()
        DiagnosticsManager.shared.log("App launched")

        NotificationCenter.default.addObserver(self, selector: #selector(handleHudToggle), name: .hudToggle, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleAutoDetectToggle), name: .autoDetectToggle, object: nil)
        configureAutoDetectTimer()
        configureHud()
        
        UpdateManager.shared.checkForUpdates(silent: true)
    }
    
    @objc func toggleBooster() {
        menuBuilder.setLoading()
        
        if menuBuilder.isBoosterActive {
            SystemManager.shared.disableGamingMode {
                self.menuBuilder.updateState(isActive: false)
                NotificationManager.shared.notify(title: "CloudBoost", body: "Boost disabled")
                DiagnosticsManager.shared.log("Boost disabled")
            }
        } else {
            SystemManager.shared.enableGamingMode(
                processNames: menuBuilder.targetProcessNames,
                openBundleId: menuBuilder.targetOpenBundleId
            ) {
                MouseManager.apply(profile: .rawFPS)
                self.menuBuilder.updateState(isActive: true)
                NotificationManager.shared.notify(title: "CloudBoost", body: "Boost enabled")
                DiagnosticsManager.shared.log("Boost enabled")
            }
        }
    }
    
    @objc func setPlatform(_ sender: NSMenuItem) {
        if let platform = sender.representedObject as? CloudPlatform {
            menuBuilder.changePlatform(platform)
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
            hudController?.startUpdating(statusProvider: { self.hudSnapshot })
        } else {
            hudController?.close()
            hudController = nil
            stopHudSampling()
        }
    }

    private func startHudSampling() {
        hudSampleTimer?.invalidate()
        hudSampleTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
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
            let summary = "Preset: \(Preferences.selectedPreset.rawValue) | Platform: \(platform.rawValue)"
            let details = self.buildHudDetails(processNames: processNames)
            DispatchQueue.main.async {
                self.hudSnapshot = (summary, details)
            }
        }
    }

    private func buildHudDetails(processNames: [String]) -> String {
        let pid = SystemManager.shared.firstMatchingPid(processNames)
        let cpu = pid.flatMap { SystemManager.shared.readCpuUsage(pid: $0) } ?? "n/a"
        let nice = pid.flatMap { SystemManager.shared.readNiceValue(pid: $0) } ?? "n/a"
        let ping = SystemManager.shared.pingStats()
        return "CPU: \(cpu)% | nice: \(nice) | ping: \(ping)"
    }
}