#!/usr/bin/env python3
"""Development-only recurrent PPO trainer for the Godot UMBRA environment."""
from __future__ import annotations

import argparse
import concurrent.futures
import hashlib
import json
import math
import os
import struct
import subprocess
import sys
import tempfile
from pathlib import Path
from typing import Any

from umbra_rl_curriculum import generalization_report, load_curriculum, rollout_requests

try:
    import torch
    from torch import Tensor, nn
    from torch.distributions import Categorical
except ImportError:
    torch = None
    Tensor = Any

    class _MissingTorchModule:
        pass

    class _MissingTorchNN:
        Module = _MissingTorchModule

    nn = _MissingTorchNN()
    Categorical = Any


PROTOCOL = "ruptura_umbra_rl"
PROTOCOL_VERSION = 1
MODEL_FORMAT = "ruptura_umbra_multihead_policy"
MODEL_FORMAT_VERSION = 1
MODEL_VERSION = "umbra_2_0_multihead_gru"
ACTION_SCHEMA_VERSION = 2
TENSOR_ORDER = [
    "encoder.weight", "encoder.bias", "gru.z_input", "gru.z_hidden", "gru.z_bias",
    "gru.r_input", "gru.r_hidden", "gru.r_bias", "gru.n_input", "gru.n_hidden",
    "gru.n_bias", "heads.action.weight", "heads.action.bias", "heads.target.weight",
    "heads.target.bias", "heads.spatial.weight", "heads.spatial.bias", "heads.value.weight",
    "heads.value.bias",
]


class RecurrentActorCritic(nn.Module):
    """Matches RTUmbraMultiheadPolicy's explicit GRU equations exactly."""

    def __init__(self, input_size: int, action_size: int, target_size: int, encoder_size: int = 32, hidden_size: int = 32):
        super().__init__()
        self.encoder = nn.Linear(input_size, encoder_size)
        self.z_input, self.z_hidden = nn.Linear(encoder_size, hidden_size), nn.Linear(hidden_size, hidden_size, bias=False)
        self.r_input, self.r_hidden = nn.Linear(encoder_size, hidden_size), nn.Linear(hidden_size, hidden_size, bias=False)
        self.n_input, self.n_hidden = nn.Linear(encoder_size, hidden_size), nn.Linear(hidden_size, hidden_size, bias=False)
        self.action_head = nn.Linear(hidden_size, action_size)
        self.target_head = nn.Linear(hidden_size, target_size)
        self.spatial_head = nn.Linear(hidden_size, 4)
        self.value_head = nn.Linear(hidden_size, 1)
        self.input_size, self.action_size, self.target_size = input_size, action_size, target_size
        self.encoder_size, self.hidden_size = encoder_size, hidden_size

    def initial_state(self, batch: int = 1) -> Tensor:
        return torch.zeros(batch, self.hidden_size, dtype=torch.float32)

    def step(self, observation: Tensor, hidden: Tensor) -> tuple[dict[str, Tensor], Tensor]:
        encoded = torch.tanh(self.encoder(observation))
        update = torch.sigmoid(self.z_input(encoded) + self.z_hidden(hidden))
        reset = torch.sigmoid(self.r_input(encoded) + self.r_hidden(hidden))
        candidate = torch.tanh(self.n_input(encoded) + self.n_hidden(reset * hidden))
        next_hidden = (1.0 - update) * candidate + update * hidden
        return {
            "action": self.action_head(next_hidden), "target": self.target_head(next_hidden),
            "spatial": self.spatial_head(next_hidden), "value": self.value_head(next_hidden).squeeze(-1),
        }, next_hidden


def require_torch() -> None:
    if torch is None:
        raise RuntimeError("PyTorch is required. Install it only in the development environment; the game exports never include this trainer.")


def root_from_args(value: str) -> Path:
    return Path(value).resolve()


def call_godot(godot: str, root: Path, script: str, user_args: list[str], timeout: int = 180) -> subprocess.CompletedProcess:
    return subprocess.run([godot, "--headless", "--path", str(root), "--script", script, "--", *user_args], capture_output=True, text=True, timeout=timeout)


def live_contract(godot: str, root: Path, out_dir: Path) -> dict[str, Any]:
    out_dir.mkdir(parents=True, exist_ok=True)
    path = out_dir / "contract.json"
    completed = call_godot(godot, root, "res://tools/umbra_rl_contract.gd", ["--out", str(path)])
    if completed.returncode != 0 or not path.exists():
        raise RuntimeError("Godot contract dump failed: " + completed.stderr[-1000:])
    contract = json.loads(path.read_text(encoding="utf-8"))
    if contract.get("protocol") != PROTOCOL or contract.get("protocol_version") != PROTOCOL_VERSION:
        raise RuntimeError("Godot returned an incompatible RL contract")
    return contract


def tensor_record(tensor: Tensor) -> dict[str, Any]:
    detached = tensor.detach().to("cpu", dtype=torch.float32).contiguous()
    return {"shape": list(detached.shape), "data": detached.flatten().tolist()}


def tensor_digest(tensors: dict[str, dict[str, Any]]) -> str:
    digest = hashlib.sha256()
    for key in TENSOR_ORDER:
        for value in tensors[key]["data"]:
            digest.update(struct.pack("<f", float(value)))
    return digest.hexdigest()


def export_game_model(model: RecurrentActorCritic, contract: dict[str, Any], output: Path) -> None:
    tensors = {
        "encoder.weight": tensor_record(model.encoder.weight), "encoder.bias": tensor_record(model.encoder.bias),
        "gru.z_input": tensor_record(model.z_input.weight), "gru.z_hidden": tensor_record(model.z_hidden.weight), "gru.z_bias": tensor_record(model.z_input.bias),
        "gru.r_input": tensor_record(model.r_input.weight), "gru.r_hidden": tensor_record(model.r_hidden.weight), "gru.r_bias": tensor_record(model.r_input.bias),
        "gru.n_input": tensor_record(model.n_input.weight), "gru.n_hidden": tensor_record(model.n_hidden.weight), "gru.n_bias": tensor_record(model.n_input.bias),
        "heads.action.weight": tensor_record(model.action_head.weight), "heads.action.bias": tensor_record(model.action_head.bias),
        "heads.target.weight": tensor_record(model.target_head.weight), "heads.target.bias": tensor_record(model.target_head.bias),
        "heads.spatial.weight": tensor_record(model.spatial_head.weight), "heads.spatial.bias": tensor_record(model.spatial_head.bias),
        "heads.value.weight": tensor_record(model.value_head.weight), "heads.value.bias": tensor_record(model.value_head.bias),
    }
    payload = {
        "format": MODEL_FORMAT, "format_version": MODEL_FORMAT_VERSION, "model_version": MODEL_VERSION,
        "observation_schema_version": contract["observation_schema_version"], "action_schema_version": ACTION_SCHEMA_VERSION,
        "precision": "fp32", "feature_schema": contract["feature_schema"], "action_schema": contract["action_schema"],
        "target_schema": contract["target_schema"], "spatial_schema": contract["spatial_schema"],
        "architecture": {"input_size": model.input_size, "encoder_size": model.encoder_size, "hidden_size": model.hidden_size, "action_head_size": model.action_size, "target_head_size": model.target_size},
        "tensors": tensors, "integrity": {"algorithm": "sha256-fp32le", "tensors_sha256": tensor_digest(tensors)},
    }
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(json.dumps(payload, indent=2), encoding="utf-8")


def run_rollout(godot: str, root: Path, request: dict[str, Any], ordinal: int) -> dict[str, Any]:
    with tempfile.TemporaryDirectory(prefix=f"umbra-ppo-{ordinal}-") as temp:
        temp_dir = Path(temp)
        request_path, response_path = temp_dir / "request.json", temp_dir / "response.json"
        request_path.write_text(json.dumps(request), encoding="utf-8")
        completed = call_godot(godot, root, "res://tools/umbra_rl_rollout.gd", ["--request", str(request_path), "--response", str(response_path)])
        if completed.returncode != 0 or not response_path.exists():
            raise RuntimeError("Godot rollout failed: " + completed.stderr[-1000:])
        result = json.loads(response_path.read_text(encoding="utf-8"))
        if not result.get("ok"):
            raise RuntimeError("Godot environment rejected rollout: " + str(result.get("error")))
        return result


def run_selfplay_reference(godot: str, root: Path, out_dir: Path, update: int, seed: int, episodes: int) -> dict[str, Any]:
    """Runs the existing heuristic self-play as a comparison, never as PPO data."""
    reference_dir = out_dir / "selfplay_reference" / f"update_{update:04d}"
    completed = call_godot(godot, root, "res://tools/umbra_selfplay_train.gd", [f"--episodes={max(1, episodes)}", "--max-steps=360", f"--seed={seed + update * 97}", f"--out={reference_dir}"], timeout=180)
    report_path = reference_dir / "umbra_selfplay_report.json"
    if completed.returncode != 0 or not report_path.exists():
        raise RuntimeError("self-play reference failed: " + completed.stderr[-1000:])
    return json.loads(report_path.read_text(encoding="utf-8")).get("summary", {})


def collect(model: RecurrentActorCritic, contract: dict[str, Any], curriculum: dict[str, Any], args: argparse.Namespace, out_dir: Path, update: int, episodes: int, split: str) -> list[dict[str, Any]]:
    model_path = out_dir / "rollout_policy.json"
    export_game_model(model, contract, model_path)
    requests = rollout_requests(curriculum, split, update, episodes, args.seed, args.max_steps, args.step_seconds, str(model_path), sample_actions=split == "train")
    with concurrent.futures.ThreadPoolExecutor(max_workers=max(1, args.workers)) as pool:
        futures = [pool.submit(run_rollout, args.godot, Path(args.root), request, index) for index, request in enumerate(requests)]
        return [future.result() for future in futures]


def masked_distribution(logits: Tensor, mask: list[float]) -> Categorical:
    valid = torch.tensor(mask, dtype=torch.bool).unsqueeze(0)
    return Categorical(logits=logits.masked_fill(~valid, -1e9))


def episode_terms(model: RecurrentActorCritic, rollout: dict[str, Any]) -> tuple[list[Tensor], list[Tensor], list[Tensor], list[Tensor]]:
    hidden = model.initial_state()
    log_probs, values, entropies, rewards = [], [], [], []
    for item in rollout["transitions"]:
        observation = torch.tensor(item["observation"], dtype=torch.float32).unsqueeze(0)
        output, hidden = model.step(observation, hidden)
        action_dist = masked_distribution(output["action"], item["action_mask"])
        action = torch.tensor([item["action"]["action_index"]])
        # The environment currently validates target/space fields but the live
        # UMBRA executor has not bound them to abilities. Optimizing them now
        # would train a placebo head, so PPO learns only causal action choices.
        log_probs.append(action_dist.log_prob(action))
        entropies.append(action_dist.entropy())
        values.append(output["value"])
        rewards.append(torch.tensor(float(item["reward"])))
    return log_probs, values, entropies, rewards


def ppo_update(model: RecurrentActorCritic, optimizer: torch.optim.Optimizer, rollouts: list[dict[str, Any]], epochs: int) -> dict[str, float]:
    with torch.no_grad():
        old_terms = [episode_terms(model, rollout) for rollout in rollouts]
        old_log_probs = [torch.cat(terms[0]).detach() for terms in old_terms]
        returns = [torch.stack(terms[3]).flip(0).cumsum(0).flip(0).detach() for terms in old_terms]
    last = {"loss": 0.0, "reward": 0.0}
    for _ in range(epochs):
        optimizer.zero_grad()
        policy_losses, value_losses, entropy_terms = [], [], []
        for rollout, old_log, target_return in zip(rollouts, old_log_probs, returns):
            log_probs, values, entropies, _ = episode_terms(model, rollout)
            new_log = torch.cat(log_probs)
            advantages = (target_return - torch.cat(values).detach())
            if advantages.numel() > 1:
                advantages = (advantages - advantages.mean()) / (advantages.std(unbiased=False) + 1e-6)
            ratio = torch.exp(new_log - old_log)
            clipped = torch.clamp(ratio, 0.8, 1.2)
            policy_losses.append(-torch.minimum(ratio * advantages, clipped * advantages).mean())
            value_losses.append(torch.nn.functional.mse_loss(torch.cat(values), target_return))
            entropy_terms.append(torch.cat(entropies).mean())
        loss = torch.stack(policy_losses).mean() + 0.5 * torch.stack(value_losses).mean() - 0.01 * torch.stack(entropy_terms).mean()
        loss.backward()
        torch.nn.utils.clip_grad_norm_(model.parameters(), 0.5)
        optimizer.step()
        last["loss"] = float(loss.detach())
    last["reward"] = sum(float(result["summary"]["total_reward"]) for result in rollouts) / max(1, len(rollouts))
    return last


def save_checkpoint(path: Path, model: RecurrentActorCritic, optimizer: torch.optim.Optimizer, update: int, seed: int, contract: dict[str, Any], curriculum: dict[str, Any]) -> None:
    torch.save({"format": "ruptura_umbra_ppo_checkpoint", "version": 2, "update": update, "seed": seed, "contract": contract, "curriculum": curriculum, "model": model.state_dict(), "optimizer": optimizer.state_dict(), "torch_rng_state": torch.get_rng_state()}, path)


def load_checkpoint(path: Path, model: RecurrentActorCritic, optimizer: torch.optim.Optimizer, contract: dict[str, Any], curriculum: dict[str, Any]) -> int:
    checkpoint = torch.load(path, map_location="cpu", weights_only=False)
    if checkpoint.get("format") != "ruptura_umbra_ppo_checkpoint" or checkpoint.get("contract") != contract or checkpoint.get("curriculum") != curriculum:
        raise RuntimeError("checkpoint contract or curriculum mismatch")
    model.load_state_dict(checkpoint["model"])
    optimizer.load_state_dict(checkpoint["optimizer"])
    if checkpoint.get("torch_rng_state") is not None:
        torch.set_rng_state(checkpoint["torch_rng_state"])
    return int(checkpoint.get("update", 0))


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", default=str(Path(__file__).resolve().parents[1]))
    parser.add_argument("--godot", default="godot")
    parser.add_argument("--out", default="artifacts/umbra_rl")
    parser.add_argument("--seed", type=int, default=7301)
    parser.add_argument("--updates", type=int, default=1)
    parser.add_argument("--episodes-per-update", type=int, default=2)
    parser.add_argument("--episodes", type=int, default=4)
    parser.add_argument("--max-steps", type=int, default=48)
    parser.add_argument("--step-seconds", type=float, default=0.16)
    parser.add_argument("--workers", type=int, default=1)
    parser.add_argument("--curriculum", default=str(Path(__file__).resolve().parent / "config" / "umbra_rl_curriculum_v1.json"))
    parser.add_argument("--evaluation-episodes", type=int, default=4)
    parser.add_argument("--selfplay-episodes", type=int, default=8)
    parser.add_argument("--no-selfplay-reference", action="store_true")
    parser.add_argument("--resume")
    parser.add_argument("--evaluate")
    args = parser.parse_args()
    try:
        require_torch()
        args.root = str(root_from_args(args.root))
        out_dir = Path(args.out).resolve()
        curriculum = load_curriculum(Path(args.curriculum).resolve())
        contract = live_contract(args.godot, Path(args.root), out_dir)
        torch.manual_seed(args.seed)
        model = RecurrentActorCritic(len(contract["feature_schema"]), len(contract["action_schema"]), len(contract["target_schema"]))
        optimizer = torch.optim.Adam(model.parameters(), lr=3e-4)
        if args.evaluate:
            load_checkpoint(Path(args.evaluate), model, optimizer, contract, curriculum)
            results = collect(model, contract, curriculum, args, out_dir, 0, args.episodes, "held_out")
            report = generalization_report(curriculum, results, "held_out")
            (out_dir / "generalization_report.json").write_text(json.dumps(report, indent=2), encoding="utf-8")
            print(json.dumps({"mode": "evaluation", "episodes": len(results), "mean_reward": sum(float(item["summary"]["total_reward"]) for item in results) / max(1, len(results)), "report": str(out_dir / "generalization_report.json")}))
            return 0
        start = load_checkpoint(Path(args.resume), model, optimizer, contract, curriculum) if args.resume else 0
        metrics_path = out_dir / "metrics.jsonl"
        for update in range(start, start + max(1, args.updates)):
            rollouts = collect(model, contract, curriculum, args, out_dir, update, max(1, args.episodes_per_update), "train")
            metrics = ppo_update(model, optimizer, rollouts, epochs=2)
            metrics.update({"update": update + 1, "episodes": len(rollouts), "algorithm": "recurrent_ppo", "baseline": "dqn_v1_preserved", "curriculum_version": curriculum["curriculum_version"], "reward_version": curriculum["reward_version"]})
            if not args.no_selfplay_reference:
                metrics["selfplay_reference"] = run_selfplay_reference(args.godot, Path(args.root), out_dir, update + 1, args.seed, args.selfplay_episodes)
            with metrics_path.open("a", encoding="utf-8") as stream:
                stream.write(json.dumps(metrics) + "\n")
            save_checkpoint(out_dir / "checkpoint.pt", model, optimizer, update + 1, args.seed, contract, curriculum)
            export_game_model(model, contract, out_dir / "umbra_multihead_policy.json")
            held_out = collect(model, contract, curriculum, args, out_dir, update + 1, max(1, args.evaluation_episodes), "held_out")
            report = generalization_report(curriculum, held_out, "held_out")
            report["update"] = update + 1
            (out_dir / "generalization_report.json").write_text(json.dumps(report, indent=2), encoding="utf-8")
            print(json.dumps(metrics))
        return 0
    except Exception as error:
        print("UMBRA_PPO_TRAIN_FAIL: " + str(error), file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
