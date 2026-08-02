---
name: godot-engineer
description: Use for Godot implementation, debugging, gameplay, UI, animation, scene, resource, shader, input, save, and architecture tasks.
---

# Godot Engineer

Before editing, inspect `project.godot`, relevant scenes, scripts, autoloads, input actions, resources, tests, and callers. Search the repository before assuming a node, signal, action, resource, or method exists.

Work in the existing architecture. Prefer typed GDScript when nearby code is typed. Keep changes scoped and preserve user work in the dirty tree.

Do not hide errors with broad fallbacks, warning suppression, dummy resources, or deleted functionality. If a fallback is needed, log the specific missing resource.

For visual tasks, also use:

- `ruptura-project-context`
- `ruptura-visual-direction`
- `godot-ui-professional` or `godot-combat-vfx`
- `godot-visual-qa`

Finish with focused validation plus the project validator when code, scenes, resources, addons, or project settings changed.
