#!/usr/bin/env python3
"""
verify_rules.py ve yardimci modulleri icin unit testler.

Calistirma:
  python scripts/test_verify_rules.py
  python -m pytest scripts/test_verify_rules.py -v
"""

import json
import re
import runpy
import sys
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

# Script dizinini path'e ekle
SCRIPTS_DIR = Path(__file__).resolve().parent
sys.path.insert(0, str(SCRIPTS_DIR))

from _rules_collectors import (
    collect_data_layer,
    collect_repos_and_remotes,
    collect_source_file_count,
    collect_test_counts,
    collect_widgets,
    count_files_recursive,
    count_json_leaf_keys,
    count_json_top_keys,
    count_route_consts,
    count_string_consts,
    extract_first_number,
    get_schema_version,
)
from _rules_fixers import _apply_inline_fixes, _fix_file, build_fix_updates, fix_claude_md
from verify_rules import check, parse_claude_md_stats


# ── Helpers ──────────────────────────────────────────────────────────────────


def _make_sample_actual(overrides=None) -> dict:
    base = {
        "models": 21,
        "enums": 12,
        "tables": 20,
        "daos": 20,
        "mappers": 20,
        "repos": 20,
        "remotes": 20,
        "features": 20,
        "services": 14,
        "icons": 82,
        "svg_files": 82,
        "routes": 60,
        "schema": 17,
        "tr_keys": 1954,
        "categories": 35,
        "supa": 94,
        "widgets_total": 19,
        "widgets_root": 14,
        "widgets_buttons": 2,
        "widgets_cards": 2,
        "widgets_dialogs": 1,
        "test_files": 680,
        "individual_tests": 7974,
        "source_files": 717,
    }
    if overrides:
        base.update(overrides)
    return base


def _make_claude_md_content(
    test_files=680,
    individual_tests=7974,
    source_files=717,
    widgets_total=19,
    widgets_root=14,
    tr_keys=1954,
    schema=17,
) -> str:
    return f"""\
# CLAUDE.md

## Codebase Stats

| Metric | Value |
| --- | --- |
| Source files (lib/) | {source_files} Dart files |
| Test files (test/) | {test_files} test files, {individual_tests:,}+ individual tests |
| Feature modules | 20 |
| Drift tables / DAOs / Mappers | 20 each |
| Repositories | 20 entity + base + sync_metadata |
| Remote sources | 20 entity + base + 2 caches + providers |
| Freezed models | 21 model files + statistics_models + supabase_extensions |
| Domain services | 14 directories |
| Routes | 60 |
| Custom SVG icons | 82 constants, 82 files on disk |
| Shared widgets | {widgets_total} ({widgets_root} root + 2 buttons + 2 cards + 1 dialog) |
| Enum files | 12 |
| Supabase constants | 94 (tables + buckets + columns) |
| L10n keys | ~{tr_keys:,} per language, 35 categories |
| DB schema version | {schema} |

## Key File Locations

```
Shared UI:    lib/core/widgets/               ({widgets_total} widgets: {widgets_root} root + 2 buttons + 2 cards + 1 dialog)
Translations: assets/translations/            (~{tr_keys:,} leaf keys per language, 35 categories)
Database:     schemaVersion {schema} (switch-based migration, 30+ perf indexes)
```
"""


# ── extract_first_number ──────────────────────────────────────────────────────


class TestExtractFirstNumber(unittest.TestCase):
    def test_plain_integer(self):
        self.assertEqual(extract_first_number("42"), 42)

    def test_with_tilde_prefix(self):
        self.assertEqual(extract_first_number("~1,941"), 1941)

    def test_with_trailing_text(self):
        self.assertEqual(extract_first_number("680 test files, 7,974+ individual tests"), 680)

    def test_with_plus_suffix(self):
        self.assertEqual(extract_first_number("7,974+"), 7974)

    def test_empty_string(self):
        self.assertIsNone(extract_first_number(""))

    def test_no_digits(self):
        self.assertIsNone(extract_first_number("no numbers here"))


# ── count_json_leaf_keys ──────────────────────────────────────────────────────


class TestCountJsonLeafKeys(unittest.TestCase):
    def _write_json(self, data: dict) -> Path:
        tmp = tempfile.NamedTemporaryFile(
            mode="w", suffix=".json", delete=False, encoding="utf-8"
        )
        json.dump(data, tmp)
        tmp.close()
        return Path(tmp.name)

    def test_flat_object(self):
        p = self._write_json({"a": "1", "b": "2", "c": "3"})
        self.assertEqual(count_json_leaf_keys(p), 3)

    def test_nested_object(self):
        p = self._write_json({"outer": {"inner1": "v1", "inner2": "v2"}})
        self.assertEqual(count_json_leaf_keys(p), 2)

    def test_deeply_nested(self):
        p = self._write_json({"a": {"b": {"c": "leaf"}}})
        self.assertEqual(count_json_leaf_keys(p), 1)

    def test_mixed_depth(self):
        p = self._write_json({"top": "val", "nested": {"k1": "v1", "k2": "v2"}})
        self.assertEqual(count_json_leaf_keys(p), 3)

    def test_missing_file(self):
        self.assertEqual(count_json_leaf_keys(Path("/nonexistent/file.json")), 0)


# ── parse_claude_md_stats ─────────────────────────────────────────────────────


class TestParseClaudeMdStats(unittest.TestCase):
    def _write_claude_md(self, content: str) -> Path:
        tmp = tempfile.NamedTemporaryFile(
            mode="w", suffix=".md", delete=False, encoding="utf-8"
        )
        tmp.write(content)
        tmp.close()
        return Path(tmp.name)

    def test_parses_table_correctly(self):
        content = _make_claude_md_content()
        p = self._write_claude_md(content)
        import verify_rules as vr

        original = vr.CLAUDE_MD
        vr.CLAUDE_MD = p
        try:
            stats = parse_claude_md_stats()
        finally:
            vr.CLAUDE_MD = original

        self.assertEqual(stats.get("Feature modules"), "20")
        self.assertEqual(stats.get("Routes"), "60")
        self.assertEqual(stats.get("DB schema version"), "17")

    def test_returns_empty_when_no_table(self):
        p = self._write_claude_md("# No table here\nJust text.\n")
        import verify_rules as vr

        original = vr.CLAUDE_MD
        vr.CLAUDE_MD = p
        try:
            stats = parse_claude_md_stats()
        finally:
            vr.CLAUDE_MD = original

        self.assertEqual(stats, {})

    def test_parses_l10n_value_preserves_tilde_format(self):
        """~N,NNN per language, N categories formatini dogru parse etmeli."""
        content = _make_claude_md_content(tr_keys=1954)
        p = self._write_claude_md(content)
        import verify_rules as vr

        original = vr.CLAUDE_MD
        vr.CLAUDE_MD = p
        try:
            stats = parse_claude_md_stats()
        finally:
            vr.CLAUDE_MD = original

        l10n_val = stats.get("L10n keys", "")
        self.assertTrue(l10n_val.startswith("~"), f"L10n degeri '~' ile baslamali: {l10n_val!r}")
        self.assertIn("35 categories", l10n_val)

    def test_parses_test_files_complex_format(self):
        """'NNN test files, N,NNN+ individual tests' formatini dogru parse etmeli."""
        content = _make_claude_md_content(test_files=680, individual_tests=7974)
        p = self._write_claude_md(content)
        import verify_rules as vr

        original = vr.CLAUDE_MD
        vr.CLAUDE_MD = p
        try:
            stats = parse_claude_md_stats()
        finally:
            vr.CLAUDE_MD = original

        test_val = stats.get("Test files (test/)", "")
        self.assertIn("680", test_val)
        self.assertIn("7,974", test_val)

    def test_table_stops_at_section_boundary(self):
        """Tablo bittikten sonra ek bolum satirlari parse edilmemeli."""
        content = _make_claude_md_content()
        content += "\n## Another Section\n\n| Metric | Value |\n| --- | --- |\n| Extra | 99 |\n"
        p = self._write_claude_md(content)
        import verify_rules as vr

        original = vr.CLAUDE_MD
        vr.CLAUDE_MD = p
        try:
            stats = parse_claude_md_stats()
        finally:
            vr.CLAUDE_MD = original

        self.assertNotIn("Extra", stats)


# ── check() ──────────────────────────────────────────────────────────────────


class TestCheckFunction(unittest.TestCase):
    def test_exact_match_passes(self):
        self.assertTrue(check("test", 10, 10))

    def test_mismatch_fails(self):
        self.assertFalse(check("test", 10, 11))

    def test_within_tolerance_passes(self):
        self.assertTrue(check("test", 100, 105, tolerance=5))

    def test_exceeds_tolerance_fails(self):
        self.assertFalse(check("test", 100, 106, tolerance=5))

    def test_zero_tolerance_exact_only(self):
        self.assertTrue(check("test", 50, 50, tolerance=0))
        self.assertFalse(check("test", 50, 51, tolerance=0))


# ── build_fix_updates ─────────────────────────────────────────────────────────


class TestBuildFixUpdates(unittest.TestCase):
    def test_all_keys_present(self):
        actual = _make_sample_actual()
        updates = build_fix_updates(actual)
        expected_keys = {
            "Freezed models",
            "Enum files",
            "Drift tables / DAOs / Mappers",
            "Repositories",
            "Remote sources",
            "Feature modules",
            "Domain services",
            "Custom SVG icons",
            "Routes",
            "DB schema version",
            "L10n keys",
            "Supabase constants",
            "Shared widgets",
            "Source files (lib/)",
            "Test files (test/)",
        }
        self.assertEqual(set(updates.keys()), expected_keys)

    def test_shared_widgets_format(self):
        actual = _make_sample_actual()
        updates = build_fix_updates(actual)
        self.assertEqual(updates["Shared widgets"], "19 (14 root + 2 buttons + 2 cards + 1 dialog)")

    def test_test_files_format(self):
        actual = _make_sample_actual()
        updates = build_fix_updates(actual)
        self.assertEqual(updates["Test files (test/)"], "680 test files, 7,974+ individual tests")

    def test_l10n_format(self):
        actual = _make_sample_actual()
        updates = build_fix_updates(actual)
        self.assertEqual(updates["L10n keys"], "~1,954 per language, 35 categories")


# ── fix_claude_md ─────────────────────────────────────────────────────────────


class TestFixClaudeMd(unittest.TestCase):
    def _run_fix(self, content: str, actual: dict) -> str:
        """_fix_file'i gecici dosyada calistir, guncellenmis icerigi dondur."""
        tmp = tempfile.NamedTemporaryFile(
            mode="w", suffix=".md", delete=False, encoding="utf-8"
        )
        tmp.write(content)
        tmp.close()
        p = Path(tmp.name)
        updates = build_fix_updates(actual)
        _fix_file(p, updates, actual)
        return p.read_text(encoding="utf-8")

    def test_fixes_stale_widget_count_in_table(self):
        content = _make_claude_md_content(widgets_total=18, widgets_root=13)
        actual = _make_sample_actual()
        result = self._run_fix(content, actual)
        self.assertIn("19 (14 root + 2 buttons + 2 cards + 1 dialog)", result)
        self.assertNotIn("18 (13 root", result)

    def test_fixes_stale_widget_count_inline(self):
        content = _make_claude_md_content(widgets_total=18, widgets_root=13)
        actual = _make_sample_actual()
        result = self._run_fix(content, actual)
        self.assertIn("(19 widgets: 14 root + 2 buttons + 2 cards + 1 dialog)", result)

    def test_fixes_stale_l10n_key_count(self):
        content = _make_claude_md_content(tr_keys=1941)
        actual = _make_sample_actual()
        result = self._run_fix(content, actual)
        self.assertIn("~1,954 per language", result)
        self.assertNotIn("~1,941", result)

    def test_fixes_stale_l10n_inline_leaf_keys(self):
        content = _make_claude_md_content(tr_keys=1941)
        actual = _make_sample_actual()
        result = self._run_fix(content, actual)
        self.assertIn("~1,954 leaf keys per language", result)

    def test_fixes_stale_schema_version_inline(self):
        content = _make_claude_md_content(schema=16)
        actual = _make_sample_actual()
        result = self._run_fix(content, actual)
        self.assertIn("schemaVersion 17", result)
        self.assertNotIn("schemaVersion 16", result)

    def test_fixes_stale_test_count(self):
        content = _make_claude_md_content(test_files=656, individual_tests=7700)
        actual = _make_sample_actual()
        result = self._run_fix(content, actual)
        self.assertIn("680 test files, 7,974+ individual tests", result)

    def test_no_change_when_already_current(self):
        actual = _make_sample_actual()
        content = _make_claude_md_content()  # already uses current values
        result = self._run_fix(content, actual)
        # Content should not change (modulo trailing newline normalisation)
        self.assertEqual(content.strip(), result.strip())

    def test_fix_file_skips_table_row_with_extra_columns(self):
        """3 sutunlu tablo satiri (len != 2) → continue (satir 106) calisir.

        'Metric' ve '---' satirlari 102. satirda filtrelenir; bu test
        dogrudan 3-sutunlu bir data satiri kullanarak 105-106. satirlara ulasir.
        """
        # "Metric"/"---" icermeyen, 3 sutunlu bir satir → len(parts)==3 → continue
        content = "| Foo | Bar | Baz |\n"
        actual = _make_sample_actual()
        updates = build_fix_updates(actual)
        with tempfile.NamedTemporaryFile(
            mode="w", suffix=".md", delete=False, encoding="utf-8"
        ) as tmp:
            tmp.write(content)
            p = Path(tmp.name)
        changed = _fix_file(p, updates, actual)
        self.assertFalse(changed)

    def test_fix_claude_md_updates_both_files_when_rules_exists(self):
        """RULES_CLAUDE_MD mevcutsa her iki dosya da guncellenir (satir 136, 140-141).

        any() kisa devre yapilmadi — acik dongu her dosyayi gunceller.
        """
        import _rules_fixers as rf

        actual = _make_sample_actual({"tr_keys": 999, "categories": 35})
        stale = _make_claude_md_content(tr_keys=1)  # her iki dosya bayatlamis
        updates = build_fix_updates(actual)
        with tempfile.TemporaryDirectory() as d:
            root = Path(d)
            main_md = root / "CLAUDE.md"
            rules_md = root / ".claude" / "rules" / "CLAUDE.md"
            rules_md.parent.mkdir(parents=True)
            main_md.write_text(stale, encoding="utf-8")
            rules_md.write_text(stale, encoding="utf-8")
            with patch.object(rf, "CLAUDE_MD", main_md), \
                 patch.object(rf, "RULES_CLAUDE_MD", rules_md), \
                 patch.object(rf, "ROOT", root):
                fix_claude_md(updates, actual)
            # Her iki dosya da yeni tr_keys degerini icermeli
            self.assertIn("~999", main_md.read_text(encoding="utf-8"))
            self.assertIn("~999", rules_md.read_text(encoding="utf-8"))

    def test_fix_claude_md_no_change_message_when_already_current(self):
        """Dosyalar zaten guncel → 'zaten guncel' yolu (satir 142-143) calisir."""
        import _rules_fixers as rf

        actual = _make_sample_actual()
        current = _make_claude_md_content()  # zaten guncel
        updates = build_fix_updates(actual)
        with tempfile.TemporaryDirectory() as d:
            root = Path(d)
            main_md = root / "CLAUDE.md"
            main_md.write_text(current, encoding="utf-8")
            # RULES_CLAUDE_MD yok (sadece ana dosya)
            rules_md = root / ".claude" / "rules" / "CLAUDE.md"
            with patch.object(rf, "CLAUDE_MD", main_md), \
                 patch.object(rf, "RULES_CLAUDE_MD", rules_md), \
                 patch.object(rf, "ROOT", root):
                fix_claude_md(updates, actual)
            # Dosya degismemeli
            self.assertEqual(current.strip(), main_md.read_text(encoding="utf-8").strip())


# ── _apply_inline_fixes (inline drift detection) ─────────────────────────────


class TestApplyInlineFixes(unittest.TestCase):
    def test_no_drift_returns_unchanged_content(self):
        actual = _make_sample_actual()
        content = _make_claude_md_content()  # all values current
        fixed, messages = _apply_inline_fixes(content, actual)
        self.assertEqual(fixed, content)
        self.assertEqual(messages, [])

    def test_stale_widget_count_detected(self):
        actual = _make_sample_actual()
        content = _make_claude_md_content(widgets_total=18, widgets_root=13)
        fixed, messages = _apply_inline_fixes(content, actual)
        self.assertNotEqual(fixed, content)
        self.assertTrue(any("widget" in m.lower() for m in messages))

    def test_stale_l10n_leaf_keys_detected(self):
        actual = _make_sample_actual()
        content = _make_claude_md_content(tr_keys=1941)
        fixed, messages = _apply_inline_fixes(content, actual)
        self.assertNotEqual(fixed, content)
        self.assertTrue(any("l10n" in m.lower() or "key" in m.lower() for m in messages))

    def test_stale_schema_version_detected(self):
        actual = _make_sample_actual()
        content = _make_claude_md_content(schema=16)
        fixed, messages = _apply_inline_fixes(content, actual)
        self.assertNotEqual(fixed, content)
        self.assertTrue(any("schema" in m.lower() for m in messages))

    def test_multiple_stale_values_all_reported(self):
        actual = _make_sample_actual()
        content = _make_claude_md_content(widgets_total=18, widgets_root=13, tr_keys=1941, schema=16)
        fixed, messages = _apply_inline_fixes(content, actual)
        self.assertGreaterEqual(len(messages), 3)

    def test_fixed_content_contains_new_values(self):
        actual = _make_sample_actual()
        content = _make_claude_md_content(widgets_total=18, widgets_root=13)
        fixed, _ = _apply_inline_fixes(content, actual)
        self.assertIn("(19 widgets: 14 root + 2 buttons + 2 cards + 1 dialog)", fixed)
        self.assertNotIn("(18 widgets: 13 root", fixed)

    def test_l10n_without_leaf_keyword_updated(self):
        """'~X keys per language' (leaf olmadan) guncellenir — satir 46 (_replace_l10n)."""
        actual = _make_sample_actual({"tr_keys": 1954})
        # "leaf" kelimesi olmayan inline referans
        content = "See ~100 keys per language for details.\n"
        fixed, messages = _apply_inline_fixes(content, actual)
        self.assertIn("~1,954 keys per language", fixed)
        self.assertNotIn("~100", fixed)
        self.assertTrue(any("l10n" in m.lower() or "key" in m.lower() for m in messages))


# ── Collector helpers ─────────────────────────────────────────────────────────


class TestCollectDataLayer(unittest.TestCase):
    def _make_lib(self, tmpdir: Path):
        """lib/ icerisinde test dosyalari olustur."""
        (tmpdir / "data" / "models").mkdir(parents=True)
        (tmpdir / "core" / "enums").mkdir(parents=True)
        (tmpdir / "data" / "local" / "database" / "tables").mkdir(parents=True)
        (tmpdir / "data" / "local" / "database" / "daos").mkdir(parents=True)
        (tmpdir / "data" / "local" / "database" / "mappers").mkdir(parents=True)
        return tmpdir

    def test_counts_model_files(self):
        with tempfile.TemporaryDirectory() as d:
            lib = self._make_lib(Path(d))
            (lib / "data" / "models" / "bird_model.dart").touch()
            (lib / "data" / "models" / "egg_model.dart").touch()
            result = collect_data_layer(lib)
            self.assertEqual(result["models"], 2)

    def test_counts_enum_files(self):
        with tempfile.TemporaryDirectory() as d:
            lib = self._make_lib(Path(d))
            (lib / "core" / "enums" / "bird_enums.dart").touch()
            result = collect_data_layer(lib)
            self.assertEqual(result["enums"], 1)

    def test_counts_tables_daos_mappers(self):
        with tempfile.TemporaryDirectory() as d:
            lib = self._make_lib(Path(d))
            (lib / "data" / "local" / "database" / "tables" / "birds_table.dart").touch()
            (lib / "data" / "local" / "database" / "daos" / "birds_dao.dart").touch()
            (lib / "data" / "local" / "database" / "mappers" / "bird_mapper.dart").touch()
            result = collect_data_layer(lib)
            self.assertEqual(result["tables"], 1)
            self.assertEqual(result["daos"], 1)
            self.assertEqual(result["mappers"], 1)

    def test_returns_zeros_for_empty_dirs(self):
        with tempfile.TemporaryDirectory() as d:
            lib = self._make_lib(Path(d))
            result = collect_data_layer(lib)
            self.assertEqual(result["models"], 0)
            self.assertEqual(result["enums"], 0)


class TestCollectReposAndRemotes(unittest.TestCase):
    def test_counts_entity_repos_excludes_base(self):
        with tempfile.TemporaryDirectory() as d:
            lib = Path(d)
            repo_dir = lib / "data" / "repositories"
            repo_dir.mkdir(parents=True)
            (repo_dir / "bird_repository.dart").touch()
            (repo_dir / "egg_repository.dart").touch()
            (repo_dir / "base_repository.dart").touch()  # excluded
            result = collect_repos_and_remotes(lib)
            self.assertEqual(result["repos"], 2)

    def test_counts_entity_remotes_excludes_base(self):
        with tempfile.TemporaryDirectory() as d:
            lib = Path(d)
            remote_dir = lib / "data" / "remote" / "api"
            remote_dir.mkdir(parents=True)
            (remote_dir / "bird_remote_source.dart").touch()
            (remote_dir / "base_remote_source.dart").touch()  # excluded
            result = collect_repos_and_remotes(lib)
            self.assertEqual(result["remotes"], 1)

    def test_returns_zeros_when_dirs_missing(self):
        with tempfile.TemporaryDirectory() as d:
            result = collect_repos_and_remotes(Path(d))
            self.assertEqual(result["repos"], 0)
            self.assertEqual(result["remotes"], 0)


class TestCollectWidgets(unittest.TestCase):
    def _make_widgets_dir(self, tmpdir: Path):
        w = tmpdir / "core" / "widgets"
        (w / "buttons").mkdir(parents=True)
        (w / "cards").mkdir(parents=True)
        (w / "dialogs").mkdir(parents=True)
        return w

    def test_counts_root_and_subdir_widgets(self):
        with tempfile.TemporaryDirectory() as d:
            lib = Path(d)
            w = self._make_widgets_dir(lib)
            (w / "empty_state.dart").touch()
            (w / "loading_state.dart").touch()
            (w / "buttons" / "primary_button.dart").touch()
            result = collect_widgets(lib)
            self.assertEqual(result["widgets_root"], 2)
            self.assertEqual(result["widgets_buttons"], 1)
            self.assertEqual(result["widgets_total"], 3)

    def test_counts_cards_and_dialogs(self):
        with tempfile.TemporaryDirectory() as d:
            lib = Path(d)
            w = self._make_widgets_dir(lib)
            (w / "cards" / "stat_card.dart").touch()
            (w / "cards" / "info_card.dart").touch()
            (w / "dialogs" / "confirm_dialog.dart").touch()
            result = collect_widgets(lib)
            self.assertEqual(result["widgets_cards"], 2)
            self.assertEqual(result["widgets_dialogs"], 1)

    def test_returns_zeros_when_no_widgets_dir(self):
        with tempfile.TemporaryDirectory() as d:
            result = collect_widgets(Path(d))
            self.assertEqual(result["widgets_total"], 0)


class TestCollectTestCounts(unittest.TestCase):
    def test_counts_test_files_and_individual_tests(self):
        with tempfile.TemporaryDirectory() as d:
            root = Path(d)
            test_dir = root / "test"
            test_dir.mkdir()
            (test_dir / "bird_test.dart").write_text(
                "test('creates bird', () {});\ntestWidgets('shows list', (t) {});\n",
                encoding="utf-8",
            )
            result = collect_test_counts(root)
            self.assertEqual(result["test_files"], 1)
            self.assertEqual(result["individual_tests"], 2)

    def test_counts_multiple_test_files(self):
        with tempfile.TemporaryDirectory() as d:
            root = Path(d)
            test_dir = root / "test"
            test_dir.mkdir()
            for name in ("a_test.dart", "b_test.dart"):
                (test_dir / name).write_text("test('x', () {});\n", encoding="utf-8")
            result = collect_test_counts(root)
            self.assertEqual(result["test_files"], 2)
            self.assertEqual(result["individual_tests"], 2)

    def test_returns_zeros_when_no_test_dir(self):
        with tempfile.TemporaryDirectory() as d:
            result = collect_test_counts(Path(d))
            self.assertEqual(result["test_files"], 0)
            self.assertEqual(result["individual_tests"], 0)


class TestCollectSourceFileCount(unittest.TestCase):
    def test_counts_dart_files(self):
        with tempfile.TemporaryDirectory() as d:
            lib = Path(d)
            (lib / "app.dart").touch()
            (lib / "main.dart").touch()
            self.assertEqual(collect_source_file_count(lib), 2)

    def test_excludes_generated_files(self):
        with tempfile.TemporaryDirectory() as d:
            lib = Path(d)
            (lib / "app.dart").touch()
            (lib / "bird_model.g.dart").touch()
            (lib / "bird_model.freezed.dart").touch()
            self.assertEqual(collect_source_file_count(lib), 1)

    def test_returns_zero_when_dir_missing(self):
        self.assertEqual(collect_source_file_count(Path("/nonexistent/lib")), 0)


# ── Scalar collector helpers ──────────────────────────────────────────────────


class TestCountFilesRecursive(unittest.TestCase):
    def test_counts_svg_files_recursively(self):
        with tempfile.TemporaryDirectory() as d:
            root = Path(d)
            sub = root / "navigation"
            sub.mkdir()
            (sub / "bird.svg").touch()
            (root / "home.svg").touch()
            self.assertEqual(count_files_recursive(root, "*.svg"), 2)

    def test_returns_zero_when_dir_missing(self):
        self.assertEqual(count_files_recursive(Path("/nonexistent"), "*.svg"), 0)

    def test_different_pattern(self):
        with tempfile.TemporaryDirectory() as d:
            root = Path(d)
            (root / "file.png").touch()
            (root / "file.svg").touch()
            self.assertEqual(count_files_recursive(root, "*.png"), 1)


class TestCountJsonTopKeys(unittest.TestCase):
    def test_counts_top_level_keys(self):
        with tempfile.NamedTemporaryFile(
            mode="w", suffix=".json", delete=False, encoding="utf-8"
        ) as tmp:
            json.dump({"common": {}, "birds": {}, "eggs": {}}, tmp)
            p = Path(tmp.name)
        self.assertEqual(count_json_top_keys(p), 3)

    def test_returns_zero_when_file_missing(self):
        self.assertEqual(count_json_top_keys(Path("/nonexistent/tr.json")), 0)

    def test_empty_object_returns_zero(self):
        with tempfile.NamedTemporaryFile(
            mode="w", suffix=".json", delete=False, encoding="utf-8"
        ) as tmp:
            json.dump({}, tmp)
            p = Path(tmp.name)
        self.assertEqual(count_json_top_keys(p), 0)


class TestCountStringConsts(unittest.TestCase):
    def test_counts_static_const_declarations(self):
        with tempfile.NamedTemporaryFile(
            mode="w", suffix=".dart", delete=False, encoding="utf-8"
        ) as tmp:
            tmp.write("static const String foo = 'foo';\nstatic const String bar = 'bar';\n")
            p = Path(tmp.name)
        self.assertEqual(count_string_consts(p), 2)

    def test_returns_zero_when_file_missing(self):
        self.assertEqual(count_string_consts(Path("/nonexistent/app_icons.dart")), 0)

    def test_returns_zero_when_no_consts(self):
        with tempfile.NamedTemporaryFile(
            mode="w", suffix=".dart", delete=False, encoding="utf-8"
        ) as tmp:
            tmp.write("class Foo {}\n")
            p = Path(tmp.name)
        self.assertEqual(count_string_consts(p), 0)


class TestCountRouteConsts(unittest.TestCase):
    def test_counts_route_path_constants(self):
        with tempfile.NamedTemporaryFile(
            mode="w", suffix=".dart", delete=False, encoding="utf-8"
        ) as tmp:
            tmp.write(
                "static const birds = '/birds';\n"
                "static const birdDetail = '/birds/:id';\n"
                "static const String name = 'notARoute';\n"
            )
            p = Path(tmp.name)
        self.assertEqual(count_route_consts(p), 2)

    def test_returns_zero_when_file_missing(self):
        self.assertEqual(count_route_consts(Path("/nonexistent/route_names.dart")), 0)

    def test_returns_zero_when_no_route_consts(self):
        with tempfile.NamedTemporaryFile(
            mode="w", suffix=".dart", delete=False, encoding="utf-8"
        ) as tmp:
            tmp.write("static const String name = 'not-a-route';\n")
            p = Path(tmp.name)
        self.assertEqual(count_route_consts(p), 0)


class TestGetSchemaVersion(unittest.TestCase):
    def test_extracts_schema_version(self):
        with tempfile.NamedTemporaryFile(
            mode="w", suffix=".dart", delete=False, encoding="utf-8"
        ) as tmp:
            tmp.write("int get schemaVersion => 17;\n")
            p = Path(tmp.name)
        self.assertEqual(get_schema_version(p), 17)

    def test_returns_zero_when_file_missing(self):
        self.assertEqual(get_schema_version(Path("/nonexistent/app_database.dart")), 0)

    def test_returns_zero_when_no_match(self):
        with tempfile.NamedTemporaryFile(
            mode="w", suffix=".dart", delete=False, encoding="utf-8"
        ) as tmp:
            tmp.write("class AppDatabase {}\n")
            p = Path(tmp.name)
        self.assertEqual(get_schema_version(p), 0)

    def test_extracts_multi_digit_version(self):
        with tempfile.NamedTemporaryFile(
            mode="w", suffix=".dart", delete=False, encoding="utf-8"
        ) as tmp:
            tmp.write("@override\nint get schemaVersion => 123;\n")
            p = Path(tmp.name)
        self.assertEqual(get_schema_version(p), 123)


# ── _file_label ───────────────────────────────────────────────────────────────


class TestFileLabel(unittest.TestCase):
    def setUp(self):
        from _rules_fixers import _file_label, ROOT as FX_ROOT
        self._label = _file_label
        self._root = FX_ROOT

    def test_root_claude_md(self):
        p = self._root / "CLAUDE.md"
        self.assertEqual(self._label(p), "CLAUDE.md (root)")

    def test_rules_claude_md(self):
        p = self._root / ".claude" / "rules" / "CLAUDE.md"
        self.assertEqual(self._label(p), "CLAUDE.md (rules)")

    def test_other_file(self):
        p = self._root / "scripts" / "verify_rules.py"
        self.assertEqual(self._label(p), "verify_rules.py")


# ── collect_actual_values() integration ──────────────────────────────────────


class TestCollectActualValues(unittest.TestCase):
    """collect_actual_values() gercek dosya yapisi ile entegrasyon testleri."""

    def _minimal_root(self, root: Path) -> None:
        """collect_actual_values() icin minimum dosya yapisi olustur."""
        (root / "lib").mkdir(exist_ok=True)
        (root / "assets" / "translations").mkdir(parents=True, exist_ok=True)
        (root / "assets" / "icons").mkdir(parents=True, exist_ok=True)
        (root / "assets" / "translations" / "tr.json").write_text(
            '{}', encoding="utf-8"
        )

    def test_returns_all_expected_keys(self):
        import _rules_collectors as rc

        with tempfile.TemporaryDirectory() as d:
            root = Path(d)
            self._minimal_root(root)
            with patch.object(rc, "LIB", root / "lib"), \
                 patch.object(rc, "ASSETS", root / "assets"), \
                 patch.object(rc, "ROOT", root):
                result = rc.collect_actual_values()

        expected = {
            "models", "enums", "tables", "daos", "mappers",
            "repos", "remotes", "features", "services",
            "icons", "svg_files", "routes", "schema",
            "tr_keys", "categories", "supa",
            "widgets_total", "widgets_root", "widgets_buttons",
            "widgets_cards", "widgets_dialogs",
            "test_files", "individual_tests", "source_files",
        }
        self.assertTrue(expected.issubset(set(result.keys())))

    def test_counts_feature_dirs(self):
        import _rules_collectors as rc

        with tempfile.TemporaryDirectory() as d:
            root = Path(d)
            self._minimal_root(root)
            (root / "lib" / "features" / "birds").mkdir(parents=True)
            (root / "lib" / "features" / "eggs").mkdir(parents=True)
            with patch.object(rc, "LIB", root / "lib"), \
                 patch.object(rc, "ASSETS", root / "assets"), \
                 patch.object(rc, "ROOT", root):
                result = rc.collect_actual_values()

        self.assertEqual(result["features"], 2)

    def test_returns_zeros_for_empty_structure(self):
        import _rules_collectors as rc

        with tempfile.TemporaryDirectory() as d:
            root = Path(d)
            self._minimal_root(root)
            with patch.object(rc, "LIB", root / "lib"), \
                 patch.object(rc, "ASSETS", root / "assets"), \
                 patch.object(rc, "ROOT", root):
                result = rc.collect_actual_values()

        self.assertEqual(result["models"], 0)
        self.assertEqual(result["test_files"], 0)
        self.assertEqual(result["source_files"], 0)
        self.assertEqual(result["features"], 0)

    def test_counts_source_files_excludes_generated(self):
        import _rules_collectors as rc

        with tempfile.TemporaryDirectory() as d:
            root = Path(d)
            self._minimal_root(root)
            lib = root / "lib"
            (lib / "app.dart").touch()
            (lib / "bootstrap.dart").touch()
            (lib / "app_model.g.dart").touch()           # excluded
            (lib / "app_model.freezed.dart").touch()     # excluded
            with patch.object(rc, "LIB", lib), \
                 patch.object(rc, "ASSETS", root / "assets"), \
                 patch.object(rc, "ROOT", root):
                result = rc.collect_actual_values()

        self.assertEqual(result["source_files"], 2)


# ── verify_rules.main() integration ──────────────────────────────────────────


class TestVerifyRulesMain(unittest.TestCase):
    """verify_rules.main() icin entegrasyon testleri."""

    def _make_assets(self, tmpdir: Path, key_count: int = 3) -> Path:
        """Gecici assets/ dizini olustur, 3 dil JSON'u yaz."""
        trans_dir = tmpdir / "translations"
        trans_dir.mkdir(parents=True)
        data = {f"k{i}": f"v{i}" for i in range(key_count)}
        for lang in ("tr", "en", "de"):
            (trans_dir / f"{lang}.json").write_text(
                json.dumps(data), encoding="utf-8"
            )
        return tmpdir

    def _patch_and_run_main(self, tmp_md: Path, assets_dir: Path, root: Path, actual: dict):
        import verify_rules as vr

        with patch.object(vr, "CLAUDE_MD", tmp_md), \
             patch.object(vr, "ASSETS", assets_dir), \
             patch.object(vr, "ROOT", root), \
             patch.object(vr, "collect_actual_values", return_value=actual):
            return vr.main()

    def test_fix_mode_returns_0_and_writes_updates(self):
        """FIX_MODE=True iken satirlar 78-81 calisir: updates hesaplanir, return 0."""
        import verify_rules as vr

        key_count = 3
        actual = _make_sample_actual({"tr_keys": key_count, "categories": 35})
        content = _make_claude_md_content(tr_keys=key_count + 99)  # kasitli uyumsuz
        with tempfile.TemporaryDirectory() as d:
            root = Path(d)
            assets = self._make_assets(root, key_count=key_count)
            tmp_md = root / "CLAUDE.md"
            tmp_md.write_text(content, encoding="utf-8")
            with patch.object(vr, "CLAUDE_MD", tmp_md), \
                 patch.object(vr, "ASSETS", assets), \
                 patch.object(vr, "ROOT", root), \
                 patch.object(vr, "collect_actual_values", return_value=actual), \
                 patch.object(vr, "FIX_MODE", True):
                result = vr.main()
        self.assertEqual(result, 0)

    def test_strict_mode_prints_message(self):
        """STRICT_MODE=True iken satir 94 calisir: 'STRICT modu' mesaji basilir."""
        import io
        import sys as _sys
        import verify_rules as vr

        key_count = 3
        actual = _make_sample_actual({"tr_keys": key_count, "categories": 35})
        content = _make_claude_md_content(tr_keys=key_count)
        with tempfile.TemporaryDirectory() as d:
            root = Path(d)
            assets = self._make_assets(root, key_count=key_count)
            tmp_md = root / "CLAUDE.md"
            tmp_md.write_text(content, encoding="utf-8")
            captured = io.StringIO()
            old = _sys.stdout
            _sys.stdout = captured
            try:
                with patch.object(vr, "CLAUDE_MD", tmp_md), \
                     patch.object(vr, "ASSETS", assets), \
                     patch.object(vr, "ROOT", root), \
                     patch.object(vr, "collect_actual_values", return_value=actual), \
                     patch.object(vr, "STRICT_MODE", True):
                    vr.main()
            finally:
                _sys.stdout = old
        self.assertIn("STRICT", captured.getvalue())

    def test_returns_0_when_all_stats_match(self):
        key_count = 3
        actual = _make_sample_actual({"tr_keys": key_count, "categories": 35})
        content = _make_claude_md_content(
            tr_keys=key_count,
            test_files=actual["test_files"],
            individual_tests=actual["individual_tests"],
            source_files=actual["source_files"],
            widgets_total=actual["widgets_total"],
            widgets_root=actual["widgets_root"],
            schema=actual["schema"],
        )
        with tempfile.TemporaryDirectory() as d:
            root = Path(d)
            assets = self._make_assets(root, key_count=key_count)
            tmp_md = root / "CLAUDE.md"
            tmp_md.write_text(content, encoding="utf-8")
            result = self._patch_and_run_main(tmp_md, assets, root, actual)
        self.assertEqual(result, 0)

    def test_returns_1_when_stats_table_missing(self):
        import verify_rules as vr

        with tempfile.TemporaryDirectory() as d:
            root = Path(d)
            tmp_md = root / "CLAUDE.md"
            tmp_md.write_text("# CLAUDE.md\n\nNo table here.\n", encoding="utf-8")
            with patch.object(vr, "CLAUDE_MD", tmp_md), \
                 patch.object(vr, "ROOT", root):
                result = vr.main()
        self.assertEqual(result, 1)

    def test_returns_1_when_model_count_mismatch(self):
        key_count = 3
        # actual has models=99 but CLAUDE.md says 21 → mismatch exceeds tolerance
        actual = _make_sample_actual({"tr_keys": key_count, "categories": 35, "models": 99})
        content = _make_claude_md_content(
            tr_keys=key_count,
            test_files=actual["test_files"],
            individual_tests=actual["individual_tests"],
            source_files=actual["source_files"],
            widgets_total=actual["widgets_total"],
            widgets_root=actual["widgets_root"],
            schema=actual["schema"],
        )
        with tempfile.TemporaryDirectory() as d:
            root = Path(d)
            assets = self._make_assets(root, key_count=key_count)
            tmp_md = root / "CLAUDE.md"
            tmp_md.write_text(content, encoding="utf-8")
            result = self._patch_and_run_main(tmp_md, assets, root, actual)
        self.assertEqual(result, 1)

    def _make_matching_claude_md(self, key_count: int, extra_inline: str = "") -> str:
        """Stats tablosu gercek degerlerle eslesir, inline bolum ozel metin icerir."""
        base = _make_claude_md_content(
            tr_keys=key_count,
            test_files=680,
            individual_tests=7974,
            source_files=717,
            widgets_total=19,
            widgets_root=14,
            schema=17,
        )
        if extra_inline:
            base += f"\n{extra_inline}\n"
        return base

    def test_inline_drift_warn_path_executed(self):
        """Stale inline L10n count → WARN yolu (satir 157-160) calisir, return 0."""
        key_count = 3
        actual = _make_sample_actual({"tr_keys": key_count, "categories": 35})
        # Stats tablosu eslesir, ancak inline bolum bayatlamis (~999) icerir
        stale_inline = "Translations: assets/translations/ (~999 leaf keys per language)"
        content = self._make_matching_claude_md(key_count, extra_inline=stale_inline)
        with tempfile.TemporaryDirectory() as d:
            root = Path(d)
            assets = self._make_assets(root, key_count=key_count)
            tmp_md = root / "CLAUDE.md"
            tmp_md.write_text(content, encoding="utf-8")
            result = self._patch_and_run_main(tmp_md, assets, root, actual)
        # Inline drift hata sayilmaz → 0
        self.assertEqual(result, 0)

    def _make_rules_dir(self, root: Path) -> Path:
        """root/.claude/rules/ dizinini olustur ve yolunu dondur."""
        rules_dir = root / ".claude" / "rules"
        rules_dir.mkdir(parents=True)
        return rules_dir

    def test_cross_ref_broken_target_file(self):
        """Var olmayan .md hedefi → kirik referans WARN (satir 175-176)."""
        key_count = 3
        actual = _make_sample_actual({"tr_keys": key_count, "categories": 35})
        content = self._make_matching_claude_md(key_count)
        with tempfile.TemporaryDirectory() as d:
            root = Path(d)
            assets = self._make_assets(root, key_count=key_count)
            tmp_md = root / "CLAUDE.md"
            tmp_md.write_text(content, encoding="utf-8")
            rules_dir = self._make_rules_dir(root)
            # source.md references missing.md which does not exist
            (rules_dir / "source.md").write_text(
                '`missing.md` \u2192 "some section"\n', encoding="utf-8"
            )
            result = self._patch_and_run_main(tmp_md, assets, root, actual)
        # broken_refs not counted in fail_count → 0
        self.assertEqual(result, 0)

    def test_cross_ref_section_not_found(self):
        """Target .md var ama bolum bulunamadi → WARN (satir 178-181)."""
        key_count = 3
        actual = _make_sample_actual({"tr_keys": key_count, "categories": 35})
        content = self._make_matching_claude_md(key_count)
        with tempfile.TemporaryDirectory() as d:
            root = Path(d)
            assets = self._make_assets(root, key_count=key_count)
            tmp_md = root / "CLAUDE.md"
            tmp_md.write_text(content, encoding="utf-8")
            rules_dir = self._make_rules_dir(root)
            (rules_dir / "target.md").write_text(
                "# Target\n\nNo matching section here.\n", encoding="utf-8"
            )
            (rules_dir / "source.md").write_text(
                '`target.md` \u2192 "missing section title"\n', encoding="utf-8"
            )
            result = self._patch_and_run_main(tmp_md, assets, root, actual)
        self.assertEqual(result, 0)

    def test_cross_ref_all_valid(self):
        """Tum cross-reference'lar gecerli → PASS mesaji (satir 182-183)."""
        key_count = 3
        actual = _make_sample_actual({"tr_keys": key_count, "categories": 35})
        content = self._make_matching_claude_md(key_count)
        with tempfile.TemporaryDirectory() as d:
            root = Path(d)
            assets = self._make_assets(root, key_count=key_count)
            tmp_md = root / "CLAUDE.md"
            tmp_md.write_text(content, encoding="utf-8")
            rules_dir = self._make_rules_dir(root)
            (rules_dir / "target.md").write_text(
                "# Target\n\n## Correct Section\n\nContent here.\n", encoding="utf-8"
            )
            (rules_dir / "source.md").write_text(
                '`target.md` \u2192 "Correct Section"\n', encoding="utf-8"
            )
            result = self._patch_and_run_main(tmp_md, assets, root, actual)
        self.assertEqual(result, 0)


    def test_inline_drift_includes_rules_claude_when_exists(self):
        """.claude/rules/CLAUDE.md varsa inline_targets'a ekleniyor (satir 149)."""
        import verify_rules as vr

        key_count = 3
        actual = _make_sample_actual({"tr_keys": key_count, "categories": 35})
        content = _make_claude_md_content(tr_keys=key_count)
        with tempfile.TemporaryDirectory() as d:
            root = Path(d)
            assets = self._make_assets(root, key_count=key_count)
            tmp_md = root / "CLAUDE.md"
            tmp_md.write_text(content, encoding="utf-8")
            # .claude/rules/CLAUDE.md olustur → exists() True → satir 149 calisir
            rules_dir = root / ".claude" / "rules"
            rules_dir.mkdir(parents=True)
            rules_claude = rules_dir / "CLAUDE.md"
            rules_claude.write_text(content, encoding="utf-8")
            with patch.object(vr, "CLAUDE_MD", tmp_md), \
                 patch.object(vr, "ASSETS", assets), \
                 patch.object(vr, "ROOT", root), \
                 patch.object(vr, "collect_actual_values", return_value=actual):
                result = vr.main()
        self.assertEqual(result, 0)


# ── Script entrypoint (satir 207) ─────────────────────────────────────────────


class TestVerifyRulesEntrypoint(unittest.TestCase):
    """if __name__ == '__main__': sys.exit(main()) dalini in-process ile kapsar (satir 207)."""

    def test_script_runs_as_main(self):
        """Script __main__ olarak calistirildiginda sys.exit cagrilir (coverage tracked)."""
        import runpy
        script = str(SCRIPTS_DIR / "verify_rules.py")
        with patch.object(sys, "exit"):
            runpy.run_path(script, run_name="__main__")


# ── Runner ────────────────────────────────────────────────────────────────────


if __name__ == "__main__":
    unittest.main(verbosity=2)
