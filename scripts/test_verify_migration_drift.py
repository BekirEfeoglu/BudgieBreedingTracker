#!/usr/bin/env python3
"""Unit tests for verify_migration_drift.py."""

import sys
import unittest
from io import StringIO
from pathlib import Path
from unittest.mock import patch

SCRIPTS_DIR = Path(__file__).resolve().parent
sys.path.insert(0, str(SCRIPTS_DIR))

import verify_migration_drift as vmd  # noqa: E402


def _write(tmp: Path, *names: str) -> Path:
    for name in names:
        (tmp / name).write_text("-- noop\n", encoding="utf-8")
    return tmp


class TestParsing(unittest.TestCase):
    def test_parses_full_timestamp_version(self):
        self.assertEqual(
            vmd.parse_version("20260709180636_reconcile_policy.sql"), "20260709180636"
        )

    def test_parses_short_historical_version(self):
        self.assertEqual(
            vmd.parse_version("20260309_guard_founder.sql"), "20260309"
        )

    def test_rejects_missing_version(self):
        self.assertIsNone(vmd.parse_version("create_profiles.sql"))

    def test_rejects_empty_description(self):
        self.assertIsNone(vmd.parse_version("20260709180636_.sql"))

    def test_rejects_non_sql_extension(self):
        self.assertIsNone(vmd.parse_version("20260709180636_desc.txt"))

    def test_rejects_uppercase_description(self):
        self.assertIsNone(vmd.parse_version("20260709180636_Desc.sql"))


class TestStructuralChecks(unittest.TestCase):
    def test_find_malformed_returns_only_bad_names(self):
        names = ["20260709180636_ok.sql", "bad.sql", "20260309_ok.sql"]
        self.assertEqual(vmd.find_malformed(names), ["bad.sql"])

    def test_find_malformed_empty_when_all_valid(self):
        self.assertEqual(vmd.find_malformed(["20260709180636_ok.sql"]), [])

    def test_find_duplicate_versions_groups_collisions(self):
        names = [
            "20260709180636_a.sql",
            "20260709180636_b.sql",
            "20260709180637_c.sql",
        ]
        dupes = vmd.find_duplicate_versions(names)
        self.assertEqual(
            dupes,
            {"20260709180636": ["20260709180636_a.sql", "20260709180636_b.sql"]},
        )

    def test_find_duplicate_versions_ignores_malformed(self):
        self.assertEqual(vmd.find_duplicate_versions(["bad.sql", "also_bad.sql"]), {})

    def test_find_duplicate_versions_empty_when_unique(self):
        names = ["20260709180636_a.sql", "20260709180637_b.sql"]
        self.assertEqual(vmd.find_duplicate_versions(names), {})


class TestListMigrationFiles(unittest.TestCase):
    def test_lists_sorted_sql_files_only(self):
        import tempfile

        with tempfile.TemporaryDirectory() as raw:
            tmp = Path(raw)
            _write(tmp, "20260709180637_b.sql", "20260709180636_a.sql")
            (tmp / "README.md").write_text("ignore", encoding="utf-8")
            self.assertEqual(
                vmd.list_migration_files(tmp),
                ["20260709180636_a.sql", "20260709180637_b.sql"],
            )


class TestLedgerParsing(unittest.TestCase):
    def test_parse_ledger_versions_extracts_version_tokens(self):
        text = (
            "  Local          | Remote         | Time\n"
            "  ---------------|----------------|------\n"
            "  20260709180636 | 20260709180636 | ...\n"
            "  20260309       | 20260309       | ...\n"
            "  noise line without a version\n"
        )
        self.assertEqual(
            vmd.parse_ledger_versions(text), {"20260709180636", "20260309"}
        )

    def test_parse_ledger_versions_empty(self):
        self.assertEqual(vmd.parse_ledger_versions(""), set())

    def test_compare_versions_reports_both_directions(self):
        local = ["20260709180636_a.sql", "20260709180637_b.sql", "bad.sql"]
        remote = {"20260709180637", "20260709180638"}
        local_only, remote_only = vmd.compare_versions(local, remote)
        self.assertEqual(local_only, ["20260709180636"])
        self.assertEqual(remote_only, ["20260709180638"])


class TestSupabaseCli(unittest.TestCase):
    def test_run_returns_stdout_on_success(self):
        completed = type("P", (), {"returncode": 0, "stdout": "rows", "stderr": ""})()
        with patch("verify_migration_drift.subprocess.run", return_value=completed):
            self.assertEqual(vmd.run_supabase_migration_list(), "rows")

    def test_run_raises_on_failure(self):
        completed = type("P", (), {"returncode": 1, "stdout": "", "stderr": "boom"})()
        with patch("verify_migration_drift.subprocess.run", return_value=completed):
            with self.assertRaises(RuntimeError) as ctx:
                vmd.run_supabase_migration_list()
            self.assertIn("boom", str(ctx.exception))

    def test_run_raises_with_default_message_when_stderr_empty(self):
        completed = type("P", (), {"returncode": 1, "stdout": "", "stderr": ""})()
        with patch("verify_migration_drift.subprocess.run", return_value=completed):
            with self.assertRaises(RuntimeError) as ctx:
                vmd.run_supabase_migration_list()
            self.assertIn("failed", str(ctx.exception))


class TestCheck(unittest.TestCase):
    def _dir(self, *names):
        import tempfile

        raw = tempfile.mkdtemp()
        self.addCleanup(__import__("shutil").rmtree, raw)
        return _write(Path(raw), *names)

    def test_offline_clean(self):
        tmp = self._dir("20260709180636_a.sql", "20260709180637_b.sql")
        self.assertEqual(vmd.check(tmp), [])

    def test_offline_flags_malformed_and_duplicates(self):
        tmp = self._dir(
            "20260709180636_a.sql", "20260709180636_b.sql", "bad.sql"
        )
        problems = vmd.check(tmp)
        self.assertTrue(any("malformed" in p for p in problems))
        self.assertTrue(any("duplicate version" in p for p in problems))

    def test_online_clean_when_parity(self):
        tmp = self._dir("20260709180636_a.sql")
        with patch.object(
            vmd, "run_supabase_migration_list", return_value="20260709180636"
        ):
            self.assertEqual(vmd.check(tmp, online=True), [])

    def test_online_flags_missing_and_extra(self):
        tmp = self._dir("20260709180636_a.sql")
        with patch.object(
            vmd, "run_supabase_migration_list", return_value="20260709180699"
        ):
            problems = vmd.check(tmp, online=True)
            self.assertTrue(any("never applied to prod" in p for p in problems))
            self.assertTrue(any("missing from repo" in p for p in problems))

    def test_online_reports_cli_failure(self):
        tmp = self._dir("20260709180636_a.sql")
        with patch.object(
            vmd, "run_supabase_migration_list", side_effect=RuntimeError("no token")
        ):
            problems = vmd.check(tmp, online=True)
            self.assertTrue(any("online ledger check failed" in p for p in problems))

    def test_online_reports_missing_cli(self):
        tmp = self._dir("20260709180636_a.sql")
        with patch.object(
            vmd, "run_supabase_migration_list", side_effect=FileNotFoundError("supabase")
        ):
            problems = vmd.check(tmp, online=True)
            self.assertTrue(any("online ledger check failed" in p for p in problems))


class TestMain(unittest.TestCase):
    def _dir(self, *names):
        import tempfile

        raw = tempfile.mkdtemp()
        self.addCleanup(__import__("shutil").rmtree, raw)
        return _write(Path(raw), *names)

    def test_main_clean_returns_zero(self):
        tmp = self._dir("20260709180636_a.sql")
        out = StringIO()
        with patch("sys.stdout", out):
            code = vmd.main(["--dir", str(tmp)])
        self.assertEqual(code, 0)
        self.assertIn("OK", out.getvalue())

    def test_main_problems_return_one(self):
        tmp = self._dir("bad.sql")
        out = StringIO()
        with patch("sys.stdout", out):
            code = vmd.main(["--dir", str(tmp)])
        self.assertEqual(code, 1)
        self.assertIn("FAILED", out.getvalue())

    def test_main_online_flag_reports_parity_scope(self):
        tmp = self._dir("20260709180636_a.sql")
        out = StringIO()
        with patch.object(
            vmd, "run_supabase_migration_list", return_value="20260709180636"
        ):
            with patch("sys.stdout", out):
                code = vmd.main(["--dir", str(tmp), "--online"])
        self.assertEqual(code, 0)
        self.assertIn("prod parity", out.getvalue())


if __name__ == "__main__":
    unittest.main()
