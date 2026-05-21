import AppKit

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    
    // Ícones da barra de menus usando SF Symbols
    let config = NSImage.SymbolConfiguration(scale: .large)
    lazy var offImage = NSImage(systemSymbolName: "gamecontroller", accessibilityDescription: nil)?.withSymbolConfiguration(config)
    lazy var onImage = NSImage(systemSymbolName: "gamecontroller.fill", accessibilityDescription: nil)?.withSymbolConfiguration(config)
    
    // Elementos dinâmicos do menu
    var mainActionItem: NSMenuItem!
    var statusTextItem: NSMenuItem!
    
    // Itens informativos das otimizações
    var optimTitle: NSMenuItem!
    var awdlItem: NSMenuItem!
    var dnsItem: NSMenuItem!
    var mouseItem: NSMenuItem!
    var tmItem: NSMenuItem!
    var sleepItem: NSMenuItem! // Nova otimização visual
    
    var isBoosterActive = false
    var caffeinateProcess: Process? // Monitora o processo anti-sono do Mac

    static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.setActivationPolicy(.accessory)
        app.run()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = offImage
        }
        setupMenu()
    }

    func setupMenu() {
        let menu = NSMenu()
        
        // 1. Botão Principal
        mainActionItem = NSMenuItem(title: "Ativar GFN Booster", action: #selector(toggleBooster), keyEquivalent: "b")
        mainActionItem.target = self
        menu.addItem(mainActionItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // 2. Status Geral
        statusTextItem = NSMenuItem(title: "Status: Padrão", action: nil, keyEquivalent: "")
        statusTextItem.isEnabled = false
        menu.addItem(statusTextItem)
        
        // 3. Área de Informações Expandida (Oculta por padrão)
        optimTitle = NSMenuItem(title: "Otimizações Ativas:", action: nil, keyEquivalent: "")
        optimTitle.isEnabled = false
        menu.addItem(optimTitle)
        
        awdlItem = createFeatureItem(title: "AirDrop / Handoff pausados", icon: "wifi.slash")
        menu.addItem(awdlItem)
        
        dnsItem = createFeatureItem(title: "Cache DNS limpo e refeito", icon: "server.rack")
        menu.addItem(dnsItem)
        
        mouseItem = createFeatureItem(title: "Aceleração de Mouse desativada (Raw)", icon: "cursorarrow.motionlines")
        menu.addItem(mouseItem)
        
        tmItem = createFeatureItem(title: "Time Machine pausado", icon: "clock.badge.xmark")
        menu.addItem(tmItem)
        
        sleepItem = createFeatureItem(title: "Prevenção de repouso ativa", icon: "sun.max.fill")
        menu.addItem(sleepItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // 4. Encerrar
        let quitItem = NSMenuItem(title: "Encerrar", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        quitItem.image = NSImage(systemSymbolName: "power", accessibilityDescription: nil)
        menu.addItem(quitItem)
        
        statusItem.menu = menu
        updateMenuUI()
    }

    func createFeatureItem(title: String, icon: String) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        item.isEnabled = false
        item.image = NSImage(systemSymbolName: icon, accessibilityDescription: nil)
        return item
    }

    @objc func toggleBooster() {
        if isBoosterActive {
            disableMode()
        } else {
            enableMode()
        }
    }

    func enableMode() {
        setLoadingState(true)
        
        DispatchQueue.global(qos: .userInitiated).async {
            let sudoCommands = [
                "ifconfig awdl0 down",
                "dscacheutil -flushcache",
                "killall -HUP mDNSResponder",
                "tmutil disable"
            ].joined(separator: "; ")
            
            self.runPrivileged(command: sudoCommands)
            self.runUnprivileged(command: "defaults write .GlobalPreferences com.apple.mouse.scaling -1")
            
            // Inicia o Caffeinate para impedir o Mac de dormir durante o jogo
            self.startCaffeinate()
            
            // Abre o GeForce NOW automaticamente
            self.runUnprivileged(command: "open -a \"GeForce NOW\"")
            
            DispatchQueue.main.async {
                self.isBoosterActive = true
                self.setLoadingState(false)
                self.updateMenuUI()
            }
        }
    }

    func disableMode() {
        setLoadingState(true)
        
        DispatchQueue.global(qos: .userInitiated).async {
            let sudoCommands = [
                "ifconfig awdl0 up",
                "tmutil enable"
            ].joined(separator: "; ")
            
            self.runPrivileged(command: sudoCommands)
            self.runUnprivileged(command: "defaults write .GlobalPreferences com.apple.mouse.scaling 1.5")
            
            // Para o processo de prevenção de repouso
            self.stopCaffeinate()
            
            DispatchQueue.main.async {
                self.isBoosterActive = false
                self.setLoadingState(false)
                self.updateMenuUI()
            }
        }
    }

    func startCaffeinate() {
        // Garante que não tem nenhum rodando antes
        stopCaffeinate()
        
        let process = Process()
        process.launchPath = "/usr/bin/caffeinate"
        process.arguments = ["-d", "-i"] // -d impede a tela de apagar, -i impede o sistema de hibernar
        process.launch()
        self.caffeinateProcess = process
    }
    
    func stopCaffeinate() {
        if let process = caffeinateProcess, process.isRunning {
            process.terminate()
            caffeinateProcess = nil
        }
    }

    func runPrivileged(command: String) {
        let script = "do shell script \"\(command)\" with administrator privileges"
        var error: NSDictionary?
        if let appleScript = NSAppleScript(source: script) {
            appleScript.executeAndReturnError(&error)
        }
    }
    
    func runUnprivileged(command: String) {
        let process = Process()
        process.launchPath = "/bin/sh"
        process.arguments = ["-c", command]
        process.launch()
        process.waitUntilExit()
    }

    func setLoadingState(_ isLoading: Bool) {
        guard let button = statusItem.button else { return }
        if isLoading {
            button.image = NSImage(systemSymbolName: "hourglass", accessibilityDescription: nil)
            mainActionItem.title = "Processando..."
            mainActionItem.isEnabled = false
        } else {
            mainActionItem.isEnabled = true
        }
    }
    
    func updateMenuUI() {
        guard let button = statusItem.button else { return }
        
        if isBoosterActive {
            button.image = onImage
            button.contentTintColor = NSColor.systemGreen
            
            mainActionItem.title = "Desativar GFN Booster"
            mainActionItem.image = NSImage(systemSymbolName: "bolt.slash.fill", accessibilityDescription: nil)
            
            statusTextItem.title = "Status: Otimizado para Jogos"
            statusTextItem.image = NSImage(systemSymbolName: "checkmark.shield.fill", accessibilityDescription: nil)
            
            optimTitle.isHidden = false
            awdlItem.isHidden = false
            dnsItem.isHidden = false
            mouseItem.isHidden = false
            tmItem.isHidden = false
            sleepItem.isHidden = false
            
        } else {
            button.image = offImage
            button.contentTintColor = nil
            
            mainActionItem.title = "Ativar GFN Booster"
            mainActionItem.image = NSImage(systemSymbolName: "bolt.fill", accessibilityDescription: nil)
            
            statusTextItem.title = "Status: Padrão da Apple"
            statusTextItem.image = NSImage(systemSymbolName: "shield", accessibilityDescription: nil)
            
            optimTitle.isHidden = true
            awdlItem.isHidden = true
            dnsItem.isHidden = true
            mouseItem.isHidden = true
            tmItem.isHidden = true
            sleepItem.isHidden = true
        }
    }

    @objc func quitApp() {
        if isBoosterActive {
            runPrivileged(command: "ifconfig awdl0 up; tmutil enable")
            runUnprivileged(command: "defaults write .GlobalPreferences com.apple.mouse.scaling 1.5")
            stopCaffeinate()
        }
        NSApplication.shared.terminate(nil)
    }
}