# Manifestacoes removidas

Levantamento feito em 2026-11-04, antes de alterar o roster ou o runtime. A
fonte oficial encontrada foi `MANIFESTATIONS`, em
`scripts/main_runtime_state.gd`, complementada por
`MANIFESTATION_UNLOCK_RULES`, pelo catalogo em `scripts/catalog/` e pelas telas
de selecao em `scripts/presentation/menus_presentation.gd`.

## Roster confirmado

O roster anterior tinha 15 manifestacoes. Permanecem somente:

- `eletrica`
- `lacerante`
- `prismatica`
- `parasitica`
- `gravitante`

Sao removidas:

- `retornante`
- `ancorada`
- `cartografica`
- `mnesica`
- `ressonante`
- `contratual`
- `acorrentada`
- `eclipsada`
- `bombastica`
- `necronada`

Henry, suas mutacoes, efeitos e o uso de `lacerante_empower` como
`activate_reinforcement` ficam fora desta remocao.

## Superficies compartilhadas afetadas

- Roster, constantes, estado e desbloqueios:
  `scripts/main_runtime_state.gd`.
- Integracao de combate, habilidades, teleporte, recompensas, selecao,
  desbloqueios, catalogo, telemetria auxiliar e facades online:
  `scripts/main_runtime_core.gd`.
- Selecao, detalhes e previews:
  `scripts/presentation/menus_presentation.gd`.
- HUD e controles extras: `scripts/presentation/hud_presentation.gd` e
  `scripts/ui/hud_layout.gd`. `lacerante_empower` era compartilhado por
  Lacerante, Eclipsada e Necronada; `bombastica_detonator` era exclusivo de
  Bombastica. O caminho de Henry Colosso para `activate_reinforcement` deve ser
  preservado.
- Códex: `scripts/catalog/catalog_details.gd`,
  `scripts/catalog/catalog_repository.gd` e facades de catalogo no core.
- Saves e runs interrompidas:
  `scripts/systems/save/runtime_save_controller.gd` e os carregadores de
  perfil/config no core. Chaves removidas devem migrar para `eletrica`, sem
  descartar os outros campos do save.
- Evolucoes: `scripts/systems/manifest_evolutions/manifest_evolution_catalog.gd`
  e os hooks no core. Os controllers de Lacerante e Prismatica permanecem.
- Apresentacao/VFX compartilhados:
  `scripts/presentation/combat_effects_presentation.gd`,
  `scripts/presentation/entities_presentation.gd`,
  `scripts/presentation/player_status_vfx_presentation.gd` e
  `scripts/vfx/combat_vfx_runtime.gd`.
- Online congelado: indices/chaves e snapshots aparecem em
  `scripts/systems/online/runtime_manifestation_visual_snapshot.gd` e no core.
  Nao serao executados testes multiplayer; a compatibilidade pendente sera
  registrada em `.agents/MULTIPLAYER_DEFERRED_VALIDATION.md`.
- UMBRA: `scripts/systems/umbra_observation_schema.gd` ainda codificava o
  roster antigo.
- Telemetria: `scripts/systems/telemetry/telemetry_system.gd` grava nome e
  `manifestation_key` genericamente; ao normalizar o runtime para Eletrica, o
  payload tambem deixa de emitir chaves removidas.
- Cartas: nao foi encontrada definicao de carta exclusiva condicionada a uma
  das dez chaves em `scripts/catalog/card_catalog_definitions.gd` ou
  `scripts/systems/cards/`. Existem sinergias genericas no core por categoria
  de dano (`basic_attack`, `skill_q`, `skill_e`, `manifestation_secondary`),
  que permanecem para as cinco manifestacoes estaveis.
- Falas da Geovana: nao foi encontrada fala nominal exclusiva das dez
  manifestacoes. Permanecem falas genericas sobre manifestacoes; descricoes e
  textos nominais do roster/Códex sao removidos.

## Dependencias por manifestacao removida

### Retornante

- Implementacao embutida no core: projeteis de ida/volta, memoria, HAB1,
  ultimate e janela de retorno do teleporte.
- Estado/constantes no runtime state e persistencia legada no save controller.
- HUD: rotulo `VOLTAR`; configuracao antiga `retornante_cheat` e status de
  desbloqueio.
- Catalogo/detalhes, desbloqueio, evolucoes e snapshots online.
- Arte exclusiva: `assets/sprites/manifestacao_retornante.png` e
  `assets/previews/manifestations/retornante_{atk,skill,ultimate}.webp`, com
  respectivos `.import`.
- Teste exclusivo: `tests/hud_fps_retornante_smoke.gd`. Testes mistos:
  `manifestation_tp_smoke`, selecao/espectro, previews, fases experimentais,
  UI desktop, musica, QA e contratos multiplayer congelados.

### Ancorada

- Controllers exclusivos:
  `scripts/systems/abilities/ancorada_ability_controller.gd` e
  `scripts/systems/manifest_evolutions/ancorada_evolution_controller.gd`.
- Hooks de territorio/ancoras/obstaculos no core, HUD dedicado, status VFX,
  mist guide, catalogo, desbloqueio, evolucoes, UMBRA e snapshots online.
- Arte exclusiva: `assets/sprites/manifestacao_ancorada.png` e
  `assets/previews/manifestations/ancorada_{atk,skill,ultimate}.webp`, com
  respectivos `.import`.
- Testes exclusivos: `ancorada_manifestation_smoke`, `ancorada_visual_smoke`,
  `ancorada_evolution_functional_smoke`, `ancorada_evolution_visual_smoke` e
  `test_ancorada_redesign`. O contrato multiplayer exclusivo tambem deixa de
  fazer sentido. Testes mistos de alvo no chao, range, status, evolucoes e
  seguranca precisam ser ajustados.

### Cartografica

- Implementacao embutida no core: coordenadas, rotas, teleporte e ultimate.
- Catalogo/detalhes, evolucoes, UMBRA, VFX e snapshots online.
- Arte exclusiva: `assets/previews/manifestations/cartografica_{atk,skill,ultimate}.webp`,
  com respectivos `.import`.
- Teste exclusivo: `tests/cartografica_rework_smoke.gd`; testes mistos de
  novas manifestacoes, previews, configuracoes e multiplayer congelado.

### Mnesica

- Implementacao embutida no core: memoria de alvos, detonacao e secundario.
- Catalogo/detalhes, evolucoes, UMBRA, VFX e snapshots online.
- Arte exclusiva: `assets/previews/manifestations/mnesica_{atk,skill,ultimate}.webp`,
  com respectivos `.import`.
- Sem teste solo exclusivo; aparece em `new_manifestations_smoke`, previews,
  orçamento visual mobile e contratos multiplayer congelados.

### Ressonante

- Implementacao embutida no core: compasso, notas, acordes e ultimate.
- Catalogo/detalhes, evolucoes, UMBRA, VFX e snapshots online. A palavra
  “ressonante” em Sineiro Boreal e em lore de inimigo nao representa a
  manifestacao e nao deve ser removida.
- Arte exclusiva: `assets/previews/manifestations/ressonante_{atk,skill,ultimate}.webp`,
  com respectivos `.import`.
- Sem teste solo exclusivo; aparece em `new_manifestations_smoke`, previews e
  contratos multiplayer congelados.

### Contratual

- Implementacao embutida no core: clausulas, ordem/sentenca e secundario.
- Catalogo/detalhes, evolucoes, UMBRA, VFX e snapshots online.
- Arte exclusiva: `assets/previews/manifestations/contratual_{atk,skill,ultimate}.webp`,
  com respectivos `.import`.
- Teste exclusivo: `tests/contractual_order_smoke.gd`; testes mistos de novas
  manifestacoes, previews, configuracoes e multiplayer congelado.

### Acorrentada

- Controller exclusivo de evolucao:
  `scripts/systems/manifest_evolutions/acorrentada_evolution_controller.gd`.
- Combo, tensao, elos, correntes, chefe, HAB1/ultimate e desenho ainda estao
  distribuídos entre core, state, HUD, status VFX, menus, audio e
  `scripts/vfx/chain_visual_physics.gd`.
- Save controller persiste o estado dedicado; catalogo, desbloqueio, evolucoes,
  UMBRA e snapshots online tambem referenciam a chave.
- Arte exclusiva: `assets/previews/manifestations/acorrentada_{atk,skill,ultimate}.webp`,
  com respectivos `.import`.
- Testes exclusivos: `acorrentada_manifestation_smoke`,
  `acorrentada_evolution_functional_smoke` e
  `acorrentada_evolution_visual_smoke`. Testes mistos de evolucao, status e
  multiplayer congelado precisam ser ajustados.

### Eclipsada

- Implementacao embutida no core: formas Sol/Lua, furtividade, tracos,
  ataques, HAB1, ultimate e teleporte.
- HUD usa `lacerante_empower` para troca de forma; esse ramo sai, mas o bind
  continua para Lacerante e Henry Colosso.
- Entidade/apresentacao, player control, catalogo, evolucoes, UMBRA, VFX e
  snapshots online.
- Arte exclusiva: `assets/sprites/manifestacao-eclipsada.png` e
  `assets/previews/manifestations/eclipsada_{atk,skill,ultimate}.webp`, com
  respectivos `.import`.
- Testes exclusivos: `eclipsada_rework_smoke` e
  `eclipsada_vfx_visual_smoke`. Testes mistos de cartas/qualidade, catalogo,
  render, evolucoes e multiplayer congelado precisam ser ajustados.

### Bombastica

- VFX exclusivo: `scripts/vfx/bombastica_scene_vfx.gd`; bombas, polvora,
  cargas, detonacao e ultimate no core/state.
- HUD/control extra exclusivo `bombastica_detonator` em HUD, layout e player
  control.
- Catalogo, evolucoes, status VFX, UMBRA e snapshots online.
- Arte exclusiva: `assets/sprites/manifestacao_bombastica.png` e
  `assets/previews/manifestations/bombastica_{atk,skill,ultimate}.webp`, com
  respectivos `.import`.
- Testes exclusivos: `bombastica_manifestation_smoke`,
  `bombastica_vfx_origin_visual_smoke` e `test_bombastica_vfx_logic`. Testes
  mistos de HUD, mira, previews, seguranca e multiplayer congelado precisam ser
  ajustados.

### Necronada

- Controller exclusivo:
  `scripts/systems/abilities/necronada_ability_controller.gd`.
- Epitafios, vestigios, remanescentes, requiem, jardim ossuario e ultimate no
  core/state; HUD e status VFX dedicados.
- HUD usa `lacerante_empower` para Poeira; esse ramo sai, preservando Lacerante
  e Henry Colosso.
- Enemy manager tinha integracao de remanescentes; player control, catalogo,
  evolucoes, UMBRA, VFX, save e snapshots online tambem referenciam a chave.
- Arte exclusiva: `assets/sprites/manifestacao-necronada.png` e
  `assets/previews/manifestations/necronada_{atk,skill,ultimate}.webp`, com
  respectivos `.import`.
- Testes exclusivos: `necronada_ability_controller_smoke` e
  `necronada_manifestation_smoke`. Testes mistos de catalogo, inimigos,
  seguranca, status, UMBRA e multiplayer congelado precisam ser ajustados.

## Criterios de verificacao

- `MANIFESTATIONS` e todas as superficies publicas expõem exatamente as cinco
  chaves mantidas.
- Chave removida em perfil, config ou run interrompida vira `eletrica`.
- `lacerante_empower` continua funcionando para Lacerante e para
  `activate_reinforcement` de Henry Colosso.
- Arte exclusiva e seus sidecars `.import` sao movidos para `_to_delete/`
  preservando a estrutura relativa.
- Testes multiplayer nao sao executados durante o congelamento; o impacto e os
  cenarios de validacao futura ficam no backlog dedicado.
