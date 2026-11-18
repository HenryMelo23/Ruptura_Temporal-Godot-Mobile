#!/usr/bin/env python3
"""Comparacao pareada (mesmas sementes) entre a UMBRA sem e com a DQN.

python3 tools/umbra_dqn_compare.py eval_fallback.jsonl eval_dqn.jsonl
"""
import json
import math
import sys


def episodes(path):
    out = {}
    for line in open(path, encoding="utf-8"):
        try:
            r = json.loads(line)
        except json.JSONDecodeError:
            continue
        if r.get("record_type") == "episode":
            out[r["episode"]] = r
    return out


def stats(diffs):
    n = len(diffs)
    m = sum(diffs) / n
    sd = math.sqrt(sum((d - m) ** 2 for d in diffs) / max(1, n - 1))
    se = sd / math.sqrt(n)
    return m, se


def main(a_path, b_path):
    a, b = episodes(a_path), episodes(b_path)
    keys = sorted(set(a) & set(b))
    print("episodios pareados:", len(keys))
    for metric in ("score", "dealt", "taken"):
        da = [a[k][metric] for k in keys]
        db = [b[k][metric] for k in keys]
        m, se = stats([y - x for x, y in zip(da, db)])
        print("%-6s sem=%.4f com=%.4f  diferenca=%+.4f  IC95=[%+.4f, %+.4f]" % (metric, sum(da) / len(da), sum(db) / len(db), m, m - 1.96 * se, m + 1.96 * se))
    wins = sum(1 for k in keys if b[k]["score"] > a[k]["score"])
    kills_a = sum(1 for k in keys if a[k]["player_dead"])
    kills_b = sum(1 for k in keys if b[k]["player_dead"])
    print("episodios em que a DQN foi melhor: %d/%d   jogador derrotado: sem=%d com=%d" % (wins, len(keys), kills_a, kills_b))


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])
