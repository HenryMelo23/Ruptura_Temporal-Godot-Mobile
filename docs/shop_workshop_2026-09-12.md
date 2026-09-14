# Shop presentation and multiplayer

## Behavior

Landscape shop presentation now lives in `scripts/ui/shop_presentation.gd`.
The existing main scene owns input, purchases, card effects, and RPCs. The module
owns layout and transient visual state; it never charges a wallet or sends RPCs.
Existing card art and animated textures are reused. Portrait keeps the existing
layout; the target platforms are desktop and landscape mobile.

- Purchase: card flies to the deck; existing 0.62-second transaction commits once.
- Reroll: staggered card flips; reserved slots remain visible and unchanged.
- Burn: pixelated fire front and embers, 0.72 seconds; source art remains visible
  during destruction. Burning clears the reservation, consumes one Cinzas card,
  and preserves the existing accumulated bonus. The bonus is described explicitly.
- Reserve: sliding seal, 0.34 seconds. Unlocking uses the same short feedback window.
- Exit: cards move offscreen during the existing 0.72-second visual transition;
  the three-second synchronized gameplay return remains unchanged.
- Actions and exit are gated during purchase, reroll, burn, and reserve animations.
- Multiplayer: spending stays individual; the ready count includes only living
  registered players. Eliminated observers and the last living player can return
  when the remaining shoppers finish. Disconnects refresh readiness counts.

No RPC declarations or packet schemas were added or changed. This shop work was
validated locally; it has not been deployed to the VPS or exported to APK/EXE.

## Changed files

- `scripts/main.gd`
- `scripts/ui/shop_presentation.gd` and generated UID
- `tests/multiplayer_shop_flow_smoke.gd`
- `tests/shop_schedule_rarity_smoke.gd`
- `tests/support_cards_smoke.gd`
- `tests/shop_workshop_visual_smoke.gd` and generated UID
- `tests/multiplayer_shop_wire_smoke.gd` and generated UID
- `tools/run_multiplayer_shop_smoke.ps1`
- This report

Existing transport/.gitignore changes from the preceding task were preserved.
The shop fixtures now explicitly complete the player-arrival phase and disable
the onboarding tutorial before exercising shop controls. Support-card assertions
use the new presentation state instead of a missing legacy animation field.

## Validation

Use `-GodotBin` with the local Godot console executable for PowerShell tools.
Godot 4.6.3 was used locally.

Passed:

- `tools/validate_godot.ps1 -Deep`, including Boot.tscn, 300 frames.
- Final explicit-script validator plus Main.tscn, 120 frames.
- `tools/run_multiplayer_shop_smoke.ps1`: separate ENet server, host and client;
  host spent 500 points, client retained 5000, host waited for client, consensus
  released both peers. This is a local network test, not a new VPS/cellular test.
- `tests/shop_hub_animation_smoke.gd`
- `tests/shop_deck_ui_smoke.gd`
- `tests/multiplayer_shop_flow_smoke.gd`, including eliminated peers, sole survivor
  and stale/dead vote exclusion.
- `tests/support_cards_smoke.gd`
- `tests/shop_schedule_rarity_smoke.gd`
- `tests/shop_fairness_v2_smoke.gd`: 100000 iterations, zero duplicate offers.
- `tests/shop_workshop_visual_smoke.gd`: 1280x720, 960x540, 800x450; purchase,
  reroll, reserve, burn, team/waiting, return and longest name/description.

Visual captures: `.codex/shop_workshop_1280x720.png`,
`.codex/shop_workshop_800x450.png`, `.codex/shop_purchase_1280x720.png`,
`.codex/shop_reroll_1280x720.png`, `.codex/shop_reserve_1280x720.png`,
`.codex/shop_burn_1280x720.png`, `.codex/shop_return_1280x720.png`.
Logs: `.agent_logs/shop_*current.log` and `.agent_logs/shop_wire/`.
