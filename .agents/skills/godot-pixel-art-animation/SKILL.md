---
name: godot-pixel-art-animation
description: Create and integrate pixel-art sprite frames and directional animation in Godot while preserving the existing character identity and pixel scale.
---

# Godot Pixel Art Animation

Resolve the actual playable textures and their callers before choosing references; filenames such as Stop may belong to a different character. Inspect the idle, movement, and existing attack images at native size.

For new raster frames, use the available image-generation/editing tool with the original sprites as references. Keep source assets unchanged. Preserve hair, face, glasses, clothing, palette, outline, body proportions, and pixel density. Direction changes may expose previously hidden surfaces, but must not redesign the character. Reject mismatched results instead of masking discrepancies through stretching or glow.

Use consistent transparent cells, ground anchors, and body height across a sequence. Check actual alpha rather than assuming a checkerboard is transparency. Store accepted images and their direction/frame mapping in the repository; avoid machine-specific asset paths. AtlasTexture regions are suitable for a generated sprite sheet and avoid lossy resampling.

Connect the animation to the actual attack direction captured when the shot is emitted. Preserve movement, damage, freeze, and special-ability priorities. A stationary attack must not replace the walk cycle while moving. Keep shot timing and damage independent of frame timing. If animation snapshots are networked, update and test both local and remote texture selection.

Verify every requested direction, both frames, return to idle, attack while moving, and interruption by damage or freeze. Compare screenshots at gameplay scale and enlarged nearest-neighbor scale. Inspect terminal output and follow the repository Godot validation rules after the final change.

This skill is project-owned. Keep this file and its .gitignore allowlist committed so it is available on other devices. Respect the user's existing authorization; the skill does not introduce an additional approval step.
