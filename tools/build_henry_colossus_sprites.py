#!/usr/bin/env python3
"""Normalize the approved Colosso D37 source sheets for Godot.

The authored sources are retained outside the runtime asset tree.  This build
step crops their logical grids, restores Henry's canonical palette/pixel
density, enforces a common ground anchor and removes any rear-facing tie blue.
"""

from collections import deque
from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
SOURCE_DIR = ROOT / "tools/source_assets"
ASSET_DIR = ROOT / "assets/sprites/player/player_2_suit"
CELL = 256
GROUND_Y = 248
BODY_HEIGHT = 232

SHEETS = {
    "henry_colossus_transform_sheet_v1.png": ("henry_colossus_transform_source_v1.png", 4, 2, 8, 1, False),
    "henry_colossus_walk_sheet_v1.png": ("henry_colossus_walk_source_v1.png", 3, 3, 3, 3, True),
    "henry_colossus_attack_sheet_v1.png": ("henry_colossus_attack_source_v1.png", 4, 3, 4, 3, True),
    "henry_colossus_skill_sheet_v1.png": ("henry_colossus_skill_source_v1.png", 3, 3, 3, 3, True),
    "henry_colossus_normal_attack_sheet_v1.png": ("henry_colossus_normal_attack_source_v1.png", 4, 3, 4, 3, True),
    "henry_colossus_normal_skill_sheet_v1.png": ("henry_colossus_normal_skill_source_v1.png", 3, 3, 3, 3, True),
}


def _alpha_components(frame: Image.Image, threshold: int = 72) -> list[list[tuple[int, int]]]:
    """Return 8-connected opaque components, largest first."""
    alpha = frame.getchannel("A")
    pixels = alpha.load()
    visited = bytearray(frame.width * frame.height)
    components: list[list[tuple[int, int]]] = []
    for y in range(frame.height):
        for x in range(frame.width):
            offset = y * frame.width + x
            if visited[offset] or pixels[x, y] < threshold:
                continue
            visited[offset] = 1
            pending = deque([(x, y)])
            component: list[tuple[int, int]] = []
            while pending:
                current_x, current_y = pending.popleft()
                component.append((current_x, current_y))
                for neighbor_y in range(max(0, current_y - 1), min(frame.height, current_y + 2)):
                    for neighbor_x in range(max(0, current_x - 1), min(frame.width, current_x + 2)):
                        neighbor_offset = neighbor_y * frame.width + neighbor_x
                        if visited[neighbor_offset] or pixels[neighbor_x, neighbor_y] < threshold:
                            continue
                        visited[neighbor_offset] = 1
                        pending.append((neighbor_x, neighbor_y))
            components.append(component)
    return sorted(components, key=len, reverse=True)


def _source_subjects(image: Image.Image, columns: int, rows: int, label: str) -> list[Image.Image]:
    """Extract complete figures before dividing them into runtime atlas cells.

    Generated poses can cross the nominal source grid. Cropping the grid first
    therefore cuts a fist from one pose and carries it into the next cell. The
    authored figures are separate alpha components, so isolate those full
    silhouettes, group them by row, then order them from left to right.
    """
    expected = columns * rows
    components = _alpha_components(image)
    if len(components) < expected:
        raise ValueError(f"expected {expected} Colosso subjects in {label}, got {len(components)}")
    subjects = components[:expected]
    positioned: list[tuple[float, float, list[tuple[int, int]]]] = []
    for component in subjects:
        center_x = sum(point[0] for point in component) / len(component)
        center_y = sum(point[1] for point in component) / len(component)
        positioned.append((center_y, center_x, component))
    positioned.sort(key=lambda entry: entry[0])
    ordered: list[list[tuple[int, int]]] = []
    for row in range(rows):
        row_subjects = positioned[row * columns : (row + 1) * columns]
        row_subjects.sort(key=lambda entry: entry[1])
        ordered.extend(entry[2] for entry in row_subjects)

    source_pixels = image.load()
    frames: list[Image.Image] = []
    for component in ordered:
        min_x = min(point[0] for point in component)
        min_y = min(point[1] for point in component)
        max_x = max(point[0] for point in component) + 1
        max_y = max(point[1] for point in component) + 1
        frame = Image.new("RGBA", (max_x - min_x, max_y - min_y), (0, 0, 0, 0))
        frame_pixels = frame.load()
        for x, y in component:
            frame_pixels[x - min_x, y - min_y] = source_pixels[x, y]
        frames.append(frame)
    print(f"HENRY_COLOSSUS_SUBJECT_EXTRACT_OK {label} subjects={len(frames)}")
    return frames


def _assert_single_subject(frame: Image.Image, label: str) -> None:
    substantial = [component for component in _alpha_components(frame) if len(component) >= 16]
    if len(substantial) != 1:
        sizes = [len(component) for component in substantial]
        raise ValueError(f"Colosso cell has detached sprite fragments: {label} components={sizes}")


def _identity_palette() -> list[tuple[int, int, int]]:
    paths = [ASSET_DIR / "henry_walk_sheet_v2.png", ASSET_DIR / "henry_idle_pocket_sheet_v1.png"]
    counts: dict[tuple[int, int, int], int] = {}
    for path in paths:
        image = Image.open(path).convert("RGBA")
        for red, green, blue, alpha in image.get_flattened_data():
            if alpha < 224:
                continue
            color = (red, green, blue)
            counts[color] = counts.get(color, 0) + 1
    ranked = sorted(counts.items(), key=lambda entry: entry[1], reverse=True)
    base = [color for color, _count in ranked[:144]]
    tie = [color for color, _count in ranked if color[2] > 70 and color[2] > color[0] * 1.2 and color[2] > color[1] * 1.12][:48]
    skin = [color for color, _count in ranked if color[0] > color[1] * 1.15 and color[1] > color[2] * 1.08][:48]
    return list(dict.fromkeys(base + tie + skin))


def _remove_rear_tie(frame: Image.Image) -> Image.Image:
    result = frame.copy()
    pixels = result.load()
    for y in range(result.height):
        for x in range(result.width):
            red, green, blue, alpha = pixels[x, y]
            if alpha > 32 and blue > 80 and blue > red * 1.18 and blue > green * 1.12:
                pixels[x, y] = (34, 34, 48, alpha)
    return result


def _fit_frame(frame: Image.Image, palette: list[tuple[int, int, int]], rear: bool) -> Image.Image:
    alpha = frame.getchannel("A").point(lambda value: 255 if value >= 72 else 0)
    bbox = alpha.getbbox()
    if bbox is None:
        raise ValueError("authored Colosso cell is empty")
    cropped = frame.crop(bbox)
    scale = min(BODY_HEIGHT / cropped.height, 246.0 / cropped.width)
    width = max(2, int(cropped.width * scale) // 2 * 2)
    height = max(2, int(cropped.height * scale) // 2 * 2)
    # Work at half size and expand with nearest-neighbour to match Henry's
    # canonical two-pixel clusters instead of preserving generated smoothing.
    half = cropped.resize((max(1, width // 2), max(1, height // 2)), Image.Resampling.LANCZOS)
    pixelated = half.resize((width, height), Image.Resampling.NEAREST)
    nearest_cache: dict[tuple[int, int, int], tuple[int, int, int]] = {}
    pixels = pixelated.load()
    for y in range(height):
        for x in range(width):
            red, green, blue, value = pixels[x, y]
            if value < 72:
                pixels[x, y] = (0, 0, 0, 0)
                continue
            source = (red, green, blue)
            nearest = nearest_cache.get(source)
            if nearest is None:
                nearest = min(palette, key=lambda color: (color[0] - red) ** 2 + (color[1] - green) ** 2 + (color[2] - blue) ** 2)
                nearest_cache[source] = nearest
            pixels[x, y] = (*nearest, 255)
    if rear:
        pixelated = _remove_rear_tie(pixelated)
    result = Image.new("RGBA", (CELL, CELL), (0, 0, 0, 0))
    result.alpha_composite(pixelated, ((CELL - width) // 2, GROUND_Y - height))
    return result


def _atlas(columns: int, rows: int, frames: list[Image.Image]) -> Image.Image:
    if len(frames) != columns * rows:
        raise ValueError(f"expected {columns * rows} cells, got {len(frames)}")
    result = Image.new("RGBA", (columns * CELL, rows * CELL), (0, 0, 0, 0))
    for index, frame in enumerate(frames):
        result.alpha_composite(frame, ((index % columns) * CELL, (index // columns) * CELL))
    return result


def main() -> None:
    palette = _identity_palette()
    for output_name, (source_name, source_columns, source_rows, output_columns, output_rows, directional) in SHEETS.items():
        source = Image.open(SOURCE_DIR / source_name).convert("RGBA")
        raw_cells = _source_subjects(source, source_columns, source_rows, source_name)
        frames: list[Image.Image] = []
        for index, raw in enumerate(raw_cells):
            source_row = index // source_columns
            label = f"{output_name}[{index}]"
            frame = _fit_frame(raw, palette, directional and source_row == source_rows - 1)
            _assert_single_subject(frame, label)
            frames.append(frame)
        output = _atlas(output_columns, output_rows, frames)
        output_path = ASSET_DIR / output_name
        output.save(output_path, format="PNG", optimize=False)
        print(f"HENRY_COLOSSUS_SPRITE_OK {output_path.relative_to(ROOT)} {output.width}x{output.height}")


if __name__ == "__main__":
    main()
