#!/usr/bin/env python3
"""Ajusta a mente base da UMBRA a partir das amostras do coletor headless.

Para cada acao, regressao ridge do retorno em 3 s (dano causado - dano sofrido)
sobre o contexto (12 features). O peso final de cada acao e a vantagem dela
sobre a media das acoes no mesmo contexto, escalada para a faixa das
heuristicas do jogo. Tambem escolhe o aim_lead pela melhor taxa de acerto.

uso: python3 tools/umbra_mind_fit.py .agent_logs/umbra_train/samples_*.jsonl \
         --out assets/data/umbra_mind_base.json [--blend 0.5]
"""
import argparse, glob, json, time
import numpy as np

FEATURES = ["bias", "distance", "umbra_hp", "player_hp", "player_speed", "player_edge",
            "player_dash_ready", "under_fire", "dimension_base", "hazards", "rewind_armed", "fight_time"]
ACTIONS = ["ATAQUE", "SIFON", "TELEPORTE", "TELEPORTE_JUKE",
           "TRANSMUTAR_VORTICE", "TRANSMUTAR_GRAVIDADE", "TRANSMUTAR_NECROSE", "TRANSMUTAR_RESSONANCIA",
           "TRANSMUTAR_HEMORRAGIA", "TRANSMUTAR_ATRITO", "TRANSMUTAR_RASTRO",
           "VORTICE", "PRISAO", "MIASMA", "DESCARGA_ELETRICA", "CAMINHO_ESPINHOS", "LASER_SOBRECARGA", "PRAGA_RATOS",
           "REBOBINAR", "ECO_PROFETICO"]
DEALT_W = 10.0
TAKEN_W = 30.0
RIDGE = 6.0
TARGET_SPREAD = 1.2
MAX_AVG = 1.4
# O bot le os avisos perfeitamente; a base nao suprime nenhuma habilidade
# alem disso. A mente coletiva (partidas reais) pode baixar mais.
MIN_AVG = -0.35
AIM_MAX = 0.9  # base desviavel por humanos  # desvio tipico do bonus da mente (faixa das heuristicas)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("inputs", nargs="+")
    ap.add_argument("--out", required=True)
    ap.add_argument("--blend", type=float, default=0.6, help="peso do ajuste novo sobre o arquivo atual")
    ap.add_argument("--min-samples", type=int, default=25)
    a = ap.parse_args()
    if not 0.0 < a.blend <= 1.0 or a.min_samples < 2:
        ap.error("--blend precisa estar em (0, 1] e --min-samples >= 2")

    files = []
    for pattern in a.inputs:
        files.extend(sorted(glob.glob(pattern)))
    rows, episodes = [], []
    for path in files:
        with open(path) as fh:
            for line in fh:
                d = json.loads(line)
                (rows if "a" in d else episodes).append(d)
    if not rows:
        raise SystemExit("sem amostras")
    n_f = len(FEATURES)
    X = np.array([r["f"][:n_f] for r in rows], dtype=np.float64)
    y = np.array([DEALT_W * r["dealt"] - TAKEN_W * r["taken"] for r in rows], dtype=np.float64)
    acts = np.array([r["a"] for r in rows])

    coef = {}
    counts = {}
    for act in ACTIONS:
        m = acts == act
        counts[act] = int(m.sum())
        if m.sum() < a.min_samples:
            continue
        Xa, ya = X[m], y[m]
        reg = RIDGE * np.eye(n_f)
        reg[0, 0] = 0.5  # bias quase livre
        coef[act] = np.linalg.solve(Xa.T @ Xa + reg, Xa.T @ ya)

    # Vantagem: Q_a(f) - media_b Q_b(f), linear em f.
    known = list(coef.keys())
    if len(known) < 2:
        raise SystemExit("evidencia insuficiente: pelo menos duas acoes precisam atingir --min-samples; nenhum modelo foi escrito")
    mean_w = np.mean([coef[k] for k in known], axis=0)
    adv = {k: coef[k] - mean_w for k in known}
    # Escala: desvio padrao das vantagens nas amostras reais -> TARGET_SPREAD.
    spread = np.std(np.concatenate([X @ adv[k] for k in known])) or 1.0
    scale = TARGET_SPREAD / spread

    try:
        with open(a.out) as fh:
            current = json.load(fh)
    except (OSError, ValueError):
        current = {}
    cur_w = current.get("weights", {})
    weights = {}
    for act in ACTIONS:
        old = np.array(cur_w.get(act, [0.0] * n_f), dtype=np.float64)[:n_f]
        if act in adv:
            new = np.clip(adv[act] * scale, -3.0, 3.0)
            # Nenhuma acao domina sozinha: bonus medio limitado a +-MAX_AVG.
            avg = float(np.mean(X @ new))
            if avg > MAX_AVG:
                new[0] -= avg - MAX_AVG
            elif avg < MIN_AVG:
                new[0] += MIN_AVG - avg
            w = (1 - a.blend) * old + a.blend * new
        else:
            w = old
        weights[act] = [round(float(v), 4) for v in w]

    # aim_lead: melhor taxa de acerto do plasma (suavizada).
    lead_stats = {}
    for e in episodes:
        k = round(float(e["lead"]), 2)
        s = lead_stats.setdefault(k, [0, 0])
        s[0] += int(e["shots"]); s[1] += int(e["plasma_hits"])
    aim = float(current.get("aim_lead", 0.72))
    if len(lead_stats) >= 3:
        # Inclinacao da taxa de acerto em funcao do lead (ponderada por tiros):
        # anda no maximo 0.05 por rodada na direcao que acerta mais.
        ks = np.array(list(lead_stats.keys()), dtype=np.float64)
        n = np.array([v[0] for v in lead_stats.values()], dtype=np.float64)
        h = np.array([v[1] for v in lead_stats.values()], dtype=np.float64)
        rate = (h + 1) / (n + 4)
        if n.sum() >= 300:
            km = np.average(ks, weights=n)
            slope = np.sum(n * (ks - km) * (rate - np.average(rate, weights=n))) / max(1e-6, np.sum(n * (ks - km) ** 2))
            aim = round(float(np.clip(aim + np.clip(slope * 0.1, -0.05, 0.05), 0.4, AIM_MAX)), 3)
    gen = int(current.get("generation", 0)) + 1
    out = {
        "schema_version": 1, "features": FEATURES, "actions": ACTIONS, "weights": weights,
        "aim_lead": aim, "version": "umbra-base-r%d" % gen, "generation": gen,
        "trained_episodes": int(current.get("trained_episodes", 0)) + len(episodes),
        "trained_samples": int(current.get("trained_samples", 0)) + len(rows),
        "opponent": "apolo_bot", "trained_at_unix": int(time.time()),
        "fit": {"samples": len(rows), "episodes": len(episodes), "counts": counts,
                "mean_return": round(float(y.mean()), 4), "scale": round(float(scale), 3),
                "lead_stats": {str(k): v for k, v in sorted(lead_stats.items())}},
    }
    with open(a.out, "w") as fh:
        json.dump(out, fh, indent=1)
    kills = sum(1 for e in episodes if e.get("dead"))
    print("UMBRA_FIT round=%d samples=%d episodes=%d kills=%d mean_return=%.4f aim=%.3f" % (gen, len(rows), len(episodes), kills, y.mean(), aim))
    top = sorted(((k, float(np.mean(X @ np.array(weights[k])))) for k in known), key=lambda kv: -kv[1])
    print("UMBRA_FIT avg_bonus " + " ".join("%s=%.2f" % kv for kv in top))


if __name__ == "__main__":
    main()
