"""Create deterministic damage frames from the canonical Geo stop sprites.

The effect is deliberately derived from the exact stop pixels: only channel offsets,
horizontal slices and sparse temporal fragments are added. This keeps identity and
proportions stable while giving the hit a readable temporal-glitch progression.
"""
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SPRITES = ROOT / "assets/sprites"
OUTPUT = SPRITES / "player/damage"
OUTPUT.mkdir(parents=True, exist_ok=True)


def shift_rgba(source: np.ndarray, amount: int) -> np.ndarray:
    result = np.zeros_like(source)
    if amount >= 0:
        result[:, amount:] = source[:, : source.shape[1] - amount]
    else:
        result[:, :amount] = source[:, -amount:]
    return result


def band_shift(source: np.ndarray, y0: int, y1: int, amount: int) -> np.ndarray:
    result = np.zeros_like(source)
    result[y0:y1] = shift_rgba(source[y0:y1], amount)
    return result


def make_frame(frame: int) -> Image.Image:
    base_name = "Geo1.png" if frame in (0, 2) else "Geo2.png"
    base = np.array(Image.open(SPRITES / base_name).convert("RGBA"), dtype=np.uint8)
    h, w, _ = base.shape
    alpha = base[:, :, 3]
    result = np.zeros_like(base)
    # Keep the exact original colors as the readable foundation.
    result[:, :, :3] = base[:, :, :3]
    result[:, :, 3] = alpha

    severity = [0.22, 0.52, 0.82, 0.36][frame]
    channel_offset = [1, 2, 4, 2][frame]
    red = shift_rgba(base, channel_offset)
    blue = shift_rgba(base, -channel_offset)
    active = alpha > 0
    # Chromatic edges are clipped by the source silhouette, never repainting the body.
    for channel, shifted in ((0, red), (2, blue)):
        edge_alpha = (shifted[:, :, 3].astype(float) * severity * 0.62).astype(np.uint8)
        edge_alpha[~active] = np.maximum(edge_alpha[~active], (shifted[:, :, 3][~active] * severity * 0.28).astype(np.uint8))
        result[:, :, channel] = np.maximum(result[:, :, channel], shifted[:, :, channel])
        result[:, :, 3] = np.maximum(result[:, :, 3], edge_alpha)

    # Horizontal slices progress from a small hit twitch into a readable rupture.
    slice_count = [2, 4, 7, 3][frame]
    slice_height = max(3, int(round(4 + severity * 5)))
    for i in range(slice_count):
        y0 = int((17 + i * 37 + frame * 11) % max(1, h - slice_height))
        y1 = min(h, y0 + slice_height)
        amount = int(round(((-1 if i % 2 else 1) * (3 + frame * 3 + i))))
        shifted = band_shift(base, y0, y1, amount)
        band_alpha = (shifted[y0:y1, :, 3].astype(float) * (0.46 + severity * 0.35)).astype(np.uint8)
        result[y0:y1, :, :3] = shifted[y0:y1, :, :3]
        result[y0:y1, :, 3] = np.maximum(result[y0:y1, :, 3], band_alpha)

        # Detached pixels make the displacement visible without adding a new object.
        if frame in (1, 2):
            fragment = band_shift(base, y0, y1, amount + (5 if i % 2 else -5))
            frag_alpha = (fragment[y0:y1, :, 3].astype(float) * (0.24 + severity * 0.2)).astype(np.uint8)
            result[y0:y1, :, :3] = np.where(frag_alpha[:, :, None] > 0, fragment[y0:y1, :, :3], result[y0:y1, :, :3])
            result[y0:y1, :, 3] = np.maximum(result[y0:y1, :, 3], frag_alpha)

    # Cyan/magenta pixel sparks stay near the existing silhouette bounding box.
    ys, xs = np.where(alpha > 0)
    rng = np.random.default_rng(4100 + frame)
    for _ in range(5 + frame * 3):
        idx = int(rng.integers(0, len(xs)))
        x = int(xs[idx] + rng.integers(-8 - frame * 2, 9 + frame * 2))
        y = int(ys[idx] + rng.integers(-4, 5))
        if 1 <= x < w - 1 and 1 <= y < h - 1:
            color = np.array([45, 225, 255, int(110 + severity * 105)] if _ % 2 == 0 else [255, 50, 190, int(90 + severity * 100)], dtype=np.uint8)
            result[y, x] = color
            if frame >= 2 and _ % 3 == 0:
                result[y, x - 1] = color
                result[y, x + 1] = color

    # No opaque background and no resampling: native 165x254 stop canvas.
    result[:, :, 3] = np.minimum(result[:, :, 3], 255)
    out = Image.fromarray(result, "RGBA")
    out.save(OUTPUT / f"Geo_Damage{frame + 1}.png")
    return out


def main() -> None:
    for frame in range(4):
        image = make_frame(frame)
        print(f"Geo_Damage{frame + 1}.png {image.size} {image.mode} bbox={image.getbbox()}")


if __name__ == "__main__":
    main()
