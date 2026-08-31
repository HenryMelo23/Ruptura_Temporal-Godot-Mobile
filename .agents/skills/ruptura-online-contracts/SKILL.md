---
name: ruptura-online-contracts
description: Use for Ruptura Temporal online multiplayer, lobby, tunnel, readiness, packet/RPC sync, revive, shared score, votes, leadership, and host/client bugs.
---

# Ruptura Online Contracts

Use this skill for online mode, tunnel behavior, lobby UI, room creation/join, host/client confirmation, player readiness, specter/manifestation selection, synchronized enemies, shared points, revive, boss/shop/phase votes, or multiplayer balancing.

## Architecture Boundaries

- The active multiplayer integration lives mostly in `scripts/main.gd`.
- Smokes should instantiate `res://scenes/Main.tscn`; do not construct abstract `MultiplayerAPI` directly.
- Use the project helpers such as `_mp_sender_id()`, `_mp_unique_id()`, `_mp_sender_is_self()`, `_mp_peer_ids()`, `_is_world_authority()`, and `_is_world_replica()` so offline/headless tests remain safe.
- Dedicated server/tunnel logic should relay or authorize packets. Normal peers should render their own local gameplay and remote replicas separately.

## Contract Rules

- Enemy, boss, player, ability, revive, and economy payloads must be changed as pairs: pack, send, receive, apply, legacy/default handling, and tests.
- Shared score means positive kill rewards go to every active player; purchases and penalties remain individual.
- Dead/spectator players are not valid sources for damage, boss call, shop call, phase vote, pause vote, or leadership.
- Votes for boss, shop, pause, and phase should count living active players. If only one living player remains, avoid blocking that player on eliminated teammates.
- Host remains run leader by default. If host is dead, choose a living temporary leader and restore host leadership after revive.
- Remote ability packets are visual replication unless the existing code path is explicitly authoritative.

## Efficient Search

Start here:

```powershell
rg -n "_mp_|_rpc_|dedicated_|net_players_by_peer|_pack_net_|_apply_remote_|shop_mp|boss_mp|phase_mp|pause_mp|team_revival|run_leader" scripts/main.gd tests -g "*.gd"
rg -n "MULTIPLAYER|ONLINE_|NET_.*STRIDE|score|revive|fragment|altar|ready|manifest" scripts/main.gd tests -g "*.gd"
```

Avoid broad wildcard roots in PowerShell. Prefer `rg <pattern> tests -g 'multiplayer*.gd'` or explicit test paths.

## Focused Smokes

Prefer existing tests before inventing a new harness:

- `tests/multiplayer_three_player_contract_smoke.gd`
- `tests/multiplayer_team_revival_smoke.gd`
- `tests/multiplayer_ability_visual_smoke.gd`
- `tests/multiplayer_network_smoothing_smoke.gd`
- `tests/online_*_smoke.gd` when lobby/tunnel/search UI is involved

Run the deep validator after a multiplayer code change because schema drift can parse cleanly but break another path.
