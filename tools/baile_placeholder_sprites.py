#!/usr/bin/env python3
"""Arte PROVISORIA da Fase 10 (Bailao da Dona Boleta).

Gera placeholders legiveis para o pipeline de texturas funcionar antes da arte
final (que vem pelo fluxo do Codex). Trocar os PNGs por frames definitivos nao
exige mudar a logica: so manter nomes, tamanho de canvas e pivo (pes no centro
inferior do canvas).

Uso: python3 tools/baile_placeholder_sprites.py
Saida: assets/sprites/baile/*.png e assets/sprites/experimental/phase_ex10_terrain_atlas.png
"""
from __future__ import annotations

import math
import random
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "assets" / "sprites" / "baile"
ATLAS = ROOT / "assets" / "sprites" / "experimental" / "phase_ex10_terrain_atlas.png"

SS = 2  # supersampling

SPECIES = {
    # nome: (asa superior, asa inferior, veio/borda, detalhe)
    "monarca": ((236, 122, 28), (214, 96, 20), (26, 16, 12), "dots"),
    "garrafeira": ((120, 96, 78), (92, 74, 60), (40, 30, 26), "eyes"),
    "sombrinha": ((214, 232, 236), (196, 220, 228), (40, 30, 34), "glass"),
    "paredinha": ((168, 70, 44), (140, 56, 36), (54, 26, 20), "tri"),
    "hype": ((40, 120, 236), (30, 92, 206), (10, 20, 46), "shine"),
    "dancarina": ((226, 60, 150), (190, 40, 124), (40, 12, 30), "dots"),
}


def _wing(d: ImageDraw.ImageDraw, cx: float, cy: float, sx: float, sy: float, side: int, upper: bool, col, edge, open_k: float) -> list:
    if upper:
        pts = [(0, 0), (0.25, -0.95), (1.0, -1.05), (1.05, -0.35), (0.55, 0.05)]
    else:
        pts = [(0, 0.05), (0.7, 0.1), (0.85, 0.7), (0.4, 0.95), (0.05, 0.55)]
    poly = [(cx + side * x * sx * open_k, cy + y * sy) for x, y in pts]
    d.polygon(poly, fill=col + (255,) if len(col) == 3 else col, outline=edge + (255,))
    d.line(poly + [poly[0]], fill=edge + (255,), width=3 * SS)
    return poly


def butterfly(species: str, size: int, flap: float, pose: str) -> Image.Image:
    up, low, edge, detail = SPECIES[species]
    s = size * SS
    img = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    cx, cy = s * 0.5, s * 0.52
    wx, wy = s * 0.36, s * 0.3
    open_k = {"idle": 0.75 + 0.25 * flap, "attack": 0.6, "drop": 1.0}.get(pose, 0.8)
    alpha_up = up + (150,) if detail == "glass" else up
    alpha_low = low + (140,) if detail == "glass" else low
    for side in (-1, 1):
        pu = _wing(d, cx, cy, wx, wy, side, True, alpha_up, edge, open_k)
        pl = _wing(d, cx, cy + s * 0.02, wx * 0.8, wy * 0.85, side, False, alpha_low, edge, open_k)
        if detail == "dots":
            for k in range(4):
                px = cx + side * wx * open_k * (0.55 + 0.12 * k)
                d.ellipse([px - 4 * SS, cy - wy * (0.85 - 0.12 * k) - 4 * SS, px + 4 * SS, cy - wy * (0.85 - 0.12 * k) + 4 * SS], fill=(250, 246, 236, 255))
        elif detail == "eyes":
            ex, ey = cx + side * wx * open_k * 0.55, cy + wy * 0.45
            d.ellipse([ex - 15 * SS, ey - 15 * SS, ex + 15 * SS, ey + 15 * SS], fill=(230, 186, 60, 255), outline=edge + (255,), width=2 * SS)
            d.ellipse([ex - 7 * SS, ey - 7 * SS, ex + 7 * SS, ey + 7 * SS], fill=(16, 12, 10, 255))
        elif detail == "tri":
            tx, ty = cx + side * wx * open_k * 0.6, cy - wy * 0.45
            d.polygon([(tx, ty - 10 * SS), (tx + side * 12 * SS, ty + 8 * SS), (tx - side * 6 * SS, ty + 8 * SS)], fill=(246, 236, 214, 255))
        elif detail == "shine":
            d.line([pu[1], pu[3]], fill=(150, 220, 255, 255), width=4 * SS)
    # corpo
    d.ellipse([cx - 8 * SS, cy - s * 0.2, cx + 8 * SS, cy + s * 0.2], fill=(28, 20, 22, 255))
    d.ellipse([cx - 13 * SS, cy - s * 0.27, cx + 13 * SS, cy - s * 0.15], fill=(36, 26, 28, 255))
    # antenas
    hy = cy - s * 0.24
    for side in (-1, 1):
        d.line([(cx + side * 4 * SS, hy - 4 * SS), (cx + side * 18 * SS, hy - 26 * SS)], fill=(28, 20, 22, 255), width=2 * SS)
        d.ellipse([cx + side * 18 * SS - 3 * SS, hy - 29 * SS, cx + side * 18 * SS + 3 * SS, hy - 23 * SS], fill=(28, 20, 22, 255))
    # oculos Juliet: lentes ovais escuras com aro dourado e ponte reta
    for side in (-1, 1):
        lx = cx + side * 7 * SS
        d.ellipse([lx - 8 * SS, hy - 3 * SS, lx + 8 * SS, hy + 6 * SS], fill=(20, 10, 40, 255), outline=(236, 196, 72, 255), width=2 * SS)
        d.line([(lx - 3 * SS, hy - 1 * SS), (lx + 1 * SS, hy + 1 * SS)], fill=(190, 140, 255, 255), width=1 * SS)
    d.line([(cx - 3 * SS, hy), (cx + 3 * SS, hy)], fill=(236, 196, 72, 255), width=2 * SS)
    # corrente de ouro
    d.arc([cx - 12 * SS, cy - s * 0.17, cx + 12 * SS, cy - s * 0.06], 10, 170, fill=(246, 206, 70, 255), width=3 * SS)
    if species == "sombrinha":
        ux, uy = cx + 22 * SS, cy - s * 0.36
        d.pieslice([ux - 40 * SS, uy - 26 * SS, ux + 40 * SS, uy + 26 * SS], 180, 360, fill=(236, 70, 140, 255), outline=(60, 20, 40, 255), width=2 * SS)
        for k in range(-2, 3):
            d.line([(ux, uy), (ux + k * 16 * SS, uy)], fill=(120, 30, 70, 255), width=1 * SS)
        d.line([(ux, uy), (ux, uy + 40 * SS)], fill=(60, 40, 30, 255), width=3 * SS)
    if species == "paredinha":
        bx, by = cx, cy + s * 0.24
        d.rectangle([bx - 18 * SS, by - 14 * SS, bx + 18 * SS, by + 14 * SS], fill=(30, 28, 32, 255), outline=(240, 70, 160, 255), width=2 * SS)
        d.ellipse([bx - 9 * SS, by - 9 * SS, bx + 9 * SS, by + 9 * SS], fill=(70, 66, 72, 255))
    if species == "hype":
        d.rectangle([cx - 14 * SS, hy - 16 * SS, cx + 14 * SS, hy - 8 * SS], fill=(246, 206, 70, 255))
    if species == "garrafeira" and pose == "attack":
        bx, by = cx + 34 * SS, cy - s * 0.3
        d.rectangle([bx - 5 * SS, by - 18 * SS, bx + 5 * SS, by + 12 * SS], fill=(150, 96, 30, 230))
        d.rectangle([bx - 2 * SS, by - 26 * SS, bx + 2 * SS, by - 18 * SS], fill=(150, 96, 30, 230))
    return img.resize((size, size), Image.LANCZOS)


def boss(frame: str, k: int) -> Image.Image:
    w, h = 360 * SS, 300 * SS
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    cx, cy = w * 0.5, h * 0.55
    flap = 0.5 + 0.5 * math.sin(k * math.pi * 0.5)
    open_k = 0.8 + 0.2 * flap
    if frame in ("attack", "roda"):
        open_k = 1.0
    if frame == "daze":
        open_k = 0.55
    if frame == "death":
        open_k = 0.4 + 0.1 * k
    up, low, edge = (118, 40, 168), (84, 26, 128), (34, 10, 46)
    for side in (-1, 1):
        _wing(d, cx, cy, w * 0.42, h * 0.42, side, True, up, edge, open_k)
        _wing(d, cx, cy + 10 * SS, w * 0.34, h * 0.34, side, False, low, edge, open_k)
        for r in range(3):
            ex = cx + side * w * 0.42 * open_k * (0.4 + 0.2 * r)
            ey = cy - h * 0.42 * (0.55 - 0.1 * r)
            d.ellipse([ex - 12 * SS, ey - 12 * SS, ex + 12 * SS, ey + 12 * SS], fill=(246, 196, 64, 255), outline=edge + (255,), width=2 * SS)
    # casaco de pelucia (perde no remix: frame "remix")
    if frame != "remix":
        d.ellipse([cx - 52 * SS, cy - 50 * SS, cx + 52 * SS, cy + 80 * SS], fill=(246, 150, 196, 255))
        for a in range(0, 360, 30):
            px = cx + math.cos(math.radians(a)) * 50 * SS
            py = cy + 15 * SS + math.sin(math.radians(a)) * 64 * SS
            d.ellipse([px - 10 * SS, py - 10 * SS, px + 10 * SS, py + 10 * SS], fill=(252, 186, 220, 255))
    d.ellipse([cx - 20 * SS, cy - 70 * SS, cx + 20 * SS, cy + 70 * SS], fill=(30, 18, 30, 255))
    hy = cy - 86 * SS
    d.ellipse([cx - 30 * SS, hy - 26 * SS, cx + 30 * SS, hy + 26 * SS], fill=(40, 24, 36, 255))
    # coroa
    d.polygon([(cx - 26 * SS, hy - 20 * SS), (cx - 18 * SS, hy - 46 * SS), (cx - 6 * SS, hy - 26 * SS), (cx, hy - 52 * SS), (cx + 6 * SS, hy - 26 * SS), (cx + 18 * SS, hy - 46 * SS), (cx + 26 * SS, hy - 20 * SS)], fill=(250, 210, 70, 255))
    # oculos Juliet espelhados
    for side in (-1, 1):
        lx = cx + side * 15 * SS
        d.ellipse([lx - 16 * SS, hy - 8 * SS, lx + 16 * SS, hy + 10 * SS], fill=(150, 220, 255, 255), outline=(250, 210, 70, 255), width=3 * SS)
        d.line([(lx - 8 * SS, hy - 4 * SS), (lx + 4 * SS, hy + 4 * SS)], fill=(255, 255, 255, 255), width=2 * SS)
    # microfone
    mx, my = cx + 44 * SS, hy + 20 * SS
    if frame in ("attack", "sing", "roda"):
        mx, my = cx + 26 * SS, hy + 26 * SS
    d.line([(mx, my), (mx + 10 * SS, my + 46 * SS)], fill=(200, 200, 210, 255), width=6 * SS)
    d.ellipse([mx - 12 * SS, my - 14 * SS, mx + 12 * SS, my + 10 * SS], fill=(230, 230, 240, 255), outline=(250, 210, 70, 255), width=2 * SS)
    if frame == "sing" or frame == "roda":
        for r in range(3):
            rr = (22 + 16 * r + 6 * k) * SS
            d.arc([mx - rr, my - rr, mx + rr, my + rr], 290, 350, fill=(250, 120, 200, 200), width=3 * SS)
    if frame == "daze":
        for a in range(0, 360, 72):
            px = cx + math.cos(math.radians(a + k * 30)) * 40 * SS
            py = hy - 50 * SS + math.sin(math.radians(a + k * 30)) * 12 * SS
            d.ellipse([px - 6 * SS, py - 6 * SS, px + 6 * SS, py + 6 * SS], fill=(250, 230, 90, 255))
    out = img.resize((360, 300), Image.LANCZOS)
    if frame == "death":
        out.putalpha(out.getchannel("A").point(lambda v: int(v * (1.0 - 0.2 * k))))
    return out


def lagartona_head(k: int, pose: str) -> Image.Image:
    s = 170 * SS
    img = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    cx, cy = s * 0.5, s * 0.58
    bob = math.sin(k * math.pi * 0.5) * 6 * SS
    d.ellipse([cx - 66 * SS, cy - 56 * SS + bob, cx + 66 * SS, cy + 56 * SS + bob], fill=(126, 190, 52, 255), outline=(30, 50, 14, 255), width=4 * SS)
    for side in (-1, 1):
        lx = cx + side * 24 * SS
        d.ellipse([lx - 20 * SS, cy - 26 * SS + bob, lx + 20 * SS, cy + 4 * SS + bob], fill=(18, 10, 30, 255), outline=(240, 200, 70, 255), width=3 * SS)
    d.line([(cx - 6 * SS, cy - 12 * SS + bob), (cx + 6 * SS, cy - 12 * SS + bob)], fill=(240, 200, 70, 255), width=3 * SS)
    mouth_open = 22 if pose in ("attack", "roar") else 8
    d.ellipse([cx - 24 * SS, cy + 16 * SS + bob, cx + 24 * SS, cy + (16 + mouth_open) * SS + bob], fill=(60, 10, 30, 255))
    for side in (-1, 1):
        d.line([(cx + side * 30 * SS, cy - 50 * SS + bob), (cx + side * 50 * SS, cy - 80 * SS + bob)], fill=(30, 50, 14, 255), width=4 * SS)
    if pose == "daze":
        for a in range(0, 360, 90):
            px = cx + math.cos(math.radians(a + k * 40)) * 40 * SS
            py = cy - 70 * SS + math.sin(math.radians(a + k * 40)) * 10 * SS
            d.ellipse([px - 6 * SS, py - 6 * SS, px + 6 * SS, py + 6 * SS], fill=(250, 230, 90, 255))
    return img.resize((170, 170), Image.LANCZOS)


def lagartona_segment(lit: bool, cocoon: bool) -> Image.Image:
    s = 130 * SS
    img = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    cx, cy = s * 0.5, s * 0.55
    if cocoon:
        d.ellipse([cx - 56 * SS, cy - 52 * SS, cx + 56 * SS, cy + 52 * SS], fill=(214, 206, 180, 255), outline=(120, 110, 90, 255), width=4 * SS)
        for k in range(-3, 4):
            d.arc([cx - 56 * SS, cy - 52 * SS + k * 12 * SS, cx + 56 * SS, cy + 52 * SS + k * 12 * SS], 200, 340, fill=(170, 160, 136, 255), width=2 * SS)
        return img.resize((130, 130), Image.LANCZOS)
    d.ellipse([cx - 54 * SS, cy - 46 * SS, cx + 54 * SS, cy + 46 * SS], fill=(110, 170, 46, 255), outline=(30, 50, 14, 255), width=4 * SS)
    d.rectangle([cx - 36 * SS, cy - 56 * SS, cx + 36 * SS, cy + 8 * SS], fill=(26, 24, 30, 255), outline=(240, 70, 160, 255) if lit else (90, 60, 80, 255), width=3 * SS)
    cone = (255, 120, 210, 255) if lit else (70, 66, 74, 255)
    d.ellipse([cx - 22 * SS, cy - 46 * SS, cx + 22 * SS, cy - 2 * SS], fill=cone, outline=(10, 10, 12, 255), width=2 * SS)
    d.ellipse([cx - 8 * SS, cy - 32 * SS, cx + 8 * SS, cy - 16 * SS], fill=(20, 18, 22, 255))
    return img.resize((130, 130), Image.LANCZOS)


def bottle(kind: str) -> Image.Image:
    s = 48 * SS
    img = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    col = {"whisky": (176, 104, 30, 235), "gin": (150, 220, 200, 200), "vodka": (226, 236, 246, 210)}[kind]
    cx = s * 0.5
    d.rounded_rectangle([cx - 9 * SS, 18 * SS, cx + 9 * SS, 44 * SS], radius=4 * SS, fill=col, outline=(30, 24, 20, 255), width=2 * SS)
    d.rectangle([cx - 4 * SS, 6 * SS, cx + 4 * SS, 18 * SS], fill=col, outline=(30, 24, 20, 255), width=2 * SS)
    d.rectangle([cx - 5 * SS, 3 * SS, cx + 5 * SS, 7 * SS], fill=(200, 40, 40, 255) if kind == "whisky" else (40, 40, 40, 255))
    d.rectangle([cx - 7 * SS, 26 * SS, cx + 7 * SS, 34 * SS], fill=(246, 236, 210, 255))
    return img.resize((48, 48), Image.LANCZOS)


def stage() -> Image.Image:
    w, h = 520 * SS, 300 * SS
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    # paredoes
    for side in (-1, 1):
        x0 = w * 0.5 + side * 210 * SS
        d.rectangle([x0 - 46 * SS, 30 * SS, x0 + 46 * SS, 230 * SS], fill=(24, 22, 28, 255), outline=(80, 70, 90, 255), width=4 * SS)
        for r in range(3):
            yy = 70 * SS + r * 60 * SS
            d.ellipse([x0 - 28 * SS, yy - 24 * SS, x0 + 28 * SS, yy + 24 * SS], fill=(54, 50, 60, 255), outline=(12, 12, 14, 255), width=3 * SS)
            d.ellipse([x0 - 10 * SS, yy - 8 * SS, x0 + 10 * SS, yy + 8 * SS], fill=(18, 18, 20, 255))
    # tablado
    d.polygon([(70 * SS, 150 * SS), (w - 70 * SS, 150 * SS), (w - 30 * SS, 270 * SS), (30 * SS, 270 * SS)], fill=(70, 46, 36, 255), outline=(30, 20, 16, 255))
    for k in range(9):
        x = 30 * SS + k * (w - 60 * SS) / 8
        d.line([(x, 270 * SS), (70 * SS + k * (w - 140 * SS) / 8, 150 * SS)], fill=(50, 32, 26, 255), width=2 * SS)
    d.rectangle([30 * SS, 270 * SS, w - 30 * SS, 292 * SS], fill=(44, 30, 24, 255))
    # faixa de luz
    d.rectangle([60 * SS, 18 * SS, w - 60 * SS, 30 * SS], fill=(40, 36, 44, 255))
    for k in range(7):
        x = 90 * SS + k * (w - 180 * SS) / 6
        d.ellipse([x - 9 * SS, 22 * SS, x + 9 * SS, 40 * SS], fill=(250, 190, 80, 255))
    # pedestal do microfone na boca do palco (ponto de invocacao)
    mx = w * 0.5
    d.line([(mx, 200 * SS), (mx, 270 * SS)], fill=(180, 180, 190, 255), width=4 * SS)
    d.ellipse([mx - 9 * SS, 188 * SS, mx + 9 * SS, 206 * SS], fill=(230, 230, 240, 255), outline=(250, 210, 70, 255), width=2 * SS)
    return img.resize((520, 300), Image.LANCZOS)


def terrain_atlas() -> Image.Image:
    """4 x 4 de quadra de concreto com marcas de baile; indice 5 = piso do palco."""
    cell = 1254 // 4
    size = cell * 4
    rnd = random.Random(1010)
    img = Image.new("RGB", (size, size), (60, 58, 62))
    d = ImageDraw.Draw(img)
    for idx in range(16):
        cx0, cy0 = (idx % 4) * cell, (idx // 4) * cell
        base = rnd.randint(52, 70)
        tone = (base, base - 2, base + 4)
        d.rectangle([cx0, cy0, cx0 + cell, cy0 + cell], fill=tone)
        for _ in range(900):
            x, y = cx0 + rnd.randint(0, cell - 1), cy0 + rnd.randint(0, cell - 1)
            v = rnd.randint(-14, 14)
            d.point((x, y), fill=(tone[0] + v, tone[1] + v, tone[2] + v))
        # placas de concreto
        for k in range(1, 3):
            d.line([(cx0 + k * cell // 3, cy0), (cx0 + k * cell // 3, cy0 + cell)], fill=(42, 40, 44), width=2)
            d.line([(cx0, cy0 + k * cell // 3), (cx0 + cell, cy0 + k * cell // 3)], fill=(42, 40, 44), width=2)
        if idx == 5:
            d.rectangle([cx0 + 10, cy0 + 10, cx0 + cell - 10, cy0 + cell - 10], fill=(44, 34, 40))
            for k in range(12):
                d.line([(cx0 + 10, cy0 + 10 + k * (cell - 20) // 12), (cx0 + cell - 10, cy0 + 10 + k * (cell - 20) // 12)], fill=(56, 40, 48), width=3)
            d.ellipse([cx0 + cell // 2 - 46, cy0 + cell // 2 - 46, cx0 + cell // 2 + 46, cy0 + cell // 2 + 46], outline=(120, 60, 130), width=4)
            continue
        kind = idx % 5
        if kind == 0:  # linha de quadra
            d.arc([cx0 - cell // 2, cy0 + cell // 4, cx0 + cell // 2, cy0 + cell + cell // 4], 270, 360, fill=(170, 160, 120), width=6)
        elif kind == 1:  # poca refletindo luz
            px, py = cx0 + rnd.randint(60, cell - 60), cy0 + rnd.randint(60, cell - 60)
            d.ellipse([px - 50, py - 22, px + 50, py + 22], fill=(34, 30, 46))
            d.ellipse([px - 20, py - 8, px + 10, py + 2], fill=(110, 50, 110))
        elif kind == 2:  # rachadura
            x, y = cx0 + rnd.randint(30, cell - 30), cy0 + 10
            for _ in range(8):
                nx, ny = x + rnd.randint(-28, 28), y + rnd.randint(20, 40)
                d.line([(x, y), (nx, ny)], fill=(30, 28, 32), width=3)
                x, y = nx, ny
        elif kind == 3:  # tampinhas / copos
            for _ in range(10):
                px, py = cx0 + rnd.randint(20, cell - 20), cy0 + rnd.randint(20, cell - 20)
                d.ellipse([px - 4, py - 4, px + 4, py + 4], fill=rnd.choice([(190, 60, 60), (200, 190, 80), (160, 160, 170)]))
        else:  # faixa pintada
            d.line([(cx0, cy0 + cell // 2), (cx0 + cell, cy0 + cell // 2)], fill=(150, 60, 120), width=8)
    return img.filter(ImageFilter.SMOOTH)


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    sizes = {"monarca": 150, "garrafeira": 150, "sombrinha": 160, "paredinha": 170, "hype": 150, "dancarina": 140}
    for sp, size in sizes.items():
        butterfly(sp, size, 0.0, "idle").save(OUT / f"b10_{sp}_0.png")
        butterfly(sp, size, 1.0, "idle").save(OUT / f"b10_{sp}_1.png")
        butterfly(sp, size, 0.0, "attack").save(OUT / f"b10_{sp}_2.png")
        butterfly(sp, size, 0.0, "drop").save(OUT / f"b10_{sp}_3.png")
    for frame, count in (("idle", 4), ("sing", 4), ("attack", 2), ("roda", 2), ("daze", 2), ("remix", 2), ("death", 4)):
        for k in range(count):
            boss(frame, k).save(OUT / f"boss10_{frame}_{k}.png")
    for k in range(4):
        lagartona_head(k, "idle").save(OUT / f"b10_lagartona_{k}.png")
    lagartona_head(0, "attack").save(OUT / "b10_lagartona_attack.png")
    lagartona_head(1, "daze").save(OUT / "b10_lagartona_daze.png")
    lagartona_segment(False, False).save(OUT / "b10_segmento_0.png")
    lagartona_segment(True, False).save(OUT / "b10_segmento_1.png")
    lagartona_segment(False, True).save(OUT / "b10_segmento_casulo.png")
    for kind in ("whisky", "gin", "vodka"):
        bottle(kind).save(OUT / f"b10_garrafa_{kind}.png")
    stage().save(OUT / "b10_palco.png")
    terrain_atlas().save(ATLAS)
    print("ok", len(list(OUT.glob("*.png"))), "sprites +", ATLAS.name)


if __name__ == "__main__":
    main()
