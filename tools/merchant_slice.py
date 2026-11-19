#!/usr/bin/env python3
"""Recorta as folhas do Mercador em PNGs individuais.

Folhas 1 e 2 (grade 3x2): poses, retratos, teleportador e portal.
Folhas 3 e 4 (grade 5x3): moveis, maquinas, miudezas e marcas de chao.

As quatro poses de corpo inteiro compartilham UM unico recorte (bbox da uniao),
senao a escala e o pe da personagem pulariam entre os quadros da animacao: a
apresentacao normaliza pela altura e ancora no pe. Todo o resto e recortado
pelo proprio conteudo.

uso:
  python3 tools/merchant_slice.py --out assets/sprites/merchant f1.png f2.png
  python3 tools/merchant_slice.py --out assets/sprites/merchant \\
      --layout props1 props1.png --layout props2 props2.png
"""
import argparse
import os

from PIL import Image

# nome -> (colunas, linhas, [(arquivo, usa_bbox_comum)])
LAYOUTS = {
    "poses": (3, 2, [
        ("merchant_idle_01", True), ("merchant_idle_02", True),
        ("merchant_work", True), ("merchant_cheer", True),
        ("portrait_mercador", False), ("portrait_mercador_sad", False),
    ]),
    "objects": (3, 2, [
        ("teleporter", False), ("teleporter_off", False), ("exit_portal", False),
        ("counter", False), ("part", False), ("scrap", False),
    ]),
    "props1": (5, 3, [
        ("shelf_tall", False), ("shelf_low", False), ("workbench", False),
        ("forge", False), ("stove", False),
        ("generator", False), ("ring_half", False), ("safe", False),
        ("barrel", False), ("crates", False),
        ("maptable", False), ("armchair", False), ("scales", False),
        ("cabinet", False), ("wheelbarrow", False),
    ]),
    "props2": (5, 3, [
        ("lamp_floor", False), ("lamp_hanging", False), ("plant", False),
        ("toolbox", False), ("cables", False),
        ("coil", False), ("books", False), ("sign", False),
        ("decal_rug", False), ("decal_oil", False),
        ("decal_scorch", False), ("decal_bolts", False), ("decal_coins", False),
        ("pet", False), ("crate_fallen", False),
    ]),
}
MARGIN = 4
# Maior lado guardado por asset: ~1.5x o tamanho que o jogo desenha, para
# nitidez sem carregar textura gigante no celular.
MAX_SIDE = {
    "merchant_idle_01": 260, "merchant_idle_02": 260,
    "merchant_work": 260, "merchant_cheer": 260,
    "portrait_mercador": 256, "portrait_mercador_sad": 256,
    "teleporter": 384, "teleporter_off": 384,
    "exit_portal": 224, "counter": 288, "part": 128, "scrap": 256,
}
# Moveis grandes guardam mais pixel; miudeza e marca de chao guardam menos.
BIG_PROPS = {"shelf_tall", "forge", "ring_half", "cabinet", "generator", "stove", "armchair", "maptable"}
DEFAULT_PROP_SIDE = 224
BIG_PROP_SIDE = 288


def max_side(name):
    if name in MAX_SIDE:
        return MAX_SIDE[name]
    return BIG_PROP_SIDE if name in BIG_PROPS else DEFAULT_PROP_SIDE


def shrink(img, name):
    limit = max_side(name)
    side = max(img.size)
    if limit <= 0 or side <= limit:
        return img
    k = limit / float(side)
    return img.resize((max(1, round(img.size[0] * k)), max(1, round(img.size[1] * k))), Image.LANCZOS)


def key_magenta(im):
    """Tira o fundo magenta chapado, com meio-tom nas bordas do anti-alias."""
    im = im.convert("RGBA")
    px = im.load()
    w, h = im.size
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            d = ((r - 255) ** 2 + g ** 2 + (b - 255) ** 2) ** 0.5
            if d < 120:
                px[x, y] = (0, 0, 0, 0)
            elif d < 190 and r > 150 and b > 150 and g < 140:
                k = (d - 120) / 70.0
                m = min(r, b, max(g, int(min(r, b) * 0.55)))
                px[x, y] = (min(r, m + 40), g, min(b, m + 40), int(255 * k))
    return im


def cells(src, cols, rows):
    w, h = src.size
    cw, ch = w // cols, h // rows
    out = []
    for cell in range(cols * rows):
        cx, cy = cell % cols, cell // cols
        out.append(src.crop((cx * cw, cy * ch, cx * cw + cw, cy * ch + ch)))
    return out, cw, ch


def bbox_of(img):
    alpha = img.split()[3].point(lambda v: 255 if v > 16 else 0)
    return alpha.getbbox()


def union(boxes):
    boxes = [b for b in boxes if b is not None]
    if not boxes:
        return None
    return (min(b[0] for b in boxes), min(b[1] for b in boxes),
            max(b[2] for b in boxes), max(b[3] for b in boxes))


def pad(box, cw, ch):
    return (max(0, box[0] - MARGIN), max(0, box[1] - MARGIN),
            min(cw, box[2] + MARGIN), min(ch, box[3] + MARGIN))


def cut(sheet_path, layout_name, out_dir):
    cols, rows, entries = LAYOUTS[layout_name]
    src = key_magenta(Image.open(sheet_path))
    imgs, cw, ch = cells(src, cols, rows)
    shared = union([bbox_of(imgs[i]) for i, (_, common) in enumerate(entries) if common])
    saved = 0
    for i, (name, common) in enumerate(entries):
        box = shared if common else bbox_of(imgs[i])
        if box is None:
            print("celula vazia:", sheet_path, i)
            continue
        img = shrink(imgs[i].crop(pad(box, cw, ch)), name)
        img.save(os.path.join(out_dir, name + ".png"))
        print("  %-24s %dx%d" % (name, img.size[0], img.size[1]))
        saved += 1
    return saved


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("sheets", nargs="*", help="folha de poses e folha de objetos (grade 3x2)")
    ap.add_argument("--layout", nargs=2, action="append", metavar=("NOME", "FOLHA"),
                    default=[], help="recorta FOLHA com o layout NOME")
    ap.add_argument("--out", required=True)
    a = ap.parse_args()
    os.makedirs(a.out, exist_ok=True)
    jobs = []
    if a.sheets:
        if len(a.sheets) != 2:
            ap.error("passe as duas folhas 3x2 ou use --layout")
        jobs = [("poses", a.sheets[0]), ("objects", a.sheets[1])]
    jobs += [(name, path) for name, path in a.layout]
    total = 0
    for layout_name, path in jobs:
        if layout_name not in LAYOUTS:
            ap.error("layout desconhecido: %s" % layout_name)
        print(path, "->", layout_name)
        total += cut(path, layout_name, a.out)
    fallback = os.path.join(a.out, "merchant.png")
    idle = os.path.join(a.out, "merchant_idle_01.png")
    if os.path.exists(idle):
        # Fallback usado pela apresentacao quando nao ha quadro de animacao.
        Image.open(idle).save(fallback)
        total += 1
    print("MERCHANT_SLICED", total)


if __name__ == "__main__":
    main()
