# GFN Booster (macOS)

A native, open-source macOS menu bar utility built in Swift, designed to eliminate ping spikes, stuttering, and optimize your system for stable GeForce NOW cloud gaming sessions.

![GFN Booster in Action](assets/preview.png)

## The Problem
Mac users relying on cloud gaming often experience random micro-stutters and sudden latency spikes, even on flawless fiber connections. In the Apple ecosystem, this is primarily caused by background routines:
1. **AWDL (Apple Wireless Direct Link):** The network interface managing AirDrop, Handoff, and AirPlay constantly scans for nearby devices. While unnoticeable during regular browsing, it completely ruins the strict latency required for game streaming.
2. **Location Services:** The system periodically scans Wi-Fi networks to update the Mac's location, causing network drops.
3. **Mouse Acceleration:** macOS forces a native pointer acceleration curve that ruins muscle memory and precision in FPS games or fast-paced clicking.
4. **Power & Backup Routines:** Time Machine performing heavy I/O network backups or the display dimming/sleeping while you use a controller.

## How it Works (Complete Transparency)
As an open-source project running system-level commands, transparency is key. When you click **"Enable GFN Booster"**, the app asks for Administrator privileges **only once** to group and execute the following optimizations:

* **Clean Network:** Temporarily disables the AWDL interface (`ifconfig awdl0 down`).
* **Direct Routing:** Flushes and rebuilds the system's DNS cache (`dscacheutil -flushcache; killall -HUP mDNSResponder`).
* **Raw Mouse Input:** Changes the mouse scaling factor to `-1` (`defaults write .GlobalPreferences com.apple.mouse.scaling -1`), ensuring raw input for precise aiming.
* **Bandwidth Focus:** Pauses Time Machine backups during the session (`tmutil disable`).
* **Console Mode (Anti-Sleep):** Starts the native `caffeinate` background process to prevent the display from sleeping or the CPU from throttling due to keyboard/mouse "inactivity" when playing with a controller.
* **Auto-Launch:** Automatically opens the official **GeForce NOW** application right after applying the optimizations.

### Fail-Safe (Security)
Whenever you click **"Disable GFN Booster"** or simply **"Quit"** the app, it automatically reverts absolutely every change. It restores the default mouse speed (`1.5`), reactivates AirDrop/Handoff (`ifconfig awdl0 up`), enables Time Machine, and hands power management back to macOS.

## Project Structure
To compile and run from the source code:

```bash
# Clone the repository
git clone [https://github.com/your-username/GFNOptimizer.git](https://github.com/your-username/GFNOptimizer.git)
cd GFNOptimizer

# Build and run via Swift Package Manager
swift run

Requirements
macOS 12.0 or newer.
Swift 5.9+.
Developed independently for the Mac cloud gaming community. Feel free to open Issues or submit Pull Requests!





---

### README.md (Versão em Português)

```markdown
# GFN Booster (macOS)

Um utilitário nativo e open-source para a barra de menus do macOS desenvolvido em Swift, focado em eliminar *ping spikes* (saltos de latência) e otimizar o sistema para sessões estáveis no GeForce NOW.

![GFN Booster em Ação](assets/preview.png)

## O Problema que ele resolve
Quem joga via cloud gaming no Mac frequentemente sofre com pequenos engasgos (*stuttering*) e picos de latência repentinos, mesmo em conexões de fibra excelentes. No ecossistema Apple, isso é causado principalmente por rotinas em segundo plano:
1. **AWDL (Apple Wireless Direct Link):** A interface de rede que gerencia AirDrop, Handoff e AirPlay faz varreduras de Wi-Fi constantes. Para navegação comum é imperceptível; para stream de jogos, que exige latência cravada, é fatal.
2. **Serviços de Localização:** O sistema escaneia redes próximas periodicamente para triangular a posição do Mac.
3. **Aceleração do Mouse:** O macOS impõe uma curva de aceleração de ponteiro nativa que prejudica a precisão em jogos de tiro (FPS) ou cliques rápidos.
4. **Rotinas de Energia e Backup:** Backups automáticos em segundo plano e telas apagando por inatividade no meio de cutscenes usando controle.

## Como o App Funciona (Transparência)
Como um bom projeto open-source que roda comandos de sistema, a transparência é total. Ao clicar em **"Ativar GFN Booster"**, o app solicita privilégios de administrador **uma única vez** para agrupar e executar as seguintes otimizações:

* **Rede Limpa:** Desativa temporariamente a interface AWDL (`ifconfig awdl0 down`).
* **Rotas Diretas:** Limpa e refaz o cache de DNS do sistema (`dscacheutil -flushcache; killall -HUP mDNSResponder`).
* **Performance Crua do Mouse:** Altera o fator de escala do mouse para `-1` (`defaults write .GlobalPreferences com.apple.mouse.scaling -1`), garantindo leitura direta (*raw input*) ideal para jogos.
* **Foco Total de Banda:** Pausa backups do Time Machine durante o jogo (`tmutil disable`).
* **Modo Console (Anti-Sleep):** Inicia o processo nativo `caffeinate` em background para impedir que a tela apague ou o Mac reduza o clock por "inatividade".
* **Auto-Launch:** Abre o aplicativo oficial do **GeForce NOW** imediatamente após aplicar as correções.

### Fail-Safe (Segurança)
Ao clicar em **"Desativar GFN Booster"** ou simplesmente **"Encerrar"** o aplicativo, ele desfaz absolutamente todas as alterações automaticamente, trazendo o mouse à velocidade padrão (`1.5`), reativando o AirDrop/Handoff (`ifconfig awdl0 up`), liberando o Time Machine e devolvendo o controle de energia nativo do macOS.

## Estrutura do Projeto
Para compilar e rodar a partir do código-fonte:

```bash
# Clone o repositório
git clone [https://github.com/seu-usuario/GFNOptimizer.git](https://github.com/seu-usuario/GFNOptimizer.git)
cd GFNOptimizer

# Execute o projeto via Swift Package Manager
swift run

Requisitos
macOS 12.0 ou superior.
Swift 5.9+.
Desenvolvido de forma independente para a comunidade de cloud gaming no Mac. Sinta-se à vontade para abrir Issues ou enviar Pull Requests.