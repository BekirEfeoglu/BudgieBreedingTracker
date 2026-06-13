#!/usr/bin/env python3
"""Unit tests for check_obsidian_brain.py."""

import sys
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

SCRIPTS_DIR = Path(__file__).resolve().parent
sys.path.insert(0, str(SCRIPTS_DIR))


def _write_valid_wiki(root: Path) -> Path:
    wiki = root / "obsidian-brain"
    wiki.mkdir()
    (wiki / "README.md").write_text("# README\n\n[[index]]\n", encoding="utf-8")
    (wiki / "CLAUDE.md").write_text("# Contract\n", encoding="utf-8")
    (wiki / "index.md").write_text(
        "# Wiki Index\n\n| Page | Description |\n|---|---|\n| [[README]] | Entry |\n| [[CLAUDE.md]] | Contract |\n| [[index]] | Catalog |\n| [[log]] | Log |\n| [[topic]] | Topic |\n",
        encoding="utf-8",
    )
    (wiki / "log.md").write_text("# Log\n\n## [2026-06-13] test | ok\n", encoding="utf-8")
    (wiki / "topic.md").write_text(
        "# Topic\n\nBack to [[index]].\n\nInline example: `[[missing-example]]`.\n",
        encoding="utf-8",
    )
    return wiki


class TestCheckObsidianBrain(unittest.TestCase):
    def test_returns_0_for_valid_wiki(self):
        import check_obsidian_brain as cob

        with tempfile.TemporaryDirectory() as d:
            root = Path(d)
            wiki = _write_valid_wiki(root)
            with patch.object(cob, "ROOT", root), patch.object(cob, "WIKI_DIR", wiki):
                self.assertEqual(cob.main(), 0)

    def test_returns_1_when_page_exceeds_line_limit(self):
        import check_obsidian_brain as cob

        with tempfile.TemporaryDirectory() as d:
            root = Path(d)
            wiki = _write_valid_wiki(root)
            (wiki / "topic.md").write_text("\n".join(["# Topic"] + ["x"] * 201), encoding="utf-8")
            with patch.object(cob, "ROOT", root), patch.object(cob, "WIKI_DIR", wiki):
                self.assertEqual(cob.main(), 1)

    def test_returns_1_when_wikilink_is_missing(self):
        import check_obsidian_brain as cob

        with tempfile.TemporaryDirectory() as d:
            root = Path(d)
            wiki = _write_valid_wiki(root)
            (wiki / "topic.md").write_text("# Topic\n\n[[missing-page]]\n", encoding="utf-8")
            with patch.object(cob, "ROOT", root), patch.object(cob, "WIKI_DIR", wiki):
                self.assertEqual(cob.main(), 1)

    def test_returns_1_when_page_is_missing_from_index(self):
        import check_obsidian_brain as cob

        with tempfile.TemporaryDirectory() as d:
            root = Path(d)
            wiki = _write_valid_wiki(root)
            (wiki / "unlisted.md").write_text("# Unlisted\n\n[[index]]\n", encoding="utf-8")
            with patch.object(cob, "ROOT", root), patch.object(cob, "WIKI_DIR", wiki):
                self.assertEqual(cob.main(), 1)


if __name__ == "__main__":
    unittest.main()
