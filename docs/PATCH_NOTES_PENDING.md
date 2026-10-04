# Patch notes pendentes

Este arquivo acumula, em linguagem de jogador, o resumo das mudanças que devem entrar na próxima publicação.

Quando o pedido for algo como "liberar atualização na VPS, criar APK e EXE da versão x.x.x", usar este arquivo como base para montar as notas públicas da versão. Depois da publicação validada, limpar este arquivo e deixar somente o cabeçalho/processo para a próxima atualização.

## Próxima versão

### Estabilidade e manutenção

- Unificamos a base de desenvolvimento com a versão de segurança para preservar mapas, efeitos da Gravitante, evoluções e melhorias já existentes no jogo.
- Corrigimos a leitura do cache local de progresso após reiniciar, mantendo compatibilidade com o cache anterior e a sincronização com o servidor.
- Garantimos que os rerolls pagos, os bônus de atributos de Queimar e as escolhas de evolução sejam preservados ao retomar uma run ou usar retry.
- Reorganizamos partes internas importantes do runtime para deixar o jogo mais estável e mais fácil de evoluir.
- O sistema de save/configuração foi separado do núcleo principal, preservando compatibilidade com saves existentes.
- A lógica de transição/progressão de fases foi isolada em um controlador dedicado, reduzindo risco de conflitos e regressões no arquivo principal.
- Reorganizamos internamente progressão de run, pontuação, recompensas e economia da loja para reduzir risco de bugs em compras, score e multiplayer.
- Parte da apresentação visual de ondas/bosses foi separada do núcleo de gameplay, mantendo o comportamento e o visual atuais.
- Adicionamos validações automatizadas cobrindo save/configuração, transição de fases, portais/fragmentos, multiplayer de transferência de fase, economia/loja, score multiplayer, UMBRA/Fase 5 e Boss 1.

### Balanceamento de runs longas

- Ajustamos a fantasia de poder em runs longas para manter a construção entre 0–15 min, acelerar entre 15–30 min e deixar builds boas realmente fortes por volta de 40–45 min.
- A economia late-game agora entrega mais recompensa por inimigo depois da ruptura, ajudando builds avançadas a comprarem mais cartas sem mudar o começo da run.
- O perigo de 40+ min foi deslocado mais para densidade e ritmo de spawn, em vez de transformar todos os inimigos em esponjas de HP.
- O crescimento de HP dos inimigos por abate passa a aliviar gradualmente depois dos 30 min, preservando dano, bosses, padrões e hits relevantes.
- Adicionamos smoke test específico para os marcos de 15, 30, 45 e 60 min, cobrindo economia, densidade, ritmo de spawn e taper de HP.

### Observação para release

- Antes de publicar, transformar estes itens em texto final de atualização para players.
- Após APK, EXE, relay/VPS e manifests públicos serem validados, mover o texto final para o changelog da versão e limpar esta seção.
