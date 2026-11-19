#!/usr/bin/env python3
"""Compara execucoes do soak do tunel sem leitura manual de log.

uso:
  python3 tools/analyze_tunnel_soak.py .agent_logs/tunnel_soak/baseline
  python3 tools/analyze_tunnel_soak.py --baseline <dir> --candidate <dir>

Criterios de aceite verificados (rede normal):
  - zero desconexoes
  - idade p95 da geracao <= 250 ms
  - idade p99 <= 500 ms
  - nenhum silencio de mundo > 1500 ms
  - manager p95 < 500 ms
  - RSS sem crescimento continuo
"""
import argparse
import glob
import json
import os

BUDGET = {
    "world_gap_p95_ms": 250,
    "world_gap_p99_ms": 500,
    "world_silence_max_ms": 1500,
    "manager_p95_ms": 500,
    "rss_growth_mb": 64.0,
}


def load(run_dir):
    data = {"dir": run_dir, "roles": {}, "report": {}}
    report_path = os.path.join(run_dir, "report.json")
    if os.path.exists(report_path):
        with open(report_path) as handle:
            data["report"] = json.load(handle)
    for path in sorted(glob.glob(os.path.join(run_dir, "*.jsonl"))):
        role = os.path.basename(path)[: -len(".jsonl")]
        windows = []
        summary = {}
        for line in open(path):
            try:
                entry = json.loads(line)
            except Exception:
                continue
            if entry.get("kind") == "window":
                windows.append(entry)
            elif entry.get("kind") == "summary":
                summary = entry
        data["roles"][role] = {"windows": windows, "summary": summary}
    return data


def metrics(run):
    out = {}
    for role, info in run["roles"].items():
        windows = info["windows"]
        summary = info["summary"]
        applied = [w for w in windows if w.get("world_updates_in_window", 0) > 0]
        silences = [w.get("world_silence_ms", 0) for w in windows]
        rss = [w.get("rss_kb", 0) for w in windows if w.get("rss_kb")]
        # Uma execucao interrompida nao tem summary: cai para as janelas, que
        # sao gravadas a cada 5 s, para o relatorio nao mentir "nunca aplicou".
        last = windows[-1] if windows else {}
        window_p95 = sorted(w.get("world_gap_p95_ms", 0) for w in applied)
        out[role] = {
            "world_applied": summary.get("world_applied", last.get("world_applied", 0)),
            "world_gap_p95_ms": summary.get("world_gap_p95_ms",
                                           window_p95[int(len(window_p95) * 0.95)] if window_p95 else 0),
            "world_gap_p99_ms": summary.get("world_gap_p99_ms", max(window_p95) if window_p95 else 0),
            "world_gap_max_ms": summary.get("world_gap_max_ms",
                                            max((w.get("world_gap_max_ms", 0) for w in windows), default=0)),
            "world_silence_max_ms": max(silences) if silences else 0,
            "ping_p95_ms": summary.get("ping_p95_ms", last.get("ping_p95_ms", 0)),
            "disconnects": summary.get("disconnects", 0),
            "rss_growth_mb": round((rss[-1] - rss[0]) / 1024.0, 1) if len(rss) >= 2 else 0.0,
            "windows_with_updates": len(applied),
            "windows": len(windows),
            "reason": summary.get("reason", ""),
        }
    samples = [s.get("response_ms", 0) for s in run["report"].get("health_samples", []) if "response_ms" in s]
    samples.sort()
    out["_manager_p95_ms"] = samples[min(len(samples) - 1, int(len(samples) * 0.95))] if samples else 0
    return out


def verdict(role_metrics, manager_p95):
    problems = []
    for role, m in role_metrics.items():
        if role.startswith("_"):
            continue
        if m["disconnects"]:
            problems.append("%s: %d desconexao(oes) (%s)" % (role, m["disconnects"], m["reason"]))
        if m["world_applied"] == 0 and role != "host":
            problems.append("%s: nunca aplicou geracao do mundo" % role)
        if role != "host":
            if m["world_gap_p95_ms"] > BUDGET["world_gap_p95_ms"]:
                problems.append("%s: gap p95 %dms > %dms" % (role, m["world_gap_p95_ms"], BUDGET["world_gap_p95_ms"]))
            if m["world_gap_p99_ms"] > BUDGET["world_gap_p99_ms"]:
                problems.append("%s: gap p99 %dms > %dms" % (role, m["world_gap_p99_ms"], BUDGET["world_gap_p99_ms"]))
            if m["world_silence_max_ms"] > BUDGET["world_silence_max_ms"]:
                problems.append("%s: silencio de %dms > %dms" % (role, m["world_silence_max_ms"], BUDGET["world_silence_max_ms"]))
        if m["rss_growth_mb"] > BUDGET["rss_growth_mb"]:
            problems.append("%s: RSS cresceu %.1fMB" % (role, m["rss_growth_mb"]))
    if manager_p95 > BUDGET["manager_p95_ms"]:
        problems.append("manager p95 %dms > %dms" % (manager_p95, BUDGET["manager_p95_ms"]))
    return problems


def show(name, run):
    m = metrics(run)
    print("\n== %s (%s) ==" % (name, run["dir"]))
    for role, data in sorted(m.items()):
        if role.startswith("_"):
            continue
        print("  %-8s aplicadas=%-5s p95=%-5sms p99=%-5sms max=%-6sms silencio_max=%-6sms ping_p95=%-4sms desconexoes=%s rss=%.1fMB" % (
            role, data["world_applied"], data["world_gap_p95_ms"], data["world_gap_p99_ms"],
            data["world_gap_max_ms"], data["world_silence_max_ms"], data["ping_p95_ms"],
            data["disconnects"], data["rss_growth_mb"]))
    print("  manager p95: %sms" % m["_manager_p95_ms"])
    problems = verdict(m, m["_manager_p95_ms"])
    if problems:
        print("  REPROVADO:")
        for problem in problems:
            print("    - %s" % problem)
    else:
        print("  dentro do orcamento")
    return m


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("run", nargs="?")
    parser.add_argument("--baseline")
    parser.add_argument("--candidate")
    args = parser.parse_args()
    if args.run:
        show("execucao", load(args.run))
        return 0
    if not (args.baseline and args.candidate):
        parser.error("informe um diretorio, ou --baseline e --candidate")
    base = show("baseline", load(args.baseline))
    cand = show("candidato", load(args.candidate))
    print("\n== delta (candidato - baseline) ==")
    for role in sorted(set(base) & set(cand)):
        if role.startswith("_"):
            continue
        for key in ["world_applied", "world_gap_p95_ms", "world_gap_max_ms", "world_silence_max_ms", "disconnects"]:
            delta = cand[role][key] - base[role][key]
            arrow = "=" if delta == 0 else ("+" if delta > 0 else "")
            print("  %-8s %-22s %s%s" % (role, key, arrow, delta))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
