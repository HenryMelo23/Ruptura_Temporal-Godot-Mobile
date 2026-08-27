---
name: ruptura-token-efficient-workflow
description: Use before non-trivial Ruptura Temporal repository work to reduce token use, avoid broad scans, and choose the smallest sufficient validation path.
---

# Ruptura Token Efficient Workflow

Use this skill before any non-trivial task in the Ruptura Temporal repository, especially Godot, Game Base parity, UMBRA, VFX, UI, balancing, online, or release work.

The goal is to spend context on the real control points only. Do not use this skill to skip required validation after code, scene, resource, project setting, addon, or test changes.

## First Pass

Run a bounded discovery pass before opening large files:

- Check `git status --short`.
- Search with `rg` for the exact symbol, scene, ability, hazard, setting, or test name.
- Prefer `rg --files` over directory walks.
- Read only the relevant line windows from large files such as `scripts/main.gd` and files under `Game Base/`.
- Quote paths with spaces in PowerShell, for example `'Game Base'`.
- Open only the required repository skills for the task.

Default discovery budget: five shell reads/searches before deciding the first implementation path. Expand only when a concrete missing link appears.

## Context Ladder

Load context in this order:

1. Current repo instructions: `AGENTS.md` and this skill.
2. Required domain skill, for example `ruptura-project-context`, `godot-engineer`, `godot-umbra-ai-port`, `godot-combat-vfx`, or `godot-test-repair`.
3. Affected script, scene, test, and direct callers.
4. Game Base reference only when the request asks for parity or when existing code names a Game Base source.
5. Broader docs only when a local symbol or test points to them.

Avoid reading whole lore docs, whole copied game files, whole logs, or all tests unless the task explicitly needs that scope.

## Implementation Loop

Keep each loop small:

- State the target files and assumption before editing.
- Change the smallest set of files that can satisfy the request.
- Preserve dirty worktree changes and ignore unrelated modified files.
- Prefer constants, narrow helpers, focused tests, and existing data paths over rewrites.
- If a test failure is stale or unrelated, record the exact failure and continue with the focused validation required for the change.
- Stop expanding the investigation when the player-visible behavior has a verified control point.

## Validation Ladder

Choose the cheapest validation that honestly covers the edit:

- Markdown, docs, or agent-skill-only change: validate formatting/skill structure and run `git diff --check`; no Godot validator is required.
- Single GDScript or tool edit: parse changed scripts with `--check-only`, then run the nearest focused tool/test.
- Gameplay, VFX, AI, collision, UI, or scene edit: run focused parse/test plus the affected scene or flow smoke.
- Shared systems, project settings, resources, addons, release, online, export, or uncertain blast radius: run the deep project validator.

On Windows, prefer the project validator when code or scene validation is required:

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\validate_godot.ps1 -Deep
```

Use `-Scene "res://path/to/scene.tscn"` and a small `-SmokeFrames` value for focused smoke checks during repair.

## Output Discipline

Do not paste massive logs into the conversation. Summarize the signal:

- command name;
- pass/fail;
- first actionable error line;
- exact log path when deeper inspection matters.

Final reports should include changed files, validation commands, what ran cleanly, and any path not exercised.

## Portability

This skill is stored under `.agents/skills/`, and `AGENTS.md` references it. Keep both files committed so the workflow travels through GitHub between desktop and notebook.
