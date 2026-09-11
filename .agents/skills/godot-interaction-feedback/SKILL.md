---
name: godot-interaction-feedback
description: Use Interaction Feedback for restrained hover, focus, press, touch, and keyboard feedback on Godot Control or Node2D UI.
---

# Interaction Feedback

Use the addon to give menus, settings, catalog cards, and HUD controls tactile motion without coupling feedback to gameplay state. Prefer small scale, offset, rotation, or modulation effects that preserve readable focus and touch targets.

## Dependency and portable installation

The project should contain `res://addons/interaction_feedback/plugin.cfg` and have `InteractionFeedback` enabled in Project Settings. If it is missing, install the tested upstream release with:

```bash
git clone --depth 1 --branch v1.1.1 https://github.com/paufau/godot-interaction-feedback.git /tmp/godot-interaction-feedback
cp -a /tmp/godot-interaction-feedback/addons/interaction_feedback res://addons/
```

When `res://` is not a shell path, replace it with the absolute project directory. The same addon folder can be downloaded from the repository archive on systems without Git. Enable it from Project Settings → Plugins; it requires Godot 4.7+.

## Usage

Attach an `InteractionFeedback` child to the target and add focused effects such as `FeedbackScaleEffect`, `FeedbackOffsetOnceEffect`, or `FeedbackModulateOnceEffect`. From code:

```gdscript
var feedback := InteractionFeedback.attach(button)
feedback.add_effect(FeedbackScaleEffect.new())
```

Keep animation durations short, avoid stacking multiple large transforms on one control, and retain keyboard focus plus touch behavior. Do not use the addon to hide disabled states or replace the project's danger/glitch language.

## Validation

Run the affected scene in desktop and landscape mobile layouts. Confirm hover/focus, press, and touch feedback remain readable and that the terminal has no script or resource errors. The addon is optional at runtime; gameplay must still load if it is disabled.
