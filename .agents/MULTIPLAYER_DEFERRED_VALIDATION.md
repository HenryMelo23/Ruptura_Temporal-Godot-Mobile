# Multiplayer Deferred Validation Backlog

## 2026-11-02 — Character status VFX and XP HUD

- Local presentation only: left card/aura/manifestation/contract panels replaced by character-attached feedback. XP uses existing progression threshold getter. No RPC, snapshot or gameplay math changed.
- Solo evidence: `tests/player_status_vfx_visual_smoke.gd` rendered desktop/mobile landscape, four manifestations, animation, lightweight HUD, contracts, death and asserted XP fill for levels 1–10. Existing world card effects retained; per-card gameplay coverage is not claimed.
- Owed: local feedback from replicated aura/card/charge states on clients; contract progress/timers after sync; XP after authoritative grants; revive/spectator/disconnect transitions. New signals are local-player only, as were the retired HUD panels; remote-player rendering remains unchanged. No online, multi-process or physical-device tests in this task.

This file records multiplayer work intentionally deferred while production is
focused on the solo game. It is a validation backlog, not permission to remove
or ignore multiplayer implementation paths.

## Active Production Rule

Decision date: 2026-10-29.

Multiplayer validation was explicitly resumed by the user on 2026-10-29 for
the release following 2.0.60. The evidence below records the completed local
multi-process pass; it does not convert local ENet into physical-device proof.

- Build and validate the solo behavior first.
- When a changed system already participates in multiplayer, keep its authority,
  serialization, RPC, snapshot, legacy/default, and remote-presentation paths
  compatible as part of the implementation.
- Do not run multiplayer-specific validation unless the user explicitly asks to
  resume it. This includes dedicated server, host/client, relay, lobby/online,
  multi-process, public-network, and physical multi-device tests.
- Solo smokes, solo visual QA, parsing, and project validation remain available;
  they must not be described as multiplayer proof.
- Add one compact item below for every new feature whose multiplayer behavior
  was implemented or may have been affected but was not actually validated.
- A pending item is cleared only with explicit multiplayer validation evidence.

During normal solo work, append the new item without auditing the entire list.
Read and execute the complete backlog only when the user asks to focus on
multiplayer again.

## Frozen Reproducible Baseline

- Branch: `runtime-refactor-next`
- Remote commit: `068448a20c2513ea84233b5e8dd023c26e802600`
- Commit title: `release: publish 2.0.60 update manifests`
- Game version: `2.0.60`
- Android version code: `26000`
- Freeze date: 2026-10-29

This commit is the durable Git reference for the multiplayer version considered
stable at the start of solo-first production. Dirty worktree changes are not
part of that reproducible baseline.

## Evidence Recorded Before the Freeze

### MP-000 - Henry Incendiario traveling spin

Status: multiplayer validated locally before the freeze; not pending unless the
feature changes again.

- Henry travels to the selected teleport destination, remains protected, allows
  movement after arrival, explodes after 2.45 seconds, and transports the full
  destination in its ability visual event.
- Evidence: focused gameplay smoke, desktop/mobile visual smoke, and local
  dedicated relay plus host plus client all passed on 2026-10-29.
- Git note: this delta was still uncommitted when the freeze was recorded, so the
  frozen remote commit above remains the only reproducible baseline.

## Pending Multiplayer Validation

### MP-001 - Suturador de Ambar combat and card economy

Status: local multi-process validation completed on 2026-10-29.

Solo/local evidence already available:

- Four-attack rotation, movement, hook telegraph/pull, visible card theft,
  rewards, cleanup, save behavior, presentation captures, and deep project
  validation passed.
- Local contract checks exist, but they are not dedicated server plus host plus
  client proof.

Multiplayer evidence completed in the resumed pass:

- Dedicated server, host and client completed the authority battery; the target
  client alone received Suturador card mutation through request, relay and
  client-apply paths.
- The four-process match (server, host, client and client2) proved target-only
  theft/restoration while the non-target client retained its card.
- Duplicate steal and restore RPCs were injected in both duo and trio runs.
  Client apply is now idempotent per encounter/card, and a restore without a
  matching theft cannot grant a card.
- The authoritative snapshot transported encounter identity and hook visual
  state before cleanup; the existing room lifecycle battery covered orderly
  leave/shutdown after the feature pass.
- Focused gameplay and visual smokes still cover clamp, pull, named feedback,
  cleanup, rewards and desktop/mobile-profile presentation.

Not represented as proof: a physical two-device Android session during an
active theft. The public relay is validated again as part of release activation.

Suggested entry points when multiplayer validation resumes:

- `tests/phase6_amber_suturer_smoke.gd`
- `tests/phase6_amber_suturer_visual_smoke.gd`
- The project multiplayer runner with `server`, `host`, and `client` roles; do
  not invoke a role-based smoke without its role arguments.

### MP-002 - Boss 6 Matriarca three-stage rework

Status: local multi-process validation completed on 2026-10-29.

Solo scope currently represented in the worktree:

- Three health stages, stage-specific movement, Foices Vertebrais, Florada
  Acida, Mare de Carnificina, authored attack frames, and living-team target
  batches capped at three players.
- Boss visual snapshots now carry `boss6_stage`.

Multiplayer evidence completed in the resumed pass:

- Dedicated server relayed the authoritative phase-6 identity while host,
  client and client2 all received stage 3 and the same active ability.
- The focused team-pressure smoke proved living-only target selection, dead
  exclusion and a three-player cap; the trio transport pass preserved those
  player identities without local boss simulation on the relay.
- Snapshot pack/apply transported `boss6_stage`, ability and Suturador state in
  refreshed snapshots; legacy/default behavior remains covered by the focused
  Boss 6 contract smoke.
- General multiplayer lifecycle, ability visual and authority batteries passed
  after the Boss 6 transport pass, including leave/shutdown cleanup.
- Six real-render captures cover all three forms on desktop and mobile
  landscape with the segmented bar and team target markers.

Not represented as proof: a physical mobile client observing a live internet
Boss 6 fight. The public host/client transport is validated at release time.

Suggested entry points when multiplayer validation resumes:

- `tests/boss6_three_stage_rework_smoke.gd`
- `tests/boss6_team_pressure_smoke.gd`
- `tests/boss6_three_stage_visual_smoke.gd`
- `tests/multiplayer_gameplay_authority_smoke.gd` through a runner that supplies
  `--role=server|host|client`
- `tests/multiplayer_visual_fidelity_visual_smoke.gd`

### MP-003 - Hidden unpolished manifestations and specters

Status: local multi-process validation completed on 2026-10-29.

Solo scope represented in the worktree:

- Cartografica, Mnesica, Ressonante, Acorrentada, Necronada, Eclipsada, and
  Contratual remain in canonical data but are omitted from public selection and
  catalog surfaces.
- Nula, Abissal, Crepuscular, and Equilibrista follow the same rule.
- Carousel slots stay dense, canonical IDs stay stable, and legacy hidden
  selections fall back to public defaults before a new run.
- Focused selection, catalog, icon, specter-upgrade, and existing selector
  smokes passed; desktop 1280x720 and Android-profile landscape 960x540
  captures were rendered and inspected on 2026-10-29.

Multiplayer evidence completed in the resumed pass:

- Server, host, client and client2 completed selection using the same dense
  public lists while retaining canonical indices in transport state.
- Every non-Henry remote identity is now asserted public during the two- and
  three-player integration flow; duplicate-choice rejection/retry remained
  operational and the match started only after public selections were ready.
- The reconciliation battery covered reconnect-adjacent lobby state, spectator,
  shop, selection and final match startup without exposing a hidden identity.
- Focused selector/catalog tests and inspected desktop/mobile-profile captures
  contain no hidden cards, dots, gaps, notifications or catalog entries.

Not represented as proof: a physical-device reconnect while the selector is
open. Canonical fallback and delayed-packet guards remain covered locally.

Suggested entry points when multiplayer validation resumes:

- `tests/hidden_manifestations_specters_smoke.gd`
- `tests/hidden_selection_visual_smoke.gd`
- `tests/multiplayer_manifest_flow_smoke.gd` through the complete role-based
  multiplayer runner.

### MP-004 - Native-quality governor and asynchronous card-drop art

Status: pending multiplayer validation.

Solo evidence completed on 2026-10-30:

- `tests/runtime_adaptive_performance_smoke.gd` preserved native canvas,
  shadows and full projectile fidelity in Ultra across measured recovery stages.
- `tests/runtime_performance_visual_smoke.gd` rendered and captured full and
  emergency stages without changing Ultra's authored visual stage.
- `tests/card_drop_cold_load_smoke.gd` spawned four rewards without loading the
  catalog or selected card textures synchronously; selected art completed via
  the bounded threaded queue.
- `tests/singleplayer_long_run_accumulation_smoke.gd` exercised repeated kills,
  cleanup and resource monitors in Ultra.

Affected contract: authoritative reward selection remains unchanged, while
each peer now resolves replicated card-drop art through its local bounded
loader. Graphics-profile fidelity is local presentation state only.

Multiplayer scenarios still owed:

- Host and clients receive every authoritative Larapio/Suturador card drop once.
- A slow-loading client displays the placeholder, cannot collect before the
  card is ready, and later renders the same selected card as the host.
- Disconnect or scene cleanup drains pending texture requests without an
  orphaned RID/resource or duplicate reward.
- Desktop and mobile clients preserve their own explicit graphics profile
  without changing simulation, authority or remote reward identity.

Suggested tests/runners:

- `tests/multiplayer_three_player_contract_smoke.gd`
- `tests/card_drop_cold_load_smoke.gd`
- the role-based host/client/client2 runner when multiplayer validation resumes.

### MP-005 - Spatial enemy hot paths and periodic agglomeration

Status: pending multiplayer validation.

Solo evidence completed on 2026-10-30:

- `tests/enemy_spatial_grid_smoke.gd` preserved deterministic separation and
  phase-2 shooter selection while reducing 400-entity candidate discovery from
  160,000 brute-force pairs to 13,072 spatial candidates.
- `tests/agglomeration_spatial_smoke.gd` proved that three eligible live common
  enemies fuse once, while dead and distant enemies remain excluded.
- `tests/singleplayer_rendered_frame_pacing_smoke.gd` passed with full authored
  graphics, and `tests/singleplayer_long_run_accumulation_smoke.gd` completed
  90 seconds of repeated kills without orphan or resource growth.

Affected contract: the world authority still owns enemy movement, contact,
phase-2 common shooting and agglomerator fusion. The change reuses spatial
candidate buffers and caches the deterministic phase-2 shooter pair for one
simulation update; it does not add or change a network payload.

Multiplayer scenarios still owed:

- Host and clients observe the same phase-2 common shooter pair across cycle
  boundaries and late snapshots.
- Agglomerator fusion occurs once on authority and replicas remove the same
  source enemies without a duplicate fused enemy.
- Host plus two clients preserve collision/contact ownership when multiple
  players and remnants occupy adjacent spatial cells.
- Disconnect and spectator transitions do not leave a stale target or spatial
  candidate in the following authority update.

Suggested tests/runners:

- `tests/enemy_spatial_grid_smoke.gd`
- `tests/agglomeration_spatial_smoke.gd`
- `tests/multiplayer_three_player_contract_smoke.gd` through the role-based
  host/client/client2 runner when multiplayer validation resumes.

## Template for Future Items

### MP-2026-10-30-ROUTE-SUTURER-CAMERA - Random four-map cycles and Suturador crystal rules

Status: pending multiplayer validation.
Solo evidence: `tests/phase6_amber_suturer_smoke.gd`, `tests/start_phase_random_smoke.gd`, `tests/phase_route_fragment_portals_smoke.gd`, `tests/phase_transition_smoke.gd`, `tests/umbra_final_victory_route_smoke.gd`, and `tests/camera_comfort_smoke.gd`.
Affected contract: world authority owns Suturador armor, crystal crossfire/repair and projectile spawn; phase-choice consensus must replicate the same four-map queue; comfortable camera remains local presentation state.

Multiplayer scenarios still owed:

- Host and clients observe identical armor fracture, crossfire, repair, crystal destruction and hook speed/damage without duplicate projectiles or healing.
- Farm portal consensus chooses and preserves one authoritative four-map queue for host, clients, late join and retry restore.
- The fourth completed boss opens exactly two portals once, and Umbra remains unreachable before the shared fourth completion.
- Spectator/dead camera targets keep local comfort smoothing without affecting authority or other peers.

Suggested tests/runners: `tests/multiplayer_three_player_contract_smoke.gd`, host/client/client2 phase-consensus runner, late-join snapshot runner, and a two-device landscape visual pass when multiplayer validation resumes.

### MP-2026-11-01-AFFORDABLE-SCORE-CACHE - High-score shop forecast performance

Status: pending multiplayer validation.
Solo evidence: `tests/runtime_progression_controller_smoke.gd`, `tests/long_run_economy_smoke.gd`, `tests/shop_abuse_integrity_smoke.gd`, the Larápio steal/loot assertions in `tests/pause_cronomante_larapio_smoke.gd`, and a 60-second rendered six-enemy cycling-kill run in `tests/singleplayer_long_run_accumulation_smoke.gd`.
Affected contract: score authority and purchase rules are unchanged; local HUD/shop affordability now reuses an exact cached forecast and invalidates it when score, card cost, discounts, cards or Cinzas state changes. No packet or RPC schema changed.

Multiplayer scenarios still owed:

- Host and clients show the same affordable-card count after authoritative rewards, purchases and a Larápio theft.
- A score RPC received in the same frame as opening the manual shop cannot reuse a stale forecast.
- Late join, retry restore and shop-discount activation invalidate the local forecast without changing the authoritative price.
- Two- and three-player shop entry still rejects insufficient funds and accepts the same boundary purchase on every peer.

Suggested tests/runners: `tests/multiplayer_three_player_contract_smoke.gd`, the role-based host/client/client2 runner, and a late-join shop snapshot scenario when multiplayer validation resumes.

### MP-2026-11-01-SHOP-PURCHASE-FULL-REROLL - Full shop refresh and retired design cards

Status: pending multiplayer validation.
Solo evidence: `tests/new_common_cards_smoke.gd`, `tests/shop_hub_animation_smoke.gd`, `tests/cinzas_attribute_burn_system_smoke.gd`, and `tests/cinzas_card_visual_smoke.gd` passed. `tests/shop_paid_rerolls_smoke.gd` preserved its economy assertions but still reports the pre-existing `shop_spend` audio-check failure for both paid reroll and purchase.
Affected contract: a committed purchase now generates all three offers again and clears legacy shop locks; `escolha_adiada`, `leitura_instante`, `margem_segura`, and `solo_consolidado` no longer enter the card pool, unlock rules, catalog, or effective saved-card count. Purchase authority, pricing, and packet schemas are unchanged.

Multiplayer scenarios still owed:

- Host and clients receive the same three replacement offers and generation index after an authoritative purchase.
- Late join, retry restore, and old saves cannot reactivate retired cards or preserve a stale locked shop slot.
- Two- and three-player purchase timing keeps score, discounts, Cinzas marks, selection, and refreshed offers synchronized.
- Duplicate purchase requests cannot trigger two full generations or leave different offers between peers.

Suggested tests/runners: `tests/multiplayer_three_player_contract_smoke.gd`, `tests/multiplayer_shop_flow_smoke.gd`, the role-based host/client/client2 runner, and a late-join shop snapshot scenario when multiplayer validation resumes.

### MP-2026-11-01-TARGET-RANGE-REGULAR-ENEMY-BALANCE - Independent ability targeting and softer regular enemies

Status: pending multiplayer validation.
Solo evidence: `tests/ranged_attack_range_smoke.gd`, `tests/player_run_level_smoke.gd`, `tests/gameplay_safety_pack_smoke.gd`, `tests/player_control_controller_smoke.gd`, `tests/parasitica_skill_aim_smoke.gd`, `tests/lacerante_ultimate_aim_smoke.gd`, `tests/ancorada_manifestation_smoke.gd`, all three focused Henry mutation smokes, `tests/regular_enemy_balance_smoke.gd`, and `tests/phase6_amber_suturer_smoke.gd` passed.
Affected contract: basic attacks retain a replicated 420 px base range and projectile boundary while automatic abilities can choose nearest/lowest-health targets independently; regular enemy HP growth and armor reduction retain 55 percent of their former scaling, with bosses, Larápio, Sineiro Boreal and Suturador de Âmbar exempt. No packet schema changed.

Multiplayer scenarios still owed:

- Host and clients choose the same nearest/lowest-health ability target when it is outside basic-attack range.
- Remote basic projectiles retain the 420 px base plus card/level growth without allowing automatic fire beyond the ring.
- Authority-spawned regular enemies use the softened HP curve identically in two- and three-player runs while exempt minibosses keep their prior health.
- Damage requests apply softened regular armor exactly once and preserve boss/miniboss armor on host, clients, late join and retry restore.

Suggested tests/runners: `tests/multiplayer_three_player_contract_smoke.gd`, the role-based host/client/client2 combat runner, remote projectile snapshot checks, and a late-join enemy snapshot scenario when multiplayer validation resumes.

### MP-2026-11-01-ECONOMY-RARITY-LIFESTEAL-OVERCRIT - Economy denomination and card balance

Status: pending multiplayer validation.
Solo evidence: `tests/runtime_progression_controller_smoke.gd`, `tests/new_common_cards_smoke.gd`, `tests/roguelike_point_cards_smoke.gd`, `tests/cinzas_attribute_burn_system_smoke.gd`, `tests/ranged_attack_range_smoke.gd`, and the desktop/mobile captures from `tests/uncommon_cards_visual_smoke.gd` passed.
Affected contract: internal score, prices, purchase authority, save values, and packet schemas remain unchanged while player-facing point values use a 10:1 denomination. Roubo de Vida, Moeda Estável, Pacto das Possibilidades, and Tributo da Dor are now uncommon; incompatible legacy Cinzas state is sanitized. Roubo de Vida heals 3 percent of projectile damage per copy, and Tempestade grants 10 percent critical chance per copy with excess chance converted into critical damage.

Multiplayer scenarios still owed:

- Host and clients display the same denominated score, prices, spend animation, Larápio theft, loot return, boss reward, and point-card rewards from authoritative raw values.
- Authoritative purchases and late-join snapshots preserve the new uncommon rarities without allowing promoted cards through the common or Cinzas pools.
- Projectile lifesteal heals exactly once from confirmed damage on host and replicas, including critical and overcritical hits.
- Ten or more Tempestade copies produce identical guaranteed critical damage on host, clients, late join, retry restore, and remote combat presentation.

Suggested tests/runners: `tests/multiplayer_three_player_contract_smoke.gd`, `tests/multiplayer_shop_flow_smoke.gd`, the role-based host/client/client2 combat runner, and a late-join score/card snapshot scenario when multiplayer validation resumes.

### MP-2026-11-01-CARD-POWER-FEEDBACK - Visible card power and combat threat feedback

Status: pending multiplayer validation.
Solo evidence: `tests/card_power_feedback_smoke.gd` passed; `tests/card_power_feedback_visual_smoke.gd` produced desktop and landscape-mobile captures with the memory-saver reduction active.
Affected contract: card acquisition, confirmed damage, lifesteal, mitigation and heavy-hit events now create bounded local draw-primitive feedback. Purchases made behind the shop queue their presentation until gameplay resumes. No authority, snapshot, RPC or packet schema changed.

Multiplayer scenarios still owed:

- Host and clients show one local acquisition confirmation after each authoritative shop purchase without replaying it from snapshots.
- Remote confirmed attacks do not duplicate the local critical, power-hit, lifesteal or overkill feedback.
- Late join, retry restore, disconnect and run reset clear queued acquisition and cooldown state without losing card counts.
- Desktop and landscape-mobile peers keep equivalent readable feedback while memory-saver peers use the reduced ray count.

Suggested tests/runners: `tests/multiplayer_three_player_contract_smoke.gd`, `tests/multiplayer_shop_flow_smoke.gd`, the role-based host/client/client2 combat runner, and desktop/mobile remote-presentation captures when multiplayer validation resumes.

### MP-2026-11-01-PHASE1-ENEMY-TUNING - Crystal armor, Projector range and Stalker opacity

Status: pending multiplayer validation.
Solo evidence: `tests/phase1_enemy_tuning_smoke.gd` and the before/after landscape capture from `tests/phase1_enemy_tuning_visual_smoke.gd`.
Affected contract: the Cristalizado now applies stronger authority-side mitigation, the Projetador engages at 420 px, and Espreitador snapshots carry a 0.75 opacity multiplier in visible, sprint and furtive states. No packet or RPC schema changed.

Multiplayer scenarios still owed:

- Host-authoritative Cristalizado mitigation produces identical remote health and damage text.
- Projetadores select and fire at targets between 281 and 420 px without duplicate remote projectiles.
- Espreitador opacity remains 0.75 on host, clients and late join across visible, sprint and furtive transitions.
- Retry restore and enemy snapshot interpolation preserve these values without reverting to the former defaults.

Suggested tests/runners: `tests/multiplayer_three_player_contract_smoke.gd`, the role-based host/client/client2 combat runner, a late-join enemy snapshot scenario, and remote landscape captures when multiplayer validation resumes.

### MP-2026-11-01-CINZAS-LARAPIO-PHASE1-PRESSURE - Uncommon Cinzas and earlier mixed horde pressure

Status: pending multiplayer validation.
Solo evidence: `tests/cinzas_attribute_burn_system_smoke.gd`, `tests/porcao_larapio_balance_smoke.gd`, `tests/phase1_pressure_balance_smoke.gd`, and `tests/phase_density_carry_smoke.gd` passed.
Affected contract: Cinzas da Escolha now belongs to the uncommon pool while retaining its consumable and non-burnable policy; authority-spawned Larápio HP uses the stronger base/time/kill curve; phase 1 and phase 6 break their base enemy cap at 600 seconds, and phase 1 chooses special enemies more often than common Errantes after the first special unlock. No packet schema changed.

Multiplayer scenarios still owed:

- Host purchases, refreshed shops, late joins and retry restores keep Cinzas in the uncommon pool and out of common/Cinzas targets.
- Authority-spawned Larápios use the same HP curve for every peer and preserve it through enemy snapshots and reconnects.
- Two- and three-player enemy caps begin post-break kill growth at the same phase elapsed time without duplicate increments.
- Remote clients receive the same mixed phase-1 composition and special caps without locally spawning extra enemies.

Suggested tests/runners: `tests/multiplayer_three_player_contract_smoke.gd`, `tests/multiplayer_shop_flow_smoke.gd`, the role-based host/client/client2 combat runner, and late-join shop/enemy snapshot scenarios when multiplayer validation resumes.

### MP-2026-11-01-MANIFEST-EVOLUTIONS-HIDDEN - Temporary evolution shutdown

Status: pending multiplayer validation.
Solo evidence: `tests/manifest_evolution_hidden_smoke.gd` passed with choice capacity, fragments, saved effects and menu access disabled.
Affected contract: the evolution catalog and saved data remain intact, but runtime choices, combat hooks, fields, visual snapshot IDs, fragments and selection UI are gated off by `MANIFEST_EVOLUTIONS_ENABLED`. Existing barrier/RPC schemas remain present and unchanged.

Multiplayer scenarios still owed:

- Host and clients never spawn or collect evolution fragments after Arauto defeat while the feature flag is disabled.
- Late join and retry restore preserve saved evolution data without activating its combat or visual effects.
- A stale evolution barrier cannot pause one peer, open a hidden selection screen or leave peers waiting.
- Re-enabling the flag later restores one authoritative shared choice flow without duplicate picks.

Suggested tests/runners: `tests/multiplayer_manifest_evolution_barrier_smoke.gd`, `tests/multiplayer_three_player_contract_smoke.gd`, the role-based host/client/client2 runner, and a late-join interrupted-run scenario when multiplayer validation resumes.

### MP-2026-11-01-BOSS6-STATIONARY-SURVIVAL - Stationary Matriarch survival cycles

Status: pending multiplayer validation.
Solo evidence: `tests/boss6_three_stage_rework_smoke.gd` passed; `tests/boss6_three_stage_visual_smoke.gd` produced six inspected desktop and landscape-mobile captures with the boss fixed to the arena anchor.
Affected contract: the Matriarca da Chaga no longer moves or relocates; authority stage updates snap it to the central altar. HP milestones now combine carapace with scythes/incubation, acid bloom or carnage tide to create survival windows. Existing boss attack and visual snapshot shapes remain unchanged.

Multiplayer scenarios still owed:

- Host, clients and late join keep the Matriarch on the same fixed world anchor through every stage and special event.
- Survival-cycle carapace and hazards start once on authority and replicate without duplicate attacks or damage.
- Disconnect, retry restore and interrupted-run restore preserve milestone flags without replaying completed cycles.
- Remote desktop and landscape-mobile peers see matching telegraphs, stage sprites, carapace state and arena hazards.

Suggested tests/runners: `tests/multiplayer_three_player_contract_smoke.gd`, the role-based host/client/client2 boss runner, a late-join boss snapshot scenario, and remote desktop/mobile captures when multiplayer validation resumes.

Copy this block for each solo-first feature with deferred multiplayer proof:

```text
### MP-XXX - Feature name

Status: pending multiplayer validation.
Solo evidence: tests or captures that actually ran.
Affected contract: authority, payload/snapshot/RPC, remote presentation, or state cleanup.
Multiplayer scenarios still owed:
- Server/host/client behavior.
- Two- and three-player ownership/targeting.
- Duplicate, late, disconnect, retry, and cleanup behavior as applicable.
- Remote desktop/mobile visual parity as applicable.
Suggested tests/runners: exact paths or commands to use later.
```

## 2026-11-01 — Anti-heal health-bar wire

- Changed `scripts/ui/combat_hud.gd` and `scripts/presentation/hud_presentation.gd`: local HUD draws barbed wire from existing sacrifice healing-penalty and calcification states; no gameplay or packet changes.
- Solo evidence: `tests/health_barbed_wire_visual_smoke.gd` passed under Compatibility/llvmpipe at 1280x720 and 960x540, including active, expired, calcified and lightweight HUD captures. Pixel assertions verify appearance and removal after penalty expiry.
- Deferred: verify each client's own bar after sacrifice/revive, penalty expiry and calcification entry/exit; verify spectator/death transitions and remote desktop/mobile parity. Multiplayer and physical-device performance were not exercised.


## 2026-11-02 — Fase EX: terreno em chunks e altar integrado

- EX continua explicitamente solo-only. Novo atlas de 16 regiões, seleção estável
  por célula de 384 unidades e altar integrado à célula reservada; o ponto de
  interação é o centro da mesma célula. A camada de mapa comum ganhou um modo
  de atlas, restaurando o material normal ao sair da EX.
- Evidência solo: smoke de EX verifica unicidade do altar, variedade, estabilidade
  ao mover câmera, deslocamento da célula e invocação; capturas desktop 1280x720
  e paisagem 960x540 em Compatibility/llvmpipe. Não é evidência de Android físico.
- Ainda devido quando a validação multiplayer for retomada: conferir retorno ao
  mapa normal em host/client após uma partida EX solo; conferir que o bloqueio
  de EX em lobby/online permanece. Se EX for liberada online no futuro, replicar
  célula do altar/layout antes de validar desenho remoto e invocação autoritativa.
- Nenhum servidor, lobby, relay ou sessão multiplayer executado neste trabalho.

## 2026-11-02 — FaseEX2 e padrão compartilhado de mapas experimentais

- `FaseEX2` arma uma nova partida solo baseada na fase 2. Usa o controlador de
  EX, área 5×, atlas glacial de 16 regiões e altar único integrado. A entrada da
  Sentinela Glacial usa a célula do altar somente na EX2; fase 2 normal mantém o
  centro da arena. O renderer recebe a textura do perfil, evitando cache da EX1.
- Evidência solo: `experimental_phase2_smoke` verifica comando/cancelamento,
  regras da fase 2, unicidade do altar, invocação/entrada da Sentinela, alternância
  EX2 -> EX -> normal e entrada normal. `experimental_phase_smoke` e
  `boss2_state_machine_smoke` passaram. Capturas EX2 desktop 1280×720 e paisagem
  960×540, com a personagem, altar movido/usado e modo leve, em llvmpipe local.
- `experimental_terrain_render_smoke` passou para EX e EX2: deslocamento de
  câmera sem diferença nos pixels comparados e amostra central do altar alinhada.
- Pendente quando a validação multiplayer for retomada: verificar bloqueio de
  FaseEX2 em host/client/lobby, entrada normal da Sentinela e apresentação de
  mapas normais após uma EX2 solo. Se EX2 for liberada online futuramente,
  sincronizar perfil, célula/âncora do altar e início de invocação antes de testar
  chegada da Sentinela e eventos climáticos em peers remotos.
- Nenhuma sessão de servidor, host/client, lobby, relay ou múltiplos dispositivos
  foi executada. Android físico e desempenho em aparelho continuam não medidos.

## 2026-11-02 — FaseEX3: catedral e esgoto

- Alteração: perfil solo FaseEX3, atlas com altar integrado e chegada do Pai-Rato
  ancorada na célula de invocação apenas durante a variante experimental.
- Evidência solo: `experimental_phase3_smoke.gd` passou comando/cancelamento,
  atributos originais, altar único, invocação, chegada e retorno à fase normal;
  `experimental_phase_visual_smoke.gd -- --ex3` e `--ex3 --low` passaram com
  capturas desktop/paisagem móvel, altar movido/usado e restauração do material.
  `experimental_terrain_render_smoke.gd` confirmou câmera e centro nas três artes.
  Regressões EX/EX2 e `phase3_smoke.gd` passaram; este último foi corrigido para
  respeitar a rota variável existente em vez de presumir fase 2 -> fase 3.
- Ainda devido quando o usuário retomar multiplayer: verificar entrada do
  Pai-Rato e anúncio na fase 3 normal em host/cliente, sincronização visual do
  boss e restauração de mapa/tamanho ao entrar online depois de uma jornada EX3;
  confirmar rejeição da variante em conexão online/servidor. Caso EX3 seja
  liberada online no futuro, sincronizar perfil, célula, descoberta, progresso,
  invocação única e entrada do boss para clientes e reconexão.
- Nenhuma sessão multiplayer executada. Capturas locais não validam Android físico.

## 2026-11-02 — FaseEX4: Coração do Nexo

- Alteração: perfil solo FaseEX4, piso escuro com fissuras/cristais magenta e
  altar integrado do Nexo Anfíbio (sapo adulto sem cauda). Na variante, a queda
  orbital termina na célula do altar; o alvo normal em 68%/50% foi preservado.
- Evidência solo: `experimental_phase4_smoke.gd` passou comando/cancelamento,
  atributos originais, altar único, invocação, meio/fim da queda e retorno normal.
  Regressões EX/EX2/EX3 e `boss4_integral_rework_smoke.gd` passaram, incluindo
  locomoção, estágios, habilidades contextuais e resultados da ultimate.
  Arte corrigida conferida em `experimental_phase_visual_smoke.gd -- --ex4`
  e `--ex4 --low`, desktop/paisagem móvel, altar movido/usado e retorno do material.
  `experimental_terrain_render_smoke.gd` passou câmera/âncora nas quatro artes.
- Ainda devido quando o usuário retomar multiplayer: entrada orbital normal do
  boss 4 em host/cliente, sincronização do destino e do movimento, retorno ao
  mapa/tamanho normal após EX4 e rejeição da variante em online/servidor. Se EX4
  for liberada online no futuro, sincronizar perfil, célula, descoberta,
  progresso, autorização única e chegada do boss, inclusive reconexão.
- Nenhuma sessão multiplayer executada. Android físico não exercitado.

## 2026-11-03 — FaseEX6: pântano, doença e ossos

- Alteração: perfil solo FaseEX6, atlas orgânico próprio sem referência visual às
  fases 3/4, ninho integrado de raízes/costelas/âmbar e decoração no próprio piso.
  `RTBoss6StageController.arena_center()` mantém a Matriarca no altar durante
  entrada, três estágios e eventos; miasma (colisão/desenho), órgãos e pontos de
  invocação relacionados usam o mesmo centro. Fase 6 normal mantém o centro antigo.
- Evidência solo: `experimental_phase6_smoke.gd` passou comando, atributos,
  altar único, partículas de entrada, estágios, especiais, órgãos, miasma,
  retorno normal e bloqueio de persistência. Regressões EX/EX2/EX3/EX4 e
  `boss6_three_stage_rework_smoke.gd` passaram. Capturas finais de
  `experimental_phase_visual_smoke.gd -- --ex6` e `--ex6 --low` conferidas em
  desktop/paisagem móvel, com altar movido/usado e miasma. Render da câmera e
  centro do altar passou nas cinco artes em `experimental_terrain_render_smoke.gd`.
- Ainda devido quando o usuário retomar multiplayer: entrada/âncora da Matriarca
  na fase 6 normal em host/cliente, miasma visual versus colisão autoritativa,
  órgãos/eventos especiais, restauração após EX6 e rejeição da variante online.
  Se EX6 for liberada online no futuro, sincronizar perfil, célula, descoberta,
  progresso, autorização única, centro do encontro e reconexão.
- Nenhuma sessão multiplayer executada. Android físico não exercitado.

## 2026-11-03 — FaseEX7: floresta queimada e brasas

- Alteração: perfil solo FaseEX7, atlas de floresta carbonizada com clareira da
  Fênix integrada. A arte foi revisada após captura com Geovana para reduzir
  granulação e aproximar o acabamento do jogo. Invocação na célula; voo, mergulho,
  projéteis e quadrantes de fogo usam o encontro local de dimensões normais.
  Fogo visual e dano compartilham a origem/tamanho; fase normal mantém coordenadas.
- Evidência solo: `experimental_phase7_smoke.gd` passou comando/atributos,
  altar único, entrada, voo, mergulho/projétil, fogo local, núcleo/renascimento e
  retorno normal. `boss7_fenix_smoke.gd`, `boss7_fire_progression_smoke.gd` e
  regressões EX/EX2/EX3/EX4/EX6 passaram. O teste de progressão do fogo foi repetido
  com renderização real após erro do compilador de shader no encerramento
  headless; a execução renderizada passou sem esse erro.
  `experimental_phase_visual_smoke.gd -- --ex7` e `--ex7 --low` conferidos com
  Geovana real em desktop/paisagem móvel, altar movido/usado e fogo. Teste de
  terreno passou câmera/centro nas seis artes, incluindo a revisão final.
- Ainda devido quando o usuário retomar multiplayer: entrada normal da Fênix,
  voo/mergulho, sincronização dos quadrantes e dano remoto, núcleo/renascimento,
  retorno ao mapa normal depois de EX7 e rejeição da variante online. Para futura
  liberação online de EX7, sincronizar perfil/célula, centro/retângulo do encontro,
  descoberta, progresso e autorização única de invocação, inclusive reconexão.
- Nenhuma sessão multiplayer executada. Android físico não exercitado.

## 2026-11-03 — Conjunto ilustrado EX1–EX5 e perfil EX5
- Escopo: repintura dos atlas EX–EX4, novo atlas/perfil EX5, selo da UMBRA preservado no shader durante trocas dimensionais, entrada/vórtice/laser ancorados no altar. Fases EX seguem exclusivas solo.
- Evidência solo: smokes EX1–EX5 e fase5 normal aprovados; capturas reais com Geovana em 1280x720 e 960x540, modo leve, altar movido; teste de terreno EX1–EX7 sem deslocamento com câmera; validação profunda e orçamento aprovados. Logs: `.agent_logs/phase_ex_collection/`.
- Ainda devido quando o congelamento terminar: confirmar rejeição do comando EX5 em sessão real host/client; regressão da UMBRA normal com transmutação, vórtice e laser (origem de desenho, dano e snapshots) em host/client; confirmar retorno de materiais após troca de fase/conexão. Nenhuma sessão multiplayer foi executada.

## 2026-11-03 — Mapas expandidos promovidos à campanha definitiva

- Alteração: as fases 1–7 da campanha agora usam por padrão o mundo 3200×2250,
  atlas em chunks, exploração e altar local do boss. Os antigos mapas 1600×900
  passaram a ser variantes one-shot `FaseEX`–`FaseEX7`, exclusivas de solo e sem
  partida interrompida. A campanha expandida preserva rota e salvamento; posição,
  descoberta e uso do altar entram no snapshot.
- Compatibilidade implementada sem sessão online: sorteio do altar é determinístico
  por fase quando há multiplayer/online/servidor, e a interação encaminha a chamada
  pelo fluxo existente de votação/RPC em vez de iniciar o boss apenas localmente.
- Evidência solo: `experimental_phase_smoke.gd`, smokes específicos 2–7,
  `phase_transition_smoke.gd` e `runtime_save_controller_smoke.gd` aprovados.
- Ainda devido quando o usuário retomar multiplayer: executar host/cliente e
  servidor dedicado; confirmar mesma célula de altar e chunks em todos os pares,
  descoberta/apresentação remota, votação iniciada no altar por host e cliente,
  chamada única, entrada e centro local dos bosses 1–7, transmutação da fase 5,
  transições de rota, reconexão e rejeição das variantes clássicas EX.
- Nenhuma sessão multiplayer ou dispositivo físico foi executado nesta alteração.

## 2026-11-03 — Fenda do Mercador (loja automática solo) e névoa-guia

- Alteração: em partidas solo com loja automática, a contagem de 15 s foi
  substituída por uma fenda no mundo (`merchant_rift_controller.gd`) aberta por
  marco de abates ou pelo intervalo configurado; o jogador entra andando,
  entrada no limite dá -10%, fenda ignorada guarda fragmento (-5% e +1 reroll).
  A linha do altar virou névoa-guia compartilhada com marcador de borda.
- Compatibilidade: a fenda é desativada com `is_multiplayer`/servidor dedicado;
  nesses casos `shop_controller.should_trigger_forced` mantém a contagem e o RPC
  `_rpc_trigger_shop` legados. Estado salvo na partida interrompida solo.
- Evidência solo (Godot 4.7.2): `merchant_rift_smoke.gd` aprovado (abates,
  entrada, limite, fragmento, colapso, reembolso do boss, intervalo, online
  legado, troca de fase); `merchant_rift_visual_smoke.gd` normal e `--low`
  com capturas em `.agent_logs/merchant_rift/`; regressões
  `bargain_capsule_smoke`, `shop_button_layout_smoke`, `experimental_phase_smoke`,
  `phase_transition_smoke`, `runtime_save_controller_smoke` aprovadas.
  `shop_schedule_rarity_smoke` falha antes da fenda: a oferta de tutorial do
  início pausa o mundo e o tempo da loja não avança (problema pré-existente).
- Ainda devido quando o multiplayer for retomado: decidir se a fenda vira
  entidade de mundo autoritativa (posição, idade, estado, entrada de qualquer
  par abrindo a loja do grupo, fragmentos por grupo, snapshot/reconexão) ou se
  o online permanece na contagem; confirmar que a névoa do altar aparece nos
  clientes com descoberta sincronizada. Nenhuma sessão multiplayer executada.


## 2026-11-03 — Boss 4: saltos, Língua-Arpão e Salto Esmagador

- Alteração: locomoção por saltos (fases em `boss4_ai_state`), Língua-Arpão com mira
  que trava, puxão + tapa, quebra por dash e auto-puxão no erro; anel de choque
  `boss4_shock_ring` em `phase4_enemy_hazards`; sorteio reduzido por estágio.
- Compatibilidade: todo o estado novo vive em `boss4_ai_state` (já incluído em
  `snapshot()`); o anel usa `phase4_enemy_hazards`; dano remoto via `_send_peer_damage`.
  O puxão da língua só move o jogador local (pares remotos só levam o dano).
- Evidência solo: `boss4_hop_tongue_smoke`, `boss4_integral_rework_smoke`,
  `boss4_nexus_mechanics_smoke`, `boss4_multiplayer_sync_smoke` (contrato de snapshot),
  `boss4_continuous_performance_smoke` e visual `boss4_hop_tongue_visual_smoke`.
- Ainda devido: host/cliente reais — altura/fase do salto e quadro da língua nos
  clientes, puxão de um cliente agarrado (hoje só dano), dash de cliente quebrando a
  língua, anel acertando cada par uma vez, reconexão no meio do salto.

- Boss 4 Raio do Capacete: `beam_from/beam_to/beam_angle/beam_hits` vivem em `boss4_ai_state` (snapshot); dano remoto via `_send_peer_damage`. Validar sincronia do angulo da varredura e dano em peers quando o congelamento acabar.
- Boss 4 Poco Gravitacional: o puxao so e aplicado ao jogador local do host (`_update_singularities`); peers remotos recebem dano do nucleo/implosao via `_send_peer_damage`, mas ainda NAO sao puxados. Decidir: aplicar o puxao no cliente lendo o hazard `boss4_singularity` replicado.
- Boss 6 locomoção/Mergulho: `boss6_ai_state` (modo, monte, ponto de emersão, facing) ainda NÃO entra no pacote de `runtime_boss_visual_sync_controller`; réplicas veem só `boss_pos` (o corpo desliza com o monte e não afunda). Adicionar `boss6_ai_state` ao pacote visual e validar dano de emersão em peers (`_send_peer_damage`).
- Boss 6 Foices/Cuspe/Cauda: ataques novos vivem em `boss_attacks` (`waves`, `spots` com `launch`, `back/side`), já replicados pelo pacote visual; validar que réplicas desenham com a idade certa e que o dano remoto (`_send_peer_damage`) chega uma vez por onda/bola/varrida.
- Henry Incendiário rework: trilha do dash (`ember_trail`), fila/explosões de Combustão e bolas de fogo vivem no controlador local (não estão no snapshot); a autoridade aplica dano/cargas, mas peers remotos não veem a trilha nem as explosões. O visual remoto do dash ainda usa o pacote antigo do giro (`NET_ANIM_LACERANTE 48+`, `NET_ABILITY_TELEPORT` com `HenryFire.spin`). Replicar trilha/explosões e trocar o visual remoto do dash.
- Pressão infinita da horda (`scripts/systems/enemies/horde_pressure_controller.gd`): o orçamento de inimigos vivos é aprendido pelo FPS do host; validar com clientes lentos (o host pode ficar folgado e o cliente travar) e se o enxame condensado (vida/dano/pontos) replica certo.
- Henry Ignição Total rework: a linha do tempo local mudou (impactos em 0,70/1,45/2,20 s, raios 150/225/300, total 2,55 s), mas o visual remoto (`NET_ABILITY_SECONDARY` em `_draw_henry_network_ability`) ainda desenha 3 ciclos de 0,8 s com anel genérico de 280 px e os quadros de rede seguem a v1 (8 quadros, índices 40–47). Alinhar o visual remoto e o pacote de quadros.

## Henry Colosso — rework de peso (local)
- Hit-freeze, cone de choque do 3º soco, passos do gigante, decals (rachadura/poeira/estrela/sulco) e estouro da transformação rodam só no cliente local; dano do cone e empurrão do estouro precisam ser validados como autoritativos no host.
- Sheets v2 (8 direções) são carregadas só pro jogador local; pools de frames de rede continuam nos índices v1 (3 direções). Ao destravar o multiplayer: sincronizar índice v2 ou mapear v2→v1.
- Teste: tests/henry_colossus_weight_smoke.gd, tests/henry_colossus_weight_visual_smoke.gd.

## Loja manual aposentada
- Opções "Abertura da loja" e "Intervalo da loja" saíram das configurações; `shop_auto_enabled` fica sempre true e o intervalo fixo em 180 s (valores salvos antigos são ignorados).
- Botão LOJA do HUD só existe como atalho de QA (`shop_controller.manual_dev_access()`: dados QA ou fase inicial forçada).
- Online a Fenda segue desligada, então o MP usa só a contagem automática; o fluxo de pedido de loja manual entre parceiros (`_rpc_request_shop`) fica inalcançável para jogadores. Validar ao destravar o MP (ou levar a Fenda pro online).
- Teste: tests/manual_shop_removed_smoke.gd.

## Empurrões suaves do jogador + canalização segura do Henry Incendiário
- `_shove_player(offset)` (RTPlayerShoveController) troca os empurrões/puxões de impacto que teleportavam por deslocamento de ~0,2 s. Só mexe no jogador local; a posição chega aos parceiros pelo sync normal (verificar interpolação remota sem "saltos"). Puxões contínuos (redemoinho, vórtice, poço) seguem por quadro como antes.
- Henry Incendiário: Q e ultimate repelem + lentidão (`evolution_slow`) ao iniciar e mantêm guarda de 94 px durante a canalização. Só a autoridade de mundo empurra inimigos; cliente não-host não repele (validar pedido ao host).
- Cancelamento da canalização (teleporte ou apertar a mesma habilidade) é local: os pulsos restantes da ultimate somem só no cliente que cancelou — falta mandar evento de cancelamento pros parceiros (o visual remoto do cone/onda vai até o fim).
- Testes: tests/henry_channel_guard_smoke.gd, tests/henry_incendiary_smoke.gd, tests/boss6_spit_tail_smoke.gd.

## Manifestações enxutas — roster estável da Geovana
- O roster da Geovana foi reduzido a Elétrica, Lacerante, Prismática, Parasítica e Gravitante; índices/chaves antigos das dez manifestações removidas migram para Elétrica ao carregar save ou run interrompida. Henry, mutações e o botão compartilhado de reforço do Colosso foram preservados.
- Evidência solo: `manifestation_roster_smoke`, `manifestation_roster_playability_smoke`, `runtime_save_controller_smoke`, `manifestation_tp_smoke`, seleção/Códex/HUD visuais e catálogo de evoluções com 60 entradas para as cinco manifestações.
- Ainda devido: host/cliente reais selecionando cada uma das cinco; recepção de snapshot/reconexão com chave ou índice legado e normalização para Elétrica; replicação de ataque/Q/E/teleporte/ultimate das cinco; reforço do Henry Colosso pelo botão compartilhado; payloads de desbloqueio/telemetria do relay sem qualquer manifestação removida.

## Necrocronismo (rework "Eco que ricocheteia")
- Ecos vivem em `active_necro_specters` (estado: rise/seek/dash/recover/collapse) via RTNecrocronismController; dano das investidas e da implosão só na autoridade de mundo. Riscos de investida (`streaks`) são só visuais/locais.
- Validar: sincronizar posição/estado dos Ecos para os parceiros (hoje o cliente remoto não vê os Ecos do host) e o efeito `necro_collapse`.
- Teste: tests/necrocronism_echo_smoke.gd.

## Tela de escolha de build unificada (solo)
- Solo: Geovana (Manifestação/Espectro) e Henry (Mutação/Efeito) usam RTBuildSelectPresentation + textos de RTBuildChoiceDossier.
- Multiplayer (`manifest_mp`, `mutation_select_mp`, `effect_select_mp`) segue na tela de equipe antiga, com os textos antigos de CatalogDetails. Ao destravar o MP: levar o relatório novo (RTBuildChoiceDossier) para `_draw_manifest_mp_compact_info` e alinhar o visual.
- Testes: tests/build_choice_dossier_smoke.gd, tests/manifest_spectrum_select_smoke.gd.

## Gravitante rework (Massa crítica / Q suave / Poço de Partida)
- RTGravitanteController: órbitas limitadas a 3 por alvo; Estrela (3 órbitas) puxa vizinhos; Q puxa os marcados por 0,3 s antes de colidir; TP abre Poço de Partida (2,5 s) que puxa/marca e colapsa.
- Puxões, colisão e poço só rodam na autoridade de mundo. Validar: cliente não-host com Gravitante (pedido ao host), sincronia dos poços/colisões para o visual remoto (hoje `wells`/`collisions` são locais) e snapshot `gravitante_vfx_events` com os kinds novos (gravity_star_birth, gravity_q_pull, gravity_well_collapse).
- Teste: tests/gravitante_rework_smoke.gd, tests/manifestation_tp_smoke.gd, tests/combat_pack_2_0_10_smoke.gd.

## Lacerante rework (Laceração / barra de execução / execução reservada)
- RTLaceranteExecutionController: Laceração com limite 5 e sangramento pelo `_damage_enemy`; barra de execução (dano do Reforço); execução de 0,9 s com o alvo marcado `lacerante_exec` — `_damage_enemy` ignora qualquer dano que não seja `lacerante_execution` nesse alvo (inclusive pedidos de dano de outros peers no host).
- Só roda na autoridade de mundo (`try_start` exige `_is_world_authority`). **A Lacerante cliente não-host não consegue executar ainda**: precisa de RPC "pedir execução" → host reserva o alvo e responde; e sincronizar o estado da execução (posição da Geovana, animação, slash_events) para os parceiros verem.
- Teste: tests/lacerante_execution_smoke.gd, tests/lacerante_rework_smoke.gd.
- Câmera de execução (RTExecutionCamera) usa `viewport.canvas_transform` e esconde o HUD por ~1,15 s só no cliente local; parceiros não veem o foco. Imunidade pós-execução (0,9 s) é local ao jogador que executou.
- Recarga do Reforço agora vive no RTLaceranteExecutionController (10 s com execução, 15 s sem; −0,3 s por ATK que acerta; piso 4 s reduzido por Intervalo Fraturado). Não vai no save nem na rede: ao carregar save o Reforço volta pronto.

## Otimização de FPS (nov/2026) — validar quando o multiplayer voltar
- Desenho de inimigos em camadas (entities_presentation._draw_enemies_body): sombras e sprites via MultiMesh, auras largas (Cout, Curador, Incensário, Relicário, portal do Larápio, chama do Pinguim) agora ficam SOB os sprites, barras de vida por cima de tudo. Puramente visual/local, mas conferir inimigos remotos/espelhados (net) no cliente.
- enemy_manager: `_get_nearest_player_pos` só é calculado para Kamikaze; contato checa distância antes de `_local_player_damageable_by_contact`; cápsula da barganha lida uma vez por quadro. Semântica igual no host; conferir dano de contato em peers remotos.
- `_get_enemy_target_pos`: removida checagem duplicada de chefe/especial (ramos idênticos) e `enemies.find()` só sem uid. Conferir distribuição de alvos entre peers.
- Henry Incendiário: `_update_enemy_burn`/`_update_knockback` saem cedo quando o inimigo não tem as chaves de queimadura/empurrão. Conferir queimadura aplicada por cliente (on_damage_dealt no host).
- Henry Colosso gigante parado: freada (henry_colossus_stop_*) e respiracao (henry_colossus_idle_*) so no jogador local (RTHenryColossusAbilityController.giant_rest_texture). O parceiro remoto continua vendo o quadro 0 do andar (NET_ANIM_* nao tem estado de idle/freada do gigante). Avaliar se vale mandar isso na rede.
- Cronoguejo, Crono-Ruptura (RTRewindCamera): camera (zoom/inclinacao), trincas, VHS e relogio novo sao locais e seguem `boss1_rewind_sequence`, que ja e sincronizado por `_rpc_boss1_team_rewind`. Conferir num cliente: a cinematica deve tocar para todos ao mesmo tempo e o HUD some durante ~3,7 s (como na execucao da Lacerante).

## Mini-chefes (nov/2026) — validar com o multiplayer
- Larapio: bote (larapio_lunge*), leque de pedras e recarga por portal ficam no dict do inimigo (host). O rastro de moedas e a seta de borda sao derivados da posicao replicada (RTLarapioPresentation) — conferir que o cliente ve os portais em recarga (campo `cd` nos portais precisa ir no snapshot).
- Sineiro: Dobre Glacial (`rings` so no host; o visual vai por `_rpc_sineiro_event` ring_prepare/ring_release) e Dobre de Chamada (call_start/call_arrive). Dano/lentidao do anel em peers usa _send_peer_damage + _request_peer_status("slow").
- Arautos (RTArautoThreatController, so host): Coro de Ecos, Olhar Prismatico, Silencio Total, Inversao de Eco, Ferrao/Veneno, Casca, Ricochete. O estado (ability/inversion/stings/spikes) NAO e replicado: clientes nao veem os avisos. Veneno e Silencio Total/Inversao so atingem o jogador local do host (falta RPC de status/puxao para peers).
- Suturador (RTSuturerThreatController, so host): Remendo Vivo cria inimigos normais (replicados), Casulo/Elite marcam o dict do inimigo (amber_elite/amber_patched precisam ir no snapshot para o visual); os fios/linhas de costura nao sao replicados.

## Boss 2 — movimento e nevasca (2026-11)
- `RTBoss2MotionController` (órbita aleatória, bote com preparo de 0.45 s, deslize de barriga com redirecionamento) roda só no host e altera `boss_pos`/`boss2_target_position`; réplicas recebem a posição. Validar que o preparo do bote (`dash_windup`) e o rastro de gelo aparecem nas réplicas — hoje o rastro e a linha do bote são locais ao host.
- `RTBoss2BlizzardPresentation.reveal()` usa estado estático local (alpha suavizado) e o marcador de borda; ok por cliente, mas confirmar `_boss2_ultimate_boss_visible()` replicado.
- (2026-11-05) Nevasca: o pinguim agora sai andando da nevoa na janela de aviso e volta para ela depois do cuspe (`emerging()`/`in_blizzard()` no motion controller, host). O auto-alvo usa `in_blizzard()` pela posicao (antes era so o timer). Dissolver/remontar e visual local por `boss_pos`; validar que réplicas veem o mesmo momento de aparecer (interpolação de `boss_pos`).

## Artefatos de campo, pactos e escolha pos-chefe (2026-11-05)
- `RTFieldArtifactController`: tipo sorteado no host e enviado no orbe (`artifact_type`). Furia/ima vao no snapshot `field_artifacts`; expurgo roda so na autoridade (`purge_screen`). Validar: replica coletando ima puxa os orbes do peer certo; furia so no coletor? (hoje o snapshot e global -> todos ganham +50%).
- `RTBossPactController` / `RTRunChoiceController`: escolha e efeitos sao LOCAIS por jogador, sem barreira de rede (o jogo de cada um pausa sozinho em mode "run_choice"). Mecanicas de perigo (raios, meteoros, tremor) so afetam o jogador local. Precisa de barreira igual a `manifest_evolution` antes de liberar no MP.
- Pactos com `enemy_hp`/`enemy_speed`/`enemy_dmg` alteram globais do mundo: no MP devem rodar so no host.

## Boss 7 (Fenix) rework (2026-11-05)
- `RTBoss7MotionController` (voo em curvas, rasante `swoop_warn`/`swoop`, altitude/sombra do mergulho) roda no host via `boss_pos`/`boss7_state`. Replicas: conferir que os estados novos chegam no snapshot de estado do boss e que `altitude`/`trail` (locais, derivados de `boss_pos`) ficam coerentes.
- Chuva de Fogo agora causa dano (`RTBoss7Attacks.update_sky_fireballs`), usando `_damage_remote_player_in_radius` no host.
