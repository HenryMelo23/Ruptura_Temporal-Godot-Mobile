#!/usr/bin/env python3
"""Normalize every Parasitica firing frame to the idle silhouette height.

The source art is kept pixel-sharp: only one nearest-neighbour scale is applied,
then the visible bounds are centered on the idle frame's horizontal center and
placed on its exact foot baseline. Re-running the script is idempotent.
"""

from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
PARASITICA = ROOT / "assets/sprites/player/parasitica"
IDLE = PARASITICA / "idle/parasitica_idle_0.png"
FIRE_GLOBS = ("fire/*.png", "fire_directional/*.png")


def alpha_bounds(image: Image.Image) -> tuple[int, int, int, int]:
    bounds = image.getchannel("A").getbbox()
    if bounds is None:
        raise ValueError("sprite has no visible pixels")
    return bounds


def normalize(path: Path, target_height: int, target_center_x: float, target_bottom: int) -> None:
    source = Image.open(path).convert("RGBA")
    left, top, right, bottom = alpha_bounds(source)
    visible_height = bottom - top
    if visible_height == target_height and abs(((left + right) * 0.5) - target_center_x) <= 0.5 and bottom == target_bottom:
        return

    scale = target_height / float(visible_height)
    crop = source.crop((left, top, right, bottom))
    scaled_size = (
        max(1, round(crop.width * scale)),
        target_height,
    )
    scaled = crop.resize(scaled_size, Image.Resampling.NEAREST)
    destination = Image.new("RGBA", source.size, (0, 0, 0, 0))
    paste_x = round(target_center_x - scaled.width * 0.5)
    paste_y = target_bottom - scaled.height
    if paste_x < 2 or paste_y < 2 or paste_x + scaled.width > source.width - 2 or paste_y + scaled.height > source.height - 2:
        raise ValueError(f"{path}: normalized sprite would touch the canvas edge")
    destination.alpha_composite(scaled, (paste_x, paste_y))
    destination.save(path, optimize=True)


def main() -> None:
    idle = Image.open(IDLE).convert("RGBA")
    left, top, right, bottom = alpha_bounds(idle)
    target_height = bottom - top
    target_center_x = (left + right) * 0.5
    paths = sorted(path for pattern in FIRE_GLOBS for path in PARASITICA.glob(pattern))
    for path in paths:
        normalize(path, target_height, target_center_x, bottom)
    print(f"PARASITICA_FIRE_NORMALIZED frames={len(paths)} visible_height={target_height} baseline={bottom}")


if __name__ == "__main__":
    main()
