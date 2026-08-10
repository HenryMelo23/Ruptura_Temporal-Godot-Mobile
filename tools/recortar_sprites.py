#!/usr/bin/env python3
"""Recorta folhas de sprites de inimigos, bosses e animacoes em frames PNG.

Fluxo padrao:
  python tools/recortar_sprites.py --input puras_sprites

Entrada:  uma imagem ou pasta com folhas de sprites em fundo preto/transparente.
Saida:    assets/sprites/recortes/<nome>_01.png, <nome>_02.png, ...

O script mantem o arquivo original por padrao. Use --delete-source apenas quando
quiser apagar a folha depois de recortar com sucesso.
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from collections import Counter, deque
from dataclasses import asdict, dataclass
from pathlib import Path
from typing import Iterable

try:
    from PIL import Image, ImageDraw
except ImportError as exc:  # pragma: no cover - mensagem operacional
    raise SystemExit(
        "Pillow nao esta instalado. Instale com: python -m pip install Pillow"
    ) from exc


IMAGE_EXTENSIONS = {".png", ".jpg", ".jpeg", ".webp", ".bmp"}


@dataclass(frozen=True)
class FrameBox:
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

    def padded(self, padding: int, image_width: int, image_height: int) -> "FrameBox":
        return FrameBox(
            max(0, self.left - padding),
            max(0, self.top - padding),
            min(image_width, self.right + padding),
            min(image_height, self.bottom + padding),
        )


def parse_args() -> argparse.Namespace:
    root = Path(__file__).resolve().parents[1]
    parser = argparse.ArgumentParser(
        description=(
            "Recorta folhas de sprites em frames PNG com transparencia. "
            "Funciona bem com fundo preto, transparente ou cor solida nas bordas."
        )
    )
    parser.add_argument(
        "--input",
        "-i",
        default=str(root / "puras_sprites"),
        help="Imagem ou pasta de entrada. Padrao: puras_sprites/",
    )
    parser.add_argument(
        "--output",
        "-o",
        default=str(root / "assets" / "sprites" / "recortes"),
        help="Pasta de saida. Padrao: assets/sprites/recortes/",
    )
    parser.add_argument(
        "--pattern",
        default="*",
        help="Padrao glob quando --input for pasta. Ex: '*.png'.",
    )
    parser.add_argument(
        "--prefix",
        default="",
        help="Prefixo dos frames. Se omitido, usa o nome da folha.",
    )
    parser.add_argument(
        "--expected-frames",
        type=int,
        default=0,
        help="Falha se a folha nao gerar essa quantidade de frames.",
    )
    parser.add_argument(
        "--padding",
        type=int,
        default=4,
        help="Margem extra em pixels ao redor de cada frame.",
    )
    parser.add_argument(
        "--tolerance",
        type=int,
        default=10,
        help="Tolerancia RGB para considerar fundo conectado nas bordas.",
    )
    parser.add_argument(
        "--alpha-threshold",
        type=int,
        default=8,
        help="Alpha igual/abaixo disso e considerado fundo.",
    )
    parser.add_argument(
        "--min-area",
        type=int,
        default=80,
        help="Area minima de foreground para aceitar um frame.",
    )
    parser.add_argument(
        "--min-column-pixels",
        type=int,
        default=0,
        help="Pixels minimos por coluna. 0 calcula automaticamente.",
    )
    parser.add_argument(
        "--cluster-gap",
        type=int,
        default=2,
        help="Une partes separadas por ate N colunas vazias. Aumente se um frame for dividido em partes.",
    )
    parser.add_argument(
        "--tight",
        action="store_true",
        help="Salva cada frame no proprio tamanho. Padrao usa canvas uniforme.",
    )
    parser.add_argument(
        "--overwrite",
        action="store_true",
        help="Sobrescreve frames existentes.",
    )
    parser.add_argument(
        "--delete-source",
        action="store_true",
        help="Apaga a folha original apenas apos recortar com sucesso.",
    )
    return parser.parse_args()


def safe_stem(path: Path) -> str:
    stem = re.sub(r"[^A-Za-z0-9_-]+", "_", path.stem).strip("_")
    return stem or "sprite"


def iter_images(input_path: Path, pattern: str) -> Iterable[Path]:
    if input_path.is_file():
        if input_path.suffix.lower() in IMAGE_EXTENSIONS:
            yield input_path
        return
    if not input_path.exists():
        raise FileNotFoundError(f"Entrada nao encontrada: {input_path}")
    for path in sorted(input_path.glob(pattern)):
        if path.is_file() and path.suffix.lower() in IMAGE_EXTENSIONS:
            yield path


def sampled_border_color(image: Image.Image, alpha_threshold: int) -> tuple[int, int, int]:
    width, height = image.size
    pixels = image.load()
    samples: list[tuple[int, int, int]] = []

    for x in range(width):
        for y in (0, height - 1):
            r, g, b, a = pixels[x, y]
            if a > alpha_threshold:
                samples.append((r // 8 * 8, g // 8 * 8, b // 8 * 8))
    for y in range(height):
        for x in (0, width - 1):
            r, g, b, a = pixels[x, y]
            if a > alpha_threshold:
                samples.append((r // 8 * 8, g // 8 * 8, b // 8 * 8))

    if not samples:
        return (0, 0, 0)
    return Counter(samples).most_common(1)[0][0]


def close_to_background(
    pixel: tuple[int, int, int, int],
    background: tuple[int, int, int],
    tolerance: int,
    alpha_threshold: int,
) -> bool:
    r, g, b, a = pixel
    if a <= alpha_threshold:
        return True
    return (
        abs(r - background[0]) <= tolerance
        and abs(g - background[1]) <= tolerance
        and abs(b - background[2]) <= tolerance
    )


def build_foreground_mask(
    image: Image.Image,
    tolerance: int,
    alpha_threshold: int,
) -> tuple[Image.Image, bytearray]:
    rgba = image.convert("RGBA")
    width, height = rgba.size
    pixels = rgba.load()
    background = sampled_border_color(rgba, alpha_threshold)

    visited = bytearray(width * height)
    queue: deque[tuple[int, int]] = deque()

    def enqueue_if_background(x: int, y: int) -> None:
        idx = y * width + x
        if visited[idx]:
            return
        if close_to_background(pixels[x, y], background, tolerance, alpha_threshold):
            visited[idx] = 1
            queue.append((x, y))

    for x in range(width):
        enqueue_if_background(x, 0)
        enqueue_if_background(x, height - 1)
    for y in range(height):
        enqueue_if_background(0, y)
        enqueue_if_background(width - 1, y)

    while queue:
        x, y = queue.popleft()
        if x > 0:
            enqueue_if_background(x - 1, y)
        if x < width - 1:
            enqueue_if_background(x + 1, y)
        if y > 0:
            enqueue_if_background(x, y - 1)
        if y < height - 1:
            enqueue_if_background(x, y + 1)

    mask = bytearray(width * height)
    for y in range(height):
        for x in range(width):
            idx = y * width + x
            if visited[idx]:
                continue
            if pixels[x, y][3] > alpha_threshold:
                mask[idx] = 1
    return rgba, mask


def find_x_clusters(
    mask: bytearray,
    width: int,
    height: int,
    min_column_pixels: int,
    cluster_gap: int,
) -> list[tuple[int, int]]:
    threshold = min_column_pixels if min_column_pixels > 0 else max(2, height // 160)
    column_counts = [
        sum(mask[y * width + x] for y in range(height))
        for x in range(width)
    ]

    raw: list[tuple[int, int]] = []
    start = -1
    for x, count in enumerate(column_counts):
        if count >= threshold and start < 0:
            start = x
        elif count < threshold and start >= 0:
            raw.append((start, x))
            start = -1
    if start >= 0:
        raw.append((start, width))

    if not raw:
        return []

    merged: list[tuple[int, int]] = [raw[0]]
    for start, end in raw[1:]:
        previous_start, previous_end = merged[-1]
        if start - previous_end <= cluster_gap:
            merged[-1] = (previous_start, end)
        else:
            merged.append((start, end))
    return merged


def boxes_from_clusters(
    mask: bytearray,
    width: int,
    height: int,
    clusters: list[tuple[int, int]],
    min_area: int,
) -> list[FrameBox]:
    boxes: list[FrameBox] = []
    for left, right in clusters:
        top = height
        bottom = -1
        min_x = right
        max_x = left - 1
        area = 0
        for y in range(height):
            row = y * width
            for x in range(left, right):
                if not mask[row + x]:
                    continue
                area += 1
                top = min(top, y)
                bottom = max(bottom, y + 1)
                min_x = min(min_x, x)
                max_x = max(max_x, x + 1)
        if area >= min_area and bottom > top and max_x > min_x:
            boxes.append(FrameBox(min_x, top, max_x, bottom))
    return boxes


def transparent_frame(rgba: Image.Image, mask: bytearray, box: FrameBox) -> Image.Image:
    width, _height = rgba.size
    source = rgba.load()
    frame = Image.new("RGBA", (box.width, box.height), (0, 0, 0, 0))
    target = frame.load()
    for y in range(box.height):
        source_y = box.top + y
        row = source_y * width
        for x in range(box.width):
            source_x = box.left + x
            if mask[row + source_x]:
                target[x, y] = source[source_x, source_y]
    return frame


def put_on_uniform_canvas(frames: list[Image.Image]) -> list[Image.Image]:
    if not frames:
        return []
    max_width = max(frame.width for frame in frames)
    max_height = max(frame.height for frame in frames)
    uniform: list[Image.Image] = []
    for frame in frames:
        canvas = Image.new("RGBA", (max_width, max_height), (0, 0, 0, 0))
        x = (max_width - frame.width) // 2
        y = (max_height - frame.height) // 2
        canvas.alpha_composite(frame, (x, y))
        uniform.append(canvas)
    return uniform


def save_preview(frames: list[Image.Image], output_path: Path) -> None:
    if not frames:
        return
    gap = 12
    label_height = 18
    width = sum(frame.width for frame in frames) + gap * (len(frames) + 1)
    height = max(frame.height for frame in frames) + gap * 2 + label_height
    preview = Image.new("RGBA", (width, height), (16, 16, 18, 255))
    draw = ImageDraw.Draw(preview)
    x = gap
    for index, frame in enumerate(frames, start=1):
        y = gap
        preview.alpha_composite(frame, (x, y))
        draw.rectangle((x, y, x + frame.width - 1, y + frame.height - 1), outline=(0, 255, 220, 180))
        draw.text((x, y + frame.height + 2), f"{index:02d}", fill=(220, 255, 250, 255))
        x += frame.width + gap
    output_path.parent.mkdir(parents=True, exist_ok=True)
    preview.save(output_path)


def process_image(path: Path, args: argparse.Namespace, output_root: Path, total_sources: int) -> bool:
    image = Image.open(path)
    rgba, mask = build_foreground_mask(image, args.tolerance, args.alpha_threshold)
    width, height = rgba.size
    clusters = find_x_clusters(mask, width, height, args.min_column_pixels, args.cluster_gap)
    boxes = [
        box.padded(args.padding, width, height)
        for box in boxes_from_clusters(mask, width, height, clusters, args.min_area)
    ]

    if args.expected_frames and len(boxes) != args.expected_frames:
        print(
            f"ERRO: {path.name}: esperado {args.expected_frames} frames, detectado {len(boxes)}.",
            file=sys.stderr,
        )
        return False
    if not boxes:
        print(f"ERRO: {path.name}: nenhum frame detectado.", file=sys.stderr)
        return False

    sheet_name = safe_stem(path)
    if args.prefix and total_sources == 1:
        sheet_name = re.sub(r"[^A-Za-z0-9_-]+", "_", args.prefix).strip("_") or sheet_name

    output_dir = output_root
    output_dir.mkdir(parents=True, exist_ok=True)

    frames = [transparent_frame(rgba, mask, box) for box in boxes]
    saved_frames = frames if args.tight else put_on_uniform_canvas(frames)

    metadata = {
        "source": str(path),
        "sheet": sheet_name,
        "frame_count": len(saved_frames),
        "uniform_canvas": not args.tight,
        "padding": args.padding,
        "boxes": [asdict(box) for box in boxes],
        "files": [],
    }

    targets: list[Path] = []
    for index in range(1, len(saved_frames) + 1):
        targets.append(output_dir / f"{sheet_name}_{index:02d}.png")
    if not args.overwrite:
        existing = [target for target in targets if target.exists()]
        if existing:
            print(
                f"ERRO: {path.name}: arquivo ja existe, use --overwrite: {existing[0]}",
                file=sys.stderr,
            )
            return False

    for frame, target in zip(saved_frames, targets):
        frame.save(target)
        metadata["files"].append(str(target))

    preview_dir = output_dir / "_preview"
    save_preview(saved_frames, preview_dir / f"{sheet_name}_preview.png")
    with (preview_dir / f"{sheet_name}_frames.json").open("w", encoding="utf-8") as file:
        json.dump(metadata, file, ensure_ascii=False, indent=2)

    if args.delete_source:
        path.unlink()

    print(
        f"OK: {path.name}: {len(saved_frames)} frames -> {output_dir} "
        f"(canvas {'uniforme' if not args.tight else 'justo'})"
    )
    return True


def main() -> int:
    args = parse_args()
    input_path = Path(args.input).expanduser().resolve()
    output_root = Path(args.output).expanduser().resolve()
    images = list(iter_images(input_path, args.pattern))
    if not images:
        print(f"Nenhuma imagem encontrada em: {input_path}", file=sys.stderr)
        return 1

    failures = 0
    for image_path in images:
        try:
            if not process_image(image_path, args, output_root, len(images)):
                failures += 1
        except Exception as exc:  # pragma: no cover - ferramenta operacional
            failures += 1
            print(f"ERRO: {image_path.name}: {exc}", file=sys.stderr)

    if failures:
        print(f"Concluido com {failures} falha(s).", file=sys.stderr)
        return 1
    print(f"Concluido: {len(images)} folha(s) processada(s).")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
