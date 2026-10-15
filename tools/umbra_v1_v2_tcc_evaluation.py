#!/usr/bin/env python3
"""Freeze and summarize a reproducible, non-promotional UMBRA v1/v2 study."""
from __future__ import annotations

import argparse
import csv
import hashlib
import json
import math
import subprocess
import sys
from collections import Counter
from pathlib import Path
from statistics import fmean
from typing import Any

PROTOCOL_FORMAT = "ruptura_umbra_v1_v2_tcc_protocol"
MANIFEST_FORMAT = "ruptura_umbra_v1_v2_tcc_manifest"
RAW_FORMAT = "ruptura_umbra_v1_v2_tcc_raw"


def read_json(path: Path) -> dict[str, Any]:
    value = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(value, dict):
        raise ValueError(f"{path} must contain a JSON object")
    return value


def write_json(path: Path, value: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(value, indent=2, sort_keys=True) + "\n", encoding="utf-8")


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def sha256_json(value: dict[str, Any]) -> str:
    return hashlib.sha256(json.dumps(value, sort_keys=True, separators=(",", ":")).encode("utf-8")).hexdigest()


def git_commit(root: Path) -> str:
    completed = subprocess.run(["git", "rev-parse", "HEAD"], cwd=root, text=True, capture_output=True, check=False)
    return completed.stdout.strip() if completed.returncode == 0 else "unavailable"


def cases_from_protocol(protocol: dict[str, Any]) -> list[dict[str, Any]]:
    result: list[dict[str, Any]] = []
    seen: set[tuple[str, int]] = set()
    for group in protocol.get("scenario_groups", []):
        group_id = str(group.get("id", ""))
        split = str(group.get("split", ""))
        for scenario_id in group.get("scenario_ids", []):
            for seed in group.get("seeds", []):
                key = (str(scenario_id), int(seed))
                if not group_id or not split or key in seen:
                    raise ValueError("scenario matrix has empty or duplicate cases")
                seen.add(key)
                result.append({
                    "group": group_id,
                    "split": split,
                    "scenario_id": key[0],
                    "seed": key[1],
                    "pattern_change": bool(group.get("pattern_change", False)),
                    "change_at_step": int(group.get("change_at_step", -1)),
                })
    if not result:
        raise ValueError("scenario matrix is empty")
    return result


def validate_model_contract(path: Path, policy_id: str) -> dict[str, Any]:
    """Reject a random JSON or a stale export before it can enter the study."""
    model = read_json(path)
    if policy_id == "v1":
        if model.get("model_version") != "umbra_dqn_2_0_actions_23":
            raise ValueError("v1 model_version is not the canonical 23-action DQN")
        if int(model.get("action_schema_version", -1)) != 2 or int(model.get("feature_schema_version", -1)) != 1:
            raise ValueError("v1 action/feature schema versions are incompatible")
        if int(model.get("input_size", -1)) != 24 or int(model.get("output_size", -1)) != 23:
            raise ValueError("v1 input/output sizes are incompatible")
        if len(model.get("feature_schema", [])) != 24 or len(model.get("action_schema", [])) != 23:
            raise ValueError("v1 feature/action schemas are incomplete")
    elif policy_id == "v2":
        if model.get("format") != "ruptura_umbra_multihead_policy":
            raise ValueError("v2 model is not a multi-head policy export")
        if int(model.get("observation_schema_version", -1)) != 2 or int(model.get("action_schema_version", -1)) != 2:
            raise ValueError("v2 observation/action schema versions are incompatible")
        architecture = model.get("architecture", {})
        if int(architecture.get("input_size", -1)) != 83 or int(architecture.get("action_head_size", -1)) != 23:
            raise ValueError("v2 input/action head sizes are incompatible")
        if len(model.get("feature_schema", [])) != 83 or len(model.get("action_schema", [])) != 23:
            raise ValueError("v2 feature/action schemas are incomplete")
    else:
        raise ValueError("unknown policy id")
    return model


def freeze(protocol_path: Path, v1_model: Path, v2_model: Path, output: Path, root: Path) -> dict[str, Any]:
    protocol = read_json(protocol_path)
    if protocol.get("format") != PROTOCOL_FORMAT or int(protocol.get("protocol_version", 0)) != 1:
        raise ValueError("unsupported TCC protocol")
    if not v1_model.is_file() or not v2_model.is_file():
        raise ValueError("both frozen model files must exist")
    validate_model_contract(v1_model, "v1")
    validate_model_contract(v2_model, "v2")
    manifest = {
        "format": MANIFEST_FORMAT,
        "version": 1,
        "evaluation_id": protocol.get("evaluation_id"),
        "protocol_path": str(protocol_path.resolve()),
        "protocol_sha256": sha256_file(protocol_path),
        "git_commit": git_commit(root),
        "models": {
            "v1": {"path": str(v1_model.resolve()), "sha256": sha256_file(v1_model), "bytes": v1_model.stat().st_size},
            "v2": {"path": str(v2_model.resolve()), "sha256": sha256_file(v2_model), "bytes": v2_model.stat().st_size},
        },
        "controls": protocol.get("controls", {}),
        "platforms": protocol.get("platforms", {}),
        "scenario_cases": cases_from_protocol(protocol),
        "raw_data_contract": protocol.get("raw_data_contract", {}),
        "created_by": "tools/umbra_v1_v2_tcc_evaluation.py",
    }
    manifest["manifest_sha256"] = sha256_json(manifest)
    write_json(output, manifest)
    return manifest


def percentile(values: list[float], fraction: float) -> float | None:
    if not values:
        return None
    ordered = sorted(values)
    index = (len(ordered) - 1) * fraction
    low, high = math.floor(index), math.ceil(index)
    if low == high:
        return ordered[low]
    return ordered[low] + (ordered[high] - ordered[low]) * (index - low)


def mean_or_none(values: list[float]) -> float | None:
    return round(fmean(values), 6) if values else None


def wilson(wins: int, total: int) -> dict[str, float | int] | None:
    if total <= 0:
        return None
    z = 1.959963984540054
    proportion = wins / total
    denominator = 1.0 + z * z / total
    center = (proportion + z * z / (2.0 * total)) / denominator
    radius = z * math.sqrt((proportion * (1.0 - proportion) + z * z / (4.0 * total)) / total) / denominator
    return {"wins": wins, "episodes": total, "rate": round(proportion, 6), "low_95": round(max(0.0, center - radius), 6), "high_95": round(min(1.0, center + radius), 6)}


def action_stats(actions: list[str]) -> dict[str, Any]:
    if not actions:
        return {"count": 0, "unique": 0, "entropy_bits": 0.0, "adjacent_repeat_rate": 0.0, "max_repeat_streak": 0}
    counts = Counter(actions)
    total = len(actions)
    entropy = -sum((count / total) * math.log2(count / total) for count in counts.values())
    repeats = sum(1 for index in range(1, total) if actions[index] == actions[index - 1])
    longest, streak = 1, 1
    for index in range(1, total):
        streak = streak + 1 if actions[index] == actions[index - 1] else 1
        longest = max(longest, streak)
    return {"count": total, "unique": len(counts), "entropy_bits": round(entropy, 6), "adjacent_repeat_rate": round(repeats / max(1, total - 1), 6), "max_repeat_streak": longest, "counts": dict(sorted(counts.items()))}


def distribution_tvd(first: list[str], second: list[str]) -> float | None:
    if not first or not second:
        return None
    left, right = Counter(first), Counter(second)
    keys = set(left) | set(right)
    return round(0.5 * sum(abs(left[key] / len(first) - right[key] / len(second)) for key in keys), 6)


def flatten_numeric(episodes: list[dict[str, Any]], field: str) -> list[float]:
    values: list[float] = []
    for episode in episodes:
        raw = episode.get(field, [])
        raw = raw if isinstance(raw, list) else [raw]
        values.extend(float(value) for value in raw)
    return values


def validate_raw(raw: dict[str, Any], manifest: dict[str, Any], policy_id: str) -> list[dict[str, Any]]:
    if raw.get("format") != RAW_FORMAT or int(raw.get("version", 0)) != 1:
        raise ValueError(f"{policy_id}: unsupported raw data format")
    if raw.get("evaluation_id") != manifest.get("evaluation_id"):
        raise ValueError(f"{policy_id}: evaluation_id differs from manifest")
    if raw.get("manifest_sha256") != manifest.get("manifest_sha256"):
        raise ValueError(f"{policy_id}: raw data was not produced from this frozen manifest")
    if raw.get("policy_id") != policy_id:
        raise ValueError(f"{policy_id}: wrong policy id")
    if raw.get("model_sha256") != manifest["models"][policy_id]["sha256"]:
        raise ValueError(f"{policy_id}: model hash differs from frozen model")
    runtime_validation = raw.get("runtime_validation", {})
    if not bool(runtime_validation.get("model_loaded", False)) or not bool(runtime_validation.get("contract_verified", False)):
        raise ValueError(f"{policy_id}: raw data does not prove that the frozen artifact loaded in the runtime")
    if not str(runtime_validation.get("godot_version", "")).strip():
        raise ValueError(f"{policy_id}: raw data is missing the runtime version")
    episodes = raw.get("episodes", [])
    if not isinstance(episodes, list):
        raise ValueError(f"{policy_id}: episodes must be a list")
    expected = {(item["scenario_id"], int(item["seed"])): item for item in manifest["scenario_cases"]}
    actual: set[tuple[str, int]] = set()
    for episode in episodes:
        key = (str(episode.get("scenario_id", "")), int(episode.get("seed", -1)))
        if key not in expected or key in actual:
            raise ValueError(f"{policy_id}: unexpected, missing, or duplicate episode {key}")
        actual.add(key)
        if str(episode.get("outcome", "")) not in {"umbra_win", "umbra_loss", "timeout"}:
            raise ValueError(f"{policy_id}: invalid outcome for {key}")
        if not isinstance(episode.get("actions"), list) or not episode["actions"]:
            raise ValueError(f"{policy_id}: actions are required for {key}")
        for field in ("duration_seconds", "damage_to_player", "damage_to_umbra", "peak_runtime_bytes"):
            if field not in episode or float(episode[field]) < 0.0:
                raise ValueError(f"{policy_id}: invalid {field} for {key}")
        if expected[key]["pattern_change"]:
            adaptation = episode.get("adaptation")
            if not isinstance(adaptation, dict) or not adaptation.get("pre_actions") or not adaptation.get("post_actions"):
                raise ValueError(f"{policy_id}: adaptation windows are required for {key}")
    if actual != set(expected):
        raise ValueError(f"{policy_id}: expected {len(expected)} paired cases, received {len(actual)}")
    return episodes


def episode_summary(episodes: list[dict[str, Any]]) -> dict[str, Any]:
    actions = [str(action) for episode in episodes for action in episode["actions"]]
    adaptation = [episode["adaptation"] for episode in episodes if isinstance(episode.get("adaptation"), dict)]
    damage_player = [float(episode["damage_to_player"]) for episode in episodes]
    damage_umbra = [float(episode["damage_to_umbra"]) for episode in episodes]
    duration = [float(episode["duration_seconds"]) for episode in episodes]
    decision_usec = flatten_numeric(episodes, "decision_usec")
    frame_usec = flatten_numeric(episodes, "frame_usec")
    peak_memory = [float(episode["peak_runtime_bytes"]) for episode in episodes]
    split_rows: dict[str, list[dict[str, Any]]] = {}
    for episode in episodes:
        split_rows.setdefault(str(episode.get("split", "unknown")), []).append(episode)
    def metric_rows(rows: list[dict[str, Any]]) -> dict[str, Any]:
        return {
            "win_rate_wilson_95": wilson(sum(item["outcome"] == "umbra_win" for item in rows), len(rows)),
            "mean_damage_to_player": mean_or_none([float(item["damage_to_player"]) for item in rows]),
            "mean_damage_to_umbra": mean_or_none([float(item["damage_to_umbra"]) for item in rows]),
            "mean_duration_seconds": mean_or_none([float(item["duration_seconds"]) for item in rows]),
        }
    adaptation_tvd = [distribution_tvd([str(x) for x in item["pre_actions"]], [str(x) for x in item["post_actions"]]) for item in adaptation]
    adaptation_tvd = [value for value in adaptation_tvd if value is not None]
    return {
        "episodes": len(episodes),
        "by_split": {split: metric_rows(rows) for split, rows in sorted(split_rows.items())},
        "damage": {"to_player_mean": mean_or_none(damage_player), "to_umbra_mean": mean_or_none(damage_umbra), "duration_seconds_mean": mean_or_none(duration)},
        "actions": action_stats(actions),
        "adaptation": {"episodes": len(adaptation), "action_tvd_pre_to_post_mean": mean_or_none(adaptation_tvd)},
        "performance": {
            "decision_usec_mean": mean_or_none(decision_usec), "decision_usec_p95": None if not decision_usec else round(percentile(decision_usec, 0.95), 6),
            "frame_usec_mean": mean_or_none(frame_usec), "frame_usec_p95": None if not frame_usec else round(percentile(frame_usec, 0.95), 6),
            "peak_runtime_bytes_max": int(max(peak_memory)),
        },
        "stability": {
            "invalid_action_count": sum(int(item.get("invalid_action_count", 0)) for item in episodes),
            "executor_reject_count": sum(int(item.get("executor_reject_count", 0)) for item in episodes),
            "crash_count": sum(bool(item.get("crash", False)) for item in episodes),
            "determinism_mismatch_count": sum(int(item.get("determinism_mismatch_count", 0)) for item in episodes),
        },
    }


def human_summary(path: Path | None) -> dict[str, Any]:
    if path is None:
        return {"status": "not_collected", "note": "No human-perception conclusion is available."}
    with path.open(encoding="utf-8", newline="") as stream:
        rows = list(csv.DictReader(stream))
    by_code: dict[str, list[dict[str, str]]] = {}
    for row in rows:
        by_code.setdefault(row.get("blind_code", "unknown"), []).append(row)
    result: dict[str, Any] = {"status": "collected", "source_sha256": sha256_file(path), "responses": len(rows), "by_blind_code": {}}
    for code, answers in sorted(by_code.items()):
        result["by_blind_code"][code] = {metric: mean_or_none([float(row[metric]) for row in answers if row.get(metric, "")]) for metric in ("intelligence", "fairness", "fun")}
    return result


def summarize(manifest_path: Path, v1_raw_path: Path, v2_raw_path: Path, output: Path, human_csv: Path | None) -> dict[str, Any]:
    manifest = read_json(manifest_path)
    if manifest.get("format") != MANIFEST_FORMAT or manifest.get("manifest_sha256") != sha256_json({key: value for key, value in manifest.items() if key != "manifest_sha256"}):
        raise ValueError("manifest is invalid or was edited after freezing")
    v1 = validate_raw(read_json(v1_raw_path), manifest, "v1")
    v2 = validate_raw(read_json(v2_raw_path), manifest, "v2")
    report = {
        "format": "ruptura_umbra_v1_v2_tcc_report",
        "version": 1,
        "evaluation_id": manifest["evaluation_id"],
        "manifest_sha256": manifest["manifest_sha256"],
        "raw_data": {"v1": {"path": str(v1_raw_path.resolve()), "sha256": sha256_file(v1_raw_path)}, "v2": {"path": str(v2_raw_path.resolve()), "sha256": sha256_file(v2_raw_path)}},
        "models": manifest["models"],
        "results": {"v1": episode_summary(v1), "v2": episode_summary(v2)},
        "human_perception": human_summary(human_csv),
        "conclusion_rule": "No automatic winner. Interpret each metric with its interval, controls, data quality and human-study limitation; a negative or mixed conclusion is valid.",
    }
    write_json(output, report)
    return report


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest="command", required=True)
    freeze_parser = commands.add_parser("freeze", help="lock two model artifacts and the seed matrix")
    freeze_parser.add_argument("--protocol", type=Path, required=True)
    freeze_parser.add_argument("--v1-model", type=Path, required=True)
    freeze_parser.add_argument("--v2-model", type=Path, required=True)
    freeze_parser.add_argument("--out", type=Path, required=True)
    freeze_parser.add_argument("--root", type=Path, default=Path(__file__).resolve().parents[1])
    report_parser = commands.add_parser("summarize", help="validate immutable raw data and create a metric report")
    report_parser.add_argument("--manifest", type=Path, required=True)
    report_parser.add_argument("--v1-raw", type=Path, required=True)
    report_parser.add_argument("--v2-raw", type=Path, required=True)
    report_parser.add_argument("--out", type=Path, required=True)
    report_parser.add_argument("--human-csv", type=Path)
    args = parser.parse_args()
    try:
        result = freeze(args.protocol, args.v1_model, args.v2_model, args.out, args.root) if args.command == "freeze" else summarize(args.manifest, args.v1_raw, args.v2_raw, args.out, args.human_csv)
        print(json.dumps({"ok": True, "command": args.command, "evaluation_id": result["evaluation_id"], "output": str(args.out.resolve())}))
        return 0
    except (OSError, ValueError, json.JSONDecodeError) as error:
        print("UMBRA_V1_V2_TCC_EVALUATION_FAIL: " + str(error), file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
