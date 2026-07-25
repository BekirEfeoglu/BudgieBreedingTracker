#!/usr/bin/env python3
"""Unit tests for check_obsidian_brain.py."""

import re
import subprocess
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


def _entry(date: str, filler: int = 0) -> str:
    body = "".join(f"line {i}\n" for i in range(filler))
    return f"## [{date}] test | entry\n\n{body}\n"


def _write_rotatable_wiki(root: Path, *, entry_dates, archive_dates,
                          filler: int = 0, index_range: str = "(07-01 to 07-02)",
                          archive_range: str = "(07-01 to 07-02)") -> Path:
    """Wiki whose log.md holds `entry_dates` newest-first plus one archive."""
    wiki = root / "obsidian-brain"
    wiki.mkdir()
    (wiki / "README.md").write_text("# README\n\n[[index]]\n", encoding="utf-8")
    (wiki / "CLAUDE.md").write_text("# Contract\n", encoding="utf-8")
    (wiki / "index.md").write_text(
        "# Wiki Index\n\n| Page | Description |\n|---|---|\n"
        "| [[README]] | Entry |\n| [[CLAUDE.md]] | Contract |\n| [[index]] | Catalog |\n"
        "| [[log]] | Log |\n"
        f"| [[log-archive-2026-07]] | Archived entries {index_range} |\n",
        encoding="utf-8",
    )
    (wiki / "log.md").write_text(
        "# Change Log\n\n---\n\n" + "".join(_entry(d, filler) for d in entry_dates),
        encoding="utf-8",
    )
    (wiki / "log-archive-2026-07.md").write_text(
        f"# Archive\n\nArchived entries {archive_range}\n\n---\n\n"
        + "".join(_entry(d) for d in archive_dates),
        encoding="utf-8",
    )
    return wiki


class TestRotateLog(unittest.TestCase):
    """rotate_log: elle yapilan uc adimi (tasi, arsiv araligini genislet,
    index satirini genislet) otomatiklestirir."""

    def _rotate(self, wiki):
        import check_obsidian_brain as cob
        return cob.rotate_log(wiki)

    def test_no_op_when_within_limits(self):
        with tempfile.TemporaryDirectory() as d:
            wiki = _write_rotatable_wiki(Path(d), entry_dates=["2026-07-10"],
                                         archive_dates=["2026-07-02"])
            before = (wiki / "log.md").read_text(encoding="utf-8")
            messages, errors = self._rotate(wiki)
        self.assertEqual(errors, [])
        self.assertIn("nothing to rotate", messages[0])
        self.assertEqual(before, before)

    def test_moves_oldest_entries_when_over_the_line_cap(self):
        import check_obsidian_brain as cob

        with tempfile.TemporaryDirectory() as d:
            # 4 entries x 60 filler lines = well past MAX_LINES
            wiki = _write_rotatable_wiki(
                Path(d),
                entry_dates=["2026-07-14", "2026-07-13", "2026-07-12", "2026-07-11"],
                archive_dates=["2026-07-02"], filler=60,
            )
            messages, errors = self._rotate(wiki)
            log_text = (wiki / "log.md").read_text(encoding="utf-8")
            archive_text = (wiki / "log-archive-2026-07.md").read_text(encoding="utf-8")

        self.assertEqual(errors, [])
        self.assertLessEqual(len(log_text.splitlines()), cob.MAX_LINES)
        # Oldest moved, newest kept.
        self.assertNotIn("[2026-07-11]", log_text)
        self.assertIn("[2026-07-14]", log_text)
        self.assertIn("[2026-07-11]", archive_text)
        self.assertTrue(any("moved" in m for m in messages))

    def test_archive_stays_newest_first_after_rotation(self):
        with tempfile.TemporaryDirectory() as d:
            wiki = _write_rotatable_wiki(
                Path(d),
                entry_dates=["2026-07-14", "2026-07-13", "2026-07-12", "2026-07-11"],
                archive_dates=["2026-07-02"], filler=60,
            )
            self._rotate(wiki)
            archive_text = (wiki / "log-archive-2026-07.md").read_text(encoding="utf-8")
        dates = re.findall(r"^## \[(\d{4}-\d{2}-\d{2})\]", archive_text, re.MULTILINE)
        self.assertEqual(dates, sorted(dates, reverse=True))

    def test_widens_archive_and_index_ranges(self):
        with tempfile.TemporaryDirectory() as d:
            wiki = _write_rotatable_wiki(
                Path(d),
                entry_dates=["2026-07-14", "2026-07-13", "2026-07-12", "2026-07-11"],
                archive_dates=["2026-07-02"], filler=60,
            )
            self._rotate(wiki)
            archive_text = (wiki / "log-archive-2026-07.md").read_text(encoding="utf-8")
            index_text = (wiki / "index.md").read_text(encoding="utf-8")
        self.assertIn("(07-01 to 07-11)", archive_text)
        self.assertIn("(07-01 to 07-11)", index_text)

    def test_widens_a_range_with_trailing_text_in_the_parenthesis(self):
        """Gercek index satiri '(07-17 to 07-24 release, CI, ...)' seklinde.

        Ilk implementasyon kapanis parantezini ikinci tarihin hemen ardinda
        beklediginden bu satiri sessizce atliyordu — gercek wiki'de kosturunca
        yakalandi.
        """
        with tempfile.TemporaryDirectory() as d:
            wiki = _write_rotatable_wiki(
                Path(d),
                entry_dates=["2026-07-14", "2026-07-13", "2026-07-12", "2026-07-11"],
                archive_dates=["2026-07-02"], filler=60,
                index_range="(07-01 to 07-02 release, CI, and security hardening)",
            )
            messages, errors = self._rotate(wiki)
            index_text = (wiki / "index.md").read_text(encoding="utf-8")
        self.assertEqual(errors, [])
        self.assertIn("(07-01 to 07-11 release, CI, and security hardening)", index_text)
        self.assertTrue(any("widened the index row" in m for m in messages))

    def test_warns_when_no_range_to_widen(self):
        with tempfile.TemporaryDirectory() as d:
            wiki = _write_rotatable_wiki(
                Path(d),
                entry_dates=["2026-07-14", "2026-07-13", "2026-07-12", "2026-07-11"],
                archive_dates=["2026-07-02"], filler=60,
                archive_range="for July", index_range="for July",
            )
            messages, errors = self._rotate(wiki)
        self.assertEqual(errors, [])
        self.assertTrue(any("no '(MM-DD to MM-DD)' range" in m for m in messages))
        self.assertTrue(any("index row" in m and "no range" in m for m in messages))

    def test_refuses_to_overflow_the_target_archive(self):
        """Yeni arsiv sayfasi index satiri + aciklama ister — script uydurmaz."""
        with tempfile.TemporaryDirectory() as d:
            wiki = _write_rotatable_wiki(
                Path(d),
                entry_dates=["2026-07-14", "2026-07-13", "2026-07-12", "2026-07-11"],
                archive_dates=["2026-07-02"], filler=60,
            )
            # Fill the archive to just under the cap so any move overflows it.
            archive = wiki / "log-archive-2026-07.md"
            archive.write_text(
                "# Archive\n\nArchived entries (07-01 to 07-02)\n\n---\n\n"
                + _entry("2026-07-02", filler=190),
                encoding="utf-8",
            )
            log_before = (wiki / "log.md").read_text(encoding="utf-8")
            messages, errors = self._rotate(wiki)
            log_after = (wiki / "log.md").read_text(encoding="utf-8")
        self.assertTrue(any("would exceed" in e for e in errors))
        self.assertEqual(log_before, log_after, "log.md must be left untouched")

    def test_errors_when_log_missing(self):
        with tempfile.TemporaryDirectory() as d:
            wiki = Path(d) / "obsidian-brain"
            wiki.mkdir()
            _, errors = self._rotate(wiki)
        self.assertEqual(errors, ["log.md is missing"])

    def test_errors_when_log_has_no_entries(self):
        with tempfile.TemporaryDirectory() as d:
            wiki = Path(d) / "obsidian-brain"
            wiki.mkdir()
            (wiki / "log.md").write_text("# Change Log\n\nno entries\n", encoding="utf-8")
            _, errors = self._rotate(wiki)
        self.assertEqual(errors, ["log.md has no dated session entry"])

    def test_errors_when_no_archive_exists(self):
        with tempfile.TemporaryDirectory() as d:
            wiki = Path(d) / "obsidian-brain"
            wiki.mkdir()
            (wiki / "log.md").write_text(
                "# Change Log\n\n---\n\n" + "".join(
                    _entry(f"2026-07-{n:02d}", 60) for n in (14, 13, 12, 11)),
                encoding="utf-8")
            _, errors = self._rotate(wiki)
        self.assertEqual(errors, ["no log-archive-*.md page found to rotate into"])

    def test_newest_archive_is_chosen_by_content_not_filename(self):
        """`log-archive-2026-07-b.md` dosya adi olarak `...-07.md`'den ONCE gelir."""
        import check_obsidian_brain as cob

        with tempfile.TemporaryDirectory() as d:
            wiki = Path(d) / "obsidian-brain"
            wiki.mkdir()
            (wiki / "log-archive-2026-07.md").write_text(
                "# A\n\n" + _entry("2026-07-02"), encoding="utf-8")
            (wiki / "log-archive-2026-07-b.md").write_text(
                "# B\n\n" + _entry("2026-07-20"), encoding="utf-8")
            (wiki / "log-archive-empty.md").write_text("# Empty\n", encoding="utf-8")
            chosen = cob._newest_archive(wiki)
        self.assertEqual(chosen.name, "log-archive-2026-07-b.md")

    def test_rotate_flag_runs_from_main(self):
        import check_obsidian_brain as cob

        with tempfile.TemporaryDirectory() as d:
            root = Path(d)
            wiki = _write_rotatable_wiki(root, entry_dates=["2026-07-10"],
                                         archive_dates=["2026-07-02"])
            with patch.object(cob, "ROOT", root), patch.object(cob, "WIKI_DIR", wiki):
                code = cob.main(["--rotate"])
        self.assertEqual(code, 0)

    def test_rotate_flag_reports_failure_from_main(self):
        import check_obsidian_brain as cob

        with tempfile.TemporaryDirectory() as d:
            root = Path(d)
            wiki = root / "obsidian-brain"
            wiki.mkdir()
            with patch.object(cob, "ROOT", root), patch.object(cob, "WIKI_DIR", wiki):
                code = cob.main(["--rotate"])
        self.assertEqual(code, 1)


class TestHelperBranches(unittest.TestCase):
    """Dogrudan test edilmemis saf yardimcilar."""

    def test_target_candidates_rejects_empty_link(self):
        import check_obsidian_brain as cob

        with tempfile.TemporaryDirectory() as d:
            wiki = Path(d)
            self.assertEqual(cob._target_candidates(wiki / "a.md", "  ", wiki), [])

    def test_target_candidates_skips_targets_outside_the_wiki(self):
        import check_obsidian_brain as cob

        with tempfile.TemporaryDirectory() as d:
            wiki = Path(d) / "obsidian-brain"
            wiki.mkdir()
            self.assertEqual(cob._target_candidates(wiki / "a.md", "../outside", wiki), [])

    def test_index_targets_returns_empty_when_index_missing(self):
        import check_obsidian_brain as cob

        with tempfile.TemporaryDirectory() as d:
            wiki = Path(d)
            self.assertEqual(cob._index_targets(wiki / "index.md", wiki), set())

    def test_count_json_leaf_keys_counts_nested_leaves(self):
        import check_obsidian_brain as cob

        self.assertEqual(cob._count_json_leaf_keys({"a": {"b": 1, "c": 2}, "d": 3}), 3)

    def test_first_int_parses_and_rejects(self):
        import check_obsidian_brain as cob

        self.assertEqual(cob._first_int("~3,167 per language"), 3167)
        self.assertIsNone(cob._first_int("no digits here"))

    def test_git_tracked_count_returns_none_without_git_dir(self):
        import check_obsidian_brain as cob

        with tempfile.TemporaryDirectory() as d:
            self.assertIsNone(cob._git_tracked_count(Path(d), ["lib/**"]))

    def test_git_tracked_count_returns_none_on_git_failure(self):
        import check_obsidian_brain as cob

        with tempfile.TemporaryDirectory() as d:
            root = Path(d)
            (root / ".git").mkdir()
            completed = subprocess.CompletedProcess(args=[], returncode=128, stdout="", stderr="boom")
            with patch.object(cob.subprocess, "run", return_value=completed):
                self.assertIsNone(cob._git_tracked_count(root, ["lib/**"]))

    def test_git_tracked_count_counts_tracked_files(self):
        import check_obsidian_brain as cob

        with tempfile.TemporaryDirectory() as d:
            root = Path(d)
            (root / ".git").mkdir()
            completed = subprocess.CompletedProcess(
                args=[], returncode=0, stdout="lib/a.dart\nlib/b.dart\n\n", stderr="")
            with patch.object(cob.subprocess, "run", return_value=completed):
                self.assertEqual(cob._git_tracked_count(root, ["lib/**"]), 2)

    def test_check_wiki_reports_missing_directory(self):
        import check_obsidian_brain as cob

        with tempfile.TemporaryDirectory() as d:
            errors = cob.check_wiki(Path(d) / "nope")
        self.assertEqual(len(errors), 1)
        self.assertIn("directory missing", errors[0])

    def test_check_wiki_reports_missing_log(self):
        import check_obsidian_brain as cob

        with tempfile.TemporaryDirectory() as d:
            wiki = Path(d) / "obsidian-brain"
            wiki.mkdir()
            (wiki / "index.md").write_text("# Index\n", encoding="utf-8")
            errors = cob.check_wiki(wiki)
        self.assertIn("log.md is missing", errors)

    def test_check_wiki_reports_log_without_entries(self):
        import check_obsidian_brain as cob

        with tempfile.TemporaryDirectory() as d:
            wiki = Path(d) / "obsidian-brain"
            wiki.mkdir()
            (wiki / "index.md").write_text("# Index\n\n[[log]]\n", encoding="utf-8")
            (wiki / "log.md").write_text("# Change Log\n\nnothing\n", encoding="utf-8")
            errors = cob.check_wiki(wiki)
        self.assertIn("log.md has no dated session entry", errors)


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
