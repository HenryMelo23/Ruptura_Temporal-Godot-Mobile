# Runtime Symbol Index

Generated for navigation, not as an exhaustive API reference. For files over
100 KB, search the exact symbol and open a small line window.

## Current Metrics

Metrics come from `python3 tools/check_architecture_budget.py --json`.
`code_loc` excludes blank and comment-only lines.

| File | Physical LOC | Code LOC | Functions | Largest function |
| --- | ---: | ---: | ---: | --- |
| `scripts/main_runtime_core.gd` | 46378 | 39807 | 3185 | `_handle_key` 456 code LOC |
| `scripts/main_runtime_state.gd` | 3524 | 3488 | 1 | `_safe_load` 5 code LOC |
| `scripts/presentation/combat_effects_presentation.gd` | 4063 | 3719 | 99 | `_draw_projectiles` 327 code LOC |
| `scripts/presentation/lightning_presentation.gd` | owner | owner | owner | `bolt`, `contact`, `channel`, `visible_segments`; shared render-only electrical geometry and silhouette protection |
| `scripts/presentation/combat_text_presentation.gd` | owner | owner | owner | `add_damage`, `draw`; merged damage numbers, critical animation and disabled allocation guard |
| `scripts/systems/ranged_attack_range.gd` | owner | owner | owner | `attack_range`, `damage_multiplier`, `configure_bullet`, `advance_bullet`, `draw_range_indicator`; shared ranged-primary range contract |
| `scripts/presentation/menus_presentation.gd` | 3073 | 2729 | 102 | `_draw_manifest_select` 176 code LOC |
| `scripts/presentation/world_environment_presentation.gd` | 2543 | 2384 | 56 | `_draw_boss_attacks` 375 code LOC |
| `scripts/ui/shop_controller.gd` | 701 | 586 | 51 | `handle_touch` 82 code LOC |
| `scripts/ui/shop_presentation.gd` | 938 | 814 | 28 | `draw_legacy` 326 code LOC |
| `scripts/systems/telemetry/telemetry_system.gd` | 534 | 488 | 22 | `build_minimal_session_payload` 127 code LOC |
| `scripts/systems/events/runtime_event_director.gd` | owner | owner | owner | `on_enemy_killed`, `active_snapshot` |
| `scripts/systems/events/runtime_event_catalog.gd` | owner | owner | owner | `CONFIG`, `EVENTS` |
| `scripts/systems/enemies/phase3_enemy_controller.gd` | owner | owner | owner | `update_enemy`, `movement_speed_multiplier`; Phase 3 enemy family behavior |
| `scripts/systems/events/phase3_ritual_pulse_controller.gd` | owner | owner | owner | `update`, `update_devotee`, `on_enemy_defeated`, `active_snapshot` |
| `scripts/presentation/phase3_ritual_pulse_presentation.gd` | owner | owner | owner | `draw` |
| `scripts/systems/events/phase4_instability_pulse_controller.gd` | owner | owner | owner | `update`, `active_snapshot`, `apply_remote_snapshot` |
| `scripts/presentation/phase4_instability_pulse_presentation.gd` | owner | owner | owner | `draw` |
| `scripts/systems/bosses/boss4_instability_fissure_controller.gd` | owner | owner | owner | `update`, `cast_now`, `force_cast_for_test` |
| `scripts/presentation/boss4_instability_fissure_presentation.gd` | owner | owner | owner | `draw` |
| `scripts/systems/online/net_contract.gd` | 365 | 342 | 11 | `unpack_enemy_snapshot` 77 code LOC |
| `scripts/systems/audio/audio_lifecycle.gd` | 357 | 292 | 32 | `on_music_finished` 20 code LOC |
| `scripts/systems/enemy_manager.gd` | owner | owner | owner | `update_enemies`, `rebuild_spatial_index`, `avoidance_neighbors`, `apply_entity_separation` |
| `scripts/systems/boss_party_scaling.gd` | owner | owner | owner | `profile_for_party_size` |
| `scripts/systems/manifest_evolutions/manifest_evolution_catalog.gd` | owner | owner | owner | `all_entries`, `entries_for_manifestation`, `validate_catalog` |
| `scripts/presentation/gravitante_vfx_presentation.gd` | owner | owner | owner | `lod`, `projectile`, `orbitals`, `collision`, `teleport`, `ultimate` |
| `scripts/systems/modern_boss_controller.gd` | 520 | 453 | 30 | `update_boss7_state` 70 code LOC |
| `scripts/presentation/boss_wave_presentation.gd` | 127 | 97 | 4 | `_draw_boss_wave_crest_and_foam` 49 code LOC |
| `scripts/systems/phase/phase_flow_controller.gd` | 624 | 555 | 34 | `_advance_to_phase` 191 code LOC |
| `scripts/systems/phase/experimental_phase_controller.gd` | owner | owner | owner | `prepare_new_run`, `activate_after_phase_setup`, `update`; isolated FaseEX exploration and altar contract |
| `scripts/systems/assets/runtime_asset_controller.gd` | owner | owner | owner | `should_stream_phase_assets`, `should_lazy_gallery_assets`, `release_transient_gallery_assets`, `prepare_phase`, `ensure_key`, `phase_keys` |
| `scripts/systems/progression/runtime_progression_controller.gd` | 249 | 181 | 33 | `elite_point_multiplier` 19 code LOC |
| `scripts/systems/cards/roguelike_point_card_controller.gd` | owner | owner | owner | `on_enemy_defeated`, `on_player_damaged`, `critical_damage_multiplier`, `extra_card_copies`; triggered point, critical and duplication cards |
| `scripts/systems/save/runtime_save_controller.gd` | 654 | 605 | 33 | `_load_config` 117 code LOC |
| `scripts/systems/player/player_control_controller.gd` | owner | owner | owner | `read_move`, `aim_direction`, touch/gamepad/desktop input routing, Parasítica HAB1 and Lacerante ultimate quick-versus-held aiming |
| `scripts/lacerante_sprites.gd` | owner | owner | owner | `register`, `snapshot`, `draw_height`; canonical Lacerante movement/attack/Q/ultimate frame selection for local and remote players |
| `scripts/systems/umbra_observation_schema.gd` | owner | owner | owner | `build_from_runtime`, `build_from_snapshot`, `validate_observation` |
| `scripts/systems/online/umbra_authority_controller.gd` | owner | owner | owner | `build_authoritative_decision`, `revalidate_before_execution`, `accept_replica_event` |
| `scripts/systems/umbra_neural_runtime.gd` | owner | owner | owner | `create`, `forward`, `contract_error` |

## Runtime Lookup

| Need | Search symbol | Owner / window start |
| --- | --- | --- |
| Startup setup | `_ready` | `scripts/main_runtime_core.gd:31` |
| Run start/reset | `_start_game` | `scripts/main_runtime_core.gd:6064` |
| Frame update | `_process` | `scripts/main_runtime_core.gd:8096` |
| Draw orchestration | `_draw` | `scripts/main_runtime_core.gd:34136` |
| Shop open | `_open_shop` | `scripts/main_runtime_core.gd:29351` then `RTShopController.open_shop` |
| Shop visit reset | `_begin_shop_visit` | `scripts/main_runtime_core.gd:29492` |
| Shop card roll | `_roll_shop_cards_v2` | `scripts/main_runtime_core.gd:29705` |
| Shop lock preservation | `_apply_locked_shop_slots` | `scripts/main_runtime_core.gd:29406` |
| Shop UI/economy owner | `class_name RTShopController` | `scripts/ui/shop_controller.gd:2` |
| Shop reroll | `func reroll` | `scripts/ui/shop_controller.gd:411` |
| Shop paid reroll cost | `next_paid_reroll_cost` | `scripts/ui/shop_controller.gd:135` |
| Shop drawing | `func draw` | `scripts/ui/shop_presentation.gd:382` |
| Triggered point/critical card owner | `class_name RTRoguelikePointCardController` | `scripts/systems/cards/roguelike_point_card_controller.gd`; kill drop, damage reward, final critical multiplier and non-legendary duplication contracts |
| Legacy shop drawing | `func draw_legacy` | `scripts/ui/shop_presentation.gd:502` |
| HUD render and responsive layout | `HudPresentation._draw_hud`, `HudPresentation.update_button_layout` | `scripts/presentation/hud_presentation.gd`; core keeps `_draw_hud` / `_update_button_layout` wrappers |
| Telemetry facade | `_record_telemetry_shop_reroll` | `scripts/main_runtime_core.gd:2292` |
| Telemetry owner | `class_name RTTelemetrySystem` | `scripts/systems/telemetry/telemetry_system.gd:1` |
| Shop reroll telemetry | `record_shop_reroll` | `scripts/systems/telemetry/telemetry_system.gd:191` |
| Minimal telemetry payload | `build_minimal_session_payload` | `scripts/systems/telemetry/telemetry_system.gd:273` |
| Runtime event owner | `class_name RTRuntimeEventDirector` | `scripts/systems/events/runtime_event_director.gd:1` |
| Runtime event config | `const CONFIG` | `scripts/systems/events/runtime_event_catalog.gd:6` |
| Runtime event kill charge | `on_enemy_killed` | `scripts/systems/events/runtime_event_director.gd:53` |
| Runtime event sync snapshot | `active_snapshot` | `scripts/systems/events/runtime_event_director.gd:89` |
| Phase 3 enemy family behavior | `Phase3EnemyController.update_enemy` | `scripts/systems/enemies/phase3_enemy_controller.gd`; authority-only behavior for Devoto, Incensário, Flagelante, Salmodiante and Portador de Relicário |
| Phase 3 enemy family cadence | `EnemyManager.special_kind_unlock_time`, `paced_special_type` | `scripts/systems/enemy_manager.gd`; onboarding/experienced unlocks and bounded simultaneous counts |
| Phase 3 ritual pulse owner | `class_name RTPhase3RitualPulseController` | `scripts/systems/events/phase3_ritual_pulse_controller.gd:1` |
| Phase 3 ritual devotee routing | `update_devotee`, `on_enemy_defeated` | `scripts/systems/events/phase3_ritual_pulse_controller.gd` |
| Phase 3 ritual visual snapshot | `active_snapshot`, `apply_remote_snapshot` | `scripts/systems/events/phase3_ritual_pulse_controller.gd`; transported by `runtime_boss_visual_sync_controller.gd` |
| Phase 3 ritual presentation | `Phase3RitualPulsePresentation.draw` | `scripts/presentation/phase3_ritual_pulse_presentation.gd`; world environment keeps only the phase routing call |
| Phase 4 instability pulse owner | `class_name RTPhase4InstabilityPulseController` | `scripts/systems/events/phase4_instability_pulse_controller.gd`; owns cadence, fragments, collection, reward, failure pressure and snapshots without writing `boss4_instability` |
| Phase 4 instability pulse presentation | `Phase4InstabilityPulsePresentation.draw` | `scripts/presentation/phase4_instability_pulse_presentation.gd`; renders immutable controller snapshots |
| Boss 4 instability fissure owner | `RTBoss4InstabilityFissureController.update`, `cast_now` | `scripts/systems/bosses/boss4_instability_fissure_controller.gd`; owns cadence, recent-position history, living-target rotation, fixed-party coverage, event IDs and safe-corridor geometry |
| Boss 4 instability fissure damage | `RTBoss4InstabilityFissureController.resolve_hazard` | `scripts/systems/bosses/boss4_instability_fissure_controller.gd`; authority-only hit resolution, safe-corridor exclusion and one hit per stable peer ID; core wrapper only routes |
| Boss 4 instability fissure presentation | `RTBoss4InstabilityFissurePresentation.draw` | `scripts/presentation/boss4_instability_fissure_presentation.gd`; renders warning, active fracture, safe corridor and dissipation from replicated hazard snapshots |
| Boss 4 authoritative FSM | `RTBoss4Controller.update`, `request_contextual_action`, `snapshot`, `apply_remote_snapshot` | `scripts/systems/bosses/boss4_controller.gd`; owns locomotion, per-peer contact cooldown, four-stage contextual attack choice and exact action timing |
| Boss 4 animation presentation | `RTBoss4AnimationPresentation.visual_state`, `active_texture`, `draw_death` | `scripts/presentation/boss4_animation_presentation.gd`; maps the replicated FSM to the original Nexo Anfíbio atlas while preserving a fixed in-game scale and bottom pivot |
| Online packet contract | `class_name RTNetContract` | `scripts/systems/online/net_contract.gd:1` |
| Player visual snapshot | `RTVisualSyncContract.pack_player_visual`, `unpack_player_visual` | `scripts/systems/online/runtime_visual_sync_contract.gd`; fixed-stride schema on unreliable ordered player channel; movement/aim/action intent complements authoritative position and animation frame |
| Ability visual event | `RTManifestationVisualSnapshot.capture`, `RTVisualSyncContract.sanitize_ability_payload`, `_send_network_ability_visual`, `_rpc_ability_visual`, `_rpc_ability_visual_patch` | schema 3 replays canonical local presentation state through the same renderers; reliable start plus bounded 250 ms unreliable-ordered corrections for long Q/E effects; stable event ID and peer sequence; presentation only, never damage authority |
| Boss visual packet owner | `RTBossVisualSyncController.pack`, `apply` | `scripts/systems/online/runtime_boss_visual_sync_controller.gd:1`; core retains `_pack_net_boss_visuals` and `_apply_remote_boss_visual_snapshot` compatibility facades while RPC dispatch remains on `Main` |
| Online lobby handshake owner | `class_name RTLobbyController` | `scripts/systems/online/runtime_lobby_controller.gd`; RPC node path/configuration remains on `Main` |
| Revive lifecycle owner | `class_name RTRuntimeReviveController` | `scripts/systems/online/runtime_revive_controller.gd`; core keeps `_update_team_revival`, altar and RPC facades |
| Team revive state snapshot | `class_name RTTeamRevivalState` | `scripts/systems/online/team_revival_state.gd` |
| Audio lifecycle | `class_name RTAudioLifecycle` | `scripts/systems/audio/audio_lifecycle.gd:1` |
| Enemy updates and spatial separation | `update_enemies`, `rebuild_spatial_index`, `apply_entity_separation` | `scripts/systems/enemy_manager.gd` |
| Enemy spawning | `spawn_wave` | `scripts/systems/enemy_manager.gd:143` |
| Phase 2 Sineiro owner | `class_name RTPhase2SineiroBorealController` | `scripts/systems/enemies/phase2_sineiro_boreal_controller.gd:1` |
| Phase 2 Sineiro VFX | `class_name RTPhase2SineiroPresentation` | `scripts/presentation/phase2_sineiro_presentation.gd:1` |
| Phase 6 Suturador owner | `class_name RTPhase6AmberSuturerController` | `scripts/systems/enemies/phase6_amber_suturer_controller.gd:1` |
| Phase 6 Suturador VFX | `class_name RTPhase6AmberSuturerPresentation` | `scripts/presentation/phase6_amber_suturer_presentation.gd:1` |
| Manifest evolution catalog | `class_name RTManifestEvolutionCatalog` | `scripts/systems/manifest_evolutions/manifest_evolution_catalog.gd:2` |
| Acorrentada evolution owner | `RTAcorrentadaEvolutionController.on_combo_resolved`, `on_hit`, `on_skill`, `on_teleport`, `on_sentence_started`, `update_effects`, `draw_world` | `scripts/systems/manifest_evolutions/acorrentada_evolution_controller.gd`; 12 ID-specific, save-contained contracts with capped persistent collections and no projectile dependency |
| Ancorada evolution owner | `RTAncoradaEvolutionController.on_anchor_placed`, `on_hit`, `on_skill`, `on_teleport`, `on_ultimate_started`, `update_effects`, `draw_world` | `scripts/systems/manifest_evolutions/ancorada_evolution_controller.gd`; 12 ID-specific structural contracts with capped walls/domains/lines/fortresses/monuments, structure HP and sampled collision scans |
| Lacerante melee evolution adapter | `RTLaceranteEvolutionController.on_hit`, `update_effects` | `scripts/systems/manifest_evolutions/lacerante_evolution_controller.gd`; five projectile-shaped legacy IDs resolve through real melee hits, with capped persistent wounds and non-recursive chains |
| Manifest evolution option source | `_manifest_evolution_entries` | `scripts/main_runtime_core.gd:7566` |
| Manifest evolution projectile hook | `_apply_manifest_evolution_to_bullet` | `scripts/main_runtime_core.gd:7836` |
| Manifest evolution impact hook | `_manifest_evolution_on_projectile_hit` | `scripts/main_runtime_core.gd:7926` |
| Ranged primary range contract | `RTRangedAttackRange.configure_bullet`, `advance_bullet`, `draw_range_indicator` | `scripts/systems/ranged_attack_range.gd`; core retains attack gating, collision and RPC routing while combat presentation draws the subtle boundary/fade |
| Boss 7 state | `update_boss7_state` | `scripts/systems/modern_boss_controller.gd:35` |
| Boss 7 ultimate | `check_boss7_ultimate` | `scripts/systems/modern_boss_controller.gd:427` |
| Boss party scaling contract | `profile_for_party_size` | `scripts/systems/boss_party_scaling.gd:13` |
| Shared boss attack contract | `RTSharedBossAttackContract` | `scripts/systems/bosses/shared_boss_attack_contract.gd:1`; Boss 2 Hunt Mark delegates target rotation, event metadata and idempotent hit/visual claims |
| Ability controller base | `RTAbilityControllerBase` | `scripts/systems/abilities/ability_controller_base.gd:1`; runtime binding bridge for incremental manifestation extraction |
| Necronada ability owner | `RTNecronadaAbilityController.try_use_skill`, `update_remnants` | `scripts/systems/abilities/necronada_ability_controller.gd:1`; core retains `_try_use_necronada_skill` and `_update_necronada_remnants` compatibility facades |
| Ancorada ability owner | `RTAncoradaAbilityController.update`, `trigger_hab1`, `spawn_ultimate`, `on_projectile_hit`, `on_teleport` | `scripts/systems/abilities/ancorada_ability_controller.gd:1`; owns the mobile-territory rework while core retains public compatibility facades and shared save/network fields |
| Henry Incendiário owner | `RTHenryIncendiaryAbilityController.on_player_damaged`, `fire_auto_attack`, `begin_skill`, `cast_ultimate` | `scripts/systems/abilities/henry_incendiary_ability_controller.gd`; owns friction accumulation, periodic Incandescência release, per-target dwell scaling and existing burn kit while runtime fields remain save/network compatible |
| Henry Barométrico owner | `RTHenryBarometricAbilityController.fire_auto_attack`, `on_henry_auto_fired`, `begin_skill`, `cast_ultimate`, `update_projectile`, `visual_snapshot` | `scripts/systems/abilities/henry_barometric_ability_controller.gd`; owns pressure autos, the mobile low-pressure corridor, the mobile Eye of the Storm and independent Nimbo duplication. `scripts/presentation/henry_barometric_presentation.gd` renders the same bounded snapshot for local and remote players without owning damage. Walk/attack/cast v1 atlases preserve approved Henry cells; `henry_barometric_ultimate_sheet_v2.png` provides eight new palette/pixel/anchor-normalized poses rebuilt by `tools/build_henry_barometric_sprites.py`. The 0.55 s Barometric windup consumes all eight frames, pure back buckets remove tie-blue pixels, and intro stays shared. Tests: `henry_barometric_smoke`, `henry_barometric_visual_smoke`. |
| Henry Colosso D37 owner | `RTHenryColossusAbilityController.fire_auto_attack`, `begin_skill`, `cast_ultimate`, `modify_incoming_damage`, `on_damage_confirmed_enemy`, `visual_snapshot` | `scripts/systems/abilities/henry_colossus_ability_controller.gd`; owns the melee combo/Ímpeto, guard-counter, collision-safe giant charge, 1.2 s forward/reverse growth, 30 s giant timer and temporary HP. It also owns independent Lastro stacks with per-target hit throttle, regular-enemy anchor and boss slow. `scripts/presentation/henry_colossus_presentation.gd` renders bounded physical accents and marks; six runtime atlases are normalized by `tools/build_henry_colossus_sprites.py`, share a 256 px cell/ground anchor and erase rear tie blue. Giant remote state uses visual flag bit 4 while retaining visual schema/stride. Tests: `henry_colossus_smoke`, `henry_colossus_visual_smoke`. |
| Henry unlock cheat | `_try_unlock_henry_cheat` | `scripts/main_runtime_core.gd`; `HENRYP` sets only the local persisted test unlock and does not award an UMBRA victory |
| Henry temporal entrance / flame VFX | `RTHenryIncendiaryAbilityController.begin_entrance`, `update_entrance`, `apply_entrance_snapshot`; `HenryFire.cone`, `wave`, `charge` | Entry runs before combat, authority owns wander/brake/freeze/release; existing world visual packet carries `henry_entrance`. `scripts/presentation/henry_fire_presentation.gd` shares bounded mesh-based fire across local/remote casts. Tests: `henry_cinematic_fire_smoke`, `henry_entrance_transport_smoke`, `henry_fire_visual_smoke`, `henry_fire_budget_smoke`. |
| Henry entrance and idle presentation | `EntitiesPresentation._draw_henry_entry`, `_henry_entry_draw_height`, `_update_henry_idle_animation`, `_henry_idle_frame_index` | entrance frames use measured alpha heights to match the 237 px idle silhouette; pocket/foot-tap is the normal idle and beard gesture chooses a side every 7 stationary seconds; exact frame index reuses the existing player animation snapshot |
| Henry Quimera organ compositor | `RTHenryQuimeraPresentation.resolve_overlay`, `draw_local`, `draw_remote` | `scripts/presentation/henry_quimera_presentation.gd`; maps optional local/remote visual snapshots onto the existing body Rect2 with front/side/back buckets, fixed family order, source sockets and stage-3 procedural accents. No gameplay, collision, texture creation, viewport or packet ownership. Tests: `henry_quimera_presentation_smoke`, `henry_quimera_presentation_visual_smoke`. |
| Boss party scaling snapshot | `_ensure_boss_party_scaling_context` | `scripts/main_runtime_core.gd:6896` |
| Boss 1 animation state selection | `RTBoss1AnimationPresentation.active_texture` | `scripts/presentation/boss1_animation_presentation.gd` |
| Boss 1 animation facing | `RTBoss1AnimationPresentation.should_flip_h` | `scripts/presentation/boss1_animation_presentation.gd` |
| Boss 2 animation state selection | `RTBoss2AnimationPresentation.active_texture` | `scripts/presentation/boss2_animation_presentation.gd`; resolves the existing FSM without owning gameplay |
| Boss 2 hit/death visual lifecycle | `RTBoss2AnimationPresentation.trigger_hit`, `trigger_death`, `draw_death` | `scripts/presentation/boss2_animation_presentation.gd`; runtime keeps authoritative HP/death transitions |
| UMBRA Observation Schema 2.0 | `RTUmbraObservationSchema.build_from_runtime` | `scripts/systems/umbra_observation_schema.gd:96` |
| UMBRA multiplayer authority | `RTUmbraAuthorityController.build_authoritative_decision` | `scripts/systems/online/umbra_authority_controller.gd` |
| UMBRA Observation fixtures | `build_from_snapshot` | `scripts/systems/umbra_observation_schema.gd:69` |
| UMBRA FP32 neural runtime | `RTUmbraNeuralRuntime.forward` | `scripts/systems/umbra_neural_runtime.gd:85` |
| UMBRA 2.0 multi-head recurrent policy | `RTUmbraMultiheadPolicy.step` | `scripts/systems/umbra_multihead_policy.gd` |
| UMBRA PC/Android fixture parity | `RTUmbraMultiheadPolicy.set_hidden_state` | `tests/umbra_multihead_parity_smoke.gd` |
| UMBRA 2.0 memory lifecycle | `RTUmbraMemoryController.begin_run` | `scripts/systems/umbra_memory_controller.gd` |
| UMBRA pre-combat knowledge dossier | `RTUmbraMemoryController.knowledge_report` | `scripts/systems/umbra_memory_controller.gd` |
| UMBRA RL contract dump | `SceneTree._init` | `tools/umbra_rl_contract.gd` |
| UMBRA RL authoritative rollout | `SceneTree._run` | `tools/umbra_rl_rollout.gd` |
| UMBRA RL reward/curriculum | `_reward_for_transition` | `tools/umbra_rl_rollout.gd` |

## Preserved extracted owners

Use exact symbol search in these owners; core keeps compatible wrappers.

- Devorador de Destinos visuals: `scripts/presentation/devorador_destinos_presentation.gd` (`warmup`, `draw_world`, `draw_foreground`); existing `_draw_devorador_world` facade retained, foreground runs after actors; existing proc timers remain authoritative. Focused tests: `devorador_destinos_smoke.gd`, `devorador_destinos_visual_smoke.gd`.

- Boss 3 Miasma presentation: `scripts/presentation/boss3_miasma_presentation.gd` (`clones`, `darkness`, `overlay`, `qte_openness`); world/combat wrappers and core unchanged APIs. No gameplay state ownership.
- Save/config/resume/retry: `scripts/systems/save/runtime_save_controller.gd`.
- Player/input interpretation: `scripts/systems/player/player_control_controller.gd`; shared runtime state and public core wrappers remain compatible while attack, skill and dash execution stay in the core.
- Phase setup/transition/portals: `scripts/systems/phase/phase_flow_controller.gd`.
- Experimental FaseEX world, randomized hidden altar and discovery lifecycle: `scripts/systems/phase/experimental_phase_controller.gd`; integrated altar, post-discovery guidance and map presentation: `scripts/presentation/experimental_phase_presentation.gd` and `scripts/presentation/phase_map_presentation.gd`.
- Phase-scoped texture residency/catalog lazy loading: `scripts/systems/assets/runtime_asset_controller.gd`.
- Revive lifecycle authority and transition rules: `scripts/systems/online/runtime_revive_controller.gd`; serialized fragment/altar state stays in `scripts/systems/online/team_revival_state.gd`.
- Lobby ready/session snapshot application: `scripts/systems/online/runtime_lobby_controller.gd`; public RPC entrypoints remain on `Main`, preserving names, payload order and Godot RPC configuration.
- Phase 2 Sineiro Boreal combat/reward authority: `scripts/systems/enemies/phase2_sineiro_boreal_controller.gd`; presentation: `scripts/presentation/phase2_sineiro_presentation.gd`.
- Phase 6 Suturador de Âmbar event authority: `scripts/systems/enemies/phase6_amber_suturer_controller.gd`; presentation: `scripts/presentation/phase6_amber_suturer_presentation.gd`.
- Score/card math and long-run curves: `scripts/systems/progression/runtime_progression_controller.gd`; temporary x2 point artifact drop budget, buff timer, Event Director cap and team snapshot: `scripts/systems/progression/point_boost_pickup_controller.gd`.
- Boss wave drawing: `scripts/presentation/boss_wave_presentation.gd`.
- Boss 1 animation/facing/damage-stage presentation: `scripts/presentation/boss1_animation_presentation.gd`; rewind plus Pinças em Tenaz targeting, sequence construction and state-machine updates live in `scripts/systems/early_boss_controller.gd`. Shared state, public wrappers and authority/RPC boundary remain in core.
- Cross-owner regression: `tests/runtime_backup_reconciliation_smoke.gd`.

## Search Recipes

```bash
grep -n "func reroll" scripts/ui/shop_controller.gd
sed -n '400,445p' scripts/ui/shop_controller.gd
```

```bash
grep -n "_roll_shop_cards_v2" scripts/main_runtime_core.gd
sed -n '29590,29650p' scripts/main_runtime_core.gd
```

```bash
python3 tools/check_architecture_budget.py --json
```
