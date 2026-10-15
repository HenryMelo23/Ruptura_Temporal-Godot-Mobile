# Agent Codemap

This map routes work by domain to the smallest likely owner and the focused
tests that should run first. Use exact symbol lookup and small windows for files
over 100 KB.

| Domain | Owner / first file | Runtime entry symbols | Focused tests |
| --- | --- | --- | --- |
| Save/config/resume/retry | `scripts/systems/save/runtime_save_controller.gd` | `_load_player_profile`, `_load_card_unlocks`, `_build_interrupted_run_snapshot`, `_resume_interrupted_run`, `_use_run_retry`; core wrappers remain public | `tests/runtime_save_controller_smoke.gd`, `tests/runtime_backup_reconciliation_smoke.gd`, `tests/player_progress_cache_smoke.gd` |
| Permanent progress recovery | `scripts/systems/player_progress_sync.gd`, `scripts/systems/save/runtime_save_controller.gd`, `server/relay_manager.js` | versioned cache/event builders, `_apply_remote_player_progress_snapshot`, identity create/claim and relay event validation; menu only presents status/recovery controls | `tests/player_progress_cache_smoke.gd`, `tests/runtime_backup_reconciliation_smoke.gd`, `tests/player_progress_profile_visual_smoke.gd`, `server/player_progress_smoke.js` |
| Phase orchestration | `scripts/systems/phase/phase_flow_controller.gd` | `_setup_initial_phase_state`, `_advance_to_phase`, phase timers/portals/fragment helpers | `tests/phase_transition_smoke.gd`, `tests/runtime_backup_reconciliation_smoke.gd`, `tests/phase_density_carry_smoke.gd` |
| Runtime asset residency | `scripts/systems/assets/runtime_asset_controller.gd` | `preload_all`, `prepare_phase`, `ensure_key`; core wrappers preserve catalog and phase entry behavior | `tests/runtime_asset_controller_smoke.gd`, `tests/catalog_manifest_spectrum_icons_smoke.gd`, `tests/phase_transition_smoke.gd` |
| Progression/rewards/card math | `scripts/systems/progression/runtime_progression_controller.gd` | `points_for_enemy`, `apply_score_delta`, `new_common_card_count`, `effective_card_price`, long-run helpers | `tests/runtime_progression_controller_smoke.gd`, `tests/long_run_power_fantasy_smoke.gd`, `tests/long_run_economy_smoke.gd`, `tests/cinzas_attribute_burn_system_smoke.gd` |
| Boss wave drawing | `scripts/presentation/boss_wave_presentation.gd` | `_draw_boss_wave_safe_sector`, `_draw_boss_wave_water_body`, crest/foam/trail helpers | `tests/boss_wave_smoke.gd`, `tests/boss_wave_visual_smoke.gd` |
| Boss 1 animation | `scripts/presentation/boss1_animation_presentation.gd`, assets in `assets/sprites/boss1/` | `update`, `active_texture`, `should_flip_h`, `draw_damage_stage`; gameplay attacks remain authoritative in core | `tests/boss1_animation_smoke.gd`, `tests/boss1_animation_visual_smoke.gd`, nearest Boss 1 attack/network smoke |
| Shop and economy | `scripts/ui/shop_controller.gd` | `RTShopController.open_shop`, `buy_selected_card`, `reroll`, `reserve_card` | `tests/shop_paid_rerolls_smoke.gd`, `tests/shop_fairness_v2_smoke.gd`, `tests/shop_abuse_integrity_smoke.gd`, `tests/multiplayer_shop_flow_smoke.gd` |
| Shop drawing | `scripts/ui/shop_presentation.gd` | `draw`, `draw_legacy`, `draw_round_button` | `tests/shop_button_layout_smoke.gd`, `tests/shop_deck_visual_smoke.gd`, `tests/shop_workshop_visual_smoke.gd` |
| Telemetry and reports | `scripts/systems/telemetry/telemetry_system.gd` | `start_report`, `record_shop_reroll`, `build_minimal_session_payload`, `build_run_report_payload` | `tests/minimal_telemetry_schema_smoke.gd`, `tests/run_telemetry_smoke.gd`, `tests/run_report_default_webhook_smoke.gd` |
| Runtime events | `scripts/systems/events/runtime_event_director.gd`, `scripts/systems/events/runtime_event_catalog.gd` | `RTRuntimeEventDirector.update`, `on_enemy_killed`, `active_snapshot`; `RTRuntimeEventCatalog.CONFIG` | `tests/runtime_event_director_smoke.gd`, `tests/minimal_telemetry_schema_smoke.gd`, multiplayer smoke nearest touched flow |
| Online contracts | `scripts/systems/online/net_contract.gd` | `RTNetContract` pack/unpack helpers | `tests/multiplayer_transport_smoke.gd`, `tests/multiplayer_shop_wire_smoke.gd`, `tests/multiplayer_gameplay_authority_smoke.gd` |
| Online flow and UI | `scripts/main_runtime_core.gd` facade plus `scripts/ui/shop_controller.gd` | `_net_report_*`, online room input helpers, shop MP helpers | `tests/online_lobby_smoke.gd`, `tests/multiplayer_lobby_integration_smoke.gd`, `tests/multiplayer_shop_flow_smoke.gd` |
| Audio lifecycle | `scripts/systems/audio/audio_lifecycle.gd` | `RTAudioLifecycle` methods | `tests/audio_lifecycle_smoke.gd`, `tests/menu_to_phase_music_smoke.gd`, `tests/rain_audio_lifecycle_smoke.gd` |
| Enemy waves | `scripts/systems/enemy_manager.gd` | `update_enemies`, `spawn_wave`, limit/interval helpers | `tests/enemy_escalation_reconstitution_smoke.gd`, `tests/phase4_enemy_ecosystem_smoke.gd`, `tests/phase7_enemy_behaviour_smoke.gd` |
| Phase 2 Sineiro Boreal | `scripts/systems/enemies/phase2_sineiro_boreal_controller.gd`, `scripts/presentation/phase2_sineiro_presentation.gd` | `spawn_now`, `update_enemy`, `build_echo_positions`, `on_enemy_defeated`, `draw_world` | `tests/phase2_sineiro_boreal_smoke.gd`, `tests/phase2_sineiro_visual_smoke.gd` |
| Phase 6 Suturador de Âmbar | `scripts/systems/enemies/phase6_amber_suturer_controller.gd`, `scripts/presentation/phase6_amber_suturer_presentation.gd` | `spawn_now`, `update_enemy`, `build_suture_segments`, `on_enemy_defeated`, `draw_world` | `tests/phase6_amber_suturer_smoke.gd`, `tests/phase6_amber_suturer_visual_smoke.gd` |
| Manifest evolutions | `scripts/systems/manifest_evolutions/manifest_evolution_catalog.gd` plus thin hooks in `scripts/main_runtime_core.gd` | `RTManifestEvolutionCatalog.all_entries`, `_manifest_evolution_entries`, `_apply_manifest_evolution_to_bullet`, `_manifest_evolution_on_projectile_hit` | `tests/manifest_evolution_catalog_smoke.gd`, `tests/manifest_evolution_540_combinations_smoke.gd`, `tests/manifest_evolution_functional_matrix_smoke.gd`, `tests/manifest_evolution_smoke.gd` |
| Boss runtime | `scripts/systems/modern_boss_controller.gd` plus boss sections in `scripts/main_runtime_core.gd` | `update_boss7_state`, `start_boss7_*`, `check_boss7_ultimate` | `tests/boss7_fenix_smoke.gd`, `tests/boss7_fire_progression_smoke.gd`, `tests/boss4_nexus_mechanics_smoke.gd` |
| Boss party scaling | `scripts/systems/boss_party_scaling.gd` plus thin hooks in `scripts/main_runtime_core.gd` | `RTBossPartyScaling.profile_for_party_size`, `_ensure_boss_party_scaling_context`, `_boss_party_scaling_report` | `tests/boss_party_scaling_smoke.gd`, `tests/multiplayer_three_player_contract_smoke.gd` |
| Combat visuals | `scripts/presentation/combat_effects_presentation.gd` | `_draw_projectiles`, impact/trail drawing helpers | `tests/player_attack_animation_movement_smoke.gd`, `tests/bombastica_vfx_origin_visual_smoke.gd`, `tests/presentation_extraction_visual_smoke.gd` |
| Boss 3 Miasma visuals | `scripts/presentation/boss3_miasma_presentation.gd` via world/combat presentation wrappers | `clones`, `darkness`, `overlay`, `qte_openness`; only variants 1/2/4, existing snapshots remain authoritative | `tests/boss3_miasma_presentation_contract_smoke.gd`, `tests/boss3_miasma_visual_smoke.gd`, `tests/boss3_miasma_smoke.gd` |
| Gravitante visuals | `scripts/presentation/gravitante_vfx_presentation.gd` | `RTGravitanteVfx.projectile`, `orbitals`, `ultimate`, `collision`, `teleport`; cosmetic state only | `tests/gravitante_vfx_contract_smoke.gd`, `tests/gravitante_visual_smoke.gd`, `tests/gravitante_vfx_performance_smoke.gd`, `tests/gravitante_smoke.gd` |
| Menus and catalog UI | `scripts/presentation/menus_presentation.gd`, `scripts/catalog/*` | menu draw helpers, catalog repository/interface classes | `tests/main_menu_visual_smoke.gd`, `tests/catalog_repository_smoke.gd`, `tests/catalog_interface_visual_smoke.gd` |
| World presentation | `scripts/presentation/world_environment_presentation.gd` | `_draw_boss_attacks`, environment and phase drawing helpers | `tests/phase_transition_visual_smoke.gd`, `tests/dynamic_shadows_visual_smoke.gd`, `tests/readability_visual_smoke.gd` |
| Runtime state/constants | `scripts/main_runtime_state.gd` | state constants and shared variables | nearest domain test plus `python3 tools/check_architecture_budget.py` |
| UMBRA neural runtime | `scripts/systems/umbra_neural_runtime.gd` | `RTUmbraNeuralRuntime.create`, `forward`, `contract_error` | `tests/umbra_neural_runtime_smoke.gd`, `tests/umbra_dqn_contract_smoke.gd` |
| UMBRA observation schema | `scripts/systems/umbra_observation_schema.gd` | `RTUmbraObservationSchema.build_from_runtime`, `build_from_snapshot`, `validate_observation` | `tests/umbra_observation_schema_v2_smoke.gd`, `tests/umbra_dqn_contract_smoke.gd` |
| UMBRA multiplayer authority | `scripts/systems/online/umbra_authority_controller.gd` plus phase-5 facade hooks | `build_authoritative_decision`, `revalidate_before_execution`, `accept_replica_event`; compact event rides the world-visual snapshot | `tests/umbra_multiplayer_authority_smoke.gd`, `tests/multiplayer_gameplay_authority_smoke.gd` |
| UMBRA multi-head policy | `scripts/systems/umbra_multihead_policy.gd` | `RTUmbraMultiheadPolicy.create`, `step`, `reset_recurrence`, `set_hidden_state`, `logits_to_probabilities`, `contract_error` | `tests/umbra_multihead_policy_smoke.gd`, `tests/umbra_multihead_parity_smoke.gd` |
| UMBRA 2.0 memory lifecycle | `scripts/systems/umbra_memory_controller.gd` | `begin_run`, `begin_encounter`, `record_local_sample`, `finish_run` | `tests/umbra_memory_controller_smoke.gd` |
| UMBRA external RL bridge | `tools/umbra_rl_contract.gd`, `tools/umbra_rl_rollout.gd`, `tools/train_umbra_ppo.py`, `tools/umbra_rl_curriculum.py` | protocol dump, authoritative headless rollout, versioned reward/curriculum, development-only recurrent PPO/export | `tools/umbra_rl_protocol_smoke.py`, `tools/umbra_rl_curriculum_smoke.py` |

## Owner Rules

- Save/config/retry state stays in the save owner with existing state adapters;
  do not restore duplicated implementations from old core history.
- Phase flow stays in the phase owner; preserve density-carry, party-scaling,
  authoritative unlock and VFX cleanup hooks at phase boundaries.
- Phase-scoped texture residency stays in the runtime asset owner; catalog
  access must remain on-demand and desktop keeps eager preload behavior.
- Score/card math stays in the progression owner; retain telemetry and burned
  attribute hooks alongside the approved long-run baseline.
- Put new shop/economy behavior in `scripts/ui/shop_controller.gd` unless it is
  only a core facade or state persistence hook.
- Put telemetry schema and payload changes in
  `scripts/systems/telemetry/telemetry_system.gd`; keep core wrappers thin.
- Put temporary runtime event rules, cooldowns, thresholds, and active-state
  ownership in `scripts/systems/events/runtime_event_director.gd` and
  `runtime_event_catalog.gd`; keep core as bind/tick/facade only.
- Put manifestation evolution IDs, labels, descriptions, tags, and tunable
  profile data in `scripts/systems/manifest_evolutions/manifest_evolution_catalog.gd`;
  keep `main_runtime_core.gd` limited to save-compatible hook dispatch.
- Put online serialization in `scripts/systems/online/net_contract.gd`; keep UI
  and state transitions outside the contract.
- Put boss party-size coefficients in `scripts/systems/boss_party_scaling.gd`;
  keep `main_runtime_core.gd` limited to encounter snapshot/reset hooks.
- Keep UMBRA observation versions in `scripts/systems/umbra_observation_schema.gd`.
  A new schema must not replace a policy ABI, weights, or fallback until a
  separately trained artifact opts in through its own validated contract.
- Keep UMBRA model parsing, integrity validation and contiguous FP32 inference
  in `scripts/systems/umbra_neural_runtime.gd`. Do not add platform-specific
  inference paths without proving an equivalent model output contract.
- Keep UMBRA training under `tools/`; the headless rollout owns the
  observation -> action -> simulation -> reward/done/info boundary. Python and
  PyTorch must never be added to game export dependencies.
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
