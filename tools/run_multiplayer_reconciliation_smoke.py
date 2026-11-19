#!/usr/bin/env python3
"""Local ENet regression battery; isolated saves/results, no public relay access."""
import os
from pathlib import Path
import re
import shutil
import socket
import subprocess
import tempfile
import time

ROOT = Path(__file__).resolve().parents[1]
ERROR = re.compile(r"SCRIPT ERROR:|ERROR:|Assertion failed|leaked at exit")


def run_scenario(name, script, roles, scenario="ready"):
    folder = Path(tempfile.mkdtemp(prefix=f"ruptura-net-{name}-"))
    with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as sock:
        sock.bind(("127.0.0.1", 0))
        port = sock.getsockname()[1]
    processes = []
    logs = []
    print(f"START {name} logs={folder}", flush=True)
    try:
        for role in roles:
            output = (folder / f"{role}.log").open("w")
            logs.append(output)
            env = dict(os.environ, XDG_DATA_HOME=str(folder / role))
            process = subprocess.Popen([
                os.environ.get("GODOT_BIN", shutil.which("godot") or "godot"),
                "--headless", "--path", str(ROOT), "--script", f"res://tests/{script}.gd",
                "--", f"--role={role}", f"--scenario={scenario}", f"--port={port}",
                f"--result-dir={folder}",
            ], cwd=ROOT, env=env, stdout=output, stderr=subprocess.STDOUT)
            processes.append((role, process))
            # Give the dedicated process its startup lead, as in the PS runner.
            time.sleep(1.2 if role == "server" else 0.8)
        deadline = time.monotonic() + 80
        for role, process in processes:
            code = process.wait(timeout=max(1, deadline - time.monotonic()))
            content = (folder / f"{role}.log").read_text()
            result = folder / f"{role}_result.txt"
            if not result.is_file():
                prefixed_results = list(folder.glob(f"*_{role}_result.txt"))
                if len(prefixed_results) == 1:
                    result = prefixed_results[0]
            if code != 0 or ERROR.search(content) or not result.is_file() or not result.read_text().startswith("OK"):
                raise RuntimeError(f"{name}/{role} exit={code}\n{content}")
        print(f"PASS {name} roles={','.join(roles)} logs={folder}", flush=True)
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


if __name__ == "__main__":
    trio = ["server", "host", "client"]
    run_scenario("ready", "multiplayer_lobby_integration_smoke", trio)
    run_scenario("spectator", "multiplayer_lobby_integration_smoke", trio, "spectator")
    run_scenario("owner_leave", "multiplayer_lobby_integration_smoke", trio, "owner_leave")
    run_scenario("shop", "multiplayer_shop_wire_smoke", trio)
    run_scenario("boss1-rewind", "multiplayer_boss1_rewind_wire_smoke", trio)
    run_scenario("death-cycle", "multiplayer_death_cycle_wire_smoke", trio)
    run_scenario("deck", "multiplayer_deck_wire_smoke", trio)
    run_scenario("lacerante-execution", "multiplayer_lacerante_execution_wire_smoke", trio)
    run_scenario("score-boss-entry", "multiplayer_score_boss_entry_wire_smoke", trio)
    run_scenario("world-shop", "multiplayer_world_interaction_smoke", trio, "shop")
    run_scenario("boss-aftermath", "multiplayer_world_interaction_smoke", trio, "aftermath")
    run_scenario("team-chips", "multiplayer_world_interaction_smoke", trio, "chips")
    run_scenario("phase8", "multiplayer_world_interaction_smoke", trio, "phase8")
    run_scenario("phase9", "multiplayer_world_interaction_smoke", trio, "phase9")
    run_scenario("match", "multiplayer_integration_smoke", trio + ["client2"])
    print("MULTIPLAYER_RECONCILIATION_OK ready spectator shop boss1-rewind death-cycle deck lacerante-execution score-boss-entry world-shop boss-aftermath team-chips phase8 phase9 manifestation spectrum match")
