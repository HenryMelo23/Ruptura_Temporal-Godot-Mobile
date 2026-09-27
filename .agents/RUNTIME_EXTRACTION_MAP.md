# Runtime Extraction Map

Source: `.agent_index/runtime_symbols.tsv`, `rg`, and narrow symbol windows for `scripts/main_runtime_core.gd` only. Core currently has about 39.7k LOC. Keep lifecycle wrappers (`_ready`, `_process`, `_draw`, `_unhandled_input`) and RPC entrypoints in core while moving implementation behind owned controllers.

## Domains

### Presentation and Draw Facade
- Domain name: Presentation and draw facade
- Approximate LOC: 4.2k removable or delegatable LOC
- Proposed owner file/directory: `scripts/presentation/*`, `scripts/ui/*`, optional `scripts/presentation/runtime_presentation_facade.gd`
- Representative symbols: `_draw`, `_draw_*`, `MenusPresentation.*`, `HudPresentation.*`, `CombatEffectsPresentation.*`, `WorldEnvironmentPresentation.*`, `EntitiesPresentation.*`
- Focused tests: main menu smoke, gameplay HUD smoke, shop/catalog/menu visual smoke, affected scene startup
- Dependencies: textures, fonts, camera transforms, HUD layout, debug overlays, direct `self` state access
- Extraction priority: P0, highest token savings and many symbols are already delegated

### Runtime Input, Menus, and HUD Editing
- Domain name: Runtime input, menus, and HUD editing
- Approximate LOC: 3.0k LOC
- Proposed owner file/directory: `scripts/ui/runtime_input_controller.gd`, `scripts/ui/hud_layout.gd`, `scripts/ui/menu_presentation.gd`
- Representative symbols: `_unhandled_input`, `_handle_key`, `_handle_press`, `_handle_edit_layout_press`, `_handle_shop_touch`, `_handle_manifest_touch`
- Focused tests: desktop input smoke, mobile touch smoke, HUD edit layout smoke, shop/menu navigation smoke
- Dependencies: mode flags, pause/shop/menu state, touch buttons, player aim state, multiplayer pause/room state
- Extraction priority: P0, large reduction and major future navigation savings, with medium coupling

### Content Updates, App Updates, and Run Reporting
- Domain name: Content updates, app updates, and run reporting
- Approximate LOC: 1.5k LOC
- Proposed owner file/directory: `scripts/systems/updates/runtime_update_controller.gd`, `scripts/systems/content_pack_state.gd`, `scripts/systems/telemetry/*`
- Representative symbols: `_start_next_content_update_download`, `_check_content_patch_version`, `_apply_app_update_manifest`, `_send_run_report_to_discord`
- Focused tests: `tests/content_update_smoke.gd`, `tests/content_patch_boot_smoke.gd`, app update smoke, run-report HTTP smoke
- Dependencies: `HTTPRequest` nodes, local `user://` files, update modal UI, release/version constants
- Extraction priority: P1, low gameplay risk and good separation from combat runtime

### Audio Lifecycle and Phase Music
- Domain name: Audio lifecycle and phase music
- Approximate LOC: 0.8k LOC
- Proposed owner file/directory: `scripts/systems/audio/audio_lifecycle.gd`, `scripts/systems/audio/audio_manager.gd`
- Representative symbols: `_load_audio_streams`, `_play_sfx`, `_play_menu_music`, `_update_phase_music`, `_stop_boss_audio`
- Focused tests: audio lifecycle smoke, random phase music smoke, menu-to-game music transition smoke
- Dependencies: phase/boss state, Android resource loading, audio bus names, weather/boss loops
- Extraction priority: P1, moderate risk but self-contained and repeatedly player-visible

### Save, Config, Profile, and Runtime Boot Data
- Domain name: Save, config, profile, and runtime boot data
- Approximate LOC: 1.0k LOC
- Proposed owner file/directory: `scripts/systems/save/runtime_save_controller.gd`, `scripts/main_runtime_state.gd`
- Representative symbols: `_load_config`, `_save_config`, `_save_interrupted_run`, `_load_interrupted_run`, `_save_player_profile`, `_load_card_unlocks`
- Focused tests: save-clear-reload smoke, interrupted-run resume smoke, hub selection persistence smoke
- Dependencies: `user://` schema compatibility, legacy config keys, player profile globals, startup ordering
- Extraction priority: P1, low visual risk and important for persistence fixes

### Weather and Environment Effects
- Domain name: Weather and environment effects
- Approximate LOC: 0.4k LOC
- Proposed owner file/directory: `scripts/vfx/weather_vfx.gd`, `scripts/presentation/world_environment_presentation.gd`
- Representative symbols: `_start_boss1_rain`, `_stop_boss1_rain`, `_spawn_raindrop`, `_draw_weather_precipitation`
- Focused tests: boss rain smoke, weather visual smoke, weather audio lifecycle smoke
- Dependencies: boss phase state, audio lifecycle, presentation transforms
- Extraction priority: P1, small but low-risk and useful for isolating VFX

### Shop, Cards, and Economy
- Domain name: Shop, cards, and economy
- Approximate LOC: 3.3k LOC
- Proposed owner file/directory: `scripts/ui/shop_controller.gd`, `scripts/ui/shop_presentation.gd`, optional `scripts/systems/economy/runtime_cards_controller.gd`
- Representative symbols: `_apply_card`, `_reset_card_proc_state`, `_shop_*`, `_apply_score_delta`, `_manifest_selection_summary_rows`
- Focused tests: shop purchase smoke, card effect smoke, shared reward/individual spend smoke, catalog summary smoke
- Dependencies: score/reward state, card arrays, manifestation state, multiplayer shop voting, UI selection state
- Extraction priority: P2, high LOC but rules-sensitive

### Abilities, Manifestations, Auras, and Player Powers
- Domain name: Abilities, manifestations, auras, and player powers
- Approximate LOC: 6.3k LOC
- Proposed owner file/directory: `scripts/systems/abilities/*`, `scripts/systems/manifestations/*`
- Representative symbols: `_use_skill`, `_use_secondary_skill`, `_update_*manifestation*`, `_spawn_*`, `_apply_bullet_effect`
- Focused tests: manifestation ability smoke, cooldown smoke, projectile/VFX smoke, host-client ability sync smoke
- Dependencies: player stats, cooldowns, bullets, enemies, boss damage, VFX, audio, net visual packets
- Extraction priority: P2, huge reduction but high gameplay coupling

### Enemies, Projectiles, Damage, and Combat Runtime
- Domain name: Enemies, projectiles, damage, and combat runtime
- Approximate LOC: 5.8k LOC
- Proposed owner file/directory: `scripts/systems/enemy_manager.gd`, `scripts/systems/combat/runtime_combat_controller.gd`
- Representative symbols: `_spawn_enemy`, `_update_bullets`, `_update_return_bullets`, `_damage_enemy`, `_damage_boss`, `_damage_player`, `_kill_enemy`
- Focused tests: enemy wave smoke, projectile collision smoke, damage progression smoke, multiplayer damage sync smoke
- Dependencies: enemy/bullet dictionaries, boss state, card procs, score rewards, VFX/audio, authority checks
- Extraction priority: P3, very high LOC but core gameplay risk

### Bosses, Phases, and Hazards
- Domain name: Bosses, phases, and hazards
- Approximate LOC: 7.1k LOC
- Proposed owner file/directory: `scripts/systems/bosses/*`, `scripts/systems/phases/runtime_phase_controller.gd`
- Representative symbols: `_advance_to_phase`, `_update_boss_attacks`, `_update_boss2_attacks`, `_update_phase4_enemy_hazards`, `_update_phase5_hazards`, `_spawn_umbra_action`
- Focused tests: phase transition smoke, boss entry smoke, boss attack smoke, phase 4/5 hazard smoke
- Dependencies: current phase, enemy manager, combat damage, music, weather, multiplayer votes, VFX snapshots
- Extraction priority: P3, largest domain but high coupling and acceptance risk

### Online, RPC, Team Revival, and Net Snapshots
- Domain name: Online, RPC, team revival, and net snapshots
- Approximate LOC: 4.3k LOC
- Proposed owner file/directory: `scripts/systems/online/*`, optional `scripts/systems/online/runtime_multiplayer_facade.gd`
- Representative symbols: `_rpc_*`, `_pack_net_boss_visuals`, `_apply_remote_boss_visual_snapshot`, `_sync_multiplayer_state`, `_start_team_revival_for_dead`, `_update_team_revival`
- Focused tests: multiplayer packet contract smoke, host-client revive smoke, boss snapshot smoke, pause/shop vote smoke
- Dependencies: Godot RPC annotations, authority, peer IDs, packet schema, dead-player gating, legacy wrappers
- Extraction priority: P4, wrappers/RPC declarations should remain in core while internals move carefully

### Runtime Orchestration and Main Loop
- Domain name: Runtime orchestration and main loop
- Approximate LOC: 2.6k LOC
- Proposed owner file/directory: `scripts/systems/runtime_flow_controller.gd`
- Representative symbols: `_ready`, `_process`, `_start_game`, `_update_game`, `_cleanup_runtime_resources`, `_apply_initial_phase_setup`
- Focused tests: project import, main scene smoke, new run smoke, skip intro/name flow smoke
- Dependencies: nearly every subsystem, startup order, node paths, signal wiring, lifecycle wrappers
- Extraction priority: P5, extract last after owned subsystems stabilize

## Keep In Core

- Public Godot lifecycle entrypoints: `_ready`, `_process`, `_draw`, `_unhandled_input`.
- RPC declarations and public wrapper names currently used by packets, tests, scenes, or external callers.
- Thin compatibility wrappers for delegated modules until focused tests prove each call path is migrated.
