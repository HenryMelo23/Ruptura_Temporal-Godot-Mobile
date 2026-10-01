# Runtime Symbol Index

Generated for navigation, not as an exhaustive API reference. For files over
100 KB, search the exact symbol and open a small line window.

## Current Metrics

Metrics come from `python3 tools/check_architecture_budget.py --json`.
`code_loc` excludes blank and comment-only lines.

| File | Physical LOC | Code LOC | Functions | Largest function |
| --- | ---: | ---: | ---: | --- |
| `scripts/main_runtime_core.gd` | 46115 | 39717 | 3093 | `_handle_key` 456 code LOC |
| `scripts/main_runtime_state.gd` | 3416 | 3380 | 1 | `_safe_load` 5 code LOC |
| `scripts/presentation/combat_effects_presentation.gd` | 4239 | 3881 | 101 | `_draw_projectiles` 345 code LOC |
| `scripts/presentation/menus_presentation.gd` | 3066 | 2722 | 102 | `_draw_manifest_select` 176 code LOC |
| `scripts/presentation/world_environment_presentation.gd` | 2649 | 2471 | 56 | `_draw_boss_attacks` 375 code LOC |
| `scripts/ui/shop_controller.gd` | 699 | 584 | 51 | `handle_touch` 82 code LOC |
| `scripts/ui/shop_presentation.gd` | 938 | 814 | 28 | `draw_legacy` 326 code LOC |
| `scripts/systems/telemetry/telemetry_system.gd` | 511 | 467 | 21 | `build_minimal_session_payload` 122 code LOC |
| `scripts/systems/events/runtime_event_director.gd` | owner | owner | owner | `on_enemy_killed`, `active_snapshot` |
| `scripts/systems/events/runtime_event_catalog.gd` | owner | owner | owner | `CONFIG`, `EVENTS` |
| `scripts/systems/online/net_contract.gd` | 322 | 299 | 11 | `unpack_enemy_snapshot` 55 code LOC |
| `scripts/systems/audio/audio_lifecycle.gd` | 357 | 292 | 32 | `on_music_finished` 20 code LOC |
| `scripts/systems/enemy_manager.gd` | 257 | 231 | 11 | `update_enemies` 115 code LOC |
| `scripts/systems/manifest_evolutions/manifest_evolution_catalog.gd` | owner | owner | owner | `all_entries`, `entries_for_manifestation`, `validate_catalog` |
| `scripts/presentation/gravitante_vfx_presentation.gd` | owner | owner | owner | `lod`, `projectile`, `orbitals`, `collision`, `teleport`, `ultimate` |
| `scripts/systems/modern_boss_controller.gd` | 520 | 453 | 30 | `update_boss7_state` 70 code LOC |

## Runtime Lookup

| Need | Search symbol | Owner / window start |
| --- | --- | --- |
| Startup setup | `_ready` | `scripts/main_runtime_core.gd:10` |
| Run start/reset | `_start_game` | `scripts/main_runtime_core.gd:6115` |
| Frame update | `_process` | `scripts/main_runtime_core.gd:8180` |
| Draw orchestration | `_draw` | `scripts/main_runtime_core.gd:34164` |
| Shop open | `_open_shop` | `scripts/main_runtime_core.gd:29244` then `RTShopController.open_shop` |
| Shop visit reset | `_begin_shop_visit` | `scripts/main_runtime_core.gd:29385` |
| Shop card roll | `_roll_shop_cards_v2` | `scripts/main_runtime_core.gd:29598` |
| Shop lock preservation | `_apply_locked_shop_slots` | `scripts/main_runtime_core.gd:29299` |
| Shop UI/economy owner | `class_name RTShopController` | `scripts/ui/shop_controller.gd:2` |
| Shop reroll | `func reroll` | `scripts/ui/shop_controller.gd:409` |
| Shop paid reroll cost | `next_paid_reroll_cost` | `scripts/ui/shop_controller.gd:135` |
| Shop drawing | `func draw` | `scripts/ui/shop_presentation.gd:382` |
| Legacy shop drawing | `func draw_legacy` | `scripts/ui/shop_presentation.gd:502` |
| Telemetry facade | `_record_telemetry_shop_reroll` | `scripts/main_runtime_core.gd:2036` |
| Telemetry owner | `class_name RTTelemetrySystem` | `scripts/systems/telemetry/telemetry_system.gd:1` |
| Shop reroll telemetry | `record_shop_reroll` | `scripts/systems/telemetry/telemetry_system.gd:188` |
| Minimal telemetry payload | `build_minimal_session_payload` | `scripts/systems/telemetry/telemetry_system.gd:257` |
| Runtime event owner | `class_name RTRuntimeEventDirector` | `scripts/systems/events/runtime_event_director.gd:1` |
| Runtime event config | `const CONFIG` | `scripts/systems/events/runtime_event_catalog.gd:6` |
| Runtime event kill charge | `on_enemy_killed` | `scripts/systems/events/runtime_event_director.gd:53` |
| Runtime event sync snapshot | `active_snapshot` | `scripts/systems/events/runtime_event_director.gd:89` |
| Online packet contract | `class_name RTNetContract` | `scripts/systems/online/net_contract.gd:1` |
| Audio lifecycle | `class_name RTAudioLifecycle` | `scripts/systems/audio/audio_lifecycle.gd:1` |
| Enemy updates | `update_enemies` | `scripts/systems/enemy_manager.gd:19` |
| Enemy spawning | `spawn_wave` | `scripts/systems/enemy_manager.gd:139` |
| Manifest evolution catalog | `class_name RTManifestEvolutionCatalog` | `scripts/systems/manifest_evolutions/manifest_evolution_catalog.gd:2` |
| Manifest evolution option source | `_manifest_evolution_entries` | `scripts/main_runtime_core.gd:7921` |
| Manifest evolution projectile hook | `_apply_manifest_evolution_to_bullet` | `scripts/main_runtime_core.gd:8036` |
| Manifest evolution impact hook | `_manifest_evolution_on_projectile_hit` | `scripts/main_runtime_core.gd:8126` |
| Boss 7 state | `update_boss7_state` | `scripts/systems/modern_boss_controller.gd:35` |
| Boss 7 ultimate | `check_boss7_ultimate` | `scripts/systems/modern_boss_controller.gd:427` |

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
