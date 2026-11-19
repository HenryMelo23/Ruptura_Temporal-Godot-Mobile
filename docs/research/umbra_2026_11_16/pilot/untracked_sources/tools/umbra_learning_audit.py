#!/usr/bin/env python3
"""Evidence collection for the existing linear UMBRA mind; never deploys weights."""
from __future__ import annotations

import argparse
import hashlib
import json
import math
import os
from pathlib import Path
import random
import shutil
import statistics
import subprocess
import sys
import urllib.request

ROOT = Path(__file__).resolve().parents[1]
FEATURES = ["bias", "distance", "umbra_hp", "player_hp", "player_speed", "player_edge",
            "player_dash_ready", "under_fire", "dimension_base", "hazards", "rewind_armed", "fight_time"]
ACTIONS = {"ATAQUE", "SIFON", "TELEPORTE", "TELEPORTE_JUKE", "TRANSMUTAR_VORTICE", "TRANSMUTAR_GRAVIDADE",
           "TRANSMUTAR_NECROSE", "TRANSMUTAR_RESSONANCIA", "TRANSMUTAR_HEMORRAGIA", "TRANSMUTAR_ATRITO",
           "TRANSMUTAR_RASTRO", "VORTICE", "PRISAO", "MIASMA", "DESCARGA_ELETRICA", "CAMINHO_ESPINHOS",
           "LASER_SOBRECARGA", "PRAGA_RATOS", "REBOBINAR", "ECO_PROFETICO"}
PARAMETERS = ("schema_version", "features", "weights", "mode", "confidence", "aim_lead", "aim_lead_delta", "skill_priors")


def digest(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def write_json(path: Path, data: object) -> None:
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2, allow_nan=False) + "\n", encoding="utf-8")


def parameter_hash(layer: dict) -> str:
    """Parameter identity, not proof that actions or performance changed."""
    fields = {key: layer[key] for key in PARAMETERS if key in layer}
    return digest(json.dumps(fields, sort_keys=True, separators=(",", ":"), allow_nan=False).encode())


def inspect_payload(payload: dict, previous: dict | None = None) -> dict:
    if payload.get("ok") is not True:
        raise ValueError("remote payload does not declare ok=true")
    layer = payload.get("files", {}).get("umbra_collective_mind.json")
    if not isinstance(layer, dict) or layer.get("schema_version") != 1 or layer.get("features") != FEATURES:
        raise ValueError("missing or incompatible collective layer")
    weights = layer.get("weights", {})
    if not isinstance(weights, dict) or set(weights) - ACTIONS:
        raise ValueError("invalid weights")
    for row in weights.values():
        if not isinstance(row, list) or len(row) != len(FEATURES) or any(
            isinstance(v, bool) or not isinstance(v, (int, float)) or not math.isfinite(v) for v in row
        ):
            raise ValueError("invalid weight row")
    confidence = layer.get("confidence", 0)
    if not isinstance(confidence, (int, float)) or not math.isfinite(confidence) or not 0 <= confidence <= .7:
        raise ValueError("invalid collective confidence")
    nonzero = sum(abs(v) > 1e-9 for row in weights.values() for v in row)
    result = {
        "payload_contract_verified": True, "remote_verified": False, "mind_version": payload.get("mind_version"),
        "collective_version": layer.get("collective_version"), "runs": layer.get("runs", 0),
        "samples": layer.get("samples", 0), "confidence": confidence,
        "nonzero_coefficients": nonzero, "parameter_sha256": parameter_hash(layer),
        "action_weights_can_influence": bool(nonzero and confidence > 0),
        "learning_improvement_proven": False,
        "limitation": "A GET verifies a published snapshot, not client ingestion, causal action changes or improvement.",
    }
    if previous is not None:
        old = inspect_payload(previous)
        result["comparison"] = {
            "package_version_changed": old["mind_version"] != result["mind_version"],
            "parameters_changed": old["parameter_sha256"] != result["parameter_sha256"],
            "previous_parameter_sha256": old["parameter_sha256"],
        }
    return result


def paired_report(baseline: list[dict], candidate: list[dict]) -> dict:
    keys = [row["episode"] for row in baseline]
    if not keys or len(keys) != len(set(keys)) or keys != [row["episode"] for row in candidate]:
        raise ValueError("missing, duplicate or unpaired episode seeds")
    metrics = ("score", "dealt", "taken", "t")
    for row in baseline + candidate:
        if any(not isinstance(row.get(key), (int, float)) or not math.isfinite(row[key]) for key in metrics):
            raise ValueError("nonfinite or missing episode metrics")
    deltas = [b["score"] - a["score"] for a, b in zip(baseline, candidate)]
    rng = random.Random(60617)
    means = sorted(statistics.mean(rng.choices(deltas, k=len(deltas))) for _ in range(2000))
    interval = [means[49], means[1949]]
    changed = sum(a["actions"] != b["actions"] for a, b in zip(baseline, candidate))
    return {
        "pairs": len(keys), "mean_score_delta_candidate_minus_baseline": statistics.mean(deltas),
        "paired_bootstrap_95_percentile": interval,
        "action_histograms_changed_pairs": changed,
        "candidate_bonus_nonzero": any(row["bonus_l1"] > 0 for row in candidate),
        "baseline_mean": {key: statistics.mean(row[key] for row in baseline) for key in metrics},
        "candidate_mean": {key: statistics.mean(row[key] for row in candidate) for key in metrics},
        "baseline_umbra_wins": sum(row["dead"] for row in baseline),
        "candidate_umbra_wins": sum(row["dead"] for row in candidate),
        "candidate_umbra_losses": sum(row["umbra_dead"] for row in candidate),
        "evidence_status": "inconclusive" if len(keys) < 30 or interval[0] <= 0 else "positive_signal_requires_independent_training_replications",
        "learning_improvement_proven": False,
        "scope": "linear mind versus frozen heuristic opponent; score is a short-horizon proxy, not human likeness",
    }


def command(args: list[str], out: Path, name: str, env: dict | None = None, timeout: int = 300) -> str:
    write_json(out / (name + ".command.json"), args)
    try:
        done = subprocess.run(args, cwd=ROOT, env=env, capture_output=True, text=True, timeout=timeout)
    except subprocess.TimeoutExpired as exc:
        (out / (name + ".stdout.log")).write_bytes(exc.stdout or b"")
        (out / (name + ".stderr.log")).write_bytes(exc.stderr or b"")
        raise RuntimeError(name + " timed out; partial logs preserved") from exc
    (out / (name + ".stdout.log")).write_text(done.stdout, encoding="utf-8")
    (out / (name + ".stderr.log")).write_text(done.stderr, encoding="utf-8")
    if done.returncode or "SCRIPT ERROR:" in done.stderr or "SCRIPT ERROR:" in done.stdout:
        raise RuntimeError(f"{name} failed; see {out / (name + '.stderr.log')}")
    return done.stdout


def collect(args: argparse.Namespace, out: Path, name: str, seed: int, episodes: int,
            mind: Path | None, epsilon: float = 0.0) -> list[dict]:
    # Fresh per-arm user data prevents personal/cohort memory and previous tests
    # from leaking into paired trials. Nothing is written into player saves.
    home = out / (name + "_userdata")
    env = dict(os.environ, XDG_DATA_HOME=str(home / "data"), XDG_CONFIG_HOME=str(home / "config"))
    (home / "data").mkdir(parents=True)
    (home / "config").mkdir()
    path = out / (name + ".jsonl")
    cmd = [args.godot, "--headless", "--path", str(ROOT), "--script", "res://tools/umbra_mind_collect.gd", "--",
           f"--episodes={episodes}", f"--budget={args.timeout - 20}", f"--seconds={args.seconds}",
           f"--seed={seed}", f"--epsilon={epsilon}", "--lead_jitter=0", f"--out={path}"]
    cmd += [f"--mind={mind}"] if mind else ["--nomind=1"]
    command(cmd, out, name, env=env, timeout=args.timeout)
    data = [json.loads(line) for line in path.read_text(encoding="utf-8").splitlines() if line.strip()]
    rows = [row for row in data if row.get("record_type") == "episode"]
    if len(rows) != episodes:
        raise RuntimeError(f"{name}: incomplete batch {len(rows)}/{episodes}; do not infer improvement")
    if any(row.get("simulation_seconds", 0) <= 0 or not row.get("actions") for row in rows):
        raise RuntimeError(name + ": no simulated combat/decisions; tutorial or entrance may have paused the world")
    expected = digest(mind.read_bytes()) if mind else ""
    if any(row["candidate_sha256"] != expected for row in rows):
        raise RuntimeError(name + ": candidate loaded hash mismatch")
    return rows


def freeze_sources(out: Path) -> dict:
    def git(*items: str) -> str:
        return subprocess.check_output(["git", *items], cwd=ROOT, text=True)
    paths = git("ls-files", "scripts", "tools", "server", "scenes", "assets/data", "assets/weights", "project.godot").splitlines()
    paths += git("ls-files", "--others", "--exclude-standard", "scripts", "tools", "server", "scenes", "assets/data", "assets/weights").splitlines()
    hashes = {p: digest((ROOT / p).read_bytes()) for p in sorted(set(paths)) if (ROOT / p).is_file()}
    (out / "worktree.patch").write_bytes(subprocess.check_output(["git", "diff", "HEAD", "--binary"], cwd=ROOT))
    # New tool files are absent from git diff until committed; preserve them too.
    for p in git("ls-files", "--others", "--exclude-standard", "scripts", "tools", "server", "scenes", "assets/data", "assets/weights").splitlines():
        if (ROOT / p).is_file():
            target = out / "untracked_sources" / p
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(ROOT / p, target)
    result = {"commit": git("rev-parse", "HEAD").strip(), "status": git("status", "--short"), "files_sha256": hashes}
    write_json(out / "source_manifest.json", result)
    return {"commit": result["commit"], "source_manifest_sha256": digest((out / "source_manifest.json").read_bytes())}


def experiment(args: argparse.Namespace, out: Path) -> dict:
    if args.episodes < 1 or args.train_episodes < 0 or args.seed < 1 or args.seconds <= 0 or args.timeout < 30:
        raise ValueError("invalid episode count, seed, seconds or timeout")
    candidate = out / "candidate.json"
    shutil.copyfile(args.candidate, candidate)
    frozen = freeze_sources(out)
    version = command([args.godot, "--version"], out, "godot_version").strip()
    manifest = {"protocol": "umbra_linear_evidence_v1", **frozen, "godot": version,
                "arguments": vars(args), "baseline": "zero_linear_weights_default_aim" if args.zero_baseline else "frozen_candidate_before_fit",
                "opponent": "godot_exhibition_heuristic_not_python_dqn", "automatic_promotion": False}
    write_json(out / "manifest.json", manifest)
    before = out / "baseline.json"
    shutil.copyfile(candidate, before)
    if args.train_episodes:
        collect(args, out, "training", args.seed, args.train_episodes, candidate, epsilon=.3)
        command([sys.executable, "tools/umbra_mind_fit.py", str(out / "training.jsonl"), "--out", str(candidate),
                 "--blend", "0.5", "--min-samples", str(args.min_samples)], out, "fit")
    frozen_candidate_hash = digest(candidate.read_bytes())
    # Evaluation seed range is disjoint from training; seed ranges, not just
    # start values, are checked explicitly before launching either evaluation.
    eval_seed = args.seed + 10000
    train_ids = {args.seed * 100003 + i for i in range(args.train_episodes)}
    eval_ids = {eval_seed * 100003 + i for i in range(args.episodes)}
    if train_ids & eval_ids:
        raise ValueError("train/evaluation seed overlap")
    baseline = collect(args, out, "baseline_eval", eval_seed, args.episodes, None if args.zero_baseline else before)
    after = collect(args, out, "candidate_eval", eval_seed, args.episodes, candidate)
    replay = collect(args, out, "candidate_replay", eval_seed, args.episodes, candidate)
    deterministic = after == replay
    report = paired_report(baseline, after)
    report.update({"deterministic_episode_replay": deterministic, "training_episodes": args.train_episodes,
                   "candidate_sha256": digest(candidate.read_bytes()), "baseline_sha256": None if args.zero_baseline else digest(before.read_bytes()),
                   "parameter_change": parameter_hash(json.loads(before.read_text())) != parameter_hash(json.loads(candidate.read_text())),
                   "manifest_sha256": digest((out / "manifest.json").read_bytes()),
                   "published_or_promoted": False, "remote_verified": False})
    source_hashes = json.loads((out / "source_manifest.json").read_text())["files_sha256"]
    drift = [p for p, expected in source_hashes.items() if not (ROOT / p).is_file() or digest((ROOT / p).read_bytes()) != expected]
    report["source_files_changed_during_experiment"] = drift
    report["candidate_frozen_during_evaluation"] = digest(candidate.read_bytes()) == frozen_candidate_hash
    if not deterministic:
        report["evidence_status"] = "invalid_nondeterministic_replay"
    if not args.train_episodes:
        report["evidence_status"] = "ablation_only_no_training_performed" if deterministic else report["evidence_status"]
    elif args.zero_baseline:
        report["evidence_status"] = "ablation_only_zero_baseline_not_before_training"
    if drift or not report["candidate_frozen_during_evaluation"]:
        report["evidence_status"] = "invalid_source_or_artifact_changed"
    report["limitations"] = ["Episode summaries and decision samples, not full state/action trajectory replays.",
                             "Repeated seeds test summary reproducibility only; build and manifestation generalization require a separate matrix.",
                             "No human player, Python Apolo checkpoint, Android or live VPS integration was exercised."]
    write_json(out / "report.json", report)
    return report


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest="mode", required=True)
    inspect = sub.add_parser("inspect-remote", help="GET or inspect a saved anonymous VPS response; never POST")
    inspect.add_argument("--url", default="https://rupturatemporal.cloud/umbra/mind/latest")
    inspect.add_argument("--snapshot", type=Path)
    inspect.add_argument("--previous", type=Path)
    inspect.add_argument("--out", type=Path, required=True)
    run = sub.add_parser("experiment", help="optional linear fit, paired evaluation and deterministic replay")
    run.add_argument("--godot", default="godot")
    run.add_argument("--candidate", type=Path, default=ROOT / "assets/data/umbra_mind_base.json")
    run.add_argument("--episodes", type=int, default=8)
    run.add_argument("--train-episodes", type=int, default=0)
    run.add_argument("--min-samples", type=int, default=25)
    run.add_argument("--zero-baseline", action="store_true")
    run.add_argument("--seed", type=int, default=271)
    run.add_argument("--seconds", type=float, default=45)
    run.add_argument("--timeout", type=int, default=300)
    run.add_argument("--out", type=Path, required=True)
    args = parser.parse_args()
    args.out = args.out.resolve()
    if args.out.exists():
        parser.error("--out must be a new directory; previous evidence is immutable")
    args.out.mkdir(parents=True)
    # Convert Paths before serializing the exact arguments.
    if args.mode == "experiment":
        args.candidate = str(args.candidate.resolve())
    out = args.out
    args.out = str(out)
    try:
        if args.mode == "inspect-remote":
            raw = args.snapshot.read_bytes() if args.snapshot else urllib.request.urlopen(args.url, timeout=20).read()
            (out / "remote_snapshot.json").write_bytes(raw)
            previous = json.loads(args.previous.read_text()) if args.previous else None
            report = inspect_payload(json.loads(raw), previous)
            report["remote_verified"] = args.snapshot is None
            report["source"] = "saved_snapshot" if args.snapshot else args.url
            report["snapshot_sha256"] = digest(raw)
            write_json(out / "report.json", report)
        else:
            report = experiment(args, out)
        print(json.dumps({"report": str(out / "report.json"), "evidence_status": report.get("evidence_status"),
                          "learning_improvement_proven": False}, ensure_ascii=False))
        return 0
    except Exception as exc:
        write_json(out / "failure.json", {"error": str(exc), "mode": args.mode,
                                         "learning_improvement_proven": False, "remote_verified": False})
        print("UMBRA_EVIDENCE_FAIL: " + str(exc), file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
