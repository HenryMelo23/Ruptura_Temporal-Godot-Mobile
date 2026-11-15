#!/usr/bin/env python3
"""Fatia as folhas da Fenda do Mercador (Geovana + efeitos).

Entrada: .agent_logs/codex_umbra/rift_*.png (fundo magenta #FF00FF).
Saida:
  assets/sprites/player/rift/<humor>_<fase>_<n>.png
      caixa fixa por folha, medida pela altura S da Geovana em pe:
      largura BOX_W*S, altura BOX_H*S, pes a FOOT_PAD*S da base.
      (a presentation usa as mesmas constantes para ancorar os pes)
  assets/sprites/rift_fx/<nome>_<n>.png
      caixa = uniao dos quadros de cada grupo animado (escala estavel).
Uso: python3 tools/rift_slice.py [raiz_do_projeto]
"""
import os, sys
from PIL import Image

ROOT = sys.argv[1] if len(sys.argv) > 1 else os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, ".agent_logs", "codex_umbra")
OUT_CHAR = os.path.join(ROOT, "assets", "sprites", "player", "rift")
OUT_FX = os.path.join(ROOT, "assets", "sprites", "rift_fx")

BOX_W = 1.20
BOX_H = 1.34
FOOT_PAD = 0.08
OUT_S = 120  # altura em pe, em pixels, no png final

def key(img):
    img = img.convert("RGBA")
    px = img.load()
    w, h = img.size
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            # distancia ao magenta
            mag = min(r, b) - g
            if r > 150 and b > 150 and g < 110 and abs(r - b) < 90:
                px[x, y] = (0, 0, 0, 0)
            elif mag > 60 and r > 110 and b > 110:
                # borda anti-aliased: tira o magenta e deixa semi-transparente
                k = min(1.0, (mag - 60) / 120.0)
                nr = int(r - (r - g) * k * 0.8)
                nb = int(b - (b - g) * k * 0.8)
                px[x, y] = (nr, g, nb, int(a * (1.0 - k * 0.85)))
    return img

def cells(img, cols, rows):
    w, h = img.size
    cw, ch = w / cols, h / rows
    out = []
    for r in range(rows):
        for c in range(cols):
            out.append(img.crop((round(c * cw), round(r * ch), round((c + 1) * cw), round((r + 1) * ch))))
    return out

def bbox(im):
    return im.getchannel("A").point(lambda v: 255 if v > 40 else 0).getbbox()

def save(im, path):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    im.save(path, optimize=True)

def char_sheet(name, cols, rows, count, mapping, ref_index, s_override=None):
    sheet = key(Image.open(os.path.join(SRC, name)))
    cs = cells(sheet, cols, rows)[:count]
    ref = bbox(cs[ref_index])
    S = s_override or (ref[3] - ref[1])
    feet = ref[3]
    cx = (ref[0] + ref[2]) / 2.0
    bw, bh = BOX_W * S, BOX_H * S
    left = cx - bw / 2.0
    top = feet + FOOT_PAD * S - bh
    scale = OUT_S / S
    ow, oh = round(BOX_W * OUT_S), round(BOX_H * OUT_S)
    clipped = 0
    for idx, (mood, phase, n) in mapping.items():
        cell = cs[idx]
        bb = bbox(cell)
        if bb and (bb[0] < left or bb[2] > left + bw or bb[1] < top or bb[3] > top + bh):
            clipped += 1
        canvas = Image.new("RGBA", (round(bw), round(bh)), (0, 0, 0, 0))
        canvas.paste(cell, (round(-left), round(-top)), cell)
        canvas = canvas.resize((ow, oh), Image.LANCZOS)
        save(canvas, os.path.join(OUT_CHAR, "%s_%s_%d.png" % (mood, phase, n)))
    print("%s: S=%d feet=%d cx=%.0f -> %d quadros (%d passam da caixa)" % (name, S, feet, cx, len(mapping), clipped))
    return S

def char_mapping(mood):
    m = {}
    phases = [("dive", 0, 6), ("land", 6, 14), ("exit_dive", 14, 19), ("emerge", 19, 26)]
    for phase, a, b in phases:
        for i, idx in enumerate(range(a, b)):
            m[idx] = (mood, phase, i)
    return m

def fx_groups(name, cols, rows, groups, fx_scale, anchors):
    sheet = key(Image.open(os.path.join(SRC, name)))
    cs = cells(sheet, cols, rows)
    for gname, idxs in groups.items():
        boxes = [bbox(cs[i]) for i in idxs]
        boxes = [b for b in boxes if b]
        u = (min(b[0] for b in boxes), min(b[1] for b in boxes), max(b[2] for b in boxes), max(b[3] for b in boxes))
        anchor = anchors.get(gname, "center")
        # simetriza em torno do centro da celula para o pivo ficar no meio
        cw, ch = cs[idxs[0]].size
        if anchor == "center":
            hx = max(cw / 2 - u[0], u[2] - cw / 2)
            hy = max(ch / 2 - u[1], u[3] - ch / 2)
            u = (cw / 2 - hx, ch / 2 - hy, cw / 2 + hx, ch / 2 + hy)
        else:  # bottom: centro em x, base no fundo da uniao
            hx = max(cw / 2 - u[0], u[2] - cw / 2)
            u = (cw / 2 - hx, u[1], cw / 2 + hx, u[3])
        u = tuple(round(v) for v in u)
        for n, i in enumerate(idxs):
            im = cs[i].crop(u)
            im = im.resize((max(1, round(im.width * fx_scale)), max(1, round(im.height * fx_scale))), Image.LANCZOS)
            suffix = "" if len(idxs) == 1 else "_%d" % n
            save(im, os.path.join(OUT_FX, "%s%s.png" % (gname, suffix)))
        print("  fx %s: %d quadros %dx%d" % (gname, len(idxs), round((u[2]-u[0])*fx_scale), round((u[3]-u[1])*fx_scale)))

if __name__ == "__main__":
    for mood in ("scared", "resigned", "stylish"):
        char_sheet("rift_%s.png" % mood, 6, 5, 26, char_mapping(mood), 0)
    char_sheet("rift_ejected.png", 4, 2, 7, {i: ("ejected", "emerge", i) for i in range(7)}, 6, 285)
    fx_groups("rift_fx_tear.png", 4, 4, {
        "tear": list(range(0, 11)),
        "floor_hole": [11, 12, 13, 14, 15],
    }, 0.75, {})
    fx_groups("rift_fx_impact.png", 5, 4, {
        "dust": [0, 1, 2, 3],
        "shock": [4, 5, 6, 7],
        "flash": [8, 9, 10],
        "ring": [11, 12, 13],
        "speed": [14, 15, 16],
        "stars": [17], "sweat": [18], "sigh": [19],
    }, 0.75, {"dust": "bottom"})
    fx_groups("rift_fx_tunnel.png", 2, 2, {"tunnel": [0, 1, 2, 3]}, 0.85, {})
