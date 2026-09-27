#!/usr/bin/env python3
from __future__ import annotations

import csv
import re
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / ".agent_index" / "runtime_symbols.tsv"
FILES = [
    ROOT / "scripts" / "main_runtime_core.gd",
    ROOT / "scripts" / "main_runtime_state.gd",
]
FILES.extend(sorted((ROOT / "scripts" / "presentation").glob("*.gd")))
FILES.extend(sorted((ROOT / "scripts" / "systems").rglob("*.gd")))
FILES.extend(sorted((ROOT / "scripts" / "ui").glob("*.gd")))
FILES.extend(sorted((ROOT / "scripts" / "vfx").glob("*.gd")))

FUNC_RE = re.compile(r"^(?:static\s+)?func\s+([A-Za-z_][A-Za-z0-9_]*)\s*\(")


def index_file(path: Path) -> list[dict[str, object]]:
    lines = path.read_text(encoding="utf-8-sig", errors="replace").splitlines()
    symbols: list[tuple[str, int]] = []
    for number, line in enumerate(lines, start=1):
        match = FUNC_RE.match(line)
        if match:
            symbols.append((match.group(1), number))
    rows: list[dict[str, object]] = []
    for idx, (name, start) in enumerate(symbols):
        end = symbols[idx + 1][1] - 1 if idx + 1 < len(symbols) else len(lines)
        rows.append(
            {
                "file": path.relative_to(ROOT).as_posix(),
                "symbol": name,
                "start_line": start,
                "end_line": end,
                "line_count": max(1, end - start + 1),
            }
        )
    return rows


def main() -> None:
    rows: list[dict[str, object]] = []
    seen: set[Path] = set()
    for path in FILES:
        if path in seen or not path.exists() or not path.is_file():
            continue
        seen.add(path)
        rows.extend(index_file(path))
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    with OUTPUT.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(
            handle,
            fieldnames=["file", "symbol", "start_line", "end_line", "line_count"],
            delimiter="\t",
        )
        writer.writeheader()
        writer.writerows(rows)
    print(f"RUNTIME_INDEX_READY {OUTPUT.relative_to(ROOT).as_posix()} symbols={len(rows)}")


if __name__ == "__main__":
    main()
