# Runtime Refactor Campaign

Goal: make runtime work navigable and ratcheted before moving gameplay code out
of `scripts/main_runtime_core.gd`. This document is process only; it does not
authorize gameplay or balance changes.

## Non-Negotiable Rules

- No gameplay, economy, balance, timing, damage, spawn, input, save, or network
  behavior changes during infrastructure-only tasks.
- Before implementation, use at most 5 searches/reads and at most 3 full files.
- Never read files over 100 KB in full by default. Search an exact symbol and
  inspect a small surrounding window.
- Each refactor must name the owner file before moving code.
- Core should become a facade/orchestrator. New domain behavior belongs in the
  domain owner listed in `AGENT_CODEMAP.md`.
- Focused tests run first. Deep validation is reserved for broad/shared blast
  radius.
- Preserve dirty worktree changes that are unrelated to the task.

## Sequence

1. Infrastructure gate
   - Keep `AGENTS.md` minimal.
   - Maintain `AGENT_CODEMAP.md`.
   - Maintain `.agents/runtime_symbol_index.md`.
   - Run `python3 tools/check_architecture_budget.py`.

2. Owner extraction
   - Prefer existing owners under `scripts/ui`, `scripts/systems`, `scripts/presentation`, and `scripts/catalog`.
   - If no owner exists, create the smallest domain owner and keep core as a
     bridge.
   - Move one domain slice at a time.

3. Facade tightening
   - Replace direct core behavior with explicit facade calls.
   - Keep public method names stable until tests cover callers.
   - Update the symbol index after meaningful movement.

4. Ratchet
   - Refactor PRs should reduce or hold `main_runtime_core.gd` code LOC and
     function count.
   - The budget check fails on unreviewed growth beyond the baseline allowance.
   - Refresh `.agents/architecture_budget_baseline.json` only after reviewing a
     deliberate architecture step.

## Stop Conditions

- Stop and narrow scope if a focused test reveals gameplay drift.
- Stop and update the codemap if the chosen owner is wrong.
- Stop before deep validation if only docs/skills/tools changed and focused
  infrastructure checks pass.

## Per-Task Template

### Backup reconciliation — 2026-10-04

- Integrated `origin/codex/release-2.0.43` (`31d7d8c`) into
  `refactor-runtime-core-continuation` (`4c04ea0` before integration).
- Preserved Save, Phase, Progression and BossWave owners and the approved
  long-run balance. Restored backup features in those owners, not duplicate core
  implementations. Core is 1,065 physical lines shorter than the backup.
- Refreshed architecture baseline after comparing both parents: the previously
  committed baseline predated even the backup's gameplay additions. Added the
  four extracted owners to the budget coverage.
- Detailed reconciliation/validation evidence: `docs/BACKUP_RECONCILIATION.md`.

```text
Domain:
Owner:
Core symbols touched:
Focused tests:
Budget result:
Gameplay change: no
```
