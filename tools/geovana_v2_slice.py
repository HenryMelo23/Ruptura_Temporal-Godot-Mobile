#!/usr/bin/env python3
"""Recorta as folhas da Geovana base v2 (Codex) para o jogo (RTGeovanaV2).

Entradas (.agent_logs/codex_geovana/, fundo magenta):
  geovana_modelo.png      4x2  (linha 2 = repouso de combate, 4 quadros)
  geovana_andar.png       6x3  (direita, baixo, cima; 6 quadros cada)
  geovana_disparo.png     4x4  (leste, sul, norte, sudeste; 4 quadros cada)
  geovana_queda_dano.png  4x4  (nordeste; queda 4; aterrissagem 4; dano 4)

Saida: assets/sprites/player/geovana_v2/<anim>_NN.png, todos no MESMO canvas
e na MESMA escala: de pe a personagem tem STAND_H px e os pes ficam em FEET_Y.
- Escala por folha medida pela CABECA (largura do cabelo em quadros de frente),
  porque cada folha do Codex sai com a cabeca um pouco maior ou menor.
- Horizontal: centro da cabeca no centro do canvas (o corpo nao "pula" quando
  o braco estica). Vertical: a linha do chao da folha vai para FEET_Y, entao o
  sobe-e-desce do passo e a altura no ar da queda sao preservados.
- Oeste/sudoeste/noroeste do disparo saem espelhados.

Uso: python3 tools/geovana_v2_slice.py
"""
import os
from statistics import median
from PIL import Image

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
SRC = os.path.join(ROOT, ".agent_logs", "codex_geovana")
OUT = os.path.join(ROOT, "assets", "sprites", "player", "geovana_v2")

CANVAS = (256, 256)
STAND_H = 170          # altura de pe no canvas (o jogo desenha isso com 80 px)
FEET_Y = 246           # linha dos pes no canvas
HEAD_Y = FEET_Y - STAND_H

SHEETS = {
    "modelo": ("geovana_modelo.png", 4, 2),
    "andar": ("geovana_andar.png", 6, 3),
    "disparo": ("geovana_disparo.png", 4, 4),
    "queda": ("geovana_queda_dano.png", 4, 4),
}
# Quadros de frente usados para medir a cabeca em cada folha.
FRONT_REF = {
    "modelo": [(c, 1) for c in range(4)],
    "andar": [(c, 1) for c in range(6)],
    "disparo": [(0, 1), (3, 1)],
    "queda": [(3, 2), (3, 3)],
}
# Quadros com os pes no chao (definem a linha do chao da folha).
GROUND_REF = {
    "modelo": [(c, 1) for c in range(4)],
    "andar": [(c, r) for r in range(3) for c in range(6)],
    "disparo": [(c, r) for r in range(4) for c in range(4)],
    "queda": [(c, 0) for c in range(4)] + [(2, 2), (3, 2), (2, 3), (3, 3)],
}
ANIMS = {
    "idle": ("modelo", [(c, 1) for c in range(4)]),
    "walk_right": ("andar", [(c, 0) for c in range(6)]),
    "walk_down": ("andar", [(c, 1) for c in range(6)]),
    "walk_up": ("andar", [(c, 2) for c in range(6)]),
    "fire_east": ("disparo", [(c, 0) for c in range(4)]),
    "fire_south": ("disparo", [(c, 1) for c in range(4)]),
    "fire_north": ("disparo", [(c, 2) for c in range(4)]),
    "fire_southeast": ("disparo", [(c, 3) for c in range(4)]),
    "fire_northeast": ("queda", [(c, 0) for c in range(4)]),
    "fall": ("queda", [(c, 1) for c in range(4)]),
    "land": ("queda", [(c, 2) for c in range(4)]),
    "damage": ("queda", [(c, 3) for c in range(4)]),
}
MIRRORS = {"fire_southwest": "fire_southeast", "fire_northwest": "fire_northeast"}


def keyed_cell(sheet, cols, rows, c, r):
    w, h = sheet.size
    cw, ch = w / cols, h / rows
    im = sheet.crop((int(c * cw), int(r * ch), int((c + 1) * cw), int((r + 1) * ch))).convert("RGBA")
    px = im.load()
    for y in range(im.size[1]):
        for x in range(im.size[0]):
            p = px[x, y]
            if p[0] > 200 and p[2] > 200 and p[1] < 90:
                px[x, y] = (0, 0, 0, 0)
            elif p[0] > 170 and p[2] > 170 and p[1] < 120:
                px[x, y] = (p[0] // 3, p[1] // 3, p[2] // 3, 110)
    return im


def is_hair(p):
    return p[3] > 200 and 110 < p[0] < 230 and 50 < p[1] < 140 and p[2] < 110 and p[0] > p[1] + 30


def hair_box(im):
    px = im.load()
    b = im.getbbox()
    if b is None:
        return None
    top_limit = b[1] + int((b[3] - b[1]) * 0.55)
    xs, ys = [], []
    for y in range(b[1], top_limit):
        for x in range(b[0], b[2]):
            if is_hair(px[x, y]):
                xs.append(x)
                ys.append(y)
    if not xs:
        return None
    return min(xs), min(ys), max(xs), max(ys)


def run():
    os.makedirs(OUT, exist_ok=True)
    cells = {}
    for key, (name, cols, rows) in SHEETS.items():
        path = os.path.join(SRC, name)
        if not os.path.exists(path):
            raise SystemExit("faltando " + path)
        sheet = Image.open(path).convert("RGB")
        cells[key] = {(c, r): keyed_cell(sheet, cols, rows, c, r) for r in range(rows) for c in range(cols)}

    # Modelo: escala pela altura do repouso; daí a largura-alvo do cabelo.
    model_h = median(cells["modelo"][k].getbbox()[3] - cells["modelo"][k].getbbox()[1] for k in FRONT_REF["modelo"])
    model_scale = STAND_H / model_h
    target_hair = median(hair_box(cells["modelo"][k])[2] - hair_box(cells["modelo"][k])[0] for k in FRONT_REF["modelo"]) * model_scale
    scale = {}
    ground = {}
    for key in SHEETS:
        hw = median(hair_box(cells[key][k])[2] - hair_box(cells[key][k])[0] for k in FRONT_REF[key])
        scale[key] = target_hair / hw
        ground[key] = median(cells[key][k].getbbox()[3] for k in GROUND_REF[key])
        print("folha %-8s escala %.3f chao %.0f" % (key, scale[key], ground[key]))

    for anim, (key, frames) in ANIMS.items():
        s = scale[key]
        for i, k in enumerate(frames):
            im = cells[key][k]
            b = im.getbbox()
            hb = hair_box(im)
            head_cx = (hb[0] + hb[2]) * 0.5 if hb else (b[0] + b[2]) * 0.5
            part = im.crop(b)
            part = part.resize((max(1, round(part.size[0] * s)), max(1, round(part.size[1] * s))), Image.NEAREST)
            x = round(CANVAS[0] * 0.5 - (head_cx - b[0]) * s)
            y = round(FEET_Y - (ground[key] - b[1]) * s)
            out = Image.new("RGBA", CANVAS, (0, 0, 0, 0))
            out.paste(part, (x, y), part)
            if out.getbbox() != (max(0, x), max(0, y), min(CANVAS[0], x + part.size[0]), min(CANVAS[1], y + part.size[1])):
                print("  aviso: %s_%02d cortado no canvas" % (anim, i + 1))
            out.save(os.path.join(OUT, "%s_%02d.png" % (anim, i + 1)))
        print("ok", anim, len(frames))
    for anim, src in MIRRORS.items():
        i = 1
        while os.path.exists(os.path.join(OUT, "%s_%02d.png" % (src, i))):
            Image.open(os.path.join(OUT, "%s_%02d.png" % (src, i))).transpose(Image.FLIP_LEFT_RIGHT).save(os.path.join(OUT, "%s_%02d.png" % (anim, i)))
            i += 1
        print("ok", anim, i - 1, "(espelho de %s)" % src)


if __name__ == "__main__":
    run()
