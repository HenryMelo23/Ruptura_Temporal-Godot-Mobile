---
name: ruptura-main-gd-navigation
description: Use when a Ruptura Temporal task touches scripts/main.gd so the agent can find the right integration points without broad file reads.
---

# Ruptura Main.gd Navigation

Use this skill before editing `scripts/main.gd` or when a feature spans menus, HUD, online, audio, abilities, enemies, bosses, phases, shop, or run state.

## Rule

Do not open all of `scripts/main.gd` unless a precise search proves that a broad read is required. Start with symbols, then read narrow line windows around the matches and their direct callers.

## Fast Search Map

Use `rg -n` with these terms before reading:

- Startup/state: `_ready`, `_process`, `_draw`, `_start_game`, `mode =`, `game_over`, `_handle_player_down`.
- Input/HUD: `_handle_touch_press`, `_handle_touch_drag`, `_draw_touch_controls`, `_update_button_layout`, `_draw_edit_layout`, `_combat_controls_active`.
- Multiplayer: `_mp_`, `_rpc_`, `dedicated_`, `net_players_by_peer`, `_pack_net_`, `_apply_remote_`, `_is_world_authority`, `_is_world_replica`.
- Online lobby: `online_`, `lobby`, `room`, `ready`, `manifest`, `specter`, `manifestation`.
- Economy/shop/votes: `_apply_score_delta`, `_kill_enemy`, `_start_forced_shop_countdown`, `_try_open_manual_shop`, `_rpc_shop`, `_rpc_boss`, `_rpc_pause`, `_rpc_phase`.
- Bosses/enemies: `_spawn_wave`, `_enemy_limit`, `_get_enemy_target_pos`, `_boss`, `boss_target`, `_damage_player`.
- Abilities/VFX: `_use_skill`, `_use_secondary_skill`, `_try_dash`, `_send_network_ability_visual`, `_rpc_ability_visual`, `teleport_effects`, `particles`.
- Audio: `music_player`, `menu_music`, `_play_phase_music_random`, `_on_music_finished`, `_play_sfx`, `_stop_`, `audio_streams`.

PowerShell examples:

```powershell
rg -n "_rpc_shop|_rpc_boss|_rpc_phase|_apply_score_delta" scripts/main.gd tests -g "*.gd"
Get-Content .\scripts\main.gd | Select-Object -Skip 60800 -First 180
```

## Edit Pattern

- Patch the smallest helper or call site that owns the behavior.
- When changing a contract, update every pack, unpack, apply, smoke, and legacy guard in the same change.
- When adding a guard such as dead/spectator/control-lock, check touch input, keyboard/mouse input, mobile drawing, desktop drawing, and RPC entry points.
- Keep VFX replication visual-only unless the existing path is explicitly gameplay-authoritative.

## Validation

For `main.gd` edits, run a focused smoke that exercises the changed path plus the deep validator before declaring completion. For skill-only or docs-only work, use `git diff --check` instead.
