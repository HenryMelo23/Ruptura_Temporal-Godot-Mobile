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
- Henry Incendiário rework (P0.07 local/relay concluído): `visual_snapshot(action)` expõe somente estado público limitado de trilha, Combustão e bola de fogo; o evento/patch existente replica início/progresso/fim e os peers derivam VFX sem partículas individuais. Dash remoto usa `HenryFire.dash`, não o giro antigo. Validado em relay local com duo/trio; ainda falta sessão pública, perda/latência hostil, Android físico e reconexão durante a habilidade.
- Pressão infinita da horda (`scripts/systems/enemies/horde_pressure_controller.gd`): o orçamento de inimigos vivos é aprendido pelo FPS do host; validar com clientes lentos (o host pode ficar folgado e o cliente travar) e se o enxame condensado (vida/dano/pontos) replica certo.
- Henry Ignição Total rework (P0.07 relay local): o visual remoto deriva os pulsos 0,70/1,45/2,20 s e raios atuais do estado canônico do controlador; fim natural preserva a cauda da última onda e cancelamento encerra imediatamente. Os quadros de jogador continuam no contrato compatível existente; validar sob latência/perda pública e Android físico.

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
- Cancelamento da canalização (P0.07): o evento público de fim identifica Q/ultimate; cancelamento zera imediatamente o visual correspondente e duplicatas são toleradas, enquanto fim natural mantém só a cauda visual já liberada. Validado por smoke de host + dois clientes e estado limpo de reconexão; ainda falta cancelamento durante sessão pública/Android e teleporte sob perda artificial.
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
- Henry Colosso gigante parado (P0.07): flags livres do snapshot fixo distinguem freada/respiração e facing aproximado; o cliente seleciona `henry_colossus_stop_*`/`idle_*` sem mudar stride, hitbox ou gameplay. Validado por smoke local; ainda falta inspeção visual em sessão pública/Android e sob cliente lento.
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

## 2026-11-05 — Retomada da validação multiplayer pós-solo

- Baseline remoto preservado em `6f20d6a` (`runtime-refactor-next`) antes das
  correções multiplayer.
- Contratos antigos reparados sem reativar recursos aposentados: limite de
  horda mede o delta multiplayer sobre o mapa atual; loja valida contagem
  automática/Fenda legada online e confirma que a loja manual permanece
  inacessível; evolução de manifestação desativada não abre barreira.
- Transporte novo comprovado por round-trip host/réplica:
  - avisos do Arauto (`ability`, `inversion`, ferrões e espinhos);
  - preparo/rastro do Boss 2;
  - Suturador (`stitch`, `cocoon`, `tethers`) e flags `amber_patched` /
    `amber_elite` no snapshot compacto de inimigos;
  - `boss6_ai_state` (incluindo mergulho/emergência);
  - movimento visual do Boss 7 (altitude, sombra, banco, rastro, rasante,
    velocidade e direção);
  - Artefato de Fúria definido como buff de equipe; Ímã preserva o peer coletor.
- Provas locais aprovadas: bateria direta de 21 contratos; runner real local de
  três processos (`authority`, `visuals`, `room lifecycle`); reconciliação
  `server + host + client + client2` para ready, espectador, loja, manifestação,
  espectro e partida.
- Ainda não validado/não liberado como concluído:
  - execução da Lacerante por cliente não-host (exige reserva autoritativa por
    peer, resposta e replay visual; não deve reutilizar o controlador local do
    host);
  - escolhas pós-chefe/pactos com barreira de equipe e aplicação única dos
    multiplicadores globais;
  - status hostis do Arauto em peers remotos (Silêncio/Veneno) e puxões físicos
    de Inversão; os danos geométricos já usam o caminho remoto existente;
  - Henry P0.07: sessão pública/Android, perda/latência, reconexão durante a habilidade e inspeção visual remota (relay local duo/trio e contratos já cobertos);
  - Necrocronismo, poços/colisões da Gravitante e dossiê unificado no UI MP;
  - sessão pública pelo relay, reconexão durante ataques, Android físico e
    cliente com desempenho muito inferior ao host.

## 2026-11-05 — Tutorial adaptativo (RTTutorialGuide)
- `player_control_controller.desktop_dash_mode()` agora usa `core._effective_desktop_teleport_mode()`: com MIRA DO ATAQUE = automatica, modos de teleporte por cursor (cursor/segurar/confirmar) viram ULTIMA DIRECAO. Validar que o cliente MP aplica a mesma regra localmente (dash enviado ao host com o destino ja resolvido).
- Bloqueio de acoes por passo do tutorial (`_try_attack/_use_skill/_use_secondary_skill/_try_dash/_try_dash_to_world`) so atua com tutorial ativo; tutorial e contextos continuam desligados em MP (`_maybe_start_context_tutorial`), mas conferir que nenhum estado de tutorial vaza para clientes.
- Contexto novo "extraordinary_context" e o rastreador de missao sao apenas locais (nao sincronizados).

## 2026-11-05 — Rota de fases fixa (volta da sequencia antiga)
- Inicio alterna 1 <-> 6 (bias 1.0 salvo em config a cada inicio de run). Rotas: 1-2-6-3-4 e 6-1-2-3-4; depois do 4, portais 7 (farm) x 5 (Umbra). Farm = 7 + 3 regioes sorteadas e nova escolha.
- Validar em MP: host decide inicio/rota e clientes recebem a fila (`dimension_route_queue`) e os rotulos novos dos portais; voto de portal "farm" deve levar todos para a 7.

## 2026-11-05 — Buff de cartas e recompensas de mini-chefes
- Solo validado: Disparo crescente, Tempestade, Defesa, Mercenaria, Tributo da Dor e Estilhaco Prismático; recompensas de Larapio, Sineiro, Suturador e Arauto.
- Validar em MP: compra/contagem efetiva das cartas por peer; deduplicacao dos pontos diretos de Sineiro e Arauto; orbe autoritativo de Larapio/Suturador; Mercenaria pagando o bonus do dono do abate sem duplicar no host/cliente.

## 2026-11-06 — Recarga dos cristais do Suturador
- Solo validado: a formação de cristais inicia recarga de 60 s; enquanto ela estiver ativa, a janela correspondente da rotação usa o leque de agulhas e não cria novos nós.
- Validar em MP: autoridade mantém uma única recarga, réplicas recebem `crystal_suture_cooldown` no estado visual e nenhum cliente observa recriação antecipada dos nós.

## 2026-11-06 — Parasitica: Simbiose Predatoria (Q) + Verme-Rei (E)
Logica nova em `scripts/systems/abilities/parasitica_ability_controller.gd` (RTParasiticaController, autoridade local do dono). Nada foi executado em host/client.
- Snapshot visual: `runtime_manifestation_visual_snapshot` agora envia `parasitica_visual` (compacto: sym, fome, falling; rei com pos/estado/consumed/perfect/fed/vida/bite/devour/trail[8]/target_pos) nas acoes SKILL e SECONDARY. Replica desenha via `RTParasiticaPresentation.draw_remote` em `_draw_canonical_manifestation_skill`. Validar: rei aparece no cliente, entrada subterranea, mordida/Devorar, Rei Perfeito, Alimentado.
- Dano do rei/mordida usa `_damage_enemy/_damage_boss/_damage_arauto` com categorias `skill_q`/`skill_e`; em cliente nao-autoridade esses caminhos viram `_send_client_damage_request`. Validar que o host aplica larvas (`seeds`) e Devorar com o rei controlado no cliente (larvas sao estado do inimigo na autoridade).
- Fome/velocidade/movimento sao multiplicadores locais do jogador dono. Validar que o host nao aplica a Fome do cliente em dano de outros jogadores.
- `_kill_enemy` chama `on_infested_kill` so na autoridade: em cliente, a extensao da Simbiose por abate pode nao acontecer. Cenario a decidir quando o MP descongelar.
- Save/resume: campo `parasitica_ability_state` (propriedade com get/set no core) entrou no snapshot interrompido/retry.

## 2026-11-08 — Ritual da Catedral jogavel (fase 3)
- Snapshot do ritual subiu para `SCHEMA_VERSION 2` (novos campos por circulo: sealed, profane, profaned, safe_wedge, pulse_beat, outcome, broken_at, outcome_at; global `elapsed`). Cliente antigo/novo nao se misturam.
- Pulsos de compasso causam dano em jogadores remotos via `_send_peer_damage` no host; o desvio por TP so e checado para o jogador local (o host nao conhece o `last_dash_time` do cliente). Validar/decidir.
- Profanacao conta qualquer jogador vivo dentro do circulo (posicoes de `_combat_targets`). Validar com 2–3 jogadores.
- Poses de dança/reverencia dependem de chaves no dicionario do inimigo (`phase3_ritual_pose`, `phase3_ritual_role`): conferir se a replicacao de inimigos as envia; senao a replica ve os ratos parados (sem quebrar nada).

## 2026-11-08 — Campanha expandida, altar e Fenda do Mercador online

- A campanha multiplayer usa o mesmo mundo definitivo 3200×2250 do solo; as variantes clássicas `FaseEX`–`FaseEX7` continuam sendo apenas atalhos solo.
- O altar deixou de aceitar presença remota por votação: a autoridade mede as posições replicadas e só inicia a chamada quando todos os jogadores vivos estão simultaneamente no raio. Mortos e espectadores não bloqueiam.
- A Fenda do Mercador passou a ser entidade autoritativa replicada; substitui a contagem antiga também nas réplicas e abre a loja do grupo somente quando todos os vivos tocam o portal. Estado, tempo, fragmentos e bônus de entrada seguem no snapshot visual.
- Evidência real local com servidor dedicado + host + cliente: `MULTIPLAYER_WORLD_ALTAR_OK` provou bloqueio 1/2 e chamada 2/2 no mapa expandido; `MULTIPLAYER_WORLD_SHOP_PORTAL_OK` provou bloqueio 1/2, réplica da fenda e abertura 2/2. A bateria também preservou autoridade de combate, VFX e ciclo da sala.
- Ainda devido fora desta máquina: sessão em dois dispositivos físicos e reconexão tardia enquanto altar/fenda já estão ativos.

## 2026-11-08 — Causa da morte no relatório da run

- Solo: o último dano efetivo é preservado e só vira `death_cause` quando a derrota realmente se confirma; revives não encerram a run nem registram uma morte falsa.
- Validar em MP: cada peer deve manter sua própria origem letal e, quando todos morrerem, o relatório enviado pelo líder precisa representar a causa do jogador local sem sobrescrever com a morte remota que encerrou a equipe.

## 2026-11-09 — Câmera cinematográfica de morte

- Solo: derrota entra por 1,65 s em câmera lenta, aproxima o corpo, remove o HUD, dessatura a cena e só então abre a evolução dos espectros.
- Validar em MP: a câmera não deve interromper espectador/revive quando apenas o jogador local cai; decidir e provar o disparo cinematográfico somente na derrota terminal de toda a equipe.

## 2026-11-09 — Portal do Mercador como entrada única da loja

- Solo: removidos o botão manual de loja do HUD/hub, editor de layout, configurações de teclado/controle e atalhos de combate, inclusive com QA liberado ou fase forçada; a Fenda do Mercador continua ativa.
- Validar em MP: host e clientes não devem exibir o atalho aposentado; a aceitação coletiva e a saída da loja aberta pela Fenda devem continuar acessíveis pelos controles restantes, sem depender da ação legada `shop`.

## 2026-11-09 — Durabilidade drástica de todos os bosses

- Solo: as sete fases receberam multiplicadores próprios de vida entre 3,0× e 4,5×. A camada adicional depende somente do tempo da run, usa uma curva sublinear sem teto e ignora completamente pontos e abates; inimigos comuns não usam essa curva.
- Validar em MP: a autoridade deve calcular uma única vida combinando durabilidade da fase, tempo total da run e coeficiente fixo do tamanho inicial do grupo; entrada tardia, morte e revive não podem reaplicar ou reduzir nenhum multiplicador, e as réplicas devem receber o mesmo `boss_hp_max`.

## 2026-11-10 — Drops estilo RoR2 + Chips Quânticos
- Chips quânticos ficam DESLIGADOS no multiplayer (`RTQuantumChipController.on_run_started` não ativa nada com `is_multiplayer`); Corruptor também não converte drops em MP. Decidir regras de equipe antes de liberar.
- Drop de carta: nova curva (4% base, ×(1+0,1/min)×1,15^regiões, teto 40%, ÷√jogadores), elites ×2,5 e piedade por jogador local (`pity_bonus` vive no host). Validar justiça entre jogadores e se a piedade deve ser por dono.
- Drop agora aceita cartas com arte ainda não carregada (carregamento assíncrono); conferir em clientes que a carta aparece quando a textura chega.

## 2026-11-10 — Mente da UMBRA, kit base e dano de projétil restaurado
- **Dano de projétil no jogador local restaurado** em `_update_enemy_bullets`: o bloco `if local_player_hit` tinha sumido junto com a Necronada (commit 6f20d6a), então nenhum projétil inimigo feria o jogador local; o `else` passou a pertencer ao `if` do segmento do plasma. Validar em MP que o host continua ferindo réplicas pelo ramo remoto (`_send_peer_damage`) e que o cliente não toma dano duplicado.
- Mira do plasma da UMBRA: `ObservationSchema.runtime_world_size()` usa o `WORLD_SIZE` real (3200×2250) no `space` da autoridade (antes 1600×900 e clamp em 1,0). A antecipação usa histórico só do jogador local; para alvo remoto mira na posição replicada sem lead. Validar com alvo remoto.
- Kit base novo (`RTUmbraBaseSkills`): REBOBINAR só é oferecido quando o alvo da decisão é o jogador local (o host não move réplicas); ECO_PROFETICO fere remotos por `_damage_remote_player_in_radius`. Decidir se Rebobinar deve ganhar evento replicado antes de liberar em MP.
- `RTUmbraMind` (camadas base/coletiva/jogador) só rastreia encontro e grava camada pessoal no solo (`begin_encounter` não roda com `is_multiplayer`). O relatório `umbra_combat` e `umbra_phase_lessons` vão vazios em MP. Observador de fases desligado em MP.

## 2026-11-11 — Iluminação, sombras e feedback físico do auto ataque
- Nova camada `RTWorldLighting` (aditiva, filho do canvas): poças de luz sob jogador local, projéteis locais+remotos, orbes, UMBRA e efeitos com `"light"`. É só visual e lê `remote_bullets`/`net` já replicados; validar que em MP as luzes dos projéteis remotos aparecem nos clientes.
- Vinheta + banho de cor por fase desenhados antes do HUD; afeta igualmente espectador.
- `_damage_enemy` agora aplica, no host: `hit_flash_until` (flash branco + pop de escala no desenho) e empurrão de 6,5 px (×0,45 em não-comuns) em acertos de `basic_attack`. O empurrão muda `enemy["pos"]` só na autoridade; réplicas recebem a posição replicada. Validar que o empurrão não briga com a interpolação visual dos clientes nem com inimigos de rota fixa (ritual fase 3 já é imune porque o dano é bloqueado antes).
- Tiros básicos em lote ganharam `stretch` por velocidade e textura com núcleo quente; sombras dos inimigos usam mancha de contato + 1 passe de silhueta (mesmas 2 instâncias por inimigo).

## 2026-11-11 — Durabilidade v3 dos chefes (dobro da v2)
- `BOSS_HP_DURABILITY_BY_PHASE` dobrado (fases 1–7: 6,0 / 6,5 / 7,0 / 7,5 / 8,0 / 7,5 / 9,0); modelo renomeado para `boss_hp_durability_v3_time_only`. A vida final de cada chefe é exatamente 2× a anterior em solo.
- A ordem dos fatores não mudou: `B(p) × D(p) × T(t) × coeficiente de grupo`. Validar em MP que o coeficiente de grupo continua aplicado uma única vez sobre a base nova e que entrada tardia/revive não recalcula `boss_hp_max` no meio do encontro.
- Risco a observar em MP: com o dobro de vida, encontros longos pressionam mais o orçamento de cura/sustentação do grupo e o tempo de sala. Medir duração real de luta com 2 e 3 jogadores antes de liberar.

## 2026-11-11 — Corte de cura do chefe 6 e gelo do Sineiro
- **Corte de cura (fase 6)**: novo `boss6_heal_cut_timer` (4 s, cura a 35%) aplicado em `_damage_player` para as fontes de `BOSS6_HEAL_CUT_SOURCES`. A Necro-Erosão caiu de 10 s para 6 s (`BOSS6_NECRO_EROSION_TIME`), e a calcificação continua zerando cura só para quem está fora do raio. Validar em MP: cada peer precisa do próprio timer (hoje só o local é calculado); o host não propaga o corte para réplicas, então clientes podem curar cheio enquanto o host acha que cortou. Decidir se vira status replicado (`_request_peer_status`) antes de liberar.
- **Geada / patinação (fase 2)**: `player_frost_stacks` (4 cargas, −10% de velocidade cada, congela e zera ao encher) e `player_ice_slip_timer` (inércia de direção no movimento). Ambos são locais. O Sineiro já envia `slow` para peers remotos no lugar da geada, então em MP o remoto sente lentidão mas não acumula cargas nem patina. Validar e decidir se a geada vira status replicado.
- `_apply_ice_slip` entra na leitura de movimento do jogador local e multiplica a velocidade por `_ice_slip_speed_mult()`. Fora do gelo o caminho é idêntico ao anterior (retorna o vetor sem tocar), então não deve alterar netcode de posição; confirmar com dois clientes que a reconciliação não briga com a inércia.

## 2026-11-11 — Auditoria de paridade solo/multiplayer retomada

- A reconciliação local real passou com servidor dedicado, host, cliente e,
  no fluxo completo, um segundo cliente: pronto, espectador, loja, rebobinar do
  chefe 1, 28 estágios de morte/revive nas sete fases, baralho individual,
  pontuação/entrada de chefe e início de partida.
- O corredor foi ampliado para executar os cenários de fio pelo papel correto;
  os falsos erros causados por invocar testes herdados sem `--role` foram
  eliminados. O teste de baralho deixou de fixar percentuais antigos e agora
  prova que o texto transportado pertence ao outro jogador.
- Geada/patinação do Sineiro agora preserva a regra solo no cliente: o dano
  confirmado fornece a primeira carga e eventos autoritativos transportam a
  carga restante e o piso escorregadio. O anel mantém também sua lentidão.
- Silêncio, Veneno e Inversão do Arauto foram rechecados no receptor com
  epoch/life-epoch e deduplicação; o corte de cura do chefe 6 foi comprovado no
  cliente pelo mesmo `source` de dano confirmado.
- Parasítica agora registra na autoridade as larvas e o dono da infestação de
  Mordida/Verme-Rei, consome as larvas no Devorar e confirma o abate infestado
  de volta somente ao dono. A confirmação é idempotente e estende a Simbiose
  no cliente; o snapshot público do Verme-Rei também foi provado.
- A execução da Lacerante iniciada por cliente não-host agora passa por pedido
  confiável: a autoridade valida manifestação, alvo, vida, alcance e linha do
  corte, reserva uma única vez, conclui o dano e confirma o Coágulo somente ao
  dono. O cenário real `lacerante-execution` passou com servidor, host e cliente.
- Ainda não encerrado nesta auditoria: barreira/regra de equipe para pactos pós-chefe; regra de
  equipe para Chips Quânticos (continuam deliberadamente desligados no MP);
  adaptação persistente da Mente da UMBRA no cooperativo; e uma prova pública
  ou em dois dispositivos físicos sob perda/latência.
- Um cenário sintético novo que tentava injetar todos os status ainda no lobby
  foi descartado do corredor: ele alternava entre entregar e descartar pacotes
  antes da transição de partida. As provas determinísticas ficaram, mas não foi
  registrado como evidência de fio real para esses quatro efeitos.

## 2026-11-12 — Oficina do Mercador (dimensão da loja)
- A Fenda do Mercador agora leva a uma dimensão jogável (`RTMerchantDimension`), **apenas no solo**: `enter()` retorna false com `is_multiplayer`, e a fenda cai no caminho antigo (tela de loja) em MP. O chip Corruptor continua tendo prioridade sobre os dois.
- A entrada troca `WORLD_SIZE`, guarda inimigos/projéteis/posição e devolve tudo na saída. Em MP isso nunca roda, mas se um dia rodar: a troca de mundo precisa ser replicada ou cada peer veria um mundo diferente. Decidir se a oficina é instanciada por jogador ou compartilhada.
- `RTMerchantNpc` guarda história vista, peças e missão em `user://merchant_npc.cfg` (por aparelho, não por run). Em MP, decidir de quem é o progresso da missão.
- Peças caem em `_kill_enemy` só no solo, usando a mesma definição de extraordinário do tutorial.
- A expulsão confisca a essência não gasta (`_apply_score_delta` negativo com `merchant_rift_collapse`). Em MP isso precisaria ser autoritativo por peer.

## 2026-11-12 (2) — Oficina do Mercador ligada no multiplayer
Revoga o bloco anterior: `enter()` **não** recusa mais `is_multiplayer`. Nada
disto foi provado online (MP congelado); é tudo raciocínio de código.

Regras implementadas, todas derivadas de estado que cada cliente já tem:
- **Entrada simultânea.** `merchant_rift_controller.enter()` já mandava
  `_rpc_trigger_shop(false)` antes de abrir; agora esse mesmo caminho leva cada
  peer para a oficina. A troca de `WORLD_SIZE` continua local, mas passa a ser
  simétrica: todo mundo entra e sai no mesmo evento.
- **Tempo da sala.** Cada um calcula `budget_cards()` = essência / preço da
  carta (entre 3 e 12) e anuncia no RPC **novo** `_rpc_merchant_rift_budget`.
  A sala fica com o maior: `limit` só cresce, nunca encolhe no meio da compra.
  O servidor dedicado repassa o pacote como faz com `_rpc_shop_ready`.
- **Saída coletiva.** Tocar o portal não tira ninguém: marca `mp_ready` e
  reaproveita `_rpc_shop_ready` como "cheguei na saída". O grupo só sai quando
  `mp_ready_total() >= shop_mp_expected_count`. Contamos **peers distintos**
  (`mp_ready_peers`) de propósito: `shop_mp_partner_ready` sozinho liberaria a
  sala de 3 com um único companheiro pronto.
- **Fechar a tela de cartas não espera ninguém.** `_commit_exit_or_finish()`
  chama `finish()` direto quando a oficina está ativa; o portão do grupo é o
  portal, não o visor.
- **Estouro do tempo.** Cada cliente avalia o próprio relógio (mesmo `limit`,
  mesmo início) e confisca a **própria** essência com `broadcast = false`. Com
  broadcast a réplica descartava o desconto e só o anfitrião perdia pontos.
- O id do evento de pontos virou `merchant_rift_collapse_<n>`: com o id fixo,
  a segunda expulsão da run era descartada como repetida pela deduplicação de
  `_apply_score_delta`.

Riscos que **continuam abertos** e precisam de prova em dois aparelhos:
1. `_rpc_merchant_rift_budget` é um método novo: cliente antigo (2.0.65) na
   mesma sala recebe erro de RPC desconhecido. Exige bump de versão mínima.
2. Posição dos jogadores remotos durante a troca de mundo: nos quadros entre o
   `_rpc_trigger_shop` e o `enter()` de cada peer, o remoto ainda manda
   coordenadas do mundo antigo e aparece fora do lugar na oficina.
3. O anfitrião limpa `core.enemies` ao entrar e restaura na saída: se os dois
   lados saírem em quadros diferentes, a horda restaurada pode divergir.

Mitigados nesta mesma passagem (também sem prova online):
- **Sala que encolhe.** `_refresh_mp_expectation()` recalcula
  `shop_mp_expected_count` a cada quadro a partir de
  `_living_run_player_peer_ids()`, esquece peers prontos que sumiram e entra
  `mp_ready` sozinho quando o jogador local está morto ou é espectador. Sem
  isso a sala travava esperando um toque que nunca viria.
- **Fenda estável só de um lado.** O progresso da missão continua por aparelho
  (`user://merchant_npc.cfg`), mas o anúncio de orçamento manda o sentinela
  `BUDGET_STABLE = -1` quando a fenda do jogador está estável, e quem recebe
  marca `mp_room_stable`. Basta um da sala ter entregue as peças para o relógio
  parar para todos — que é a leitura generosa e combina com a ficção.

## 2026-11-13 — Cena da fenda, empurrão, balões, Curater e Aglomerador

Validado só em solo (`tests/merchant_rift_transition_smoke.gd`,
`tests/curater_escort_smoke.gd`, `tests/agglomeration_spatial_smoke.gd`,
`tests/speech_bubble_smoke.gd`).

- **Cena de entrada/saída da fenda** (`RTMerchantRiftTransition`) é **só solo**:
  `enabled()` devolve falso com `is_multiplayer`, então a sala continua com a
  troca instantânea de antes. Nada novo em RPC/snapshot.
- **Empurrão da horda ao entrar** roda dentro de `RTMerchantDimension.enter()`
  também no multiplayer, sobre o `core.enemies` local antes de salvar. Na
  autoridade isso move a horda real; numa réplica o próximo snapshot manda.
  Dever: confirmar em dois aparelhos que a horda restaurada na saída fica fora
  do anel nos dois lados e não "salta" de volta.
- **Curater** passou a escoltar aliados (`_curater_move_dir`). Roda na
  autoridade dentro de `_move_enemy`; estado novo (`curater_escort_uid`,
  `curater_escort_timer`) fica no dicionário do inimigo. Dever: ver se o
  snapshot de inimigos não engorda nem perde a posição suavizada do Curater.
- **Aglomerador**: fusão agora em 5 s de bolo contínuo após 5:30, teto 2 vivos,
  respiro 28 s (`fusion_cooldown_timer`, fora do snapshot da run). Autoridade
  apenas, como antes.
- **Balões de fala** viraram `RTSpeechBubbles` genérico; só desenho local.

## 2026-11-15 — Relevo visual dos objetos sólidos do mapa

Validado somente em solo com `tests/map_props_collision_smoke.gd`, incluindo
render real normal e `--low`. A camada `RTMapPropPresentation` deriva a arte do
mesmo SDF e do mesmo `map_key` já usados localmente por
`RTMapPropColliders`; não acrescenta estado, dano, colisão, RPC ou snapshot.

Dever multiplayer: confirmar em duo/trio que host e clientes escolhem o mesmo
atlas/dimensão durante transições e veem o relevo na mesma célula, sobretudo na
fase 5 quando a dimensão reaproveita um terreno com obstáculos. A geometria de
colisão existente não foi alterada.

## 2026-11-15 — Henry Incendiário: ticks da HAB1 e stun da ultimate

Validado somente em solo com `tests/henry_incendiary_smoke.gd`. A HAB1 agora
divide o mesmo dano-base total do cone em cinco impactos durante 320 ms. Cada
impacto da ultimate renova 900 ms de stun em inimigos comuns, mini-chefes e
Arauto; chefes completos continuam sem stun. A confirmação autoritativa de
`henry_heat_wave` é o ponto que aplica o estado, inclusive para pedido de dano
de um Henry remoto, sem novo RPC, campo de snapshot ou mudança de assinatura.

Dever multiplayer: confirmar em duo/trio que os cinco pedidos de dano da HAB1
não são perdidos ou duplicados sob latência, que cada pulso remoto renova o stun
apenas no alvo atingido e que reconnect não preserva o temporizador local de
anti-deslizamento. O transporte visual existente não foi alterado.

## 2026-11-17 — Sorte Temporal e pressão do Larápio ferido

Validado somente em solo com `tests/runtime_progression_controller_smoke.gd`,
`tests/larapio_rework_smoke.gd`, `tests/phase2_sineiro_boreal_smoke.gd` e
`tests/phase6_amber_suturer_smoke.gd`. A Sorte Temporal agora converge para
40%, com 25% em uma hora. Recompensas aleatórias: Larápio 2 cartas, ou 3 sem
roubo; Sineiro e Suturador 1 carta. Cartas roubadas pelo Suturador continuam
sendo devolvidas e não contam como recompensa nova.

O Larápio com até 45% de vida e sem saque passa a pressionar em curta/média
distância e usa intervalo de arremesso entre 2,15 s e 1,8 s. Com saque, mantém
a fuga anterior. Não houve RPC, assinatura, snapshot, dano ou regra de roubo
nova; a autoridade continua no host.

Dever multiplayer: confirmar em duo/trio que a autoridade escolhe a mesma
postura ao cruzar 45% de vida, que o movimento replicado não oscila entre fuga
e aproximação sob atraso e que cada peer recebe exatamente a quantidade nova de
cartas, incluindo devolução de carta roubada pelo Suturador sem duplicação.

## 2026-11-17 — Rota nova do ciclo de farm + Sertão (8) e Cripta (9) no multiplayer

Pedido explícito do usuário para deixar 8 e 9 prontos para multiplayer. O Codex
integra e confirma a comunicação com a VPS.

### Rota
- A rota inicial não mudou: 1→2→6→3→4 ou 6→1→2→3→4.
- Depois do boss 4 aparece a escolha: Umbra x ciclo.
- Ciclo: fase 7, depois 3 fases sorteadas sem repetir de
  `DIMENSION_FARM_POOL = [1, 2, 3, 8, 9]`. Depois do 4º boss do ciclo, nova
  escolha.
- 8 e 9 deixaram de ser bônus por sorteio e agora são membros do ciclo. Com
  isso só podem aparecer a partir da 7ª dimensão.
- No multiplayer, o líder sorteia a rota uma vez e manda junto da ação. A ação
  `"farm"` virou `"farm:A,B,C"`, então todos seguem a mesma rota. Antes, cada
  peer sorteava a sua.

### Fase 8
- Já era autoritativa.
- Correção: a caixa do ricochete do Cágado-Pião centralizava no jogador local da
  autoridade. Agora centraliza no alvo do inimigo.

### Fase 9
Autoridade:
- Usa o cone de todos os jogadores. O cone dos remotos vem de
  `aim_dir`/`input_move` do sync de jogador já existente.
- Aplica dano nos remotos por `_send_peer_damage`.
- Manda efeitos aos remotos por um RPC novo, `_rpc_phase9_event_to_peer`, com os
  tipos `slow`, `root`, `stun` e `echo` (cura do eco).

Replica:
- Recebe `cripta_visual` e `boss9_visual` no pacote de visuais do mundo:
  - semente do mapa (pilastras iguais);
  - lamparinas, ecos, fios e teias;
  - estado das aranhas;
  - estado da Matriarca.
- Roda `update_replica`, que é local: breu, ondulações, sustos, aviso pelas
  costas, regeneração na luz e "não é alvo".
- Tiro da replica que acerta um fio vai para a autoridade por outro RPC novo,
  `_rpc_phase9_event_to_authority`.

Outras mudanças:
- `NET_ENEMY_TYPES` ganhou as 8 aranhas, no fim da lista.
- `RTNetContract.MAX_PHASE_INDEX` passou de 8 para 9. Antes, a replica voltava
  para a fase 8 ao receber o boss.

### Validado
Só no processo local, sem rede:
- `tests/multiplayer_phase9_parity_smoke.gd`: mapa, mundo, visão por jogador,
  chefe e rota compartilhada.
- `tests/multiplayer_phase8_parity_smoke.gd`
- `tests/multiplayer_phase_transfer_vote_smoke.gd`
- `tests/phase8_sertao_smoke.gd`
- `tests/phase9_cripta_smoke.gd`

### Dever multiplayer (duo/trio real, com o servidor da VPS atualizado)
1. **Rota:** depois de pegar o portal de ciclo, todos entram na 7 e depois
   nas mesmas 3 fases, na mesma ordem.
2. **Fase 9, chegada:** cliente e host veem as mesmas pilastras e lamparinas.
   O breu de cada um segue o próprio cone.
3. **Viúva:** congela quando qualquer jogador a encara e morde o cliente pelas
   costas. O dano chega no cliente.
4. **Fios da Noiva:** prendem e deixam lento o cliente. O tiro do cliente rompe
   o fio (3 tiros) e o fio some para todos.
5. **Eco de Luar:** quando o cliente pega, some para todos, cura o cliente e
   soma pontos.
6. **Matriarca:**
   - o feixe pega o cliente e ela dá o bote nele;
   - no Apagão, as quedas seguem o alvo e o cliente vê a sombra e leva susto;
   - no Mil Olhos, os olhos enxergam o cliente.
7. **Fase 8:** ricochete do Pião em volta do cliente; grazes e dano chegando
   nos dois.

### Compatibilidade
Há dois RPCs novos no `main.gd`. Cliente e sala precisam ser da mesma build,
porque os IDs de RPC mudam. Salas já abertas continuam no processo antigo; só
salas novas usam o projeto atualizado.

### Integração VPS e evidência de fio (2026-11-17)
- Os seis smokes locais passaram com `rc=0`, marcador `_OK` e zero erros fora da
  exceção de segurança offline. Paridade 9 e Cripta rodaram três vezes cada;
  logs em `/tmp/ruptura_phase89_final_1794964183/`. O smoke do Sertão passou a
  limpar áudio e cena antes de sair; o erro de recursos ainda em uso sumiu.
- Backup da árvore de jogo anterior na VPS:
  `/opt/ruptura/backups/phase89-before-20261118-012056.tar`. A sincronização
  preservou `server/`, `.godot/`, `godot/`, downloads, builds, dados e logs.
  Hashes de `main_runtime_core.gd`, `net_contract.gd`, os controladores da
  Cripta, sua apresentação e o atlas EX9 bateram entre desktop e VPS.
- Import headless como usuário `ruptura` e inicialização da cena principal
  passaram. Para a versão Godot 4.7 da VPS, o Boot headless usa o carregamento
  síncrono já existente; arquivos sincronizados receberam leitura para o
  processo da sala. A sala em standby foi reciclada pelo manager apenas com
  `rooms=0`, sem reiniciar `ruptura-relay`.
- `multiplayer_phase9_parity_smoke` e `multiplayer_phase8_parity_smoke` também
  passaram no Godot da VPS, sem erros, em processo único (não são duo real).
- Duo público pelo relay: primeira tentativa `C3B58D` expôs acesso direto à
  textura `enemy_phase_3_bullet` ainda não carregada no cliente. A apresentação
  passou a tolerar essa janela, preservando o desenho do projétil. Repetição
  `BD27CC`: `PUBLIC_TUNNEL_SOAK_OK`, host/cliente iniciaram a partida, 283
  snapshots aplicados pelo cliente, zero desconexões e zero erros de script.
  P95 do intervalo entre snapshots: 312 ms; ping P95 host 79 ms, cliente 51 ms.
  Logs locais em `.agent_logs/phase89_public_duo_retry/`; journal da sala sem
  `unknown method` ou `invalid packet`. A sala encerrou e o health voltou a
  `rooms=0`, `standby=1`.
- **Ainda devido pela rede:** os sete itens de “Dever multiplayer” acima não
  foram exercidos por esse duo automatizado (o cenário `full_flow` não entra
  nas fases 8/9). A rota, mundo, visão, Matriarca e Pião têm prova determinística
  local/VPS, mas isso não equivale a combate cooperativo real nessas fases.
  Viúva, Fios, Eco e ataques específicos da Matriarca continuam pendentes em
  duo com atalho de QA, inspeção visual e logs. Nenhum APK/cliente foi publicado.

### Adendo 2026-11-17 (noite) — Cripta: visão dos ecos, espreita da Matriarca, oficina do Mercador
- **Visão dos ecos:**
  - cada Eco de Luar soma +1 de visão (até 5) e reinicia 7 s;
  - a mordida da Mímica zera o bônus;
  - é LOCAL de cada jogador, porque chega pelo evento "echo" que já existia;
  - "dim" é um tipo novo do mesmo `_rpc_phase9_event_to_peer`, sem RPC novo.
- **Espreita da Matriarca:**
  - modos `espreita` e `ambush_warn`;
  - o aviso dura 0,5 s, depois vem o bote de 0,5 s;
  - o alvo vai no snapshot (`"ap"`), e quem é o alvo recebe vibração e som.
- **Oficina do Mercador na fase 8/9:** não desenha o chão, os tiros nem o breu da fase. Os fios da Cripta não seguram tiros nem deixam lento lá dentro.

Dever multiplayer:
1. O aviso da espreita aparece forte só no alvo e fraco nos outros.
2. O bônus de visão de um jogador não muda a visão do outro.
3. Dentro da oficina, durante a fase 9, ninguém vê pilastras nem breu.

### Adendo 2026-11-18 — Cripta: controle (laço/casulo), veneno, dano menor, pontos x1,75
- **Boleadeira e Armadeira** (`cripta_grapple.gd`):
  - a autoridade decide quem prende quem (`_held` por peer) e manda "grab"/"cocoon"/"release"/"poison" pelo `_rpc_phase9_event_to_peer`. O uid vai no `amount`; o repasse do servidor não corta mais esse valor (antes era limitado a 0..10).
  - O preso arrasta/prende a si mesmo, conta os próprios toques (cada toque conta, segurar não) e manda "escape" pelo `_rpc_phase9_event_to_authority`.
- **Snapshot:**
  - inimigos levam `gp` (quem está preso);
  - teias têm o tipo "bola" (2);
  - a dona da bola vai em `web_owners` (PackedInt64Array), porque o uid não cabe em float32.
- **Veneno** é local de cada jogador.
- **Pontos x1,75** na fase 9 valem para todos.

Dever multiplayer:
1. O cliente é laçado e arrastado; o host vê a linha de seda até o cliente.
2. O cliente se solta apertando ATK; a aranha fica tonta no host.
3. O host atira na aranha que prende o cliente e o cliente é solto.
4. Casulo no cliente: guarda envenena; o cliente vê o casulo em si, e o host vê o casulo no cliente.
5. Um jogador não pode ser preso por duas aranhas ao mesmo tempo, e depois de se soltar fica 2,5 s imune.

### Adendo 2026-11-18 — Fase 10, Bailão da Dona Boleta (só solo validado)
- A autoridade roda IA, garrafas, anéis, holofotes, a Roda e o Teor de cada jogador (`teor_by_peer`). O dano em jogador remoto vai por `_send_peer_damage`. **Nenhum RPC novo.**
- Snapshot pelo pacote de visuais do mundo:
  - `baile_visual`: batida (`bp`/`bpm`), garrafas, poças, anéis, tiros, Teor por peer, estados dos inimigos e da Lagartona;
  - `boss10_visual`: modo, holofotes e Roda.
- A réplica aplica no próprio jogador, localmente: empurrão do anel, colisão do palco, lentidão do gin e limite da Roda.
- Aproximação conhecida: o bloqueio da Sombrinha usa a posição do jogador da autoridade como origem do tiro.
- Evidência solo: `tests/phase10_baile_smoke.gd`, que inclui um round-trip de snapshot sem rede.

Dever multiplayer:
1. O cliente não sai da Roda e vê as dançarinas girando no mesmo ângulo do host.
2. O Teor e os efeitos visuais do cliente sobem só quando a garrafa acerta o cliente.
3. O BPM vira para 150 no cliente junto com o host, e o passinho continua sincronizado.
4. O holofote trava no cliente-alvo e o rojão só fere quem está no círculo.
5. Palco sólido e anel de grave empurram o cliente sem tremer.

### Adendo 2026-11-18 — lista de ajustes (fase 6, Lacerante, Mercador, ultimate) (só solo validado)
- **Pústula Fóssil / cordão umbilical** (`RTFossilPustuleTether`): o puxão gradual e a imunidade a outros inimigos são **locais**. Para um peer remoto a autoridade continua no caminho antigo (`_send_peer_hostile_reposition` instantâneo + estouro imediato). O cordão do puxão não é replicado; o cordão em voo é derivado do projétil (`source_enemy_pos`).
- **Laceração no Arauto/Aguilhão**: stacks e sangramento ficam em `arauto` (já replicado no snapshot do Arauto); o dano do sangramento sai por `_damage_arauto` na máquina do Lacerante.
- **Teleporte consome Laceração**: roda em `_execute_teleport` local; o dano vai por `_damage_enemy` (mesma rota de autoridade do corte normal).
- **Cápsulas da Barganha**: `shield`/`shield_max` entram no dicionário `bargain_capsule` (replicado inteiro pelo snapshot visual). Vida inicial usa o golpe típico dos inimigos da autoridade. A missão do Mercador (cápsulas salvas) só conta em solo.
- **Ultimate**: cancelamento de Lacerante/Gravitante/Barométrico envia `NET_ABILITY_SECONDARY_END`; preview da mira automática é só local.
- Evidência solo: `tests/fossil_pustule_cord_smoke.gd`, `tests/lacerante_feedback_smoke.gd`, `tests/bargain_capsule_shield_smoke.gd`, `tests/bargain_capsule_smoke.gd`, `tests/ultimate_cancel_autoaim_smoke.gd`.

Dever multiplayer:
1. Cliente atingido pelo cordão é arrastado (não teleportado) e não toma golpe de outros inimigos no caminho; host vê o cordão até o cliente.
2. Arauto/Aguilhão mostra os stacks do Lacerar no cliente e o sangramento não duplica dano.
3. Cliente Lacerante teleportando através de alvos marcados consome stacks uma vez só (sem duplicar dano no host).
4. Escudo da cápsula decai igual no host e no cliente; vida da cápsula coerente para o grupo.
5. Cancelar a ultimate no cliente encerra o visual remoto no host.

## 2026-11-18 — Fragmento Instável, Impulso de Ruptura e Colapso Dimensional

- Owner: `scripts/systems/phase/dimension_rupture_controller.gd` (fachada `_dimension_rupture()` no core). Host decide ativação, relógio, faixa, Impulso, token, emergência, destino, ejeção e Desorientação; réplicas só aplicam `packet["rupture"]` (snapshot compacto) no pacote de mundo existente (`runtime_boss_visual_sync_controller.gd`). Ejeção reutiliza `_rpc_commit_phase_transfer` com a ação `rupture_eject` quando o host é o servidor ENet; em sala dedicada (ou com o RPC perdido) a réplica segue `last_resolution` do snapshot, uma vez por `event_id`. Nenhum RPC novo.
- Evidência solo/contratual: `tests/dimension_rupture_smoke.gd`, `tests/dimension_rupture_contract_smoke.gd` (host e réplicas duo/trio num só processo, sem rede) e `tests/dimension_rupture_visual_smoke.gd`. Não é prova multiplayer.
- Devido (transporte real): host+1 cliente; host+2 clientes; reconnect durante `unstable` (relógio não reinicia, sem recompensa repetida); reconnect durante `emergency` (mesmo `dst`); um peer dentro e outro fora do portal (todos acompanham a transição do grupo); peer derrubado durante a emergência (é carregado, não bloqueia, piso de 50% de vida não o revive); pacote duplicado e atraso artificial (sem 2º token, Impulso, cura ou transição); host encerrando a dimensão no último segundo (corrida entre consenso de travessia e ejeção); duas travessias rápidas seguidas (Impulso II e token consumido uma vez pelo grupo); ejeção completa sem dividir o grupo (sala P2P e sala dedicada).
- Risco conhecido: snapshot atrasado de uma run anterior chegando depois do primeiro snapshot da run nova seria aceito (o `run_id` difere); depende da ordenação do pacote de mundo. Em sala dedicada, o caminho da ejeção pelo snapshot depende do envio de pacotes de mundo enquanto o host está em `phase_transition`.

## 2026-11-18 — Lote: escolha aleatória, loja, Cinzas, Mercador, Espreitador, UMBRA (só solo validado)

- **Escolha aleatória no carrossel** (`_build_random_slot_enabled`, `BUILD_RANDOM_INDEX`): só nas telas solo (`manifest`, `mutation_select`, `effect_select`). `manifest_mp`, `mutation_select_mp` e `effect_select_mp` continuam sem o slot e com o giro antigo; o botão ALEATÓRIO antigo do rodapé segue valendo só nesses modos.
- **Cinzas da Escolha** (`_spawn_supreme_cinzas_drop`): só a autoridade gera, uma por peer (`_reward_peer_ids`), pelo mesmo `arauto_card_drops` dos outros prêmios; marcada `no_rupture_token`. Fontes: Larápio, Sineiro, Suturador, Arauto/Aguilhão. Cinzas e Moeda Estável saíram de `_shop_card_eligible_for_roll` e `_card_available_for_reward` (loja e sorteios de prêmio de todos os peers).
- **Vaga queimada reabastecida**: loja é local de cada jogador; nenhum pacote novo.
- **Mercador**: fenda estável e encomendas valem por run (`RTMerchantNpc.begin_run` em `_start_game`; estado em `merchant_dimension_state.npc_run`). Encomendas só existem no balcão narrativo (solo). Física da oficina (`RTMerchantWorkshopPhysics`) é local e cosmética (+ colisão do jogador local); não vai para a rede.
- **Espreitador camuflado**: `_damage_enemy` recusa dano e a mira automática ignora enquanto `invisible` (já replicado no pacote de inimigos). Recarga `camo_ready_at` só na autoridade.
- **Racional na oficina**: `_update_shop` passa a rodar `_update_aura` quando a oficina está ativa; o relógio da fenda usa `AuraSystem.world_multiplier` de cada cliente (relógio já era local por cliente, com o maior orçamento da sala).
- **UMBRA**: arrancada ao centro e giro do laser na autoridade (o hazard já é replicado); desenho do feixe usa o tamanho do mapa local.
- Evidência solo: `tests/gameplay_batch_nov18_smoke.gd`, `tests/gameplay_batch_nov18_capture.gd` (capturas em `.codex/nov18/`), `tests/boss_farm_balance_smoke.gd`, `tests/umbra_intro_smoke.gd`, `tests/support_cards_smoke.gd`.

Dever multiplayer:
1. Host e cliente derrotam um Larápio/Arauto: cada um vê e pega só a própria Cinzas; nenhuma Cinzas/Moeda aparece em loja nem em drop de prêmio.
2. Cliente acerta um Espreitador camuflado com disparo e habilidade: nenhum dano chega ao host; o alvo automático do cliente não o escolhe até revelar.
3. Cliente Racional dentro da oficina com a loja aberta: Dilatação segura o relógio local sem dessincronizar a saída coletiva.
4. Laser da UMBRA no cliente: arrancada e giro idênticos ao host, feixe atravessando o mapa inteiro.
5. Sala com `manifest_mp`/`mutation_select_mp`: confirmar que o carrossel não mostra o slot ALEATÓRIA nem quebra o giro.

## 2026-11-19 — Lote: Lagartona e fenda, atalhos, modo de cor, Espreitador, teleporte, Curater, Rebobinador (só solo validado)

- **Lagartona do Paredão** (`scripts/systems/phase10/baile_lagartona.gd`): Trenzinho 720 px/s e 420 px além do alvo. Com a Fenda do Mercador aberta (`opening`/`open`, sem mergulho), ela deixa de atacar, anda até a fenda a 1,6x e, se a cabeça encostar (`ENTER_RADIUS + SEGMENT_RADIUS`), chama `collapse(false)`: fenda fecha sem fragmento e volta pela cadência normal (`RETRY_AFTER_COLLAPSE`). Tudo dentro de `update_enemy` (autoridade); a fenda colapsada já viaja no snapshot `shop_rift`. Textos "FAREJOU/ENGOLIU A FENDA" são `_add_text` locais do host.
- **Espreitador**: `stalker_close_mult` calculado na autoridade e aplicado em `_move_enemy`; réplicas só recebem posição.
- **Rebobinador**: armadura leve (15%) em `_damage_enemy` depois do ramo de pedido do cliente (só a autoridade aplica); +35% de movimento em `_move_enemy` pela flag `reconstituted_once` (autoridade).
- **Curater**: velocidade de spawn 0,675x (antes 0,45x), autoridade.
- **Teleporte**: `_player_invulnerable` local; Lacerante sem alvo atravessado não fica imune e a Descarga da Elétrica deixou de dar imunidade.
- **Atalhos/M1 no cursor, padrão da primeira instalação, modo de cor**: só cliente local, sem rede.
- Evidência solo: `tests/gameplay_batch_nov19_smoke.gd`.

Dever multiplayer:
1. Fase 10 com host+cliente: Lagartona viva e fenda aberta — ambos veem ela ir até a fenda e a fenda fechar; nenhum peer entra numa fenda já engolida; ninguém ganha fragmento.
2. Cliente acerta reconstituído do Rebobinador: o dano que chega ao host sai 15% menor uma única vez (sem dupla redução no cliente).
3. Cliente Lacerante (sem alvo) ou Elétrica teleporta perto de inimigos do host: o dano de contato chega normalmente.
4. Espreitador/Curater/reconstituído no cliente: movimento interpolado sem trancos com as velocidades novas.

## 2026-11-19 — Rede do Petro (fusão de DNA dos chefes) e Inimigos Supremos só com pontos (só solo validado)

- **DNA**: `RTBossDnaController.on_boss_defeated` roda onde `_damage_boss` mata o chefe (autoridade). Clientes ainda NÃO recebem DNA por rede: falta replicar a morte do chefe para o banco de cada peer (um DNA por jogador vivo).
- **Habilidades**: efeitos no mundo (dano, lentidão, congelamento, puxão, onda, zona, órbita, rewind dos inimigos) só rodam se `_is_world_authority()`; efeitos pessoais (cura, escudo, guarda, invulnerabilidade, rewind da própria posição/vida) rodam no dono. Habilidades de cliente hoje só aplicam a parte pessoal; falta pedido ao host (RPC) para a parte de mundo.
- **Máquina/tela**: em sala multiplayer não há fala; encostar abre a tela direto (`dna_fusion` pausa só o mundo local). Falta validar a saída coletiva da oficina com alguém na tela de fusão.
- **Supremos**: `RTSupremeEnemyRewards.grant` usa `_apply_score_delta(..., broadcast=true)` na autoridade; Cinzas agora cai do chefe por `_spawn_supreme_cinzas_drop` (já por peer).
- Evidência solo: `tests/boss_dna_fusion_smoke.gd`, capturas `tests/boss_dna_capture.gd`.

Dever multiplayer:
1. Host+cliente matam o chefe 1: cada um recebe 1 DNA (hoje só o host) e uma Cinzas.
2. Cliente com Maré Cósmica: todos os inimigos do host desaceleram 15 s.
3. Cliente com Distorção do Relógio leva golpe letal: não morre, volta 10 s localmente, inimigos do host não teleportam de forma inconsistente.
4. Cliente na tela de fusão enquanto o host toca a saída da oficina: a saída espera ou fecha a tela sem perder a fusão paga.
5. Arauto/Sineiro/Suturador/Larápio mortos por cliente: pontos creditados uma vez para a sala.

## 2026-11-24 — Lote: oficina sala segura, Racional, conversa sem tempo, fonte, UMBRA manual, Corruptor só no Drop, Profecia (só solo validado)

- **Oficina = sala segura** (`RTMerchantDimension.seals_phase_world`): com a oficina ativa a autoridade não atualiza horda, spawns, Arauto/Larápio, chefe, projéteis inimigos, hazards, clima, fragmento nem altar; `enforce_seal` limpa e conta qualquer inimigo/projétil que apareça; `_damage_player` não aplica dano. Réplicas recebem a horda vazia do host (todos entram juntos).
- **Conversa com o Mercador**: o relógio local da fenda não corre em nenhuma fala (menu incluído); continua local por cliente com o maior orçamento da sala.
- **Racional**: Análise parada soma 10x no placar interno (+7 visíveis) e congela quando o relógio da oficina está parado; pontos via `_apply_score_delta` (réplica pede à autoridade).
- **Corruptor Mercantil**: só liga no modo Drop; `prepare_team_config` (host) filtra pelo modo; `on_run_started` também filtra no cliente.
- **Profecia** (`RTPropheticRewind`): DESLIGADA em multiplayer (`available()` exige solo). Voltar o mundo de uma sala exige autoridade + snapshot replicado.
- **Fonte das conversas / UMBRA manual**: só cliente local.
- Evidência solo: `tests/gameplay_batch_nov24_smoke.gd` (fases 1-10 na oficina, Racional, relógio, fonte, chip, Profecia).

Dever multiplayer:
1. Host+cliente na oficina por 30 s em cada fase (1-10): nenhum inimigo/projétil aparece para nenhum dos dois; ao sair, a horda volta igual nos dois.
2. Cliente conversando com o Mercador enquanto o host anda: relógios locais coerentes e saída coletiva intacta.
3. Cliente Racional parado na oficina com a loja aberta: pontos creditados uma vez pela autoridade.
4. Lobby em modo Loja com Corruptor marcado no host: ninguém recebe fichas "?"; em modo Drop todos recebem.
5. Profecia em sala: decidir regra (só buff local sem rewind, ou rewind autoritativo da sala) antes de liberar.

## 2026-11-22 — Fechamento público da 2.1.3

- Fonte e sala dedicada sincronizadas a partir da árvore 2.1.3; backup anterior em
  `/opt/ruptura/backups/pre-release-2.1.4-20261122.tar`. Import headless e boot
  no Godot 4.7 da VPS passaram sem erro de parse. O standby antigo foi reciclado
  pelo manager somente com `rooms=0`, sem reiniciar `ruptura-relay`.
- Correção de contrato: `MAX_PHASE_INDEX=10` e seis tipos de inimigo da fase 10
  acrescentados ao fim de `NET_ENEMY_TYPES`, sem deslocar índices antigos.
  O teste de round-trip de fase/identidade e `phase10_baile_smoke` passaram três
  vezes; a referência de volta da Lagartona ao controller é fraca, eliminando
  o ciclo de recursos ao sair.
- Seis testes de fases 8/9/rota passaram com `rc=0`, `_OK` e sem erros fora da
  exceção de segurança offline; os dois testes aleatórios da fase 9 rodaram
  três vezes. A reconciliação local de três processos passou em 16 cenários,
  incluindo seleção, reviver/derrota, loja, pós-boss, chips e fases 8–10.
- Salas públicas com host e cliente passaram em `ready`, `spectator`,
  `gameplay`, `altar`, `shop`, `aftermath`, `chips`, `phase8`, `phase9` e
  `phase10`. Logs locais em `/tmp/ruptura-213-public-release.log`,
  `/tmp/ruptura-213-public-chips-retry.log` e
  `/tmp/ruptura-213-public-phase8910.log`. O primeiro teste público de chips
  terminou em `game_over` porque o fixture avançava `time_alive` para 1000 s;
  o fixture passou a usar 26 s e proteção temporária contra inimigos ambientes.
  A repetição completou coleta, resgate, entrada e saída da loja nos dois peers.
- Soak público de 60 s: `PUBLIC_TUNNEL_SOAK_OK`, zero desconexões durante a
  partida, 370 snapshots de mundo aplicados no cliente. Ping P95: host 202 ms,
  cliente 347 ms; intervalo P95 entre snapshots 217 ms, máximo 2133 ms.
  Relatório em `.agent_logs/release_2_1_3_public_soak/report.json`.
  `/health` voltou a `rooms=0`, `standby=1` depois dos testes.
- No stdout da sala não houve `unknown method`, `invalid packet` nem erro de
  script nas partidas aprovadas. Houve duas mensagens ENet `Unable to send
  packet on channel 0, max channels: 0` quando os dois clientes dos cenários
  `ready`/`spectator` encerraram quase juntos; a sala encerrou normalmente.
- **Cobertura ainda devida:** os sete combates específicos da Cripta/Sertão
  descritos acima não foram todos jogados visualmente em duo; `phase9` provou
  snapshot, Eco, laço/escape e ruptura de fio, mas não toda a IA da Viúva,
  Noiva e Matriarca. `phase8` provou identidade e snapshot, não o ricochete do
  Pião em combate. `phase10` provou inimigo, BPM 150 e estado do boss na rede,
  não a Roda, Teor, holofote, anel e colisão do palco em combate cooperativo.
  O soak headless não substitui uma run longa com dois dispositivos nem prova
  Windows executado ou Android físico.
