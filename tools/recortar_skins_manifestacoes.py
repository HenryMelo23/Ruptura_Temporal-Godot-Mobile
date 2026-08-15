#!/usr/bin/env python3
"""Recorta folhas de skins das manifestacoes em frames transparentes.

Entrada esperada: folhas com 7 poses em fundo claro/branco:
  1 idle_01, 2 idle_02, 3 side_01, 4 side_02, 5 side_02_repeat_unused,
  6 front_01, 7 back_01.

Saida: assets/sprites/skins/<skin_key>/<frame>.png
"""

from __future__ import annotations

import argparse
import json
import re
import unicodedata
from collections import deque
from dataclasses import asdict, dataclass
from pathlib import Path

from PIL import Image, ImageDraw


FRAME_NAMES = [
    "idle_01",
    "idle_02",
    "side_01",
    "side_02",
    "side_02_repeat_unused",
    "front_01",
    "back_01",
]

SPECIAL_KEYS = {
    "Eclipsada-Sol": "eclipsada_sol",
    "Eclipsada-Lua": "eclipsada_lua",
}


@dataclass(frozen=True)
class Box:
    left: int
    top: int
    right: int
    bottom: int

    @property
    def width(self) -> int:
        return self.right - self.left

    @property
    def height(self) -> int:
        return self.bottom - self.top

    @property
    def area(self) -> int:
        return self.width * self.height

    @property
    def center(self) -> tuple[float, float]:
        return ((self.left + self.right) * 0.5, (self.top + self.bottom) * 0.5)

    def padded(self, amount: int, width: int, height: int) -> "Box":
        return Box(
            max(0, self.left - amount),
            max(0, self.top - amount),
            min(width, self.right + amount),
            min(height, self.bottom + amount),
        )


def parse_args() -> argparse.Namespace:
    root = Path(__file__).resolve().parents[1]
    parser = argparse.ArgumentParser(description="Recorta skins de manifestacao da Geovana.")
    parser.add_argument("--input", "-i", default=r"C:\Users\luish\Downloads\Skins")
    parser.add_argument("--output", "-o", default=str(root / "assets" / "sprites" / "skins"))
    parser.add_argument("--padding", type=int, default=8)
    parser.add_argument("--tolerance", type=int, default=34)
    parser.add_argument("--alpha-threshold", type=int, default=8)
    parser.add_argument("--min-area", type=int, default=1200)
    parser.add_argument("--overwrite", action="store_true")
    return parser.parse_args()


def slugify(stem: str) -> str:
    if stem in SPECIAL_KEYS:
        return SPECIAL_KEYS[stem]
    text = unicodedata.normalize("NFKD", stem).encode("ascii", "ignore").decode("ascii")
    text = re.sub(r"[^A-Za-z0-9]+", "_", text).strip("_").lower()
    return text or "skin"


def is_background(pixel: tuple[int, int, int, int], bg: tuple[int, int, int], tolerance: int, alpha_threshold: int) -> bool:
    r, g, b, a = pixel
    if a <= alpha_threshold:
        return True
    return abs(r - bg[0]) <= tolerance and abs(g - bg[1]) <= tolerance and abs(b - bg[2]) <= tolerance


def border_background(image: Image.Image, alpha_threshold: int) -> tuple[int, int, int]:
    rgba = image.convert("RGBA")
    width, height = rgba.size
    pixels = rgba.load()
    samples: list[tuple[int, int, int]] = []
    for x in range(width):
        for y in (0, height - 1):
            r, g, b, a = pixels[x, y]
            if a > alpha_threshold:
                samples.append((r, g, b))
    for y in range(height):
        for x in (0, width - 1):
            r, g, b, a = pixels[x, y]
            if a > alpha_threshold:
                samples.append((r, g, b))
    if not samples:
        return (255, 255, 255)
    samples.sort()
    return samples[len(samples) // 2]


def background_connected_mask(image: Image.Image, tolerance: int, alpha_threshold: int) -> tuple[Image.Image, bytearray]:
    rgba = image.convert("RGBA")
    width, height = rgba.size
    pixels = rgba.load()
    bg = border_background(rgba, alpha_threshold)
    visited = bytearray(width * height)
    queue: deque[tuple[int, int]] = deque()

    def enqueue(x: int, y: int) -> None:
        idx = y * width + x
        if visited[idx]:
            return
        if is_background(pixels[x, y], bg, tolerance, alpha_threshold):
            visited[idx] = 1
            queue.append((x, y))

    for x in range(width):
        enqueue(x, 0)
        enqueue(x, height - 1)
    for y in range(height):
        enqueue(0, y)
        enqueue(width - 1, y)

    while queue:
        x, y = queue.popleft()
        for nx, ny in ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)):
            if 0 <= nx < width and 0 <= ny < height:
                enqueue(nx, ny)
    return rgba, visited


def foreground_components(rgba: Image.Image, background_mask: bytearray, min_area: int) -> list[Box]:
    width, height = rgba.size
    visited = bytearray(width * height)
    boxes: list[Box] = []

    def is_fg(x: int, y: int) -> bool:
        idx = y * width + x
        return not background_mask[idx]

    for y in range(height):
        for x in range(width):
            idx = y * width + x
            if visited[idx] or not is_fg(x, y):
                continue
            queue: deque[tuple[int, int]] = deque([(x, y)])
            visited[idx] = 1
            left = right = x
            top = bottom = y
            count = 0
            while queue:
                cx, cy = queue.popleft()
                count += 1
                left = min(left, cx)
                right = max(right, cx)
                top = min(top, cy)
                bottom = max(bottom, cy)
                for nx, ny in ((cx - 1, cy), (cx + 1, cy), (cx, cy - 1), (cx, cy + 1)):
                    if 0 <= nx < width and 0 <= ny < height:
                        nidx = ny * width + nx
                        if not visited[nidx] and is_fg(nx, ny):
                            visited[nidx] = 1
                            queue.append((nx, ny))
            box = Box(left, top, right + 1, bottom + 1)
            if count >= min_area and box.width >= 24 and box.height >= 24:
                boxes.append(box)
    return boxes


def sort_frame_boxes(boxes: list[Box], expected: int = 7) -> list[Box]:
    if len(boxes) != expected:
        raise ValueError(f"Esperado {expected} frames grandes, encontrado {len(boxes)}")
    by_y = sorted(boxes, key=lambda b: b.center[1])
    median_h = sorted(b.height for b in by_y)[len(by_y) // 2]
    row_gap = max(48.0, median_h * 0.75)
    rows: list[list[Box]] = []
    for box in by_y:
        if not rows or abs(box.center[1] - rows[-1][0].center[1]) > row_gap:
            rows.append([box])
        else:
            rows[-1].append(box)
    if len(rows) != 2 or sorted(len(row) for row in rows) != [3, 4]:
        raise ValueError("Layout inesperado. Precisa de 4 frames na linha superior e 3 na inferior.")
    rows.sort(key=lambda row: sum(b.center[1] for b in row) / len(row))
    ordered: list[Box] = []
    for row in rows:
        ordered.extend(sorted(row, key=lambda b: b.center[0]))
    return ordered


def transparent_crop(rgba: Image.Image, background_mask: bytearray, box: Box) -> Image.Image:
    width, _height = rgba.size
    crop = rgba.crop((box.left, box.top, box.right, box.bottom))
    out = Image.new("RGBA", crop.size, (0, 0, 0, 0))
    crop_pixels = crop.load()
    out_pixels = out.load()
    for y in range(crop.size[1]):
        for x in range(crop.size[0]):
            sx = box.left + x
            sy = box.top + y
            if not background_mask[sy * width + sx]:
                out_pixels[x, y] = crop_pixels[x, y]
    return out


def save_preview(frames: list[Image.Image], dest: Path, title: str) -> None:
    cell_w = max(frame.width for frame in frames) + 24
    cell_h = max(frame.height for frame in frames) + 44
    preview = Image.new("RGBA", (cell_w * len(frames), cell_h), (16, 18, 24, 255))
    draw = ImageDraw.Draw(preview)
    for idx, frame in enumerate(frames):
        x = idx * cell_w + (cell_w - frame.width) // 2
        y = 22 + (cell_h - 42 - frame.height)
        preview.alpha_composite(frame, (x, y))
        draw.text((idx * cell_w + 8, 6), FRAME_NAMES[idx], fill=(0, 255, 220, 255))
    draw.text((8, cell_h - 18), title, fill=(255, 255, 255, 220))
    dest.parent.mkdir(parents=True, exist_ok=True)
    preview.save(dest)


def process_sheet(path: Path, out_root: Path, args: argparse.Namespace) -> dict:
    skin_key = slugify(path.stem)
    skin_dir = out_root / skin_key
    skin_dir.mkdir(parents=True, exist_ok=True)

    image = Image.open(path).convert("RGBA")
    rgba, bg_mask = background_connected_mask(image, args.tolerance, args.alpha_threshold)
    boxes = [box.padded(args.padding, rgba.width, rgba.height) for box in sort_frame_boxes(foreground_components(rgba, bg_mask, args.min_area))]
    frames = [transparent_crop(rgba, bg_mask, box) for box in boxes]

    for name, frame in zip(FRAME_NAMES, frames):
        out_path = skin_dir / f"{name}.png"
        if out_path.exists() and not args.overwrite:
            raise FileExistsError(f"Arquivo ja existe: {out_path}")
        frame.save(out_path)

    preview_path = skin_dir / "_preview" / f"{skin_key}_preview.png"
    save_preview(frames, preview_path, skin_key)
    metadata = {
        "skin_key": skin_key,
        "source": str(path),
        "frames": {name: f"{name}.png" for name in FRAME_NAMES},
        "ignored_runtime_frames": ["side_02_repeat_unused"],
        "boxes": [asdict(box) for box in boxes],
    }
    (skin_dir / "skin_manifest.json").write_text(json.dumps(metadata, indent=2, ensure_ascii=False), encoding="utf-8")
    return metadata


def main() -> None:
    args = parse_args()
    input_path = Path(args.input)
    out_root = Path(args.output)
    sheets = [input_path] if input_path.is_file() else sorted(input_path.glob("*.png"))
    if not sheets:
        raise SystemExit(f"Nenhuma folha PNG encontrada em {input_path}")
    manifest: dict[str, dict] = {}
    for sheet in sheets:
        data = process_sheet(sheet, out_root, args)
        manifest[data["skin_key"]] = data
        print(f"OK {sheet.name} -> {data['skin_key']}")
    (out_root / "skins_manifest.json").write_text(json.dumps(manifest, indent=2, ensure_ascii=False), encoding="utf-8")
    print(f"Skins recortadas: {len(manifest)}")


if __name__ == "__main__":
    main()
