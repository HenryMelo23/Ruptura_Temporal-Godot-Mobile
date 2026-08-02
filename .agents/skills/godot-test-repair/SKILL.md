---
name: godot-test-repair
description: Use after any Godot source, scene, resource, project setting, addon, or test change.
---

# Godot Test Repair

On Windows, prefer:

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\validate_godot.ps1 -Deep
```

For focused scene validation:

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\validate_godot.ps1 -Scene "res://path/to/scene.tscn"
```

Loop until actionable errors are fixed:

- Reproduce.
- Read full output and `.agent_logs/`.
- Identify the real cause.
- Patch narrowly.
- Re-run the smallest relevant command.
- Re-run final validation.

Do not claim success if validation was skipped, timed out, or failed.
