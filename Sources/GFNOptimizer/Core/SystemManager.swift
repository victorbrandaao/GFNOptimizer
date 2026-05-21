import Foundation

class SystemManager {
    static let shared = SystemManager()
    private var caffeinateProcess: Process?
    
    private init() {}

    func enableGamingMode(completion: @escaping () -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            self.startCaffeinate()
            
            // Abre pelo Bundle ID oficial do aplicativo (Infalível, ignora o nome do arquivo)
            let openProcess = Process()
            openProcess.launchPath = "/bin/sh"
            openProcess.arguments = ["-c", "open -b com.nvidia.gfnpc.mac || open -a GeForceNOW"]
            openProcess.launch()
            
            // Aguarda 4 segundos para o aplicativo carregar na tela
            Thread.sleep(forTimeInterval: 4.0)
            
            // Roda os comandos de baixo nível (este bloco pedirá a senha)
            let enableScript = """
            ifconfig awdl0 down; \
            dscacheutil -flushcache; \
            killall -HUP mDNSResponder; \
            tmutil disable; \
            purge; \
            GFN_PID=$(pgrep -x "NVIDIA GeForce NOW" | head -n 1); \
            if [ ! -z "$GFN_PID" ]; then renice -20 -p $GFN_PID; fi
            """
            
            self.executePrivileged(enableScript)
            DispatchQueue.main.async { completion() }
        }
    }

    func disableGamingMode(completion: @escaping () -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            let disableScript = "ifconfig awdl0 up; tmutil enable"
            self.executePrivileged(disableScript)
            self.stopCaffeinate()
            MouseManager.apply(profile: .defaultMac)
            DispatchQueue.main.async { completion() }
        }
    }

    private func startCaffeinate() {
        stopCaffeinate()
        let process = Process()
        process.launchPath = "/usr/bin/caffeinate"
        process.arguments = ["-d", "-i"]
        process.launch()
        caffeinateProcess = process
    }
    
    private func stopCaffeinate() {
        if let process = caffeinateProcess, process.isRunning {
            process.terminate()
            caffeinateProcess = nil
        }
    }

    private func executePrivileged(_ command: String) {
        let script = "do shell script \"\(command)\" with administrator privileges"
        var error: NSDictionary?
        if let appleScript = NSAppleScript(source: script) {
            appleScript.executeAndReturnError(&error)
        }
    }
}