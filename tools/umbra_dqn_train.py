#!/usr/bin/env python3
"""Treino offline da DQN da UMBRA (24 -> 128 -> 64 -> 23), so numpy.

Entrada: transicoes de tools/umbra_dqn_collect.gd (simulador real da fase 5).
Algoritmo: Double DQN em lote (offline) com penalidade conservadora (CQL-lite)
para nao superestimar acoes que a politica de coleta quase nao usou, mascara
de acoes legais no alvo, desconto por decisao, sem bootstrap em morte e com
bootstrap em fim por tempo. Rede igual a do jogo: LeakyReLU 0,01, saida linear.

Saida: JSON no formato legado (net.0.weight ...), convertido para o contrato
versionado por tools/export_umbra_weights.py --from-json.

python3 tools/umbra_dqn_train.py ".agent_logs/umbra_dqn/fb_*.jsonl" --out .agent_logs/umbra_dqn/dqn_net.json
"""
import argparse
import glob
import json
import random

import numpy as np

N_IN, H1, H2, N_OUT = 24, 128, 64, 23
SLOPE = 0.01


def load(patterns):
    rows = []
    for pat in patterns:
        for path in sorted(glob.glob(pat)):
            with open(path, encoding="utf-8") as f:
                for line in f:
                    line = line.strip()
                    if not line:
                        continue
                    r = json.loads(line)
                    if "record_type" in r or len(r.get("s", [])) != N_IN:
                        continue
                    rows.append(r)
    return rows


def arrays(rows, reward_scale):
    S = np.array([r["s"] for r in rows], dtype=np.float32)
    S2 = np.array([r["s2"] for r in rows], dtype=np.float32)
    A = np.array([r["a"] for r in rows], dtype=np.int64)
    R = np.array([r["r"] for r in rows], dtype=np.float32) * reward_scale
    M = np.array([r["m"] for r in rows], dtype=np.float32)
    M2 = np.array([r["m2"] for r in rows], dtype=np.float32)
    D = np.array([1.0 if r["done"] else 0.0 for r in rows], dtype=np.float32)
    EP = np.array([r["ep"] for r in rows])
    # Garante que a acao executada conta como legal.
    M[np.arange(len(A)), A] = 1.0
    return S, A, R, S2, M, M2, D, EP


class Net:
    def __init__(self, rng):
        def he(o, i):
            return (rng.standard_normal((o, i)) * np.sqrt(2.0 / i)).astype(np.float32)
        self.W = [he(H1, N_IN), he(H2, H1), (rng.standard_normal((N_OUT, H2)) * 0.01).astype(np.float32)]
        self.b = [np.zeros(H1, np.float32), np.zeros(H2, np.float32), np.zeros(N_OUT, np.float32)]
        self.m = [np.zeros_like(x) for x in self.W + self.b]
        self.v = [np.zeros_like(x) for x in self.W + self.b]
        self.t = 0

    def copy(self):
        n = Net.__new__(Net)
        n.W = [w.copy() for w in self.W]
        n.b = [b.copy() for b in self.b]
        return n

    def forward(self, x, keep=False):
        z1 = x @ self.W[0].T + self.b[0]
        a1 = np.where(z1 > 0, z1, SLOPE * z1)
        z2 = a1 @ self.W[1].T + self.b[1]
        a2 = np.where(z2 > 0, z2, SLOPE * z2)
        q = a2 @ self.W[2].T + self.b[2]
        if keep:
            return q, (x, z1, a1, z2, a2)
        return q

    def backward(self, cache, dq):
        x, z1, a1, z2, a2 = cache
        gW2 = dq.T @ a2
        gb2 = dq.sum(0)
        d2 = (dq @ self.W[2]) * np.where(z2 > 0, 1.0, SLOPE)
        gW1 = d2.T @ a1
        gb1 = d2.sum(0)
        d1 = (d2 @ self.W[1]) * np.where(z1 > 0, 1.0, SLOPE)
        gW0 = d1.T @ x
        gb0 = d1.sum(0)
        return [gW0, gW1, gW2, gb0, gb1, gb2]

    def adam(self, grads, lr, wd=1e-5, b1=0.9, b2=0.999, eps=1e-8):
        self.t += 1
        params = self.W + self.b
        for i, (p, g) in enumerate(zip(params, grads)):
            g = g + wd * p
            self.m[i] = b1 * self.m[i] + (1 - b1) * g
            self.v[i] = b2 * self.v[i] + (1 - b2) * g * g
            mh = self.m[i] / (1 - b1 ** self.t)
            vh = self.v[i] / (1 - b2 ** self.t)
            p -= lr * mh / (np.sqrt(vh) + eps)

    def soft_update(self, other, tau):
        for a, b in zip(self.W + self.b, other.W + other.b):
            a *= (1 - tau)
            a += tau * b


def masked_max_arg(q, mask):
    qq = np.where(mask > 0.5, q, -1e9)
    return qq.argmax(1)


def train(args):
    rows = load(args.inputs)
    if not rows:
        raise SystemExit("sem transicoes")
    S, A, R, S2, M, M2, D, EP = arrays(rows, args.reward_scale)
    eps_ids = sorted(set(EP.tolist()))
    rnd = random.Random(args.seed)
    rnd.shuffle(eps_ids)
    val_eps = set(eps_ids[: max(1, len(eps_ids) // 8)])
    is_val = np.array([e in val_eps for e in EP])
    tr = np.where(~is_val)[0]
    va = np.where(is_val)[0]
    rng = np.random.default_rng(args.seed)
    net = Net(rng)
    tgt = net.copy()
    n = len(tr)
    print("transicoes=%d treino=%d validacao=%d episodios=%d r_media=%.4f r_std=%.4f" % (len(rows), n, len(va), len(eps_ids), R.mean(), R.std()))
    log = []
    for step in range(1, args.steps + 1):
        idx = tr[rng.integers(0, n, args.batch)]
        s, a, r, s2, m, m2, d = S[idx], A[idx], R[idx], S2[idx], M[idx], M2[idx], D[idx]
        q, cache = net.forward(s, keep=True)
        # Double DQN: escolhe com a rede online, avalia com a alvo, so acoes legais.
        q2_online = net.forward(s2)
        a2 = masked_max_arg(q2_online, m2)
        q2_t = tgt.forward(s2)[np.arange(len(a2)), a2]
        has_next = m2.sum(1) > 0
        y = r + args.gamma * (1.0 - d) * np.where(has_next, q2_t, 0.0)
        qa = q[np.arange(len(a)), a]
        td = qa - y
        huber = np.where(np.abs(td) < 1.0, td, np.sign(td))
        dq = np.zeros_like(q)
        dq[np.arange(len(a)), a] = huber / len(a)
        # CQL-lite: empurra para baixo o logsumexp das acoes legais e para cima a executada.
        if args.cql > 0:
            qm = np.where(m > 0.5, q, -1e9)
            mx = qm.max(1, keepdims=True)
            ex = np.exp(qm - mx) * (m > 0.5)
            sm = ex / np.maximum(ex.sum(1, keepdims=True), 1e-9)
            dq += args.cql * sm / len(a)
            dq[np.arange(len(a)), a] -= args.cql / len(a)
        grads = net.backward(cache, dq)
        net.adam(grads, args.lr)
        tgt.soft_update(net, args.tau)
        if step % 1000 == 0 or step == args.steps:
            def td_loss(ids):
                qv = net.forward(S[ids])[np.arange(len(ids)), A[ids]]
                a2v = masked_max_arg(net.forward(S2[ids]), M2[ids])
                q2v = tgt.forward(S2[ids])[np.arange(len(ids)), a2v]
                yv = R[ids] + args.gamma * (1.0 - D[ids]) * np.where(M2[ids].sum(1) > 0, q2v, 0.0)
                return float(np.mean((qv - yv) ** 2))
            qall = net.forward(S[va])
            greedy = masked_max_arg(qall, M[va])
            agree = float(np.mean(greedy == A[va]))
            adv = qall - np.where(M[va] > 0.5, qall, 0).sum(1, keepdims=True) / np.maximum(M[va].sum(1, keepdims=True), 1)
            adv_std = float(np.std(adv[M[va] > 0.5]))
            entry = {"step": step, "td_train": td_loss(tr[:4000]), "td_val": td_loss(va), "agree_val": agree, "adv_std": adv_std}
            log.append(entry)
            print("passo %6d  td_treino %.5f  td_val %.5f  igual_coleta %.2f  desvio_vantagem %.3f" % (step, entry["td_train"], entry["td_val"], agree, adv_std))
    out = {
        "net.0.weight": net.W[0].tolist(), "net.0.bias": net.b[0].tolist(),
        "net.2.weight": net.W[1].tolist(), "net.2.bias": net.b[1].tolist(),
        "net.4.weight": net.W[2].tolist(), "net.4.bias": net.b[2].tolist(),
        "training": {"algorithm": "offline_double_dqn_cql_lite_numpy", "transitions": len(rows), "episodes": len(eps_ids),
                      "gamma": args.gamma, "reward_scale": args.reward_scale, "cql": args.cql, "steps": args.steps,
                      "seed": args.seed, "log": log[-5:], "inputs": args.inputs},
    }
    with open(args.out, "w", encoding="utf-8") as f:
        json.dump(out, f)
    print("salvo", args.out)


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("inputs", nargs="+")
    ap.add_argument("--out", default=".agent_logs/umbra_dqn/dqn_net.json")
    ap.add_argument("--steps", type=int, default=20000)
    ap.add_argument("--batch", type=int, default=256)
    ap.add_argument("--lr", type=float, default=5e-4)
    ap.add_argument("--gamma", type=float, default=0.9)
    ap.add_argument("--tau", type=float, default=0.005)
    ap.add_argument("--cql", type=float, default=0.5)
    ap.add_argument("--reward_scale", type=float, default=10.0)
    ap.add_argument("--seed", type=int, default=7)
    train(ap.parse_args())
