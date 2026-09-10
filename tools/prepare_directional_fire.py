"""Rebuild transparent, ground-aligned firing frames from the generated source.

Offline art preparation only; requires Pillow, NumPy and SciPy. Runtime uses PNGs.
The user's approved cleanup preserves RGB values of retained character pixels.
"""
from pathlib import Path

import numpy as np
from PIL import Image
from scipy import ndimage

ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "assets/sprites/player/fire_directional"
DIRECTIONS = ("south", "north", "northeast", "northwest", "southwest", "southeast")


def main():
    rgb = np.array(Image.open(OUTPUT / "source_magenta.png").convert("RGB"))
    r, g, b = rgb.astype(float).transpose(2, 0, 1)
    foreground = ~((r > 100) & (b > 100) & (g < np.minimum(r, b) * 0.55))
    labels, _ = ndimage.label(foreground)
    boxes = ndimage.find_objects(labels)
    components = {}
    for label, box in enumerate(boxes, 1):
        count = np.count_nonzero(labels[box] == label)
        if count < 4:
            continue
        cy = (box[0].start + box[0].stop) / 2
        cx = (box[1].start + box[1].stop) / 2
        cell = (min(1, int(cy / 512)), min(5, int(cx / 256)))
        components.setdefault(cell, []).append((label, count, box))

    for (row, column), parts in sorted(components.items()):
        body_label, _, body_box = max(parts, key=lambda part: part[1])
        ground = body_box[0].stop - 1
        feet_y, feet_x = np.where((labels == body_label) & (np.indices(labels.shape)[0] >= ground - 26))
        assert feet_y.size
        center_x = int(round((int(feet_x.min()) + int(feet_x.max())) / 2))
        alpha = np.isin(labels, [part[0] for part in parts]).astype(np.uint8) * 255
        rgba = np.dstack((rgb, alpha))
        rgba[alpha == 0, :3] = 0
        frame = Image.fromarray(rgba).crop((center_x - 128, ground - 429, center_x + 128, ground + 1))
        assert frame.size == (256, 430)
        assert frame.getbbox()[3] == 430
        frame.save(OUTPUT / f"{DIRECTIONS[column]}_{row}.png")
        print(f"{DIRECTIONS[column]}_{row}: ground={ground}, center={center_x}, body_height={body_box[0].stop-body_box[0].start}")


if __name__ == "__main__":
    main()
