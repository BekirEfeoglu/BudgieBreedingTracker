#!/usr/bin/env python3
"""Unit tests for check_platform_targets.py."""

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


if __name__ == "__main__":
    unittest.main()
