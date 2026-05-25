import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var menuBuilder: MenuBuilder!
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        menuBuilder = MenuBuilder(statusItem: statusItem)
        menuBuilder.updateState(isActive: false)
        
        UpdateManager.shared.checkForUpdates(silent: true)
    }
    
    @objc func toggleBooster() {
        menuBuilder.setLoading()
        
        if menuBuilder.isBoosterActive {
            SystemManager.shared.disableGamingMode {
                self.menuBuilder.updateState(isActive: false)
            }
        } else {
            SystemManager.shared.enableGamingMode {
                MouseManager.apply(profile: .rawFPS)
                self.menuBuilder.updateState(isActive: true)
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
}