#!/usr/bin/env python3
"""
Ruptura Temporal balance sampler.

Generates long-horizon samples for enemy, boss, and player stat scaling, plus a
self-contained interactive HTML report. The formulas mirror the deterministic
stat code in scripts/main.gd and deliberately mark probabilistic card forecasts
as approximations.
"""

from __future__ import annotations

import argparse
import csv
import json
import math
import random
from dataclasses import dataclass, field
from pathlib import Path
from statistics import quantiles
from typing import Dict, Iterable, List, Sequence


PLAYER_BASE_HP = 450.0
PLAYER_BASE_SPEED = 280.0
PLAYER_BASE_DAMAGE = 32.0
PLAYER_BASE_ATTACK_INTERVAL = 0.68
PLAYER_BASE_DASH_COOLDOWN = 2.2

ENEMY_BASE_HP = 30.0
ENEMY_BASE_SPEED = 108.0

BOSS_BASE_HP = 4860.0
BOSS_ARMOR = 0.528
BOSS_ARMOR_TIME_PER_MIN = 0.00055
BOSS_ARMOR_KILL_RATE = 0.000025
BOSS_ARMOR_COLETORA_RATE = 0.0025
BOSS_FARM_DAMAGE_TIME_CAP = 3600.0
BOSS_FARM_DAMAGE_SCORE_CAP = 250000.0
BOSS_FARM_DAMAGE_KILL_CAP = 3600.0
BOSS_FARM_DAMAGE_MAX_MULT = 1.85
BOSS7_HP_SCALE = 1.75

PORCAO_MAX_HP_GAIN_RATIO = 0.1

PHASE_ENEMY_MULTIPLIERS: Dict[int, Dict[str, float]] = {
    1: {"hp": 1.0, "speed": 1.0},
    2: {"hp": 1.65, "speed": 1.08},
    3: {"hp": 2.05, "speed": 1.12},
    4: {"hp": 2.75, "speed": 1.18},
    5: {"hp": 4.15, "speed": 1.24},
    6: {"hp": 1.0, "speed": 1.0},
    7: {"hp": 1.18, "speed": 1.08},
}

BOSS_PHASE_BASE_HP: Dict[int, float] = {
    1: BOSS_BASE_HP,
    2: 8910.0,
    3: 17280.0,
    4: 25380.0,
    5: 35100.0,
    6: BOSS_BASE_HP,
    7: BOSS_BASE_HP * BOSS7_HP_SCALE,
}

BOSS_FARM_RATES: Dict[int, Dict[str, float]] = {
    1: {"score": 6.0, "kills": 24.0},
    2: {"score": 8.0, "kills": 30.0},
    3: {"score": 11.0, "kills": 38.0},
    4: {"score": 14.0, "kills": 46.0},
    5: {"score": 17.0, "kills": 52.0},
    6: {"score": 6.0, "kills": 24.0},
    7: {"score": 10.0, "kills": 32.0},
}

MANIFESTATION_DAMAGE_MULTIPLIERS: Dict[str, float] = {
    "eletrica": 1.0,
    "lacerante": 1.12,
    "prismatica": 0.86,
    "retornante": 0.92,
    "parasitica": 0.78,
    "gravitante": 0.82,
    "ancorada": 1.0,
    "cartografica": 0.92,
    "mnesica": 0.74,
    "ressonante": 0.82,
    "contratual": 0.76,
    "acorrentada": 0.86,
    "eclipsada": 0.84,
    "bombastica": 0.9,
    "necronada": 0.84,
}

MANIFESTATION_ATTACK_INTERVALS: Dict[str, float] = {
    "eletrica": PLAYER_BASE_ATTACK_INTERVAL,
    "lacerante": 0.72,
    "prismatica": 0.42,
    "retornante": 0.62,
    "parasitica": PLAYER_BASE_ATTACK_INTERVAL,
    "gravitante": 0.74,
    "ancorada": PLAYER_BASE_ATTACK_INTERVAL,
    "cartografica": 0.61,
    "mnesica": 0.58,
    "ressonante": 0.5,
    "contratual": 0.6,
    "acorrentada": 0.76,
    "eclipsada": 0.58,
    "bombastica": 0.58,
    "necronada": 0.64,
}

ENEMY_KIND_MULTIPLIERS: Dict[str, Dict[str, float]] = {
    "common": {"hp": 1.0, "speed": 1.0, "damage": 1.0},
    "atirador": {"hp": 1.2, "speed": 0.8, "damage": 1.0},
    "kamikaze": {"hp": 0.8, "speed": 1.4, "damage": 1.0},
    "agglomerator": {"hp": 3.2, "speed": 1.35, "damage": 1.0},
    "stalker": {"hp": 0.9, "speed": 1.1, "damage": 1.0},
    "projector": {"hp": 1.2, "speed": 0.8, "damage": 1.0},
    "crystal": {"hp": 2.0, "speed": 0.5, "damage": 1.0},
    "curater": {"hp": 2.4, "speed": 0.45, "damage": 1.0},
    "cout_attack_speed": {"hp": 1.35, "speed": 0.74, "damage": 0.72},
    "shield_reflector": {"hp": 1.95, "speed": 0.58, "damage": 1.08},
    "devoto": {"hp": 0.6, "speed": 1.35, "damage": 0.9},
    "incensario": {"hp": 0.9, "speed": 0.72, "damage": 0.75},
    "guardiao": {"hp": 2.75, "speed": 0.52, "damage": 1.35},
    "pyro_penguin": {"hp": 1.85, "speed": 0.72, "damage": 0.82},
    "nexus_cartographer": {"hp": 1.25, "speed": 0.88, "damage": 0.72},
    "nexus_chronophage": {"hp": 1.55, "speed": 0.68, "damage": 0.62},
    "nexus_refractor": {"hp": 1.1, "speed": 0.82, "damage": 0.74},
    "nexus_weaver": {"hp": 1.35, "speed": 0.76, "damage": 0.68},
    "nexus_echo": {"hp": 0.95, "speed": 1.08, "damage": 0.8},
    "miasma_eel": {"hp": 1.2, "speed": 0.8, "damage": 0.82},
    "lodario": {"hp": 1.0, "speed": 1.0, "damage": 1.14},
    "fossil_pustule": {"hp": 2.0, "speed": 0.5, "damage": 0.9},
    "chronal_leech": {"hp": 0.9, "speed": 1.1, "damage": 0.82},
    "cinerido": {"hp": 0.85, "speed": 112.0 / ENEMY_BASE_SPEED, "damage": 0.35},
    "pangoliro": {"hp": 1.75, "speed": 72.0 / ENEMY_BASE_SPEED, "damage": 1.15},
    "corvol": {"hp": 0.7, "speed": 150.0 / ENEMY_BASE_SPEED, "damage": 0.82},
}

TUNABLE_CARD_NAMES = [
    "Disparo crescente",
    "Tempestade",
    "Porcao",
    "Defesa",
    "Speed Boost",
    "Speed Atack",
    "Teleporte",
    "Sorte",
    "Coletora",
    "Carta Zero",
]


@dataclass
class CardState:
    counts: Dict[str, int] = field(default_factory=dict)

    def get(self, name: str) -> int:
        return max(0, int(self.counts.get(name, 0)))

    def zero_multiplier(self) -> float:
        count = self.get("Carta Zero")
        if count <= 0:
            return 1.0
        return 1.0 + 0.06 * math.sqrt(float(count))


@dataclass
class SampleConfig:
    max_minutes: float = 90.0
    step_minutes: float = 3.0
    phase_length_minutes: float = 12.0
    score_per_minute: float = 650.0
    kills_per_minute: float = 9.0
    manifestation: str = "eletrica"
    enemy_kind: str = "common"
    cards: CardState = field(default_factory=CardState)


def clamp(value: float, minimum: float, maximum: float) -> float:
    return min(maximum, max(minimum, value))


def phase_for_minute(minute: float, phase_length_minutes: float) -> int:
    if phase_length_minutes <= 0.0:
        return 1
    return int(clamp(math.floor(minute / phase_length_minutes) + 1, 1, 7))


def manifestation_base_damage(name: str) -> float:
    return PLAYER_BASE_DAMAGE * MANIFESTATION_DAMAGE_MULTIPLIERS.get(name, 1.0)


def manifestation_attack_interval(name: str) -> float:
    return MANIFESTATION_ATTACK_INTERVALS.get(name, PLAYER_BASE_ATTACK_INTERVAL)


def player_stats(manifestation: str, cards: CardState) -> Dict[str, float]:
    zero = cards.zero_multiplier()
    base_damage = manifestation_base_damage(manifestation)
    damage = base_damage
    damage += base_damage * ((math.pow(1.15, cards.get("Disparo crescente")) - 1.0) * zero)
    damage += 5.0 * cards.get("Tempestade") * zero

    max_hp = PLAYER_BASE_HP * math.pow(1.0 + PORCAO_MAX_HP_GAIN_RATIO * zero, cards.get("Porcao"))
    speed = PLAYER_BASE_SPEED
    speed += PLAYER_BASE_SPEED * ((math.pow(1.065, cards.get("Speed Boost")) - 1.0) * zero)
    defense = min(50.0, 3.5 * cards.get("Defesa") * zero)
    crit_chance = 0.02 * cards.get("Tempestade") * zero
    attack_interval = max(0.28, manifestation_attack_interval(manifestation) - 0.014 * cards.get("Speed Atack") * zero)
    dash_cooldown = max(0.5, PLAYER_BASE_DASH_COOLDOWN - 0.3 * cards.get("Teleporte") * zero)
    effective_dps = damage * (1.0 + crit_chance) / attack_interval
    return {
        "player_hp": max_hp,
        "player_damage": damage,
        "player_speed": speed,
        "player_defense": defense,
        "player_crit_chance": crit_chance,
        "attack_interval": attack_interval,
        "dash_cooldown": dash_cooldown,
        "basic_dps_before_armor": effective_dps,
    }


def boss_farm_hp_bonus(phase: int, minute: float, score_total: float, kills: float) -> float:
    rates = BOSS_FARM_RATES.get(phase, BOSS_FARM_RATES[1])
    raw_bonus = math.sqrt(max(0.0, score_total)) * rates["score"] + math.sqrt(max(0.0, kills)) * rates["kills"]
    relief = clamp((minute - 20.0) / 40.0, 0.0, 0.55)
    return raw_bonus * (1.0 - relief)


def boss_hp(phase: int, minute: float, score_total: float, kills: float) -> float:
    return BOSS_PHASE_BASE_HP.get(phase, BOSS_BASE_HP) + boss_farm_hp_bonus(phase, minute, score_total, kills)


def boss_armor(phase: int, minute: float, kills: float, cards: CardState, source: str = "basic") -> float:
    armor = (
        BOSS_ARMOR
        + minute * BOSS_ARMOR_TIME_PER_MIN
        + kills * BOSS_ARMOR_KILL_RATE
        + cards.get("Coletora") * BOSS_ARMOR_COLETORA_RATE
    )
    if phase == 2:
        armor += 0.0165
    elif phase == 3:
        armor += 0.0495
    elif phase == 4:
        armor += 0.0825
    if source == "veneno":
        armor += 0.1
    return clamp(armor, 0.12, 0.84)


def boss_farm_pressure_multiplier(minute: float, score_total: float, kills: float) -> float:
    time_pressure = clamp((minute * 60.0) / BOSS_FARM_DAMAGE_TIME_CAP, 0.0, 1.0)
    score_pressure = clamp(score_total / BOSS_FARM_DAMAGE_SCORE_CAP, 0.0, 1.0)
    kill_pressure = clamp(kills / BOSS_FARM_DAMAGE_KILL_CAP, 0.0, 1.0)
    pressure = time_pressure * 0.5 + score_pressure * 0.3 + kill_pressure * 0.2
    return 1.0 + (BOSS_FARM_DAMAGE_MAX_MULT - 1.0) * clamp(pressure, 0.0, 1.0)


def enemy_stats(phase: int, enemy_kind: str, player_hp: float, player_defense: float) -> Dict[str, float]:
    phase_mult = PHASE_ENEMY_MULTIPLIERS.get(phase, PHASE_ENEMY_MULTIPLIERS[1])
    kind_mult = ENEMY_KIND_MULTIPLIERS.get(enemy_kind, ENEMY_KIND_MULTIPLIERS["common"])
    raw_damage = 0.06 * player_hp * kind_mult["damage"]
    actual_damage = max(1.0, raw_damage - player_defense)
    return {
        "enemy_hp": ENEMY_BASE_HP * phase_mult["hp"] * kind_mult["hp"],
        "enemy_speed": ENEMY_BASE_SPEED * phase_mult["speed"] * kind_mult["speed"],
        "enemy_raw_damage": raw_damage,
        "enemy_damage_after_defense": actual_damage,
    }


def sample_rows(config: SampleConfig) -> List[Dict[str, float]]:
    rows: List[Dict[str, float]] = []
    minute = 0.0
    while minute <= config.max_minutes + 0.0001:
        phase = phase_for_minute(minute, config.phase_length_minutes)
        score_total = minute * config.score_per_minute
        kills = minute * config.kills_per_minute
        pstats = player_stats(config.manifestation, config.cards)
        estats = enemy_stats(phase, config.enemy_kind, pstats["player_hp"], pstats["player_defense"])
        armor = boss_armor(phase, minute, kills, config.cards)
        boss_max_hp = boss_hp(phase, minute, score_total, kills)
        damage_to_boss = max(1.0, pstats["player_damage"] * (1.0 - armor))
        dps_to_boss = pstats["basic_dps_before_armor"] * (1.0 - armor)
        rows.append(
            {
                "minute": round(minute, 4),
                "phase": phase,
                "score_total": score_total,
                "kills": kills,
                "player_hp": pstats["player_hp"],
                "player_damage": pstats["player_damage"],
                "player_defense": pstats["player_defense"],
                "player_speed": pstats["player_speed"],
                "attack_interval": pstats["attack_interval"],
                "basic_dps_before_armor": pstats["basic_dps_before_armor"],
                "enemy_kind": config.enemy_kind,
                "enemy_hp": estats["enemy_hp"],
                "enemy_speed": estats["enemy_speed"],
                "enemy_damage_after_defense": estats["enemy_damage_after_defense"],
                "boss_hp": boss_max_hp,
                "boss_armor": armor,
                "damage_per_basic_to_boss": damage_to_boss,
                "basic_dps_to_boss": dps_to_boss,
                "boss_time_to_kill_seconds": boss_max_hp / max(1.0, dps_to_boss),
                "farm_pressure_damage_mult": boss_farm_pressure_multiplier(minute, score_total, kills),
            }
        )
        minute += max(0.25, config.step_minutes)
    return rows


def parse_cards(text: str) -> CardState:
    counts: Dict[str, int] = {}
    if not text:
        return CardState(counts)
    for raw in text.split(","):
        chunk = raw.strip()
        if not chunk:
            continue
        if "=" not in chunk:
            raise ValueError(f"Card entry must be NAME=COUNT, got {chunk!r}")
        name, value = chunk.split("=", 1)
        counts[name.strip()] = max(0, int(value.strip()))
    return CardState(counts)


def write_csv(path: Path, rows: Sequence[Dict[str, float]]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=list(rows[0].keys()))
        writer.writeheader()
        writer.writerows(rows)


def write_json(path: Path, rows: Sequence[Dict[str, float]]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(rows, indent=2), encoding="utf-8")


def percentile(values: Sequence[float], percent: float) -> float:
    if not values:
        return 0.0
    ordered = sorted(values)
    if len(ordered) == 1:
        return ordered[0]
    idx = (len(ordered) - 1) * percent
    lower = math.floor(idx)
    upper = math.ceil(idx)
    if lower == upper:
        return ordered[int(idx)]
    return ordered[lower] + (ordered[upper] - ordered[lower]) * (idx - lower)


def simulate_probabilistic_builds(
    purchases: int,
    runs: int,
    manifestation: str,
    seed: int,
    weights: Dict[str, float] | None = None,
) -> Dict[str, float]:
    rng = random.Random(seed)
    card_names = list(TUNABLE_CARD_NAMES)
    clean_weights = [max(0.0, float((weights or {}).get(name, 1.0))) for name in card_names]
    if sum(clean_weights) <= 0.0:
        clean_weights = [1.0 for _ in card_names]
    damages: List[float] = []
    hps: List[float] = []
    defenses: List[float] = []
    boss_ttk: List[float] = []
    for _ in range(max(1, runs)):
        counts = {name: 0 for name in card_names}
        for _purchase in range(max(0, purchases)):
            chosen = rng.choices(card_names, weights=clean_weights, k=1)[0]
            counts[chosen] += 1
        cards = CardState(counts)
        pstats = player_stats(manifestation, cards)
        armor = boss_armor(5, 60.0, 60.0 * 9.0, cards)
        dps_to_boss = pstats["basic_dps_before_armor"] * (1.0 - armor)
        damages.append(pstats["player_damage"])
        hps.append(pstats["player_hp"])
        defenses.append(pstats["player_defense"])
        boss_ttk.append(boss_hp(5, 60.0, 60.0 * 650.0, 60.0 * 9.0) / max(1.0, dps_to_boss))
    return {
        "runs": max(1, runs),
        "purchases": max(0, purchases),
        "damage_p10": percentile(damages, 0.10),
        "damage_p50": percentile(damages, 0.50),
        "damage_p90": percentile(damages, 0.90),
        "hp_p10": percentile(hps, 0.10),
        "hp_p50": percentile(hps, 0.50),
        "hp_p90": percentile(hps, 0.90),
        "defense_p10": percentile(defenses, 0.10),
        "defense_p50": percentile(defenses, 0.50),
        "defense_p90": percentile(defenses, 0.90),
        "boss_ttk_p10": percentile(boss_ttk, 0.10),
        "boss_ttk_p50": percentile(boss_ttk, 0.50),
        "boss_ttk_p90": percentile(boss_ttk, 0.90),
    }


def html_payload() -> Dict[str, object]:
    return {
        "playerBaseHp": PLAYER_BASE_HP,
        "playerBaseSpeed": PLAYER_BASE_SPEED,
        "playerBaseDamage": PLAYER_BASE_DAMAGE,
        "playerBaseAttackInterval": PLAYER_BASE_ATTACK_INTERVAL,
        "playerBaseDashCooldown": PLAYER_BASE_DASH_COOLDOWN,
        "enemyBaseHp": ENEMY_BASE_HP,
        "enemyBaseSpeed": ENEMY_BASE_SPEED,
        "bossBaseHp": BOSS_BASE_HP,
        "bossArmor": BOSS_ARMOR,
        "bossArmorTimePerMin": BOSS_ARMOR_TIME_PER_MIN,
        "bossArmorKillRate": BOSS_ARMOR_KILL_RATE,
        "bossArmorColetoraRate": BOSS_ARMOR_COLETORA_RATE,
        "porcaoMaxHpGainRatio": PORCAO_MAX_HP_GAIN_RATIO,
        "phaseEnemyMultipliers": PHASE_ENEMY_MULTIPLIERS,
        "bossPhaseBaseHp": BOSS_PHASE_BASE_HP,
        "bossFarmRates": BOSS_FARM_RATES,
        "manifestationDamageMultipliers": MANIFESTATION_DAMAGE_MULTIPLIERS,
        "manifestationAttackIntervals": MANIFESTATION_ATTACK_INTERVALS,
        "enemyKindMultipliers": ENEMY_KIND_MULTIPLIERS,
        "tunableCardNames": TUNABLE_CARD_NAMES,
    }


HTML_TEMPLATE = r"""<!doctype html>
<html lang="pt-BR">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Ruptura Temporal - Balance Scaling Sampler</title>
<style>
:root {
  color-scheme: dark;
  --bg: #070b13;
  --panel: #111826;
  --line: #273348;
  --text: #eef4ff;
  --muted: #9fb0c7;
  --cyan: #26d9ff;
  --green: #6dff78;
  --amber: #ffbe4a;
  --red: #ff6359;
}
* { box-sizing: border-box; }
body {
  margin: 0;
  background: var(--bg);
  color: var(--text);
  font: 14px/1.45 system-ui, Segoe UI, sans-serif;
}
main {
  display: grid;
  grid-template-columns: 340px 1fr;
  min-height: 100vh;
}
aside {
  border-right: 1px solid var(--line);
  background: #0c121d;
  padding: 16px;
  overflow: auto;
}
section {
  padding: 16px 18px 24px;
  min-width: 0;
}
h1, h2, h3 { margin: 0 0 10px; letter-spacing: 0; }
h1 { font-size: 22px; }
h2 { font-size: 16px; color: var(--cyan); margin-top: 18px; }
h3 { font-size: 13px; color: var(--muted); text-transform: uppercase; }
label { display: grid; gap: 5px; margin: 10px 0; color: var(--muted); }
input, select, button {
  width: 100%;
  border: 1px solid var(--line);
  border-radius: 6px;
  background: #0a1019;
  color: var(--text);
  padding: 8px 9px;
}
input[type="range"] { padding: 0; }
button { cursor: pointer; background: #142033; }
.grid { display: grid; grid-template-columns: repeat(4, minmax(140px, 1fr)); gap: 10px; margin-bottom: 12px; }
.metric {
  border: 1px solid var(--line);
  border-radius: 8px;
  padding: 10px;
  background: var(--panel);
  min-height: 74px;
}
.metric strong { display: block; font-size: 20px; }
.metric span { color: var(--muted); }
.chart {
  border: 1px solid var(--line);
  border-radius: 8px;
  background: #09101a;
  height: 360px;
  margin-bottom: 12px;
}
.charts { display: grid; grid-template-columns: 1fr 1fr; gap: 12px; }
.card-row { display: grid; grid-template-columns: 1fr 74px; gap: 8px; align-items: center; }
.note { color: var(--muted); font-size: 12px; }
table { width: 100%; border-collapse: collapse; margin-top: 10px; }
th, td { border-bottom: 1px solid var(--line); padding: 7px 6px; text-align: right; }
th:first-child, td:first-child { text-align: left; }
@media (max-width: 900px) {
  main { grid-template-columns: 1fr; }
  aside { border-right: 0; border-bottom: 1px solid var(--line); }
  .grid, .charts { grid-template-columns: 1fr; }
}
</style>
</head>
<body>
<main>
<aside>
  <h1>Balance Scaling</h1>
  <p class="note">Amostrador numerico com formulas deterministicas espelhadas de scripts/main.gd. A simulacao probabilistica usa sorteio aproximado de compras, nao a loja inteira.</p>
  <h2>Run</h2>
  <label>Manifestacao <select id="manifestation"></select></label>
  <label>Inimigo <select id="enemyKind"></select></label>
  <label>Minutos <input id="maxMinutes" type="number" min="3" step="3" value="90"></label>
  <label>Tamanho da fase em minutos <input id="phaseLength" type="number" min="1" step="1" value="12"></label>
  <label>Pontos por minuto <input id="scorePerMinute" type="number" min="0" step="50" value="650"></label>
  <label>Abates por minuto <input id="killsPerMinute" type="number" min="0" step="1" value="9"></label>
  <h2>Cartas fixas</h2>
  <div id="cardControls"></div>
  <h2>Probabilidade</h2>
  <label>Compras simuladas <input id="probPurchases" type="number" min="0" step="1" value="24"></label>
  <label>Runs simuladas <input id="probRuns" type="number" min="50" step="50" value="1000"></label>
  <button id="downloadCsv">Baixar CSV</button>
</aside>
<section>
  <div class="grid" id="metrics"></div>
  <div class="charts">
    <canvas class="chart" id="bossChart"></canvas>
    <canvas class="chart" id="enemyChart"></canvas>
    <canvas class="chart" id="damageChart"></canvas>
    <canvas class="chart" id="probChart"></canvas>
  </div>
  <h2>Leitura do ponto final</h2>
  <div id="explain"></div>
  <h2>Amostra</h2>
  <table id="sampleTable"></table>
</section>
</main>
<script id="payload" type="application/json">__PAYLOAD__</script>
<script>
const P = JSON.parse(document.getElementById("payload").textContent);
const $ = (id) => document.getElementById(id);
const colors = ["#26d9ff", "#6dff78", "#ffbe4a", "#ff6359"];

function clamp(v, lo, hi) { return Math.min(hi, Math.max(lo, v)); }
function phaseForMinute(minute, phaseLength) { return clamp(Math.floor(minute / phaseLength) + 1, 1, 7); }
function cardCounts() {
  const counts = {};
  for (const name of P.tunableCardNames) counts[name] = Number($("card_" + slug(name)).value || 0);
  return counts;
}
function slug(name) { return name.replace(/[^a-zA-Z0-9]/g, "_"); }
function zeroMult(counts) {
  const c = counts["Carta Zero"] || 0;
  return c <= 0 ? 1 : 1 + 0.06 * Math.sqrt(c);
}
function playerStats(manifestation, counts) {
  const zero = zeroMult(counts);
  const baseDamage = P.playerBaseDamage * (P.manifestationDamageMultipliers[manifestation] || 1);
  let damage = baseDamage;
  damage += baseDamage * ((Math.pow(1.15, counts["Disparo crescente"] || 0) - 1) * zero);
  damage += 5 * (counts["Tempestade"] || 0) * zero;
  const hp = P.playerBaseHp * Math.pow(1 + P.porcaoMaxHpGainRatio * zero, counts["Porcao"] || 0);
  const speed = P.playerBaseSpeed + P.playerBaseSpeed * ((Math.pow(1.065, counts["Speed Boost"] || 0) - 1) * zero);
  const defense = Math.min(50, 3.5 * (counts["Defesa"] || 0) * zero);
  const crit = 0.02 * (counts["Tempestade"] || 0) * zero;
  const baseInterval = P.manifestationAttackIntervals[manifestation] || P.playerBaseAttackInterval;
  const interval = Math.max(0.28, baseInterval - 0.014 * (counts["Speed Atack"] || 0) * zero);
  const dps = damage * (1 + crit) / interval;
  return {hp, damage, speed, defense, crit, interval, dps};
}
function bossFarmBonus(phase, minute, scoreTotal, kills) {
  const rates = P.bossFarmRates[phase] || P.bossFarmRates[1];
  const raw = Math.sqrt(Math.max(0, scoreTotal)) * rates.score + Math.sqrt(Math.max(0, kills)) * rates.kills;
  const relief = clamp((minute - 20) / 40, 0, 0.55);
  return raw * (1 - relief);
}
function bossHp(phase, minute, scoreTotal, kills) {
  return (P.bossPhaseBaseHp[phase] || P.bossBaseHp) + bossFarmBonus(phase, minute, scoreTotal, kills);
}
function bossArmor(phase, minute, kills, counts) {
  let armor = P.bossArmor + minute * P.bossArmorTimePerMin + kills * P.bossArmorKillRate + (counts["Coletora"] || 0) * P.bossArmorColetoraRate;
  if (phase === 2) armor += 0.0165;
  else if (phase === 3) armor += 0.0495;
  else if (phase === 4) armor += 0.0825;
  return clamp(armor, 0.12, 0.84);
}
function enemyStats(phase, kind, playerHp, playerDefense) {
  const pm = P.phaseEnemyMultipliers[phase] || P.phaseEnemyMultipliers[1];
  const km = P.enemyKindMultipliers[kind] || P.enemyKindMultipliers.common;
  const rawDamage = 0.06 * playerHp * km.damage;
  return {
    hp: P.enemyBaseHp * pm.hp * km.hp,
    speed: P.enemyBaseSpeed * pm.speed * km.speed,
    damage: Math.max(1, rawDamage - playerDefense)
  };
}
function rows() {
  const counts = cardCounts();
  const manifestation = $("manifestation").value;
  const enemyKind = $("enemyKind").value;
  const maxMinutes = Number($("maxMinutes").value || 90);
  const phaseLength = Number($("phaseLength").value || 12);
  const scorePerMinute = Number($("scorePerMinute").value || 0);
  const killsPerMinute = Number($("killsPerMinute").value || 0);
  const out = [];
  for (let minute = 0; minute <= maxMinutes + 0.0001; minute += 3) {
    const phase = phaseForMinute(minute, phaseLength);
    const score = minute * scorePerMinute;
    const kills = minute * killsPerMinute;
    const ps = playerStats(manifestation, counts);
    const es = enemyStats(phase, enemyKind, ps.hp, ps.defense);
    const armor = bossArmor(phase, minute, kills, counts);
    const bhp = bossHp(phase, minute, score, kills);
    out.push({
      minute, phase, score, kills,
      playerHp: ps.hp, playerDamage: ps.damage, playerDefense: ps.defense,
      enemyHp: es.hp, enemySpeed: es.speed, enemyDamage: es.damage,
      bossHp: bhp, bossArmor: armor,
      hitBoss: Math.max(1, ps.damage * (1 - armor)),
      dpsBoss: ps.dps * (1 - armor),
      ttkBoss: bhp / Math.max(1, ps.dps * (1 - armor))
    });
  }
  return out;
}
function drawChart(canvas, title, series, rows) {
  const ctx = canvas.getContext("2d");
  const ratio = window.devicePixelRatio || 1;
  canvas.width = canvas.clientWidth * ratio;
  canvas.height = canvas.clientHeight * ratio;
  ctx.setTransform(ratio, 0, 0, ratio, 0, 0);
  const w = canvas.clientWidth, h = canvas.clientHeight;
  ctx.clearRect(0, 0, w, h);
  ctx.fillStyle = "#09101a"; ctx.fillRect(0, 0, w, h);
  ctx.strokeStyle = "#273348"; ctx.lineWidth = 1;
  for (let i = 0; i <= 4; i++) {
    const y = 34 + (h - 58) * i / 4;
    ctx.beginPath(); ctx.moveTo(46, y); ctx.lineTo(w - 12, y); ctx.stroke();
  }
  ctx.fillStyle = "#eef4ff"; ctx.font = "13px system-ui"; ctx.fillText(title, 12, 20);
  const minX = 0, maxX = Math.max(...rows.map(r => r.minute), 1);
  const maxY = Math.max(...series.flatMap(s => rows.map(r => r[s.key])), 1);
  series.forEach((s, idx) => {
    ctx.strokeStyle = colors[idx % colors.length];
    ctx.lineWidth = 2;
    ctx.beginPath();
    rows.forEach((r, i) => {
      const x = 46 + (w - 64) * (r.minute - minX) / (maxX - minX);
      const y = h - 24 - (h - 58) * (r[s.key] / maxY);
      if (i === 0) ctx.moveTo(x, y); else ctx.lineTo(x, y);
    });
    ctx.stroke();
    ctx.fillStyle = colors[idx % colors.length];
    ctx.fillText(s.label, 54 + idx * 130, h - 7);
  });
}
function simulateProb() {
  const purchases = Number($("probPurchases").value || 0);
  const runs = Math.max(50, Number($("probRuns").value || 1000));
  const names = P.tunableCardNames;
  const samples = [];
  for (let r = 0; r < runs; r++) {
    const counts = {};
    for (const n of names) counts[n] = 0;
    for (let p = 0; p < purchases; p++) counts[names[Math.floor(Math.random() * names.length)]] += 1;
    samples.push(playerStats($("manifestation").value, counts).damage);
  }
  samples.sort((a, b) => a - b);
  const pick = q => samples[Math.floor((samples.length - 1) * q)] || 0;
  return [{name: "p10", value: pick(0.1)}, {name: "p50", value: pick(0.5)}, {name: "p90", value: pick(0.9)}];
}
function render() {
  const rs = rows();
  const last = rs[rs.length - 1];
  $("metrics").innerHTML = [
    ["Dano / hit", last.playerDamage.toFixed(1), "antes de armadura"],
    ["Hit no boss", last.hitBoss.toFixed(1), `${(last.bossArmor*100).toFixed(1)}% armor`],
    ["Vida inimigo", last.enemyHp.toFixed(1), `${last.enemySpeed.toFixed(1)} vel.`],
    ["TTK boss", `${last.ttkBoss.toFixed(1)}s`, `${last.bossHp.toFixed(0)} HP`],
  ].map(m => `<div class="metric"><span>${m[0]}</span><strong>${m[1]}</strong><span>${m[2]}</span></div>`).join("");
  drawChart($("bossChart"), "Boss: HP x dano efetivo", [{key:"bossHp",label:"Boss HP"}, {key:"hitBoss",label:"Hit no boss"}], rs);
  drawChart($("enemyChart"), "Inimigo: HP x dano recebido pelo jogador", [{key:"enemyHp",label:"Enemy HP"}, {key:"enemyDamage",label:"Dano no jogador"}], rs);
  drawChart($("damageChart"), "Jogador: dano x defesa", [{key:"playerDamage",label:"Dano"}, {key:"playerDefense",label:"Defesa"}], rs);
  const prob = simulateProb();
  drawChart($("probChart"), "Dano provavel por compras aleatorias", [{key:"value",label:"Dano"}], prob.map((p, i) => ({minute:i, value:p.value})));
  $("explain").innerHTML = `<p>No minuto ${last.minute.toFixed(0)}, fase ${last.phase}, o jogador causa ${last.playerDamage.toFixed(1)} por ataque basico antes da armadura. Contra o boss, a armadura estimada reduz para ${last.hitBoss.toFixed(1)} por hit e ${last.dpsBoss.toFixed(1)} DPS basico. O inimigo ${$("enemyKind").value} teria ${last.enemyHp.toFixed(1)} HP, ${last.enemySpeed.toFixed(1)} de velocidade e causaria ${last.enemyDamage.toFixed(1)} depois da defesa.</p>`;
  $("sampleTable").innerHTML = "<tr><th>Min</th><th>Fase</th><th>Dano</th><th>Enemy HP</th><th>Boss HP</th><th>Hit Boss</th><th>TTK Boss</th></tr>" +
    rs.filter((_, i) => i % 2 === 0 || i === rs.length - 1).map(r => `<tr><td>${r.minute.toFixed(0)}</td><td>${r.phase}</td><td>${r.playerDamage.toFixed(1)}</td><td>${r.enemyHp.toFixed(1)}</td><td>${r.bossHp.toFixed(0)}</td><td>${r.hitBoss.toFixed(1)}</td><td>${r.ttkBoss.toFixed(1)}s</td></tr>`).join("");
}
function downloadCsv() {
  const rs = rows();
  const headers = Object.keys(rs[0]);
  const csv = [headers.join(",")].concat(rs.map(r => headers.map(h => r[h]).join(","))).join("\n");
  const a = document.createElement("a");
  a.href = URL.createObjectURL(new Blob([csv], {type: "text/csv"}));
  a.download = "ruptura_balance_scaling.csv";
  a.click();
}
function init() {
  $("manifestation").innerHTML = Object.keys(P.manifestationDamageMultipliers).map(k => `<option>${k}</option>`).join("");
  $("enemyKind").innerHTML = Object.keys(P.enemyKindMultipliers).map(k => `<option>${k}</option>`).join("");
  $("cardControls").innerHTML = P.tunableCardNames.map(name => `<div class="card-row"><label>${name}<input id="card_${slug(name)}" type="range" min="0" max="30" value="0"></label><input id="card_${slug(name)}_num" type="number" min="0" max="999" value="0"></div>`).join("");
  for (const name of P.tunableCardNames) {
    const range = $("card_" + slug(name));
    const num = $("card_" + slug(name) + "_num");
    range.addEventListener("input", () => { num.value = range.value; render(); });
    num.addEventListener("input", () => { range.value = Math.min(30, Number(num.value || 0)); render(); });
  }
  document.querySelectorAll("input,select").forEach(el => el.addEventListener("input", render));
  $("downloadCsv").addEventListener("click", downloadCsv);
  render();
}
init();
</script>
</body>
</html>
"""


def write_html(path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    payload = json.dumps(html_payload(), separators=(",", ":"))
    path.write_text(HTML_TEMPLATE.replace("__PAYLOAD__", payload), encoding="utf-8")


def print_summary(rows: Sequence[Dict[str, float]]) -> None:
    first = rows[0]
    last = rows[-1]
    print("RUPTURA_BALANCE_SCALING_SAMPLE_OK")
    print(f"samples={len(rows)} minute_range={first['minute']:.1f}-{last['minute']:.1f} final_phase={int(last['phase'])}")
    print(
        "final_player damage={:.2f} hp={:.2f} defense={:.2f} speed={:.2f}".format(
            last["player_damage"],
            last["player_hp"],
            last["player_defense"],
            last["player_speed"],
        )
    )
    print(
        "final_enemy kind={} hp={:.2f} speed={:.2f} damage_after_defense={:.2f}".format(
            last["enemy_kind"],
            last["enemy_hp"],
            last["enemy_speed"],
            last["enemy_damage_after_defense"],
        )
    )
    print(
        "final_boss hp={:.2f} armor={:.4f} hit_damage={:.2f} ttk_seconds={:.2f}".format(
            last["boss_hp"],
            last["boss_armor"],
            last["damage_per_basic_to_boss"],
            last["boss_time_to_kill_seconds"],
        )
    )


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Sample Ruptura Temporal stat scaling and generate balance reports.")
    parser.add_argument("--max-minutes", type=float, default=90.0)
    parser.add_argument("--step-minutes", type=float, default=3.0)
    parser.add_argument("--phase-length-minutes", type=float, default=12.0)
    parser.add_argument("--score-per-minute", type=float, default=650.0)
    parser.add_argument("--kills-per-minute", type=float, default=9.0)
    parser.add_argument("--manifestation", default="eletrica", choices=sorted(MANIFESTATION_DAMAGE_MULTIPLIERS.keys()))
    parser.add_argument("--enemy-kind", default="common", choices=sorted(ENEMY_KIND_MULTIPLIERS.keys()))
    parser.add_argument("--cards", default="", help='Comma list, for example: "Disparo crescente=6,Tempestade=4,Defesa=3"')
    parser.add_argument("--csv", type=Path)
    parser.add_argument("--json", type=Path)
    parser.add_argument("--html", type=Path)
    parser.add_argument("--prob-purchases", type=int, default=0)
    parser.add_argument("--prob-runs", type=int, default=1000)
    parser.add_argument("--seed", type=int, default=37)
    return parser


def main(argv: Sequence[str] | None = None) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)
    cards = parse_cards(args.cards)
    config = SampleConfig(
        max_minutes=args.max_minutes,
        step_minutes=args.step_minutes,
        phase_length_minutes=args.phase_length_minutes,
        score_per_minute=args.score_per_minute,
        kills_per_minute=args.kills_per_minute,
        manifestation=args.manifestation,
        enemy_kind=args.enemy_kind,
        cards=cards,
    )
    rows = sample_rows(config)
    if not rows:
        parser.error("No rows generated; check --max-minutes and --step-minutes")
    if args.csv:
        write_csv(args.csv, rows)
        print(f"csv={args.csv}")
    if args.json:
        write_json(args.json, rows)
        print(f"json={args.json}")
    if args.html:
        write_html(args.html)
        print(f"html={args.html}")
    print_summary(rows)
    if args.prob_purchases > 0:
        forecast = simulate_probabilistic_builds(args.prob_purchases, args.prob_runs, args.manifestation, args.seed)
        print("PROBABILISTIC_CARD_FORECAST_APPROX")
        print(json.dumps(forecast, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
