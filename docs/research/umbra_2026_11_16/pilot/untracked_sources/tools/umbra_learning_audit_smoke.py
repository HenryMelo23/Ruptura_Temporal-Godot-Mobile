#!/usr/bin/env python3
"""Adversarial checks: metadata and broken experiments cannot prove learning."""
import copy
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

from umbra_learning_audit import FEATURES, inspect_payload, paired_report


def payload():
    return {"ok": True, "mind_version": "v1", "files": {"umbra_collective_mind.json": {
        "schema_version": 1, "features": FEATURES, "weights": {"ATAQUE": [1.0] * 12},
        "mode": "blend", "confidence": .1, "runs": 1, "samples": 60, "collective_version": "col-1"}}}


def episode(seed=7):
    return {"episode": seed, "score": 0.0, "dealt": 0.0, "taken": 0.0, "t": 10.0,
            "actions": {"ATAQUE": 3}, "bonus_l1": 1.0, "dead": False, "umbra_dead": False}


class EvidenceTests(unittest.TestCase):
    def test_new_version_is_not_new_parameters(self):
        before = payload()
        after = copy.deepcopy(before)
        after["mind_version"] = "v2"
        after["files"]["umbra_collective_mind.json"].update(runs=2, collective_version="col-2")
        report = inspect_payload(after, before)
        self.assertTrue(report["comparison"]["package_version_changed"])
        self.assertFalse(report["comparison"]["parameters_changed"])
        self.assertFalse(report["learning_improvement_proven"])

    def test_zero_confidence_does_not_activate_action_weights(self):
        data = payload()
        data["files"]["umbra_collective_mind.json"]["confidence"] = 0
        self.assertFalse(inspect_payload(data)["action_weights_can_influence"])

    def test_confidence_change_is_a_parameter_change(self):
        before = payload()
        after = copy.deepcopy(before)
        after["files"]["umbra_collective_mind.json"]["confidence"] = .2
        self.assertTrue(inspect_payload(after, before)["comparison"]["parameters_changed"])

    def test_corrupt_remote_rejected(self):
        for bad in (float("nan"), float("inf"), "1", True):
            data = payload()
            data["files"]["umbra_collective_mind.json"]["weights"]["ATAQUE"][0] = bad
            with self.assertRaises(ValueError):
                inspect_payload(data)

    def test_incompatible_schema_rejected(self):
        data = payload()
        data["files"]["umbra_collective_mind.json"]["features"] = list(reversed(FEATURES))
        with self.assertRaises(ValueError):
            inspect_payload(data)

    def test_empty_duplicate_and_unpaired_trials_rejected(self):
        for before, after in (([], []), ([episode(), episode()], [episode(), episode()]),
                              ([episode()], [episode(8)]), ([episode()], [])):
            with self.assertRaises(ValueError):
                paired_report(before, after)

    def test_tiny_positive_result_remains_inconclusive(self):
        before, after = [episode()], [episode()]
        after[0]["score"] = 100.0
        report = paired_report(before, after)
        self.assertEqual(report["evidence_status"], "inconclusive")
        self.assertFalse(report["learning_improvement_proven"])

    def test_identical_models_show_no_improvement(self):
        data = [episode(i) for i in range(32)]
        report = paired_report(data, data)
        self.assertEqual(report["paired_bootstrap_95_percentile"], [0, 0])
        self.assertEqual(report["evidence_status"], "inconclusive")

    def test_nonfinite_metrics_rejected(self):
        data = episode()
        data["score"] = float("nan")
        with self.assertRaises(ValueError):
            paired_report([data], [episode()])

    def test_sparse_training_does_not_emit_fake_model(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            samples, model = root / "samples.jsonl", root / "candidate.json"
            samples.write_text(json.dumps({"a": "ATAQUE", "f": [1.] * 12, "dealt": .1, "taken": 0}) + "\n")
            result = subprocess.run([sys.executable, str(Path(__file__).with_name("umbra_mind_fit.py")),
                                     str(samples), "--out", str(model)], capture_output=True, text=True)
            self.assertNotEqual(result.returncode, 0)
            self.assertIn("evidencia insuficiente", result.stderr)
            self.assertFalse(model.exists())


if __name__ == "__main__":
    unittest.main()
