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
| `scripts/presentation/menus_presentation.gd` | 3073 | 2729 | 102 | `_draw_manifest_select` 176 code LOC |
| `scripts/presentation/world_environment_presentation.gd` | 2543 | 2384 | 56 | `_draw_boss_attacks` 375 code LOC |
| `scripts/ui/shop_controller.gd` | 701 | 586 | 51 | `handle_touch` 82 code LOC |
| `scripts/ui/shop_presentation.gd` | 938 | 814 | 28 | `draw_legacy` 326 code LOC |
| `scripts/systems/telemetry/telemetry_system.gd` | 534 | 488 | 22 | `build_minimal_session_payload` 127 code LOC |
| `scripts/systems/events/runtime_event_director.gd` | owner | owner | owner | `on_enemy_killed`, `active_snapshot` |
| `scripts/systems/events/runtime_event_catalog.gd` | owner | owner | owner | `CONFIG`, `EVENTS` |
| `scripts/systems/online/net_contract.gd` | 365 | 342 | 11 | `unpack_enemy_snapshot` 77 code LOC |
| `scripts/systems/audio/audio_lifecycle.gd` | 357 | 292 | 32 | `on_music_finished` 20 code LOC |
| `scripts/systems/enemy_manager.gd` | 277 | 246 | 13 | `update_enemies` 115 code LOC |
| `scripts/systems/boss_party_scaling.gd` | owner | owner | owner | `profile_for_party_size` |
| `scripts/systems/manifest_evolutions/manifest_evolution_catalog.gd` | owner | owner | owner | `all_entries`, `entries_for_manifestation`, `validate_catalog` |
| `scripts/presentation/gravitante_vfx_presentation.gd` | owner | owner | owner | `lod`, `projectile`, `orbitals`, `collision`, `teleport`, `ultimate` |
| `scripts/systems/modern_boss_controller.gd` | 520 | 453 | 30 | `update_boss7_state` 70 code LOC |
| `scripts/presentation/boss_wave_presentation.gd` | 127 | 97 | 4 | `_draw_boss_wave_crest_and_foam` 49 code LOC |
| `scripts/systems/phase/phase_flow_controller.gd` | 624 | 555 | 34 | `_advance_to_phase` 191 code LOC |
| `scripts/systems/progression/runtime_progression_controller.gd` | 249 | 181 | 33 | `elite_point_multiplier` 19 code LOC |
| `scripts/systems/save/runtime_save_controller.gd` | 654 | 605 | 33 | `_load_config` 117 code LOC |

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
| Legacy shop drawing | `func draw_legacy` | `scripts/ui/shop_presentation.gd:502` |
| Telemetry facade | `_record_telemetry_shop_reroll` | `scripts/main_runtime_core.gd:2292` |
| Telemetry owner | `class_name RTTelemetrySystem` | `scripts/systems/telemetry/telemetry_system.gd:1` |
| Shop reroll telemetry | `record_shop_reroll` | `scripts/systems/telemetry/telemetry_system.gd:191` |
| Minimal telemetry payload | `build_minimal_session_payload` | `scripts/systems/telemetry/telemetry_system.gd:273` |
| Runtime event owner | `class_name RTRuntimeEventDirector` | `scripts/systems/events/runtime_event_director.gd:1` |
| Runtime event config | `const CONFIG` | `scripts/systems/events/runtime_event_catalog.gd:6` |
| Runtime event kill charge | `on_enemy_killed` | `scripts/systems/events/runtime_event_director.gd:53` |
| Runtime event sync snapshot | `active_snapshot` | `scripts/systems/events/runtime_event_director.gd:89` |
| Online packet contract | `class_name RTNetContract` | `scripts/systems/online/net_contract.gd:1` |
| Audio lifecycle | `class_name RTAudioLifecycle` | `scripts/systems/audio/audio_lifecycle.gd:1` |
| Enemy updates | `update_enemies` | `scripts/systems/enemy_manager.gd:23` |
| Enemy spawning | `spawn_wave` | `scripts/systems/enemy_manager.gd:143` |
| Manifest evolution catalog | `class_name RTManifestEvolutionCatalog` | `scripts/systems/manifest_evolutions/manifest_evolution_catalog.gd:2` |
| Manifest evolution option source | `_manifest_evolution_entries` | `scripts/main_runtime_core.gd:7566` |
| Manifest evolution projectile hook | `_apply_manifest_evolution_to_bullet` | `scripts/main_runtime_core.gd:7836` |
| Manifest evolution impact hook | `_manifest_evolution_on_projectile_hit` | `scripts/main_runtime_core.gd:7926` |
| Boss 7 state | `update_boss7_state` | `scripts/systems/modern_boss_controller.gd:35` |
| Boss 7 ultimate | `check_boss7_ultimate` | `scripts/systems/modern_boss_controller.gd:427` |
| Boss party scaling contract | `profile_for_party_size` | `scripts/systems/boss_party_scaling.gd:13` |
| Boss party scaling snapshot | `_ensure_boss_party_scaling_context` | `scripts/main_runtime_core.gd:6896` |

## Preserved extracted owners

Use exact symbol search in these owners; core keeps compatible wrappers.

- Boss 3 Miasma presentation: `scripts/presentation/boss3_miasma_presentation.gd` (`clones`, `darkness`, `overlay`, `qte_openness`); world/combat wrappers and core unchanged APIs. No gameplay state ownership.
- Save/config/resume/retry: `scripts/systems/save/runtime_save_controller.gd`.
- Phase setup/transition/portals: `scripts/systems/phase/phase_flow_controller.gd`.
- Score/card math and long-run curves: `scripts/systems/progression/runtime_progression_controller.gd`.
- Boss wave drawing: `scripts/presentation/boss_wave_presentation.gd`.
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
