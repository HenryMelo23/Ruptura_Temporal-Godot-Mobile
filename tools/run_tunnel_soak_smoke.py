#!/usr/bin/env python3
"""Orquestra o soak do tunel publico contra um manager de relay.

Cria uma sala pelo manager, sobe host e clientes, acompanha a saude do manager
durante o teste, junta os resultados e SEMPRE apaga a sala no bloco de limpeza.

Nenhum endereco ou senha fica gravado aqui: a URL do manager vem por argumento.

uso:
  python3 tools/run_tunnel_soak_smoke.py \\
    --manager http://127.0.0.1:18090 \\
    --godot /caminho/para/godot \\
    --duration 600 --peers 3 --scenario full_flow \\
    --output .agent_logs/tunnel_soak/baseline
"""
import argparse
import json
import os
import signal
import subprocess
import sys
import time
import urllib.error
import urllib.request

ROLES = ["host", "client", "client2"]
SCRIPT = "res://tests/multiplayer_tunnel_soak_smoke.gd"


def http_json(url, method="GET", payload=None, timeout=90):
    data = None
    headers = {}
    if payload is not None:
        data = json.dumps(payload).encode("utf-8")
        headers["content-type"] = "application/json"
    request = urllib.request.Request(url, data=data, headers=headers, method=method)
    # O manager e local/isolado: proxy de ambiente so atrapalha.
    opener = urllib.request.build_opener(urllib.request.ProxyHandler({}))
    with opener.open(request, timeout=timeout) as response:
        body = response.read().decode("utf-8")
    return json.loads(body) if body.strip() else {}


def wait_manager(manager, timeout_s=30):
    deadline = time.time() + timeout_s
    while time.time() < deadline:
        try:
            health = http_json(manager + "/health", timeout=5)
            if health.get("ok"):
                return health
        except Exception:
            pass
        time.sleep(0.5)
    raise RuntimeError("manager nao respondeu em %ss: %s" % (timeout_s, manager))


def launch(role, args, out_dir, project):
    log_path = os.path.join(out_dir, "%s.log" % role)
    log = open(log_path, "wb")
    command = [
        args.godot, "--headless", "--path", project,
        "--script", SCRIPT, "--",
        "--role=%s" % role,
        "--host=%s" % args.room_host,
        "--port=%d" % args.room_port,
        "--duration=%d" % args.duration,
        "--scenario=%s" % args.scenario,
        "--seed=%d" % args.seed,
        "--peers=%d" % args.peers,
        "--result-dir=%s" % args.result_res_dir,
    ]
    if args.relay_heartbeat:
        # O proprio jogo passa a bater no manager; a sala sobreviver (ou nao)
        # vira a prova do caminho de heartbeat.
        command.append("--relay-base-url=%s" % args.manager.rstrip("/"))
        command.append("--room-code=%s" % args.room_code)
    process = subprocess.Popen(command, cwd=project, stdout=log, stderr=subprocess.STDOUT,
                               start_new_session=True)
    return {"role": role, "process": process, "log": log, "log_path": log_path, "command": command}


def terminate(entry):
    process = entry["process"]
    if process.poll() is not None:
        return
    try:
        os.killpg(os.getpgid(process.pid), signal.SIGTERM)
    except Exception:
        process.terminate()
    try:
        process.wait(timeout=10)
    except Exception:
        try:
            os.killpg(os.getpgid(process.pid), signal.SIGKILL)
        except Exception:
            process.kill()


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--manager", required=True, help="URL do manager (ex.: http://127.0.0.1:18090)")
    parser.add_argument("--godot", required=True)
    parser.add_argument("--project", default=os.getcwd())
    parser.add_argument("--duration", type=int, default=600)
    parser.add_argument("--peers", type=int, default=2, choices=[2, 3])
    parser.add_argument("--scenario", default="full_flow")
    parser.add_argument("--seed", type=int, default=7)
    parser.add_argument("--output", required=True)
    parser.add_argument("--label", default="")
    parser.add_argument("--relay-heartbeat", action="store_true",
                        help="deixa o proprio jogo bater no manager em vez do runner")
    # Matriz de rede: o proxy UDP fica entre os peers e a sala.
    parser.add_argument("--chaos", action="store_true")
    parser.add_argument("--chaos-port", type=int, default=24999)
    parser.add_argument("--loss", type=float, default=0.0)
    parser.add_argument("--delay-ms", type=float, default=0.0)
    parser.add_argument("--jitter-ms", type=float, default=0.0)
    parser.add_argument("--burst-loss", type=float, default=0.0)
    parser.add_argument("--burst-ms", type=float, default=0.0)
    parser.add_argument("--blackout-at-ms", type=float, default=0.0)
    parser.add_argument("--blackout-ms", type=float, default=0.0)
    args = parser.parse_args()

    manager = args.manager.rstrip("/")
    project = os.path.abspath(args.project)
    out_dir = os.path.abspath(args.output)
    os.makedirs(out_dir, exist_ok=True)
    # O teste grava com caminho res://; o runner precisa do mesmo lugar relativo.
    args.result_res_dir = "res://" + os.path.relpath(out_dir, project).replace(os.sep, "/")

    report = {
        "label": args.label or args.scenario,
        "manager": manager,
        "scenario": args.scenario,
        "duration_s": args.duration,
        "peers": args.peers,
        "seed": args.seed,
        "started_at": time.time(),
        "health_samples": [],
        "roles": {},
        "ok": False,
    }
    room = None
    running = []
    chaos = None
    try:
        report["manager_health_start"] = wait_manager(manager)
        room = http_json(manager + "/rooms", "POST", {"name": "tunnel-soak", "roomName": "tunnel soak"})
        report["room"] = {"code": room.get("code"), "host": room.get("host"), "port": room.get("port")}
        args.room_host = room.get("host")
        args.room_port = int(room.get("port"))
        args.room_code = room.get("code")
        if args.chaos:
            chaos_log = open(os.path.join(out_dir, "chaos.log"), "wb")
            chaos_cmd = [
                sys.executable, os.path.join(project, "tools", "udp_chaos_proxy.py"),
                "--listen", str(args.chaos_port),
                "--target", "%s:%d" % (args.room_host, args.room_port),
                "--loss", str(args.loss), "--delay-ms", str(args.delay_ms),
                "--jitter-ms", str(args.jitter_ms), "--burst-loss", str(args.burst_loss),
                "--burst-ms", str(args.burst_ms),
                "--blackout-at-ms", str(args.blackout_at_ms), "--blackout-ms", str(args.blackout_ms),
            ]
            chaos_proc = subprocess.Popen(chaos_cmd, cwd=project, stdout=chaos_log,
                                          stderr=subprocess.STDOUT, start_new_session=True)
            chaos = {"role": "chaos", "process": chaos_proc, "log": chaos_log,
                     "log_path": os.path.join(out_dir, "chaos.log"), "command": chaos_cmd}
            time.sleep(1.0)
            # Os peers passam a falar com o proxy, nao com a sala.
            args.room_port = args.chaos_port
            report["chaos"] = {"loss": args.loss, "delay_ms": args.delay_ms,
                               "jitter_ms": args.jitter_ms, "burst_loss": args.burst_loss,
                               "burst_ms": args.burst_ms, "port": args.chaos_port}
        print("sala %s em %s:%s" % (room.get("code"), args.room_host, args.room_port), flush=True)

        for role in ROLES[: args.peers]:
            running.append(launch(role, args, out_dir, project))
            # Host primeiro: ele e o dono do mundo.
            time.sleep(2.0)

        deadline = time.time() + args.duration + 120
        while time.time() < deadline:
            if all(entry["process"].poll() is not None for entry in running):
                break
            try:
                started = time.time()
                health = http_json(manager + "/health", timeout=10)
                health["response_ms"] = int((time.time() - started) * 1000)
                health["at"] = int(time.time())
                report["health_samples"].append(health)
            except Exception as error:
                report["health_samples"].append({"at": int(time.time()), "error": str(error)})
            # O smoke conecta direto por ENet; sem este heartbeat de dono o
            # manager mata a sala pelo watchdog e o teste mediria o SIGTERM.
            # Com --relay-heartbeat quem bate e o jogo, e o runner sai de cena:
            # a sala sobreviver passa a ser a prova do caminho de heartbeat.
            if not args.relay_heartbeat:
                try:
                    http_json("%s/rooms/%s/heartbeat" % (manager, room["code"]), "POST",
                              {"role": "owner", "mode": "game", "peer_id": 1}, timeout=10)
                except Exception as error:
                    report.setdefault("heartbeat_errors", []).append(str(error))
            time.sleep(5.0)

        for entry in running:
            try:
                entry["process"].wait(timeout=30)
            except Exception:
                terminate(entry)

        for entry in running:
            entry["log"].close()
            code = entry["process"].returncode
            summary_path = os.path.join(out_dir, "%s_summary.json" % entry["role"])
            summary = {}
            if os.path.exists(summary_path):
                with open(summary_path) as handle:
                    summary = json.load(handle)
            with open(entry["log_path"], "r", errors="replace") as handle:
                text = handle.read()
            report["roles"][entry["role"]] = {
                "exit_code": code,
                "ok_marker": "PUBLIC_TUNNEL_SOAK_OK" in text,
                "script_error": ("SCRIPT ERROR" in text) or ("Parse Error" in text),
                "summary": summary,
                "log": entry["log_path"],
            }

        responses = [s.get("response_ms", 0) for s in report["health_samples"] if "response_ms" in s]
        responses.sort()
        if responses:
            report["manager_response_p95_ms"] = responses[min(len(responses) - 1, int(len(responses) * 0.95))]
        # Um OK so vale com codigo zero, marcador presente, sem erro de script,
        # sem desconexao e com a partida tendo realmente comecado.
        report["ok"] = all(
            entry["exit_code"] == 0
            and entry["ok_marker"]
            and not entry["script_error"]
            and int(entry["summary"].get("disconnects", 1)) == 0
            and (args.scenario == "lobby" or entry["summary"].get("match_started"))
            for entry in report["roles"].values()
        ) and len(report["roles"]) == args.peers
    finally:
        for entry in running:
            terminate(entry)
        if chaos:
            terminate(chaos)
            chaos["log"].close()
        if room and room.get("code"):
            try:
                http_json("%s/rooms/%s" % (manager, room["code"]), "DELETE", timeout=20)
                report["room_deleted"] = True
            except Exception as error:
                report["room_deleted"] = False
                report["room_delete_error"] = str(error)
        report["finished_at"] = time.time()
        with open(os.path.join(out_dir, "report.json"), "w") as handle:
            json.dump(report, handle, indent=2)

    print("\n=== resumo ===")
    for role, info in report["roles"].items():
        summary = info.get("summary", {})
        print("%-8s exit=%s ok=%s world_applied=%s gap_p95=%sms gap_max=%sms ping_p95=%sms rss=%.1fMB" % (
            role, info["exit_code"], info["ok_marker"],
            summary.get("world_applied"), summary.get("world_gap_p95_ms"),
            summary.get("world_gap_max_ms"), summary.get("ping_p95_ms"),
            float(summary.get("rss_growth_mb", 0.0)),
        ))
    print("manager p95: %sms" % report.get("manager_response_p95_ms"))
    print("relatorio: %s" % os.path.join(out_dir, "report.json"))
    print("PUBLIC_TUNNEL_SOAK_%s" % ("OK" if report["ok"] else "FAIL"))
    return 0 if report["ok"] else 1


if __name__ == "__main__":
    sys.exit(main())
