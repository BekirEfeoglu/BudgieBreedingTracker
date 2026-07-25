#!/usr/bin/env python3
"""
verify_rules.py ve yardimci modulleri icin unit testler.

Calistirma:
  python scripts/test_verify_rules.py
  python -m pytest scripts/test_verify_rules.py -v
"""

import io
import json
import re
import runpy
import sys
import tempfile
import unittest
from contextlib import redirect_stdout
from pathlib import Path
from unittest.mock import patch

# Script dizinini path'e ekle
SCRIPTS_DIR = Path(__file__).resolve().parent
sys.path.insert(0, str(SCRIPTS_DIR))

from _rules_collectors import (
    _count_indexes,
    collect_edge_function_surfaces,
    collect_icon_surfaces,
    collect_l10n_category_surfaces,
    collect_quality_checker_counts,
    collect_route_surfaces,
    collect_storage_bucket_surfaces,
    collect_supabase_table_surfaces,
    duplicate_route_values,
    undeclared_columns,
    unprovisioned_tables,
    unresolved_route_targets,
    collect_data_layer,
    collect_repos_and_remotes,
    collect_source_file_count,
    collect_test_counts,
    collect_widgets,
    count_edge_functions,
    count_files_recursive,
    count_json_leaf_keys,
    count_json_top_keys,
    count_route_consts,
    count_string_consts,
    extract_first_number,
    extract_markdown_section,
    extract_release_artifact_paths,
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
        "widgets_bottom_sheet": 0,
        "widgets_eggs": 0,
        "test_files": 680,
        "individual_tests": 7974,
        "source_files": 717,
        "indexes": 34,
        "migrations": 104,
        "edge_functions": 7,
        "quality_covered": 18,
        "quality_extra": 5,
        "quality_total": 23,
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
    migrations=104,
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

### Migrations
{migrations} SQL migration files in `supabase/migrations/`.

## Key File Locations

```
Shared UI:    lib/core/widgets/               ({widgets_total} widgets: {widgets_root} root + 2 buttons + 2 cards + 1 dialog)
Translations: assets/translations/            (~{tr_keys:,} leaf keys per language, 35 categories)
Migrations:   supabase/migrations/ ({migrations} files)
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

    def test_shared_widgets_format_includes_bottom_sheet(self):
        actual = _make_sample_actual({"widgets_total": 20, "widgets_bottom_sheet": 1})
        updates = build_fix_updates(actual)
        self.assertEqual(
            updates["Shared widgets"],
            "20 (14 root + 2 buttons + 2 cards + 1 dialog + 1 bottom_sheet)",
        )

    def test_shared_widgets_format_includes_eggs(self):
        actual = _make_sample_actual({"widgets_total": 24, "widgets_eggs": 5})
        updates = build_fix_updates(actual)
        self.assertEqual(
            updates["Shared widgets"],
            "24 (14 root + 2 buttons + 2 cards + 1 dialog + 5 eggs)",
        )

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

    def test_updates_rule_inventory_counts(self):
        actual = _make_sample_actual({
            "supa": 128,
            "edge_functions": 8,
            "migrations": 144,
            "test_files": 855,
            "individual_tests": 10566,
            "widgets_total": 23,
        })
        content = "\n".join([
            "- **Constants**: `SupabaseConstants` class (110 table/column constants)",
            "- **Edge Functions**: 7 in `supabase/functions/`",
            "- **Migrations**: 125 SQL files in `supabase/migrations/`",
            "- 820 test files, 10,093+ individual tests",
            "## Shared Widgets (20)",
        ])
        fixed, messages = _apply_inline_fixes(content, actual)
        self.assertIn("(128 table/column constants)", fixed)
        self.assertIn("**Edge Functions**: 8 in `supabase/functions/`", fixed)
        self.assertIn("**Migrations**: 144 SQL files in `supabase/migrations/`", fixed)
        self.assertIn("- 855 test files, 10,566+ individual tests", fixed)
        self.assertIn("## Shared Widgets (23)", fixed)
        self.assertGreaterEqual(len(messages), 4)

    def test_updates_quality_checker_counts(self):
        actual = _make_sample_actual({
            "quality_covered": 19,
            "quality_extra": 9,
            "quality_total": 27,
        })
        content = "\n".join([
            "python3 scripts/verify_code_quality.py    # Anti-pattern scan (21 checkers, 16/24 CLAUDE.md patterns + 5 extra)",
            "- `verify_code_quality.py` scans for 21 patterns (16 from CLAUDE.md + 5 extra)",
            "Enforced by: `verify_code_quality.py` (21 automated checkers)",
        ])
        fixed, messages = _apply_inline_fixes(content, actual)
        self.assertIn("Anti-pattern scan (27 checkers, 19/24 CLAUDE.md patterns + 9 extra)", fixed)
        self.assertIn("scans with 27 checkers (19 from CLAUDE.md + 9 extra)", fixed)
        self.assertIn("Enforced by: `verify_code_quality.py` (27 automated checkers)", fixed)
        self.assertTrue(any("quality checker" in m.lower() for m in messages))

    def test_updates_inline_asset_index_constant_and_migration_counts(self):
        actual = _make_sample_actual({
            "icons": 91,
            "indexes": 42,
            "supa": 128,
            "migrations": 144,
        })
        content = "\n".join([
            "- 82 custom SVG icons in `assets/icons/`",
            "- 34+ composite indexes keep local queries fast",
            "- Supabase constants — 110 constants",
            "- 125 SQL migration files in `supabase/migrations/`",
            "- supabase/migrations/ (125 files)",
            "- **Migrations**: 125 SQL files in `supabase/migrations/`",
        ])
        fixed, messages = _apply_inline_fixes(content, actual)
        self.assertIn("91 custom SVG icons in", fixed)
        self.assertIn("42 composite indexes", fixed)
        self.assertIn("— 128 constants", fixed)
        self.assertIn("144 SQL migration files in", fixed)
        self.assertIn("supabase/migrations/ (144 files)", fixed)
        self.assertIn("**Migrations**: 144 SQL files in `supabase/migrations/`", fixed)
        self.assertGreaterEqual(len(messages), 6)

    def test_missing_indexes_key_raises(self):
        actual = _make_sample_actual()
        actual.pop("indexes")
        with self.assertRaises(KeyError):
            _apply_inline_fixes("34 composite indexes\n", actual)


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
        (w / "bottom_sheet").mkdir(parents=True)
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
            (w / "bottom_sheet" / "app_bottom_sheet.dart").touch()
            result = collect_widgets(lib)
            self.assertEqual(result["widgets_cards"], 2)
            self.assertEqual(result["widgets_dialogs"], 1)
            self.assertEqual(result["widgets_bottom_sheet"], 1)

    def test_counts_eggs_subdir(self):
        with tempfile.TemporaryDirectory() as d:
            lib = Path(d)
            w = self._make_widgets_dir(lib)
            (w / "eggs").mkdir()
            (w / "eggs" / "egg_status_chip.dart").touch()
            (w / "eggs" / "egg_summary_row.dart").touch()
            result = collect_widgets(lib)
            self.assertEqual(result["widgets_eggs"], 2)
            self.assertEqual(result["widgets_total"], 2)

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


class TestCountEdgeFunctions(unittest.TestCase):
    def test_counts_index_ts_functions_excluding_shared(self):
        with tempfile.TemporaryDirectory() as d:
            root = Path(d)
            for name in ("send-push", "system-health", "_shared"):
                fn_dir = root / "supabase" / "functions" / name
                fn_dir.mkdir(parents=True)
                (fn_dir / "index.ts").touch()
            self.assertEqual(count_edge_functions(root), 2)

    def test_returns_zero_when_functions_dir_missing(self):
        with tempfile.TemporaryDirectory() as d:
            self.assertEqual(count_edge_functions(Path(d)), 0)


class TestCountIndexes(unittest.TestCase):
    def test_ignores_commented_create_index_lines(self):
        with tempfile.TemporaryDirectory() as d:
            db_dir = Path(d)
            (db_dir / "app_database_indexes.dart").write_text(
                "\n".join([
                    "// CREATE INDEX ignored_comment",
                    "/// CREATE INDEX ignored_doc_comment",
                    "CREATE INDEX active_index ON birds(id);",
                ]),
                encoding="utf-8",
            )
            self.assertEqual(_count_indexes(db_dir), 1)


class TestCollectQualityCheckerCounts(unittest.TestCase):
    def test_counts_quality_checker_dicts(self):
        with tempfile.TemporaryDirectory() as d:
            root = Path(d)
            scripts = root / "scripts"
            scripts.mkdir()
            (scripts / "verify_code_quality.py").write_text(
                "ANTI_PATTERN_COVERAGE = {1: 'a', 2: 'b'}\n"
                "EXTRA_CHECKERS = {'x': 'extra'}\n",
                encoding="utf-8",
            )
            result = collect_quality_checker_counts(root)
            self.assertEqual(result["quality_covered"], 2)
            self.assertEqual(result["quality_extra"], 1)
            self.assertEqual(result["quality_total"], 3)

    def test_returns_zero_counts_when_scanner_missing(self):
        with tempfile.TemporaryDirectory() as d:
            result = collect_quality_checker_counts(Path(d))
            self.assertEqual(result["quality_total"], 0)

    def test_returns_zero_counts_when_scanner_has_invalid_python(self):
        with tempfile.TemporaryDirectory() as d:
            root = Path(d)
            scripts = root / "scripts"
            scripts.mkdir()
            (scripts / "verify_code_quality.py").write_text("ANTI_PATTERN_COVERAGE = {\n", encoding="utf-8")
            result = collect_quality_checker_counts(root)
            self.assertEqual(result["quality_total"], 0)

    def test_ignores_non_name_assignments_and_non_literal_values(self):
        with tempfile.TemporaryDirectory() as d:
            root = Path(d)
            scripts = root / "scripts"
            scripts.mkdir()
            (scripts / "verify_code_quality.py").write_text(
                "ANTI_PATTERN_COVERAGE['x'] = 'ignored'\n"
                "ANTI_PATTERN_COVERAGE = dict(a='not literal')\n"
                "EXTRA_CHECKERS = {'x': 'extra'}\n",
                encoding="utf-8",
            )
            result = collect_quality_checker_counts(root)
            self.assertEqual(result["quality_covered"], 0)
            self.assertEqual(result["quality_extra"], 1)
            self.assertEqual(result["quality_total"], 1)


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
        """FIX_MODE=True iken satirlar 78-81 calisir: updates hesaplanir, return 0.

        Regression koruma: vr.main() FIX_MODE'da kendi (patch'lenmis) ROOT ve
        CLAUDE_MD degerlerini fix_claude_md'ye actikca iletmeli — aksi halde
        test calistirildiginda gercek CLAUDE.md / .claude/rules/*.md dosyalari
        unit test fixture degerleriyle UZERINE YAZILIR.
        """
        import _rules_fixers as rf
        import verify_rules as vr

        key_count = 3
        actual = _make_sample_actual({"tr_keys": key_count, "categories": 35})
        content = _make_claude_md_content(tr_keys=key_count + 99)  # kasitli uyumsuz
        with tempfile.TemporaryDirectory() as d:
            root = Path(d)
            assets = self._make_assets(root, key_count=key_count)
            tmp_md = root / "CLAUDE.md"
            tmp_md.write_text(content, encoding="utf-8")

            # Sentinel: _rules_fixers'in modul-seviyesi yollari KASITLI olarak
            # patch edilmiyor. Eger vr.main() bunlari kullanirsa sentinel
            # path'lere yazmaya calisir; bu da gercek CLAUDE.md hasari demek.
            sentinel_root = root / "__must_not_be_used__"
            sentinel_claude = sentinel_root / "CLAUDE.md"

            with patch.object(vr, "CLAUDE_MD", tmp_md), \
                 patch.object(vr, "ASSETS", assets), \
                 patch.object(vr, "ROOT", root), \
                 patch.object(rf, "ROOT", sentinel_root), \
                 patch.object(rf, "CLAUDE_MD", sentinel_claude), \
                 patch.object(vr, "collect_actual_values", return_value=actual), \
                 patch.object(vr, "FIX_MODE", True):
                result = vr.main()
        self.assertEqual(result, 0)
        # Sentinel hedefe asla yazilmamis olmali (vr.main() kendi yolunu iletmis).
        self.assertFalse(
            sentinel_claude.exists(),
            "fix_claude_md gercek modul-seviyesi CLAUDE_MD'ye yazdi; "
            "verify_rules.main() patch'li ROOT/CLAUDE_MD'sini iletmiyor.",
        )

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


# ── Release artefakt capraz-yuzey kontrolu ────────────────────────────────────
#
# 2026-07-25 regresyonu: build_release.sh iOS'ta artik
# build/ios/archive/Runner.xcarchive uretiyordu; release-ops.md, wiki ve skill
# guncellendi ama CLAUDE.md eski build/ios/ipa/*.ipa yolunu iddia etmeye devam
# etti. Sayim tabanli kontrollerin hepsi yesildi — hicbiri "bu yuzeyler ayni
# artefakti sOylemeli" kuralini kodlamiyordu.


class TestExtractMarkdownSection(unittest.TestCase):
    """extract_markdown_section: baslik govdesi cikarma."""

    TEXT = "\n".join([
        "# Title",
        "intro",
        "### Release Builds (Codemagic removed)",
        "body line",
        "#### Sub",
        "sub line",
        "### Next Section",
        "other",
        "## Higher",
        "higher",
    ])

    def test_returns_body_until_same_level_heading(self):
        body = extract_markdown_section(self.TEXT, "### Release Builds")
        self.assertIn("body line", body)
        self.assertNotIn("other", body)

    def test_keeps_deeper_subsections(self):
        body = extract_markdown_section(self.TEXT, "### Release Builds")
        self.assertIn("sub line", body)

    def test_stops_at_higher_level_heading(self):
        body = extract_markdown_section(self.TEXT, "### Next Section")
        self.assertIn("other", body)
        self.assertNotIn("higher", body)

    def test_returns_empty_when_heading_absent(self):
        self.assertEqual(extract_markdown_section(self.TEXT, "### Missing"), "")


class TestExtractReleaseArtifactPaths(unittest.TestCase):
    """extract_release_artifact_paths: build/ yollarini normalize ederek cikarir."""

    def test_finds_paths_and_strips_trailers(self):
        text = (
            "| iOS | `build/ios/archive/Runner.xcarchive` — distribute |\n"
            "produces build/app/outputs/bundle/release/app-release.aab.\n"
            "symbols land in build/symbols/android/**,\n"
        )
        self.assertEqual(
            extract_release_artifact_paths(text),
            {
                "build/ios/archive/Runner.xcarchive",
                "build/app/outputs/bundle/release/app-release.aab",
                "build/symbols/android/**",
            },
        )

    def test_returns_empty_set_without_paths(self):
        self.assertEqual(extract_release_artifact_paths("no artifacts here"), set())


class TestReleaseArtifactsCheck(unittest.TestCase):
    """main() icindeki Release Artifacts bolumu."""

    ARCHIVE = "build/ios/archive/Runner.xcarchive"

    def _run(self, root: Path, release_section: str, *, release_ops: str = None,
             producer: str = None) -> int:
        import verify_rules as vr

        assets = root / "assets" / "translations"
        assets.mkdir(parents=True)
        data = {f"k{i}": f"v{i}" for i in range(3)}
        for lang in ("tr", "en", "de"):
            (assets / f"{lang}.json").write_text(json.dumps(data), encoding="utf-8")

        tmp_md = root / "CLAUDE.md"
        tmp_md.write_text(
            _make_claude_md_content(tr_keys=3) + "\n" + release_section,
            encoding="utf-8",
        )
        if release_ops is not None:
            rules_dir = root / ".claude" / "rules"
            rules_dir.mkdir(parents=True, exist_ok=True)
            (rules_dir / "release-ops.md").write_text(release_ops, encoding="utf-8")
        if producer is not None:
            scripts_dir = root / "scripts"
            scripts_dir.mkdir(parents=True, exist_ok=True)
            (scripts_dir / "build_release.sh").write_text(producer, encoding="utf-8")

        actual = _make_sample_actual({"tr_keys": 3, "categories": 35})
        with patch.object(vr, "CLAUDE_MD", tmp_md), \
             patch.object(vr, "ASSETS", root / "assets"), \
             patch.object(vr, "ROOT", root), \
             patch.object(vr, "collect_actual_values", return_value=actual):
            return vr.main()

    def _section(self, path: str) -> str:
        return f"### Release Builds\n\n| iOS | `scripts/build_release.sh ios` | `{path}` |\n"

    def test_passes_when_surfaces_agree(self):
        with tempfile.TemporaryDirectory() as d:
            result = self._run(
                Path(d),
                self._section(self.ARCHIVE),
                release_ops=f"Dagitim: `{self.ARCHIVE}` -> Xcode Organizer",
                producer=f'echo "Archive: {self.ARCHIVE}"',
            )
        self.assertEqual(result, 0)

    def test_fails_when_claude_md_path_missing_from_release_ops(self):
        """067aa2f regresyonu: CLAUDE.md guncellenmeden birakilirsa kirmizi olmali."""
        with tempfile.TemporaryDirectory() as d:
            result = self._run(
                Path(d),
                self._section("build/ios/ipa/*.ipa"),
                release_ops=f"Dagitim: `{self.ARCHIVE}` -> Xcode Organizer",
                producer=f'echo "IPA: build/ios/ipa/*.ipa"; echo "{self.ARCHIVE}"',
            )
        self.assertEqual(result, 1)

    def test_fails_when_no_producer_emits_the_path(self):
        with tempfile.TemporaryDirectory() as d:
            result = self._run(
                Path(d),
                self._section("build/ios/imaginary/App.ipa"),
                release_ops="Dagitim: `build/ios/imaginary/App.ipa` -> nowhere",
                producer='echo "builds nothing of the sort"',
            )
        self.assertEqual(result, 1)

    def test_skips_when_release_ops_missing(self):
        with tempfile.TemporaryDirectory() as d:
            result = self._run(
                Path(d),
                self._section(self.ARCHIVE),
                producer=f'echo "{self.ARCHIVE}"',
            )
        self.assertEqual(result, 0)

    def test_skips_when_no_producer_files(self):
        with tempfile.TemporaryDirectory() as d:
            result = self._run(
                Path(d),
                self._section(self.ARCHIVE),
                release_ops=f"`{self.ARCHIVE}`",
            )
        self.assertEqual(result, 0)

    def test_skips_when_section_has_no_build_path(self):
        with tempfile.TemporaryDirectory() as d:
            result = self._run(
                Path(d),
                "### Release Builds\n\nNothing publishes automatically.\n",
                release_ops="irrelevant",
                producer="irrelevant",
            )
        self.assertEqual(result, 0)


# ── Edge Function ad tutarliligi ──────────────────────────────────────────────
#
# edge-functions.md: EdgeFunctionName sabit sinifi YOK — ad dort yuzeyde
# tekrarlanan bir literal. Drift runtime'da 404, deploy'da eksik fonksiyon veya
# sessizce (bayat _rateLimitExempt girdisi) patlar.


def _write_edge_fixture(root: Path, *, dirs, config, deploy, client_literals,
                        exempt=(), omit=()) -> None:
    """Dort Edge Function yuzeyini gecici bir kok altinda olustur."""
    if "dirs" not in omit:
        for name in dirs:
            (root / "supabase" / "functions" / name).mkdir(parents=True)
        (root / "supabase" / "functions" / "_shared").mkdir(parents=True, exist_ok=True)
    if "config" not in omit:
        (root / "supabase").mkdir(parents=True, exist_ok=True)
        body = "\n".join(f"[functions.{n}]\nverify_jwt = true" for n in config)
        (root / "supabase" / "config.toml").write_text(body, encoding="utf-8")
    if "deploy" not in omit:
        wf = root / ".github" / "workflows"
        wf.mkdir(parents=True, exist_ok=True)
        body = "\n".join(f"          supabase functions deploy {n} --project-ref X" for n in deploy)
        (wf / "ci.yml").write_text(f"jobs:\n  deploy:\n    run: |\n{body}\n", encoding="utf-8")
    if "client" not in omit:
        client_dir = root / "lib" / "data" / "remote" / "supabase"
        client_dir.mkdir(parents=True, exist_ok=True)
        calls = "\n".join(f"    return invoke('{n}');" for n in client_literals)
        exempt_body = "".join(f"    '{n}',\n" for n in exempt)
        (client_dir / "edge_function_client.dart").write_text(
            "class EdgeFunctionClient {\n"
            f"  static const _rateLimitExempt = {{\n{exempt_body}  }};\n"
            f"{calls}\n}}\n",
            encoding="utf-8",
        )


class TestCollectEdgeFunctionSurfaces(unittest.TestCase):
    """collect_edge_function_surfaces: dort yuzeyden ad toplama."""

    def test_collects_all_four_surfaces(self):
        with tempfile.TemporaryDirectory() as d:
            root = Path(d)
            _write_edge_fixture(
                root, dirs=["send-push", "mfa-lockout"],
                config=["send-push", "mfa-lockout"],
                deploy=["send-push", "mfa-lockout"],
                client_literals=["send-push"],
                exempt=["mfa-lockout"],
            )
            surfaces = collect_edge_function_surfaces(root)
        self.assertEqual(surfaces["disk"], {"send-push", "mfa-lockout"})
        self.assertEqual(surfaces["config"], {"send-push", "mfa-lockout"})
        self.assertEqual(surfaces["deploy"], {"send-push", "mfa-lockout"})
        # _rateLimitExempt girdileri de literal sayilir
        self.assertEqual(surfaces["client"], {"send-push", "mfa-lockout"})

    def test_excludes_underscore_dirs(self):
        with tempfile.TemporaryDirectory() as d:
            root = Path(d)
            _write_edge_fixture(root, dirs=["send-push"], config=[], deploy=[],
                                client_literals=[])
            self.assertEqual(collect_edge_function_surfaces(root)["disk"], {"send-push"})

    def test_missing_surface_files_yield_none(self):
        with tempfile.TemporaryDirectory() as d:
            root = Path(d)
            _write_edge_fixture(root, dirs=["send-push"], config=[], deploy=[],
                                client_literals=[],
                                omit=("config", "deploy", "client"))
            surfaces = collect_edge_function_surfaces(root)
        self.assertIsNone(surfaces["config"])
        self.assertIsNone(surfaces["deploy"])
        self.assertIsNone(surfaces["client"])

    def test_missing_functions_dir_yields_empty_disk(self):
        with tempfile.TemporaryDirectory() as d:
            self.assertEqual(collect_edge_function_surfaces(Path(d))["disk"], set())


class TestEdgeFunctionCheck(unittest.TestCase):
    """main() icindeki Edge Functions bolumu ve ozet ipucu dallari."""

    def _run(self, root: Path, *, dirs, config, deploy, client_literals,
             exempt=(), omit=(), claude_extra="", capture=False):
        import verify_rules as vr

        assets = root / "assets" / "translations"
        assets.mkdir(parents=True)
        data = {f"k{i}": f"v{i}" for i in range(3)}
        for lang in ("tr", "en", "de"):
            (assets / f"{lang}.json").write_text(json.dumps(data), encoding="utf-8")

        tmp_md = root / "CLAUDE.md"
        tmp_md.write_text(_make_claude_md_content(tr_keys=3) + claude_extra, encoding="utf-8")
        _write_edge_fixture(root, dirs=dirs, config=config, deploy=deploy,
                            client_literals=client_literals, exempt=exempt,
                            omit=omit)

        actual = _make_sample_actual({"tr_keys": 3, "categories": 35})
        buffer = io.StringIO()
        with patch.object(vr, "CLAUDE_MD", tmp_md), \
             patch.object(vr, "ASSETS", root / "assets"), \
             patch.object(vr, "ROOT", root), \
             patch.object(vr, "collect_actual_values", return_value=actual):
            if capture:
                with redirect_stdout(buffer):
                    result = vr.main()
                return result, buffer.getvalue()
            return vr.main(), ""

    def test_passes_when_all_surfaces_agree(self):
        with tempfile.TemporaryDirectory() as d:
            result, _ = self._run(
                Path(d), dirs=["send-push"], config=["send-push"],
                deploy=["send-push"], client_literals=["send-push"],
            )
        self.assertEqual(result, 0)

    def test_fails_when_config_entry_is_missing(self):
        with tempfile.TemporaryDirectory() as d:
            result, _ = self._run(
                Path(d), dirs=["send-push", "system-health"], config=["send-push"],
                deploy=["send-push", "system-health"], client_literals=["send-push"],
            )
        self.assertEqual(result, 1)

    def test_fails_when_config_names_a_deleted_function(self):
        with tempfile.TemporaryDirectory() as d:
            result, _ = self._run(
                Path(d), dirs=["send-push"], config=["send-push", "gone"],
                deploy=["send-push"], client_literals=["send-push"],
            )
        self.assertEqual(result, 1)

    def test_fails_when_deploy_list_is_missing_a_function(self):
        with tempfile.TemporaryDirectory() as d:
            result, _ = self._run(
                Path(d), dirs=["send-push", "system-health"],
                config=["send-push", "system-health"], deploy=["send-push"],
                client_literals=["send-push"],
            )
        self.assertEqual(result, 1)

    def test_fails_when_client_invokes_unknown_function(self):
        with tempfile.TemporaryDirectory() as d:
            result, _ = self._run(
                Path(d), dirs=["send-push"], config=["send-push"],
                deploy=["send-push"], client_literals=["sytem-health"],
            )
        self.assertEqual(result, 1)

    def test_fails_when_rate_limit_exempt_names_a_stale_function(self):
        """En sinsi hali: bayat _rateLimitExempt girdisi sessizce muafiyeti kaybeder."""
        with tempfile.TemporaryDirectory() as d:
            result, _ = self._run(
                Path(d), dirs=["send-push"], config=["send-push"],
                deploy=["send-push"], client_literals=["send-push"],
                exempt=["create-community-pos"],
            )
        self.assertEqual(result, 1)

    def test_client_need_not_invoke_every_function(self):
        """Webhook/trigger/cron ile cagrilan fonksiyon client'ta olmayabilir."""
        with tempfile.TemporaryDirectory() as d:
            result, _ = self._run(
                Path(d), dirs=["send-push", "revenuecat-webhook"],
                config=["send-push", "revenuecat-webhook"],
                deploy=["send-push", "revenuecat-webhook"],
                client_literals=["send-push"],
            )
        self.assertEqual(result, 0)

    def test_skips_when_surface_files_absent(self):
        with tempfile.TemporaryDirectory() as d:
            result, _ = self._run(
                Path(d), dirs=["send-push"], config=[], deploy=[],
                client_literals=[], omit=("config", "deploy", "client"),
            )
        self.assertEqual(result, 0)

    def test_skips_when_functions_dir_absent(self):
        with tempfile.TemporaryDirectory() as d:
            result, _ = self._run(
                Path(d), dirs=[], config=[], deploy=[], client_literals=[],
                omit=("dirs",),
            )
        self.assertEqual(result, 0)

    def test_manual_failure_does_not_suggest_fix(self):
        """Capraz-yuzey hatasinda '--fix ile duzelt' ipucu YANILTICI — gosterme."""
        with tempfile.TemporaryDirectory() as d:
            result, out = self._run(
                Path(d), dirs=["send-push", "system-health"], config=["send-push"],
                deploy=["send-push", "system-health"], client_literals=["send-push"],
                capture=True,
            )
        self.assertEqual(result, 1)
        self.assertNotIn("--fix' ile otomatik duzelt", out)
        self.assertIn("capraz-yuzey hatasi", out)

    def test_fixable_failure_still_suggests_fix(self):
        """Sayim drift'i hala otomatik duzeltilebilir — ipucu korunmali."""
        import verify_rules as vr

        with tempfile.TemporaryDirectory() as d:
            root = Path(d)
            assets = root / "assets" / "translations"
            assets.mkdir(parents=True)
            data = {f"k{i}": f"v{i}" for i in range(3)}
            for lang in ("tr", "en", "de"):
                (assets / f"{lang}.json").write_text(json.dumps(data), encoding="utf-8")
            tmp_md = root / "CLAUDE.md"
            tmp_md.write_text(_make_claude_md_content(tr_keys=3), encoding="utf-8")
            _write_edge_fixture(root, dirs=["send-push"], config=["send-push"],
                                deploy=["send-push"], client_literals=["send-push"])
            # routes sayisini kasten kaydir → fixable bir hata uret
            actual = _make_sample_actual({"tr_keys": 3, "categories": 35, "routes": 999})
            buffer = io.StringIO()
            with patch.object(vr, "CLAUDE_MD", tmp_md), \
                 patch.object(vr, "ASSETS", root / "assets"), \
                 patch.object(vr, "ROOT", root), \
                 patch.object(vr, "collect_actual_values", return_value=actual), \
                 redirect_stdout(buffer):
                result = vr.main()
            out = buffer.getvalue()
        self.assertEqual(result, 1)
        self.assertIn("--fix' ile otomatik duzelt", out)
        self.assertNotIn("capraz-yuzey hatasi", out)


# ── Storage bucket ad tutarliligi ─────────────────────────────────────────────


def _write_bucket_fixture(root: Path, *, constants, migrations, doc, omit=()) -> None:
    """Uc bucket yuzeyini gecici bir kok altinda olustur."""
    if "constants" not in omit:
        d = root / "lib" / "core" / "constants"
        d.mkdir(parents=True, exist_ok=True)
        body = "\n".join(
            f"  static const String {n.replace('-', '_')}Bucket = '{n}';" for n in constants
        )
        (d / "supabase_constants.dart").write_text(
            f"class SupabaseConstants {{\n{body}\n}}\n", encoding="utf-8")
    if "migrations" not in omit:
        d = root / "supabase" / "migrations"
        d.mkdir(parents=True, exist_ok=True)
        for i, name in enumerate(migrations):
            # Alternate the two real-world shapes: bucket DDL and an
            # objects-policy bucket_id reference.
            sql = (
                f"insert into storage.buckets (id, public) values ('{name}', false);"
                if i % 2 == 0
                else f"create policy p on storage.objects using (bucket_id = '{name}');"
            )
            (d / f"2026010100000{i}_bucket_{i}.sql").write_text(sql, encoding="utf-8")
    if "doc" not in omit:
        d = root / ".claude" / "rules"
        d.mkdir(parents=True, exist_ok=True)
        body = "\n".join(f"| `{n}` | Private | notes |" for n in doc)
        (d / "assets-images.md").write_text(f"# Assets\n{body}\n", encoding="utf-8")


class TestCollectStorageBucketSurfaces(unittest.TestCase):
    """collect_storage_bucket_surfaces: sabit / migration / dokuman."""

    def test_reads_both_migration_shapes(self):
        with tempfile.TemporaryDirectory() as d:
            root = Path(d)
            _write_bucket_fixture(root, constants=["bird-photos", "avatars"],
                                  migrations=["bird-photos", "avatars"],
                                  doc=["bird-photos", "avatars"])
            surfaces = collect_storage_bucket_surfaces(root)
        self.assertEqual(surfaces["constants"], {"bird-photos", "avatars"})
        self.assertEqual(surfaces["migrations"], {"bird-photos", "avatars"})
        self.assertIn("`bird-photos`", surfaces["doc_text"])

    def test_missing_surfaces_yield_none(self):
        with tempfile.TemporaryDirectory() as d:
            surfaces = collect_storage_bucket_surfaces(Path(d))
        self.assertIsNone(surfaces["constants"])
        self.assertIsNone(surfaces["migrations"])
        self.assertIsNone(surfaces["doc_text"])


class TestStorageBucketCheck(unittest.TestCase):
    """main() icindeki Storage Buckets bolumu."""

    def _run(self, root: Path, *, constants, migrations, doc, omit=()):
        import verify_rules as vr

        assets = root / "assets" / "translations"
        assets.mkdir(parents=True)
        data = {f"k{i}": f"v{i}" for i in range(3)}
        for lang in ("tr", "en", "de"):
            (assets / f"{lang}.json").write_text(json.dumps(data), encoding="utf-8")
        tmp_md = root / "CLAUDE.md"
        tmp_md.write_text(_make_claude_md_content(tr_keys=3), encoding="utf-8")
        _write_bucket_fixture(root, constants=constants, migrations=migrations,
                              doc=doc, omit=omit)

        actual = _make_sample_actual({"tr_keys": 3, "categories": 35})
        with patch.object(vr, "CLAUDE_MD", tmp_md), \
             patch.object(vr, "ASSETS", root / "assets"), \
             patch.object(vr, "ROOT", root), \
             patch.object(vr, "collect_actual_values", return_value=actual):
            return vr.main()

    def test_passes_when_all_surfaces_agree(self):
        with tempfile.TemporaryDirectory() as d:
            result = self._run(Path(d), constants=["bird-photos"],
                               migrations=["bird-photos"], doc=["bird-photos"])
        self.assertEqual(result, 0)

    def test_fails_when_constant_is_never_provisioned(self):
        """En pahali hali: upload aninda patlar, build'de degil."""
        with tempfile.TemporaryDirectory() as d:
            result = self._run(Path(d), constants=["bird-photos", "receipts"],
                               migrations=["bird-photos"],
                               doc=["bird-photos", "receipts"])
        self.assertEqual(result, 1)

    def test_fails_when_migration_bucket_has_no_constant(self):
        with tempfile.TemporaryDirectory() as d:
            result = self._run(Path(d), constants=["bird-photos"],
                               migrations=["bird-photos", "orphan-bucket"],
                               doc=["bird-photos"])
        self.assertEqual(result, 1)

    def test_fails_when_bucket_is_undocumented(self):
        with tempfile.TemporaryDirectory() as d:
            result = self._run(Path(d), constants=["bird-photos", "avatars"],
                               migrations=["bird-photos", "avatars"],
                               doc=["bird-photos"])
        self.assertEqual(result, 1)

    def test_skips_when_constants_absent(self):
        with tempfile.TemporaryDirectory() as d:
            result = self._run(Path(d), constants=[], migrations=["x"], doc=["x"],
                               omit=("constants",))
        self.assertEqual(result, 0)

    def test_skips_when_migrations_and_doc_absent(self):
        with tempfile.TemporaryDirectory() as d:
            result = self._run(Path(d), constants=["bird-photos"], migrations=[],
                               doc=[], omit=("migrations", "doc"))
        self.assertEqual(result, 0)


# ── L10n kategori ad tutarliligi ──────────────────────────────────────────────
#
# Kategori SAYISI zaten tr.json'a karsi dogrulaniyor; ADLAR degil. Yeniden
# adlandirilan bir kategori sayiyi bozmadan listeyi sessizce curutur.


def _write_l10n_fixture(root: Path, *, json_cats, doc_cats, omit=()) -> None:
    if "json" not in omit:
        d = root / "assets" / "translations"
        d.mkdir(parents=True, exist_ok=True)
        (d / "tr.json").write_text(
            json.dumps({c: {"k": "v"} for c in json_cats}), encoding="utf-8")
    if "doc" not in omit:
        d = root / ".claude" / "rules"
        d.mkdir(parents=True, exist_ok=True)
        section = "" if "section" in omit else (
            f"## {len(doc_cats)} Categories\n{', '.join(doc_cats)}\n\n")
        (d / "localization.md").write_text(
            f"# Localization\n\n{section}## Rules\nsomething\n", encoding="utf-8")


class TestCollectL10nCategorySurfaces(unittest.TestCase):
    def test_reads_both_surfaces(self):
        with tempfile.TemporaryDirectory() as d:
            root = Path(d)
            _write_l10n_fixture(root, json_cats=["birds", "common"],
                                doc_cats=["birds", "common"])
            surfaces = collect_l10n_category_surfaces(root)
        self.assertEqual(surfaces["json"], {"birds", "common"})
        self.assertEqual(surfaces["doc"], {"birds", "common"})

    def test_handles_a_wrapped_category_list(self):
        """Liste satira sigmayip sarabilir; newline virgul kadar gecerli ayirac."""
        with tempfile.TemporaryDirectory() as d:
            root = Path(d)
            rules = root / ".claude" / "rules"
            rules.mkdir(parents=True)
            (rules / "localization.md").write_text(
                "# L\n\n## 3 Categories\nbirds, common,\neggs\n\n## Next\n",
                encoding="utf-8")
            surfaces = collect_l10n_category_surfaces(root)
        self.assertEqual(surfaces["doc"], {"birds", "common", "eggs"})

    def test_missing_surfaces_yield_none(self):
        with tempfile.TemporaryDirectory() as d:
            surfaces = collect_l10n_category_surfaces(Path(d))
        self.assertIsNone(surfaces["json"])
        self.assertIsNone(surfaces["doc"])

    def test_missing_section_yields_none_doc(self):
        with tempfile.TemporaryDirectory() as d:
            root = Path(d)
            _write_l10n_fixture(root, json_cats=["birds"], doc_cats=[],
                                omit=("section",))
            self.assertIsNone(collect_l10n_category_surfaces(root)["doc"])


class TestL10nCategoryCheck(unittest.TestCase):
    def _run(self, root: Path, *, json_cats, doc_cats, omit=()):
        import verify_rules as vr

        assets = root / "assets" / "translations"
        assets.mkdir(parents=True)
        payload = json.dumps({c: {"k": "v"} for c in json_cats})
        for lang in ("tr", "en", "de"):
            (assets / f"{lang}.json").write_text(payload, encoding="utf-8")
        tmp_md = root / "CLAUDE.md"
        tmp_md.write_text(_make_claude_md_content(tr_keys=len(json_cats)), encoding="utf-8")
        _write_l10n_fixture(root, json_cats=json_cats, doc_cats=doc_cats,
                            omit=tuple(o for o in omit if o != "json"))

        actual = _make_sample_actual({"tr_keys": len(json_cats), "categories": len(json_cats)})
        with patch.object(vr, "CLAUDE_MD", tmp_md), \
             patch.object(vr, "ASSETS", root / "assets"), \
             patch.object(vr, "ROOT", root), \
             patch.object(vr, "collect_actual_values", return_value=actual):
            return vr.main()

    def test_passes_when_names_agree(self):
        with tempfile.TemporaryDirectory() as d:
            result = self._run(Path(d), json_cats=["birds", "common"],
                               doc_cats=["birds", "common"])
        self.assertEqual(result, 0)

    def test_fails_on_a_renamed_category(self):
        """Sayi ayni kalir (2 = 2) ama adlar ayrisir — sayim kontrolu bunu goremez."""
        with tempfile.TemporaryDirectory() as d:
            result = self._run(Path(d), json_cats=["birds", "common"],
                               doc_cats=["birdz", "common"])
        self.assertEqual(result, 1)

    def test_fails_when_doc_list_is_missing_a_category(self):
        with tempfile.TemporaryDirectory() as d:
            result = self._run(Path(d), json_cats=["birds", "common"],
                               doc_cats=["birds"])
        self.assertEqual(result, 1)

    def test_skips_when_section_absent(self):
        with tempfile.TemporaryDirectory() as d:
            result = self._run(Path(d), json_cats=["birds"], doc_cats=[],
                               omit=("section",))
        self.assertEqual(result, 0)


# ── SVG ikon bijeksiyonu ──────────────────────────────────────────────────────
#
# Sayilar zaten karsilastiriliyor (99 sabit == 99 dosya). Hangi sabitin hangi
# dosyayi gosterdigi karsilastirilmiyordu: yeniden adlandirilan bir asset her
# iki sayiyi da dogru birakir ve yalnizca runtime'da — flutter_svg hicbir sey
# cizmeyerek — belli olur.


def _write_icon_fixture(root: Path, *, constants, files, omit=()) -> None:
    if "constants" not in omit:
        d = root / "lib" / "core" / "constants"
        d.mkdir(parents=True, exist_ok=True)
        body = "\n".join(
            f"  static const {p.split('/')[-1][:-4]} = '{p}';" for p in constants)
        (d / "app_icons.dart").write_text(
            f"abstract final class AppIcons {{\n{body}\n}}\n", encoding="utf-8")
    if "files" not in omit:
        for rel in files:
            target = root / rel
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_text("<svg/>", encoding="utf-8")
        (root / "assets" / "icons").mkdir(parents=True, exist_ok=True)


class TestCollectIconSurfaces(unittest.TestCase):
    def test_reads_constants_and_disk(self):
        with tempfile.TemporaryDirectory() as d:
            root = Path(d)
            paths = ["assets/icons/nav/home.svg", "assets/icons/birds/male.svg"]
            _write_icon_fixture(root, constants=paths, files=paths)
            surfaces = collect_icon_surfaces(root)
        self.assertEqual(surfaces["constants"], set(paths))
        self.assertEqual(surfaces["disk"], set(paths))

    def test_missing_surfaces_yield_none(self):
        with tempfile.TemporaryDirectory() as d:
            surfaces = collect_icon_surfaces(Path(d))
        self.assertIsNone(surfaces["constants"])
        self.assertIsNone(surfaces["disk"])


class TestIconBijectionCheck(unittest.TestCase):
    def _run(self, root: Path, *, constants, files, omit=()):
        import verify_rules as vr

        assets = root / "assets" / "translations"
        assets.mkdir(parents=True)
        data = {f"k{i}": f"v{i}" for i in range(3)}
        for lang in ("tr", "en", "de"):
            (assets / f"{lang}.json").write_text(json.dumps(data), encoding="utf-8")
        tmp_md = root / "CLAUDE.md"
        tmp_md.write_text(_make_claude_md_content(tr_keys=3), encoding="utf-8")
        _write_icon_fixture(root, constants=constants, files=files, omit=omit)

        actual = _make_sample_actual({"tr_keys": 3, "categories": 35})
        with patch.object(vr, "CLAUDE_MD", tmp_md), \
             patch.object(vr, "ASSETS", root / "assets"), \
             patch.object(vr, "ROOT", root), \
             patch.object(vr, "collect_actual_values", return_value=actual):
            return vr.main()

    def test_passes_on_a_perfect_bijection(self):
        paths = ["assets/icons/nav/home.svg"]
        with tempfile.TemporaryDirectory() as d:
            self.assertEqual(self._run(Path(d), constants=paths, files=paths), 0)

    def test_fails_on_a_renamed_asset(self):
        """Sayilar esit kalir (1 == 1) ama eslesme bozulur."""
        with tempfile.TemporaryDirectory() as d:
            result = self._run(Path(d),
                               constants=["assets/icons/nav/hom.svg"],
                               files=["assets/icons/nav/home.svg"])
        self.assertEqual(result, 1)

    def test_fails_on_an_svg_without_a_constant(self):
        with tempfile.TemporaryDirectory() as d:
            result = self._run(Path(d),
                               constants=["assets/icons/nav/home.svg"],
                               files=["assets/icons/nav/home.svg",
                                      "assets/icons/nav/orphan.svg"])
        self.assertEqual(result, 1)

    def test_skips_when_surfaces_absent(self):
        with tempfile.TemporaryDirectory() as d:
            result = self._run(Path(d), constants=[], files=[],
                               omit=("constants", "files"))
        self.assertEqual(result, 0)


# ── Rota hedefleri ────────────────────────────────────────────────────────────
#
# Bu aile bir bijeksiyon DEGIL: GoRouter ic ice rotalari goreli literal'lerden
# birlestirir (`path: ':id'`), yani `/chicks/:id` hicbir zaman bir `path:`
# degeri olarak yazilmaz ve 12 sabit hakli olarak adiyla referanslanmaz —
# onlara `context.push('/chicks/$id')` ile gidilir. "Her sabit referanslansin"
# kurali bu detay rotalarinin hepsini yanlis yere isaretlerdi.


def _write_route_fixture(root: Path, *, constants, nav_source="", omit=()) -> None:
    if "names" not in omit:
        d = root / "lib" / "router"
        d.mkdir(parents=True, exist_ok=True)
        body = "\n".join(f"  static const {n} = '{v}';" for n, v in constants.items())
        (d / "route_names.dart").write_text(
            f"abstract class AppRoutes {{\n{body}\n}}\n", encoding="utf-8")
    if nav_source:
        d = root / "lib" / "features"
        d.mkdir(parents=True, exist_ok=True)
        (d / "screen.dart").write_text(nav_source, encoding="utf-8")


class TestRouteSurfaces(unittest.TestCase):
    def test_collects_constants_literals_and_prefixes(self):
        with tempfile.TemporaryDirectory() as d:
            root = Path(d)
            _write_route_fixture(
                root, constants={"birds": "/birds", "birdDetail": "/birds/:id"},
                nav_source="context.push('/birds'); context.push('/birds/${b.id}');")
            surfaces = collect_route_surfaces(root)
        self.assertEqual(surfaces["constants"]["birdDetail"], "/birds/:id")
        self.assertIn("/birds", surfaces["literals"])
        self.assertIn("/birds", surfaces["prefixes"])

    def test_missing_names_file_yields_none(self):
        with tempfile.TemporaryDirectory() as d:
            self.assertIsNone(collect_route_surfaces(Path(d))["constants"])

    def test_interpolated_target_resolves_via_a_parameterized_constant(self):
        """`/chicks/$id` hedefini `/chicks/:id` sabiti karsilar."""
        surfaces = {"constants": {"chickDetail": "/chicks/:id"},
                    "literals": set(), "prefixes": {"/chicks"}}
        self.assertEqual(unresolved_route_targets(surfaces), [])

    def test_unknown_literal_and_prefix_are_reported(self):
        surfaces = {"constants": {"birds": "/birds"},
                    "literals": {"/typo"}, "prefixes": {"/nope"}}
        self.assertEqual(unresolved_route_targets(surfaces), ["/nope", "/typo"])

    def test_duplicate_values_are_reported(self):
        surfaces = {"constants": {"a": "/birds", "b": "/birds", "c": "/eggs"}}
        self.assertEqual(duplicate_route_values(surfaces), ["/birds"])

    def test_no_duplicates_when_values_are_unique(self):
        self.assertEqual(duplicate_route_values({"constants": {"a": "/x"}}), [])


class TestRouteTargetCheck(unittest.TestCase):
    def _run(self, root: Path, *, constants, nav_source="", omit=()):
        import verify_rules as vr

        assets = root / "assets" / "translations"
        assets.mkdir(parents=True)
        data = {f"k{i}": f"v{i}" for i in range(3)}
        for lang in ("tr", "en", "de"):
            (assets / f"{lang}.json").write_text(json.dumps(data), encoding="utf-8")
        tmp_md = root / "CLAUDE.md"
        tmp_md.write_text(_make_claude_md_content(tr_keys=3), encoding="utf-8")
        _write_route_fixture(root, constants=constants, nav_source=nav_source, omit=omit)

        actual = _make_sample_actual({"tr_keys": 3, "categories": 35})
        with patch.object(vr, "CLAUDE_MD", tmp_md), \
             patch.object(vr, "ASSETS", root / "assets"), \
             patch.object(vr, "ROOT", root), \
             patch.object(vr, "collect_actual_values", return_value=actual):
            return vr.main()

    def test_passes_when_every_target_resolves(self):
        with tempfile.TemporaryDirectory() as d:
            result = self._run(
                Path(d), constants={"birds": "/birds", "birdDetail": "/birds/:id"},
                nav_source="context.push('/birds'); context.go('/birds/${b.id}');")
        self.assertEqual(result, 0)

    def test_fails_on_a_navigation_target_that_matches_no_route(self):
        """`context.push('/typo')` derlenir ve yalnizca calisma aninda 404 verir."""
        with tempfile.TemporaryDirectory() as d:
            result = self._run(Path(d), constants={"birds": "/birds"},
                               nav_source="context.push('/brids');")
        self.assertEqual(result, 1)

    def test_fails_on_two_constants_sharing_a_path(self):
        with tempfile.TemporaryDirectory() as d:
            result = self._run(Path(d),
                               constants={"birds": "/birds", "alias": "/birds"})
        self.assertEqual(result, 1)

    def test_skips_when_route_names_absent(self):
        with tempfile.TemporaryDirectory() as d:
            result = self._run(Path(d), constants={}, omit=("names",))
        self.assertEqual(result, 0)


# ── Supabase tablo adlari ─────────────────────────────────────────────────────
#
# Sabitin ADINDAKI son eke gore ayiklanir, DEGERINE gore degil:
# `adminExportAllTablesRpc` degeri 'admin_export_all_tables' olan bir RPC'dir,
# tablo degil — degere bakan bir regex onu yanlis yere isaretlerdi.


def _write_table_fixture(root: Path, *, constants, created, omit=()) -> None:
    if "constants" not in omit:
        d = root / "lib" / "core" / "constants"
        d.mkdir(parents=True, exist_ok=True)
        body = "\n".join(f"  static const String {n} = '{v}';" for n, v in constants.items())
        (d / "supabase_constants.dart").write_text(
            f"class SupabaseConstants {{\n{body}\n}}\n", encoding="utf-8")
    if "migrations" not in omit:
        d = root / "supabase" / "migrations"
        d.mkdir(parents=True, exist_ok=True)
        for i, name in enumerate(created):
            sql = (f"create table if not exists public.{name} (id uuid);"
                   if i % 2 == 0 else f"CREATE TABLE {name} (id uuid);")
            (d / f"2026010100000{i}_t{i}.sql").write_text(sql, encoding="utf-8")


class TestSupabaseTableSurfaces(unittest.TestCase):
    def test_reads_constants_and_created_tables(self):
        with tempfile.TemporaryDirectory() as d:
            root = Path(d)
            _write_table_fixture(root, constants={"birdsTable": "birds"},
                                 created=["birds"])
            surfaces = collect_supabase_table_surfaces(root)
        self.assertEqual(surfaces["constants"], {"birds"})
        self.assertEqual(surfaces["created"], {"birds"})

    def test_ignores_rpc_constants_whose_value_mentions_tables(self):
        """`adminExportAllTablesRpc` bir RPC — ad ekine gore elenmeli."""
        with tempfile.TemporaryDirectory() as d:
            root = Path(d)
            _write_table_fixture(
                root,
                constants={"birdsTable": "birds",
                           "adminExportAllTablesRpc": "admin_export_all_tables"},
                created=["birds"])
            surfaces = collect_supabase_table_surfaces(root)
        self.assertEqual(surfaces["constants"], {"birds"})
        self.assertEqual(unprovisioned_tables(surfaces), [])

    def test_missing_surfaces_yield_none(self):
        with tempfile.TemporaryDirectory() as d:
            surfaces = collect_supabase_table_surfaces(Path(d))
        self.assertIsNone(surfaces["constants"])
        self.assertIsNone(surfaces["created"])

    def test_unprovisioned_returns_empty_without_migrations(self):
        self.assertEqual(
            unprovisioned_tables({"constants": {"x"}, "created": None}), [])

    def test_undeclared_columns_returns_empty_without_migrations(self):
        self.assertEqual(
            undeclared_columns({"constants": {"user_idd"}, "declared": None}), [])

    def test_migrations_may_create_tables_the_client_never_names(self):
        """Tek yonlu: trigger'in yazdigi audit tablolari sabit istemez."""
        surfaces = {"constants": {"birds"}, "created": {"birds", "audit_logs"}}
        self.assertEqual(unprovisioned_tables(surfaces), [])


class TestSupabaseTableCheck(unittest.TestCase):
    def _run(self, root: Path, *, constants, created, omit=()):
        import verify_rules as vr

        assets = root / "assets" / "translations"
        assets.mkdir(parents=True)
        data = {f"k{i}": f"v{i}" for i in range(3)}
        for lang in ("tr", "en", "de"):
            (assets / f"{lang}.json").write_text(json.dumps(data), encoding="utf-8")
        tmp_md = root / "CLAUDE.md"
        tmp_md.write_text(_make_claude_md_content(tr_keys=3), encoding="utf-8")
        _write_table_fixture(root, constants=constants, created=created, omit=omit)

        actual = _make_sample_actual({"tr_keys": 3, "categories": 35})
        with patch.object(vr, "CLAUDE_MD", tmp_md), \
             patch.object(vr, "ASSETS", root / "assets"), \
             patch.object(vr, "ROOT", root), \
             patch.object(vr, "collect_actual_values", return_value=actual):
            return vr.main()

    def test_passes_when_every_constant_is_provisioned(self):
        with tempfile.TemporaryDirectory() as d:
            result = self._run(Path(d), constants={"birdsTable": "birds"},
                               created=["birds"])
        self.assertEqual(result, 0)

    def test_fails_on_a_constant_no_migration_creates(self):
        """Sorgu aninda Postgres hatasi verir; build'de sessizdir."""
        with tempfile.TemporaryDirectory() as d:
            result = self._run(Path(d),
                               constants={"birdsTable": "birds",
                                          "ghostTable": "ghost_records"},
                               created=["birds"])
        self.assertEqual(result, 1)

    def test_fails_on_a_column_constant_no_migration_declares(self):
        """Kolon adi tablo-kapsamli degil; yine de typo sinifini yakalar."""
        with tempfile.TemporaryDirectory() as d:
            result = self._run(Path(d),
                               constants={"birdsTable": "birds",
                                          "colTypoed": "user_idd"},
                               created=["birds"])
        self.assertEqual(result, 1)

    def test_skips_when_surfaces_absent(self):
        with tempfile.TemporaryDirectory() as d:
            result = self._run(Path(d), constants={}, created=[],
                               omit=("constants", "migrations"))
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
