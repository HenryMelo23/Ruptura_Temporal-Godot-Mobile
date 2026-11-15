#!/usr/bin/env python3
"""Desenha as formas de colisao (tools/map_collision_shapes.json) por cima do recorte
de cada ladrilho como ele aparece no jogo, para conferir o contorno.
Saida: .agent_logs/map_collision/<map_key>.png
"""
import json
import os
from PIL import Image, ImageDraw

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
ATLAS_DIR = os.path.join(ROOT, "assets", "sprites", "experimental")
OUT = os.path.join(ROOT, ".agent_logs", "map_collision")
INSET = 0.095
G = 240
FILES = {"map_phase_ex": "phase_ex_terrain_atlas.png"}
for n in range(2, 9):
    FILES["map_phase_ex%d" % n] = "phase_ex%d_terrain_atlas.png" % n


def main():
    shapes = json.load(open(os.path.join(ROOT, "tools", "map_collision_shapes.json"), encoding="utf-8"))
    os.makedirs(OUT, exist_ok=True)
    for key, fn in FILES.items():
        im = Image.open(os.path.join(ATLAS_DIR, fn)).convert("RGB")
        T = im.size[0] / 4
        sheet = Image.new("RGB", (4 * (G + 8), 4 * (G + 8)))
        for t in range(16):
            tx, ty = t % 4, t // 4
            x0 = tx * T + INSET * T
            y0 = ty * T + INSET * T
            s = T * (1 - 2 * INSET)
            tile = im.crop((int(x0), int(y0), int(x0 + s), int(y0 + s))).resize((G, G), Image.LANCZOS).convert("RGBA")
            ov = Image.new("RGBA", (G, G))
            d = ImageDraw.Draw(ov)
            for sh in shapes.get(key, {}).get(str(t), []):
                if "p" in sh:
                    d.polygon([(x * G, y * G) for x, y in sh["p"]], fill=(0, 255, 255, 70), outline=(0, 255, 255, 255))
                else:
                    x, y, r = sh["c"]
                    d.ellipse([(x - r) * G, (y - r) * G, (x + r) * G, (y + r) * G], fill=(0, 255, 255, 70), outline=(0, 255, 255, 255))
            tile = Image.alpha_composite(tile, ov).convert("RGB")
            ImageDraw.Draw(tile).text((4, 4), "T%d" % t, fill=(255, 255, 255))
            sheet.paste(tile, ((t % 4) * (G + 8), (t // 4) * (G + 8)))
        sheet.save(os.path.join(OUT, key + ".png"))
        print("ok", key)


if __name__ == "__main__":
    main()
