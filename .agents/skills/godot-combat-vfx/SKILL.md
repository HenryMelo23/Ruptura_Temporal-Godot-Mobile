---
name: godot-combat-vfx
description: Use for Godot combat VFX, particles, projectiles, impacts, boss attacks, shaders, camera feedback, and ability animation.
---

# Godot Combat VFX

Use with `ruptura-project-context`, `ruptura-visual-direction`, and `godot-visual-qa`.

## Principle

A good ability effect is a timed composition of layers, not a default particle emitter.

Choose appropriate layers:

- Anticipation or warning.
- Charge/accent buildup.
- Main shape and readable silhouette.
- Core, trail, secondary particles.
- Light/glow/shader distortion when useful.
- Impact, fragments, smoke/residue, ground mark.
- Target reaction, camera feedback, short hit-stop when appropriate.
- Dissipation and cleanup.

## Identity

- Temporal rupture: cyan, echoes, split lines, rings, displaced trails, repeated fragments, brief distortion.
- D37 infection: controlled green, organic asymmetry, tendrils, thorns, cracks, viscous residue.
- Physical attacks: weight, direction, dust, debris, recoil, compression.

## Technical Rules

- Use GPUParticles2D or CPUParticles2D deliberately; configure amount, lifetime, velocity, spread, damping, color/scale curves, draw order, and cleanup.
- Do not leave default particle values.
- Do not make projectiles look like simple colored balls.
- Do not synchronize every particle in multiplayer; sync gameplay events and play local VFX per client.
- Consider object pooling for high-frequency projectiles/impacts.
- Preserve gameplay logic; VFX failure must not break damage logic.
