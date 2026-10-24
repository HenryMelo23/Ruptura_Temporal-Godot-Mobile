#!/usr/bin/env python3
"""Audit sprite canvas, alpha bounds, edge clearance, and disconnected islands."""

from __future__ import annotations

import argparse
from collections import deque
from pathlib import Path
import sys

from PIL import Image


def parse_size(value: str) -> tuple[int, int]:
    try:
        width, height = value.lower().split("x", 1)
        parsed = (int(width), int(height))
    except (ValueError, AttributeError) as exc:
        raise argparse.ArgumentTypeError("use WIDTHxHEIGHT, for example 312x312") from exc
    if parsed[0] <= 0 or parsed[1] <= 0:
        raise argparse.ArgumentTypeError("dimensions must be positive")
    return parsed


def alpha_mask(path: Path, threshold: int) -> tuple[Image.Image, bytearray]:
    with Image.open(path) as source:
        image = source.convert("RGBA")
    alpha = image.getchannel("A")
    mask = bytearray(1 if value > threshold else 0 for value in alpha.tobytes())
    return image, mask


def mask_bbox(mask: bytearray, width: int, height: int) -> tuple[int, int, int, int] | None:
    left = width
    top = height
    right = -1
    bottom = -1
    for index, value in enumerate(mask):
        if not value:
            continue
        x = index % width
        y = index // width
        left = min(left, x)
        top = min(top, y)
        right = max(right, x)
        bottom = max(bottom, y)
    if right < 0:
        return None
    return left, top, right + 1, bottom + 1


def connected_components(mask: bytearray, width: int, height: int) -> list[dict[str, int]]:
    visited = bytearray(len(mask))
    components: list[dict[str, int]] = []
    for start, value in enumerate(mask):
        if not value or visited[start]:
            continue
        queue: deque[int] = deque([start])
        visited[start] = 1
        area = 0
        min_x = max_x = start % width
        min_y = max_y = start // width
        while queue:
            index = queue.popleft()
            x = index % width
            y = index // width
            area += 1
            min_x = min(min_x, x)
            max_x = max(max_x, x)
            min_y = min(min_y, y)
            max_y = max(max_y, y)
            for neighbor in (index - 1, index + 1, index - width, index + width):
                if neighbor < 0 or neighbor >= len(mask) or visited[neighbor] or not mask[neighbor]:
                    continue
                nx = neighbor % width
                ny = neighbor // width
                if abs(nx - x) + abs(ny - y) != 1:
                    continue
                visited[neighbor] = 1
                queue.append(neighbor)
        components.append(
            {
                "area": area,
                "left": min_x,
                "top": min_y,
                "right": max_x + 1,
                "bottom": max_y + 1,
            }
        )
    return sorted(components, key=lambda item: item["area"], reverse=True)


def inspect(path: Path, args: argparse.Namespace, reference_height_ratio: float | None) -> bool:
    image, mask = alpha_mask(path, args.alpha_threshold)
    width, height = image.size
    bbox = mask_bbox(mask, width, height)
    failures: list[str] = []

    if args.expected_size and image.size != args.expected_size:
        failures.append(f"canvas {width}x{height}, expected {args.expected_size[0]}x{args.expected_size[1]}")
    if bbox is None:
        failures.append("empty alpha content")
        print(f"FAIL {path}: " + "; ".join(failures))
        return False

    left, top, right, bottom = bbox
    clearances = (left, top, width - right, height - bottom)
    if min(clearances) < args.edge_margin:
        failures.append(
            "crop risk: edge clearance L/T/R/B=" + "/".join(str(value) for value in clearances)
        )

    visible_height_ratio = (bottom - top) / height
    if reference_height_ratio is not None:
        drift = abs(visible_height_ratio - reference_height_ratio) / reference_height_ratio
        if drift > args.max_height_drift:
            failures.append(f"visible-height drift {drift:.1%} exceeds {args.max_height_drift:.1%}")

    components = connected_components(mask, width, height)
    if args.max_components is not None and len(components) > args.max_components:
        failures.append(f"{len(components)} components, allowed {args.max_components}")

    largest_area = components[0]["area"]
    islands = [item for item in components[1:] if item["area"] <= largest_area * args.island_ratio]
    component_summary = ", ".join(
        f"{item['area']}px@{item['left']},{item['top']}..{item['right']},{item['bottom']}"
        for item in components[: args.component_report_limit]
    )
    status = "FAIL" if failures else "OK"
    print(
        f"{status} {path}: canvas={width}x{height} bbox={right-left}x{bottom-top}+{left}+{top} "
        f"clearance={clearances} components={len(components)} small_islands={len(islands)}"
    )
    if component_summary:
        print(f"  components: {component_summary}")
    for failure in failures:
        print(f"  failure: {failure}")
    if len(components) > 1:
        print("  review: verify every disconnected component is intentional")
    return not failures


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("frames", nargs="+", type=Path)
    parser.add_argument("--expected-size", type=parse_size)
    parser.add_argument("--base", type=Path, help="canonical body-height reference")
    parser.add_argument("--alpha-threshold", type=int, default=8)
    parser.add_argument("--edge-margin", type=int, default=2)
    parser.add_argument("--max-height-drift", type=float, default=0.05)
    parser.add_argument("--max-components", type=int)
    parser.add_argument("--island-ratio", type=float, default=0.005)
    parser.add_argument("--component-report-limit", type=int, default=12)
    args = parser.parse_args()

    if not 0 <= args.alpha_threshold <= 254:
        parser.error("--alpha-threshold must be between 0 and 254")
    if args.edge_margin < 0 or args.max_height_drift < 0 or args.island_ratio < 0:
        parser.error("margin, drift, and island ratio cannot be negative")

    missing = [path for path in args.frames if not path.is_file()]
    if args.base and not args.base.is_file():
        missing.append(args.base)
    if missing:
        for path in missing:
            print(f"missing: {path}", file=sys.stderr)
        return 2

    reference_height_ratio: float | None = None
    if args.base:
        reference_image, reference_mask = alpha_mask(args.base, args.alpha_threshold)
        reference_bbox = mask_bbox(reference_mask, *reference_image.size)
        if reference_bbox is None:
            print(f"base has no visible alpha content: {args.base}", file=sys.stderr)
            return 2
        reference_height_ratio = (reference_bbox[3] - reference_bbox[1]) / reference_image.height
        print(f"BASE {args.base}: visible_height_ratio={reference_height_ratio:.6f}")

    results = [inspect(path, args, reference_height_ratio) for path in args.frames]
    passed = all(results)
    return 0 if passed else 1


if __name__ == "__main__":
    raise SystemExit(main())
