# Multiplayer visual fidelity contract

Gameplay authority and visual fidelity are separate contracts. Damage, targets,
cooldowns, drops and world state remain authoritative. Clients reconstruct the
presentation from compact state and event data; they never reproduce gameplay
damage from a visual RPC.

## Continuous player presentation

`RTVisualSyncContract.PLAYER_VISUAL_SCHEMA` defines an 11-float fixed snapshot sent on
the existing unreliable ordered player channel. It carries normalized movement
and aim, current action, action elapsed time, speed ratio, action sequence and
visual flags. Position, HP, manifestation, exact animation state/frame and
facing continue in the existing light player packet.

The extension is 44 bytes per player sample. At the existing 16 ms interval its
raw incremental cost is about 2.75 KiB/s per sender before transport overhead.
Late packets may be replaced by newer state because only the latest movement
intent matters.

## Canonical ability presentation

Q, E, attack-special and teleport presentation start on reliable channel 4.
Schema 3 includes a stable `event_id`, manifestation key, deterministic seed,
aim/move intent and a `canonical_state` captured from the same presentation
collections consumed by the local renderer. The receiver temporarily applies
that state to the presentation context and invokes the existing local drawing
functions; it does not maintain a second, simplified version of each ability.

Long-lived Q/E effects receive bounded state corrections every 250 ms on the
unreliable-ordered visual channel. These corrections keep dynamic targets,
formations and animation state aligned without synchronizing damage or running
gameplay on the receiver. Initial events are limited to 24 KiB, corrections to
12 KiB, and at most four local effects may be tracked simultaneously.

The relay forwards these events without instantiating effects. Receivers reject
duplicate or reordered sequence numbers per source peer. A stable manifestation
key wins over a stale numeric index, preserving compatibility when ordering
changes between builds.

Quality settings may apply the same existing local LOD rules, but cannot replace
the ability with another drawing. Gravitante, for example, invokes
`RTGravitanteVfx` on both peers with the same event state, evolutions and
timing. The same rule applies to all 15 manifestations.

## Test evidence

- `multiplayer_network_smoothing_smoke.gd`: fixed snapshot schema, movement,
  aim, action/frame preservation, canonical Q/E/teleport state for all 15
  manifestations, dynamic-state correction and event deduplication.
- `multiplayer_ability_visual_smoke.gd`: real dedicated relay, bidirectional
  host/client Q, E, teleport, dynamic state correction and player visual state;
  relay remains presentation free.
- `multiplayer_visual_fidelity_visual_smoke.gd`: desktop and low-resource
  captures with multiple remote players and manifestation-specific effects.
