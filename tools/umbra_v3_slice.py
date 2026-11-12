#!/usr/bin/env python3
"""Recorta as folhas da UMBRA v3 (Codex) em frames 256x384.

Cada folha 1280x1280, grade 3x2. A celula inteira (426x640) e reduzida com a
MESMA escala (0,6) para manter ancora e tamanho iguais entre frames; nada de
recorte pelo contorno, senao a personagem "pula" quando o braco estica.

uso: python3 tools/umbra_v3_slice.py folha1.png ... folha5.png --out assets/sprites/umbra_v3
"""
import argparse, os
from PIL import Image

# Ordem das 30 celulas nas 5 folhas (esquerda->direita, cima->baixo).
ORDER = (
    [("idle", i) for i in range(1, 5)] + [("dano", 1), ("dano", 2)] +            # folha 1
    [("ataque", i) for i in range(1, 5)] + [("teleporte", 1), ("teleporte", 2)] +  # folha 2
    [("sifao", i) for i in range(1, 4)] + [("eco", i) for i in range(1, 4)] +      # folha 3
    [("transmutar", i) for i in range(1, 5)] + [("morte", 1), ("morte", 2)] +      # folha 4
    [("rebobinar", i) for i in range(1, 4)] + [("conjurar", i) for i in range(1, 4)]  # folha 5
)
assert len(ORDER) == 30


def key_out(im):
    im = im.convert("RGBA")
    px = im.load()
    w, h = im.size
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            d = ((r - 255) ** 2 + g ** 2 + (b - 255) ** 2) ** 0.5
            if d < 120 or (r > 200 and b > 200 and g < 80):
                px[x, y] = (0, 0, 0, 0)
            elif d < 190 and r > 150 and b > 150 and g < 140:
                k = (d - 120) / 70.0
                m = min(r, b, max(g, int(min(r, b) * 0.55)))
                px[x, y] = (min(r, m + 40), g, min(b, m + 40), int(255 * k))
    return im


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("sheets", nargs=5)
    ap.add_argument("--out", required=True)
    a = ap.parse_args()
    os.makedirs(a.out, exist_ok=True)
    k = 0
    for sheet in a.sheets:
        src = Image.open(sheet)
        if src.size != (1280, 1280):
            src = src.resize((1280, 1280), Image.LANCZOS)
        src = key_out(src)
        cw, ch = 1280 // 3, 1280 // 2
        for cell in range(6):
            cx, cy = cell % 3, cell // 3
            img = src.crop((cx * cw, cy * ch, cx * cw + cw, cy * ch + ch))
            img = img.resize((256, 384), Image.LANCZOS)
            anim, idx = ORDER[k]
            img.save(os.path.join(a.out, "%s_%02d.png" % (anim, idx)))
            k += 1
    print("UMBRA_V3_SLICED", k)


if __name__ == "__main__":
    main()
