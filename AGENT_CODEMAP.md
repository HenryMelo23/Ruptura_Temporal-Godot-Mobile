# Agent Codemap

This map routes work by domain to the smallest likely owner and the focused
tests that should run first. Use exact symbol lookup and small windows for files
over 100 KB.

| Domain | Owner / first file | Runtime entry symbols | Focused tests |
| --- | --- | --- | --- |
| Shop and economy | `scripts/ui/shop_controller.gd` | `RTShopController.open_shop`, `buy_selected_card`, `reroll`, `reserve_card` | `tests/shop_paid_rerolls_smoke.gd`, `tests/shop_fairness_v2_smoke.gd`, `tests/shop_abuse_integrity_smoke.gd`, `tests/multiplayer_shop_flow_smoke.gd` |
| Shop drawing | `scripts/ui/shop_presentation.gd` | `draw`, `draw_legacy`, `draw_round_button` | `tests/shop_button_layout_smoke.gd`, `tests/shop_deck_visual_smoke.gd`, `tests/shop_workshop_visual_smoke.gd` |
| Telemetry and reports | `scripts/systems/telemetry/telemetry_system.gd` | `start_report`, `record_shop_reroll`, `build_minimal_session_payload`, `build_run_report_payload` | `tests/minimal_telemetry_schema_smoke.gd`, `tests/run_telemetry_smoke.gd`, `tests/run_report_default_webhook_smoke.gd` |
| Runtime events | `scripts/systems/events/runtime_event_director.gd`, `scripts/systems/events/runtime_event_catalog.gd` | `RTRuntimeEventDirector.update`, `on_enemy_killed`, `active_snapshot`; `RTRuntimeEventCatalog.CONFIG` | `tests/runtime_event_director_smoke.gd`, `tests/minimal_telemetry_schema_smoke.gd`, multiplayer smoke nearest touched flow |
| Online contracts | `scripts/systems/online/net_contract.gd` | `RTNetContract` pack/unpack helpers | `tests/multiplayer_transport_smoke.gd`, `tests/multiplayer_shop_wire_smoke.gd`, `tests/multiplayer_gameplay_authority_smoke.gd` |
| Online flow and UI | `scripts/main_runtime_core.gd` facade plus `scripts/ui/shop_controller.gd` | `_net_report_*`, online room input helpers, shop MP helpers | `tests/online_lobby_smoke.gd`, `tests/multiplayer_lobby_integration_smoke.gd`, `tests/multiplayer_shop_flow_smoke.gd` |
| Audio lifecycle | `scripts/systems/audio/audio_lifecycle.gd` | `RTAudioLifecycle` methods | `tests/audio_lifecycle_smoke.gd`, `tests/menu_to_phase_music_smoke.gd`, `tests/rain_audio_lifecycle_smoke.gd` |
| Enemy waves | `scripts/systems/enemy_manager.gd` | `update_enemies`, `spawn_wave`, limit/interval helpers | `tests/enemy_escalation_reconstitution_smoke.gd`, `tests/phase4_enemy_ecosystem_smoke.gd`, `tests/phase7_enemy_behaviour_smoke.gd` |
| Boss runtime | `scripts/systems/modern_boss_controller.gd` plus boss sections in `scripts/main_runtime_core.gd` | `update_boss7_state`, `start_boss7_*`, `check_boss7_ultimate` | `tests/boss7_fenix_smoke.gd`, `tests/boss7_fire_progression_smoke.gd`, `tests/boss4_nexus_mechanics_smoke.gd` |
| Combat visuals | `scripts/presentation/combat_effects_presentation.gd` | `_draw_projectiles`, impact/trail drawing helpers | `tests/player_attack_animation_movement_smoke.gd`, `tests/bombastica_vfx_origin_visual_smoke.gd`, `tests/presentation_extraction_visual_smoke.gd` |
| Menus and catalog UI | `scripts/presentation/menus_presentation.gd`, `scripts/catalog/*` | menu draw helpers, catalog repository/interface classes | `tests/main_menu_visual_smoke.gd`, `tests/catalog_repository_smoke.gd`, `tests/catalog_interface_visual_smoke.gd` |
| World presentation | `scripts/presentation/world_environment_presentation.gd` | `_draw_boss_attacks`, environment and phase drawing helpers | `tests/phase_transition_visual_smoke.gd`, `tests/dynamic_shadows_visual_smoke.gd`, `tests/readability_visual_smoke.gd` |
| Runtime state/constants | `scripts/main_runtime_state.gd` | state constants and shared variables | nearest domain test plus `python3 tools/check_architecture_budget.py` |

## Owner Rules

- Put new shop/economy behavior in `scripts/ui/shop_controller.gd` unless it is
  only a core facade or state persistence hook.
- Put telemetry schema and payload changes in
  `scripts/systems/telemetry/telemetry_system.gd`; keep core wrappers thin.
- Put temporary runtime event rules, cooldowns, thresholds, and active-state
  ownership in `scripts/systems/events/runtime_event_director.gd` and
  `runtime_event_catalog.gd`; keep core as bind/tick/facade only.
- Put online serialization in `scripts/systems/online/net_contract.gd`; keep UI
  and state transitions outside the contract.
- Put drawing-only changes in presentation files. Do not mix balance or gameplay
  mutations into presentation owners.
- Use `scripts/main_runtime_core.gd` as a temporary integration surface only
  when no owner exists yet; add a campaign note before expanding it.

## Validation Ladder

1. Run the nearest smoke test listed above.
2. Parse/check changed scripts when GDScript changes are involved.
3. Run `python3 tools/check_architecture_budget.py` for runtime refactor work.
4. Run the deep Godot validator only for broad/shared behavior or scene/resource
   changes.
