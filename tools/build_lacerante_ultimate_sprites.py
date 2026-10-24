#!/usr/bin/env python3
"""Normalize the approved 4x2 Lacerante ultimate source into Godot cells."""

from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "tools/source_assets/lacerante_ultimate_source_v3.png"
OUTPUT = ROOT / "assets/sprites/player/lacerante/ultimate.png"
CELL = (320, 256)
GRID = (4, 2)
SOURCE_SCALE = 0.57


def split_edges(total: int, parts: int) -> list[int]:
    return [round(index * total / parts) for index in range(parts + 1)]


def main() -> None:
    source = Image.open(SOURCE).convert("RGBA")
    x_edges = split_edges(source.width, GRID[0])
    y_edges = split_edges(source.height, GRID[1])
    atlas = Image.new("RGBA", (CELL[0] * GRID[0], CELL[1] * GRID[1]), (0, 0, 0, 0))

    for row in range(GRID[1]):
        for column in range(GRID[0]):
            frame = source.crop((x_edges[column], y_edges[row], x_edges[column + 1], y_edges[row + 1]))
            scaled = frame.resize(
                (round(frame.width * SOURCE_SCALE), round(frame.height * SOURCE_SCALE)),
                Image.Resampling.NEAREST,
            )
            x = column * CELL[0] + (CELL[0] - scaled.width) // 2
            # The generated source rows use different internal baselines. Keep
            # both rows grounded at y=248 so the in-game feet never bob.
            baseline_offset = 0 if row == 0 else 24
            y = row * CELL[1] + baseline_offset
            atlas.alpha_composite(scaled, (x, y))

    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    atlas.save(OUTPUT, optimize=True)
    print(f"LACERANTE_ULTIMATE_SPRITES_OK frames=8 cell={CELL[0]}x{CELL[1]} output={OUTPUT}")


if __name__ == "__main__":
    main()
