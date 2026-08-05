# Phase 5 UMBRA Rework Audit

## Source Files Scanned

- `Game Base/habilidade_boss.py`
- `Game Base/GAME5.py`
- `Game Base/memoria_predatoria_umbra.json`
- `Game Base/umbra_profecia.py`
- `Game Base/umbra_dossie.py`
- `Game Base/sistema_ratos_umbra.py`
- `Game Base/Ruptura_Temporal-APOLO2.0/Engine/Variaveis.py`
- Mobile target: `scripts/main.gd`

## Core Identity

UMBRA is not a regular boss with a fixed rotation. In the Game Base she reads the player, chooses movement/action through a trained mind, changes dimensions, and only uses the power that belongs to the current dimension.

The mobile version already had the assets, memory load, basic weighted decisions, projectile, teleport, siphon, rats, miasma, prison, vortex, discharge and thorns. The biggest gap was orchestration: the mobile boss could choose every dimensional skill at any time, which made the fight feel random instead of intelligent.

## Game Base Decision Rules

- Always has basic attack available.
- Teleport and teleport-juke unlock when teleport cooldown is ready.
- Siphon unlocks after the fight has lasted more than 20 seconds and its cooldown is ready.
- Transmutation unlocks every 25 seconds, but only when no dimensional ability is active.
- A dimension must exist for at least 5 seconds before another transmutation is considered.
- Each transmutation lasts 30 seconds before returning to the base map, unless a dimensional ability is still active.
- The last dimension is avoided to prevent repetitive loops.

## Dimension To Skill Mapping

- `vortice` uses `VORTICE`.
- `gravidade` uses `PRISAO`.
- `necrose` uses `MIASMA`.
- `ressonancia` uses `DESCARGA_ELETRICA`.
- `hemorragia` uses `CAMINHO_ESPINHOS`.
- `atrito` uses `LASER_SOBRECARGA`.
- `rastro` uses `PRAGA_RATOS`.

## Game Base Timing Notes

- Transmutation cooldown: 25s.
- Dimension duration: 30s.
- Minimum time inside a dimension before leaving/changing: 5s.
- Prophecy cooldown: 4s.
- Prophecy validity window: 1.0s to 2.5s.
- Vortex cooldown: 12s.
- Prison cooldown: 9s.
- Miasma cooldown: 10s.
- Discharge cooldown: 11s.
- Thorns cooldown: 8s.
- Rat plague cooldown: 12s.
- Siphon cooldown: 18s on mobile, 20s source intent after the end of the ability.

## Movement Notes

The Game Base movement uses intention states such as flee, intercept, orbit and surround. It uses inertia rather than snapping to the target. Mobile had a strong velocity lerp that made UMBRA feel too robotic. The new mobile adjustment reduces the lerp speed so the boss has a smoother, more deliberate drift.

## Prophecy Notes

`umbra_profecia.py` predicts player behaviors and rewards or punishes the boss mind after the prediction window:

- flee left;
- flee right;
- go to corners;
- approach aggressively;
- wait/stand still;
- other source categories exist for dash/orb/long range.

The mobile port now includes a light tactical prophecy layer. It does not directly change damage or life. It changes short-term action scoring and exposes the mental state visually.

## Mobile Reconstruction Applied

- Dimensional skills are now locked to the current dimension.
- Transmutation now starts a 30s dimension timer.
- UMBRA returns to base after the dimension expires and no dimensional ability is active.
- Transmutation starts a visual `dimension_burst` effect.
- The currently active dimension and remaining time are drawn during the boss fight.
- A lightweight prophecy state now observes player movement and adjusts tactical scoring briefly.
- UMBRA movement smoothing was reduced to preserve momentum.

## Remaining High-Value Follow-Ups

- Port the full source prophecy taxonomy including dash, orb and long-range attack prediction.
- Make the visual map transition more literal if phase-specific map textures are meant to flash during the fight.
- Port the source laser overload as its own multi-round beam pattern instead of reusing the discharge hazard.
- Expand `sistema_ratos_umbra.py` behavior so rat plague has healing/pressure logic closer to the desktop source.
- Add focused visual smoke screenshots for each dimension once debug hooks for direct Boss 5 dimension selection are stable.
