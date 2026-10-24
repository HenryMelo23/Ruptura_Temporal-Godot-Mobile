# Quimera Adaptativa de Henry — contrato fechado

Escopo deste documento: congelar o contrato mínimo de arte, apresentação, progressão e sincronização da Quimera Adaptativa. Nesta tarefa não são criados PNGs, texture keys, estado de runtime ou efeitos de gameplay.

## 1. Base auditada

O loader vigente é `_load_textures()` em `scripts/main_runtime_core.gd`; a seleção local é `_henry_player_texture()`, a seleção remota é `_network_player_animation_snapshot()` + `_net_player_texture_for_state()`, e o desenho local/remoto está em `scripts/presentation/entities_presentation.gd`. O dono atual de entrada, ataque, habilidade, ultimate e Incandescência continua sendo `scripts/systems/abilities/henry_incendiary_ability_controller.gd`. A Quimera deverá ter controlador próprio; o controlador incendiário não deve absorver essa responsabilidade.

Todos os PNGs abaixo existem e foram inspecionados no tamanho nativo:

| PNG atual | Tamanho | Células autorais usadas | Texture keys/runtime |
|---|---:|---:|---|
| `assets/sprites/player/player_2_suit/henry_walk_sheet_v2.png` | 1280×768 | 15: 5 frente, 5 lado direito, 5 costas | `henry_down`, `henry_right`, `henry_up`: 5 cada |
| `assets/sprites/player/player_2_suit/henry_fire_sheet_v2.png` | 1280×2048 | 40: 8 direções × 5 | `henry_fire_<direção>`: 5 cada; `henry_fire_network`: 40 |
| `assets/sprites/player/player_2_suit/henry_basic_cast_sheet_v2.png` | 1280×2048 | 40: 8 direções × 5 | `henry_cast_<direção>`: 5 cada; primeiros 40 de `henry_cast_network` |
| `assets/sprites/player/player_2_suit/henry_ultimate_sheet_v1.png` | 2048×256 | 8 | `henry_ultimate`: 8; índices 40–47 de `henry_cast_network` |
| `assets/sprites/player/player_2_suit/henry_intro_sheet_v1.png` | 3072×256 | 12 | `henry_intro`: 12 |
| `assets/sprites/player/player_2_suit/henry_shop_entry_sheet_v1.png` | 2048×256 | 8 | `henry_shop_entry`: 8 |
| `assets/sprites/player/player_2_suit/henry_idle_pocket_sheet_v1.png` | 1280×256 | 5 | `henry_idle_pocket`: 5 |
| `assets/sprites/player/player_2_suit/henry_idle_beard_sheet_v2.png` | 512×256 | 2 | `henry_idle_beard`: 2 |
| `assets/sprites/player/player_2_suit/henry_frozen_sheet_v1.png` | 1774×887 | 2 recortes 576×840 em `(242,24)` e `(1012,24)` | `henry_frozen`: 2 |
| `assets/sprites/player/player_2_suit/player_2_suit_sheet_v3.png` | 1280×5120 | atlas-fonte 5×20 = 100 | não é carregado para a animação atual; permanece só como referência/fonte |

`henry_idle` não representa novas células: é um pool de 13 entradas composto pelas 5 de bolso e duas sequências `[bolso0, barba, barba, bolso0]`. Logo existem 7 células de idle autorais e 13 índices remotos. A grade comum usa células 256×256. O congelamento é a única exceção e não aceita os overlays 256×256 deste contrato.

Ordem local atual: entrada especial → congelado → entrada da loja → ultimate → habilidade básica → disparo → caminhada → idle. Para Henry, `NET_ANIM_DAMAGE` não tem atlas próprio e resolve para `henry_idle`; entrada temporal e entrada da loja não possuem estado remoto dedicado. Estados remotos válidos são idle, cima, baixo, lado, disparo 0–39, cast 0–39, ultimate 40–47 e congelado 0–1.

## 2. Assets novos: exatamente 28 overlays e 3 ícones

Os caminhos abaixo são o contrato das próximas tarefas. O diretório pai real é `assets/sprites/player/player_2_suit/`; `quimera/` e seus PNGs ainda não existem e só devem nascer na tarefa de arte.

| Asset planejado / texture key | Tamanho e matriz | Células |
|---|---:|---:|
| `quimera/henry_quimera_predatoria_overlay_v1.png` / `henry_quimera_predatoria_overlay` | 1536×512; 6×2 | 12 |
| `quimera/henry_quimera_estrutural_overlay_v1.png` / `henry_quimera_estrutural_overlay` | 768×512; 3×2 | 6 |
| `quimera/henry_quimera_anomala_overlay_v1.png` / `henry_quimera_anomala_overlay` | 768×512; 3×2 | 6 |
| `quimera/henry_quimera_sintese_overlay_v1.png` / `henry_quimera_sintese_overlay` | 1024×256; 4×1 | 4 |
| `quimera/icons/henry_quimera_predatoria_icon_v1.png` / `henry_quimera_predatoria_icon` | 64×64 | 1 ícone |
| `quimera/icons/henry_quimera_estrutural_icon_v1.png` / `henry_quimera_estrutural_icon` | 64×64 | 1 ícone |
| `quimera/icons/henry_quimera_anomala_icon_v1.png` / `henry_quimera_anomala_icon` | 64×64 | 1 ícone |

Matriz fechada:

- Predatória, linha 0 = marco 10; linha 1 = marco 25. Colunas `0–1 frente`, `2–3 lado`, `4–5 costas`; cada par é a oscilação A/B do órgão. Total 12.
- Estrutural, linha 0 = marco 10; linha 1 = marco 25. Colunas `0 frente`, `1 lado`, `2 costas`. Total 6.
- Anômala, linha 0 = marco 10; linha 1 = marco 25. Colunas `0 frente`, `1 lado`, `2 costas`. Total 6.
- Síntese, linha única `0–3`, uma animação de transformação de quatro quadros, 100 ms por quadro, tocada uma vez ao cruzar 50 tecidos totais. Total 4.
- Predatória alterna A/B pela paridade do frame-base informado pelo snapshot; Estrutural e Anômala são estáticas. Nenhum atlas duplica todos os frames corporais.

Formato: RGBA transparente, pixel art sem interpolação/mipmaps, sem sombra pintada, sem texto e sem VFX que ultrapasse a célula. Os ícones usam a mesma paleta da família e continuam legíveis a 24 px.

## 3. Alinhamento, direção e camadas

- Eixo corporal: `x = 128`. Pivô autoral para composição/espelhamento: `(128,128)`; ground anchor autoral: `(128,256)` em toda célula 256×256. O conteúdo não deve redefinir o chão por seu alpha; o frame da loja já aceita base visível entre `y=245` e `255`.
- O runtime atual ancora o fim do canvas em `player_pos + (0,40)`. O overlay deve reutilizar exatamente o `Rect2`, rotação, modulate e escala usados pelo corpo; não deve calcular um segundo pivô. Assim também acompanha a diferença já existente entre Henry local (altura preservada de 88 px) e o retângulo remoto.
- Buckets: `frente = idle, down, south, southeast, southwest, loja e ultimate`; `lado = right, east, west`; `costas = up, north, northeast, northwest`. Vetor nulo conserva o último bucket válido; sem histórico, usa frente.
- Espelhamento: caminhada/idle herdam `body_flip_h`; ataques/casts usam arte de overlay voltada à direita e espelham somente `west`, `southwest` e `northwest`, mesmo que o corpo use seu frame oeste autoral sem flip. Frente/costas retas e a síntese nunca espelham.
- Offsets, em pixels do canvas antes da escala: idle `0,0`; caminhada `0,0`; disparo `0,0`; cast `0,0`; ultimate `0,0`; loja `0,0`; dano/fallback idle `0,0`. Entrada temporal, congelado, morto/eliminado e fantasma não desenham overlays. Qualquer correção futura deve alterar uma tabela central por estado, nunca o PNG nem números dispersos.
- Ordem fixa: sombra atual → VFX traseiro procedural → corpo de Henry → Estrutural → Predatória → Anômala → Síntese → telegraphs/status/UI. Partes que exigiriam passar atrás do corpo ficam fora dos PNGs; podem virar VFX traseiro procedural sem aumentar as 28 células.

## 4. Progressão 10/25/50

Cada abate elegível creditado a Henry concede **1 tecido** da família do inimigo. Há três contadores inteiros independentes (`predatoria`, `estrutural`, `anomala`), nunca negativos e sem teto.

- 10 em uma família: desbloqueia o órgão I e a linha visual do marco 10 daquela família.
- 25 em uma família: substitui o órgão I pelo órgão II e usa a linha visual do marco 25.
- 50 tecidos totais: desbloqueia `sintese_desperta` uma única vez por run e toca os quatro frames. Os contadores continuam subindo; 50 não é cap.

A família dominante é a de maior contador. Em empate, conserva a dominante anterior; se ainda não houver uma, a precedência determinística é Predatória → Estrutural → Anômala. Estágios visuais e `sintese_desperta` são derivados dos contadores; não constituem uma segunda fonte de verdade. Valores de dano, cura, defesa, cooldown e a habilidade final não são definidos neste contrato visual/estrutural.

## 5. Classificação inicial real

Fonte dos IDs: constantes `ENEMY_*` em `scripts/main_runtime_state.gd`. Esta tabela é fechada para a primeira implementação; classificação ausente não concede tecido e deve registrar aviso de desenvolvimento, sem escolher família aleatoriamente.

| Família | IDs elegíveis (+1) |
|---|---|
| Predatória | `comum`, `kamikaze`, `aglomerador`, `espreitador`, `larapio`, `devoto_febril`, `flagelante`, `lodario`, `sanguessuga_cronal`, `cinerido`, `carapaca_brasa_pangoliro`, `fuligarra_corvol` |
| Estrutural | `cristalizador`, `curater`, `escudeiro_refletor`, `guardiao_sucata`, `portador_relicario`, `pustula_fossil`, `suturador_ambar` |
| Anômala | `atirador`, `projetador`, `cout_attack_speed`, `incensario`, `salmodiante`, `pinguim_incendiario`, `sineiro_boreal`, `cartografo_vazio`, `cronofago`, `refrator_hostil`, `tecelao_vetorial`, `eco_entropico`, `enguia_miasma` |

`sutura_ambar_node` é auxiliar e concede zero. Arauto, bosses, hazards, invocações sem `ENEMY_*` e mortes sem crédito válido concedem zero nesta versão; seus valores exigem balanceamento separado. Um UID inimigo só pode conceder tecido uma vez, inclusive com burn/status tardio ou pacote repetido.

## 6. Autoridade, rede, save e reset

- Single-player: a simulação local é autoridade. Multiplayer: host/servidor decide crédito do abate, família, incremento, cruzamento de marco e dominante para cada peer Henry. Cliente nunca envia contador nem aplica marco por conta própria.
- Estado canônico futuro: `henry_quimera_schema_version` e `henry_quimera_state_by_peer`, contendo por peer apenas os três contadores, dominante e o latch `sintese_desperta`. Em solo usa a chave estável `local`. Revisões recebidas são monotônicas e idempotentes; snapshot atrasado não regride contadores.
- Não ampliar nem reinterpretar o stride fixo de `RTVisualSyncContract.pack_player_visual`. A Quimera deve usar extensão/snapshot versionado próprio e compacto; clientes derivam estágio e célula visual do estado recebido.
- Interrupção e retry solo: incluir os dois campos canônicos na lista explícita de `scripts/systems/save/runtime_save_controller.gd`. Load ausente migra para zero; contadores são saneados para inteiros `>= 0`; estágios são recalculados. Timers puramente visuais não são salvos.
- O estado persiste entre fases, loja, pausa, morte/revive e reconexão ao mesmo lobby (rehidratação pelo host). Reseta ao iniciar nova run, abandonar para o menu, encerrar a run, trocar o personagem da run ou remover definitivamente o peer. Mudança de fase/loja jamais chama reset.
- O futuro controlador da Quimera deve possuir `reset_run_state`, `snapshot_for_peer`, `apply_authoritative_snapshot` e o dedupe de UID. `scripts/main_runtime_core.gd` permanece fachada fina; o controlador incendiário mantém seus resets atuais intactos.

## 7. Critérios de aceite das próximas tarefas

1. Os quatro atlas carregam nas dimensões/matrizes acima, somam exatamente 28 células e expõem as quatro texture keys; os três ícones carregam 64×64. Nenhum load ocorre por frame.
2. Teste de contrato cobre contagem 9→10, 24→25 e total 49→50, repetição do mesmo UID, empate dominante, contador acima de 50, ID desconhecido, node/boss/hazard e reset/persistência.
3. Save interrompido e retry restauram exatamente os contadores; nova run zera; transição de fase/loja e revive preservam.
4. Host e cliente convergem após snapshot repetido e fora de ordem. Cliente não consegue conceder tecido. Entrada tardia/reconexão recebe o estado completo.
5. QA visual cobre local e remoto em frente/lado/costas, esquerda espelhada, idle, caminhada, disparo, cast, ultimate, loja, dano-fallback, congelado e morte, em 1280×720 e 800×450. Overlays não deslizam do ground anchor nem aparecem nos estados ocultos.
6. Testes existentes de Henry continuam verdes, em especial `tests/henry_incendiary_smoke.gd`, `tests/henry_incendiary_visual_smoke.gd` e `tests/henry_frozen_visual_smoke.gd`; o pool remoto continua 13/40/48/2.
7. Custo visual é O(1) por Henry (máximo três overlays persistentes e um one-shot), sem duplicar atlas corporais e sem alterar o contrato de animação remota atual.

## 8. Fora de escopo

Arte final, geração dos 28 overlays/ícones, implementação de loader/controlador/UI/gameplay, números de balanceamento dos órgãos, habilidade/ultimate da Síntese, áudio, novos inimigos, recompensas de Arauto/boss, alterações no corpo-base de Henry e mudanças nos pacotes atuais. Este documento também não corrige a diferença de dimensionamento local/remoto já existente; ele exige apenas que os overlays herdem o retângulo real do corpo em cada caminho.
