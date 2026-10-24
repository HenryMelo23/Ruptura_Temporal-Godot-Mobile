#!/usr/bin/env python3
"""Repack the authored Suturador atlas without clipping neighboring frames.

The source art was laid out on a 4x6 grid with 181x90 cells, but several
silhouettes legitimately cross those cell borders. This tool labels complete
alpha components first, then moves each complete component into a larger
224x128 cell while preserving its original position relative to the cell.
"""

from __future__ import annotations

import argparse
from pathlib import Path

import numpy as np
from PIL import Image
from scipy import ndimage


SOURCE_CELL = (181, 90)
TARGET_CELL = (224, 144)
COLUMNS = 4
ROWS = 6
EXPECTED_SOURCE_SIZE = (SOURCE_CELL[0] * COLUMNS, SOURCE_CELL[1] * ROWS)
EXPECTED_MAIN_COMPONENTS = COLUMNS * ROWS


def parse_args() -> argparse.Namespace:
	parser = argparse.ArgumentParser()
	parser.add_argument("input", type=Path)
	parser.add_argument("output", type=Path)
	return parser.parse_args()


def main() -> int:
	args = parse_args()
	image = Image.open(args.input).convert("RGBA")
	if image.size != EXPECTED_SOURCE_SIZE:
		raise SystemExit(f"expected source {EXPECTED_SOURCE_SIZE}, got {image.size}")
	pixels = np.asarray(image)
	alpha = pixels[:, :, 3] > 0
	labels, count = ndimage.label(alpha, structure=np.ones((3, 3), dtype=np.uint8))
	objects = ndimage.find_objects(labels)
	areas = np.bincount(labels.ravel())
	main_labels = [label for label in range(1, count + 1) if int(areas[label]) >= 3000]
	if len(main_labels) != EXPECTED_MAIN_COMPONENTS:
		raise SystemExit(f"expected {EXPECTED_MAIN_COMPONENTS} main sprites, found {len(main_labels)}")

	target_size = (TARGET_CELL[0] * COLUMNS, TARGET_CELL[1] * ROWS)
	target = np.zeros((target_size[1], target_size[0], 4), dtype=np.uint8)
	main_by_cell: dict[tuple[int, int], int] = {}
	for label in range(1, count + 1):
		slices = objects[label - 1]
		if slices is None:
			continue
		y_slice, x_slice = slices
		component_mask = labels[y_slice, x_slice] == label
		y_coords, x_coords = np.nonzero(component_mask)
		center_x = float(x_coords.mean() + x_slice.start)
		center_y = float(y_coords.mean() + y_slice.start)
		column = max(0, min(COLUMNS - 1, int(center_x // SOURCE_CELL[0])))
		row = max(0, min(ROWS - 1, int(center_y // SOURCE_CELL[1])))
		if label in main_labels:
			cell = (column, row)
			if cell in main_by_cell:
				raise SystemExit(f"more than one main sprite assigned to cell {cell}")
			main_by_cell[cell] = label

		offset_x = column * (TARGET_CELL[0] - SOURCE_CELL[0]) + (TARGET_CELL[0] - SOURCE_CELL[0]) // 2
		offset_y = row * (TARGET_CELL[1] - SOURCE_CELL[1]) + (TARGET_CELL[1] - SOURCE_CELL[1]) // 2
		source_y, source_x = np.nonzero(labels == label)
		target_x = source_x + offset_x
		target_y = source_y + offset_y
		if target_x.min() < 0 or target_y.min() < 0 or target_x.max() >= target_size[0] or target_y.max() >= target_size[1]:
			raise SystemExit(f"component {label} does not fit target atlas")
		target[target_y, target_x] = pixels[source_y, source_x]

	if len(main_by_cell) != EXPECTED_MAIN_COMPONENTS:
		missing = [(column, row) for row in range(ROWS) for column in range(COLUMNS) if (column, row) not in main_by_cell]
		raise SystemExit(f"missing main sprites in cells: {missing}")

	args.output.parent.mkdir(parents=True, exist_ok=True)
	Image.fromarray(target, "RGBA").save(args.output, optimize=True)
	print(f"SUTURER_ATLAS_REPACK_OK components={count} main={len(main_labels)} size={target_size[0]}x{target_size[1]}")
	return 0


if __name__ == "__main__":
	raise SystemExit(main())
