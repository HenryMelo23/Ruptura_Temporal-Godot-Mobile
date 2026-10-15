#!/usr/bin/env python3
"""Validates UMBRA curriculum isolation, reward caps, and anti-exploit signals."""
from __future__ import annotations

import argparse
import json
import subprocess
import tempfile
from pathlib import Path

from umbra_rl_curriculum import generalization_report, load_curriculum, rollout_requests, scenario_ids


def rollout(root: Path, godot: str, request: dict) -> dict:
    with tempfile.TemporaryDirectory(prefix="umbra-curriculum-smoke-") as tmp:
        folder = Path(tmp)
        request_path, response_path = folder / "request.json", folder / "response.json"
        request_path.write_text(json.dumps(request), encoding="utf-8")
        completed = subprocess.run([godot, "--headless", "--path", str(root), "--script", "res://tools/umbra_rl_rollout.gd", "--", "--request", str(request_path), "--response", str(response_path)], capture_output=True, text=True, timeout=90)
        if completed.returncode != 0:
            raise RuntimeError("Godot rollout failed: " + completed.stderr[-1000:])
        return json.loads(response_path.read_text(encoding="utf-8"))


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--godot", default="godot")
    parser.add_argument("--root", default=str(Path(__file__).resolve().parents[1]))
    args = parser.parse_args()
    root = Path(args.root)
    config = load_curriculum(root / "tools" / "config" / "umbra_rl_curriculum_v1.json")
    train_ids = {str(row["id"]) for row in config["scenarios"] if row.get("split") == "train"}
    held_out_ids = set(scenario_ids(config, "held_out", 0))
    assert train_ids and held_out_ids and not (train_ids & held_out_ids)
    assert scenario_ids(config, "train", 0) != scenario_ids(config, "train", 60), "curriculum never advances"
    train_request = rollout_requests(config, "train", 0, 1, 919, 8, 0.12)[0]
    held_request = rollout_requests(config, "held_out", 0, 1, 919, 8, 0.12)[0]
    train_request.update({"policy_mode": "fixed_action", "fixed_action": "ATAQUE", "max_steps": 12})
    train = rollout(root, args.godot, train_request)
    held_out = rollout(root, args.godot, held_request)
    assert train["summary"]["scenario_id"] in train_ids and train["summary"]["scenario_split"] == "train"
    assert held_out["summary"]["scenario_id"] in held_out_ids and held_out["summary"]["scenario_split"] == "held_out"
    shaping_cap = float(config["reward"]["shaping"]["episode_max"])
    for result in [train, held_out]:
        assert abs(float(result["summary"]["reward_shaping_total"])) <= shaping_cap + 1e-6
        for transition in result["transitions"]:
            reward = transition["info"]["reward"]
            assert reward["version"] == config["reward_version"]
            assert float(config["reward"]["shaping"]["per_step_min"]) - 1e-6 <= float(reward["shaping"]) <= float(config["reward"]["shaping"]["per_step_max"]) + 1e-6
    anti = [row["info"]["anti_exploit"] for row in train["transitions"]]
    assert max(int(row["same_action_steps"]) for row in anti) >= 3
    assert any(int(row["no_effect_steps"]) >= 1 for row in anti)
    report = generalization_report(config, [held_out], "held_out")
    assert report["by_scenario"][held_out["summary"]["scenario_id"]]["episodes"] == 1
    print("UMBRA_RL_CURRICULUM_SMOKE_OK stages=3 train_heldout_disjoint=true reward_caps=true repeat_guard=true")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
