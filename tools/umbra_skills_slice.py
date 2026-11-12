#!/usr/bin/env python3
"""Recorta as folhas de habilidades da UMBRA (lote 1) em PNGs individuais.

Cada folha e uma grade 3x2. Cada celula e recortada pelo conteudo (bounding box
apos tirar o magenta) e salva com uma margem minima, porque o jogo desenha cada
VFX centralizada e escalada pelo maior lado.

Tambem desloca o vazio roxo das folhas para o azul-marinho do corpo v3, sem
tocar nos verdes: as folhas foram geradas com a paleta antiga.

uso: python3 tools/umbra_skills_slice.py --out assets/sprites/umbra_skills f1.png ... f5.png
"""
import argparse, colorsys, os
from PIL import Image

# [(grupo, nome, indice)] na ordem das celulas de cada folha.
SHEETS = [
    [("plasma", "bolt", 1), ("plasma", "bolt", 2), ("plasma", "bolt", 3),
     ("plasma", "muzzle", 1), ("plasma", "impact", 1), ("plasma", "spark", 1)],
    [("teleporte", "portal", 1), ("teleporte", "portal", 2), ("teleporte", "portal", 3),
     ("teleporte", "afterimage", 1), ("teleporte", "fake", 1), ("teleporte", "arrive", 1)],
    [("sifao", "dome", 1), ("sifao", "dome", 2), ("sifao", "sigil", 1),
     ("sifao", "tendril", 1), ("sifao", "tendril", 2), ("sifao", "heal", 1)],
    [("rebobinar", "hourglass", 1), ("rebobinar", "hourglass", 2), ("rebobinar", "clock", 1),
     ("rebobinar", "trail", 1), ("rebobinar", "snap", 1), ("rebobinar", "chain", 1)],
    [("eco", "sigil", 1), ("eco", "sigil", 2), ("eco", "blast", 1),
     ("eco", "blast", 2), ("eco", "blast", 3), ("eco", "eye", 1)],
]
MARGIN = 6


def key_and_retint(im):
    """Tira o fundo magenta e leva o vazio roxo para azul-marinho."""
    im = im.convert("RGBA")
    px = im.load()
    w, h = im.size
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            d = ((r - 255) ** 2 + g ** 2 + (b - 255) ** 2) ** 0.5
            if d < 120 or (r > 200 and b > 200 and g < 80):
                px[x, y] = (0, 0, 0, 0)
                continue
            if d < 190 and r > 150 and b > 150 and g < 140:
                k = (d - 120) / 70.0
                m = min(r, b, max(g, int(min(r, b) * 0.55)))
                px[x, y] = (min(r, m + 40), g, min(b, m + 40), int(255 * k))
                continue
            # Roxo/violeta -> azul-marinho, preservando o verde da UMBRA.
            hh, ll, ss = colorsys.rgb_to_hls(r / 255.0, g / 255.0, b / 255.0)
            deg = hh * 360.0
            if 255.0 <= deg <= 330.0 and ss > 0.12:
                deg = 228.0 + (deg - 255.0) * 0.16
                nr, ng, nb = colorsys.hls_to_rgb(deg / 360.0, ll * 0.96, min(1.0, ss * 1.02))
                px[x, y] = (int(nr * 255), int(ng * 255), int(nb * 255), a)
    return im


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("sheets", nargs=5)
    ap.add_argument("--out", required=True)
    ap.add_argument("--no-retint", action="store_true")
    a = ap.parse_args()
    total = 0
    for sheet_index, path in enumerate(a.sheets):
        src = Image.open(path)
        src = src.convert("RGBA") if a.no_retint else key_and_retint(src)
        w, h = src.size
        cw, ch = w // 3, h // 2
        for cell, (group, name, index) in enumerate(SHEETS[sheet_index]):
            cx, cy = cell % 3, cell // 3
            img = src.crop((cx * cw, cy * ch, cx * cw + cw, cy * ch + ch))
            alpha = img.split()[3].point(lambda v: 255 if v > 16 else 0)
            box = alpha.getbbox()
            if box is None:
                print("celula vazia:", path, cell)
                continue
            box = (max(0, box[0] - MARGIN), max(0, box[1] - MARGIN),
                   min(cw, box[2] + MARGIN), min(ch, box[3] + MARGIN))
            img = img.crop(box)
            folder = os.path.join(a.out, group)
            os.makedirs(folder, exist_ok=True)
            img.save(os.path.join(folder, "%s_%02d.png" % (name, index)))
            total += 1
    print("UMBRA_SKILLS_SLICED", total)


if __name__ == "__main__":
    main()
