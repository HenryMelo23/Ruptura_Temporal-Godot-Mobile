#!/usr/bin/env python3
"""Recorta as folhas do Codex da Dimensao 8 (Sertao das Tartarugas).

Uso:
  python3 tools/sertao_slice.py            # recorta as folhas que existirem
  python3 tools/sertao_slice.py --placeholders   # gera silhuetas provisorias

Entradas (copiadas pelo Codex sem alteracao):
  .agent_logs/codex_umbra/sertao_enemies.png      1254x1254, 4x4
  .agent_logs/codex_umbra/sertao_cangaceiro.png   1254x1254, 4x4
  .agent_logs/codex_umbra/sertao_boss_a.png       1254x1254, 4x4
  .agent_logs/codex_umbra/sertao_boss_b.png       1254x627,  4x2
  .agent_logs/codex_umbra/sertao_terrain_atlas.png 1254x1254
  .agent_logs/codex_umbra/arrive8_wide.jpg ... boss8_fragment.jpg

Saidas: assets/sprites/sertao/<chave>_<n>.png (fundo transparente),
assets/sprites/experimental/phase_ex8_terrain_atlas.png e assets/story/*.jpg.

Cada grupo de quadros (uma linha da folha) e normalizado junto: a mesma escala e
a mesma linha de base (pes) para todos os quadros do grupo, para a animacao nao
"pular".
"""
import os
import sys
from PIL import Image, ImageDraw

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
SRC = os.path.join(ROOT, ".agent_logs", "codex_umbra")
OUT = os.path.join(ROOT, "assets", "sprites", "sertao")

# (folha, colunas, linhas, [(chave, [(col, lin), ...], tamanho_saida)])
SHEETS = [
    ("sertao_enemies.png", 4, 4, [
        ("s8_jabuti", [(0, 0), (1, 0), (2, 0), (3, 0)], 160),
        ("s8_mandacaru", [(0, 1), (1, 1), (2, 1), (3, 1)], 220),
        ("s8_morteiro", [(0, 2), (1, 2), (2, 2), (3, 2)], 200),
        ("s8_piao", [(0, 3), (1, 3), (2, 3), (3, 3)], 180),
    ]),
    ("sertao_cangaceiro.png", 4, 4, [
        ("s8_cangaceiro", [(c, r) for r in range(4) for c in range(4)], 300),
    ]),
    ("sertao_boss_a.png", 4, 4, [
        ("boss8_walk", [(0, 0), (1, 0), (2, 0), (3, 0)], 420),
        ("boss8_cast", [(0, 1), (1, 1), (2, 1), (3, 1)], 420),
        ("boss8_retract", [(0, 2), (1, 2)], 420),
        ("boss8_roll", [(2, 2), (3, 2)], 420),
        ("boss8_eclipse", [(0, 3), (1, 3), (2, 3), (3, 3)], 420),
    ]),
    ("sertao_boss_b.png", 4, 2, [
        ("boss8_death", [(0, 0), (1, 0), (2, 0), (3, 0)], 420),
        ("boss8_hurt", [(0, 1)], 420),
        ("boss8_sun", [(1, 1)], 420),
        ("s8_egg", [(2, 1), (3, 1)], 120),
    ]),
]


def is_key(px):
    r, g, b = px[0], px[1], px[2]
    return r > 200 and b > 200 and g < 90


def cell_image(sheet, cols, rows, col, row):
    w, h = sheet.size
    cw, ch = w / cols, h / rows
    box = (int(col * cw), int(row * ch), int((col + 1) * cw), int((row + 1) * ch))
    cell = sheet.crop(box).convert("RGBA")
    pix = cell.load()
    for y in range(cell.size[1]):
        for x in range(cell.size[0]):
            p = pix[x, y]
            if is_key(p):
                pix[x, y] = (0, 0, 0, 0)
            elif p[0] > 170 and p[2] > 170 and p[1] < 120:
                # Franja rosada do anti-aliasing: escurece e deixa meio transparente.
                pix[x, y] = (p[0] // 3, p[1] // 3, p[2] // 3, 110)
    return cell


def group(sheet, cols, rows, cells, out_size, key):
    imgs = [cell_image(sheet, cols, rows, c, r) for c, r in cells]
    boxes = [im.getbbox() or (0, 0, 1, 1) for im in imgs]
    max_w = max(b[2] - b[0] for b in boxes)
    max_h = max(b[3] - b[1] for b in boxes)
    scale = (out_size - 8) / max(max_w, max_h)
    for i, (im, b) in enumerate(zip(imgs, boxes)):
        part = im.crop(b)
        part = part.resize((max(1, int(part.size[0] * scale)), max(1, int(part.size[1] * scale))), Image.NEAREST)
        canvas = Image.new("RGBA", (out_size, out_size), (0, 0, 0, 0))
        x = (out_size - part.size[0]) // 2
        y = out_size - 4 - part.size[1]  # todos com os pes na mesma linha
        canvas.paste(part, (x, y), part)
        canvas.save(os.path.join(OUT, "%s_%d.png" % (key, i)))
    print("ok", key, len(imgs))


def slice_all():
    os.makedirs(OUT, exist_ok=True)
    for name, cols, rows, groups in SHEETS:
        path = os.path.join(SRC, name)
        if not os.path.exists(path):
            print("faltando", name)
            continue
        sheet = Image.open(path).convert("RGB")
        for key, cells, size in groups:
            group(sheet, cols, rows, cells, size, key)
    atlas = os.path.join(SRC, "sertao_terrain_atlas.png")
    if os.path.exists(atlas):
        from PIL import ImageEnhance
        im = Image.open(atlas).convert("RGB").resize((1254, 1254), Image.LANCZOS)
        # Chao um pouco mais apagado: os projeteis brilhantes precisam ler por cima.
        im = ImageEnhance.Color(im).enhance(0.78)
        im = ImageEnhance.Brightness(im).enhance(0.86)
        im.save(os.path.join(ROOT, "assets", "sprites", "experimental", "phase_ex8_terrain_atlas.png"))
        print("ok atlas")
    for story in ["arrive8_wide", "arrive8_react", "boss8_defeat", "boss8_fragment"]:
        for ext in (".jpg", ".png"):
            p = os.path.join(SRC, story + ext)
            if os.path.exists(p):
                Image.open(p).convert("RGB").resize((1280, 720), Image.LANCZOS).save(os.path.join(ROOT, "assets", "story", story + ".jpg"), quality=90)
                print("ok", story)
                break


# ---------------------------------------------------------------- provisorios
def _turtle(size, shell, skin, kind, frame):
    im = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    s = size / 160.0
    base = size - 6
    leg = int(4 * s) * (1 if frame % 2 == 0 else -1)
    retracted = kind == "shell"
    if not retracted:
        for lx in (45, 70, 95, 118):
            off = leg if lx in (45, 95) else -leg
            d.rectangle([int((lx - 7) * s) + off, base - int(26 * s), int((lx + 7) * s) + off, base], fill=skin, outline=(30, 16, 8))
        d.ellipse([int(118 * s), base - int(62 * s), int(152 * s), base - int(32 * s)], fill=skin, outline=(30, 16, 8))
        d.ellipse([int(138 * s), base - int(54 * s), int(144 * s), base - int(48 * s)], fill=(255, 200, 60))
    d.pieslice([int(20 * s), base - int(100 * s), int(140 * s), base + int(10 * s)], 180, 360, fill=shell, outline=(30, 16, 8), width=max(1, int(2 * s)))
    d.rectangle([int(22 * s), base - int(46 * s), int(138 * s), base - int(36 * s)], fill=tuple(max(0, c - 40) for c in shell[:3]), outline=(30, 16, 8))
    for i in range(3):
        cx = int((50 + i * 30) * s)
        d.ellipse([cx - int(9 * s), base - int(84 * s), cx + int(9 * s), base - int(66 * s)], fill=tuple(min(255, c + 50) for c in shell[:3]))
    d.line([int(60 * s), base - int(80 * s), int(90 * s), base - int(60 * s)], fill=(190, 110, 255), width=max(1, int(2 * s)))
    return im


def placeholders():
    os.makedirs(OUT, exist_ok=True)
    specs = {
        "s8_jabuti": (160, (92, 58, 34), (196, 72, 40)),
        "s8_mandacaru": (220, (70, 128, 60), (190, 170, 130)),
        "s8_morteiro": (200, (150, 96, 60), (130, 120, 108)),
        "s8_piao": (180, (100, 112, 50), (140, 150, 90)),
    }
    for key, (size, shell, skin) in specs.items():
        for i in range(4):
            kind = "shell" if (key in ("s8_jabuti", "s8_piao") and i >= 2) else "walk"
            im = _turtle(size, shell, skin, kind, i)
            if key == "s8_mandacaru":
                d = ImageDraw.Draw(im)
                s = size / 160.0
                for k in range(3):
                    x = int((55 + k * 25) * s)
                    d.rectangle([x - int(6 * s), int(20 * s), x + int(6 * s), int(80 * s)], fill=(60, 150, 60) if i < 2 else (120, 220, 80), outline=(20, 50, 20))
            im.save(os.path.join(OUT, "%s_%d.png" % (key, i)))
    # Cangaceiro: tartaruga em pe com chapeu.
    for i in range(16):
        size = 300
        im = Image.new("RGBA", (size, size), (0, 0, 0, 0))
        d = ImageDraw.Draw(im)
        if i in (12, 13):
            d.pieslice([60, 150, 240, 300], 180, 360, fill=(54, 84, 50), outline=(20, 30, 16), width=3)
        else:
            d.ellipse([95, 90, 205, 280], fill=(54, 84, 50), outline=(20, 30, 16), width=3)
            d.ellipse([112, 120, 188, 250], fill=(196, 170, 110))
            d.line([110, 130, 190, 230], fill=(120, 70, 30), width=8)
            d.line([190, 130, 110, 230], fill=(120, 70, 30), width=8)
            d.ellipse([120, 40, 180, 100], fill=(120, 140, 90), outline=(20, 30, 16), width=2)
            d.pieslice([90, 10, 210, 90], 180, 360, fill=(130, 80, 40), outline=(40, 20, 10), width=2)
            if 4 <= i < 8:
                d.rectangle([200, 150, 250, 160], fill=(80, 80, 90))
                if i % 2 == 1:
                    d.ellipse([245, 140, 270, 170], fill=(255, 220, 90))
        im.save(os.path.join(OUT, "s8_cangaceiro_%d.png" % i))
    # Chefe: jabuti colossal com relogio de sol no casco.
    keys = {"boss8_walk": 4, "boss8_cast": 4, "boss8_retract": 2, "boss8_roll": 2, "boss8_eclipse": 4, "boss8_death": 4, "boss8_hurt": 1, "boss8_sun": 1}
    for key, n in keys.items():
        for i in range(n):
            size = 420
            im = _turtle(size, (150, 120, 84), (176, 128, 90), "shell" if key in ("boss8_retract", "boss8_roll") and i >= (1 if key == "boss8_retract" else 0) else "walk", i)
            d = ImageDraw.Draw(im)
            cx, cy = 210, 230
            glow = (120, 230, 255) if key == "boss8_eclipse" else (255, 210, 90)
            for h in range(12):
                import math
                a = -math.pi / 2 + h * math.pi / 6
                x, y = cx + math.cos(a) * 95, cy + math.sin(a) * 40
                d.ellipse([x - 6, y - 6, x + 6, y + 6], fill=glow)
            d.polygon([(cx - 14, cy), (cx + 14, cy), (cx, cy - 110)], fill=(170, 150, 120), outline=(40, 30, 20))
            if key == "boss8_sun":
                d.ellipse([cx - 30, cy - 140, cx + 30, cy - 80], fill=(255, 250, 220))
            if key == "boss8_death":
                for k in range(i + 1):
                    d.line([cx - 80 + k * 40, cy - 30, cx - 60 + k * 40, cy + 40], fill=(255, 220, 120), width=5)
            im.save(os.path.join(OUT, "%s_%d.png" % (key, i)))
    for i in range(2):
        im = Image.new("RGBA", (120, 120), (0, 0, 0, 0))
        d = ImageDraw.Draw(im)
        d.ellipse([28, 14, 92, 112], fill=(236, 226, 200), outline=(80, 60, 40), width=3)
        if i == 1:
            d.line([40, 60, 60, 50, 80, 64], fill=(80, 60, 40), width=4)
        im.save(os.path.join(OUT, "s8_egg_%d.png" % i))
    # Chao provisorio: atlas da fase 7 recolorido para ocre.
    src = os.path.join(ROOT, "assets", "sprites", "experimental", "phase_ex7_terrain_atlas.png")
    dst = os.path.join(ROOT, "assets", "sprites", "experimental", "phase_ex8_terrain_atlas.png")
    if not os.path.exists(dst):
        im = Image.open(src).convert("L")
        lut = []
        lo, hi = (92, 66, 44), (214, 170, 112)
        for ch in range(3):
            lut.extend([int(lo[ch] + (hi[ch] - lo[ch]) * min(1.0, v / 120.0)) for v in range(256)])
        im.convert("RGB").point(lut).save(dst)
    print("placeholders ok")


if __name__ == "__main__":
    if "--placeholders" in sys.argv:
        placeholders()
    else:
        slice_all()
