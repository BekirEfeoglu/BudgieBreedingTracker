#!/usr/bin/env python3
"""Unit tests for check_rule_symbol_drift.py."""

import subprocess
import sys
import tempfile
import unittest
from io import StringIO
from pathlib import Path
from unittest.mock import MagicMock, patch

SCRIPTS_DIR = Path(__file__).resolve().parent
sys.path.insert(0, str(SCRIPTS_DIR))


# Fixture runs of a report-printing script leak into the pre-commit gate log
# and read as failures (`xProvider`, `r.md`, "1 finding(s)" are all fixtures).
# unittest reports to stderr, so silencing stdout costs nothing.
_stdout_patcher = None


def setUpModule():
    global _stdout_patcher
    _stdout_patcher = patch("sys.stdout", new=StringIO())
    _stdout_patcher.start()


def tearDownModule():
    if _stdout_patcher is not None:
        _stdout_patcher.stop()


import check_rule_symbol_drift as crsd  # noqa: E402


class TestRegexes(unittest.TestCase):
    def test_provider_regex_matches_camelcase_provider(self):
        found = crsd.PROVIDER_RE.findall("use `communityFeedProvider` here")
        self.assertEqual(found, ["communityFeedProvider"])

    def test_provider_regex_ignores_bare_provider_type(self):
        # `Provider` (PascalCase type) must not match — needs lowercase start.
        self.assertEqual(crsd.PROVIDER_RE.findall("a `Provider` type"), [])

    def test_dart_path_regex_matches_paths_and_basenames(self):
        found = crsd.DART_PATH_RE.findall("`foo_bar.dart` and `lib/a/b.dart`")
        self.assertEqual(found, ["foo_bar.dart", "lib/a/b.dart"])

    def test_class_regex_matches_high_confidence_suffixes(self):
        found = crsd.CLASS_RE.findall(
            "`FooService` `BarNotifier` `BazRepository` `Qux Dao` `XDao` `YMapper` `ZGuard` `Plain`"
        )
        self.assertEqual(
            found, ["FooService", "BarNotifier", "BazRepository", "XDao", "YMapper", "ZGuard"]
        )

    def test_bare_class_regex_matches_prose_word(self):
        found = crsd.BARE_CLASS_RE.findall("The FooService drives it, not aFooServiceX.")
        self.assertEqual(found, ["FooService"])


class TestRg(unittest.TestCase):
    def test_rg_success(self):
        fake = MagicMock(returncode=0, stdout="lib/x.dart\n")
        with patch.object(crsd.subprocess, "run", return_value=fake) as run:
            self.assertTrue(crsd._rg("fooProvider", "lib"))
            self.assertEqual(run.call_args[0][0][0], "rg")

    def test_rg_no_match(self):
        fake = MagicMock(returncode=1, stdout="")
        with patch.object(crsd.subprocess, "run", return_value=fake):
            self.assertFalse(crsd._rg("nopeProvider", "lib"))

    def test_rg_falls_back_to_grep_when_ripgrep_missing(self):
        grep_hit = MagicMock(returncode=0, stdout="lib/x.dart\n")

        def side_effect(cmd, *a, **k):
            if cmd[0] == "rg":
                raise FileNotFoundError("no rg")
            return grep_hit

        with patch.object(crsd.subprocess, "run", side_effect=side_effect) as run:
            self.assertTrue(crsd._rg("fooProvider", "lib"))
            # last call was the grep fallback
            self.assertEqual(run.call_args[0][0][0], "grep")


class TestDartPathExists(unittest.TestCase):
    def test_generated_files_always_pass(self):
        self.assertTrue(crsd._dart_path_exists("foo.g.dart"))
        self.assertTrue(crsd._dart_path_exists("foo.freezed.dart"))

    def test_external_sdk_paths_pass(self):
        self.assertTrue(crsd._dart_path_exists("flutter/src/material/date.dart"))
        self.assertTrue(crsd._dart_path_exists("package:foo/bar.dart"))
        self.assertTrue(crsd._dart_path_exists("some/src/internal.dart"))

    def test_full_path_on_disk(self):
        with tempfile.TemporaryDirectory() as d:
            root = Path(d)
            (root / "lib").mkdir()
            (root / "lib" / "real.dart").write_text("x", encoding="utf-8")
            with patch.object(crsd, "ROOT", root):
                self.assertTrue(crsd._dart_path_exists("lib/real.dart"))
                # partial path resolved by basename fallback
                self.assertTrue(crsd._dart_path_exists("widgets/real.dart"))
                self.assertFalse(crsd._dart_path_exists("ghost.dart"))


class TestProviderExists(unittest.TestCase):
    def test_delegates_to_rg_on_lib(self):
        with patch.object(crsd, "_rg", return_value=True) as rg:
            self.assertTrue(crsd._symbol_exists("xProvider"))
            rg.assert_called_once_with("xProvider", "lib")


class TestTargetFiles(unittest.TestCase):
    def test_wiki_excludes_log_and_archives(self):
        with tempfile.TemporaryDirectory() as d:
            root = Path(d)
            rules = root / ".claude" / "rules"
            wiki = root / "obsidian-brain"
            rules.mkdir(parents=True)
            (wiki / "features").mkdir(parents=True)
            (rules / "a.md").write_text("x", encoding="utf-8")
            (wiki / "log.md").write_text("x", encoding="utf-8")
            (wiki / "log-archive-2026-05.md").write_text("x", encoding="utf-8")
            (wiki / "features" / "birds.md").write_text("x", encoding="utf-8")
            with patch.object(crsd, "RULES_DIR", rules), \
                 patch.object(crsd, "WIKI_DIR", wiki):
                rules_files = [lbl for lbl, _ in crsd._target_files("rules")]
                wiki_files = [lbl for lbl, _ in crsd._target_files("wiki")]
                all_files = [lbl for lbl, _ in crsd._target_files("all")]
            self.assertEqual(rules_files, ["a.md"])
            self.assertEqual(wiki_files, ["features/birds.md"])  # log + archive excluded
            self.assertEqual(len(all_files), 2)


class TestScan(unittest.TestCase):
    def _rules_dir(self, root: Path, content: str) -> Path:
        rules = root / "rules"
        rules.mkdir()
        (rules / "sample.md").write_text(content, encoding="utf-8")
        return rules

    def test_flags_missing_provider(self):
        with tempfile.TemporaryDirectory() as d:
            root = Path(d)
            rules = self._rules_dir(root, "See `ghostProvider` now.")
            with patch.object(crsd, "RULES_DIR", rules), \
                 patch.object(crsd, "_symbol_exists", return_value=False), \
                 patch.object(crsd, "_dart_path_exists", return_value=True):
                findings = crsd.scan()
            self.assertEqual(findings, [("sample.md", "provider", "ghostProvider")])

    def test_allowlisted_provider_skipped(self):
        with tempfile.TemporaryDirectory() as d:
            root = Path(d)
            rules = self._rules_dir(root, "Example `myProvider` here.")
            with patch.object(crsd, "RULES_DIR", rules), \
                 patch.object(crsd, "_symbol_exists", return_value=False):
                self.assertEqual(crsd.scan(), [])

    def test_flags_missing_dart_path_and_skips_allowlisted(self):
        with tempfile.TemporaryDirectory() as d:
            root = Path(d)
            rules = self._rules_dir(root, "`ghost_file.dart` and `_extensions.dart`.")
            with patch.object(crsd, "RULES_DIR", rules), \
                 patch.object(crsd, "_dart_path_exists", return_value=False):
                findings = crsd.scan()
            self.assertEqual(findings, [("sample.md", "dart-path", "ghost_file.dart")])

    def test_duplicate_provider_and_path_deduped(self):
        with tempfile.TemporaryDirectory() as d:
            root = Path(d)
            rules = self._rules_dir(
                root, "`ghostProvider` `ghostProvider` `g.dart` `g.dart`"
            )
            with patch.object(crsd, "RULES_DIR", rules), \
                 patch.object(crsd, "_symbol_exists", return_value=False), \
                 patch.object(crsd, "_dart_path_exists", return_value=False):
                findings = crsd.scan()
            # each distinct token reported once despite two occurrences
            self.assertEqual(
                findings,
                [
                    ("sample.md", "provider", "ghostProvider"),
                    ("sample.md", "dart-path", "g.dart"),
                ],
            )

    def test_clean_when_everything_resolves(self):
        with tempfile.TemporaryDirectory() as d:
            root = Path(d)
            rules = self._rules_dir(root, "`realProvider` and `real.dart`.")
            with patch.object(crsd, "RULES_DIR", rules), \
                 patch.object(crsd, "_symbol_exists", return_value=True), \
                 patch.object(crsd, "_dart_path_exists", return_value=True):
                self.assertEqual(crsd.scan(), [])

    def test_classes_flagged_only_when_enabled(self):
        with tempfile.TemporaryDirectory() as d:
            root = Path(d)
            rules = self._rules_dir(root, "Use `GhostService` here.")
            with patch.object(crsd, "RULES_DIR", rules), \
                 patch.object(crsd, "_symbol_exists", return_value=False):
                # default: classes not checked
                self.assertEqual(crsd.scan(), [])
                # opt-in: flagged
                self.assertEqual(
                    crsd.scan(check_classes=True),
                    [("sample.md", "class", "GhostService")],
                )

    def test_allowlisted_class_skipped(self):
        with tempfile.TemporaryDirectory() as d:
            root = Path(d)
            rules = self._rules_dir(root, "There is no `CalendarService` class.")
            with patch.object(crsd, "RULES_DIR", rules), \
                 patch.object(crsd, "_symbol_exists", return_value=False):
                self.assertEqual(crsd.scan(check_classes=True), [])

    def test_duplicate_class_deduped(self):
        with tempfile.TemporaryDirectory() as d:
            root = Path(d)
            rules = self._rules_dir(root, "`GhostService` again `GhostService`.")
            with patch.object(crsd, "RULES_DIR", rules), \
                 patch.object(crsd, "_symbol_exists", return_value=False):
                # second occurrence hits the `name in seen` continue branch
                self.assertEqual(
                    crsd.scan(check_classes=True),
                    [("sample.md", "class", "GhostService")],
                )

    def test_bare_prose_class_flagged(self):
        with tempfile.TemporaryDirectory() as d:
            root = Path(d)
            rules = self._rules_dir(root, "The GhostService detects online.")
            with patch.object(crsd, "RULES_DIR", rules), \
                 patch.object(crsd, "_symbol_exists", return_value=False):
                self.assertEqual(
                    crsd.scan(check_classes=True),
                    [("sample.md", "class", "GhostService")],
                )

    def test_fenced_code_class_not_scanned(self):
        content = "```dart\nclass GhostService {}\n```\nProse mentions `RealService`."
        with tempfile.TemporaryDirectory() as d:
            root = Path(d)
            rules = self._rules_dir(root, content)
            with patch.object(crsd, "RULES_DIR", rules), \
                 patch.object(crsd, "_symbol_exists", return_value=True):
                # GhostService is inside a fenced block → never scanned;
                # RealService (backtick) resolves → clean.
                self.assertEqual(crsd.scan(check_classes=True), [])


class TestAuditAllowlist(unittest.TestCase):
    def _wiki_with(self, root: Path, text: str) -> tuple[Path, Path]:
        rules = root / ".claude" / "rules"
        wiki = root / "obsidian-brain"
        rules.mkdir(parents=True)
        wiki.mkdir(parents=True)
        (rules / "a.md").write_text(text, encoding="utf-8")
        return rules, wiki

    def test_reports_uncited_entries(self):
        with tempfile.TemporaryDirectory() as d:
            root = Path(d)
            rules, wiki = self._wiki_with(root, "Only `keptProvider` is cited here.")
            with patch.object(crsd, "RULES_DIR", rules), \
                 patch.object(crsd, "WIKI_DIR", wiki), \
                 patch.object(crsd, "PROVIDER_ALLOWLIST", {"keptProvider", "deadProvider"}), \
                 patch.object(crsd, "DART_PATH_ALLOWLIST", set()), \
                 patch.object(crsd, "CLASS_ALLOWLIST", set()):
                stale = crsd.audit_allowlist()
            self.assertEqual(stale, [("PROVIDER_ALLOWLIST", "deadProvider")])

    def test_clean_when_all_cited(self):
        with tempfile.TemporaryDirectory() as d:
            root = Path(d)
            rules, wiki = self._wiki_with(root, "Cite `keptProvider` and `kept.dart`.")
            with patch.object(crsd, "RULES_DIR", rules), \
                 patch.object(crsd, "WIKI_DIR", wiki), \
                 patch.object(crsd, "PROVIDER_ALLOWLIST", {"keptProvider"}), \
                 patch.object(crsd, "DART_PATH_ALLOWLIST", {"kept.dart"}), \
                 patch.object(crsd, "CLASS_ALLOWLIST", set()):
                self.assertEqual(crsd.audit_allowlist(), [])


class TestMain(unittest.TestCase):
    def test_main_clean_returns_0(self):
        with patch.object(crsd, "scan", return_value=[]), \
             patch.object(sys, "argv", ["prog"]):
            self.assertEqual(crsd.main(), 0)

    def test_main_findings_advisory_returns_0(self):
        with patch.object(crsd, "scan", return_value=[("r.md", "provider", "xProvider")]), \
             patch.object(sys, "argv", ["prog"]):
            self.assertEqual(crsd.main(), 0)

    def test_main_findings_strict_returns_1(self):
        with patch.object(crsd, "scan", return_value=[("r.md", "provider", "xProvider")]), \
             patch.object(sys, "argv", ["prog", "--strict"]):
            self.assertEqual(crsd.main(), 1)

    def test_main_audit_clean_returns_0(self):
        with patch.object(crsd, "audit_allowlist", return_value=[]), \
             patch.object(sys, "argv", ["prog", "--audit-allowlist"]):
            self.assertEqual(crsd.main(), 0)

    def test_main_audit_stale_advisory_returns_0(self):
        with patch.object(crsd, "audit_allowlist", return_value=[("PROVIDER_ALLOWLIST", "deadProvider")]), \
             patch.object(sys, "argv", ["prog", "--audit-allowlist"]):
            self.assertEqual(crsd.main(), 0)

    def test_main_audit_stale_strict_returns_1(self):
        with patch.object(crsd, "audit_allowlist", return_value=[("PROVIDER_ALLOWLIST", "deadProvider")]), \
             patch.object(sys, "argv", ["prog", "--audit-allowlist", "--strict"]):
            self.assertEqual(crsd.main(), 1)


if __name__ == "__main__":
    unittest.main()
