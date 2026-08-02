---
name: ruptura-project-context
description: Use for every task in Ruptura Temporal to preserve project identity, platform assumptions, and existing architecture.
---

# Ruptura Project Context

Use this skill before any Ruptura Temporal implementation, UI, VFX, animation, gameplay, or QA task.

## Project Facts

- Project: Ruptura Temporal Mobile.
- Engine found in this workspace: Godot 4.7 stable.
- Primary language: GDScript.
- Main scene currently starts through `res://scenes/Boot.tscn`, which loads `res://scenes/Main.tscn`.
- Target layouts: desktop and mobile landscape. Do not design mobile portrait flows unless explicitly requested.
- The project has existing systems for menus, saves, profiles, online/LAN code paths, bosses, abilities, cards, audio, and tests. Inspect before changing and avoid rewrites.

## Visual Identity

Ruptura Temporal mixes unstable science, temporal rupture, D37 infection, worn technology, western/noir tension, mystery, danger, and cinematic 2D composition.

Visual references are direction only: high contrast graphic painting, premium game interfaces, cracked/worn materials, layered panels, temporal distortion, Arcane/Spider-Verse-level polish without copying either style.

Avoid anime drift, generic neon cyberpunk, corporate dashboards, toy-like UI, template aesthetics, and effects that are only circles or default particles.

## Narrative Color Roles

- Cyan: temporal energy, synchronization, rupture, interface focus.
- Green-neon: D37 infection, corruption, organic danger.
- Dark desaturated tones: base atmosphere.
- Warm earth tones: western influence, worn matter, dust, metal.
- Red/orange: danger, impact, alerts.
- White/cream: main readable text when contrast is needed.

Colors must have function. Do not make every element glow.

## Work Rule

Preserve user changes in the dirty worktree. Never reset or revert unrelated files. Prefer small, tested changes that fit the current architecture.
