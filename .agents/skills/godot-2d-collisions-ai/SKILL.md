---
name: godot-2d-collisions-ai
description: Use for Godot 2D collision layers/masks, DirectSpaceState2D queries, NavigationAgent2D, NPC steering, and bot AI.
---

# Godot 2D Collisions AI

Inspect layer/mask usage before changing collisions. Prefer explicit query parameters and documented groups. Validate with focused smoke tests that exercise contact, overlap, hitbox, hurtbox, and navigation behavior.

Do not change global collision layers or masks without updating callers, tests, and documentation.
