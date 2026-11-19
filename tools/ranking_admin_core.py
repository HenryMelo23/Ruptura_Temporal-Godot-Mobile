#!/usr/bin/env python3
"""Pure moderation rules used by the Ruptura ranking desktop administrator."""

from __future__ import annotations

from copy import deepcopy
from datetime import datetime, timezone
import ipaddress
from typing import Any, Callable
import uuid


VALID_RUN_DECISIONS = {"blocked", "released", "automatic"}
VALID_SECURITY_DECISIONS = {"blocked", "released", "automatic"}
MAX_REASON_LENGTH = 240
MAX_HISTORY = 40


class ModerationError(ValueError):
    """Raised when a requested moderation change is invalid or has no target."""


def utc_now_iso() -> str:
    return datetime.now(timezone.utc).isoformat(timespec="seconds").replace("+00:00", "Z")


def _clean_text(value: Any, limit: int) -> str:
    return " ".join(str(value or "").strip().split())[:limit]


def _reason(value: Any) -> str:
    result = _clean_text(value, MAX_REASON_LENGTH)
    if not result:
        raise ModerationError("Informe um motivo para registrar a decisão.")
    return result


def _actor(value: Any) -> str:
    return _clean_text(value, 64) or "Administrador local"


def _history(container: dict[str, Any]) -> list[dict[str, Any]]:
    history = container.get("manualModerationHistory")
    if not isinstance(history, list):
        history = []
        container["manualModerationHistory"] = history
    return history


def _append_history(container: dict[str, Any], event: dict[str, Any]) -> None:
    history = _history(container)
    history.append(event)
    del history[:-MAX_HISTORY]


def _original_run_state(run: dict[str, Any]) -> dict[str, Any]:
    active = run.get("manualModeration")
    if isinstance(active, dict) and isinstance(active.get("original"), dict):
        return deepcopy(active["original"])
    return {
        "rankEligible": run.get("rankEligible", True) is not False,
        "suspicious": bool(run.get("suspicious", False)),
        "suspicionReasons": deepcopy(run.get("suspicionReasons", []))
        if isinstance(run.get("suspicionReasons"), list)
        else [],
    }


def apply_run_decision(
    run: dict[str, Any],
    decision: str,
    reason: str,
    actor: str = "Administrador local",
    now_iso: str | None = None,
) -> None:
    """Apply a reversible manual decision to one raw leaderboard run."""
    if decision not in VALID_RUN_DECISIONS:
        raise ModerationError(f"Decisão de run desconhecida: {decision}")
    reason = _reason(reason)
    actor = _actor(actor)
    now_iso = _clean_text(now_iso or utc_now_iso(), 48)
    original = _original_run_state(run)
    event = {"decision": decision, "reason": reason, "actor": actor, "at": now_iso}

    if decision == "blocked":
        run["rankEligible"] = False
        run["suspicious"] = True
        reasons = run.get("suspicionReasons")
        if not isinstance(reasons, list):
            reasons = []
        if "manual_block" not in reasons:
            reasons.append("manual_block")
        run["suspicionReasons"] = reasons[:16]
        run["manualModeration"] = {**event, "original": original}
    elif decision == "released":
        # Release changes only competitive eligibility. Umbra training eligibility
        # remains untouched so a false positive is not silently used for learning.
        run["rankEligible"] = True
        run["suspicious"] = False
        run["suspicionReasons"] = []
        run["manualModeration"] = {**event, "original": original}
    else:
        run["rankEligible"] = original.get("rankEligible", True) is not False
        run["suspicious"] = bool(original.get("suspicious", False))
        restored_reasons = original.get("suspicionReasons", [])
        run["suspicionReasons"] = deepcopy(restored_reasons) if isinstance(restored_reasons, list) else []
        run.pop("manualModeration", None)

    _append_history(run, event)


def moderate_run_store(
    store: dict[str, Any],
    run_id: str,
    decision: str,
    reason: str,
    actor: str = "Administrador local",
    now_iso: str | None = None,
) -> dict[str, Any]:
    run_id = _clean_text(run_id, 64)
    runs = store.get("runs")
    if not run_id or not isinstance(runs, list):
        raise ModerationError("Arquivo de ranking inválido ou run não informada.")
    for run in runs:
        if isinstance(run, dict) and str(run.get("id", "")) == run_id:
            apply_run_decision(run, decision, reason, actor, now_iso)
            return run
    raise ModerationError(f"Run {run_id} não foi encontrada.")


def profile_key(run: dict[str, Any]) -> str:
    profile_id = _clean_text(run.get("profileId"), 64)
    if profile_id:
        return f"profile:{profile_id}"
    return f"name:{_clean_text(run.get('player'), 64).casefold()}"


def moderate_player_store(
    store: dict[str, Any],
    selected_run_id: str,
    decision: str,
    reason: str,
    actor: str = "Administrador local",
    now_iso: str | None = None,
) -> list[str]:
    runs = store.get("runs")
    if not isinstance(runs, list):
        raise ModerationError("Arquivo de ranking inválido.")
    selected = next(
        (run for run in runs if isinstance(run, dict) and str(run.get("id", "")) == selected_run_id),
        None,
    )
    if selected is None:
        raise ModerationError(f"Run {selected_run_id} não foi encontrada.")
    key = profile_key(selected)
    affected: list[str] = []
    for run in runs:
        if isinstance(run, dict) and profile_key(run) == key:
            apply_run_decision(run, decision, reason, actor, now_iso)
            affected.append(str(run.get("id", "")))
    if not affected:
        raise ModerationError("Nenhuma run do jogador foi encontrada.")
    return affected


def synthetic_ranking_score(phase: int, bosses_defeated: int, boss_damage_taken: int, victory: bool) -> int:
    phase = max(1, min(5, int(phase)))
    bosses_defeated = max(0, min(5, int(bosses_defeated)))
    boss_damage_taken = max(0, int(boss_damage_taken))
    progression = (phase - 1) * 1000
    bosses = bosses_defeated * 2000
    resilience = sum(
        round(500 / (1 + boss_damage_taken / (500 * boss_phase)))
        for boss_phase in range(1, bosses_defeated + 1)
    )
    return progression + bosses + resilience + (3000 if victory else 0)


def add_synthetic_run(
    store: dict[str, Any],
    specification: dict[str, Any],
    actor: str = "Administrador local",
    now_unix: int | None = None,
    run_uuid: str | None = None,
) -> dict[str, Any]:
    """Insert an unmistakably fake ranking run without feeding Umbra training."""
    runs = store.setdefault("runs", [])
    profiles = store.setdefault("profiles", {})
    if not isinstance(runs, list) or not isinstance(profiles, dict):
        raise ModerationError("Arquivo de ranking inválido.")
    if len(runs) >= 500:
        raise ModerationError("O arquivo já atingiu 500 runs. Arquive uma entrada antes de adicionar outra.")

    actor = _actor(actor)
    base_player = _clean_text(specification.get("player"), 32) or "Anônimo"
    phrase = "LOSER LOSER — RUN DE POSER"
    public_player = f"{base_player} · {phrase}"[:96]
    phase = max(1, min(5, int(specification.get("phase", 1) or 1)))
    bosses_defeated = max(0, min(phase, int(specification.get("bossesDefeated", 0) or 0)))
    boss_damage_taken = max(0, int(specification.get("bossDamageTaken", 0) or 0))
    victory = bool(specification.get("victory", False))
    duration_seconds = max(3, min(6 * 60 * 60, int(specification.get("durationSeconds", 600) or 600)))
    kills = max(0, int(specification.get("kills", 0) or 0))
    points_earned = max(0, int(specification.get("pointsEarned", 0) or 0))
    points_spent = max(0, min(points_earned, int(specification.get("pointsSpent", 0) or 0)))
    cards_total = max(0, int(specification.get("cardsTotal", 0) or 0))
    now_unix = int(now_unix if now_unix is not None else datetime.now(timezone.utc).timestamp())
    token = (run_uuid or uuid.uuid4().hex).replace("-", "")[:14]
    run_id = f"fake{token}"
    profile_id = f"admin_fake_{token}"
    if any(isinstance(run, dict) and str(run.get("id", "")) == run_id for run in runs):
        raise ModerationError(f"A run sintética {run_id} já existe.")

    boss_detail = [
        {
            "phase": boss_phase,
            "reached": True,
            "defeated": True,
            "damage_taken": boss_damage_taken,
            "synthetic": True,
        }
        for boss_phase in range(1, bosses_defeated + 1)
    ]
    score = synthetic_ranking_score(phase, bosses_defeated, boss_damage_taken, victory)
    run = {
        "id": run_id,
        "player": public_player,
        "profileId": profile_id,
        "profileKey": profile_id,
        "room": "admin-fake",
        "version": "ADMIN-FAKE",
        "versionCode": 0,
        "platform": "admin-desktop",
        "role": "synthetic",
        "result": "Vitoria" if victory else "Exibicao falsa",
        "date": datetime.fromtimestamp(now_unix, timezone.utc).isoformat(timespec="seconds").replace("+00:00", "Z"),
        "startedUnix": now_unix - duration_seconds,
        "endedUnix": now_unix,
        "duration": f"{duration_seconds // 60:02d}:{duration_seconds % 60:02d}",
        "durationSeconds": duration_seconds,
        "phase": phase,
        "kills": kills,
        "score": score,
        "reportedScore": score,
        "serverScore": score,
        "rankEligible": True,
        "suspicious": False,
        "suspicionReasons": [],
        "scoreCurrent": 0,
        "scoreTotal": points_earned,
        "pointsEarned": points_earned,
        "pointsSpent": points_spent,
        "baseDamageStart": 0,
        "baseDamageEnd": 0,
        "bossDamage": 0,
        "enemyDamage": 0,
        "damageTaken": boss_damage_taken * bosses_defeated,
        "damageThreats": [],
        "damageEvents": [],
        "heatmap": [],
        "behaviorMetrics": {},
        "umbraKnowledge": {},
        "umbraTrainingEligible": False,
        "umbraTrainingReasons": ["admin_fake_run"],
        "manifestation": _clean_text(specification.get("manifestation"), 64) or "Manifestação falsa",
        "manifestationKey": "admin_fake",
        "spectrum": _clean_text(specification.get("spectrum"), 64) or "Espectro falso",
        "spectrumKey": "admin_fake",
        "cardsTotal": cards_total,
        "cards": [],
        "playerStats": {},
        "enemyScaling": {},
        "timeline": [],
        "timelineSource": "admin_fake",
        "analysisCalculable": False,
        "analysisNote": "Partida sintética criada manualmente; não representa gameplay real.",
        "network": {},
        "runSessionId": "",
        "settings": {},
        "bossDetail": boss_detail,
        "balanceFlags": ["ADMIN_FAKE", "LOSER_LOSER_RUN_DE_POSER"],
        "manualSynthetic": True,
        "syntheticLabel": phrase,
        "syntheticReason": _reason(specification.get("reason")),
        "syntheticCreatedBy": actor,
        "syntheticCreatedAt": datetime.fromtimestamp(now_unix, timezone.utc).isoformat(timespec="seconds").replace("+00:00", "Z"),
    }
    runs.insert(0, run)
    profiles[profile_id] = {
        "player": public_player,
        "profileId": profile_id,
        "firstSeen": now_unix,
        "lastSeen": now_unix,
        "bestScore": score,
        "runs": 1,
        "manualSynthetic": True,
    }
    return run


def validate_ip(value: str) -> str:
    candidate = _clean_text(value, 64)
    if candidate in {"unknown", "localhost"}:
        raise ModerationError("Esse endereço não pode ser moderado manualmente.")
    try:
        parsed = ipaddress.ip_address(candidate)
    except ValueError as exc:
        raise ModerationError(f"Endereço IP inválido: {candidate}") from exc
    if parsed.is_loopback or parsed.is_unspecified:
        raise ModerationError("Endereços locais ou indefinidos não podem ser bloqueados.")
    return str(parsed)


def _security_state(store: dict[str, Any], ip: str) -> dict[str, Any]:
    ips = store.setdefault("ips", {})
    if not isinstance(ips, dict):
        raise ModerationError("Arquivo de segurança inválido.")
    state = ips.setdefault(ip, {})
    if not isinstance(state, dict):
        state = {}
        ips[ip] = state
    state.setdefault("strikes", 0)
    state.setdefault("reports", [])
    state.setdefault("blockedUntil", 0)
    state.setdefault("lastReason", "")
    state.setdefault("lastSeen", 0)
    return state


def _original_security_state(state: dict[str, Any]) -> dict[str, Any]:
    active = state.get("manualModeration")
    if isinstance(active, dict) and isinstance(active.get("original"), dict):
        return deepcopy(active["original"])
    return {
        "strikes": max(0, int(state.get("strikes", 0) or 0)),
        "reports": deepcopy(state.get("reports", [])) if isinstance(state.get("reports"), list) else [],
        "blockedUntil": max(0, int(state.get("blockedUntil", 0) or 0)),
        "lastReason": _clean_text(state.get("lastReason"), 512),
    }


def moderate_security_ip(
    store: dict[str, Any],
    ip_value: str,
    decision: str,
    reason: str,
    actor: str = "Administrador local",
    now_ms: int | None = None,
    duration_ms: int | None = None,
) -> dict[str, Any]:
    if decision not in VALID_SECURITY_DECISIONS:
        raise ModerationError(f"Decisão de segurança desconhecida: {decision}")
    ip = validate_ip(ip_value)
    reason = _reason(reason)
    actor = _actor(actor)
    now_ms = int(now_ms if now_ms is not None else datetime.now(timezone.utc).timestamp() * 1000)
    state = _security_state(store, ip)
    original = _original_security_state(state)
    event = {
        "decision": decision,
        "reason": reason,
        "actor": actor,
        "at": datetime.fromtimestamp(now_ms / 1000, timezone.utc).isoformat(timespec="seconds").replace("+00:00", "Z"),
    }

    if decision == "blocked":
        if duration_ms is None:
            duration_ms = 10 * 365 * 24 * 60 * 60 * 1000
        duration_ms = max(60_000, int(duration_ms))
        state["blockedUntil"] = now_ms + duration_ms
        state["strikes"] = max(4, int(state.get("strikes", 0) or 0))
        state["lastReason"] = f"manual_block:{reason}"
        state["lastSeen"] = max(now_ms, int(state.get("lastSeen", 0) or 0))
        state["manualModeration"] = {**event, "original": original}
    elif decision == "released":
        state["blockedUntil"] = 0
        state["strikes"] = 0
        state["reports"] = []
        state["lastReason"] = f"manual_release:{reason}"
        state["manualModeration"] = {**event, "original": original}
    else:
        state["strikes"] = original.get("strikes", 0)
        state["reports"] = deepcopy(original.get("reports", []))
        state["blockedUntil"] = original.get("blockedUntil", 0)
        state["lastReason"] = original.get("lastReason", "")
        state.pop("manualModeration", None)

    _append_history(state, event)
    audit = store.setdefault("audit", [])
    if not isinstance(audit, list):
        audit = []
        store["audit"] = audit
    audit.insert(0, {
        "at": event["at"],
        "ip": ip,
        "reasons": [f"admin_{decision}", reason],
        "severity": 0,
        "strikes": state.get("strikes", 0),
        "blockedUntil": state.get("blockedUntil", 0),
        "player": actor,
        "manual": True,
    })
    del audit[500:]
    return state


def mutate_copy(document: dict[str, Any], operation: Callable[[dict[str, Any]], Any]) -> tuple[dict[str, Any], Any]:
    """Apply an operation to a deep copy so callers never partially mutate a cache."""
    candidate = deepcopy(document)
    result = operation(candidate)
    return candidate, result
