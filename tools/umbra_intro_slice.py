#!/usr/bin/env python3
"""Recorta as folhas do Codex da cena de chegada da UMBRA (RTUmbraIntro).

Entradas (.agent_logs/codex_umbra/, fundo magenta #FF00FF):
  intro_geo231.png      1254x1254, 4x4
  intro_extras.png      1254x1254, 4x4
  intro_umbra.png       1254x940,  4x3
  intro_geovana.png     1254x940,  4x3  (opcional, v2: substitui as linhas 1-3 de intro_extras)

Saidas:
  assets/sprites/umbra_intro/geo231_<anim>_NN.png, geovana_<pose>_NN.png,
      meteoro_NN.png, impacto_NN.png
  assets/sprites/umbra_v3/risada_NN.png, invocar_NN.png (mesma escala/ancora da UMBRA v3)

Uso: python3 tools/umbra_intro_slice.py
"""
import os
from PIL import Image

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
SRC = os.path.join(ROOT, ".agent_logs", "codex_umbra")
OUT = os.path.join(ROOT, "assets", "sprites", "umbra_intro")
UMBRA = os.path.join(ROOT, "assets", "sprites", "umbra_v3")

# chave: (pasta, canvas, [(folha, colunas, linhas, col, lin), ...], modo)
# modo "feet": pes na mesma linha de base; "center": centralizado (efeitos).
G1 = ("intro_geo231.png", 4, 4)
G2 = ("intro_extras.png", 4, 4)
G3 = ("intro_umbra.png", 4, 3)
# Refacao no estilo da Geovana jogavel (pedido v2): se existir, as linhas 1-3
# de intro_extras (apagamento + nossa Geovana) vem de intro_geovana.png (4x3).
GV = ("intro_geovana.png", 4, 3)


def g2(c, r):
    if r < 3 and os.path.exists(os.path.join(SRC, GV[0])):
        return GV + (c, r)
    return G2 + (c, r)
# Personagens: canvas largo (cabe a esquiva deitada) e UMA escala por
# personagem, tirada da pose de pe de referencia: assim a GEO231 e a nossa
# Geovana ficam do mesmo tamanho da Geovana jogavel em todas as poses
# (ajoelhada fica mais baixa, como deve). O jogo desenha o canvas com
# RTUmbraIntroPresentation.CHAR_SCALE (pose de pe = 80 px, pes em +40).
CHAR = (220, 210)
CHAR_STAND_H = 174
SCALE_REF = {"geo231": "geo231_run", "geovana": "geovana_firme"}
GROUPS = {
    "geo231_run": (OUT, CHAR, [G1 + (c, 0) for c in range(4)], "feet"),
    "geo231_fall": (OUT, CHAR, [G1 + (c, 1) for c in range(4)], "feet"),
    "geo231_kneel": (OUT, CHAR, [G1 + (0, 2), G1 + (1, 2)], "feet"),
    "geo231_shout": (OUT, CHAR, [G1 + (2, 2), G1 + (3, 2)], "feet"),
    "geo231_hit": (OUT, CHAR, [G1 + (0, 3), G1 + (1, 3)], "feet"),
    "geo231_erase": (OUT, CHAR, [G1 + (2, 3), G1 + (3, 3)] + [g2(c, 0) for c in range(4)], "feet"),
    "geovana_susto": (OUT, CHAR, [g2(0, 1), g2(1, 1)], "feet"),
    "geovana_firme": (OUT, CHAR, [g2(2, 1), g2(3, 1)], "feet"),
    "geovana_esquiva": (OUT, CHAR, [g2(c, 2) for c in range(4)], "feet"),
    "meteoro": (OUT, (220, 220), [G2 + (c, 3) for c in range(4)], "center"),
    "risada": (UMBRA, None, [G3 + (c, 0) for c in range(4)], "umbra"),
    "invocar": (UMBRA, None, [G3 + (c, 1) for c in range(4)], "umbra"),
    "impacto": (OUT, (300, 300), [G3 + (c, 2) for c in range(4)], "center"),
}


def key_px(p):
    return p[0] > 200 and p[2] > 200 and p[1] < 90


def cell(sheet, cols, rows, c, r):
    w, h = sheet.size
    cw, ch = w / cols, h / rows
    im = sheet.crop((int(c * cw), int(r * ch), int((c + 1) * cw), int((r + 1) * ch))).convert("RGBA")
    px = im.load()
    for y in range(im.size[1]):
        for x in range(im.size[0]):
            p = px[x, y]
            if key_px(p):
                px[x, y] = (0, 0, 0, 0)
            elif p[0] > 170 and p[2] > 170 and p[1] < 120:
                px[x, y] = (p[0] // 3, p[1] // 3, p[2] // 3, 110)
    return im


def umbra_reference():
    """Altura do corpo e linha dos pes nos quadros idle da UMBRA v3."""
    ref = Image.open(os.path.join(UMBRA, "idle_01.png")).convert("RGBA")
    b = ref.getbbox()
    return ref.size, b[3] - b[1], b[3]


def load_group(key, sheets):
    folder, canvas, cells, mode = GROUPS[key]
    imgs = []
    for name, cols, rows, c, r in cells:
        path = os.path.join(SRC, name)
        if not os.path.exists(path):
            return []
        if name not in sheets:
            sheets[name] = Image.open(path).convert("RGB")
        imgs.append(cell(sheets[name], cols, rows, c, r))
    return imgs


# Escala pela CABECA (largura do cabelo), nao pela altura: a corrida mancando
# e as poses agachadas sao mais baixas, e folhas diferentes do Codex saem com
# a cabeca um pouco maior ou menor. Largura do cabelo = 0,55 da altura de pe
# (medido na geovana_modelo.png).
HAIR_RATIO = {"geovana": 0.55, "geo231": 0.585}  # cabelo da GEO231 e desgrenhado (mais largo)


def hair_width(im):
    px = im.load()
    xs = []
    for y in range(im.size[1]):
        for x in range(im.size[0]):
            p = px[x, y]
            if p[3] > 200 and 110 < p[0] < 230 and 50 < p[1] < 140 and p[2] < 110 and p[0] > p[1] + 30:
                xs.append(x)
    return (max(xs) - min(xs)) if xs else 0


def char_scale(key, sheets, cache):
    who = key.split("_")[0]
    if who not in cache:
        ref = load_group(SCALE_REF[who], sheets)
        widths = sorted(w for w in (hair_width(im) for im in ref) if w > 0)
        cache[who] = (CHAR_STAND_H * HAIR_RATIO[who] / widths[len(widths) // 2]) if widths else None
    return cache[who]


def run():
    os.makedirs(OUT, exist_ok=True)
    sheets = {}
    scales = {}
    for key, (folder, canvas, cells, mode) in GROUPS.items():
        imgs = []
        for name, cols, rows, c, r in cells:
            path = os.path.join(SRC, name)
            if not os.path.exists(path):
                imgs = []
                break
            if name not in sheets:
                sheets[name] = Image.open(path).convert("RGB")
            imgs.append(cell(sheets[name], cols, rows, c, r))
        if not imgs:
            print("faltando folha para", key)
            continue
        boxes = [im.getbbox() or (0, 0, 1, 1) for im in imgs]
        max_w = max(b[2] - b[0] for b in boxes)
        max_h = max(b[3] - b[1] for b in boxes)
        if mode == "umbra":
            size, ref_h, ref_bottom = umbra_reference()
            scale = ref_h / max_h
            canvas = size
        elif canvas == CHAR and char_scale(key, sheets, scales):
            scale = char_scale(key, sheets, scales)
            fit = min((canvas[0] - 6) / max_w, (canvas[1] - 6) / max_h)
            if scale > fit:
                print("  aviso: %s nao cabe no canvas na escala do personagem, reduzido" % key)
                scale = fit
        else:
            scale = min((canvas[0] - 6) / max_w, (canvas[1] - 6) / max_h)
        for i, (im, b) in enumerate(zip(imgs, boxes)):
            part = im.crop(b)
            part = part.resize((max(1, int(part.size[0] * scale)), max(1, int(part.size[1] * scale))), Image.NEAREST)
            out = Image.new("RGBA", canvas, (0, 0, 0, 0))
            x = (canvas[0] - part.size[0]) // 2
            if mode == "center":
                y = (canvas[1] - part.size[1]) // 2
            elif mode == "umbra":
                y = ref_bottom - part.size[1]
            else:
                y = canvas[1] - 3 - part.size[1]
            out.paste(part, (x, y), part)
            out.save(os.path.join(folder, "%s_%02d.png" % (key, i + 1)))
        print("ok", key, len(imgs))


if __name__ == "__main__":
    run()
