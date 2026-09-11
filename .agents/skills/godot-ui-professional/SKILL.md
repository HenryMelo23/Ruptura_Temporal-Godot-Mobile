---
name: godot-ui-professional
description: Use for Godot UI, HUD, menu, settings, catalog, modal, button, theme, layout, and interaction work.
---

# Godot UI Professional

Use with `ruptura-project-context`, `ruptura-visual-direction`, and `godot-visual-qa`.

## Before Editing

- Run or smoke the current screen.
- Capture a screenshot.
- Inspect scene/script ownership, signals, fonts, textures, themes, and input paths.
- Identify logic that must be preserved.
- Diagnose visual issues.
- Define focal point, hierarchy, palette, and responsive behavior.

## Implementation Rules

- Prefer Controls, Containers, anchors, size flags, themes, reusable StyleBoxes, and AnimationPlayer/Tweens where they fit.
- Avoid hard-coded coordinates for production UI unless the surrounding codebase already draws procedurally.
- Keep interactive states distinct: normal, hover, focus, pressed, selected, disabled, loading, error.
- Focus must be visible for keyboard/controller use.
- Use motion for communication: entry, exit, selection, confirmation, error, connection, temporal transition.
- Avoid every element pulsing, constant glitch, all-glow screens, and generic rectangular buttons.
- Test text fit, safe areas, touch size, and no overlap on landscape mobile.

## Required Verification

Capture after screenshots for relevant resolutions and inspect them before final response. Verify console output and no new Godot errors.
