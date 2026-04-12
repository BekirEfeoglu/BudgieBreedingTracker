#!/usr/bin/env python3
"""
verify_code_quality.py icin unit testler.

Calistirma:
  python scripts/test_code_quality.py
  python -m pytest scripts/test_code_quality.py -v
"""

import runpy
import sys
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

SCRIPTS_DIR = Path(__file__).resolve().parent
sys.path.insert(0, str(SCRIPTS_DIR))

from verify_code_quality import (
    Category,
    Finding,
    check_bare_catch,
    check_context_go_forward_nav,
    check_dao_import_app_database,
    check_drift_equals,
    check_dropdown_value,
    check_freezed3_pattern,
    check_freezed_private_constructor,
    check_hardcoded_colors,
    check_hardcoded_spacing,
    check_icon_icons,
    check_icondata_param,
    check_layer_imports,
    check_missing_tr,
    check_mounted_async,
    check_print_statements,
    check_ref_watch_in_callback,
    check_route_ordering,
    check_switch_unknown_case,
    check_with_opacity,
    collect_known_enums,
    is_comment_line,
    is_in_string_literal,
    is_whitelisted,
    parse_anti_patterns_from_claude_md,
)


# ── is_comment_line ───────────────────────────────────────────────────────────


class TestIsCommentLine(unittest.TestCase):
    def test_double_slash_comment(self):
        self.assertTrue(is_comment_line("  // this is a comment"))

    def test_doc_comment(self):
        self.assertTrue(is_comment_line("  /// Documentation comment"))

    def test_block_comment_start(self):
        self.assertTrue(is_comment_line("  /* block comment start */"))

    def test_block_comment_continuation(self):
        self.assertTrue(is_comment_line("   * continuation line"))

    def test_code_line_not_comment(self):
        self.assertFalse(is_comment_line("  final x = 1;"))

    def test_empty_line_not_comment(self):
        self.assertFalse(is_comment_line(""))

    def test_whitespace_only_not_comment(self):
        self.assertFalse(is_comment_line("   "))

    def test_url_in_string_not_comment(self):
        # 'https://example.com' — line starts with code, not comment marker
        self.assertFalse(is_comment_line("  final url = 'https://example.com';"))

    def test_comment_with_leading_spaces(self):
        self.assertTrue(is_comment_line("        // deeply indented comment"))


# ── is_in_string_literal ──────────────────────────────────────────────────────


class TestIsInStringLiteral(unittest.TestCase):
    def test_not_in_string_at_start(self):
        line = "withOpacity(0.5);"
        self.assertFalse(is_in_string_literal(line, 0))

    def test_inside_single_quoted_string(self):
        line = "  final s = 'print(hello)';"
        # Find position of 'print(' inside the single-quoted string
        quote_pos = line.index("'")
        idx = line.index("print(", quote_pos + 1)
        self.assertTrue(is_in_string_literal(line, idx))

    def test_inside_double_quoted_string(self):
        line = '  final s = "print(hello)";'
        quote_pos = line.index('"')
        idx = line.index("print(", quote_pos + 1)
        self.assertTrue(is_in_string_literal(line, idx))

    def test_not_in_string_before_any_quote(self):
        line = "  print('hello');"
        # print( starts before the quote
        self.assertFalse(is_in_string_literal(line, 2))

    def test_after_closed_string_not_in_string(self):
        line = "  var x = 'closed'; print('x');"
        # The second print( — after the string is already closed
        second_print_idx = line.rindex("print(")
        # This should NOT be inside a string (it's after the closed 'closed' string)
        # Count quotes before position: 2 single quotes = even = not in string
        self.assertFalse(is_in_string_literal(line, second_print_idx))


# ── Finding dataclass ─────────────────────────────────────────────────────────


class TestFindingDataclass(unittest.TestCase):
    def test_default_severity_is_error(self):
        f = Finding(file="test.dart", line_num=10, line_text="  print('x');", suggestion="Use AppLogger")
        self.assertEqual(f.severity, "error")

    def test_warning_severity(self):
        f = Finding(
            file="test.dart",
            line_num=5,
            line_text="some line",
            suggestion="fix it",
            severity="warning",
        )
        self.assertEqual(f.severity, "warning")

    def test_all_fields_accessible(self):
        f = Finding(file="lib/foo.dart", line_num=42, line_text="  bad_code();", suggestion="use good code")
        self.assertEqual(f.file, "lib/foo.dart")
        self.assertEqual(f.line_num, 42)
        self.assertEqual(f.line_text, "  bad_code();")
        self.assertEqual(f.suggestion, "use good code")


# ── Category dataclass ────────────────────────────────────────────────────────


class TestCategoryDataclass(unittest.TestCase):
    def test_empty_findings_by_default(self):
        cat = Category(name="Test", tag="[Test]", description="desc")
        self.assertEqual(cat.findings, [])

    def test_default_severity_is_error(self):
        cat = Category(name="Test", tag="[Test]", description="desc")
        self.assertEqual(cat.severity, "error")

    def test_warning_severity(self):
        cat = Category(name="Test", tag="[Test]", description="desc", severity="warning")
        self.assertEqual(cat.severity, "warning")

    def test_findings_are_independent_per_instance(self):
        cat1 = Category(name="A", tag="[A]", description="desc")
        cat2 = Category(name="B", tag="[B]", description="desc")
        cat1.findings.append(Finding(file="f.dart", line_num=1, line_text="x", suggestion="y"))
        self.assertEqual(len(cat1.findings), 1)
        self.assertEqual(len(cat2.findings), 0)

    def test_add_finding(self):
        cat = Category(name="Print", tag="[print]", description="print() kullanimi")
        cat.findings.append(
            Finding(file="lib/foo.dart", line_num=5, line_text="  print('x');", suggestion="AppLogger kullan")
        )
        self.assertEqual(len(cat.findings), 1)
        self.assertEqual(cat.findings[0].file, "lib/foo.dart")


# ── is_whitelisted ────────────────────────────────────────────────────────────


class TestIsWhitelisted(unittest.TestCase):
    def test_admin_path_whitelisted_for_context_go(self):
        p = Path("lib/features/admin/screens/admin_screen.dart")
        self.assertTrue(is_whitelisted("check_context_go_forward_nav", p))

    def test_auth_path_whitelisted_for_context_go(self):
        p = Path("lib/features/auth/screens/login_screen.dart")
        self.assertTrue(is_whitelisted("check_context_go_forward_nav", p))

    def test_birds_path_not_whitelisted_for_context_go(self):
        p = Path("lib/features/birds/screens/bird_list_screen.dart")
        self.assertFalse(is_whitelisted("check_context_go_forward_nav", p))

    def test_genetics_utils_whitelisted_for_hardcoded_colors(self):
        p = Path("lib/features/genetics/utils/budgie_color_resolver.dart")
        self.assertTrue(is_whitelisted("check_hardcoded_colors", p))

    def test_birds_not_whitelisted_for_hardcoded_colors(self):
        p = Path("lib/features/birds/screens/bird_form_screen.dart")
        self.assertFalse(is_whitelisted("check_hardcoded_colors", p))

    def test_unknown_checker_never_whitelisted(self):
        p = Path("lib/features/admin/screens/admin_screen.dart")
        self.assertFalse(is_whitelisted("check_nonexistent_checker", p))

    def test_empty_whitelist_for_checker(self):
        # check_with_opacity has no whitelist entries
        p = Path("lib/features/birds/screens/bird_list_screen.dart")
        self.assertFalse(is_whitelisted("check_with_opacity", p))


# ── parse_anti_patterns_from_claude_md ────────────────────────────────────────


class TestParseAntiPatternsFromClaudeMd(unittest.TestCase):
    def test_returns_list(self):
        result = parse_anti_patterns_from_claude_md()
        self.assertIsInstance(result, list)

    def test_returns_patterns_when_file_exists(self):
        import verify_code_quality as vcq

        if vcq.CLAUDE_MD.exists():
            result = parse_anti_patterns_from_claude_md()
            self.assertGreater(len(result), 0)

    def test_returns_empty_for_missing_file(self):
        import verify_code_quality as vcq

        original = vcq.CLAUDE_MD
        vcq.CLAUDE_MD = Path("/nonexistent/CLAUDE.md")
        try:
            result = parse_anti_patterns_from_claude_md()
        finally:
            vcq.CLAUDE_MD = original
        self.assertEqual(result, [])

    def test_all_patterns_start_with_number(self):
        import verify_code_quality as vcq

        if not vcq.CLAUDE_MD.exists():
            return
        result = parse_anti_patterns_from_claude_md()
        for pattern in result:
            self.assertTrue(
                pattern.strip()[0].isdigit(),
                f"Pattern sayi ile baslamali: {pattern!r}",
            )

    def test_returns_empty_when_section_missing(self):
        """Critical Anti-Patterns bolumu olmayan dosyada bos liste donmeli."""
        import verify_code_quality as vcq

        tmp = tempfile.NamedTemporaryFile(
            mode="w", suffix=".md", delete=False, encoding="utf-8"
        )
        tmp.write("# CLAUDE.md\n\n## Some Other Section\n\nsome content\n")
        tmp.close()
        original = vcq.CLAUDE_MD
        vcq.CLAUDE_MD = Path(tmp.name)
        try:
            result = parse_anti_patterns_from_claude_md()
        finally:
            vcq.CLAUDE_MD = original
        self.assertEqual(result, [])

    def test_section_boundary_stops_parsing(self):
        """Sonraki ## basliginda parse durumali."""
        import verify_code_quality as vcq

        tmp = tempfile.NamedTemporaryFile(
            mode="w", suffix=".md", delete=False, encoding="utf-8"
        )
        tmp.write(
            "# CLAUDE.md\n\n"
            "## Critical Anti-Patterns\n\n"
            "1. `withOpacity()` -> use `withValues(alpha: x)`\n"
            "2. Another pattern\n\n"
            "## Next Section\n\n"
            "3. Should NOT be parsed\n"
        )
        tmp.close()
        original = vcq.CLAUDE_MD
        vcq.CLAUDE_MD = Path(tmp.name)
        try:
            result = parse_anti_patterns_from_claude_md()
        finally:
            vcq.CLAUDE_MD = original
        self.assertEqual(len(result), 2)


# ── Checker Functions ─────────────────────────────────────────────────────────


def _run_checker(checker_fn, lines, filepath=None):
    """Verilen checker'i calistir, Category'yi dondur."""
    if filepath is None:
        filepath = Path("lib/features/birds/screens/bird_list_screen.dart")
    cat = Category(name="test", tag="[test]", description="test checker")
    checker_fn(lines, filepath, cat)
    return cat


class TestCheckPrintStatements(unittest.TestCase):
    def test_detects_plain_print(self):
        lines = ["  print('hello world');"]
        cat = _run_checker(check_print_statements, lines)
        self.assertEqual(len(cat.findings), 1)
        self.assertIn("print", cat.findings[0].line_text)

    def test_ignores_comment_line(self):
        lines = ["  // print('debug info');"]
        cat = _run_checker(check_print_statements, lines)
        self.assertEqual(len(cat.findings), 0)

    def test_ignores_debug_print(self):
        lines = ["  debugPrint('debug message');"]
        cat = _run_checker(check_print_statements, lines)
        self.assertEqual(len(cat.findings), 0)

    def test_ignores_print_in_string(self):
        lines = ["  final msg = 'use print(x) here';"]
        cat = _run_checker(check_print_statements, lines)
        self.assertEqual(len(cat.findings), 0)

    def test_multiple_prints(self):
        lines = ["  print('a');", "  print('b');", "  AppLogger.info('tag', msg);"]
        cat = _run_checker(check_print_statements, lines)
        self.assertEqual(len(cat.findings), 2)

    def test_skips_line_where_debug_print_also_present(self):
        """print( eslesir ama satirda debugPrint de varsa atlaniyor (satir 227)."""
        # 'print(' kelime sinirinda eslesir; ayni satirda debugPrint var → continue
        lines = ["  debugPrint('x'); print('y');"]
        cat = _run_checker(check_print_statements, lines)
        self.assertEqual(len(cat.findings), 0)


class TestCheckWithOpacity(unittest.TestCase):
    def test_detects_with_opacity(self):
        lines = ["  color.withOpacity(0.5),"]
        cat = _run_checker(check_with_opacity, lines)
        self.assertEqual(len(cat.findings), 1)

    def test_ignores_comment(self):
        lines = ["  // color.withOpacity(0.5),"]
        cat = _run_checker(check_with_opacity, lines)
        self.assertEqual(len(cat.findings), 0)

    def test_ignores_with_values(self):
        lines = ["  color.withValues(alpha: 0.5),"]
        cat = _run_checker(check_with_opacity, lines)
        self.assertEqual(len(cat.findings), 0)

    def test_ignores_in_string(self):
        lines = ["  final s = '.withOpacity(0.5)';"]
        cat = _run_checker(check_with_opacity, lines)
        self.assertEqual(len(cat.findings), 0)

    def test_finding_has_correct_line_num(self):
        lines = ["  final x = 1;", "  color.withOpacity(0.3),"]
        cat = _run_checker(check_with_opacity, lines)
        self.assertEqual(len(cat.findings), 1)
        self.assertEqual(cat.findings[0].line_num, 2)


class TestCheckIconIcons(unittest.TestCase):
    def test_detects_icon_icons(self):
        lines = ["  Icon(Icons.add),"]
        cat = _run_checker(check_icon_icons, lines)
        self.assertEqual(len(cat.findings), 1)

    def test_ignores_lucide_icons(self):
        lines = ["  Icon(LucideIcons.add),"]
        cat = _run_checker(check_icon_icons, lines)
        self.assertEqual(len(cat.findings), 0)

    def test_ignores_app_icon(self):
        lines = ["  AppIcon(AppIcons.bird),"]
        cat = _run_checker(check_icon_icons, lines)
        self.assertEqual(len(cat.findings), 0)

    def test_ignores_comment(self):
        lines = ["  // Icon(Icons.add),"]
        cat = _run_checker(check_icon_icons, lines)
        self.assertEqual(len(cat.findings), 0)

    def test_skips_app_icon_dart_file(self):
        lines = ["  Icon(Icons.add),"]
        cat = _run_checker(check_icon_icons, lines, Path("lib/core/widgets/app_icon.dart"))
        self.assertEqual(len(cat.findings), 0)


class TestCheckMissingTr(unittest.TestCase):
    """check_missing_tr: features/ veya screens/ yolunda hardcoded labelText/hintText."""

    FEATURES_PATH = Path("lib/features/birds/screens/bird_form_screen.dart")
    CORE_PATH = Path("lib/core/widgets/some_widget.dart")

    def test_detects_hardcoded_label_text(self):
        lines = ["  labelText: 'Bird Name',"]
        cat = _run_checker(check_missing_tr, lines, self.FEATURES_PATH)
        self.assertEqual(len(cat.findings), 1)

    def test_ignores_localized_label_text(self):
        lines = ["  labelText: 'birds.name'.tr(),"]
        cat = _run_checker(check_missing_tr, lines, self.FEATURES_PATH)
        self.assertEqual(len(cat.findings), 0)

    def test_ignores_value_with_dot_as_key(self):
        # 'birds.name' contains a dot — treated as already a key reference
        lines = ["  labelText: 'birds.name',"]
        cat = _run_checker(check_missing_tr, lines, self.FEATURES_PATH)
        self.assertEqual(len(cat.findings), 0)

    def test_detects_hardcoded_hint_text(self):
        lines = ["  hintText: 'Enter name',"]
        cat = _run_checker(check_missing_tr, lines, self.FEATURES_PATH)
        self.assertEqual(len(cat.findings), 1)

    def test_skips_non_feature_files(self):
        lines = ["  labelText: 'Bird Name',"]
        cat = _run_checker(check_missing_tr, lines, self.CORE_PATH)
        self.assertEqual(len(cat.findings), 0)


class TestCheckRefWatchInCallback(unittest.TestCase):
    def test_detects_ref_watch_in_on_pressed(self):
        lines = [
            "  onPressed: () {",
            "    final x = ref.watch(someProvider);",
            "  },",
        ]
        cat = _run_checker(check_ref_watch_in_callback, lines)
        self.assertEqual(len(cat.findings), 1)

    def test_ignores_ref_watch_in_build(self):
        # ref.watch() in build() is correct — not inside a callback
        lines = [
            "  Widget build(BuildContext context, WidgetRef ref) {",
            "    final birds = ref.watch(birdsStreamProvider(userId));",
            "  }",
        ]
        cat = _run_checker(check_ref_watch_in_callback, lines)
        self.assertEqual(len(cat.findings), 0)

    def test_ignores_ref_watch_in_comment(self):
        lines = [
            "  onPressed: () {",
            "    // ref.watch(provider) — don't do this",
            "  },",
        ]
        cat = _run_checker(check_ref_watch_in_callback, lines)
        self.assertEqual(len(cat.findings), 0)

    def test_detects_on_tap_callback(self):
        lines = [
            "  onTap: () {",
            "    final x = ref.watch(provider);",
            "  },",
        ]
        cat = _run_checker(check_ref_watch_in_callback, lines)
        self.assertEqual(len(cat.findings), 1)


class TestCheckHardcodedColors(unittest.TestCase):
    NORMAL_PATH = Path("lib/features/birds/screens/bird_list_screen.dart")
    COLORS_PATH = Path("lib/core/theme/app_colors.dart")
    THEME_PATH = Path("lib/core/theme/app_theme.dart")

    def test_detects_hardcoded_color(self):
        lines = ["  color: Colors.red,"]
        cat = _run_checker(check_hardcoded_colors, lines, self.NORMAL_PATH)
        self.assertEqual(len(cat.findings), 1)

    def test_ignores_transparent(self):
        lines = ["  color: Colors.transparent,"]
        cat = _run_checker(check_hardcoded_colors, lines, self.NORMAL_PATH)
        self.assertEqual(len(cat.findings), 0)

    def test_ignores_white_and_black(self):
        lines = ["  color: Colors.white,", "  color: Colors.black,"]
        cat = _run_checker(check_hardcoded_colors, lines, self.NORMAL_PATH)
        self.assertEqual(len(cat.findings), 0)

    def test_ignores_comment(self):
        lines = ["  // Colors.red should not be used here"]
        cat = _run_checker(check_hardcoded_colors, lines, self.NORMAL_PATH)
        self.assertEqual(len(cat.findings), 0)

    def test_ignores_in_string(self):
        lines = ["  final hint = 'avoid Colors.red in production';"]
        cat = _run_checker(check_hardcoded_colors, lines, self.NORMAL_PATH)
        self.assertEqual(len(cat.findings), 0)

    def test_skips_app_colors_dart(self):
        lines = ["  static const Color primary = Colors.blue;"]
        cat = _run_checker(check_hardcoded_colors, lines, self.COLORS_PATH)
        self.assertEqual(len(cat.findings), 0)

    def test_skips_app_theme_dart(self):
        lines = ["  backgroundColor: Colors.green,"]
        cat = _run_checker(check_hardcoded_colors, lines, self.THEME_PATH)
        self.assertEqual(len(cat.findings), 0)

    def test_ignores_import_lines(self):
        lines = ["import 'package:flutter/material.dart'; // provides Colors"]
        cat = _run_checker(check_hardcoded_colors, lines, self.NORMAL_PATH)
        self.assertEqual(len(cat.findings), 0)

    def test_ignores_import_line_with_colors_reference(self):
        """import satirinda Colors.xxx referansi varsa atlaniyor (satir 268)."""
        # Regex Colors.red'i bulur ama satir import ile basliyor → continue
        lines = ["import 'pkg/material.dart'; // see Colors.red palette example"]
        cat = _run_checker(check_hardcoded_colors, lines, self.NORMAL_PATH)
        self.assertEqual(len(cat.findings), 0)


class TestCheckDriftEquals(unittest.TestCase):
    DAO_PATH = Path("lib/data/local/database/daos/birds_dao.dart")
    NON_DAO_PATH = Path("lib/features/birds/screens/bird_list_screen.dart")

    def test_detects_gender_equals_in_dao(self):
        lines = ["    ..where((t) => t.gender.equals(gender))"]
        cat = _run_checker(check_drift_equals, lines, self.DAO_PATH)
        self.assertEqual(len(cat.findings), 1)

    def test_detects_status_equals_in_dao(self):
        lines = ["    ..where((t) => t.status.equals(status))"]
        cat = _run_checker(check_drift_equals, lines, self.DAO_PATH)
        self.assertEqual(len(cat.findings), 1)

    def test_ignores_user_id_equals(self):
        lines = ["    ..where((t) => t.userId.equals(userId))"]
        cat = _run_checker(check_drift_equals, lines, self.DAO_PATH)
        self.assertEqual(len(cat.findings), 0)

    def test_ignores_is_deleted_equals(self):
        lines = ["    ..where((t) => t.isDeleted.equals(false))"]
        cat = _run_checker(check_drift_equals, lines, self.DAO_PATH)
        self.assertEqual(len(cat.findings), 0)

    def test_ignores_string_literal_value(self):
        # .equals('male') — string literal means plain text column, not enum
        lines = ["    ..where((t) => t.gender.equals('male'))"]
        cat = _run_checker(check_drift_equals, lines, self.DAO_PATH)
        self.assertEqual(len(cat.findings), 0)

    def test_skips_non_dao_files(self):
        lines = ["    t.status.equals(status)"]
        cat = _run_checker(check_drift_equals, lines, self.NON_DAO_PATH)
        self.assertEqual(len(cat.findings), 0)


class TestCheckFreezed3Pattern(unittest.TestCase):
    MODEL_PATH = Path("lib/data/models/bird_model.dart")

    def test_detects_non_abstract_freezed_class(self):
        lines = [
            "@freezed",
            "class Bird with _$Bird {",
        ]
        cat = _run_checker(check_freezed3_pattern, lines, self.MODEL_PATH)
        self.assertEqual(len(cat.findings), 1)

    def test_ignores_abstract_freezed_class(self):
        lines = [
            "@freezed",
            "abstract class Bird with _$Bird {",
        ]
        cat = _run_checker(check_freezed3_pattern, lines, self.MODEL_PATH)
        self.assertEqual(len(cat.findings), 0)

    def test_no_freezed_annotation_no_finding(self):
        lines = [
            "class Bird {",
            "  final String id;",
            "}",
        ]
        cat = _run_checker(check_freezed3_pattern, lines, self.MODEL_PATH)
        self.assertEqual(len(cat.findings), 0)

    def test_freezed_with_blank_line_between(self):
        lines = [
            "@freezed",
            "",
            "class Bird with _$Bird {",
        ]
        cat = _run_checker(check_freezed3_pattern, lines, self.MODEL_PATH)
        self.assertEqual(len(cat.findings), 1)

    def test_freezed_with_comment_between_is_ignored(self):
        lines = [
            "@freezed",
            "// This is a model",
            "class Bird with _$Bird {",
        ]
        cat = _run_checker(check_freezed3_pattern, lines, self.MODEL_PATH)
        # The look-ahead skips comment lines, so still detects
        self.assertEqual(len(cat.findings), 1)


# main() entegrasyon testleri test_code_quality_main.py dosyasina tasindi.


class TestCheckHardcodedSpacing(unittest.TestCase):
    NORMAL_PATH = Path("lib/features/birds/screens/bird_list_screen.dart")
    SPACING_PATH = Path("lib/core/theme/app_spacing.dart")

    def test_detects_edgeinsets_with_hardcoded_value(self):
        lines = ["  padding: EdgeInsets.all(16.0),"]
        cat = _run_checker(check_hardcoded_spacing, lines, self.NORMAL_PATH)
        self.assertEqual(len(cat.findings), 1)

    def test_detects_sizedbox_height_hardcoded(self):
        lines = ["  SizedBox(height: 8.0),"]
        cat = _run_checker(check_hardcoded_spacing, lines, self.NORMAL_PATH)
        self.assertEqual(len(cat.findings), 1)

    def test_ignores_when_appspacing_present(self):
        lines = ["  padding: EdgeInsets.all(AppSpacing.lg),"]
        cat = _run_checker(check_hardcoded_spacing, lines, self.NORMAL_PATH)
        self.assertEqual(len(cat.findings), 0)

    def test_ignores_comment_line(self):
        lines = ["  // EdgeInsets.all(16.0) is equivalent to AppSpacing.lg"]
        cat = _run_checker(check_hardcoded_spacing, lines, self.NORMAL_PATH)
        self.assertEqual(len(cat.findings), 0)

    def test_skips_app_spacing_dart(self):
        lines = ["  static const double lg = 16.0;"]
        cat = _run_checker(check_hardcoded_spacing, lines, self.SPACING_PATH)
        self.assertEqual(len(cat.findings), 0)

    def test_ignores_hardcoded_value_when_appspacing_also_on_line(self):
        """EdgeInsets(16.0) eslesir ama satirda AppSpacing da varsa atlaniyor (satir 387)."""
        # spacing_values'de '16.0' var; satirda AppSpacing da mevcut → continue (satir 387)
        lines = ["  EdgeInsets.all(16.0), // was AppSpacing.lg = 16.0"]
        cat = _run_checker(check_hardcoded_spacing, lines, self.NORMAL_PATH)
        self.assertEqual(len(cat.findings), 0)


class TestCheckDropdownValue(unittest.TestCase):
    NORMAL_PATH = Path("lib/features/birds/widgets/bird_form.dart")

    def test_detects_value_in_dropdown(self):
        lines = [
            "  DropdownButtonFormField<String>(",
            "    value: _selected,",
            "  ),",
        ]
        cat = _run_checker(check_dropdown_value, lines, self.NORMAL_PATH)
        self.assertEqual(len(cat.findings), 1)

    def test_ignores_initial_value(self):
        lines = [
            "  DropdownButtonFormField<String>(",
            "    initialValue: _selected,",
            "  ),",
        ]
        cat = _run_checker(check_dropdown_value, lines, self.NORMAL_PATH)
        self.assertEqual(len(cat.findings), 0)

    def test_ignores_value_in_dropdown_menu_item(self):
        lines = [
            "  DropdownButtonFormField<String>(",
            "    items: genders.map((g) => DropdownMenuItem(value: g.name)).toList(),",
            "  ),",
        ]
        cat = _run_checker(check_dropdown_value, lines, self.NORMAL_PATH)
        self.assertEqual(len(cat.findings), 0)

    def test_ignores_comment_line(self):
        lines = [
            "  DropdownButtonFormField<String>(",
            "    // value: _selected,  deprecated — use initialValue",
            "  ),",
        ]
        cat = _run_checker(check_dropdown_value, lines, self.NORMAL_PATH)
        self.assertEqual(len(cat.findings), 0)


class TestCheckContextGoForwardNav(unittest.TestCase):
    NORMAL_PATH = Path("lib/features/birds/screens/bird_list_screen.dart")
    ADMIN_PATH = Path("lib/features/admin/screens/admin_dashboard_screen.dart")
    AUTH_PATH = Path("lib/features/auth/screens/login_screen.dart")

    def test_detects_context_go_in_normal_file(self):
        lines = ["  context.go('/birds');"]
        cat = _run_checker(check_context_go_forward_nav, lines, self.NORMAL_PATH)
        self.assertEqual(len(cat.findings), 1)

    def test_ignores_context_go_in_admin(self):
        lines = ["  context.go('/admin/dashboard');"]
        cat = _run_checker(check_context_go_forward_nav, lines, self.ADMIN_PATH)
        self.assertEqual(len(cat.findings), 0)

    def test_ignores_context_go_in_auth(self):
        lines = ["  context.go('/');"]
        cat = _run_checker(check_context_go_forward_nav, lines, self.AUTH_PATH)
        self.assertEqual(len(cat.findings), 0)

    def test_ignores_comment_line(self):
        lines = ["  // context.go('/birds') — use push instead"]
        cat = _run_checker(check_context_go_forward_nav, lines, self.NORMAL_PATH)
        self.assertEqual(len(cat.findings), 0)

    def test_ignores_in_string_literal(self):
        lines = ["  final hint = 'use context.go() for tab switches';"]
        cat = _run_checker(check_context_go_forward_nav, lines, self.NORMAL_PATH)
        self.assertEqual(len(cat.findings), 0)


# ── check_icondata_param ──────────────────────────────────────────────────────


class TestCheckIcondataParam(unittest.TestCase):
    CORE_WIDGETS_PATH = Path("lib/core/widgets/stat_card.dart")
    NON_WIDGETS_PATH = Path("lib/features/birds/widgets/bird_card.dart")

    def test_detects_icondata_param_in_core_widgets(self):
        lines = ["  final IconData icon;"]
        cat = _run_checker(check_icondata_param, lines, self.CORE_WIDGETS_PATH)
        self.assertEqual(len(cat.findings), 1)
        self.assertIn("IconData", cat.findings[0].line_text)

    def test_no_finding_when_widget_param(self):
        lines = ["  final Widget icon;"]
        cat = _run_checker(check_icondata_param, lines, self.CORE_WIDGETS_PATH)
        self.assertEqual(len(cat.findings), 0)

    def test_skips_non_core_widgets_file(self):
        lines = ["  final IconData icon;"]
        cat = _run_checker(check_icondata_param, lines, self.NON_WIDGETS_PATH)
        self.assertEqual(len(cat.findings), 0)

    def test_ignores_comment_line(self):
        lines = ["  // final IconData icon — use Widget instead"]
        cat = _run_checker(check_icondata_param, lines, self.CORE_WIDGETS_PATH)
        self.assertEqual(len(cat.findings), 0)


# ── collect_known_enums ────────────────────────────────────────────────────────


class TestCollectKnownEnums(unittest.TestCase):
    def test_collects_enum_names_from_files(self):
        import verify_code_quality as vcq

        with tempfile.TemporaryDirectory() as d:
            enums_dir = Path(d) / "lib" / "core" / "enums"
            enums_dir.mkdir(parents=True)
            (enums_dir / "bird_enums.dart").write_text(
                "enum BirdGender { male, female, unknown; }\n"
                "enum BirdStatus { alive, dead, unknown; }\n",
                encoding="utf-8",
            )
            with patch.object(vcq, "LIB_DIR", Path(d) / "lib"):
                result = vcq.collect_known_enums()
        self.assertIn("BirdGender", result)
        self.assertIn("BirdStatus", result)

    def test_returns_empty_set_when_enums_dir_missing(self):
        import verify_code_quality as vcq

        with patch.object(vcq, "LIB_DIR", Path("/nonexistent/lib")):
            result = vcq.collect_known_enums()
        self.assertEqual(result, set())

    def test_skips_excluded_suffix_files(self):
        """Generated .freezed.dart dosyalari atlaniyor (satir 205)."""
        import verify_code_quality as vcq

        with tempfile.TemporaryDirectory() as d:
            enums_dir = Path(d) / "lib" / "core" / "enums"
            enums_dir.mkdir(parents=True)
            # Generated dosya — EXCLUDED_SUFFIXES icinde
            (enums_dir / "bird_enums.freezed.dart").write_text(
                "enum FreezeEnum { a, b; }\n", encoding="utf-8"
            )
            with patch.object(vcq, "LIB_DIR", Path(d) / "lib"):
                result = vcq.collect_known_enums()
        # Generated dosya atlandi, enum toplanmadi
        self.assertNotIn("FreezeEnum", result)

    def test_handles_unreadable_file_gracefully(self):
        """Okunamayan dosya except blogu (satir 210-211) ile atlaniyor."""
        import verify_code_quality as vcq
        from unittest.mock import MagicMock

        with tempfile.TemporaryDirectory() as d:
            enums_dir = Path(d) / "lib" / "core" / "enums"
            enums_dir.mkdir(parents=True)
            bad_file = enums_dir / "broken_enums.dart"
            bad_file.touch()
            # Path.read_text'i exception atacak sekilde patch et
            original_read = Path.read_text

            def _mock_read(self, *args, **kwargs):
                if self.name == "broken_enums.dart":
                    raise OSError("permission denied")
                return original_read(self, *args, **kwargs)

            with patch.object(vcq, "LIB_DIR", Path(d) / "lib"), \
                 patch.object(Path, "read_text", _mock_read):
                result = vcq.collect_known_enums()
        # Hata yutulur, sonuc bos set veya baska dosyalardan toplanan degerler
        self.assertIsInstance(result, set)


# ── check_bare_catch ──────────────────────────────────────────────────────────


class TestCheckBareCatch(unittest.TestCase):
    NORMAL_PATH = Path("lib/features/birds/providers/bird_form_providers.dart")

    def test_detects_catch_without_logging(self):
        lines = [
            "  } catch (e) {",
            "    showDialog(context, title: 'Hata');",
            "  }",
        ]
        cat = _run_checker(check_bare_catch, lines, self.NORMAL_PATH)
        self.assertEqual(len(cat.findings), 1)

    def test_no_finding_when_applogger_present(self):
        lines = [
            "  } catch (e, st) {",
            "    AppLogger.error('tag', e, st);",
            "  }",
        ]
        cat = _run_checker(check_bare_catch, lines, self.NORMAL_PATH)
        self.assertEqual(len(cat.findings), 0)

    def test_no_finding_when_sentry_present(self):
        lines = [
            "  } catch (e, st) {",
            "    Sentry.captureException(e, stackTrace: st);",
            "  }",
        ]
        cat = _run_checker(check_bare_catch, lines, self.NORMAL_PATH)
        self.assertEqual(len(cat.findings), 0)

    def test_no_finding_when_rethrow(self):
        lines = [
            "  } catch (e) {",
            "    rethrow;",
            "  }",
        ]
        cat = _run_checker(check_bare_catch, lines, self.NORMAL_PATH)
        self.assertEqual(len(cat.findings), 0)

    def test_no_finding_when_state_update(self):
        lines = [
            "  } catch (e) {",
            "    state = state.copyWith(error: e.toString());",
            "  }",
        ]
        cat = _run_checker(check_bare_catch, lines, self.NORMAL_PATH)
        self.assertEqual(len(cat.findings), 0)

    def test_no_finding_when_state_direct_assign(self):
        """'state = x' (copyWith olmadan) icin satir 689 continue calisir.

        Bytecode analizi: 'state = state.copyWith(' True ise POP_JUMP_IF_TRUE 10 ile
        dogrudan loop basina atlar (satir 689 atlaniyor). Satir 689'a ulasmak icin
        ilk kontrol False, ikinci ('state =') True olmali.
        """
        lines = [
            "  } catch (e) {",
            "    state = BirdFormState();",  # 'state =' True, 'state = state.copyWith(' False
            "  }",
        ]
        cat = _run_checker(check_bare_catch, lines, self.NORMAL_PATH)
        self.assertEqual(len(cat.findings), 0)

    def test_no_finding_when_handle_error(self):
        lines = [
            "  } catch (e, st) {",
            "    _handleError(e, st);",
            "  }",
        ]
        cat = _run_checker(check_bare_catch, lines, self.NORMAL_PATH)
        self.assertEqual(len(cat.findings), 0)

    def test_ignores_comment_line(self):
        lines = [
            "  // } catch (e) { handle silently",
        ]
        cat = _run_checker(check_bare_catch, lines, self.NORMAL_PATH)
        self.assertEqual(len(cat.findings), 0)


# ── check_mounted_async ────────────────────────────────────────────────────────


class TestCheckMountedAsync(unittest.TestCase):
    NORMAL_PATH = Path("lib/features/birds/screens/bird_form_screen.dart")

    def test_detects_setstate_after_await_without_mounted(self):
        lines = [
            "class _State extends ConsumerStatefulWidget {",
            "  Future<void> _load() async {",
            "    await someAsyncCall();",
            "    setState(() { _loaded = true; });",
            "  }",
            "}",
        ]
        cat = _run_checker(check_mounted_async, lines, self.NORMAL_PATH)
        self.assertEqual(len(cat.findings), 1)

    def test_no_finding_when_mounted_checked_inline(self):
        lines = [
            "class _State extends ConsumerStatefulWidget {",
            "  Future<void> _load() async {",
            "    await someAsyncCall();",
            "    if (mounted) setState(() { _loaded = true; });",
            "  }",
            "}",
        ]
        cat = _run_checker(check_mounted_async, lines, self.NORMAL_PATH)
        self.assertEqual(len(cat.findings), 0)

    def test_no_finding_when_mounted_checked_before(self):
        lines = [
            "class _State extends ConsumerStatefulWidget {",
            "  Future<void> _load() async {",
            "    await someAsyncCall();",
            "    if (!mounted) return;",
            "    setState(() { _loaded = true; });",
            "  }",
            "}",
        ]
        cat = _run_checker(check_mounted_async, lines, self.NORMAL_PATH)
        self.assertEqual(len(cat.findings), 0)

    def test_skips_non_consumer_stateful_widget(self):
        lines = [
            "class _State extends StatefulWidget {",
            "  Future<void> _load() async {",
            "    await someAsyncCall();",
            "    setState(() { _loaded = true; });",
            "  }",
            "}",
        ]
        cat = _run_checker(check_mounted_async, lines, self.NORMAL_PATH)
        self.assertEqual(len(cat.findings), 0)

    def test_resets_on_method_boundary(self):
        lines = [
            "class _State extends ConsumerStatefulWidget {",
            "  Future<void> _first() async {",
            "    await someAsyncCall();",
            "  }",
            "  void _second() {",
            "    setState(() {});",  # no await before this — reset on boundary
            "  }",
            "}",
        ]
        cat = _run_checker(check_mounted_async, lines, self.NORMAL_PATH)
        self.assertEqual(len(cat.findings), 0)


# ── check_dao_import_app_database ─────────────────────────────────────────────


class TestCheckDaoImportAppDatabase(unittest.TestCase):
    DAO_PATH = Path("lib/data/local/database/daos/birds_dao.dart")
    NON_DAO_PATH = Path("lib/features/birds/screens/bird_list_screen.dart")

    def test_detects_missing_direct_table_import(self):
        lines = [
            "@DriftAccessor(tables: [BirdsTable])",
            "class BirdsDao extends DatabaseAccessor<AppDatabase> with _$BirdsDaoMixin {",
            "  BirdsDao(super.db);",
            "}",
        ]
        cat = _run_checker(check_dao_import_app_database, lines, self.DAO_PATH)
        self.assertEqual(len(cat.findings), 1)

    def test_no_finding_when_direct_table_import_present(self):
        lines = [
            "import 'package:app/data/local/database/tables/birds_table.dart';",
            "@DriftAccessor(tables: [BirdsTable])",
            "class BirdsDao extends DatabaseAccessor<AppDatabase> with _$BirdsDaoMixin {",
            "}",
        ]
        cat = _run_checker(check_dao_import_app_database, lines, self.DAO_PATH)
        self.assertEqual(len(cat.findings), 0)

    def test_skips_non_dao_file(self):
        lines = [
            "@DriftAccessor(tables: [BirdsTable])",
            "class BirdsDao {}",
        ]
        cat = _run_checker(check_dao_import_app_database, lines, self.NON_DAO_PATH)
        self.assertEqual(len(cat.findings), 0)

    def test_skips_dao_without_drift_accessor(self):
        lines = [
            "class BirdsDao extends DatabaseAccessor<AppDatabase> {",
            "}",
        ]
        cat = _run_checker(check_dao_import_app_database, lines, self.DAO_PATH)
        self.assertEqual(len(cat.findings), 0)

    def test_no_finding_with_tables_in_import_path(self):
        lines = [
            "import '../tables/birds_table.dart';",
            "@DriftAccessor(tables: [BirdsTable])",
            "class BirdsDao {}",
        ]
        cat = _run_checker(check_dao_import_app_database, lines, self.DAO_PATH)
        self.assertEqual(len(cat.findings), 0)


# ── check_switch_unknown_case ──────────────────────────────────────────────────


class TestCheckSwitchUnknownCase(unittest.TestCase):
    MODEL_PATH = Path("lib/data/models/bird_model.dart")
    ENUM_PATH = Path("lib/core/enums/bird_enums.dart")
    NON_MODEL_PATH = Path("lib/features/birds/screens/bird_list_screen.dart")

    def test_detects_switch_without_unknown_in_model(self):
        lines = [
            "extension BirdX on Bird {",
            "  String get label => switch (gender) {",
            "    BirdGender.male => 'Erkek',",
            "    BirdGender.female => 'Disi',",
            "  };",
            "}",
        ]
        cat = _run_checker(check_switch_unknown_case, lines, self.MODEL_PATH)
        self.assertEqual(len(cat.findings), 1)

    def test_no_finding_when_unknown_present(self):
        lines = [
            "extension BirdX on Bird {",
            "  String get label => switch (gender) {",
            "    BirdGender.male => 'Erkek',",
            "    BirdGender.female => 'Disi',",
            "    BirdGender.unknown => 'Bilinmiyor',",
            "  };",
            "}",
        ]
        cat = _run_checker(check_switch_unknown_case, lines, self.MODEL_PATH)
        self.assertEqual(len(cat.findings), 0)

    def test_detects_in_enum_file(self):
        lines = [
            "enum BirdGender {",
            "  male, female;",
            "  String toJson() => switch (this) {",
            "    BirdGender.male => 'male',",
            "    BirdGender.female => 'female',",
            "  };",
            "}",
        ]
        cat = _run_checker(check_switch_unknown_case, lines, self.ENUM_PATH)
        self.assertEqual(len(cat.findings), 1)

    def test_skips_non_model_non_enum_file(self):
        lines = [
            "switch (filter) {",
            "  case BirdFilter.all: return birds;",
            "}",
        ]
        cat = _run_checker(check_switch_unknown_case, lines, self.NON_MODEL_PATH)
        self.assertEqual(len(cat.findings), 0)

    def test_ignores_comment_with_switch(self):
        lines = [
            "// switch (gender) { without unknown case }",
        ]
        cat = _run_checker(check_switch_unknown_case, lines, self.MODEL_PATH)
        self.assertEqual(len(cat.findings), 0)


# ── check_route_ordering ───────────────────────────────────────────────────────


class TestCheckRouteOrdering(unittest.TestCase):
    ROUTER_PATH = Path("lib/router/app_router.dart")
    NON_ROUTER_PATH = Path("lib/features/birds/screens/bird_list_screen.dart")

    def test_detects_param_route_before_specific(self):
        lines = [
            "  routes: [",
            "    GoRoute(path: ':id', builder: ...),",
            "    GoRoute(path: 'form', builder: ...),",
            "  ],",
        ]
        cat = _run_checker(check_route_ordering, lines, self.ROUTER_PATH)
        self.assertEqual(len(cat.findings), 1)

    def test_no_finding_with_correct_ordering(self):
        lines = [
            "  routes: [",
            "    GoRoute(path: 'form', builder: ...),",
            "    GoRoute(path: ':id', builder: ...),",
            "  ],",
        ]
        cat = _run_checker(check_route_ordering, lines, self.ROUTER_PATH)
        self.assertEqual(len(cat.findings), 0)

    def test_skips_non_router_file(self):
        lines = [
            "  routes: [",
            "    GoRoute(path: ':id', builder: ...),",
            "    GoRoute(path: 'form', builder: ...),",
            "  ],",
        ]
        cat = _run_checker(check_route_ordering, lines, self.NON_ROUTER_PATH)
        self.assertEqual(len(cat.findings), 0)

    def test_no_finding_for_single_route(self):
        lines = [
            "  routes: [",
            "    GoRoute(path: ':id', builder: ...),",
            "  ],",
        ]
        cat = _run_checker(check_route_ordering, lines, self.ROUTER_PATH)
        self.assertEqual(len(cat.findings), 0)


# ── check_layer_imports ────────────────────────────────────────────────────────


class TestCheckLayerImports(unittest.TestCase):
    CORE_PATH = Path("lib/core/widgets/some_widget.dart")
    DATA_PATH = Path("lib/data/repositories/bird_repository.dart")
    FEATURE_PATH = Path("lib/features/birds/screens/bird_list_screen.dart")

    def test_detects_core_importing_features(self):
        lines = [
            "import '../features/birds/providers/bird_providers.dart';",
        ]
        cat = _run_checker(check_layer_imports, lines, self.CORE_PATH)
        self.assertEqual(len(cat.findings), 1)

    def test_detects_data_importing_features(self):
        lines = [
            "import '../features/birds/providers/bird_providers.dart';",
        ]
        cat = _run_checker(check_layer_imports, lines, self.DATA_PATH)
        self.assertEqual(len(cat.findings), 1)

    def test_allows_core_importing_data_models(self):
        lines = [
            "import 'package:budgie_breeding_tracker/data/models/bird_model.dart';",
        ]
        cat = _run_checker(check_layer_imports, lines, self.CORE_PATH)
        self.assertEqual(len(cat.findings), 0)

    def test_skips_feature_layer_file(self):
        lines = [
            "import '../features/other/providers/provider.dart';",
        ]
        cat = _run_checker(check_layer_imports, lines, self.FEATURE_PATH)
        self.assertEqual(len(cat.findings), 0)

    def test_detects_core_importing_data_non_models(self):
        lines = [
            "import 'package:budgie_breeding_tracker/data/repositories/bird_repository.dart';",
        ]
        cat = _run_checker(check_layer_imports, lines, self.CORE_PATH)
        self.assertEqual(len(cat.findings), 1)


# ── check_freezed_private_constructor ─────────────────────────────────────────


class TestCheckFreezedPrivateConstructor(unittest.TestCase):
    MODEL_PATH = Path("lib/data/models/bird_model.dart")
    NON_MODEL_PATH = Path("lib/features/birds/screens/bird_list_screen.dart")

    def test_detects_missing_private_constructor(self):
        lines = [
            "@freezed",
            "abstract class Bird with _$Bird {",
            "  const factory Bird({",
            "    required String id,",
            "  }) = _Bird;",
            "  factory Bird.fromJson(Map<String, dynamic> json) => _$BirdFromJson(json);",
            "}",
        ]
        cat = _run_checker(check_freezed_private_constructor, lines, self.MODEL_PATH)
        self.assertEqual(len(cat.findings), 1)

    def test_no_finding_when_private_constructor_present(self):
        lines = [
            "@freezed",
            "abstract class Bird with _$Bird {",
            "  const Bird._();",
            "  const factory Bird({",
            "    required String id,",
            "  }) = _Bird;",
            "  factory Bird.fromJson(Map<String, dynamic> json) => _$BirdFromJson(json);",
            "}",
        ]
        cat = _run_checker(check_freezed_private_constructor, lines, self.MODEL_PATH)
        self.assertEqual(len(cat.findings), 0)

    def test_skips_non_model_file(self):
        lines = [
            "@freezed",
            "abstract class SomeForm with _$SomeForm {",
            "  const factory SomeForm() = _SomeForm;",
            "}",
        ]
        cat = _run_checker(check_freezed_private_constructor, lines, self.NON_MODEL_PATH)
        self.assertEqual(len(cat.findings), 0)

    def test_skips_model_without_freezed_annotation(self):
        lines = [
            "abstract class Bird {",
            "  const Bird._();",
            "}",
        ]
        cat = _run_checker(check_freezed_private_constructor, lines, self.MODEL_PATH)
        self.assertEqual(len(cat.findings), 0)


# ── check_missing_tr ──────────────────────────────────────────────────────────


class TestCheckMissingTr(unittest.TestCase):
    FEATURES_PATH = Path("lib/features/birds/widgets/bird_form.dart")
    NON_FEATURES_PATH = Path("lib/core/widgets/shared_widget.dart")

    def test_detects_hardcoded_label_text(self):
        lines = ["  labelText: 'Bird Name',"]
        cat = _run_checker(check_missing_tr, lines, self.FEATURES_PATH)
        self.assertEqual(len(cat.findings), 1)
        self.assertIn("labelText", cat.findings[0].suggestion)

    def test_no_finding_when_tr_used(self):
        lines = ["  labelText: 'birds.name_label'.tr(),"]
        cat = _run_checker(check_missing_tr, lines, self.FEATURES_PATH)
        self.assertEqual(len(cat.findings), 0)

    def test_no_finding_when_key_has_dot(self):
        """Nokta iceren deger zaten localization key'i — atlaniyor (satir 355-356)."""
        lines = ["  labelText: 'birds.name',"]
        cat = _run_checker(check_missing_tr, lines, self.FEATURES_PATH)
        self.assertEqual(len(cat.findings), 0)

    def test_skips_non_features_file(self):
        """features/screens disindaki dosyalar atlaniyor (satir 337-338)."""
        lines = ["  labelText: 'Some Label',"]
        cat = _run_checker(check_missing_tr, lines, self.NON_FEATURES_PATH)
        self.assertEqual(len(cat.findings), 0)

    def test_detects_hardcoded_hint_text(self):
        lines = ["  hintText: 'Enter bird name',"]
        cat = _run_checker(check_missing_tr, lines, self.FEATURES_PATH)
        self.assertEqual(len(cat.findings), 1)
        self.assertIn("hintText", cat.findings[0].suggestion)

    def test_ignores_comment_line(self):
        lines = ["  // labelText: 'Bird Name',  hardcoded example"]
        cat = _run_checker(check_missing_tr, lines, self.FEATURES_PATH)
        self.assertEqual(len(cat.findings), 0)


# main() branch testleri test_code_quality_main.py dosyasina tasindi.


# ── check_json_key_unknown_enum ───────────────────────────────────────────────


class TestCheckJsonKeyUnknownEnum(unittest.TestCase):
    """_KNOWN_ENUMS_CACHE patch'lenerek satir 547-568 kapsaniyor."""

    MODEL_PATH = Path("lib/data/models/bird_model.dart")
    NON_MODEL_PATH = Path("lib/features/birds/screens/bird_list_screen.dart")

    def _run_with_cache(self, lines, filepath, enums):
        """Checker'i belirtilen enum cache ile calistir."""
        import verify_code_quality as vcq
        with patch.object(vcq, "_KNOWN_ENUMS_CACHE", enums):
            return _run_checker(vcq.check_json_key_unknown_enum, lines, filepath)

    def test_skips_non_model_file(self):
        """_model.dart ile bitmeyen dosya atlanir (satir 545)."""
        lines = ["@freezed", "required BirdGender gender,"]
        cat = self._run_with_cache(lines, self.NON_MODEL_PATH, {"BirdGender"})
        self.assertEqual(len(cat.findings), 0)

    def test_skips_model_without_freezed(self):
        """@freezed icermeyen model dosyasi atlanir (satir 548-549)."""
        lines = ["class Bird {", "  required BirdGender gender;", "}"]
        cat = self._run_with_cache(lines, self.MODEL_PATH, {"BirdGender"})
        self.assertEqual(len(cat.findings), 0)

    def test_detects_missing_json_key_annotation(self):
        """@JsonKey(unknownEnumValue:) eksik enum field → finding (satir 563-568)."""
        lines = [
            "@freezed\n",
            "abstract class Bird with _$Bird {\n",
            "  const factory Bird({\n",
            "    required BirdGender gender,\n",
            "  }) = _Bird;\n",
        ]
        cat = self._run_with_cache(lines, self.MODEL_PATH, {"BirdGender"})
        self.assertEqual(len(cat.findings), 1)
        self.assertIn("BirdGender", cat.findings[0].suggestion)

    def test_no_finding_when_unknown_enum_value_in_context(self):
        """Onceki satirda unknownEnumValue varsa finding uretilmez (satir 563)."""
        lines = [
            "@freezed\n",
            "abstract class Bird with _$Bird {\n",
            "  const factory Bird({\n",
            "    @JsonKey(unknownEnumValue: BirdGender.unknown)\n",
            "    required BirdGender gender,\n",
            "  }) = _Bird;\n",
        ]
        cat = self._run_with_cache(lines, self.MODEL_PATH, {"BirdGender"})
        self.assertEqual(len(cat.findings), 0)

    def test_no_finding_for_getter_declaration(self):
        """'EnumType get foo' getter satirlari atlaniyor (satir 560)."""
        lines = [
            "@freezed\n",
            "abstract class Bird with _$Bird {\n",
            "  BirdGender get effectiveGender => gender;\n",
            "}\n",
        ]
        cat = self._run_with_cache(lines, self.MODEL_PATH, {"BirdGender"})
        self.assertEqual(len(cat.findings), 0)

    def test_ignores_comment_line(self):
        """Yorum satirlari atlaniyor (satir 554-555)."""
        lines = [
            "@freezed\n",
            "// required BirdGender gender, — add @JsonKey\n",
        ]
        cat = self._run_with_cache(lines, self.MODEL_PATH, {"BirdGender"})
        self.assertEqual(len(cat.findings), 0)

    def test_returns_early_when_cache_empty(self):
        """known_enums bos kümeyse erken cikis (satir 551-552)."""
        lines = [
            "@freezed\n",
            "abstract class Bird with _$Bird {\n",
            "  required BirdGender gender,\n",
            "}\n",
        ]
        # Bos set → if not known_enums: return (satir 552)
        cat = self._run_with_cache(lines, self.MODEL_PATH, set())
        self.assertEqual(len(cat.findings), 0)


# VERBOSE ve entrypoint testleri test_code_quality_main.py dosyasina tasindi.


# ── Runner ────────────────────────────────────────────────────────────────────


if __name__ == "__main__":
    unittest.main(verbosity=2)
