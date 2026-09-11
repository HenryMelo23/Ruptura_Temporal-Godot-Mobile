---
name: godot-online-addons
description: Evaluate multiplayer lobby and networking add-ons against Ruptura Temporal's existing ENet and relay contracts before installing them.
---

# Online add-ons

This project already has a custom Godot multiplayer layer in `scripts/main.gd`: ENet transport, dedicated-room relay, lobby roster, readiness, spectators, host leadership, RPC replication, revive, score, boss/shop/phase votes, and focused multiplayer smokes. Treat that layer as the contract to preserve.

## Decision for the listed assets

- **SmartFox Lobby Basics, Buddies, and Matchmaking** are demo projects around SmartFoxServer services. They require a SmartFox backend and would replace the current room/relay flow. Do not copy their project files into this repository. Port an isolated UI idea only after choosing SmartFox as the backend.
- **CM.gd** abstracts Godot multiplayer for single-player, couch co-op, and networked modes. It is a possible architecture for a new project, but installing it here would duplicate the existing authority and packet contracts. Defer it unless a deliberate migration is approved.
- **Photon Fusion Godot** is a native SDK with Photon Cloud rooms, state replication, prediction, and RPCs. The official Godot SDK is a development preview; it also requires a Photon App ID and a service account. Do not install it for the current build. If a migration is explicitly chosen, follow the official SDK download instructions, copy `fusion/` into `res://addons/`, configure Project Settings, and migrate one isolated test scene first: https://doc.photonengine.com/fusion-godot/v3-shared-authority/getting-started/sdk-download
- **Tubo** is a small WebRTC session helper. Consider it only when browser or NAT traversal is a confirmed requirement. Install the exact Asset Library release into `res://addons/`, then test connect, disconnect, relay fallback, and mobile permissions without changing gameplay RPCs.
- **3D Multiplayer Template** is unrelated to this 2D project. Do not import it.
- **MQTT Node** is broker messaging, not real-time authoritative gameplay transport. It may support presence or telemetry later, but must not carry combat state.

## Installation gate

Before adding an online dependency, record its backend, license, platform binaries, authority model, and migration surface. Keep the addon disabled until these existing tests pass: `tests/online_lobby_smoke.gd`, `tests/multiplayer_lobby_integration_smoke.gd`, `tests/multiplayer_room_lifecycle_smoke.gd`, `tests/multiplayer_three_player_contract_smoke.gd`, and the affected visual smoke. Never put App IDs, access tokens, relay secrets, or hosted-service credentials in Git.

## Compatibility rules

Do not mix a new framework's room, authority, prediction, or RPC objects with the current ENet objects in the same gameplay scene. If an experiment needs another transport, isolate it behind a test scene and an adapter that preserves the current pack/send/receive/apply contract. Remove the experiment when it introduces parse errors, native crashes, unbounded socket listeners, or a mobile export regression.
