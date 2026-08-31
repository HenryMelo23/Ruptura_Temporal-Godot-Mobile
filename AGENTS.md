# Godot Project Agent Rules

## Mission

Work as an autonomous Godot software engineer. Complete requested changes directly in the repository, preserve the existing design, and verify the real project before reporting completion.

## Non-negotiable completion rule

A code-changing task is not complete until the project has been tested after the final edit.

Before delivering:

1. Import and validate the Godot project from the command line.
2. Parse the changed GDScript files and any directly affected scripts.
3. Build the C# solution when the project uses C#.
4. Run the project's existing automated tests, when present.
5. Run the main scene and every directly affected scene or flow.
6. Inspect the complete terminal output, not only the process exit code.
7. Fix every actionable parse error, script error, missing resource, invalid node path, invalid call, failed assertion, and regression caused or exposed by the work.
8. Repeat the test-and-repair cycle until the tested commands finish successfully and the terminal contains no Godot errors.

Never claim that the project works when the verification was skipped, failed, timed out, or produced errors.

## Required skills

Before any non-trivial Ruptura Temporal repository task, use the token-efficient workflow skill to keep context gathering, edits, and validation scoped:

- `.agents/skills/ruptura-token-efficient-workflow/SKILL.md`

For any Godot implementation, debugging, scene, resource, gameplay, UI, animation, signal, physics, save system, shader, input, or architecture task, use the repository skill:

- `.agents/skills/godot-engineer/SKILL.md`

For any Ruptura Temporal task, first preserve the project context and visual identity:

- `.agents/skills/ruptura-project-context/SKILL.md`

For UI, HUD, menu, settings, catalog, modal, typography, button, layout, or interaction work, use:

- `.agents/skills/ruptura-visual-direction/SKILL.md`
- `.agents/skills/godot-ui-professional/SKILL.md`
- `.agents/skills/godot-visual-qa/SKILL.md`

For combat VFX, particles, projectiles, boss attacks, shaders, impact feedback, animation, or visual gameplay effects, use:

- `.agents/skills/ruptura-visual-direction/SKILL.md`
- `.agents/skills/godot-pixel-art-animation/SKILL.md` when sprite/frame animation, pixel-art motion, animated UI/icons/cards, or animation polish is involved
- `.agents/skills/godot-combat-vfx/SKILL.md`
- `.agents/skills/godot-visual-qa/SKILL.md`

For pixel-art animation work that looks flat, generic, low-detail, blurry, lifeless, or too procedural, use:

- `.agents/skills/godot-pixel-art-animation/SKILL.md`
- `.agents/skills/ruptura-visual-direction/SKILL.md`
- `.agents/skills/godot-visual-qa/SKILL.md`

For layered scene/map/menu/phase/dimensional transitions where one image, texture, map, or frame is revealed under another, use:

- `.agents/skills/godot-image-reveal-transitions/SKILL.md`
- `.agents/skills/ruptura-visual-direction/SKILL.md`
- `.agents/skills/godot-visual-qa/SKILL.md`

For UMBRA/Fase 5 AI, predatory memory, prophecy, DQN weight export/import, dimension transmutation, ability gating, or Game Base-to-Godot mind compatibility, use:

- `.agents/skills/godot-umbra-ai-port/SKILL.md`
- `.agents/skills/godot-2d-collisions-ai/SKILL.md` when movement, steering, hitboxes, hazards, or spatial queries change
- `.agents/skills/godot-combat-vfx/SKILL.md` and `.agents/skills/godot-visual-qa/SKILL.md` when VFX or visual readability changes

For 2D pixel art particles, physics optimization, spatial hashing, and soft-body separation, use:

- `.agents/skills/godot-pixel-physics-particles/SKILL.md`

For 2D collision rules, layer/mask matrix, DirectSpaceState2D queries, NavigationAgent2D, and NPC/Bot steering AI, use:

- `.agents/skills/godot-2d-collisions-ai/SKILL.md`

For game design, mathematical stat scaling, diminishing returns, damage formulas, and Roguelike/Roguelite/Soulslike balancing rules, use:

- `.agents/skills/godot-game-balancing/SKILL.md`

For fast navigation of the large `scripts/main.gd` integration file, especially when a task touches menus, HUD, online, audio, bosses, phases, abilities, or player state, use:

- `.agents/skills/ruptura-main-gd-navigation/SKILL.md`

For online/multiplayer, lobby, tunnel, room readiness, host/client packet flow, enemy/player synchronization, revive, score sharing, votes, or leadership, use:

- `.agents/skills/ruptura-online-contracts/SKILL.md`

For music playlist, menu music, phase music, looping boss/weather audio, SFX lifecycle, stereo/mono behavior, or sound assets, use:

- `.agents/skills/ruptura-audio-lifecycle/SKILL.md`

For version bumps, GitHub preservation, APK/EXE export, update-server publishing, release notes, fonts, or asset portability between desktop/notebook/mobile, use:

- `.agents/skills/ruptura-release-portability/SKILL.md`

After any source, scene, resource, project setting, addon configuration, or test change, use:

- `.agents/skills/godot-test-repair/SKILL.md`

## Before editing

Inspect before changing:

- `project.godot`;
- the main scene and affected scenes;
- autoloads and global state;
- input actions;
- affected scripts and their callers;
- connected signals;
- inherited scenes and scripts;
- resources, groups, node paths, and exported properties;
- existing tests and project-specific validation commands;
- Godot version and whether the project uses GDScript, C#, GDExtension, or addons.

Search the repository before assuming a class, node, signal, input action, resource, method, or setting exists.

## Implementation behavior

- Make the smallest complete change that solves the request.
- Follow the project's existing architecture and naming style.
- Prefer typed GDScript when the surrounding code is typed.
- Preserve scene inheritance and reusable resources.
- Use signals for decoupled communication when consistent with the project.
- Do not add autoloads, addons, dependencies, or project settings without a clear need.
- Do not rewrite complete scenes or scripts when a targeted edit is sufficient.
- Do not hide errors with broad exception handling, warning suppression, dummy fallbacks, or deleted functionality.
- Do not leave placeholders, TODO-only solutions, disconnected signals, broken node paths, or unused exported properties.
- Update all callers when changing public methods, signals, resources, or data formats.

## Testing command

On Windows, prefer:

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\validate_godot.ps1 -Deep
```

On Linux or macOS, prefer:

```bash
bash ./tools/validate_godot.sh --deep
```

Use `-Scene "res://path/to/affected_scene.tscn"` on Windows or `--scene "res://path/to/affected_scene.tscn"` on Linux/macOS to smoke-test a specific affected scene.

Run focused checks during implementation and the deep validator after the final edit. If the validator fails, inspect its logs in `.agent_logs/`, correct the cause, and run it again.

## Test-and-repair loop

Continue while an error is actionable:

1. Reproduce the issue.
2. Read the complete error and stack trace.
3. Identify the actual cause.
4. Apply a targeted correction.
5. Re-run the smallest relevant test.
6. Re-run final project validation.

Do not stop after the first failed attempt. Do not ask the user to test something the agent can test with the available editor, terminal, or project tools.

## Honest boundary

A headless smoke test proves startup and the code paths exercised during that test; it does not prove every possible player interaction. For gameplay changes, create or run focused automated tests, test scenes, or reproducible debug flows that exercise the changed behavior. State exactly which paths were exercised.

## Final report

Keep the final response concise and include:

- what changed;
- files changed;
- tests and commands executed;
- whether the main scene and affected scenes ran without terminal errors;
- any path that could not be exercised and the precise reason.
