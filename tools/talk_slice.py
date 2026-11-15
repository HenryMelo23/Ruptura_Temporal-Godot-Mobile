#!/usr/bin/env python3
"""Fatia as folhas do Mercador animado e dos retratos falando.

Entrada: .agent_logs/codex_umbra/{merchant_loops1,merchant_loops2,
portraits_geovana1,portraits_geovana2,portraits_mercador}.png (magenta).
Saida em assets/sprites/merchant/:
  merchant_<idle|work|talk|cheer>_loop_<n>.png  caixa fixa por folha:
      altura LOOP_BOX_H*S, largura LOOP_BOX_W*S, pes na base (S = altura
      dele em pe no 1o quadro). A presentation usa LOOP_BOX_H para escalar.
  portrait_<quem>[_<humor>].png, ..._talk_0..3.png, ..._blink.png
      mesma caixa para a folha inteira (boca/olhos nao pulam).
Uso: python3 tools/talk_slice.py [raiz]
"""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rift_slice import key, cells, bbox, save
from PIL import Image

ROOT = sys.argv[1] if len(sys.argv) > 1 else os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, ".agent_logs", "codex_umbra")
OUT = os.path.join(ROOT, "assets", "sprites", "merchant")
LOOP_BOX_H = 1.3
LOOP_BOX_W = 1.9
LOOP_OUT_S = 200
FOOT_PAD = 0.03
PORTRAIT_OUT = 256


def loops(sheet, cols, rows, groups):
    cs = cells(key(Image.open(os.path.join(SRC, sheet))), cols, rows)
    ref = bbox(cs[0])
    S = ref[3] - ref[1]
    cx = (ref[0] + ref[2]) / 2.0
    feet = ref[3]
    bw, bh = LOOP_BOX_W * S, LOOP_BOX_H * S
    left, top = cx - bw / 2.0, feet + FOOT_PAD * S - bh
    ow, oh = round(LOOP_BOX_W * LOOP_OUT_S), round(LOOP_BOX_H * LOOP_OUT_S)
    for name, idxs in groups.items():
        clipped = 0
        for n, i in enumerate(idxs):
            cell = cs[i]
            bb = bbox(cell)
            if bb and (bb[0] < left or bb[2] > left + bw or bb[1] < top or bb[3] > top + bh):
                clipped += 1
            canvas = Image.new("RGBA", (round(bw), round(bh)), (0, 0, 0, 0))
            canvas.paste(cell, (round(-left), round(-top)), cell)
            save(canvas.resize((ow, oh), Image.LANCZOS), os.path.join(OUT, "%s_%d.png" % (name, n)))
        print("%s: %s %d quadros (S=%d, %d passam da caixa)" % (sheet, name, len(idxs), S, clipped))


def portraits(sheet, who, suffixes):
    cs = cells(key(Image.open(os.path.join(SRC, sheet))), 4, 4)
    boxes = [b for b in (bbox(c) for c in cs) if b]
    u = [min(b[0] for b in boxes), min(b[1] for b in boxes), max(b[2] for b in boxes), max(b[3] for b in boxes)]
    side = max(u[2] - u[0], u[3] - u[1])
    cx = (u[0] + u[2]) / 2.0
    box = (round(cx - side / 2.0), u[3] - side, round(cx + side / 2.0), u[3])
    for row, suffix in enumerate(suffixes):
        base = "portrait_%s%s" % (who, ("_" + suffix) if suffix else "")
        frames = []
        for col in range(4):
            cell = cs[row * 4 + col]
            canvas = Image.new("RGBA", (box[2] - box[0], box[3] - box[1]), (0, 0, 0, 0))
            canvas.paste(cell, (-box[0], -box[1]), cell)
            frames.append(canvas.resize((PORTRAIT_OUT, PORTRAIT_OUT), Image.LANCZOS))
        closed, half, opened, blink = frames
        save(closed, os.path.join(OUT, base + ".png"))
        for n, im in enumerate([half, opened, half, closed]):
            save(im, os.path.join(OUT, "%s_talk_%d.png" % (base, n)))
        save(blink, os.path.join(OUT, base + "_blink.png"))
    print("%s: %d humores" % (sheet, len(suffixes)))


if __name__ == "__main__":
    loops("merchant_loops1.png", 4, 4, {"merchant_idle_loop": list(range(0, 8)), "merchant_work_loop": list(range(8, 16))})
    loops("merchant_loops2.png", 4, 3, {"merchant_talk_loop": list(range(0, 6)), "merchant_cheer_loop": list(range(6, 12))})
    portraits("portraits_geovana1.png", "geovana", ["", "surprised", "suspicious", "annoyed"])
    portraits("portraits_geovana2.png", "geovana", ["determined", "worried", "sad", "happy"])
    portraits("portraits_mercador.png", "mercador", ["", "sad", "excited", "worried"])
