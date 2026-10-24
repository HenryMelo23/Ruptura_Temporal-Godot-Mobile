#!/usr/bin/env python3
"""Build Henry's Barometric atlases from approved authored sprite sources.

Movement, attack and HAB1 preserve Henry's existing 256x256 cells.  The
ultimate uses an authored eight-pose source sheet, then normalizes its palette,
pixel density and ground anchor to the canonical Henry sprites.
"""

from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
ASSET_DIR = ROOT / "assets/sprites/player/player_2_suit"
CELL = 256

WALK_SOURCE = ASSET_DIR / "henry_walk_sheet_v2.png"
ATTACK_SOURCE = ASSET_DIR / "henry_fire_sheet_v2.png"
CAST_SOURCE = ASSET_DIR / "henry_basic_cast_sheet_v2.png"
BAROMETRIC_ULTIMATE_SOURCE = ROOT / "tools/source_assets/henry_barometric_ultimate_source_v2.png"

WALK_OUTPUT = ASSET_DIR / "henry_barometric_walk_sheet_v1.png"
ATTACK_OUTPUT = ASSET_DIR / "henry_barometric_attack_sheet_v1.png"
CAST_OUTPUT = ASSET_DIR / "henry_barometric_cast_sheet_v1.png"
ULTIMATE_OUTPUT = ASSET_DIR / "henry_barometric_ultimate_sheet_v2.png"

def _load(path: Path) -> Image.Image:
    image = Image.open(path).convert("RGBA")
    if image.width % CELL or image.height % CELL:
        raise ValueError(f"{path.name} is not aligned to {CELL}px cells")
    return image


def _cell(sheet: Image.Image, row: int, column: int) -> Image.Image:
    return sheet.crop((column * CELL, row * CELL, (column + 1) * CELL, (row + 1) * CELL))


def _alpha_bbox(frame: Image.Image) -> tuple[int, int, int, int]:
    bbox = frame.getchannel("A").getbbox()
    if bbox is None:
        raise ValueError("empty authored frame")
    return bbox


def _hide_rear_tie(source: Image.Image) -> Image.Image:
    """Remove blue tie pixels only from a pure back-facing authored cell."""
    frame = source.copy()
    pixels = frame.load()
    for y in range(frame.height):
        for x in range(frame.width):
            red, green, blue, alpha = pixels[x, y]
            if alpha > 32 and blue > 90 and blue > red * 1.2 and blue > green * 1.15:
                pixels[x, y] = (34, 34, 48, alpha)
    return frame


def _compose_walk_pose(upper: Image.Image, lower: Image.Image, shift_x: int) -> Image.Image:
    """Recombine two approved walk cells without redrawing either body part."""
    result = Image.new("RGBA", (CELL, CELL), (0, 0, 0, 0))
    # The lower source owns the common ground anchor and legs. The upper source
    # owns head, face, arms, torso and visible tie. Their overlap sits inside
    # the dark suit/hip area, so no synthetic anatomy or rear tie is created.
    result.alpha_composite(lower.crop((0, 154, CELL, CELL)), (0, 154))
    result.alpha_composite(upper.crop((0, 0, CELL, 190)), (shift_x, 0))
    return result


def _sheet(columns: int, rows: int, frames: list[Image.Image]) -> Image.Image:
    if len(frames) != columns * rows:
        raise ValueError(f"expected {columns * rows} frames, received {len(frames)}")
    atlas = Image.new("RGBA", (columns * CELL, rows * CELL), (0, 0, 0, 0))
    for index, frame in enumerate(frames):
        atlas.alpha_composite(frame, ((index % columns) * CELL, (index // columns) * CELL))
    return atlas


def _build_walk(walk: Image.Image) -> Image.Image:
    frames: list[Image.Image] = []
    upper_columns = [1, 3, 0, 4, 2]
    upper_shifts = [-1, -2, -1, -2, 0]
    for row in range(3):
        for column in range(5):
            frame = _compose_walk_pose(_cell(walk, row, upper_columns[column]), _cell(walk, row, column), upper_shifts[column])
            frames.append(_hide_rear_tie(frame) if row == 2 else frame)
    return _sheet(5, 3, frames)


def _build_attack(attack: Image.Image, cast: Image.Image) -> Image.Image:
    frames: list[Image.Image] = []
    # Preserve the authored guard for each combo opening, then use Henry's
    # authored open-hand poses for pressure releases instead of the fire gun.
    source_columns = [(attack, 0), (cast, 1), (attack, 2), (cast, 2), (cast, 3)]
    for row in range(8):
        for source, source_column in source_columns:
            frame = _cell(source, row, source_column)
            frames.append(_hide_rear_tie(frame) if row == 6 else frame)
    return _sheet(5, 8, frames)


def _build_cast(cast: Image.Image) -> Image.Image:
    frames: list[Image.Image] = []
    attack = _load(ATTACK_SOURCE)
    sources = [(attack, 0), (cast, 1), (cast, 2), (cast, 3), (attack, 2)]
    for row in range(8):
        for source, source_column in sources:
            frame = _cell(source, row, source_column)
            frames.append(_hide_rear_tie(frame) if row == 6 else frame)
    return _sheet(5, 8, frames)


def _identity_palette(*sources: Image.Image) -> list[tuple[int, int, int]]:
    counts: dict[tuple[int, int, int], int] = {}
    for source in sources:
        for red, green, blue, alpha in source.get_flattened_data():
            if alpha < 224:
                continue
            color = (red, green, blue)
            counts[color] = counts.get(color, 0) + 1
    ranked = sorted(counts.items(), key=lambda item: item[1], reverse=True)
    base = [color for color, _count in ranked[:112]]
    # The blue tie occupies few pixels and would disappear from a palette based
    # only on global frequency. Keep its authored ramps explicitly.
    tie = [
        color
        for color, _count in ranked
        if color[2] > 70 and color[2] > color[0] * 1.2 and color[2] > color[1] * 1.12
    ][:48]
    return list(dict.fromkeys(base + tie))


def _normalize_ultimate_frame(frame: Image.Image, palette: list[tuple[int, int, int]]) -> Image.Image:
    solid_alpha = frame.getchannel("A").point(lambda alpha: 255 if alpha >= 80 else 0)
    bbox = solid_alpha.getbbox()
    if bbox is None:
        raise ValueError("empty authored ultimate frame")
    cropped = frame.crop(bbox)
    height = 232
    width = max(2, int(cropped.width * (height / cropped.height)) // 2 * 2)
    # Author at half resolution and expand by an integer factor so the result
    # has the same chunky two-pixel clusters as Henry's canonical sheets.
    half = cropped.resize((max(1, width // 2), max(1, height // 2)), Image.Resampling.LANCZOS)
    pixelated = half.resize((width, height), Image.Resampling.NEAREST)
    if width > 244:
        # Wide open-arm poses must not make Henry's head and torso shrink.
        # Preserve the central body at its uniform scale and compact only the
        # extended arm/leg margins into the 256px gameplay cell.
        core_width = min(160, width)
        source_side = (width - core_width) // 2
        target_side = (244 - core_width) // 2
        fitted = Image.new("RGBA", (244, height), (0, 0, 0, 0))
        left = pixelated.crop((0, 0, source_side, height)).resize((target_side, height), Image.Resampling.NEAREST)
        core = pixelated.crop((source_side, 0, source_side + core_width, height))
        right = pixelated.crop((source_side + core_width, 0, width, height)).resize((target_side, height), Image.Resampling.NEAREST)
        fitted.alpha_composite(left, (0, 0))
        fitted.alpha_composite(core, (target_side, 0))
        fitted.alpha_composite(right, (target_side + core_width, 0))
        pixelated = fitted
        width = pixelated.width
    pixels = pixelated.load()
    nearest_cache: dict[tuple[int, int, int], tuple[int, int, int]] = {}
    for y in range(height):
        for x in range(width):
            red, green, blue, alpha = pixels[x, y]
            if alpha < 80:
                pixels[x, y] = (0, 0, 0, 0)
                continue
            source_color = (red, green, blue)
            nearest = nearest_cache.get(source_color)
            if nearest is None:
                nearest = min(
                    palette,
                    key=lambda color: (color[0] - red) ** 2 + (color[1] - green) ** 2 + (color[2] - blue) ** 2,
                )
                nearest_cache[source_color] = nearest
            pixels[x, y] = (*nearest, 255)
    result = Image.new("RGBA", (CELL, CELL), (0, 0, 0, 0))
    result.alpha_composite(pixelated, ((CELL - width) // 2, 248 - height))
    return result


def _build_ultimate(identity: Image.Image, walk: Image.Image) -> Image.Image:
    source = Image.open(BAROMETRIC_ULTIMATE_SOURCE).convert("RGBA")
    palette = _identity_palette(identity, walk)
    x_edges = [round(index * source.width / 4.0) for index in range(5)]
    y_edges = [round(index * source.height / 2.0) for index in range(3)]
    frames: list[Image.Image] = []
    for index in range(8):
        column = index % 4
        row = index // 4
        raw = source.crop((x_edges[column], y_edges[row], x_edges[column + 1], y_edges[row + 1]))
        frames.append(_normalize_ultimate_frame(raw, palette))
    return _sheet(8, 1, frames)


def main() -> None:
    walk = _load(WALK_SOURCE)
    attack = _load(ATTACK_SOURCE)
    cast = _load(CAST_SOURCE)
    identity = _load(ASSET_DIR / "henry_idle_pocket_sheet_v1.png")

    outputs = {
        WALK_OUTPUT: _build_walk(walk),
        ATTACK_OUTPUT: _build_attack(attack, cast),
        CAST_OUTPUT: _build_cast(cast),
        ULTIMATE_OUTPUT: _build_ultimate(identity, walk),
    }
    for path, image in outputs.items():
        image.save(path, format="PNG", optimize=False)
        print(f"HENRY_BAROMETRIC_SPRITE_OK {path.relative_to(ROOT)} {image.width}x{image.height}")


if __name__ == "__main__":
    main()
