---
name: godot-visual-qa
description: Use after every Godot visual/UI/VFX change to require screenshot-based verification and console review.
---

# Godot Visual QA

Visual work is not done until it has been observed in real screenshots.

## Required Cycle

1. Inspect current state.
2. Run the project or affected scene.
3. Capture before screenshot when modifying an existing visual.
4. Implement.
5. Run again.
6. Capture after screenshots.
7. Compare visually.
8. Fix text clipping, overlap, weak hierarchy, generic styling, excessive effects, or performance issues.
9. Review full terminal/log output.
10. Run focused scene smoke and final project validation when code/resources changed.

## Review Questions

- Is there a clear focal point?
- Does the player understand what to do?
- Does the result belong to Ruptura Temporal without reading the title?
- Are buttons/states professional and touchable?
- Is text readable on mobile landscape and low resolution?
- Does the movement communicate a state?
- Does the effect have anticipation, execution, and dissipation when appropriate?
- Does the effect hide gameplay?
- Are nodes/resources cleaned up?
- Did screenshots prove the result?

Do not deliver visual changes from code inspection alone.
