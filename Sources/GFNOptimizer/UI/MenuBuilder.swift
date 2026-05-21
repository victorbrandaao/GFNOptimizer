import AppKit

class MenuBuilder {
    private let statusItem: NSStatusItem
    private var isBoosterActive = false
    
    init(statusItem: NSStatusItem) {
        self.statusItem = statusItem
    }
    
    func buildMenu() -> NSMenu {
        let menu = NSMenu()
        
        let toggleItem = NSMenuItem(title: isBoosterActive ? "Disable GFN Booster" : "Enable GFN Booster", 
                                    action: #selector(AppDelegate.toggleBooster), 
                                    keyEquivalent: "b")
        menu.addItem(toggleItem)
        menu.addItem(NSMenuItem.separator())
        
        if isBoosterActive {
            menu.addItem(createInfoItem(title: "Status: Optimized", icon: "checkmark.shield.fill", color: .systemGreen))
            menu.addItem(NSMenuItem.separator())
            
            menu.addItem(createInfoItem(title: "AWDL Paused", icon: "wifi.slash"))
            menu.addItem(createInfoItem(title: "DNS Flushed", icon: "server.rack"))
            menu.addItem(createInfoItem(title: "RAM Purged", icon: "memorychip"))
            menu.addItem(createInfoItem(title: "CPU High Priority", icon: "cpu"))
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
    
    func updateState(isActive: Bool) {
        self.isBoosterActive = isActive
        statusItem.menu = buildMenu()
        
        let iconName = isActive ? "gamecontroller.fill" : "gamecontroller"
        let config = NSImage.SymbolConfiguration(scale: .large)
        if let button = statusItem.button, let image = NSImage(systemSymbolName: iconName, accessibilityDescription: nil)?.withSymbolConfiguration(config) {
            button.image = image
            button.contentTintColor = isActive ? .systemGreen : nil
        }
    }
    
    func setLoading() {
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "hourglass", accessibilityDescription: nil)
            button.contentTintColor = .systemYellow
        }
    }
}