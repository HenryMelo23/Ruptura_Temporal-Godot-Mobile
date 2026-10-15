#!/usr/bin/env python3
"""Versioned UMBRA RL curriculum selection and generalization reporting."""
from __future__ import annotations

import json
from collections import Counter, defaultdict
from pathlib import Path
from typing import Any

FORMAT = "ruptura_umbra_curriculum"


def load_curriculum(path: Path) -> dict[str, Any]:
    config = json.loads(path.read_text(encoding="utf-8"))
    if config.get("format") != FORMAT:
        raise ValueError("invalid UMBRA curriculum format")
    if int(config.get("curriculum_version", 0)) < 1 or int(config.get("reward_version", 0)) < 1:
        raise ValueError("curriculum/reward version missing")
    scenarios = {str(row["id"]): row for row in config.get("scenarios", [])}
    if len(scenarios) != len(config.get("scenarios", [])):
        raise ValueError("scenario IDs must be unique")
    held_out = {key for key, row in scenarios.items() if row.get("split") == "held_out"}
    if not held_out:
        raise ValueError("at least one held-out scenario is required")
    previous = -1
    stage_ids: set[str] = set()
    for stage in config.get("stages", []):
        minimum = int(stage.get("min_update", -1))
        if minimum < previous:
            raise ValueError("curriculum stages must be sorted")
        previous = minimum
        for scenario_id in stage.get("scenario_ids", []):
            scenario_id = str(scenario_id)
            if scenario_id not in scenarios or scenarios[scenario_id].get("split") != "train":
                raise ValueError("training stage references a non-training scenario")
            stage_ids.add(scenario_id)
    if not stage_ids or stage_ids & held_out:
        raise ValueError("held-out scenarios cannot enter a training stage")
    return config


def active_stage(config: dict[str, Any], update: int) -> dict[str, Any]:
    result = config["stages"][0]
    for stage in config["stages"]:
        if update >= int(stage["min_update"]):
            result = stage
    return result


def scenario_ids(config: dict[str, Any], split: str, update: int) -> list[str]:
    if split == "train":
        return [str(key) for key in active_stage(config, update)["scenario_ids"]]
    return [str(row["id"]) for row in config["scenarios"] if row.get("split") == split]


def rollout_requests(config: dict[str, Any], split: str, update: int, episodes: int, seed: int, max_steps: int, step_seconds: float, policy_path: str | None = None, sample_actions: bool = True) -> list[dict[str, Any]]:
    ids = scenario_ids(config, split, update)
    if not ids:
        raise ValueError(f"no scenarios for split={split}")
    offset = abs(seed + update * 31) % len(ids)
    requests: list[dict[str, Any]] = []
    for ordinal in range(max(1, episodes)):
        request = {
            "protocol": "ruptura_umbra_rl", "protocol_version": 1,
            "curriculum_version": config["curriculum_version"], "reward_version": config["reward_version"],
            "scenario_id": ids[(offset + ordinal) % len(ids)],
            "seed": seed + update * 10000 + ordinal, "max_steps": max_steps,
            "step_seconds": step_seconds, "policy_mode": "model" if policy_path else "legal_cycle",
            "sample_actions": sample_actions,
        }
        if policy_path:
            request["policy_model"] = policy_path
        requests.append(request)
    return requests


def generalization_report(config: dict[str, Any], rollouts: list[dict[str, Any]], split: str) -> dict[str, Any]:
    by_scenario: dict[str, dict[str, Any]] = defaultdict(lambda: {"episodes": 0, "reward": 0.0, "principal": 0.0, "shaping": 0.0, "wins": 0, "losses": 0, "timeouts": 0, "repeat_without_effect": 0, "passive_streak": 0, "actions": Counter()})
    for rollout in rollouts:
        scenario = str(rollout.get("summary", {}).get("scenario_id", "unknown"))
        row = by_scenario[scenario]
        row["episodes"] += 1
        for transition in rollout.get("transitions", []):
            info = transition.get("info", {})
            reward = info.get("reward", {})
            anti = info.get("anti_exploit", {})
            row["reward"] += float(transition.get("reward", 0.0))
            row["principal"] += float(reward.get("principal", 0.0))
            row["shaping"] += float(reward.get("shaping", 0.0))
            row["repeat_without_effect"] += int(bool(anti.get("repeat_without_effect", False)))
            row["passive_streak"] += int(bool(anti.get("passive_streak", False)))
            row["actions"][str(transition.get("action", {}).get("action", ""))] += 1
            outcome = str(reward.get("outcome", ""))
            if outcome == "umbra_win":
                row["wins"] += 1
            elif outcome == "umbra_loss":
                row["losses"] += 1
            elif outcome == "timeout":
                row["timeouts"] += 1
    normalized = {}
    for scenario, row in sorted(by_scenario.items()):
        actions = dict(sorted(row.pop("actions").items()))
        normalized[scenario] = {**row, "actions": actions}
    return {
        "format": "ruptura_umbra_generalization_report", "version": 1,
        "curriculum_version": config["curriculum_version"], "reward_version": config["reward_version"],
        "split": split, "episodes": len(rollouts), "by_scenario": normalized,
        "held_out_ids": scenario_ids(config, "held_out", 0),
    }
