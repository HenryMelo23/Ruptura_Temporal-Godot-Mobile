# Patch notes pendentes

Este arquivo acumula, em linguagem de jogador, o resumo das mudanças que devem entrar na próxima publicação.

Quando o pedido for algo como "liberar atualização na VPS, criar APK e EXE da versão x.x.x", usar este arquivo como base para montar as notas públicas da versão. Depois da publicação validada, limpar este arquivo e deixar somente o cabeçalho/processo para a próxima atualização.

## Próxima versão

### Estabilidade e manutenção

- Reorganizamos partes internas importantes do runtime para deixar o jogo mais estável e mais fácil de evoluir.
- O sistema de save/configuração foi separado do núcleo principal, preservando compatibilidade com saves existentes.
- A lógica de transição/progressão de fases foi isolada em um controlador dedicado, reduzindo risco de conflitos e regressões no arquivo principal.
- Parte da apresentação visual de ondas/bosses foi separada do núcleo de gameplay, mantendo o comportamento e o visual atuais.
- Adicionamos validações automatizadas cobrindo save/configuração, transição de fases, portais/fragmentos, multiplayer de transferência de fase, UMBRA/Fase 5 e Boss 1.

### Observação para release

- Antes de publicar, transformar estes itens em texto final de atualização para players.
- Após APK, EXE, relay/VPS e manifests públicos serem validados, mover o texto final para o changelog da versão e limpar esta seção.
