#!/usr/bin/env python3
"""Runs two deterministic Godot headless rollouts and validates the RL ABI."""
import argparse
import json
import subprocess
import tempfile
from pathlib import Path


def rollout(root: Path, godot: str, request: dict) -> dict:
    with tempfile.TemporaryDirectory(prefix="umbra-rl-smoke-") as tmp:
        tmp_path = Path(tmp)
        request_path = tmp_path / "request.json"
        response_path = tmp_path / "response.json"
        request_path.write_text(json.dumps(request), encoding="utf-8")
        completed = subprocess.run([godot, "--headless", "--path", str(root), "--script", "res://tools/umbra_rl_rollout.gd", "--", "--request", str(request_path), "--response", str(response_path)], capture_output=True, text=True, timeout=90)
        if completed.returncode != 0:
            raise RuntimeError("Godot rollout failed: " + completed.stderr[-1000:])
        return json.loads(response_path.read_text(encoding="utf-8"))


def compact(result: dict) -> list:
    return [(item["action"]["action_index"], item["reward"], item["done"]) for item in result["transitions"]]


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--godot", default="godot")
    parser.add_argument("--root", default=str(Path(__file__).resolve().parents[1]))
    args = parser.parse_args()
    request = {"protocol": "ruptura_umbra_rl", "protocol_version": 1, "seed": 731, "max_steps": 6, "step_seconds": 0.12, "policy_mode": "legal_cycle"}
    first = rollout(Path(args.root), args.godot, request)
    second = rollout(Path(args.root), args.godot, request)
    assert first["ok"] and first["protocol"] == "ruptura_umbra_rl"
    assert len(first["transitions"]) == 6
    assert compact(first) == compact(second), "seeded rollout is not deterministic"
    for transition in first["transitions"]:
        assert len(transition["observation"]) == 83
        assert len(transition["action_mask"]) == 23
        assert len(transition["target_mask"]) == 3
        assert 0 <= transition["action"]["action_index"] < 23
        assert transition["info"]["executor_action"]
    print("UMBRA_RL_PROTOCOL_SMOKE_OK transitions=6 observation=83 action_mask=23 target_mask=3 deterministic=true")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
