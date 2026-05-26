import AppKit

enum CloudPlatform: String {
    case geforceNow = "GeForce NOW"
    case boosteroid = "Boosteroid"
    case xcloud = "Xbox Cloud Gaming"
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
    
    var targetProcessName: String {
        switch selectedPlatform {
        case .geforceNow:
            return "com.nvidia.gfnpc.mac"
        case .xcloud:
            return MenuBuilder.getDefaultBrowserProcessName()
        case .boosteroid:
            let useBrowser = UserDefaults.standard.bool(forKey: "BoosteroidUseBrowser")
            return useBrowser ? MenuBuilder.getDefaultBrowserProcessName() : "com.boosteroid.mac.client"
        }
    }
    
    // --- CONSTRUÇÃO DA INTERFACE ---
    
    func rebuildMenu() {
        let menu = NSMenu()
        
        if let button = statusItem.button {
            // Se tiver uma lógica de ícone ativo/inativo, aplique aqui
            button.image = NSImage(named: NSImage.Name("CloudBoostIcon"))
            button.image?.isTemplate = true
        }
        
        // 1. Plataformas
        menu.addItem(NSMenuItem(title: "Select Platform:", action: nil, keyEquivalent: ""))
        
        let gfnItem = NSMenuItem(title: "GeForce NOW", action: Selector(("setPlatform:")), keyEquivalent: "")
        gfnItem.target = NSApp.delegate // Aponta de volta para o AppDelegate
        gfnItem.representedObject = CloudPlatform.geforceNow
        gfnItem.state = (selectedPlatform == .geforceNow) ? .on : .off
        menu.addItem(gfnItem)
        
        let boosteroidItem = NSMenuItem(title: "Boosteroid", action: Selector(("setPlatform:")), keyEquivalent: "")
        boosteroidItem.target = NSApp.delegate
        boosteroidItem.representedObject = CloudPlatform.boosteroid
        boosteroidItem.state = (selectedPlatform == .boosteroid) ? .on : .off
        menu.addItem(boosteroidItem)
        
        let xcloudItem = NSMenuItem(title: "Xbox Cloud Gaming (xCloud)", action: Selector(("setPlatform:")), keyEquivalent: "")
        xcloudItem.target = NSApp.delegate
        xcloudItem.representedObject = CloudPlatform.xcloud
        xcloudItem.state = (selectedPlatform == .xcloud) ? .on : .off
        menu.addItem(xcloudItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // 2. Opções Avançadas (Navegador)
        menu.addItem(NSMenuItem(title: "Options:", action: nil, keyEquivalent: ""))
        
        let boosteroidToggle = NSMenuItem(title: "Launch Boosteroid in Browser", action: #selector(toggleBoosteroidBrowser(_:)), keyEquivalent: "")
        boosteroidToggle.target = self // Resolvido aqui dentro
        let isBrowserEnabled = UserDefaults.standard.bool(forKey: "BoosteroidUseBrowser")
        boosteroidToggle.state = isBrowserEnabled ? .on : .off
        menu.addItem(boosteroidToggle)
        
        let currentBrowserName = MenuBuilder.getDefaultBrowserProcessName()
        let browserInfoItem = NSMenuItem(title: "Default Browser: \(currentBrowserName)", action: nil, keyEquivalent: "")
        browserInfoItem.isEnabled = false
        menu.addItem(browserInfoItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // 3. Controlo do Booster
        let boosterTitle = isBoosterActive ? "Disable CloudBoost" : "Enable CloudBoost"
        let boosterActionItem = NSMenuItem(title: boosterTitle, action: Selector(("toggleBooster")), keyEquivalent: "b")
        boosterActionItem.target = NSApp.delegate // Aponta de volta para o AppDelegate
        menu.addItem(boosterActionItem)
        
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit CloudBoost", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        
        statusItem.menu = menu
    }
    
    @objc func toggleBoosteroidBrowser(_ sender: NSMenuItem) {
        let currentState = UserDefaults.standard.bool(forKey: "BoosteroidUseBrowser")
        UserDefaults.standard.set(!currentState, forKey: "BoosteroidUseBrowser")
        rebuildMenu() // Atualiza a UI instantaneamente
    }
}