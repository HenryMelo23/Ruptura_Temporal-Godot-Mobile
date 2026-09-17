# Public relay repair: 2026-09-12

Branch: `codex/multiplayer-main-2026-09-12`.

## Confirmed causes

- The client forced FastLZ, while the deployed relay used ENet's default
  compression. An isolated public ENet probe timed out after 12 seconds with
  FastLZ and connected in 41 ms without compression.
- After matching compression, the connection exposed `rpc node checksum failed`.
  The deployed main.gd SHA256 was
  `21b945027d26a4d0f86dc1cd09d0a941f6d389bcde6d8c996b2ffb5bbd40a2cc`.
  This branch uses
  `6fb24f301dea84fb1c3b2b38ab1dddc03eecf16648a986fd723b352c58ffa0b1`.

## Changes

- Default transport uses no compression. Explicit FastLZ remains available only
  when both endpoints are configured identically. The wire test verifies the
  production default against an unconfigured receiver and separately checks
  compressed payload integrity.
- Added `tests/relay_enet_probe.gd` to separate ENet handshake failures from RPC
  failures. Arguments: `--host=HOST --port=PORT --compression=none|fastlz`.
- Updated deployed scripts, scenes, shaders, VFX and project settings to this
  branch, including the modified transport module. Imported resources on the VPS.
  Server source backup: `/opt/ruptura/relay-source-backup-20260912-0203.tar.gz`.
- Uploaded the missing Top_Menu.otf and World.otf fonts, reimported resources,
  and restarted the relay. New rooms no longer reported missing fonts.
- Enabled repository-local `core.longpaths`. Added a tracked toolchain/.gdignore
  so Godot does not import the Android SDK as game assets. SDK contents remain
  excluded from Git.

## Observed validation

- Local lobby: ready, spectator, and three-player selection-to-game flow passed.
- Public lobby: ready and spectator passed after deployment.
- Public gameplay: host/client reached game; 22 client damage routes were applied
  by host authority; targeted enemy damage arrived only at the intended client.
  Observed final/minimum peer RTT: 32-33 ms. This is one desktop running two game
  processes through the public VPS, not a cellular or packet-loss stress test.
- Deep validation parsed 301 scripts and Boot.tscn ran for 300 frames; no errors
  in that validation's logs. SDK import was excluded before the successful run.

The first public gameplay run timed out while local SDK import was still causing
heavy load. A subsequent run passed after resource preparation and validation.
Do not treat /health alone as proof of gameplay compatibility. Use
`tools/run_public_relay_smoke.ps1` and
`tools/run_public_relay_gameplay_smoke.ps1` with their version checks enabled.

Installed clients must use compatible RPC declarations. Updating the relay does
not update existing APK/EXE installations, and no player update was published.

## Remaining limitation

The final public ready/spectator battery passed, but VPS journal inspection
showed one `Unable to send packet on channel 0, max channels: 0` during the
near-simultaneous exit of the two spectator-test peers. There was no GDScript
stack trace. This teardown race is not fixed or attributed to a confirmed cause.
Do not describe the entire VPS session as error-free.

Final changed-script validation passed after the last GDScript edit, including
Main.tscn for 120 frames. The default-versus-plain ENet wire test also passed.
