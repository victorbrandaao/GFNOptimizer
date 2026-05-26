import AppKit

enum CloudPlatform: String {
    case geforceNow = "GeForce NOW"
    case boosteroid = "Boosteroid"
    case xcloud = "Xbox Cloud Gaming"
    case moonlight = "Moonlight"
    case voidlink = "VoidLink Extreme"
}

class MenuBuilder: NSObject {
    let statusItem: NSStatusItem
    var isBoosterActive: Bool = false
    var selectedPlatform: CloudPlatform = .geforceNow
    
    init(statusItem: NSStatusItem) {
        self.statusItem = statusItem
        super.init()
        
        // Recupera a última plataforma selecionada pelo utilizador
        if let savedStr = UserDefaults.standard.string(forKey: "SelectedPlatform"),
           let platform = CloudPlatform(rawValue: savedStr) {
            self.selectedPlatform = platform
        }
        
        rebuildMenu()
    }
    
    // --- MÉTODOS REQUERIDOS PELO APPDELEGATE ---
    
    func updateState(isActive: Bool) {
        self.isBoosterActive = isActive
        rebuildMenu()
    }
    
    func setLoading() {
        if let menu = statusItem.menu, 
           let item = menu.item(withTitle: isBoosterActive ? "Disable CloudBoost" : "Enable CloudBoost") {
            item.title = "Applying..."
            item.isEnabled = false
        }
    }
    
    func changePlatform(_ platform: CloudPlatform) {
        self.selectedPlatform = platform
        UserDefaults.standard.set(platform.rawValue, forKey: "SelectedPlatform")
        rebuildMenu()
    }
    
    // --- LÓGICA DO NAVEGADOR DINÂMICO ---
    
    static func getDefaultBrowserProcessName() -> String {
        guard let dummyURL = URL(string: "https://"),
              let browserURL = NSWorkspace.shared.urlForApplication(toOpen: dummyURL) else {
            return "Safari" // Fallback seguro
        }
        return browserURL.lastPathComponent.replacingOccurrences(of: ".app", with: "")
    }

    static func getDefaultBrowserBundleId() -> String? {
        guard let dummyURL = URL(string: "https://"),
              let browserURL = NSWorkspace.shared.urlForApplication(toOpen: dummyURL),
              let bundle = Bundle(url: browserURL) else {
            return nil
        }
        return bundle.bundleIdentifier
    }
    
    var targetProcessNames: [String] {
        switch selectedPlatform {
        case .geforceNow:
            return ["NVIDIA GeForce NOW"]
        case .xcloud:
            return [MenuBuilder.getDefaultBrowserProcessName()]
        case .boosteroid:
            let useBrowser = UserDefaults.standard.bool(forKey: "BoosteroidUseBrowser")
            return useBrowser ? [MenuBuilder.getDefaultBrowserProcessName()] : ["Boosteroid"]
        case .moonlight:
            return ["Moonlight"]
        case .voidlink:
            return ["VoidLink", "VoidLink Extreme"]
        }
    }

    var targetOpenBundleId: String? {
        switch selectedPlatform {
        case .geforceNow:
            return "com.nvidia.gfnpc.mac"
        case .xcloud:
            return MenuBuilder.getDefaultBrowserBundleId()
        case .boosteroid:
            let useBrowser = UserDefaults.standard.bool(forKey: "BoosteroidUseBrowser")
            return useBrowser ? MenuBuilder.getDefaultBrowserBundleId() : "com.boosteroid.mac.client"
        case .moonlight:
            return "com.moonlight-stream.Moonlight"
        case .voidlink:
            return nil
        }
    }
    
    // --- CONSTRUÇÃO DA INTERFACE ---
    
    func rebuildMenu() {
        let menu = NSMenu()
        
        if let button = statusItem.button {
            // Usa um símbolo do sistema para garantir visibilidade em `swift run` e no app distribuído.
            if let symbolImage = NSImage(systemSymbolName: isBoosterActive ? "bolt.fill" : "cloud.fill", accessibilityDescription: "CloudBoost") {
                symbolImage.isTemplate = true
                button.image = symbolImage
                button.title = ""
            } else {
                button.image = nil
                button.title = "CB"
            }
        }
        
        // 1. Plataformas
        menu.addItem(NSMenuItem(title: "Select Platform:", action: nil, keyEquivalent: ""))
        
        let gfnItem = NSMenuItem(title: "GeForce NOW", action: Selector(("setPlatform:")), keyEquivalent: "")
        gfnItem.image = menuIcon(name: "cloud.fill")
        gfnItem.target = NSApp.delegate // Aponta de volta para o AppDelegate
        gfnItem.representedObject = CloudPlatform.geforceNow
        gfnItem.state = (selectedPlatform == .geforceNow) ? .on : .off
        menu.addItem(gfnItem)
        
        let boosteroidItem = NSMenuItem(title: "Boosteroid", action: Selector(("setPlatform:")), keyEquivalent: "")
        boosteroidItem.image = menuIcon(name: "speedometer")
        boosteroidItem.target = NSApp.delegate
        boosteroidItem.representedObject = CloudPlatform.boosteroid
        boosteroidItem.state = (selectedPlatform == .boosteroid) ? .on : .off
        menu.addItem(boosteroidItem)
        
        let xcloudItem = NSMenuItem(title: "Xbox Cloud Gaming (xCloud)", action: Selector(("setPlatform:")), keyEquivalent: "")
        xcloudItem.image = menuIcon(name: "gamecontroller")
        xcloudItem.target = NSApp.delegate
        xcloudItem.representedObject = CloudPlatform.xcloud
        xcloudItem.state = (selectedPlatform == .xcloud) ? .on : .off
        menu.addItem(xcloudItem)

        let moonlightItem = NSMenuItem(title: "Moonlight", action: Selector(("setPlatform:")), keyEquivalent: "")
        moonlightItem.image = menuIcon(name: "moon.stars.fill")
        moonlightItem.target = NSApp.delegate
        moonlightItem.representedObject = CloudPlatform.moonlight
        moonlightItem.state = (selectedPlatform == .moonlight) ? .on : .off
        menu.addItem(moonlightItem)

        let voidlinkItem = NSMenuItem(title: "VoidLink Extreme", action: Selector(("setPlatform:")), keyEquivalent: "")
        voidlinkItem.image = menuIcon(name: "bolt.horizontal.circle.fill")
        voidlinkItem.target = NSApp.delegate
        voidlinkItem.representedObject = CloudPlatform.voidlink
        voidlinkItem.state = (selectedPlatform == .voidlink) ? .on : .off
        menu.addItem(voidlinkItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // 2. Opções Avançadas (Navegador)
        menu.addItem(NSMenuItem(title: "Options:", action: nil, keyEquivalent: ""))
        
        let boosteroidToggle = NSMenuItem(title: "Launch Boosteroid in Browser", action: #selector(toggleBoosteroidBrowser(_:)), keyEquivalent: "")
        boosteroidToggle.image = menuIcon(name: "safari")
        boosteroidToggle.target = self // Resolvido aqui dentro
        let isBrowserEnabled = UserDefaults.standard.bool(forKey: "BoosteroidUseBrowser")
        boosteroidToggle.state = isBrowserEnabled ? .on : .off
        menu.addItem(boosteroidToggle)
        
        let currentBrowserName = MenuBuilder.getDefaultBrowserProcessName()
        let browserInfoItem = NSMenuItem(title: "Default Browser: \(currentBrowserName)", action: nil, keyEquivalent: "")
        browserInfoItem.isEnabled = false
        menu.addItem(browserInfoItem)

        menu.addItem(NSMenuItem.separator())

        // 3. Performance
        menu.addItem(NSMenuItem(title: "Performance Preset:", action: nil, keyEquivalent: ""))
        for preset in PresetName.allCases {
            let item = NSMenuItem(title: preset.rawValue, action: #selector(selectPreset(_:)), keyEquivalent: "")
            item.image = menuIcon(name: "slider.horizontal.3")
            item.target = self
            item.representedObject = preset
            item.state = (Preferences.selectedPreset == preset) ? .on : .off
            menu.addItem(item)
        }

        let autoDetectItem = NSMenuItem(title: "Auto-Detect Active Platform", action: #selector(toggleAutoDetect(_:)), keyEquivalent: "")
        autoDetectItem.image = menuIcon(name: "wand.and.stars")
        autoDetectItem.target = self
        autoDetectItem.state = Preferences.autoDetectEnabled ? .on : .off
        menu.addItem(autoDetectItem)

        let hudItem = NSMenuItem(title: "Performance HUD", action: #selector(toggleHud(_:)), keyEquivalent: "")
        hudItem.image = menuIcon(name: "gauge")
        hudItem.target = self
        hudItem.state = Preferences.hudEnabled ? .on : .off
        menu.addItem(hudItem)

        let notificationsItem = NSMenuItem(title: "Status Notifications", action: #selector(toggleNotifications(_:)), keyEquivalent: "")
        notificationsItem.image = menuIcon(name: "bell.badge.fill")
        notificationsItem.target = self
        notificationsItem.state = Preferences.notificationsEnabled ? .on : .off
        menu.addItem(notificationsItem)

        menu.addItem(NSMenuItem.separator())

        // 4. Diagnostics
        let allowlistItem = NSMenuItem(title: "Edit Allowlist...", action: #selector(editAllowlist), keyEquivalent: "")
        allowlistItem.image = menuIcon(name: "checkmark.seal")
        allowlistItem.target = self
        menu.addItem(allowlistItem)

        let blocklistItem = NSMenuItem(title: "Edit Blocklist...", action: #selector(editBlocklist), keyEquivalent: "")
        blocklistItem.image = menuIcon(name: "xmark.seal")
        blocklistItem.target = self
        menu.addItem(blocklistItem)

        let exportLogsItem = NSMenuItem(title: "Export Diagnostics...", action: #selector(exportDiagnostics), keyEquivalent: "")
        exportLogsItem.image = menuIcon(name: "doc.text")
        exportLogsItem.target = self
        menu.addItem(exportLogsItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // 5. Controlo do Booster
        let boosterTitle = isBoosterActive ? "Disable CloudBoost" : "Enable CloudBoost"
        let boosterActionItem = NSMenuItem(title: boosterTitle, action: Selector(("toggleBooster")), keyEquivalent: "b")
        boosterActionItem.image = menuIcon(name: isBoosterActive ? "stop.circle.fill" : "bolt.circle.fill")
        boosterActionItem.target = NSApp.delegate // Aponta de volta para o AppDelegate
        menu.addItem(boosterActionItem)
        
        menu.addItem(NSMenuItem.separator())
        let quitItem = NSMenuItem(title: "Quit CloudBoost", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        quitItem.image = menuIcon(name: "power")
        menu.addItem(quitItem)
        
        statusItem.menu = menu
    }
    
    @objc func toggleBoosteroidBrowser(_ sender: NSMenuItem) {
        let currentState = UserDefaults.standard.bool(forKey: "BoosteroidUseBrowser")
        UserDefaults.standard.set(!currentState, forKey: "BoosteroidUseBrowser")
        rebuildMenu() // Atualiza a UI instantaneamente
    }

    @objc private func selectPreset(_ sender: NSMenuItem) {
        guard let preset = sender.representedObject as? PresetName else { return }
        Preferences.selectedPreset = preset
        DiagnosticsManager.shared.log("Preset changed to \(preset.rawValue)")
        rebuildMenu()
    }

    @objc private func toggleAutoDetect(_ sender: NSMenuItem) {
        Preferences.autoDetectEnabled.toggle()
        NotificationCenter.default.post(name: .autoDetectToggle, object: nil)
        DiagnosticsManager.shared.log("Auto-detect toggled: \(Preferences.autoDetectEnabled)")
        rebuildMenu()
    }

    @objc private func toggleHud(_ sender: NSMenuItem) {
        Preferences.hudEnabled.toggle()
        NotificationCenter.default.post(name: .hudToggle, object: nil)
        DiagnosticsManager.shared.log("HUD toggled: \(Preferences.hudEnabled)")
        rebuildMenu()
    }

    @objc private func toggleNotifications(_ sender: NSMenuItem) {
        Preferences.notificationsEnabled.toggle()
        NotificationManager.shared.requestIfNeeded()
        DiagnosticsManager.shared.log("Notifications toggled: \(Preferences.notificationsEnabled)")
        rebuildMenu()
    }

    @objc private func editAllowlist() {
        let result = promptList(title: "Edit Allowlist", message: "Comma-separated process names to allow.", current: Preferences.allowlist)
        if let list = result {
            Preferences.allowlist = list
            DiagnosticsManager.shared.log("Allowlist updated")
        }
    }

    @objc private func editBlocklist() {
        let result = promptList(title: "Edit Blocklist", message: "Comma-separated process names to block.", current: Preferences.blocklist)
        if let list = result {
            Preferences.blocklist = list
            DiagnosticsManager.shared.log("Blocklist updated")
        }
    }

    @objc private func exportDiagnostics() {
        DiagnosticsManager.shared.exportDiagnostics(selectedPlatform: selectedPlatform, targetProcessNames: targetProcessNames)
    }

    private func promptList(title: String, message: String, current: [String]) -> [String]? {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = .informational
        let textField = NSTextField(string: current.joined(separator: ", "))
        textField.frame = NSRect(x: 0, y: 0, width: 300, height: 24)
        alert.accessoryView = textField
        alert.addButton(withTitle: "Save")
        alert.addButton(withTitle: "Cancel")
        let response = alert.runModal()
        guard response == .alertFirstButtonReturn else { return nil }
        let raw = textField.stringValue
        let parts = raw.split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        return parts.filter { !$0.isEmpty }
    }

    private func menuIcon(name: String) -> NSImage? {
        guard let image = NSImage(systemSymbolName: name, accessibilityDescription: nil) else {
            return nil
        }
        image.isTemplate = true
        return image
    }
}