import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var menuBuilder: MenuBuilder!
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        menuBuilder = MenuBuilder(statusItem: statusItem)
        menuBuilder.updateState(isActive: false)
    }
    
    @objc func toggleBooster() {
        menuBuilder.setLoading()
        
        if let button = statusItem.button, button.contentTintColor == .systemGreen {
            SystemManager.shared.disableGamingMode {
                self.menuBuilder.updateState(isActive: false)
            }
        } else {
            SystemManager.shared.enableGamingMode {
                MouseManager.apply(profile: .rawFPS) // Default to FPS when activated
                self.menuBuilder.updateState(isActive: true)
            }
        }
    }
    
    @objc func setFPSMouse() { MouseManager.apply(profile: .rawFPS) }
    @objc func setMOBAMouse() { MouseManager.apply(profile: .fastMOBA) }
    
    func applicationWillTerminate(_ notification: Notification) {
        SystemManager.shared.disableGamingMode {}
    }
}