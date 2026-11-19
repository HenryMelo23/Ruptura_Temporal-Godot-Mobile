#!/usr/bin/env python3
"""Isolated tests for tools/check_architecture_budget.py.

Runs entirely in a temporary fixture root: never touches repository scripts or
the committed baseline. Run with:
  python3 tools/tests/test_check_architecture_budget.py
"""

from __future__ import annotations

import contextlib
import io
import shutil
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import check_architecture_budget as budget  # noqa: E402


def gd_function(name: str, body_lines: int) -> str:
    body = "".join(f"\tvar v{i}: int = {i}\n" for i in range(body_lines))
    return f"func {name}() -> void:\n{body}\n"


CORE = "scripts/main_runtime_core.gd"
OWNER = "scripts/systems/owner.gd"


class ArchitectureBudgetTest(unittest.TestCase):
    def setUp(self) -> None:
        self.root = Path(tempfile.mkdtemp(prefix="arch_budget_"))
        (self.root / "scripts/systems").mkdir(parents=True)
        self.write(CORE, gd_function("_big", 30) + gd_function("_second", 20) + gd_function("_small", 3))
        self.write(OWNER, gd_function("tick", 5))
        self._saved = (budget.DEFAULT_TARGETS, budget.HOTSPOT_CODE_LOC, budget.LONG_FUNCTION_CODE_LOC)
        budget.DEFAULT_TARGETS = [CORE, OWNER]
        budget.HOTSPOT_CODE_LOC = 40
        budget.LONG_FUNCTION_CODE_LOC = 25
        self.assertEqual(self.run_tool("--write-baseline", "--reason", "fixture"), 0)

    def tearDown(self) -> None:
        budget.DEFAULT_TARGETS, budget.HOTSPOT_CODE_LOC, budget.LONG_FUNCTION_CODE_LOC = self._saved
        shutil.rmtree(self.root, ignore_errors=True)

    def write(self, rel: str, text: str) -> None:
        path = self.root / rel
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(text, encoding="utf-8")

    def append(self, rel: str, text: str) -> None:
        with (self.root / rel).open("a", encoding="utf-8") as handle:
            handle.write(text)

    def run_tool(self, *args: str) -> int:
        self.output = io.StringIO()
        with contextlib.redirect_stdout(self.output):
            return budget.main(["--root", str(self.root), *args])

    def test_baseline_passes(self) -> None:
        self.assertEqual(self.run_tool(), 0)
        self.assertIn("ARCHITECTURE_BUDGET_OK", self.output.getvalue())

    def test_core_growth_fails_and_restore_passes(self) -> None:
        original = (self.root / CORE).read_text(encoding="utf-8")
        self.append(CORE, gd_function("_extra_a", 10) + gd_function("_extra_b", 10))
        self.assertEqual(self.run_tool(), 1)
        out = self.output.getvalue()
        self.assertIn("ARCHITECTURE_BUDGET_FAIL", out)
        self.assertIn("main_runtime_core.gd: functions=5 exceeds baseline 3+1", out)
        self.assertIn("code_loc=", out)
        self.write(CORE, original)  # restore fixture
        self.assertEqual(self.run_tool(), 0)

    def test_second_largest_function_growth_fails(self) -> None:
        text = (self.root / CORE).read_text(encoding="utf-8")
        grown = text.replace(gd_function("_second", 20), gd_function("_second", 29))
        self.write(CORE, grown)
        self.assertEqual(self.run_tool(), 1)
        self.assertIn("function _second code_loc=30 exceeds baseline 21+8", self.output.getvalue())

    def test_new_long_function_fails(self) -> None:
        self.write(OWNER, gd_function("tick", 26))
        self.assertEqual(self.run_tool(), 1)
        self.assertIn("owner.gd: long_functions=1 exceeds baseline 0+0", self.output.getvalue())

    def test_uncovered_hotspot_fails(self) -> None:
        self.write("scripts/systems/new_giant.gd", "".join(gd_function(f"f{i}", 9) for i in range(5)))
        self.assertEqual(self.run_tool(), 1)
        self.assertIn("new_giant.gd: uncovered hotspot", self.output.getvalue())

    def test_small_new_file_is_not_a_failure(self) -> None:
        self.write("scripts/systems/tiny_owner.gd", gd_function("x", 3))
        self.assertEqual(self.run_tool(), 0)

    def test_write_baseline_requires_reason(self) -> None:
        self.assertEqual(self.run_tool("--write-baseline"), 2)

    def test_json_mode_reports_failures(self) -> None:
        self.append(CORE, gd_function("_extra", 30))
        self.assertEqual(self.run_tool("--json"), 1)
        self.assertIn('"status": "FAIL"', self.output.getvalue())

    def test_large_shrink_only_warns(self) -> None:
        budget_slack = budget.SLACK_CODE_LOC
        budget.SLACK_CODE_LOC = 10
        try:
            self.write(CORE, gd_function("_big", 30))
            self.assertEqual(self.run_tool(), 0)
            self.assertIn("ARCHITECTURE_BUDGET_SLACK", self.output.getvalue())
        finally:
            budget.SLACK_CODE_LOC = budget_slack


if __name__ == "__main__":
    unittest.main(verbosity=2)
