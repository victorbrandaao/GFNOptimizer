import AppKit

class UpdateManager {
    static let shared = UpdateManager()
    
    // Altere para o seu usuário e repositório exatos, se necessário
    private let repoAPI = "https://api.github.com/repos/victorbrandaao/GFNOptimizer/releases/latest"
    
    private init() {}
    
    func checkForUpdates(silent: Bool = true) {
        guard let url = URL(string: repoAPI) else { return }
        
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else {
                if !silent { self.showAlert(title: "Erro", message: "Não foi possível verificar atualizações.") }
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let tagName = json["tag_name"] as? String,
                   let htmlUrl = json["html_url"] as? String {
                    
                    let latestVersion = tagName.replacingOccurrences(of: "v", with: "")
                    let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.2.0"
                    
                    if latestVersion.compare(currentVersion, options: .numeric) == .orderedDescending {
                        DispatchQueue.main.async {
                            self.showUpdateAlert(latestVersion: latestVersion, releaseURL: htmlUrl)
                        }
                    } else if !silent {
                        DispatchQueue.main.async {
                            self.showAlert(title: "Atualizado", message: "Você já está usando a versão mais recente do GFN Booster (\(currentVersion)).")
                        }
                    }
                }
            } catch {
                print("Erro ao processar JSON: \(error)")
            }
        }
        task.resume()
    }
    
    private func showUpdateAlert(latestVersion: String, releaseURL: String) {
        let alert = NSAlert()
        alert.messageText = "Nova versão disponível!"
        alert.informativeText = "A versão \(latestVersion) do GFN Booster já está disponível. Você quer baixar agora?"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Baixar Atualização")
        alert.addButton(withTitle: "Depois")
        
        if alert.runModal() == .alertFirstButtonReturn {
            if let url = URL(string: releaseURL) {
                NSWorkspace.shared.open(url)
            }
        }
    }
    
    private func showAlert(title: String, message: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}