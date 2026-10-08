---
name: ruptura-runtime-navigation
description: Navigate Ruptura Temporal runtime owners, symbols, and tests without broad reads of large Godot files.
---

# Ruptura Runtime Navigation

Use this skill when a task touches runtime flow, `scripts/main_runtime_core.gd`,
domain ownership, symbol lookup, refactor planning, or test selection.

## First Move

- Read `AGENT_CODEMAP.md` for domain -> owner -> focused tests.
- Read `.agents/runtime_symbol_index.md` for exact symbols and line anchors.
- Run `python3 tools/check_architecture_budget.py` when refactor scope can grow
  or shrink runtime code.

## Large File Rule

Files over 100 KB are lookup targets, not reading targets. Do not open them in
full by default. Search the exact symbol and inspect a small window around the
line.

Known large files:

- `scripts/main_runtime_core.gd`
- `scripts/main_runtime_state.gd`
- `scripts/presentation/combat_effects_presentation.gd`
- `scripts/presentation/menus_presentation.gd`
- `scripts/presentation/world_environment_presentation.gd`

## Owner Rules

- Shop/economy behavior belongs in `scripts/ui/shop_controller.gd`.
- Shop presentation belongs in `scripts/ui/shop_presentation.gd`.
- Telemetry schema and payload logic belongs in
  `scripts/systems/telemetry/telemetry_system.gd`.
- Online serialization belongs in `scripts/systems/online/net_contract.gd`.
- Audio lifecycle belongs in `scripts/systems/audio/audio_lifecycle.gd`.
- Enemy wave logic belongs in `scripts/systems/enemy_manager.gd`.
- Boss 7 extracted logic belongs in `scripts/systems/modern_boss_controller.gd`.
- Core should remain a facade/orchestrator unless the codemap says no owner
  exists yet.

## Validation Routing

- Docs/skills/tools only: run skill validation when relevant, Python compile for
  tools, `python3 tools/check_architecture_budget.py`, and `git diff --check`.
- Single domain script: parse changed scripts and run the focused smoke test from
  `AGENT_CODEMAP.md`.
- Shared runtime or uncertain behavior: run focused tests first; use the deep
  Godot validator only after the narrower signal is clean or insufficient.

## Update Rule

When a refactor moves ownership or changes important symbol anchors, update both
`AGENT_CODEMAP.md` and `.agents/runtime_symbol_index.md` in the same change.
