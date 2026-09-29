#!/usr/bin/env python3
"""Check Ruptura runtime architecture budgets with a baseline/ratchet model.

The check is intentionally lightweight for Codex work: it streams files line by
line, records current LOC/symbol metrics, and only fails when a metric grows
past the committed baseline plus the configured allowance.
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
BASELINE_PATH = ROOT / ".agents" / "architecture_budget_baseline.json"

DEFAULT_TARGETS = [
    "scripts/main_runtime_core.gd",
    "scripts/main_runtime_state.gd",
    "scripts/ui/shop_controller.gd",
    "scripts/ui/shop_presentation.gd",
    "scripts/systems/telemetry/telemetry_system.gd",
    "scripts/systems/online/net_contract.gd",
    "scripts/systems/audio/audio_lifecycle.gd",
    "scripts/systems/enemy_manager.gd",
    "scripts/systems/modern_boss_controller.gd",
    "scripts/presentation/combat_effects_presentation.gd",
    "scripts/presentation/menus_presentation.gd",
    "scripts/presentation/world_environment_presentation.gd",
]

DEFAULT_BUDGETS = {
    "physical_loc": 25,
    "code_loc": 15,
    "functions": 1,
    "classes": 0,
    "signals": 0,
    "max_function_code_loc": 8,
}

FUNCTION_RE = re.compile(r"^\s*(?:static\s+)?func\s+([A-Za-z_][A-Za-z0-9_]*)\s*\(")
CLASS_RE = re.compile(r"^\s*class_name\s+([A-Za-z_][A-Za-z0-9_]*)\b")
SIGNAL_RE = re.compile(r"^\s*signal\s+([A-Za-z_][A-Za-z0-9_]*)\b")
COMMENT_RE = re.compile(r"^\s*#")


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


def count_file(path: Path) -> dict[str, Any]:
    metrics: dict[str, Any] = {
        "physical_loc": 0,
        "code_loc": 0,
        "functions": 0,
        "classes": 0,
        "signals": 0,
        "max_function_code_loc": 0,
        "largest_function": "",
    }
    current_function = ""
    current_function_indent = -1
    current_function_code_loc = 0

    for line in iter_text_lines(path):
        metrics["physical_loc"] += 1
        stripped = line.strip()
        is_code = bool(stripped) and not COMMENT_RE.match(line)
        indent = len(line) - len(line.lstrip(" \t"))

        match = FUNCTION_RE.match(line)
        if match:
            if current_function_code_loc > metrics["max_function_code_loc"]:
                metrics["max_function_code_loc"] = current_function_code_loc
                metrics["largest_function"] = current_function
            metrics["functions"] += 1
            current_function = match.group(1)
            current_function_indent = indent
            current_function_code_loc = 1 if is_code else 0
        elif current_function and is_code:
            if stripped and indent > current_function_indent:
                current_function_code_loc += 1
            elif stripped and indent <= current_function_indent:
                if current_function_code_loc > metrics["max_function_code_loc"]:
                    metrics["max_function_code_loc"] = current_function_code_loc
                    metrics["largest_function"] = current_function
                current_function = ""
                current_function_indent = -1
                current_function_code_loc = 0

        if CLASS_RE.match(line):
            metrics["classes"] += 1
        if SIGNAL_RE.match(line):
            metrics["signals"] += 1
        if is_code:
            metrics["code_loc"] += 1

    if current_function_code_loc > metrics["max_function_code_loc"]:
        metrics["max_function_code_loc"] = current_function_code_loc
        metrics["largest_function"] = current_function
    return metrics


def collect_metrics(paths: list[str]) -> dict[str, Any]:
    files: dict[str, Any] = {}
    totals = {
        "physical_loc": 0,
        "code_loc": 0,
        "functions": 0,
        "classes": 0,
        "signals": 0,
    }
    for rel_path in paths:
        path = project_path(rel_path)
        if not path.exists():
            raise FileNotFoundError(rel_path)
        file_metrics = count_file(path)
        files[rel_path] = file_metrics
        for key in totals:
            totals[key] += int(file_metrics[key])
    return {
        "schema": 1,
        "description": "Architecture budget baseline for runtime refactor work. Counts are streamed and exclude blank/comment-only lines from code_loc.",
        "targets": paths,
        "ratchet_allowance": DEFAULT_BUDGETS,
        "totals": totals,
        "files": files,
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


def compare(current: dict[str, Any], baseline: dict[str, Any]) -> list[str]:
    failures: list[str] = []
    allowance = baseline.get("ratchet_allowance", DEFAULT_BUDGETS)
    baseline_files = baseline.get("files", {})

    for rel_path, metrics in current["files"].items():
        base = baseline_files.get(rel_path)
        if base is None:
            failures.append(f"{rel_path}: missing from baseline")
            continue
        for metric_name, extra in allowance.items():
            current_value = int(metrics.get(metric_name, 0))
            baseline_value = int(base.get(metric_name, 0))
            if current_value > baseline_value + int(extra):
                failures.append(
                    f"{rel_path}: {metric_name}={current_value} exceeds baseline "
                    f"{baseline_value}+{extra}"
                )
    return failures


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--baseline",
        default=str(BASELINE_PATH.relative_to(ROOT)),
        help="Baseline JSON path relative to repository root.",
    )
    parser.add_argument(
        "--write-baseline",
        action="store_true",
        help="Write the current metrics as the baseline.",
    )
    parser.add_argument(
        "--json",
        action="store_true",
        help="Print current metrics JSON.",
    )
    parser.add_argument(
        "paths",
        nargs="*",
        help="Optional repository-relative .gd files to check.",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    paths = args.paths or DEFAULT_TARGETS
    current = collect_metrics(paths)
    baseline_path = project_path(args.baseline)

    if args.write_baseline:
        write_json(baseline_path, current)
        print(f"ARCHITECTURE_BUDGET_BASELINE_WRITTEN {baseline_path.relative_to(ROOT)}")
        return 0

    baseline = load_baseline(baseline_path)
    if baseline is None:
        print(f"ARCHITECTURE_BUDGET_NO_BASELINE {baseline_path.relative_to(ROOT)}")
        print("Run with --write-baseline after reviewing current metrics.")
        return 2

    failures = compare(current, baseline)
    if args.json:
        print(json.dumps(current, indent=2, sort_keys=True))
    if failures:
        print("ARCHITECTURE_BUDGET_FAIL")
        for failure in failures:
            print(f"- {failure}")
        return 1

    print("ARCHITECTURE_BUDGET_OK")
    print(
        "targets={targets} code_loc={code_loc} functions={functions}".format(
            targets=len(current["files"]),
            code_loc=current["totals"]["code_loc"],
            functions=current["totals"]["functions"],
        )
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
