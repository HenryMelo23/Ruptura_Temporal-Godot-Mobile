#!/usr/bin/env python3
"""Check Ruptura runtime architecture budgets with a baseline/ratchet model.

The check is intentionally lightweight for agent work: it streams files line by
line, records LOC/function metrics, and fails only when a metric grows past the
committed baseline plus the reviewed allowance.

Gates (exit 1 on any failure):
  * every tracked file (explicit targets + every script over the hotspot
    threshold at baseline time) may not grow past baseline + allowance on
    physical_loc, code_loc, functions, classes, signals, max_function_code_loc
    and long_functions;
  * each of the top functions recorded per file may not grow past
    baseline + max_function_code_loc allowance (catches growth of the 2nd..5th
    largest function, not only the largest);
  * a script under scripts/ that crosses the hotspot threshold without being in
    the baseline fails as an uncovered hotspot.

Shrinking far below the baseline only warns (SLACK) so the ratchet can be
tightened after review. Quantity of files is never a metric.

Usage:
  python3 tools/check_architecture_budget.py            # gate
  python3 tools/check_architecture_budget.py --report   # gate + hotspot report
  python3 tools/check_architecture_budget.py --json     # machine-readable
  python3 tools/check_architecture_budget.py --write-baseline --reason "..."
"""

from __future__ import annotations

import argparse
import datetime as _dt
import json
import re
import subprocess
import sys
from pathlib import Path
from typing import Any


TOOL_ROOT = Path(__file__).resolve().parents[1]
BASELINE_REL = ".agents/architecture_budget_baseline.json"
SCAN_DIR = "scripts"
SCHEMA = 2

# Explicit targets are always tracked, whatever their size. Files under
# SCAN_DIR whose code_loc reaches HOTSPOT_CODE_LOC are tracked automatically.
DEFAULT_TARGETS = [
    "scripts/main_runtime_core.gd",
    "scripts/main_runtime_state.gd",
    "scripts/ui/shop_controller.gd",
    "scripts/ui/shop_presentation.gd",
    "scripts/systems/telemetry/telemetry_system.gd",
    "scripts/systems/online/net_contract.gd",
    "scripts/systems/audio/audio_lifecycle.gd",
    "scripts/systems/enemy_manager.gd",
    "scripts/systems/combat/runtime_targeting_controller.gd",
    "scripts/systems/enemies/regular_enemy_balance.gd",
    "scripts/systems/modern_boss_controller.gd",
    "scripts/presentation/combat_effects_presentation.gd",
    "scripts/presentation/menus_presentation.gd",
    "scripts/presentation/world_environment_presentation.gd",
    "scripts/systems/save/runtime_save_controller.gd",
    "scripts/systems/phase/phase_flow_controller.gd",
    "scripts/systems/progression/runtime_progression_controller.gd",
    "scripts/presentation/boss_wave_presentation.gd",
    # Owners added by the 2026-11-18/19 batch (Merchant, Ruptura, dialogue).
    "scripts/systems/shop/merchant_mission_controller.gd",
    "scripts/systems/shop/merchant_workshop_physics.gd",
    "scripts/systems/phase/dimension_rupture_controller.gd",
    "scripts/presentation/dialogue_box_presentation.gd",
]

HOTSPOT_CODE_LOC = 500
LONG_FUNCTION_CODE_LOC = 120
TOP_FUNCTIONS_PER_FILE = 5

DEFAULT_BUDGETS = {
    "physical_loc": 25,
    "code_loc": 15,
    "functions": 1,
    "classes": 0,
    "signals": 0,
    "max_function_code_loc": 8,
    "long_functions": 0,
}

# Shrink beyond this many code_loc below baseline is reported as SLACK.
SLACK_CODE_LOC = 150

FUNCTION_RE = re.compile(r"^\s*(?:static\s+)?func\s+([A-Za-z_][A-Za-z0-9_]*)\s*\(")
CLASS_RE = re.compile(r"^\s*class_name\s+([A-Za-z_][A-Za-z0-9_]*)\b")
SIGNAL_RE = re.compile(r"^\s*signal\s+([A-Za-z_][A-Za-z0-9_]*)\b")
COMMENT_RE = re.compile(r"^\s*#")

ROOT = TOOL_ROOT


def project_path(path: str) -> Path:
    candidate = (ROOT / path).resolve()
    try:
        candidate.relative_to(ROOT)
    except ValueError as exc:
        raise ValueError(f"path outside repository: {path}") from exc
    return candidate


def iter_text_lines(path: Path):
    with path.open("r", encoding="utf-8", errors="replace") as handle:
        for line in handle:
            yield line.rstrip("\n")


def count_file(path: Path, with_function_sizes: bool = False) -> dict[str, Any]:
    metrics: dict[str, Any] = {
        "physical_loc": 0,
        "code_loc": 0,
        "functions": 0,
        "classes": 0,
        "signals": 0,
        "max_function_code_loc": 0,
        "largest_function": "",
        "long_functions": 0,
    }
    sizes: dict[str, int] = {}
    current_function = ""
    current_function_indent = -1
    current_function_code_loc = 0

    def close_function() -> None:
        if not current_function:
            return
        if current_function_code_loc > metrics["max_function_code_loc"]:
            metrics["max_function_code_loc"] = current_function_code_loc
            metrics["largest_function"] = current_function
        if current_function_code_loc >= LONG_FUNCTION_CODE_LOC:
            metrics["long_functions"] += 1
        sizes[current_function] = max(sizes.get(current_function, 0), current_function_code_loc)

    for line in iter_text_lines(path):
        metrics["physical_loc"] += 1
        stripped = line.strip()
        is_code = bool(stripped) and not COMMENT_RE.match(line)
        indent = len(line) - len(line.lstrip(" \t"))

        match = FUNCTION_RE.match(line)
        if match:
            close_function()
            metrics["functions"] += 1
            current_function = match.group(1)
            current_function_indent = indent
            current_function_code_loc = 1 if is_code else 0
        elif current_function and is_code:
            if indent > current_function_indent:
                current_function_code_loc += 1
            else:
                close_function()
                current_function = ""
                current_function_indent = -1
                current_function_code_loc = 0

        if CLASS_RE.match(line):
            metrics["classes"] += 1
        if SIGNAL_RE.match(line):
            metrics["signals"] += 1
        if is_code:
            metrics["code_loc"] += 1

    close_function()
    if with_function_sizes:
        metrics["_function_sizes"] = sizes
    return metrics


def scan_scripts() -> dict[str, dict[str, Any]]:
    scan_root = ROOT / SCAN_DIR
    result: dict[str, dict[str, Any]] = {}
    if not scan_root.exists():
        return result
    for path in sorted(scan_root.rglob("*.gd")):
        rel = path.relative_to(ROOT).as_posix()
        result[rel] = count_file(path, with_function_sizes=True)
    return result


def top_functions(sizes: dict[str, int], limit: int = TOP_FUNCTIONS_PER_FILE) -> dict[str, int]:
    ranked = sorted(sizes.items(), key=lambda item: (-item[1], item[0]))[:limit]
    return {name: loc for name, loc in ranked}


def collect_metrics(explicit_paths: list[str] | None = None, baseline: dict[str, Any] | None = None) -> dict[str, Any]:
    scanned = scan_scripts()
    targets = list(explicit_paths or DEFAULT_TARGETS)
    for rel in targets:
        if rel not in scanned:
            path = project_path(rel)
            if not path.exists():
                raise FileNotFoundError(rel)
            scanned[rel] = count_file(path, with_function_sizes=True)

    tracked = set(targets)
    if not explicit_paths:
        tracked.update(rel for rel, m in scanned.items() if m["code_loc"] >= HOTSPOT_CODE_LOC)
        if baseline:
            tracked.update(rel for rel in baseline.get("files", {}) if rel in scanned)

    files: dict[str, Any] = {}
    for rel in sorted(tracked):
        metrics = dict(scanned[rel])
        metrics["top_functions"] = top_functions(metrics.pop("_function_sizes"))
        files[rel] = metrics

    totals = {key: 0 for key in ("physical_loc", "code_loc", "functions", "classes", "signals", "long_functions")}
    for metrics in files.values():
        for key in totals:
            totals[key] += int(metrics[key])

    project = {key: 0 for key in ("physical_loc", "code_loc", "functions", "long_functions")}
    all_functions: list[tuple[int, str, str]] = []
    for rel, metrics in scanned.items():
        for key in project:
            project[key] += int(metrics[key])
        for name, loc in metrics.get("_function_sizes", {}).items():
            all_functions.append((loc, rel, name))
    all_functions.sort(key=lambda item: (-item[0], item[1], item[2]))

    return {
        "schema": SCHEMA,
        "targets": targets,
        "hotspot_code_loc": HOTSPOT_CODE_LOC,
        "long_function_code_loc": LONG_FUNCTION_CODE_LOC,
        "ratchet_allowance": dict(DEFAULT_BUDGETS),
        "totals": totals,
        "project_totals": project,
        "files": files,
        "hotspot_functions": [
            {"file": rel, "function": name, "code_loc": loc} for loc, rel, name in all_functions[:10]
        ],
    }


def load_baseline(path: Path) -> dict[str, Any] | None:
    if not path.exists():
        return None
    with path.open("r", encoding="utf-8") as handle:
        return json.load(handle)


def write_json(path: Path, payload: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8") as handle:
        json.dump(payload, handle, indent=2, sort_keys=True)
        handle.write("\n")


def file_allowance(baseline: dict[str, Any], rel_path: str) -> dict[str, int]:
    allowance = dict(baseline.get("ratchet_allowance", DEFAULT_BUDGETS))
    override = baseline.get("allowance_overrides", {}).get(rel_path, {})
    allowance.update({k: v for k, v in override.items() if k in DEFAULT_BUDGETS})
    return allowance


def compare(current: dict[str, Any], baseline: dict[str, Any]) -> tuple[list[str], list[str]]:
    failures: list[str] = []
    warnings: list[str] = []
    baseline_files = baseline.get("files", {})
    hotspot = int(baseline.get("hotspot_code_loc", HOTSPOT_CODE_LOC))

    for rel_path, metrics in current["files"].items():
        base = baseline_files.get(rel_path)
        if base is None:
            if rel_path in current["targets"]:
                failures.append(f"{rel_path}: tracked target missing from baseline")
            elif int(metrics["code_loc"]) >= hotspot:
                failures.append(
                    f"{rel_path}: uncovered hotspot code_loc={metrics['code_loc']} >= {hotspot}; "
                    "split it or review and refresh the baseline"
                )
            continue
        allowance = file_allowance(baseline, rel_path)
        for metric_name, extra in allowance.items():
            if metric_name not in base:
                continue
            current_value = int(metrics.get(metric_name, 0))
            baseline_value = int(base[metric_name])
            if current_value > baseline_value + int(extra):
                failures.append(
                    f"{rel_path}: {metric_name}={current_value} exceeds baseline "
                    f"{baseline_value}+{extra}"
                )
        fn_extra = int(allowance.get("max_function_code_loc", 0))
        for name, base_loc in base.get("top_functions", {}).items():
            current_loc = int(metrics.get("top_functions", {}).get(name, 0))
            if current_loc == 0:
                continue  # renamed, removed or no longer in this file's top list
            if current_loc > int(base_loc) + fn_extra:
                failures.append(
                    f"{rel_path}: function {name} code_loc={current_loc} exceeds baseline "
                    f"{base_loc}+{fn_extra}"
                )
        slack = int(base.get("code_loc", 0)) - int(metrics["code_loc"])
        if slack >= SLACK_CODE_LOC:
            warnings.append(
                f"{rel_path}: code_loc={metrics['code_loc']} is {slack} below baseline "
                f"{base['code_loc']}; tighten the baseline after review"
            )
    for rel_path in baseline_files:
        if rel_path not in current["files"] and rel_path in baseline.get("targets", []):
            warnings.append(f"{rel_path}: in baseline but no longer tracked (deleted or moved?)")
    return failures, warnings


def _delta(current: int, base: int | None) -> str:
    if base is None:
        return "new"
    diff = current - base
    return f"{diff:+d}"


def extraction_summary(current: dict[str, Any], baseline: dict[str, Any]) -> list[str]:
    """Separate core shrink by extraction from shrink by deletion/compaction."""
    core = "scripts/main_runtime_core.gd"
    lines: list[str] = []
    base_files = baseline.get("files", {})
    cur_core = current["files"].get(core)
    base_core = base_files.get(core)
    base_project = baseline.get("project_totals")
    if not cur_core or not base_core:
        return lines
    core_code = int(cur_core["code_loc"]) - int(base_core["code_loc"])
    core_phys = int(cur_core["physical_loc"]) - int(base_core["physical_loc"])
    lines.append(f"core delta: code_loc {core_code:+d}, physical_loc {core_phys:+d}, functions "
                 f"{int(cur_core['functions']) - int(base_core['functions']):+d}")
    if base_project:
        project_code = int(current["project_totals"]["code_loc"]) - int(base_project["code_loc"])
        outside = project_code - core_code
        lines.append(f"scripts/ delta: code_loc {project_code:+d} (outside core {outside:+d})")
        if core_code < 0:
            moved = min(-core_code, max(outside, 0))
            removed = -core_code - moved
            lines.append(
                f"core shrink {-core_code}: at least {removed} by deletion/compaction; at most {moved} "
                "could be extraction (upper bound only; run --compare-ref <baseline head> to classify)"
            )
    if core_phys < 0 and core_code > core_phys / 2:
        lines.append("note: physical shrink much larger than code shrink -> mostly comments/blank lines removed")
    return lines


def print_report(current: dict[str, Any], baseline: dict[str, Any] | None) -> None:
    base_files = (baseline or {}).get("files", {})
    print("ARCHITECTURE_BUDGET_REPORT")
    print(f"{'file':64} {'phys':>6} {'code':>6} {'Δcode':>6} {'fn':>5} {'maxfn':>5} {'long':>4}  largest")
    rows = sorted(current["files"].items(), key=lambda item: -int(item[1]["code_loc"]))
    for rel, m in rows:
        base = base_files.get(rel)
        print(
            f"{rel:64} {m['physical_loc']:6d} {m['code_loc']:6d} "
            f"{_delta(int(m['code_loc']), None if base is None else int(base['code_loc'])):>6} "
            f"{m['functions']:5d} {m['max_function_code_loc']:5d} {m['long_functions']:4d}  {m['largest_function']}"
        )
    t = current["totals"]
    p = current["project_totals"]
    print(f"tracked totals: files={len(current['files'])} physical={t['physical_loc']} code={t['code_loc']} "
          f"functions={t['functions']} long_functions={t['long_functions']}")
    print(f"scripts/ totals: physical={p['physical_loc']} code={p['code_loc']} functions={p['functions']} "
          f"long_functions(>={LONG_FUNCTION_CODE_LOC})={p['long_functions']}")
    print("top 10 functions by code_loc:")
    for item in current["hotspot_functions"]:
        print(f"  {item['code_loc']:5d}  {item['file']}::{item['function']}")
    if baseline:
        for line in extraction_summary(current, baseline):
            print(line)


def count_text(text: str) -> dict[str, int]:
    """Function sizes for an in-memory file (used for git refs)."""
    import tempfile

    with tempfile.NamedTemporaryFile("w", suffix=".gd", delete=False, encoding="utf-8") as handle:
        handle.write(text)
        tmp = Path(handle.name)
    try:
        return count_file(tmp, with_function_sizes=True)
    finally:
        tmp.unlink(missing_ok=True)


def compare_ref_report(ref: str, rel_path: str = "scripts/main_runtime_core.gd") -> int:
    """Classify a file's shrink since `ref`: extraction (function now lives in
    another script) vs deletion (function gone from scripts/) vs in-place."""
    try:
        old_text = subprocess.run(
            ["git", "show", f"{ref}:{rel_path}"], cwd=ROOT, capture_output=True, text=True, check=True
        ).stdout
    except (OSError, subprocess.CalledProcessError) as exc:
        print(f"ARCHITECTURE_BUDGET_REF_ERROR {ref}:{rel_path}: {exc}")
        return 2
    old = count_text(old_text)
    new = count_file(project_path(rel_path), with_function_sizes=True)
    old_sizes, new_sizes = old["_function_sizes"], new["_function_sizes"]
    elsewhere: dict[str, str] = {}
    for other_rel, metrics in scan_scripts().items():
        if other_rel == rel_path:
            continue
        for name in metrics["_function_sizes"]:
            elsewhere.setdefault(name.lstrip("_"), other_rel)
    removed = {n: s for n, s in old_sizes.items() if n not in new_sizes}
    moved = {n: s for n, s in removed.items() if n.lstrip("_") in elsewhere}
    deleted = {n: s for n, s in removed.items() if n not in moved}
    shrunk = sum(old_sizes[n] - new_sizes[n] for n in old_sizes if n in new_sizes and new_sizes[n] < old_sizes[n])
    grown = sum(new_sizes[n] - old_sizes.get(n, 0) for n in new_sizes if new_sizes[n] > old_sizes.get(n, 0))
    print(f"ARCHITECTURE_BUDGET_COMPARE_REF {ref} {rel_path}")
    print(f"code_loc {old['code_loc']} -> {new['code_loc']} ({new['code_loc'] - old['code_loc']:+d}); "
          f"functions {old['functions']} -> {new['functions']}")
    print(f"removed functions: {len(removed)} ({sum(removed.values())} fn code_loc)")
    print(f"  extracted (same name, +/- leading _, now in another script): {len(moved)} ({sum(moved.values())})")
    print(f"  deleted (name absent from scripts/): {len(deleted)} ({sum(deleted.values())})")
    print(f"shrunk in place: {shrunk}; grown/added in place: {grown} "
          f"({len([n for n in new_sizes if n not in old_sizes])} new functions)")
    for name, size in sorted(moved.items(), key=lambda item: -item[1])[:10]:
        print(f"  moved {size:4d} {name} -> {elsewhere[name.lstrip('_')]}")
    for name, size in sorted(deleted.items(), key=lambda item: -item[1])[:5]:
        print(f"  deleted {size:4d} {name}")
    return 0


def git_head() -> str:
    try:
        return subprocess.run(
            ["git", "rev-parse", "--short", "HEAD"], cwd=ROOT, capture_output=True, text=True, check=True
        ).stdout.strip()
    except (OSError, subprocess.CalledProcessError):
        return "unknown"


def parse_args(argv: list[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--baseline", default=BASELINE_REL, help="Baseline JSON path relative to --root.")
    parser.add_argument("--root", default=str(TOOL_ROOT), help="Repository root (tests use a fixture root).")
    parser.add_argument("--write-baseline", action="store_true", help="Write current metrics as the baseline.")
    parser.add_argument("--reason", default="", help="Required with --write-baseline: why the baseline moves.")
    parser.add_argument("--json", action="store_true", help="Print metrics, failures and warnings as JSON only.")
    parser.add_argument("--report", action="store_true", help="Print per-file table, top functions and deltas.")
    parser.add_argument("--compare-ref", default="", help="Git ref: classify core shrink as extraction vs deletion.")
    parser.add_argument("paths", nargs="*", help="Optional repository-relative .gd files (disables auto hotspots).")
    return parser.parse_args(argv)


def main(argv: list[str] | None = None) -> int:
    global ROOT
    args = parse_args(argv)
    ROOT = Path(args.root).resolve()
    if args.compare_ref:
        return compare_ref_report(args.compare_ref)
    baseline_path = project_path(args.baseline)
    baseline = load_baseline(baseline_path)

    if args.write_baseline:
        if not args.reason.strip():
            print("ARCHITECTURE_BUDGET_REASON_REQUIRED: pass --reason describing the reviewed change")
            return 2
        current = collect_metrics(args.paths or None, None)
        current["description"] = (
            "Architecture budget baseline. code_loc excludes blank/comment-only lines. "
            "Refresh only after review: python3 tools/check_architecture_budget.py --write-baseline --reason ..."
        )
        current["review"] = {
            "head": git_head(),
            "date": _dt.date.today().isoformat(),
            "reason": args.reason.strip(),
        }
        if baseline:
            for key in ("allowance_overrides", "exceptions"):
                if key in baseline:
                    current[key] = baseline[key]
        write_json(baseline_path, current)
        print(f"ARCHITECTURE_BUDGET_BASELINE_WRITTEN {baseline_path.relative_to(ROOT)}")
        return 0

    if baseline is None:
        print(f"ARCHITECTURE_BUDGET_NO_BASELINE {baseline_path.relative_to(ROOT)}")
        print("Run with --write-baseline --reason ... after reviewing current metrics.")
        return 2

    current = collect_metrics(args.paths or None, baseline)
    failures, warnings = compare(current, baseline)

    if args.json:
        payload = dict(current)
        payload["status"] = "FAIL" if failures else "OK"
        payload["failures"] = failures
        payload["warnings"] = warnings
        payload["baseline_review"] = baseline.get("review", {})
        print(json.dumps(payload, indent=2, sort_keys=True))
        return 1 if failures else 0

    if args.report:
        print_report(current, baseline)
    for warning in warnings:
        print(f"ARCHITECTURE_BUDGET_SLACK {warning}")
    if failures:
        print("ARCHITECTURE_BUDGET_FAIL")
        for failure in failures:
            print(f"- {failure}")
        return 1

    print("ARCHITECTURE_BUDGET_OK")
    print(
        "tracked={tracked} code_loc={code_loc} functions={functions} long_functions={long} baseline={head}".format(
            tracked=len(current["files"]),
            code_loc=current["totals"]["code_loc"],
            functions=current["totals"]["functions"],
            long=current["totals"]["long_functions"],
            head=baseline.get("review", {}).get("head", "unreviewed"),
        )
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
