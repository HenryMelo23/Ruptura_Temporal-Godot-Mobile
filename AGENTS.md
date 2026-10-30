# Ruptura Temporal Agent Context

Use this file as the minimal task router. Load only the extra file that matches
the current task.

## Required First Step

For any non-trivial repository work, use:

- `.agents/skills/ruptura-token-efficient-workflow/SKILL.md`
- `.agents/skills/ruptura-project-context/SKILL.md`

For runtime navigation, large-file lookup, or owner discovery, use:

- `.agents/skills/ruptura-runtime-navigation/SKILL.md`
- `.agents/runtime_symbol_index.md`
- `AGENT_CODEMAP.md`

For refactor sequencing and stop rules, use:

- `.agents/REFRACTOR_CAMPAIGN.md`

## Solo-First Multiplayer Freeze

The user froze multiplayer validation on 2026-10-29 to prioritize solo
production. Until the user explicitly asks to resume multiplayer validation:

- Keep new gameplay compatible with the existing multiplayer architecture when
  the affected path already has authority, snapshot, RPC, or remote-visual
  handling.
- Do not run dedicated-server, host/client, relay, lobby, online, multi-process,
  or physical multi-device tests. Validate the solo behavior instead.
- Do not remove, bypass, or knowingly break existing multiplayer contracts just
  because their validation is deferred.
- Append every feature with unverified multiplayer impact to
  `.agents/MULTIPLAYER_DEFERRED_VALIDATION.md`, including the solo evidence and
  the exact multiplayer scenarios still owed.
- Do not load or execute the complete deferred backlog during normal solo work.
  Read it in full only when the user explicitly asks to resume or audit
  multiplayer.

The reproducible frozen remote baseline and current pending items live in that
backlog.

## Context Budget

- Before implementation, keep discovery to at most 5 searches/reads and at most
  3 full files.
- Do not read files over 100 KB in full by default. Search an exact symbol and
  open a small line window.
- Prefer focused validation first. Run the deep Godot validator only when the
  change affects broad/shared runtime behavior, scenes, resources, exports, or
  uncertain blast radius.
- Preserve dirty worktree changes that are not part of the current task.

## Architecture Budget

Run the infrastructure budget check before and after refactor-sized runtime
work:

```bash
python3 tools/check_architecture_budget.py
```

Only refresh the baseline after reviewing a deliberate architecture change:

```bash
python3 tools/check_architecture_budget.py --write-baseline
```

## Completion

Report only the files changed, focused validations run, and any path not
exercised. Do not claim gameplay coverage for infrastructure-only checks.
