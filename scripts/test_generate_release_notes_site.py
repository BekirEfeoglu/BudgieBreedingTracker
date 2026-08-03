#!/usr/bin/env python3
"""Unit tests for generate_release_notes_site.py."""

from __future__ import annotations

import sys
import tempfile
import unittest
from shutil import rmtree
from io import StringIO
from pathlib import Path
from unittest.mock import patch


SCRIPTS_DIR = Path(__file__).resolve().parent
sys.path.insert(0, str(SCRIPTS_DIR))

import generate_release_notes_site as release_site  # noqa: E402


def write_release(root: Path, version: str, **notes: str) -> Path:
    release_dir = root / version
    release_dir.mkdir(parents=True)
    for language, note in notes.items():
        (release_dir / f"{language}.txt").write_text(note, encoding="utf-8")
    return release_dir


NOTE = "Product v1\n\nHighlights:\n• First change\n• Second change\n\nThanks!\n"


class ReleaseNoteParsingTest(unittest.TestCase):
    def test_semantic_version_key_sorts_versions(self):
        self.assertLess(
            release_site.semantic_version_key("1.1.9"),
            release_site.semantic_version_key("1.2.0"),
        )

    def test_semantic_version_key_rejects_non_semantic_version(self):
        with self.assertRaisesRegex(ValueError, "invalid release-note"):
            release_site.semantic_version_key("v1.1.9")

    def test_read_app_version_reads_semantic_portion(self):
        with tempfile.TemporaryDirectory() as raw:
            pubspec = Path(raw) / "pubspec.yaml"
            pubspec.write_text("name: test\nversion: 2.3.4+56\n", encoding="utf-8")
            self.assertEqual("2.3.4", release_site.read_app_version(pubspec))

    def test_read_app_version_rejects_missing_version(self):
        with tempfile.TemporaryDirectory() as raw:
            pubspec = Path(raw) / "pubspec.yaml"
            pubspec.write_text("name: test\n", encoding="utf-8")
            with self.assertRaisesRegex(ValueError, "could not read version"):
                release_site.read_app_version(pubspec)

    def test_parse_note_blocks_preserves_structure_and_escapes_html(self):
        rendered = release_site.parse_note_blocks(
            "Title\n\nWhat changed <today>\n• Safer & faster\n\nThanks!\n"
        )
        self.assertIn("<p>What changed &lt;today&gt;</p>", rendered)
        self.assertIn("<li>Safer &amp; faster</li>", rendered)
        self.assertIn("<p>Thanks!</p>", rendered)

    def test_parse_note_blocks_rejects_empty_or_title_only_notes(self):
        with self.assertRaisesRegex(ValueError, "empty"):
            release_site.parse_note_blocks("\n")
        with self.assertRaisesRegex(ValueError, "no body"):
            release_site.parse_note_blocks("Title only\n")


class ReleaseDiscoveryTest(unittest.TestCase):
    def test_discovers_complete_releases_newest_first(self):
        with tempfile.TemporaryDirectory() as raw:
            source = Path(raw)
            for version in ("1.0.0", "1.2.0"):
                write_release(source, version, tr=NOTE, en=NOTE, de=NOTE)

            releases = release_site.discover_releases(source)

            self.assertEqual(["1.2.0", "1.0.0"], [release.version for release in releases])
            self.assertIn("<ul>", releases[0].notes["tr"])

    def test_rejects_missing_source_missing_language_and_invalid_directory(self):
        with tempfile.TemporaryDirectory() as raw:
            source = Path(raw) / "missing"
            with self.assertRaisesRegex(ValueError, "source directory is missing"):
                release_site.discover_releases(source)

            source.mkdir()
            write_release(source, "1.0.0", tr=NOTE, en=NOTE)
            with self.assertRaisesRegex(ValueError, "missing de"):
                release_site.discover_releases(source)

            rmtree(source / "1.0.0")
            (source / "not-a-version").mkdir()
            with self.assertRaisesRegex(ValueError, "invalid release-note"):
                release_site.discover_releases(source)

    def test_rejects_empty_source_directory(self):
        with tempfile.TemporaryDirectory() as raw:
            with self.assertRaisesRegex(ValueError, "no release-note"):
                release_site.discover_releases(Path(raw))


class PageGenerationTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.root = Path(self.temp.name)
        self.source = self.root / "source"
        write_release(self.source, "1.1.9", tr=NOTE, en=NOTE, de=NOTE)
        self.pubspec = self.root / "pubspec.yaml"
        self.pubspec.write_text("version: 1.1.9+61\n", encoding="utf-8")
        self.paths = {
            language: self.root / language / "release-notes" / "index.html"
            for language in release_site.LANGUAGES
        }
        self.paths["tr"] = self.root / "release-notes" / "index.html"
        self.page_paths = patch.object(release_site, "PAGE_PATHS", self.paths)
        self.page_paths.start()
        self.addCleanup(self.page_paths.stop)
        self.addCleanup(self.temp.cleanup)

    def test_renders_localized_pages_with_language_links_and_release_cards(self):
        pages = release_site.expected_pages(self.source, self.pubspec)
        german = pages[self.paths["de"]]

        self.assertEqual(set(self.paths.values()), set(pages))
        self.assertIn('<html lang="de">', german)
        self.assertIn("Versionshinweise", german)
        self.assertIn("v1.1.9", german)
        self.assertIn('hreflang="tr"', german)
        self.assertIn('aria-current="page"', german)

    def test_requires_notes_for_current_pubspec_version(self):
        self.pubspec.write_text("version: 1.2.0+62\n", encoding="utf-8")
        with self.assertRaisesRegex(ValueError, "missing release notes"):
            release_site.expected_pages(self.source, self.pubspec)

    def test_writes_and_detects_stale_generated_pages(self):
        pages = release_site.expected_pages(self.source, self.pubspec)
        self.assertEqual(list(self.paths.values()), release_site.stale_pages(pages))

        release_site.write_pages(pages)
        self.assertEqual([], release_site.stale_pages(pages))

        self.paths["tr"].write_text("stale", encoding="utf-8")
        self.assertEqual([self.paths["tr"]], release_site.stale_pages(pages))


class CommandTest(unittest.TestCase):
    def test_parse_args_requires_a_single_mode(self):
        self.assertTrue(release_site.parse_args(["--write"]).write)
        self.assertTrue(release_site.parse_args(["--check"]).check)
        with self.assertRaises(SystemExit):
            release_site.parse_args([])
        with self.assertRaises(SystemExit):
            release_site.parse_args(["--write", "--check"])

    def test_main_writes_and_checks_pages(self):
        pages = {Path("release-notes/index.html"): "generated"}
        with patch.object(release_site, "expected_pages", return_value=pages), patch.object(
            release_site, "write_pages"
        ) as write_pages, patch.object(release_site, "stale_pages", return_value=[]):
            self.assertEqual(0, release_site.main(["--write"]))
            write_pages.assert_called_once_with(pages)
            self.assertEqual(0, release_site.main(["--check"]))

    def test_main_reports_source_and_staleness_errors(self):
        with patch.object(
            release_site, "expected_pages", side_effect=ValueError("bad source")
        ), patch("sys.stdout", new=StringIO()) as output:
            self.assertEqual(1, release_site.main(["--check"]))
            self.assertIn("bad source", output.getvalue())

        stale = release_site.ROOT / "docs" / "release-notes" / "index.html"
        with patch.object(release_site, "expected_pages", return_value={}), patch.object(
            release_site, "stale_pages", return_value=[stale]
        ), patch("sys.stdout", new=StringIO()) as output:
            self.assertEqual(1, release_site.main(["--check"]))
            self.assertIn("docs/release-notes/index.html", output.getvalue())


if __name__ == "__main__":
    unittest.main()
