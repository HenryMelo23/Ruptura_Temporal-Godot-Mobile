# Evidências da correção do simulador/percepção

Registro de 16/11/2026. Implementação e limitações:
[`../../UMBRA_SIMULATOR_PERCEPTION_V3.md`](../../UMBRA_SIMULATOR_PERCEPTION_V3.md).
Estes dados validam o ambiente, sem medir aprendizado de uma policy.

| Verificação | Resultado |
| --- | --- |
| Checks do ambiente | 47 passaram |
| Categorias de ameaça | 11 com sinal; ameaça desconhecida recusada |
| Replay | 96 transições completas idênticas |
| Ticks de simulação no rollout | 960 a 60 Hz |
| Dano no jogador no rollout | 798 |
| Dano na Umbra no rollout | 1686,2854 |
| Ações executadas no rollout | 9, seguindo a cadência real |
| Cadência sob 120 solicitações em 2 s | 1 ação executada |
| Eco em caso controlado | Sem dano antecipado; 465 de dano após aviso |
| Plasma em caso controlado | Movimento e colisão; 417 de dano |
| Comando espacial | Miasma criado nas coordenadas solicitadas |
| Modelos de produção | Schema/inferência/paridade v2 passaram |
| Parse focado | 7 GDScripts passaram |
| Cena principal | Smoke de 120 frames passou |
| Treinamento por gradiente | Não executado; PyTorch ausente |

`protocol/` contém o pedido e as duas respostas completas. O teste compara
todos os campos das transições, incluindo dano, percepção e comandos, não
apenas scores resumidos. O caso usa oponente programado, manifestação
elétrica, seed 731 e limite de 96 passos. `step_seconds=0.16` é quantizado
para dez ticks de 1/60 s (0,16666… s), registrado no sumário.

`curriculum/` preserva um caso de treino e um held-out. O smoke verifica
separação entre splits, limites de shaping, espera obrigatória e cálculo
de retorno com/sem bootstrap. Isso não é avaliação de generalização de
um modelo treinado. `environment.json` e `environment.log` descrevem os
casos controlados de percepção, atraso, colisões e contratos.

`source_manifest.json` identifica o commit, a versão do Godot, as fontes
utilizadas e o hash da base de produção, que permaneceu intacta. A árvore
possuía alterações anteriores à tarefa; o commit sozinho não representa
todas essas fontes. Os testes devem ser reproduzidos com os hashes e as
alterações correspondentes, sem supor que o checkout do commit seja idêntico.

O validador profundo **não passou**: `deep_validation_blocked.log` registra
o bloqueio dos listeners TCP do editor na importação. Ele não chegou à
etapa profunda de parse de todos os scripts. O orçamento arquitetural
também permanece com falhas preexistentes, preservadas no log. Esses
resultados não foram convertidos em sucesso por causa dos testes focados.

Não foram executados treino PPO, inferência do checkpoint Python do Apolo,
integração VPS, Android, sessões multiplayer, teste de percepção limitada
ao visível ou atribuição causal por instância de ameaça. Os IDs de ameaça
nos eventos de dano continuam explicitamente não resolvidos.

A tentativa de atualizar o backlog em `.agents/` foi recusada automaticamente
por proteção de caminho. A anotação está em
[`../../UMBRA_MULTIPLAYER_DEFERRED_SIMULATOR_V3.md`](../../UMBRA_MULTIPLAYER_DEFERRED_SIMULATOR_V3.md).

`SHA256SUMS.json` cobre os arquivos de evidência, excluindo este README e o
próprio índice. As instruções de reprodução estão no documento da implementação.
