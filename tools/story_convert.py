#!/usr/bin/env python3
"""Converte os PNGs da HQ (assets/story/_source) em JPG 1280x720 usados pelo jogo."""
import glob, os
from PIL import Image

root = os.path.join(os.path.dirname(__file__), "..", "assets", "story")
for src in sorted(glob.glob(os.path.join(root, "_source", "*.png"))):
    name = os.path.splitext(os.path.basename(src))[0]
    dst = os.path.join(root, name + ".jpg")
    if os.path.exists(dst) and os.path.getmtime(dst) >= os.path.getmtime(src):
        continue
    Image.open(src).convert("RGB").resize((1280, 720), Image.LANCZOS).save(dst, quality=88, optimize=True)
    print("convertido", name)
