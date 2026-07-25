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

    def test_returns_1_when_inline_file_reference_is_missing(self):
        import check_obsidian_brain as cob

        with tempfile.TemporaryDirectory() as d:
            root = Path(d)
            wiki = _write_valid_wiki(root)
            (wiki / "topic.md").write_text(
                "# Topic\n\nImplementation lives in `lib/missing/file.dart`.\n",
                encoding="utf-8",
            )

            with patch.object(cob, "ROOT", root), patch.object(cob, "WIKI_DIR", wiki):
                self.assertEqual(cob.main(), 1)

    def test_allows_gitignored_generated_file_references(self):
        """Generated, gitignored paths are absent from a fresh checkout.

        They are still worth documenting — ios/Flutter/DartDefines.xcconfig is
        named in the release docs precisely because it goes stale and can ship a
        DSN-less build. Without this allowance the lint passes locally (where
        the file exists) and fails in CI, which is how it was found.
        """
        import check_obsidian_brain as cob

        with tempfile.TemporaryDirectory() as d:
            root = Path(d)
            wiki = _write_valid_wiki(root)
            (wiki / "topic.md").write_text(
                "# Topic\n\nXcode reads `ios/Flutter/DartDefines.xcconfig`.\n",
                encoding="utf-8",
            )

            with patch.object(cob, "ROOT", root), patch.object(cob, "WIKI_DIR", wiki):
                self.assertEqual(cob.main(), 0)

    def test_returns_0_when_inline_file_reference_exists(self):
        import check_obsidian_brain as cob

        with tempfile.TemporaryDirectory() as d:
            root = Path(d)
            wiki = _write_valid_wiki(root)
            (root / "lib").mkdir()
            (root / "lib" / "existing.dart").write_text("void main() {}\n", encoding="utf-8")
            (wiki / "topic.md").write_text(
                "# Topic\n\nImplementation lives in `lib/existing.dart`.\n",
                encoding="utf-8",
            )

            with patch.object(cob, "ROOT", root), patch.object(cob, "WIKI_DIR", wiki):
                self.assertEqual(cob.main(), 0)

    def test_returns_1_when_overview_schema_metric_drifts(self):
        import check_obsidian_brain as cob

        with tempfile.TemporaryDirectory() as d:
            root = Path(d)
            wiki = _write_valid_wiki(root)
            (root / "lib" / "data" / "local" / "database").mkdir(parents=True)
            (root / "lib" / "data" / "local" / "database" / "app_database.dart").write_text(
                "class AppDatabase { int get schemaVersion => 26; }\n",
                encoding="utf-8",
            )
            (wiki / "index.md").write_text(
                "# Wiki Index\n\n| Page | Description |\n|---|---|\n"
                "| [[README]] | Entry |\n| [[CLAUDE.md]] | Contract |\n"
                "| [[index]] | Catalog |\n| [[log]] | Log |\n"
                "| [[topic]] | Topic |\n| [[overview]] | Overview |\n",
                encoding="utf-8",
            )
            (wiki / "overview.md").write_text(
                "# Overview\n\n"
                "| Metric | Value |\n"
                "|--------|-------|\n"
                "| DB schema version | 25 |\n",
                encoding="utf-8",
            )

            with patch.object(cob, "ROOT", root), patch.object(cob, "WIKI_DIR", wiki):
                self.assertEqual(cob.main(), 1)

    def test_returns_1_when_required_decision_sections_are_missing(self):
        import check_obsidian_brain as cob

        with tempfile.TemporaryDirectory() as d:
            root = Path(d)
            wiki = _write_valid_wiki(root)
            (wiki / "features").mkdir()
            (wiki / "features" / "community.md").write_text(
                "# Feature: community\n\n[[index]]\n",
                encoding="utf-8",
            )
            (wiki / "index.md").write_text(
                "# Wiki Index\n\n| Page | Description |\n|---|---|\n"
                "| [[README]] | Entry |\n| [[CLAUDE.md]] | Contract |\n"
                "| [[index]] | Catalog |\n| [[log]] | Log |\n"
                "| [[topic]] | Topic |\n| [[features/community]] | Community |\n",
                encoding="utf-8",
            )

            with patch.object(cob, "ROOT", root), patch.object(cob, "WIKI_DIR", wiki):
                self.assertEqual(cob.main(), 1)

    def test_returns_1_when_active_log_has_too_many_entries(self):
        import check_obsidian_brain as cob

        with tempfile.TemporaryDirectory() as d:
            root = Path(d)
            wiki = _write_valid_wiki(root)
            entries = "\n".join(
                f"## [2026-07-{day:02d}] docs | entry {day}" for day in range(1, 32)
            )
            (wiki / "log.md").write_text(f"# Log\n\n{entries}\n", encoding="utf-8")

            with patch.object(cob, "ROOT", root), patch.object(cob, "WIKI_DIR", wiki):
                self.assertEqual(cob.main(), 1)


if __name__ == "__main__":
    unittest.main()
