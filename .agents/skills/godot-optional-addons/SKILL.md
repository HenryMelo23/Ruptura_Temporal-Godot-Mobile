---
name: godot-optional-addons
description: Evaluate deferred Godot add-ons before adding rendering, AI, particles, or editor-only dependencies to Ruptura Temporal.
---

# Optional add-ons

Install these only when a concrete feature needs them and after checking Godot 4.7/mobile compatibility. Add-ons must remain isolated behind a reversible project setting and must not change the game's story or core runtime contract.

## Current shortlist

- **LimboAI** — behavior trees and state machines. Use only for a bounded enemy or boss migration; the project already has custom AI paths. Install the Godot 4 release from https://github.com/limbonaut/limboai/releases, copy its `addons/limboai` directory into `res://addons/`, enable it, and run AI-focused smoke tests.
- **Lit 2D Lighting Engine** — alternative 2D lights and post-processing. Install the Godot Asset Library release into the project root, then profile the Compatibility/Mobile renderer before enabling it globally.
- **Post Effect Stack** — ordered post effects. Install the matching Godot 4.7 Asset Library package into `res://addons/`, apply it first in a test scene, and verify that the health-danger red vignette and glitch remain readable on mobile.
- **Wind Driven Falling Particles** — a template project, not a drop-in addon. Do not copy its whole project into this game; port only a reviewed particle shader/scene if a wind effect is later approved.
- **Vfx Animation Player** — editor support for scrubbing particle emission. Install from its official repository or Asset Library only when authoring particle timelines; it is not needed in exported builds.

## Decision gate

Before installing an optional item, record the feature it unlocks, its license, renderer/platform support, and the smallest affected scene. Keep the addon disabled until import, parse, scene smoke, and screenshot QA pass. Remove it from the project if it introduces parse errors, native crashes, socket listeners, or mobile regressions.
