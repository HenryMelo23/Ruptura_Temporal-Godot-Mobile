#!/usr/bin/env python3
"""Recorta as folhas do Codex da Dimensao 9 (Cripta de Seda).

Uso:
  python3 tools/cripta_slice.py                  # recorta as folhas que existirem
  python3 tools/cripta_slice.py --placeholders   # silhuetas provisorias (so cria o que falta)
  python3 tools/cripta_slice.py --placeholders --force   # sobrescreve tudo com provisorios

Entradas (o Codex copia sem alterar) em .agent_logs/codex_umbra/:
  cripta_aranhas_a.png     1254x1254, 4x4  lobo / viuva / alcapao / saltadora
  cripta_aranhas_b.png     1254x1254, 4x4  mimica / poses avulsas / olho+lamparina / ecos
  cripta_pilastras.png     1254x1254, 2x1  duas pilastras (cada celula 627x1254)
  cripta_noiva.png         1254x1254, 4x4  Noiva de Seda: andar / conjurar / veu / dor
  cripta_matriarca_a.png   1254x1254, 4x4  Matriarca: andar / olhar / conjurar / salto
  cripta_matriarca_b.png   1254x627,  4x2  Matriarca: atordoada / morte
  cripta_sustos.png        1254x627,  4x2  closes de susto
  cripta_terrain_atlas.png 1254x1254       chao (vira phase_ex9_terrain_atlas.png)
Fundo das folhas: magenta puro #FF00FF (vira transparente).

Saidas: assets/sprites/cripta/<chave>_<n>.png (ou <chave>.png nos avulsos) e
assets/sprites/experimental/phase_ex9_terrain_atlas.png.
Cada grupo (linha) e normalizado junto: mesma escala e mesma linha de base.
"""
import math
import os
import sys
from PIL import Image, ImageDraw, ImageEnhance

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
SRC = os.path.join(ROOT, ".agent_logs", "codex_umbra")
OUT = os.path.join(ROOT, "assets", "sprites", "cripta")
ATLAS = os.path.join(ROOT, "assets", "sprites", "experimental", "phase_ex9_terrain_atlas.png")

ROW = lambda r, n=4: [(c, r) for c in range(n)]
# (folha, colunas, linhas, [(chave, celulas, (w, h), numerado)])
SHEETS = [
    ("cripta_aranhas_a.png", 4, 4, [
        ("s9_lobo", ROW(0), (180, 180), True),
        ("s9_viuva", ROW(1), (220, 220), True),
        ("s9_alcapao", ROW(2), (200, 200), True),
        ("s9_saltadora", ROW(3), (190, 190), True),
    ]),
    ("cripta_aranhas_b.png", 4, 4, [
        ("s9_mimica", ROW(0), (180, 180), True),
        ("s9_viuva_freeze", [(0, 1)], (220, 220), False),
        ("s9_alcapao_lid", [(1, 1)], (200, 200), False),
        ("s9_filhote", [(2, 1), (3, 1)], (110, 110), True),
        ("s9_olho", [(0, 2), (1, 2)], (130, 130), True),
        ("s9_lamp_on", [(2, 2)], (160, 240), False),
        ("s9_lamp_off", [(3, 2)], (160, 240), False),
        ("s9_echo", ROW(3), (120, 120), True),
    ]),
    ("cripta_pilastras.png", 2, 1, [
        ("s9_pillar_0", [(0, 0)], (220, 440), False),
        ("s9_pillar_1", [(1, 0)], (220, 440), False),
    ]),
    ("cripta_noiva.png", 4, 4, [
        ("s9_noiva", [(c, r) for r in range(4) for c in range(4)], (420, 420), True),
    ]),
    ("cripta_matriarca_a.png", 4, 4, [
        ("boss9_walk", ROW(0), (520, 520), True),
        ("boss9_gaze", ROW(1), (520, 520), True),
        ("boss9_cast", ROW(2), (520, 520), True),
        ("boss9_leap", ROW(3), (520, 520), True),
    ]),
    ("cripta_aranhas_d.png", 4, 4, [
        ("s9_boleadeira", ROW(0), (190, 190), True),
        ("s9_armadeira", ROW(1), (220, 220), True),
        ("s9_casulo", ROW(2), (160, 240), True),
        ("s9_bola", [(0, 3), (1, 3)], (90, 90), True),
        ("s9_veneno", [(2, 3)], (90, 90), False),
        ("s9_seda_rompida", [(3, 3)], (160, 160), False),
    ]),
    ("cripta_matriarca_b.png", 4, 2, [
        ("boss9_daze", ROW(0), (520, 520), True),
        ("boss9_death", ROW(1), (520, 520), True),
    ]),
]
SCARES = ["lobo", "viuva", "alcapao", "saltadora", "mimica", "noiva", "matriarca", "filhote"]
SCARES_B = ["armadeira", "boleadeira"]


import numpy as np


def _grow(seed, allowed, limit=3000):
    """Inunda a partir de seed andando so por allowed (4 vizinhos)."""
    cur = seed & allowed
    for _ in range(limit):
        nxt = cur.copy()
        nxt[1:, :] |= cur[:-1, :]
        nxt[:-1, :] |= cur[1:, :]
        nxt[:, 1:] |= cur[:, :-1]
        nxt[:, :-1] |= cur[:, 1:]
        nxt &= allowed
        if (nxt == cur).all():
            break
        cur = nxt
    return cur


def _dilate(m, n=1):
    for _ in range(n):
        d = m.copy()
        d[1:, :] |= m[:-1, :]
        d[:-1, :] |= m[1:, :]
        d[:, 1:] |= m[:, :-1]
        d[:, :-1] |= m[:, 1:]
        m = d
    return m


def unkey(rgb):
    """Fundo magenta -> transparente, sem comer o violeta/rosa da arte.

    1. Fundo = magenta ligado a borda da celula (inundacao) + buracos de magenta
       PURO presos entre as patas.
    2. Franja (ate 2 px do fundo) mesclada com magenta: vira semitransparente
       por "cor para alfa" e perde o tom rosado.
    3. Veu/teia translucidos mais para dentro: ficam quase opacos (alfa >= 0.8)
       e so perdem a cor rosada do fundo.
    4. Brilho vermelho (feixe dos olhos) sobre o magenta: vira brilho vermelho
       semitransparente.
    """
    a = rgb.astype(np.int32)
    r, g, b = a[..., 0], a[..., 1], a[..., 2]
    keyish = (r > 165) & (b > 165) & (g < 115) & (np.abs(r - b) < 70)
    border = np.zeros_like(keyish)
    border[0, :] = border[-1, :] = True
    border[:, 0] = border[:, -1] = True
    bg = _grow(border, keyish)
    pure = (r > 215) & (b > 215) & (g < 70) & (np.abs(r - b) < 35)
    bg |= pure
    soft_ok = (np.abs(r - b) < 40) & ((np.minimum(r, b) - g) > 40) & ~bg
    soft = _grow(_dilate(bg) & soft_ok, soft_ok)
    fringe = soft & _dilate(bg, 2)
    deep = soft & ~fringe
    glow_ok = (r > 190) & (g < 110) & (b > 90) & (b < 240) & ~bg & ~soft
    glow = _grow(_dilate(bg) & glow_ok, glow_ok)
    f = a.astype(np.float32) / 255.0
    alpha = np.maximum(np.maximum(1.0 - f[..., 0], f[..., 1]), 1.0 - f[..., 2])
    alpha = np.clip(alpha, 0.04, 1.0)
    mag = np.array([1.0, 0.0, 1.0], np.float32)
    fg = np.clip((f - (1.0 - alpha)[..., None] * mag) / alpha[..., None], 0.0, 1.0)
    lum = (fg * np.array([0.3, 0.55, 0.15], np.float32)).sum(-1, keepdims=True)
    tint = np.array([0.98, 0.95, 1.06], np.float32)
    fg = fg * 0.3 + np.clip(lum * tint, 0.0, 1.0) * 0.7
    # Veu por dentro: tira so o rosado (puxa o verde para perto de R/B).
    calm = f.copy()
    calm[..., 1] = calm[..., 1] + 0.55 * (np.minimum(calm[..., 0], calm[..., 2]) - calm[..., 1])
    out = np.zeros(a.shape[:2] + (4,), np.uint8)
    out[..., :3] = a.astype(np.uint8)
    out[..., 3] = 255
    out[fringe, :3] = (fg[fringe] * 255.0).astype(np.uint8)
    out[fringe, 3] = (alpha[fringe] * 255.0).astype(np.uint8)
    out[deep, :3] = (calm[deep] * 255.0).astype(np.uint8)
    out[deep, 3] = (np.maximum(alpha[deep], 0.82) * 255.0).astype(np.uint8)
    ga = np.clip(1.0 - f[..., 2] * 0.85, 0.15, 0.9)
    out[glow, 0] = 255
    out[glow, 1] = 70
    out[glow, 2] = 80
    out[glow, 3] = (ga[glow] * 255.0).astype(np.uint8)
    out[bg] = 0
    return Image.fromarray(out, "RGBA")


def cell_image(sheet, cols, rows, col, row):
    w, h = sheet.size
    cw, ch = w / cols, h / rows
    cell = sheet.crop((int(col * cw), int(row * ch), int((col + 1) * cw), int((row + 1) * ch))).convert("RGB")
    return unkey(np.asarray(cell))


def feather(im, frac=0.14):
    """Some as bordas da celula (closes que encostam na borda nao viram um quadrado)."""
    a = np.asarray(im).copy()
    h, w = a.shape[:2]
    yy, xx = np.mgrid[0:h, 0:w]
    d = np.minimum(np.minimum(xx, w - 1 - xx), np.minimum(yy, h - 1 - yy)).astype(np.float32)
    k = np.clip(d / (frac * min(w, h)), 0.0, 1.0)
    k = k * k * (3.0 - 2.0 * k)
    a[..., 3] = (a[..., 3].astype(np.float32) * k).astype(np.uint8)
    return Image.fromarray(a, "RGBA")


def group(sheet, cols, rows, cells, size, key, numbered, anchor="feet", soft_edges=False):
    imgs = [cell_image(sheet, cols, rows, c, r) for c, r in cells]
    if soft_edges:
        imgs = [feather(im) for im in imgs]
    boxes = [im.split()[3].point(lambda v: 255 if v > 24 else 0).getbbox() or (0, 0, 1, 1) for im in imgs]
    max_w = max(b[2] - b[0] for b in boxes)
    max_h = max(b[3] - b[1] for b in boxes)
    ow, oh = size
    scale = min((ow - 8) / max_w, (oh - 8) / max_h)
    for i, (im, b) in enumerate(zip(imgs, boxes)):
        part = im.crop(b)
        part = part.resize((max(1, int(part.size[0] * scale)), max(1, int(part.size[1] * scale))), Image.LANCZOS)
        canvas = Image.new("RGBA", (ow, oh), (0, 0, 0, 0))
        x = (ow - part.size[0]) // 2
        y = oh - 4 - part.size[1] if anchor == "feet" else (oh - part.size[1]) // 2
        canvas.paste(part, (x, y), part)
        canvas.save(os.path.join(OUT, ("%s_%d.png" % (key, i)) if numbered else key + ".png"))
    print("ok", key, len(imgs))


def slice_all():
    os.makedirs(OUT, exist_ok=True)
    for name, cols, rows, groups in SHEETS:
        path = os.path.join(SRC, name)
        if not os.path.exists(path):
            print("faltando", name)
            continue
        sheet = Image.open(path).convert("RGB")
        for key, cells, size, numbered in groups:
            group(sheet, cols, rows, cells, size, key, numbered)
    path = os.path.join(SRC, "cripta_sustos.png")
    if os.path.exists(path):
        sheet = Image.open(path).convert("RGB")
        for i, k in enumerate(SCARES):
            group(sheet, 4, 2, [(i % 4, i // 4)], (640, 640), "s9_scare_" + k, False, anchor="center", soft_edges=True)
    else:
        print("faltando cripta_sustos.png")
    path = os.path.join(SRC, "cripta_sustos_b.png")
    if os.path.exists(path):
        sheet = Image.open(path).convert("RGB")
        for i, k in enumerate(SCARES_B):
            group(sheet, 2, 1, [(i, 0)], (640, 640), "s9_scare_" + k, False, anchor="center", soft_edges=True)
    else:
        print("faltando cripta_sustos_b.png")
    atlas = os.path.join(SRC, "cripta_terrain_atlas.png")
    if os.path.exists(atlas):
        im = Image.open(atlas).convert("RGB").resize((1254, 1254), Image.LANCZOS)
        # O breu ja escurece tudo: o chao fica so um pouco mais frio/apagado.
        im = ImageEnhance.Color(im).enhance(0.85)
        im.save(ATLAS)
        print("ok atlas")


# ================================================================ provisorios
INK = (14, 10, 14)


def _spider(size, body, eye, legs_phase=0, crouch=False, leap=False, fangs=False, scale=1.0, eyes=8):
    w, h = size
    im = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    s = min(w, h) / 160.0 * scale
    cx, base = w / 2, h - 6
    cy = base - (26 if crouch else 44) * s - (18 * s if leap else 0)
    for side in (-1, 1):
        for k in range(4):
            a = math.radians(-35 + k * 24)
            wig = (5 * s if (k + legs_phase) % 2 == 0 else -5 * s)
            kx = cx + side * (34 + k * 6) * s
            ky = cy - (26 - k * 6) * s + wig
            fx = cx + side * (58 + k * 10) * s * (1.25 if leap else 1.0)
            fy = base - (2 if not leap else 26) * s + (k - 1.5) * 3 * s
            d.line([cx + side * 14 * s, cy, kx, ky, fx, fy], fill=INK, width=max(2, int(5 * s)))
    d.ellipse([cx - 30 * s, cy - 30 * s, cx + 30 * s, cy + 22 * s], fill=body, outline=INK, width=max(1, int(3 * s)))
    d.ellipse([cx - 20 * s, cy - 2 * s, cx + 20 * s, cy + 30 * s], fill=tuple(min(255, c + 25) for c in body), outline=INK, width=max(1, int(2 * s)))
    for k in range(eyes):
        ex = cx - 14 * s + (28 * s) * (k / max(1, eyes - 1))
        ey = cy + 8 * s - abs(k - (eyes - 1) / 2) * 1.5 * s
        d.ellipse([ex - 3 * s, ey - 3 * s, ex + 3 * s, ey + 3 * s], fill=eye)
    if fangs:
        d.polygon([(cx - 8 * s, cy + 26 * s), (cx - 3 * s, cy + 40 * s), (cx - 1 * s, cy + 26 * s)], fill=(230, 225, 215))
        d.polygon([(cx + 8 * s, cy + 26 * s), (cx + 3 * s, cy + 40 * s), (cx + 1 * s, cy + 26 * s)], fill=(230, 225, 215))
    return im


def _save(im, name, force):
    p = os.path.join(OUT, name + ".png")
    if force or not os.path.exists(p):
        im.save(p)


def placeholders(force=False):
    os.makedirs(OUT, exist_ok=True)
    red, pale, amber = (255, 40, 60), (220, 230, 255), (255, 190, 60)
    specs = {
        "s9_lobo": ((180, 180), (88, 70, 56), amber),
        "s9_viuva": ((220, 220), (24, 22, 30), red),
        "s9_alcapao": ((200, 200), (84, 66, 50), amber),
        "s9_saltadora": ((190, 190), (60, 60, 70), (120, 255, 200)),
        "s9_mimica": ((180, 180), (96, 92, 110), pale),
    }
    for key, (size, body, eye) in specs.items():
        for i in range(4):
            if key == "s9_saltadora":
                im = _spider(size, body, eye, i, crouch=i == 2, leap=i == 3)
            else:
                im = _spider(size, body, eye, i, fangs=i >= 2, leap=key == "s9_alcapao" and i >= 2)
            _save(im, "%s_%d" % (key, i), force)
    fr = _spider((220, 220), (24, 22, 30), (90, 20, 30), 0)
    _save(fr, "s9_viuva_freeze", force)
    lid = Image.new("RGBA", (200, 200), (0, 0, 0, 0))
    d = ImageDraw.Draw(lid)
    d.ellipse([30, 120, 170, 190], fill=(70, 58, 46), outline=INK, width=3)
    for k in range(6):
        d.line([40 + k * 22, 140, 52 + k * 22, 176], fill=(110, 96, 80), width=2)
    _save(lid, "s9_alcapao_lid", force)
    for i in range(2):
        _save(_spider((110, 110), (120, 110, 100), red, i, scale=0.9, eyes=4), "s9_filhote_%d" % i, force)
    for i in range(2):
        im = Image.new("RGBA", (130, 130), (0, 0, 0, 0))
        d = ImageDraw.Draw(im)
        d.ellipse([20, 30, 110, 110], fill=(230, 220, 205), outline=INK, width=3)
        d.ellipse([46, 52 + i * 4, 84, 90 + i * 4], fill=(170, 20, 40))
        d.ellipse([58, 64, 72, 78], fill=INK)
        for k in range(5):
            d.line([65, 110, 30 + k * 18, 128], fill=(200, 200, 220), width=2)
        _save(im, "s9_olho_%d" % i, force)
    for name, lit in (("s9_lamp_on", True), ("s9_lamp_off", False)):
        im = Image.new("RGBA", (160, 240), (0, 0, 0, 0))
        d = ImageDraw.Draw(im)
        d.rectangle([72, 70, 88, 236], fill=(50, 46, 44), outline=INK, width=2)
        d.rectangle([52, 40, 108, 96], fill=(60, 54, 50), outline=INK, width=3)
        d.ellipse([66, 52, 94, 86], fill=(255, 210, 110) if lit else (40, 36, 34))
        if lit:
            d.ellipse([74, 58, 86, 76], fill=(255, 250, 220))
        _save(im, name, force)
    for i in range(4):
        im = Image.new("RGBA", (120, 120), (0, 0, 0, 0))
        d = ImageDraw.Draw(im)
        r = 22 + 4 * math.sin(i * math.pi / 2)
        d.ellipse([60 - r - 10, 60 - r - 10, 60 + r + 10, 60 + r + 10], fill=(150, 200, 255, 70))
        d.polygon([(60, 60 - r), (60 + r * 0.6, 60), (60, 60 + r), (60 - r * 0.6, 60)], fill=(200, 230, 255), outline=(90, 140, 220))
        _save(im, "s9_echo_%d" % i, force)
    for k in range(2):
        im = Image.new("RGBA", (220, 440), (0, 0, 0, 0))
        d = ImageDraw.Draw(im)
        d.rectangle([40, 40, 180, 420], fill=(66, 64, 72), outline=INK, width=4)
        d.rectangle([24, 20, 196, 60], fill=(80, 78, 86), outline=INK, width=3)
        d.rectangle([24, 400, 196, 436], fill=(80, 78, 86), outline=INK, width=3)
        for j in range(6):
            d.line([40, 80 + j * 55 + k * 10, 180, 100 + j * 55], fill=(225, 225, 240, 140), width=2)
        _save(im, "s9_pillar_%d" % k, force)
    # Noiva: aranha palida com veu, 4 linhas.
    for row in range(4):
        for c in range(4):
            im = _spider((420, 420), (230, 226, 236), (180, 30, 60), c, fangs=row == 1, scale=1.0)
            d = ImageDraw.Draw(im)
            d.polygon([(210, 70), (130, 260), (290, 260)], fill=(245, 245, 255, 150 if row != 2 else 230))
            if row == 3:
                d.line([150, 150, 270, 270], fill=(255, 80, 90), width=6)
            _save(im, "s9_noiva_%d" % (row * 4 + c), force)
    # Matriarca: aranha enorme com oito olhos vermelhos.
    for key in ("boss9_walk", "boss9_gaze", "boss9_cast", "boss9_leap", "boss9_daze", "boss9_death"):
        for i in range(4):
            im = _spider((520, 520), (34, 20, 28), (255, 30, 50) if key != "boss9_daze" else (120, 60, 70), i,
                         fangs=key in ("boss9_cast", "boss9_leap"), crouch=key == "boss9_leap" and i == 0,
                         leap=key == "boss9_leap" and i > 0)
            d = ImageDraw.Draw(im)
            if key == "boss9_gaze":
                d.ellipse([200, 250, 320, 300], outline=(255, 60, 60), width=4 + i)
            if key == "boss9_death":
                for k in range(i + 1):
                    d.line([170 + k * 40, 260, 200 + k * 40, 380], fill=(255, 200, 220), width=5)
            _save(im, "%s_%d" % (key, i), force)
    # Boleadeira (bola verde), Armadeira (empina), casulo, bola, veneno.
    for i in range(4):
        im = _spider((190, 190), (70, 66, 52), (150, 255, 120), i, fangs=i == 3)
        if i >= 2:
            d = ImageDraw.Draw(im)
            d.line([95, 100, 95 + (40 if i == 3 else 0), 40], fill=(230, 230, 240), width=2)
            d.ellipse([80 + (40 if i == 3 else 0) - 14, 26, 108 + (40 if i == 3 else 0) - 14, 54], fill=(150, 255, 120))
        _save(im, "s9_boleadeira_%d" % i, force)
    for i in range(4):
        _save(_spider((220, 220), (110, 80, 50), (255, 60, 40), i, fangs=i >= 2, crouch=i == 3, leap=i == 2), "s9_armadeira_%d" % i, force)
    for i in range(4):
        im = Image.new("RGBA", (160, 240), (0, 0, 0, 0))
        d = ImageDraw.Draw(im)
        h = [70, 130, 200, 200][i]
        d.ellipse([30, 236 - h, 130, 236], fill=(236, 236, 244), outline=INK, width=3)
        for k in range(h // 14):
            d.line([34, 230 - k * 14, 126, 222 - k * 14], fill=(170, 170, 185), width=2)
        if i >= 2:
            d.ellipse([58, 30, 102, 74], fill=(240, 200, 170), outline=INK, width=2)
            d.ellipse([52, 18, 108, 50], fill=(150, 70, 40))
        _save(im, "s9_casulo_%d" % i, force)
    for i in range(2):
        im = Image.new("RGBA", (90, 90), (0, 0, 0, 0))
        d = ImageDraw.Draw(im)
        d.ellipse([22, 22, 68, 68], fill=(150, 255, 120, 230), outline=(40, 90, 30), width=3)
        d.arc([16, 16, 74, 74], 30 + i * 90, 200 + i * 90, fill=(235, 235, 245), width=3)
        _save(im, "s9_bola_%d" % i, force)
    im = Image.new("RGBA", (90, 90), (0, 0, 0, 0))
    ImageDraw.Draw(im).polygon([(45, 10), (70, 55), (45, 80), (20, 55)], fill=(110, 230, 80), outline=INK)
    _save(im, "s9_veneno", force)
    im = Image.new("RGBA", (160, 160), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    for k in range(10):
        a = k * math.pi / 5
        d.line([80, 80, 80 + math.cos(a) * 70, 80 + math.sin(a) * 70], fill=(235, 235, 245), width=2)
    _save(im, "s9_seda_rompida", force)
    for k in SCARES + SCARES_B:
        im = Image.new("RGBA", (640, 640), (0, 0, 0, 0))
        big = _spider((640, 640), (20, 12, 16), (255, 30, 50), 0, fangs=True, scale=1.6)
        im.paste(big, (0, -120), big)
        _save(im, "s9_scare_" + k, force)
    if force or not os.path.exists(ATLAS):
        src = os.path.join(ROOT, "assets", "sprites", "experimental", "phase_ex3_terrain_atlas.png")
        im = Image.open(src).convert("L")
        lut = []
        lo, hi = (18, 16, 24), (96, 92, 112)
        for ch in range(3):
            lut.extend([int(lo[ch] + (hi[ch] - lo[ch]) * min(1.0, v / 150.0)) for v in range(256)])
        im.convert("RGB").point(lut).save(ATLAS)
    print("placeholders ok")


if __name__ == "__main__":
    if "--placeholders" in sys.argv:
        placeholders("--force" in sys.argv)
    else:
        slice_all()
