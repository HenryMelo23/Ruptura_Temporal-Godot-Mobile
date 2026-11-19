#!/usr/bin/env python3
"""Proxy UDP que degrada o tunel de propósito, para a matriz de rede.

Fica entre os peers e a sala: perda, atraso, jitter, rajada e reordenação
aplicados em datagramas de verdade, então o ENet enxerga perda real e
retransmite de verdade — que é o que a hipótese de head-of-line blocking
precisa para ser confirmada ou descartada.

Não precisa de root e não encosta em interface nenhuma: é só um socket.
Use SOMENTE contra o ambiente isolado.

uso:
  python3 tools/udp_chaos_proxy.py --listen 24999 --target 127.0.0.1:24522 \\
      --loss 0.01 --delay-ms 50 --jitter-ms 20 --burst-loss 0.03 --burst-ms 400
"""
import argparse
import random
import socket
import threading
import time

STATS = {"in": 0, "out": 0, "dropped": 0, "delayed": 0}


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--listen", type=int, required=True)
    parser.add_argument("--target", required=True, help="host:porta da sala")
    parser.add_argument("--bind", default="127.0.0.1")
    parser.add_argument("--loss", type=float, default=0.0, help="perda aleatoria 0..1")
    parser.add_argument("--delay-ms", type=float, default=0.0)
    parser.add_argument("--jitter-ms", type=float, default=0.0)
    parser.add_argument("--reorder", type=float, default=0.0, help="chance de atrasar so um datagrama")
    parser.add_argument("--burst-loss", type=float, default=0.0, help="perda dentro da rajada")
    parser.add_argument("--burst-ms", type=float, default=0.0, help="duracao da rajada")
    parser.add_argument("--burst-every-ms", type=float, default=10000.0)
    parser.add_argument("--blackout-at-ms", type=float, default=0.0, help="corte total a partir de")
    parser.add_argument("--blackout-ms", type=float, default=0.0)
    parser.add_argument("--seed", type=int, default=7)
    parser.add_argument("--stats-every-ms", type=float, default=5000.0)
    args = parser.parse_args()

    rng = random.Random(args.seed)
    host, port = args.target.rsplit(":", 1)
    target = (host, int(port))

    upstream = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    upstream.bind((args.bind, args.listen))
    # Um socket por cliente para a sala responder no lugar certo.
    downstream = {}
    started = time.time()
    lock = threading.Lock()

    def now_ms():
        return (time.time() - started) * 1000.0

    def impaired(at_ms):
        if args.blackout_ms > 0.0 and args.blackout_at_ms <= at_ms < args.blackout_at_ms + args.blackout_ms:
            return "blackout"
        if args.burst_ms > 0.0 and (at_ms % args.burst_every_ms) < args.burst_ms:
            return "burst"
        return "normal"

    def should_drop(at_ms):
        state = impaired(at_ms)
        if state == "blackout":
            return True
        loss = args.burst_loss if state == "burst" else args.loss
        return loss > 0.0 and rng.random() < loss

    def hold_ms(at_ms):
        base = args.delay_ms
        if args.jitter_ms > 0.0:
            base += rng.uniform(-args.jitter_ms, args.jitter_ms)
        if args.reorder > 0.0 and rng.random() < args.reorder:
            base += rng.uniform(20.0, 90.0)
        return max(0.0, base)

    def forward(sock, data, addr):
        delay = hold_ms(now_ms())
        if delay <= 0.5:
            sock.sendto(data, addr)
            return
        with lock:
            STATS["delayed"] += 1
        threading.Timer(delay / 1000.0, lambda: _safe_send(sock, data, addr)).start()

    def _safe_send(sock, data, addr):
        try:
            sock.sendto(data, addr)
        except Exception:
            pass

    def pump_back(client_addr, sock):
        while True:
            try:
                data, _ = sock.recvfrom(65535)
            except Exception:
                return
            with lock:
                STATS["out"] += 1
            if should_drop(now_ms()):
                with lock:
                    STATS["dropped"] += 1
                continue
            forward(upstream, data, client_addr)

    def report():
        while True:
            time.sleep(args.stats_every_ms / 1000.0)
            with lock:
                print("CHAOS t=%.1fs in=%d out=%d dropped=%d delayed=%d estado=%s" % (
                    now_ms() / 1000.0, STATS["in"], STATS["out"], STATS["dropped"],
                    STATS["delayed"], impaired(now_ms())), flush=True)

    threading.Thread(target=report, daemon=True).start()
    print("CHAOS ouvindo %s:%d -> %s:%d perda=%.3f atraso=%.0fms jitter=%.0fms" % (
        args.bind, args.listen, target[0], target[1], args.loss, args.delay_ms, args.jitter_ms), flush=True)

    while True:
        data, client_addr = upstream.recvfrom(65535)
        with lock:
            STATS["in"] += 1
        if client_addr not in downstream:
            sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
            sock.bind((args.bind, 0))
            downstream[client_addr] = sock
            threading.Thread(target=pump_back, args=(client_addr, sock), daemon=True).start()
        if should_drop(now_ms()):
            with lock:
                STATS["dropped"] += 1
            continue
        forward(downstream[client_addr], data, target)


if __name__ == "__main__":
    main()
