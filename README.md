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
git clone [https://github.com/seu-usuario/GFNOptimizer.git](https://github.com/seu-usuario/GFNOptimizer.git)
cd GFNOptimizer
swift run


Requisitos
macOS 12.0 ou superior.
Swift 5.9+.
Desenvolvido para a comunidade de cloud gaming no Mac. Sinta-se à vontade para abrir Issues ou enviar Pull Requests.