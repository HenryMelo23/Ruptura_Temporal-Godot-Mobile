# Auditoria EV1 + EV2 — 13/10/2026

## Escopo e referência

- Branch auditada: `runtime-refactor-2.0.48`
- HEAD auditado: `f758b7434fa9d63c00aadb45df1ff95d1d34b2c8`
- A árvore de trabalho continha alterações independentes antes da auditoria. Este
  documento e `tests/manifest_evolution_persistence_contract_smoke.gd` são os
  únicos artefatos criados pela auditoria.
- Não houve alteração de mecânica, balanceamento ou protocolo de rede.

O contrato auditado guarda a escolha em
`manifest_evolution_state.choices[*].evolution`, não no identificador visual.
O estado é incluído pelo `RuntimeSaveController` no snapshot de run. O ledger
de eventos de combate é deliberadamente transitório: ele impede proc duplicado
em uma mesma run, mas não deve sobreviver a resume/retry.

## Matriz executada

| Cenário | Evidência reprodutível | Resultado |
| --- | --- | --- |
| Catálogo das 15 manifestações | `godot --headless --path . --script res://tests/manifest_evolution_catalog_smoke.gd` | PASS: 180 definições, 6 EV1 e 6 EV2 por manifestação. |
| Pares EV1 × EV2 | `godot --headless --path . --script res://tests/manifest_evolution_540_combinations_smoke.gd` | PASS: 540 pares. Há aviso de ObjectDB/recursos ao encerrar; não invalida o assert, mas merece limpeza no teste. |
| Resultado funcional de catálogo | `godot --headless --path . --script res://tests/manifest_evolution_functional_matrix_smoke.gd` | PASS: 180 definições/15 manifestações. |
| Ganchos reais de combate | `godot --headless --path . --script res://tests/manifest_evolution_combat_hooks_smoke.gd` | PASS: 15 manifestações; Lacerante, Acorrentada e Q válida da Necronada; deduplicação por evento/peer. |
| Seleção, resume, retry e bloqueio online | `godot --headless --path . --script res://tests/manifest_evolution_persistence_contract_smoke.gd` | PASS: um par EV1+EV2 restaura após resume e retry; multiplayer não persiste a run. |
| Barreira de seleção | `godot --headless --path . --script res://tests/multiplayer_manifest_evolution_barrier_smoke.gd` | PASS: host/cliente primeiro, simultâneo, três peers, duplicata, reorder, disconnect e nova barreira. |
| Gravitante: identidade VFX versus efeito | `godot --headless --path . --script res://tests/gravitante_vfx_contract_smoke.gd` | PASS: 36 pares; o teste separa cosmético de mecânica. |
| Prismática (alteração ainda não versionada nesta árvore) | `godot --headless --path . --script res://tests/prismatica_evolution_functional_smoke.gd` | PASS: 12 IDs, 36 pares, dano geométrico em boss e limite de formações. |

## Contratos confirmados

1. `_choose_manifest_evolution` grava a identidade canônica em `evolution` e
   mantém metadata de apresentação para tooltip; renderizadores não devem usar
   isso como prova de efeito mecânico.
2. O host é a fonte de verdade da barreira. Os prontos são associados ao peer
   elegível e mensagens repetidas não aumentam a contagem.
3. O dispatcher de combate usa um identificador de evento e peer/origem para
   impedir que uma mesma ocorrência processe uma evolução duas vezes.
4. `RuntimeSaveController` serializa `manifest_evolution_state`; saves online,
   dedicated e multiplayer continuam bloqueados pela política atual.
5. O reset de run/retry não deve restaurar o ledger de deduplicação transitório.

## Defeitos e lacunas rastreáveis

### EV-AUD-001 — impacto de projétil remoto perfurante não é resolvido

**Severidade:** alta para consistência visual remota e confirmação de impacto.

**Reprodução:**

```text
godot --headless --path . --script res://tests/multiplayer_network_smoothing_smoke.gd
```

Falha atual: `piercing remote projectile did not register its impact/ricochet`
na linha 214. O cenário cria um projétil Prismática remoto, perfurante, sobre
um inimigo e espera um impacto/ricochete visual. O caminho envolvido é
`MainRuntimeCore._update_remote_bullets` → `_apply_remote_projectile_visual_impact`.

**Limite desta auditoria:** não foi corrigido, pois corrigir replicação/dano
remoto exige uma alteração de mecânica/rede além de uma correção comprovada
isoladamente.

### EV-AUD-002 — smoke de VFX multiplayer não é executável isoladamente

**Severidade:** média, cobertura de integração ausente.

**Reprodução:**

```text
godot --headless --path . --script res://tests/multiplayer_ability_visual_smoke.gd
```

Falha atual: `[ ] invalid role`. O arquivo requer lançamento coordenado com
`--role=server|host|client`, mas não há runner de três processos no teste. Ele
não prova host/cliente reais no estado atual.

### EV-AUD-003 — contrato de trio de revive está divergente e o teste reporta
sucesso após erros

**Severidade:** alta para a confiabilidade da suíte, relação com EV indireta.

**Reprodução:**

```text
godot --headless --path . --script res://tests/multiplayer_three_player_contract_smoke.gd
```

O processo retorna falha para três asserts de sacrifício/altar, porém ainda
imprime uma mensagem `...SMOKE_OK`. Isso impede usar o smoke como prova de
eliminação/revive na matriz EV. A regra de revive foi alterada em trabalho
paralelo e precisa de decisão de produto antes de atualizar código ou oracle.

### EV-AUD-004 — cobertura visual, áudio e desempenho renderizado ainda não é
prova para os 180 IDs

**Severidade:** média, lacuna de validação.

`gravitante_vfx_performance_smoke.gd` depende de renderer (`frame_post_draw`) e
não finaliza em modo headless. Os smokes de catálogo confirmam definições,
tooltips de metadata e gatilhos, mas não equivalem a screenshot/áudio real para
cada uma das 180 escolhas. O teste Prismática confirma limites funcionais (e.g.
formações) e a Gravitante confirma seu contrato de VFX, porém é necessário um
playtest desktop/mobile LOW/MEMORY com captura para afirmar legibilidade,
áudio e frame-time de campos, correntes, orbitais, invocações e cadeias.

## Cobertura que ainda falta para aceite integral

- Executar `EV-AUD-001` após corrigir a resolução de impacto remoto e repetir
  em host + dois clientes com manifestações/evoluções diferentes.
- Criar um runner controlado para `EV-AUD-002`, introduzindo latência e
  reconexão, e capturar owner/atacante em dano, cura, debuff, invocação e VFX.
- Definir e alinhar o contrato de revive de `EV-AUD-003`; só então usar o
  cenário morte/revive como prova de reset EV.
- Rodar a varredura visual/áudio em renderer real, com LOW/MEMORY mobile e
  orçamento de entidades/frame time registrado.

## Resultado honesto

O contrato de seleção, persistência local, retry, deduplicação de ganchos e
barreira determinística está coberto pelos smokes listados. Não é correto
declarar ausência total de divergência em rede nem ausência de placebo visual:
o impacto remoto perfurante falha e não há ainda sessão automática de 2/3 peers
nem captura visual/áudio para os 180 IDs. Estes defeitos foram preservados aqui
como reprodutores, sem reescrever mecânicas durante a auditoria.
