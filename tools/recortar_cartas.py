#!/usr/bin/env python3
"""Recorta folhas com duas cartas e envia os PNGs para assets/sprites/Deck.

Fluxo padrao:
  python tools/recortar_cartas.py

Entrada:  puras/
Saida:    assets/sprites/Deck/carta-<nome>1.png
          assets/sprites/Deck/carta-<nome>2.png

O arquivo original so e apagado quando as duas cartas forem salvas com sucesso.
"""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path
from typing import Iterable, NamedTuple

try:
    from PIL import Image
except ImportError as exc:  # pragma: no cover - mensagem operacional
    raise SystemExit(
        "Pillow nao esta instalado. Instale com: python -m pip install Pillow"
    ) from exc


IMAGE_EXTENSIONS = {".png", ".jpg", ".jpeg", ".webp", ".bmp"}


class CropBox(NamedTuple):
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

    def padded(self, padding: int, image_width: int, image_height: int) -> "CropBox":
        return CropBox(
            max(0, self.left - padding),
            max(0, self.top - padding),
            min(image_width, self.right + padding),
            min(image_height, self.bottom + padding),
        )

    def inset(self, amount: int) -> "CropBox":
        if amount <= 0:
            return self
        max_inset_x = max(0, (self.width - 1) // 2)
        max_inset_y = max(0, (self.height - 1) // 2)
        safe_amount = min(amount, max_inset_x, max_inset_y)
        return CropBox(
            self.left + safe_amount,
            self.top + safe_amount,
            self.right - safe_amount,
            self.bottom - safe_amount,
        )


def parse_args() -> argparse.Namespace:
    root = Path(__file__).resolve().parents[1]
    parser = argparse.ArgumentParser(
        description="Recorta imagens com duas cartas lado a lado e gera carta-<nome>1/2.png."
    )
    parser.add_argument(
        "--input",
        "-i",
        type=Path,
        default=root / "puras",
        help="Pasta com as imagens puras. Padrao: puras/",
    )
    parser.add_argument(
        "--output",
        "-o",
        type=Path,
        default=root / "assets" / "sprites" / "Deck",
        help="Pasta destino do deck. Padrao: assets/sprites/Deck/",
    )
    parser.add_argument(
        "--white-threshold",
        type=int,
        default=246,
        help="Pixels com RGB acima desse valor sao tratados como fundo branco.",
    )
    parser.add_argument(
        "--alpha-threshold",
        type=int,
        default=16,
        help="Pixels com alpha ate esse valor sao tratados como transparentes.",
    )
    parser.add_argument(
        "--padding",
        type=int,
        default=0,
        help="Margem extra em pixels no recorte final.",
    )
    parser.add_argument(
        "--inset",
        type=int,
        default=3,
        help="Corta alguns pixels para dentro depois de detectar a carta, removendo linhas brancas de borda.",
    )
    parser.add_argument(
        "--keep-source",
        action="store_true",
        help="Nao apaga as imagens originais depois de recortar.",
    )
    parser.add_argument(
        "--overwrite",
        action="store_true",
        help="Sobrescreve cartas existentes no destino.",
    )
    return parser.parse_args()


def iter_images(folder: Path) -> Iterable[Path]:
    for path in sorted(folder.iterdir()):
        if path.is_file() and path.suffix.lower() in IMAGE_EXTENSIONS:
            yield path


def safe_stem(path: Path) -> str:
    stem = path.stem.strip()
    stem = re.sub(r"^carta[-_\s]+", "", stem, flags=re.IGNORECASE)
    stem = re.sub(r"\s+", "_", stem)
    stem = re.sub(r"[^A-Za-z0-9_.-]+", "_", stem)
    stem = stem.strip("._-")
    return stem or "sem_nome"


def is_foreground(pixel: tuple[int, int, int, int], white_threshold: int, alpha_threshold: int) -> bool:
    r, g, b, a = pixel
    if a <= alpha_threshold:
        return False
    return not (r >= white_threshold and g >= white_threshold and b >= white_threshold)


def foreground_column_counts(
    image: Image.Image, white_threshold: int, alpha_threshold: int
) -> list[int]:
    rgba = image.convert("RGBA")
    width, height = rgba.size
    pixels = rgba.load()
    counts = [0] * width
    for y in range(height):
        for x in range(width):
            if is_foreground(pixels[x, y], white_threshold, alpha_threshold):
                counts[x] += 1
    return counts


def split_column_clusters(counts: list[int], image_height: int, min_gap: int) -> list[tuple[int, int]]:
    threshold = max(8, int(image_height * 0.012))
    clusters: list[tuple[int, int]] = []
    start: int | None = None
    last_seen = 0

    for x, count in enumerate(counts):
        if count >= threshold:
            if start is None:
                start = x
            last_seen = x
        elif start is not None and x - last_seen > min_gap:
            clusters.append((start, last_seen + 1))
            start = None

    if start is not None:
        clusters.append((start, last_seen + 1))
    return clusters


def crop_box_for_x_range(
    image: Image.Image,
    x_range: tuple[int, int],
    white_threshold: int,
    alpha_threshold: int,
) -> CropBox | None:
    rgba = image.convert("RGBA")
    width, height = rgba.size
    pixels = rgba.load()
    left, right = x_range
    top = height
    bottom = -1
    real_left = width
    real_right = -1

    for y in range(height):
        for x in range(left, right):
            if is_foreground(pixels[x, y], white_threshold, alpha_threshold):
                real_left = min(real_left, x)
                real_right = max(real_right, x)
                top = min(top, y)
                bottom = max(bottom, y)

    if real_right < real_left or bottom < top:
        return None
    return CropBox(real_left, top, real_right + 1, bottom + 1)


def detect_card_boxes(
    image: Image.Image,
    white_threshold: int,
    alpha_threshold: int,
    padding: int,
    inset: int,
) -> list[CropBox]:
    width, height = image.size
    counts = foreground_column_counts(image, white_threshold, alpha_threshold)
    clusters = split_column_clusters(counts, height, min_gap=max(8, width // 160))
    boxes: list[CropBox] = []

    for cluster in clusters:
        box = crop_box_for_x_range(image, cluster, white_threshold, alpha_threshold)
        if box is None:
            continue
        if box.width < width * 0.12 or box.height < height * 0.25:
            continue
        boxes.append(box.padded(padding, width, height).inset(inset))

    boxes.sort(key=lambda item: item.area, reverse=True)
    boxes = boxes[:2]
    boxes.sort(key=lambda item: item.left)
    return boxes


def output_paths(source: Path, output_folder: Path) -> tuple[Path, Path]:
    stem = safe_stem(source)
    return (
        output_folder / f"carta-{stem}1.png",
        output_folder / f"carta-{stem}2.png",
    )


def display_path(path: Path) -> str:
    try:
        return str(path.relative_to(Path.cwd()))
    except ValueError:
        return str(path)


def process_image(source: Path, output_folder: Path, args: argparse.Namespace) -> bool:
    with Image.open(source) as image:
        boxes = detect_card_boxes(
            image,
            white_threshold=args.white_threshold,
            alpha_threshold=args.alpha_threshold,
            padding=args.padding,
            inset=args.inset,
        )
        if len(boxes) != 2:
            print(f"[ERRO] {source.name}: encontrei {len(boxes)} carta(s), esperado 2. Original preservada.")
            return False

        first_path, second_path = output_paths(source, output_folder)
        targets = [first_path, second_path]
        if not args.overwrite:
            existing = [path.name for path in targets if path.exists()]
            if existing:
                print(
                    f"[ERRO] {source.name}: destino ja existe ({', '.join(existing)}). "
                    "Use --overwrite para substituir. Original preservada."
                )
                return False

        output_folder.mkdir(parents=True, exist_ok=True)
        for box, target in zip(boxes, targets):
            cropped = image.crop(tuple(box)).convert("RGBA")
            cropped.save(target)
            print(f"[OK] {source.name} -> {display_path(target)} ({cropped.width}x{cropped.height})")

    if not args.keep_source:
        source.unlink()
        print(f"[OK] original removida: {source.name}")
    return True


def main() -> int:
    args = parse_args()
    input_folder = args.input.resolve()
    output_folder = args.output.resolve()

    if not input_folder.exists():
        input_folder.mkdir(parents=True, exist_ok=True)
        print(f"[INFO] Pasta criada: {input_folder}")
        print("Coloque as imagens puras nela e rode o script novamente.")
        return 0

    images = list(iter_images(input_folder))
    if not images:
        print(f"[INFO] Nenhuma imagem encontrada em: {input_folder}")
        return 0

    ok_count = 0
    for image_path in images:
        try:
            if process_image(image_path, output_folder, args):
                ok_count += 1
        except Exception as exc:  # pragma: no cover - protecao operacional
            print(f"[ERRO] {image_path.name}: {exc}. Original preservada.")

    print(f"[FIM] {ok_count}/{len(images)} imagem(ns) processada(s).")
    return 0 if ok_count == len(images) else 1


if __name__ == "__main__":
    raise SystemExit(main())
