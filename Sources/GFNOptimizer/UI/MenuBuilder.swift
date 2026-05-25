import AppKit

enum CloudPlatform: String, CaseIterable {
    case geforceNow = "GeForce NOW"
    case boosteroid = "Boosteroid"
    case xcloud = "Xbox Cloud Gaming"
    
    var bundleID: String? {
        switch self {
        case .geforceNow: return "com.nvidia.gfnpc.mac"
        case .boosteroid: return "com.boosteroid.mac.client"
        case .xcloud: return nil 
        }
    }
    
    var processName: String {
        switch self {
        case .geforceNow: return "NVIDIA GeForce NOW"
        case .boosteroid: return "Boosteroid"
        case .xcloud: return "Safari" 
        }
    }
}

class MenuBuilder {
    private let statusItem: NSStatusItem
    private(set) var isBoosterActive = false
    private(set) var selectedPlatform: CloudPlatform = .geforceNow
    
    init(statusItem: NSStatusItem) {
        self.statusItem = statusItem
    }
    
    func buildMenu() -> NSMenu {
        let menu = NSMenu()
        
        let toggleItem = NSMenuItem(title: isBoosterActive ? "Disable CloudBoost" : "Enable CloudBoost", 
                                    action: #selector(AppDelegate.toggleBooster), 
                                    keyEquivalent: "b")
        menu.addItem(toggleItem)
        menu.addItem(NSMenuItem.separator())
        
        let platformMenu = NSMenuItem(title: "Target Platform: \(selectedPlatform.rawValue)", action: nil, keyEquivalent: "")
        platformMenu.image = NSImage(systemSymbolName: "gamecontroller", accessibilityDescription: nil)
        platformMenu.isEnabled = !isBoosterActive
        
        let platformSubmenu = NSMenu()
        for platform in CloudPlatform.allCases {
            let item = NSMenuItem(title: platform.rawValue, action: #selector(AppDelegate.setPlatform), keyEquivalent: "")
            item.state = (platform == selectedPlatform) ? .on : .off
            item.representedObject = platform
            platformSubmenu.addItem(item)
        }
        platformMenu.submenu = platformSubmenu
        menu.addItem(platformMenu)
        menu.addItem(NSMenuItem.separator())
        
        if isBoosterActive {
            menu.addItem(createInfoItem(title: "Status: Optimized (\(selectedPlatform.rawValue))", icon: "checkmark.shield.fill", color: .systemGreen))
            menu.addItem(NSMenuItem.separator())
            
            menu.addItem(createInfoItem(title: "AWDL Paused", icon: "wifi.slash"))
            menu.addItem(createInfoItem(title: "DNS Flushed", icon: "server.rack"))
            menu.addItem(createInfoItem(title: "RAM Purged", icon: "memorychip"))
            menu.addItem(createInfoItem(title: "CPU High Priority (\(selectedPlatform.processName))", icon: "cpu"))
            menu.addItem(createInfoItem(title: "Anti-Sleep Active", icon: "sun.max.fill"))
            
            menu.addItem(NSMenuItem.separator())
            menu.addItem(createMouseMenu())
        } else {
            menu.addItem(createInfoItem(title: "Status: Default", icon: "shield"))
        }
        
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        
        return menu
    }
    
    private func createMouseMenu() -> NSMenuItem {
        let mouseItem = NSMenuItem(title: "Mouse Profiles", action: nil, keyEquivalent: "")
        mouseItem.image = NSImage(systemSymbolName: "computermouse", accessibilityDescription: nil)
        
        let submenu = NSMenu()
        let fpsItem = NSMenuItem(title: MouseProfile.rawFPS.title, action: #selector(AppDelegate.setFPSMouse), keyEquivalent: "")
        let mobaItem = NSMenuItem(title: MouseProfile.fastMOBA.title, action: #selector(AppDelegate.setMOBAMouse), keyEquivalent: "")
        
        submenu.addItem(fpsItem)
        submenu.addItem(mobaItem)
        mouseItem.submenu = submenu
        
        return mouseItem
    }
    
    private func createInfoItem(title: String, icon: String, color: NSColor? = nil) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        item.isEnabled = false
        if let image = NSImage(systemSymbolName: icon, accessibilityDescription: nil) {
            let config = NSImage.SymbolConfiguration(paletteColors: [color ?? .labelColor])
            item.image = image.withSymbolConfiguration(config)
        }
        return item
    }
    
    func changePlatform(_ platform: CloudPlatform) {
        self.selectedPlatform = platform
        statusItem.menu = buildMenu()
    }
    
    func updateState(isActive: Bool) {
        self.isBoosterActive = isActive
        statusItem.menu = buildMenu()
        
        let iconName = isActive ? "gamecontroller.fill" : "gamecontroller"
        let config = NSImage.SymbolConfiguration(scale: .large)
        if let button = statusItem.button, let image = NSImage(systemSymbolName: iconName, accessibilityDescription: nil)?.withSymbolConfiguration(config) {
            image.isTemplate = true
            button.image = image
            button.contentTintColor = nil 
        }
    }
    
    func setLoading() {
        if let button = statusItem.button {
            let config = NSImage.SymbolConfiguration(scale: .large)
            if let image = NSImage(systemSymbolName: "hourglass.circle.fill", accessibilityDescription: nil)?.withSymbolConfiguration(config) {
                image.isTemplate = true
                button.image = image
            }
            button.contentTintColor = nil
        }
    }
}