#!/usr/bin/env python3
"""Exercise real public relay rooms using isolated test results and saves."""
import argparse
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import tempfile
import time
from urllib.error import HTTPError
from urllib.request import Request, urlopen

ROOT = Path(__file__).resolve().parents[1]
ERROR = re.compile(r"SCRIPT ERROR:|ERROR:|Assertion failed|leaked at exit")


def request(base, method, route, body=None):
    data = None if body is None else json.dumps(body).encode()
    req = Request(base + route, data=data, method=method, headers={"Content-Type": "application/json"})
    with urlopen(req, timeout=25) as reply:
        return json.load(reply)


def run(base, name, script, ping_budget):
    folder = Path(tempfile.mkdtemp(prefix=f"ruptura-public-{name}-"))
    room = request(base, "POST", "/rooms", {"name": "Release244-" + name})
    code = room["code"]
    processes, logs = [], []
    print(f"START {name} room={code} logs={folder}", flush=True)
    try:
        request(base, "POST", f"/rooms/{code}/heartbeat", {"role": "owner", "mode": "lobby_online_host", "peer_id": 1})
        for role in ["host", "client"]:
            if role == "client":
                request(base, "POST", f"/rooms/{code}/join", {})
            output = (folder / f"{role}.log").open("w")
            logs.append(output)
            args = [shutil.which("godot") or "godot", "--headless", "--path", str(ROOT),
                    "--script", f"res://tests/{script}.gd", "--", f"--role={role}",
                    f"--host={room['host']}", f"--port={room['port']}",
                    f"--scenario={name}", "--external-server", f"--result-dir={folder}",
                    f"--ping-budget={ping_budget}"]
            processes.append((role, subprocess.Popen(args, cwd=ROOT,
                env=dict(os.environ, XDG_DATA_HOME=str(folder / role)), stdout=output, stderr=subprocess.STDOUT)))
            time.sleep(0.8)
        deadline = time.monotonic() + 90
        for role, process in processes:
            rc = process.wait(timeout=max(1, deadline - time.monotonic()))
            content = (folder / f"{role}.log").read_text()
            prefix = "gameplay_authority_" if name == "gameplay" else ""
            result = folder / f"{prefix}{role}_result.txt"
            if rc != 0 or ERROR.search(content) or not result.is_file() or not result.read_text().startswith("OK"):
                raise RuntimeError(f"{name}/{role} exit={rc}\n{content}")
            for line in content.splitlines():
                if "_OK" in line or "ping_min_ms=" in line:
                    print(line, flush=True)
        print(f"PASS {name} logs={folder}", flush=True)
    finally:
        for _, process in processes:
            if process.poll() is None:
                process.terminate()
                try:
                    process.wait(timeout=5)
                except subprocess.TimeoutExpired:
                    process.kill()
                    process.wait()
        for output in logs:
            output.close()
        try:
            request(base, "DELETE", f"/rooms/{code}")
        except HTTPError as exc:
            if exc.code != 404:
                raise


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--manager", default="http://72.61.217.238:8090")
    parser.add_argument("--version", required=True)
    parser.add_argument("--ping-budget", type=int, default=150)
    args = parser.parse_args()
    health = request(args.manager, "GET", "/health")
    if not health.get("ok") or health.get("project", {}).get("version") != args.version:
        raise SystemExit("Public relay does not match requested version")
    for scenario in ["ready", "spectator"]:
        run(args.manager, scenario, "multiplayer_lobby_integration_smoke", args.ping_budget)
    run(args.manager, "gameplay", "multiplayer_gameplay_authority_smoke", args.ping_budget)
    if not request(args.manager, "GET", "/health").get("ok"):
        raise SystemExit("Public relay unhealthy after tests")
    print("PUBLIC_RELEASE_SMOKE_OK ready spectator gameplay")
