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
     deliberate architecture step, with
     `--write-baseline --reason "..."` (reason, HEAD and date are stored under
     `review`; `exceptions` and `allowance_overrides` are preserved).

### Ratchet contract (P1.01, baseline 73d2ada)

- Tracked: explicit targets in `tools/check_architecture_budget.py` plus every
  `scripts/**/*.gd` with code_loc >= 500. A file crossing 500 without a
  baseline entry fails as an uncovered hotspot. File count is not a metric.
- Per-file allowance: physical +25, code +15, functions +1, classes/signals +0,
  largest function +8, long functions (>= 120 code LOC) +0. Each file's top 5
  functions are ratcheted by name (+8). Per-file overrides go in
  `allowance_overrides` with a justification in `exceptions`.
- Shrink >= 150 code_loc below baseline prints `ARCHITECTURE_BUDGET_SLACK`
  (no failure): tighten the baseline in the same reviewed change so the slack
  cannot be spent later.
- Extraction vs deletion: `--compare-ref <ref>` classifies core functions
  removed since `ref` as extracted (same name, +/- leading `_`, now in another
  script) or deleted. A core shrink only counts as refactor progress when it is
  extraction; deletion of content is reported separately.
- Isolated tests (fixture root, intentional growth failures):
  `python3 tools/tests/test_check_architecture_budget.py`.

### P1.01 measurement — 2026-11-19 (HEAD 73d2ada)

- Old baseline (a0388d2) failed 17 checks on 6 owners (growth merged by
  feature commits) while leaving core 3,363 code_loc of slack.
- `--compare-ref a0388d2`: 324 core functions removed (4,342 fn LOC), 0
  extracted, all deleted (content cut in 6f20d6a). Core reduction since the old
  baseline is deletion, not refactor. Since 1c38031 core grew +181 code_loc.
- New baseline at HEAD: core 46,886 physical / 39,820 code / 3,325 functions /
  21 long functions; 48 tracked files, 79,853 code_loc; scripts/ 114,668
  code_loc, 45 functions >= 120 code LOC. Top functions: `_handle_key` 501,
  `_start_game` 381, `_spawn_enemy` 362 (core), `_draw_boss_attacks` 350.
- Accepted growth list: `exceptions.accepted_growth_a0388d2_to_73d2ada`.

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
