# Henry — entrada temporal e fogo

Implementado na branch `runtime-refactor-2.0.48`, sobre HEAD `c4eee47` e o trabalho local existente. Sem commit/publicação nesta tarefa.

## Comportamento

- Início: 1,2 s de caminhada errante dos inimigos, seguidos de 0,65 s de desaceleração suave. Usa inimigos/spawn existentes, com posições limitadas à arena; não dispara ataques ou recompensas nessa apresentação.
- Mundo congelado durante os 3,15 s da animação existente do Henry. O filtro azul é desenhado sobre o mundo e antes do Henry/HUD. Retorna ao combate após o último frame. Duração total: 5 s.
- A simulação de combate e seu relógio não avançam durante a entrada. Não usa `Engine.time_scale`, mantendo comunicação e UI vivas.
- Multiplayer: autoridade controla movimento, tempo e liberação. A chave aditiva `henry_entrance` (`active`, `elapsed`, `peers`) viaja no snapshot visual de mundo existente. Não há novo RPC ou partículas sincronizadas. Cliente interpola apenas a apresentação e nunca se libera pelo próprio cronômetro. Release é repetido pelos snapshots; pacotes atrasados não reabrem uma entrada concluída.
- Henry de qualquer participante ativa a apresentação compartilhada; Geovana não vira Henry. O desenho remoto reutiliza os mesmos frames e ajuste de proporções da entrada local.
- Menu, mudança de fase, morte, boss e início de nova run limpam a sequência. Remoção autoritativa do último Henry desconectado encerra a sequência. Resume/retry não reiniciam a apresentação; o trecho transitório não é salvo.
- Q bloqueia deslocamento e ações concorrentes por 1 s. Dano continua no instante de 0,46 s, com alcance/queimação originais. E mantém os 800 ms existentes e raio de 280 px. Nenhum balanceamento de dano/cooldown foi alterado.

## VFX e custo

`henry_fire_presentation.gd` desenha línguas de fogo em camadas, núcleo quente, bordas vermelhas, movimento, brasas e dissipação. Não desenha contorno triangular do alcance. Q, carga de E e onda de E usam o mesmo renderer para local/remoto.

Cache fixo de oito malhas pré-trianguladas. Zero nós de partículas, sem cópia da tela, blur ou render target adicional em gameplay. Modo leve reduz línguas/brasas, mantendo a forma do efeito.

Benchmark isolado, Intel Graphics RPL-P / Vulkan Mobile / Godot 4.7.2, 100 amostras após aquecimento, Q+carga+onda simultâneos:

| Perfil | CPU média | CPU P95 |
| --- | ---: | ---: |
| Completo | 238,58 µs | 358 µs |
| Leve | 67,67 µs | 107 µs |

Mede somente submissão dos desenhos na CPU. Não é tempo de GPU, FPS de gameplay nem benchmark Android. Capturas de tela também não são benchmarks de FPS.

## Arquivos

- `scripts/systems/abilities/henry_incendiary_ability_controller.gd`: lifecycle/cronograma, seleção dos Henrys, estado autoritativo e lock no lançamento.
- `scripts/main_runtime_core.gd`: integração mínima de início/update/lock/remoção de peer.
- `scripts/systems/online/runtime_boss_visual_sync_controller.gd`: snapshot aditivo e recepção.
- `scripts/systems/save/runtime_save_controller.gd`: evita persistir a entrada transitória, sem alterar schema.
- `scripts/presentation/henry_fire_presentation.gd`: novo renderer específico.
- `scripts/presentation/combat_effects_presentation.gd`: delegação dos efeitos e ordem do filtro.
- `scripts/presentation/entities_presentation.gd`: reutilização da pose local/remota e desenho do Henry após filtro.
- Testes novos: `henry_cinematic_fire_smoke.gd`, `henry_entrance_transport_smoke.gd`, `henry_fire_visual_smoke.gd`, `henry_fire_budget_smoke.gd`.
- Fixtures existentes ajustadas: `henry_incendiary_smoke.gd`, `henry_incendiary_visual_smoke.gd`.
- Codemap/índice e `PATCH_NOTES_PENDING.md` atualizados.

## Testes executados

```sh
godot4 --headless --path . --script tests/henry_cinematic_fire_smoke.gd
godot4 --headless --path . --script tests/henry_incendiary_smoke.gd
godot4 --path . --audio-driver Dummy --script tests/henry_incendiary_visual_smoke.gd
godot4 --path . --audio-driver Dummy --script tests/henry_fire_visual_smoke.gd
godot4 --path . --audio-driver Dummy --disable-vsync --script tests/henry_fire_budget_smoke.gd
bash tools/validate_godot.sh --frames 60 --scene res://scenes/Main.tscn
```

PASS: caminhada/desaceleração/freeze, controles, frame de impacto, Q+tentativa de dash/E, retorno do movimento, snapshots dupla/trio, release obrigatório da autoridade, stale/duplicação, saída, disconnect via handler e resume/retry. Regressão Henry mantém burn, dano perto/longe, escala de frames e idempotência visual. Capturas conferidas em `.codex/henry_fire/`, com dimensões exatas 1280×720/960×540.

Transporte real local: rodar cada papel em um processo, com a mesma porta livre e diferente da usada antes (os marcadores são isolados por porta). Trio executado na porta 4675:

```sh
godot4 --headless --path . --script tests/henry_entrance_transport_smoke.gd -- --role=server --port=4675 --party=3
godot4 --headless --path . --script tests/henry_entrance_transport_smoke.gd -- --role=host --port=4675 --party=3
godot4 --headless --path . --script tests/henry_entrance_transport_smoke.gd -- --role=client --client-index=1 --port=4675 --party=3
godot4 --headless --path . --script tests/henry_entrance_transport_smoke.gd -- --role=client --client-index=2 --port=4675 --party=3
```

PASS: relay, host Geovana e dois clientes (Henry/Geovana), freeze dos cinco inimigos na autoridade, relógio de combate parado e liberação recebida por ambos os clientes no snapshot 147. Dupla também passou antes, porta 4674, release no snapshot 148.

Regressão adicional: `multiplayer_ability_visual_smoke.gd` em três processos `--role=server`, `--role=host`, `--role=client`, porta 4673. PASS: transporte de Q/E/TP das 15 manifestações, remoção de projétil e relay sem instanciação de gameplay. Ping mínimo local observado: host 16 ms, cliente 33 ms; não representa Internet móvel.

## Limites / falha fora do escopo

A validação normal de importação/inicialização passou. A validação `--deep` foi executada, mas parou ao analisar `tests/bargain_capsule_visual_smoke.gd`, que ainda acessa constantes antigas como `BargainCapsulePresentation.HIT_REACTION`; a apresentação atual usa carregamento lazy e `HIT_REACTION_PATH`. Nenhum desses dois arquivos foi alterado nesta tarefa. Não declarar a suíte completa verde.

Não houve teste em Android físico, Internet/VPS, perda de pacotes artificial, reconnect real ou partida longa. Trio/dupla foram testados em processos locais; stale/duplicação e remoção do peer também têm teste determinístico. Uma execução inicial do smoke de lifecycle apresentou avisos de recursos ao encerrar; a repetição final com `--verbose` passou sem esses avisos.
