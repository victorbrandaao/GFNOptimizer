import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var menuBuilder: MenuBuilder!
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        menuBuilder = MenuBuilder(statusItem: statusItem)
        menuBuilder.updateState(isActive: false)
        
        // Checa atualizações silenciosamente em segundo plano ao abrir
        UpdateManager.shared.checkForUpdates(silent: true)
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
    
    @objc func checkUpdatesManual() {
        UpdateManager.shared.checkForUpdates(silent: false)
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        SystemManager.shared.disableGamingMode {}
    }
}