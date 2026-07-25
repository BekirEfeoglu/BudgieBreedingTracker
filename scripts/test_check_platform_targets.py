#!/usr/bin/env python3
"""Unit tests for check_platform_targets.py."""

import runpy
import sys
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

SCRIPTS_DIR = Path(__file__).resolve().parent
sys.path.insert(0, str(SCRIPTS_DIR))


class TestCheckPlatformTargets(unittest.TestCase):
    def test_returns_0_without_flutter_web_target(self):
        import check_platform_targets as cpt

        with tempfile.TemporaryDirectory() as d:
            root = Path(d)
            (root / "docs").mkdir()
            (root / "docs" / "index.html").write_text("<html></html>", encoding="utf-8")

            with patch.object(cpt, "ROOT", root):
                self.assertEqual(cpt.main(), 0)

    def test_returns_1_when_flutter_web_target_exists(self):
        import check_platform_targets as cpt

        with tempfile.TemporaryDirectory() as d:
            root = Path(d)
            (root / "web").mkdir()
            (root / "web" / "index.html").write_text("<html></html>", encoding="utf-8")

            with patch.object(cpt, "ROOT", root):
                self.assertEqual(cpt.main(), 1)


    def test_returns_0_when_web_dir_exists_but_holds_no_flutter_markers(self):
        """Bos bir `web/` dizini Flutter web target'i DEGILDIR.

        Bu dal, dizinin varligi ile gercek bir web app'in varligini ayirir;
        yalnizca `web/` gormek yanlis pozitif uretmemeli.
        """
        import check_platform_targets as cpt

        with tempfile.TemporaryDirectory() as d:
            root = Path(d)
            (root / "web").mkdir()
            (root / "web" / "notes.txt").write_text("scratch", encoding="utf-8")

            with patch.object(cpt, "ROOT", root):
                self.assertEqual(cpt.main(), 0)

    def test_detects_each_flutter_web_marker(self):
        import check_platform_targets as cpt

        for marker, is_dir in (("index.html", False), ("manifest.json", False), ("icons", True)):
            with self.subTest(marker=marker):
                with tempfile.TemporaryDirectory() as d:
                    root = Path(d)
                    (root / "web").mkdir()
                    target = root / "web" / marker
                    if is_dir:
                        target.mkdir()
                    else:
                        target.write_text("x", encoding="utf-8")
                    with patch.object(cpt, "ROOT", root):
                        self.assertEqual(cpt.main(), 1)


class TestEntrypoint(unittest.TestCase):
    def test_script_runs_as_main(self):
        """`if __name__ == '__main__': raise SystemExit(main())` dalini kapsar."""
        script = str(SCRIPTS_DIR / "check_platform_targets.py")
        with self.assertRaises(SystemExit) as ctx:
            runpy.run_path(script, run_name="__main__")
        self.assertEqual(ctx.exception.code, 0)


if __name__ == "__main__":
    unittest.main()
