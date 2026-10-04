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
