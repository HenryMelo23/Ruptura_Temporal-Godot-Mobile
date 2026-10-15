#!/usr/bin/env python3
"""Contract smoke for the frozen UMBRA v1/v2 TCC evaluator."""
from __future__ import annotations

import json
import tempfile
from pathlib import Path

import umbra_v1_v2_tcc_evaluation as evaluator


def raw(policy_id: str, manifest: dict, action: str) -> dict:
    episodes = []
    for item in manifest["scenario_cases"]:
        row = {
            "scenario_id": item["scenario_id"], "seed": item["seed"], "split": item["split"],
            "outcome": "umbra_win" if item["seed"] % 2 else "timeout", "duration_seconds": 12.0,
            "damage_to_player": 10.0, "damage_to_umbra": 20.0, "actions": [action, "ATAQUE", action],
            "decision_usec": [100.0, 120.0], "frame_usec": [8000.0, 9000.0], "peak_runtime_bytes": 4096,
            "invalid_action_count": 0, "executor_reject_count": 0, "crash": False, "determinism_mismatch_count": 0,
        }
        if item["pattern_change"]:
            row["adaptation"] = {"pre_actions": [action, action], "post_actions": ["TELEPORTE", "ATAQUE"], "pre_damage_to_player": 4.0, "post_damage_to_player": 6.0, "window_seconds": 4.0}
        episodes.append(row)
    return {"format": evaluator.RAW_FORMAT, "version": 1, "evaluation_id": manifest["evaluation_id"], "manifest_sha256": manifest["manifest_sha256"], "policy_id": policy_id, "model_sha256": manifest["models"][policy_id]["sha256"], "runtime_validation": {"model_loaded": True, "contract_verified": True, "godot_version": "test"}, "episodes": episodes}


def main() -> int:
    root = Path(__file__).resolve().parents[1]
    protocol = root / "tools/config/umbra_v1_v2_tcc_protocol_v1.json"
    with tempfile.TemporaryDirectory(prefix="umbra-v1-v2-tcc-") as temp:
        folder = Path(temp)
        v1, v2 = folder / "v1.json", folder / "v2.json"
        v1.write_text(json.dumps({
            "model_version": "umbra_dqn_2_0_actions_23", "action_schema_version": 2, "feature_schema_version": 1,
            "input_size": 24, "output_size": 23, "feature_schema": [f"f{i}" for i in range(24)], "action_schema": [f"a{i}" for i in range(23)],
        }), encoding="utf-8")
        v2.write_text(json.dumps({
            "format": "ruptura_umbra_multihead_policy", "observation_schema_version": 2, "action_schema_version": 2,
            "feature_schema": [f"f{i}" for i in range(83)], "action_schema": [f"a{i}" for i in range(23)],
            "architecture": {"input_size": 83, "action_head_size": 23},
        }), encoding="utf-8")
        manifest_path = folder / "manifest.json"
        manifest = evaluator.freeze(protocol, v1, v2, manifest_path, root)
        v1_raw, v2_raw = folder / "v1_raw.json", folder / "v2_raw.json"
        v1_raw.write_text(json.dumps(raw("v1", manifest, "ATAQUE")), encoding="utf-8")
        v2_raw.write_text(json.dumps(raw("v2", manifest, "HABILIDADE")), encoding="utf-8")
        report = evaluator.summarize(manifest_path, v1_raw, v2_raw, folder / "report.json", None)
        assert report["results"]["v1"]["episodes"] == len(manifest["scenario_cases"])
        assert report["results"]["v2"]["adaptation"]["episodes"] > 0
        broken = raw("v1", manifest, "ATAQUE")
        broken["episodes"][0]["seed"] = 999999
        try:
            evaluator.validate_raw(broken, manifest, "v1")
        except ValueError:
            pass
        else:
            raise AssertionError("the evaluator accepted a raw report with a non-frozen seed")
        try:
            evaluator.validate_model_contract(root / "assets/weights/umbra_dqn_weights.json", "v1")
        except ValueError:
            pass
        else:
            raise AssertionError("the legacy incomplete v1 artifact was accepted as frozen research model")
    print("UMBRA_V1_V2_TCC_EVALUATION_SMOKE_OK")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
