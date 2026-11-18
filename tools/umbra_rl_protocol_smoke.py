#!/usr/bin/env python3
"""Runs two deterministic Godot headless rollouts and validates the RL ABI."""
import argparse
import json
import os
import math
import subprocess
import tempfile
from pathlib import Path


def rollout(root: Path, godot: str, request: dict) -> dict:
    with tempfile.TemporaryDirectory(prefix="umbra-rl-smoke-") as tmp:
        tmp_path = Path(tmp)
        request_path = tmp_path / "request.json"
        response_path = tmp_path / "response.json"
        request_path.write_text(json.dumps(request), encoding="utf-8")
        env = dict(os.environ, XDG_DATA_HOME=str(tmp_path / "data"), XDG_CONFIG_HOME=str(tmp_path / "config"))
        (tmp_path / "data").mkdir()
        (tmp_path / "config").mkdir()
        completed = subprocess.run([godot, "--headless", "--path", str(root), "--script", "res://tools/umbra_rl_rollout.gd", "--", "--request", str(request_path), "--response", str(response_path)], capture_output=True, text=True, timeout=90, env=env)
        if completed.returncode != 0 or "SCRIPT ERROR:" in completed.stderr or "ERROR:" in completed.stderr:
            raise RuntimeError("Godot rollout failed: " + completed.stderr[-1000:])
        return json.loads(response_path.read_text(encoding="utf-8"))


def compact(result: dict) -> list:
    return [(item["action"]["action_index"], item["reward"], item["done"]) for item in result["transitions"]]


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--godot", default="godot")
    parser.add_argument("--root", default=str(Path(__file__).resolve().parents[1]))
    parser.add_argument("--out", type=Path)
    args = parser.parse_args()
    request = {"protocol": "ruptura_umbra_rl", "protocol_version": 2, "seed": 731, "max_steps": 96, "step_seconds": 0.16, "policy_mode": "fixed_action", "fixed_action": "ATAQUE"}
    first = rollout(Path(args.root), args.godot, request)
    second = rollout(Path(args.root), args.godot, request)
    assert first["ok"] and first["protocol"] == "ruptura_umbra_rl"
    assert 1 < len(first["transitions"]) <= 96
    assert first == second, "full seeded transitions are not deterministic"
    assert sum(t["info"]["player_damage"] for t in first["transitions"]) > 0, "Umbra cannot damage player"
    assert sum(t["info"]["boss_damage"] for t in first["transitions"]) > 0, "player cannot damage Umbra"
    assert first["summary"]["simulation_ticks"] > 0
    assert first["transitions"][-1]["terminated"] != first["transitions"][-1]["truncated"]
    for transition in first["transitions"]:
        assert len(transition["observation"]) == 90
        assert len(transition["action_mask"]) == 25
        assert len(transition["target_mask"]) == 3
        assert 0 <= transition["action"]["action_index"] < 25
        assert transition["info"]["executor_action"]
        assert len(transition["next_observation"]) == 90
        assert all(math.isfinite(x) and -1.0001 <= x <= 1.0001 for x in transition["observation"])
        assert transition["info"]["ticks_advanced"] > 0
        if transition["info"]["executor_action"] == "NENHUMA" and not transition["action"]["decision_opportunity"]:
            assert not transition["info"]["anti_exploit"]["repeat_without_effect"], "cooldown wait punished"
    if args.out:
        args.out.mkdir(parents=True, exist_ok=False)
        for name, data in (("request", request), ("first", first), ("replay", second)):
            (args.out / (name + ".json")).write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")
    print("UMBRA_RL_PROTOCOL_SMOKE_OK observation=90 action_mask=25 target_mask=3 full_transitions_deterministic=true damage_both_sides=true")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
