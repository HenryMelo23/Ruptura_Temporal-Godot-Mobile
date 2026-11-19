#!/usr/bin/env python3
"""Gera os mapas de distancia (SDF) de colisao dos objetos pintados nos atlas de chao.

Fonte: tools/map_collision_shapes.json  ->  {map_key: {ladrilho: [forma, ...]}}
  forma: {"p": [[u, v], ...]} (poligono) ou {"c": [u, v, r]} (circulo)
  u, v em coordenadas do ladrilho COMO APARECE NO JOGO (o shader do chao mostra so o
  miolo de 81% de cada ladrilho do atlas; tools/map_collision_preview.py desenha as
  formas por cima desse recorte para conferir).

Saida: assets/sprites/experimental/collision/<map_key>.png, 384x384 (4x4 ladrilhos de
96 px; 1 texel = 4 unidades do mundo). Distancia com sinal em unidades do mundo
(positivo fora do objeto) codificada em 16 bits: R*256+G = d*32 + 32768.

Uso: python3 tools/build_map_collision.py
"""
import json
import os
import numpy as np
from PIL import Image, ImageDraw

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
SHAPES = os.path.join(ROOT, "tools", "map_collision_shapes.json")
OUT_DIR = os.path.join(ROOT, "assets", "sprites", "experimental", "collision")
CHUNK = 384.0
RES = 96            # texels por ladrilho
MASK = 384          # mascara em 1 unidade do mundo por pixel
FAR = 1000.0


def tile_mask(shapes):
    im = Image.new("L", (MASK, MASK), 0)
    d = ImageDraw.Draw(im)
    for s in shapes:
        if "p" in s:
            d.polygon([(u * MASK, v * MASK) for u, v in s["p"]], fill=255)
        else:
            u, v, r = s["c"]
            d.ellipse([(u - r) * MASK, (v - r) * MASK, (u + r) * MASK, (v + r) * MASK], fill=255)
    return np.asarray(im) > 127


def boundary_points(mask):
    m = mask
    pad = np.pad(m, 1, constant_values=False)
    inner = pad[1:-1, 1:-1]
    edge = inner & ~(pad[:-2, 1:-1] & pad[2:, 1:-1] & pad[1:-1, :-2] & pad[1:-1, 2:])
    ys, xs = np.nonzero(edge)
    return np.stack([xs + 0.5, ys + 0.5], axis=1).astype(np.float32)


def tile_sdf(shapes):
    if not shapes:
        return np.full((RES, RES), FAR, dtype=np.float32)
    mask = tile_mask(shapes)
    pts = boundary_points(mask)
    step = MASK / RES
    gx, gy = np.meshgrid((np.arange(RES) + 0.5) * step, (np.arange(RES) + 0.5) * step)
    q = np.stack([gx.ravel(), gy.ravel()], axis=1).astype(np.float32)
    best = np.full(len(q), np.inf, dtype=np.float32)
    for i in range(0, len(pts), 512):
        chunk = pts[i:i + 512]
        dd = ((q[:, None, :] - chunk[None, :, :]) ** 2).sum(axis=2)
        best = np.minimum(best, dd.min(axis=1))
    dist = np.sqrt(best).reshape(RES, RES) * (CHUNK / MASK)
    inside = mask[(gy.astype(int)).clip(0, MASK - 1), (gx.astype(int)).clip(0, MASK - 1)]
    return np.where(inside, -dist, dist).astype(np.float32)


def encode(sdf):
    v = np.clip(np.round(sdf * 32.0 + 32768.0), 0, 65535).astype(np.uint32)
    rgb = np.zeros(sdf.shape + (3,), dtype=np.uint8)
    rgb[..., 0] = (v >> 8) & 255
    rgb[..., 1] = v & 255
    return rgb


def main():
    data = json.load(open(SHAPES, encoding="utf-8"))
    os.makedirs(OUT_DIR, exist_ok=True)
    for key, tiles in data.items():
        atlas = np.zeros((RES * 4, RES * 4, 3), dtype=np.uint8)
        for t in range(16):
            sdf = tile_sdf(tiles.get(str(t), []))
            tx, ty = t % 4, t // 4
            atlas[ty * RES:(ty + 1) * RES, tx * RES:(tx + 1) * RES] = encode(sdf)
        Image.fromarray(atlas, "RGB").save(os.path.join(OUT_DIR, key + ".png"))
        print("ok", key, sum(len(v) for v in tiles.values()), "formas")


if __name__ == "__main__":
    main()
