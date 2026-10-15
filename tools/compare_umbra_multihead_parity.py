#!/usr/bin/env python3
"""Reject PC/Android UMBRA policy reports that differ mechanically."""
from __future__ import annotations

import argparse
import json
import math
from pathlib import Path

FLOAT_TOLERANCE = 1e-5
SPATIAL_TOLERANCE = 1e-5
MAX_ANDROID_P95_USEC = 2000.0
MAX_FRAME_BUDGET_PERCENT = 12.0
MAX_MODEL_BYTES = 524_288
MAX_RUNTIME_BYTES = 131_072


def fail(message: str) -> None:
    raise SystemExit(f"UMBRA_PLATFORM_PARITY_FAIL {message}")


def close(left: float, right: float, label: str, tolerance: float = FLOAT_TOLERANCE) -> None:
    if not math.isclose(float(left), float(right), rel_tol=0.0, abs_tol=tolerance):
        fail(f"{label}: pc={left} android={right} tolerance={tolerance}")


def compare_vector(pc: list[float], android: list[float], label: str, tolerance: float = FLOAT_TOLERANCE) -> None:
    if len(pc) != len(android):
        fail(f"{label}: length pc={len(pc)} android={len(android)}")
    for index, (left, right) in enumerate(zip(pc, android)):
        close(left, right, f"{label}[{index}]", tolerance)


def load(path: Path) -> dict:
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        fail(f"could not read {path}: {error}")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--pc", type=Path, required=True)
    parser.add_argument("--android", type=Path, required=True)
    args = parser.parse_args()
    pc, android = load(args.pc), load(args.android)
    for key in ("report_version", "precision", "model_hash", "observation_schema_version", "action_schema_version", "brain_hz", "model_serialized_bytes", "runtime_buffer_bytes"):
        if pc.get(key) != android.get(key):
            fail(f"metadata {key}: pc={pc.get(key)} android={android.get(key)}")
    if pc.get("precision") != "fp32":
        fail(f"unsupported parity baseline {pc.get('precision')}")
    pc_cases = {entry["id"]: entry for entry in pc.get("fixture_results", [])}
    android_cases = {entry["id"]: entry for entry in android.get("fixture_results", [])}
    if pc_cases.keys() != android_cases.keys():
        fail("fixture IDs differ")
    for fixture_id, pc_case in pc_cases.items():
        android_case = android_cases[fixture_id]
        for key in ("action_logits", "action_probabilities", "target_logits", "target_probabilities", "next_hidden"):
            compare_vector(pc_case[key], android_case[key], f"{fixture_id}.{key}")
        for key in ("action_index", "target_slot"):
            if pc_case[key] != android_case[key]:
                fail(f"{fixture_id}.{key}: pc={pc_case[key]} android={android_case[key]}")
        for key in ("x", "y", "direction_x", "direction_y"):
            close(pc_case["spatial"][key], android_case["spatial"][key], f"{fixture_id}.spatial.{key}", SPATIAL_TOLERANCE)
    android_forward = android.get("forward", {})
    if float(android_forward.get("p95_usec", math.inf)) > MAX_ANDROID_P95_USEC:
        fail(f"android P95 exceeds {MAX_ANDROID_P95_USEC}us")
    if float(android_forward.get("frame_budget_percent", math.inf)) > MAX_FRAME_BUDGET_PERCENT:
        fail(f"android frame budget impact exceeds {MAX_FRAME_BUDGET_PERCENT}%")
    if int(android.get("model_serialized_bytes", math.inf)) > MAX_MODEL_BYTES or int(android.get("runtime_buffer_bytes", math.inf)) > MAX_RUNTIME_BYTES:
        fail("android model memory budget exceeded")
    print("UMBRA_PLATFORM_PARITY_OK fixtures=%d tolerance=%g android_mean_usec=%.3f android_p95_usec=%.3f" % (
        len(pc_cases), FLOAT_TOLERANCE, float(android_forward["mean_usec"]), float(android_forward["p95_usec"])))


if __name__ == "__main__":
    main()
