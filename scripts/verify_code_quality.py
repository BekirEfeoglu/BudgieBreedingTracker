#!/usr/bin/env python3
"""
BudgieBreedingTracker - Code Quality Anti-Pattern Scanner

CLAUDE.md'deki Critical Anti-Patterns listesini referans alarak
lib/ altindaki Dart dosyalarini tarar.

Otomatik checker'lar mevcut anti-pattern'lerin bir alt kumesini kapsar.
Script, CLAUDE.md'deki toplam anti-pattern sayisini parse ederek
kapsam raporunu da sunar.

Kullanim: python scripts/verify_code_quality.py [--verbose]
"""

import os
import re
import sys
from pathlib import Path
from dataclasses import dataclass, field
from typing import List, Tuple

# --- Configuration ---

ROOT_DIR = Path(__file__).resolve().parent.parent
LIB_DIR = ROOT_DIR / "lib"
CLAUDE_MD = ROOT_DIR / "CLAUDE.md"

EXCLUDED_SUFFIXES = (".freezed.dart", ".g.dart")
EXCLUDED_DIRS = {"test", "tests", ".dart_tool"}

# ANSI colors
RED = "\033[91m"
GREEN = "\033[92m"
YELLOW = "\033[93m"
CYAN = "\033[96m"
BOLD = "\033[1m"
RESET = "\033[0m"

VERBOSE = "--verbose" in sys.argv


# --- CLAUDE.md Parser ---

def parse_anti_patterns_from_claude_md() -> List[str]:
    """CLAUDE.md'deki Critical Anti-Patterns listesini parse et."""
    if not CLAUDE_MD.exists():
        return []

    content = CLAUDE_MD.read_text(encoding="utf-8")
    patterns = []
    in_section = False

    for line in content.splitlines():
        if "## Critical Anti-Patterns" in line:
            in_section = True
            continue
        if in_section and line.startswith("##"):
            break
        if in_section and re.match(r'\d+\.', line.strip()):
            patterns.append(line.strip())

    return patterns


# Anti-pattern ID -> checker mapping (hangi CLAUDE.md anti-pattern'i hangi checker ile kapsaniyor)
ANTI_PATTERN_COVERAGE = {
    1: "check_with_opacity",           # withOpacity() -> withValues
    2: "check_dropdown_value",          # value on Dropdown -> initialValue
    3: "check_drift_equals",            # .equals() -> .equalsValue()
    4: "check_ref_watch_in_callback",   # ref.watch() in callbacks -> ref.read()
    5: "check_print_statements",        # print() -> AppLogger
    6: "check_missing_tr",              # Hardcoded text -> .tr()
    7: "check_icon_icons",             # Icon(Icons.x) -> AppIcon(AppIcons.x)
    # 8: @JsonKey(unknownEnumValue) — requires AST analysis, not regex
    # 9: switch without unknown case — requires AST analysis, not regex
    # 10: context.go() -> context.push() — requires context awareness
    # 11: Import table via app_database — requires import graph analysis
    # 12: Route ordering — requires GoRouter config analysis
    13: "check_hardcoded_colors",       # Hardcoded colors -> Theme/AppColors
    # 14: Missing dispose — requires lifecycle analysis
    15: "check_freezed3_pattern",       # Missing const Model._() in Freezed
    # 16: Hardcoded SVG paths — low occurrence, covered by AppIcons convention
    17: "check_icondata_param",         # IconData param -> Widget param
}
# Spacing is an extra checker not directly in CLAUDE.md list but related to #13
EXTRA_CHECKERS = {"check_hardcoded_spacing": "Hardcoded spacing (AppSpacing convention)"}

# --- Whitelist (checker bazinda dosya/dizin istisna listesi) ---
WHITELIST = {
    'check_context_go_forward_nav': [
        'lib/features/auth/',
        'lib/features/home/',
        'lib/features/admin/',
        'lib/features/more/',
        'lib/features/profile/widgets/profile_menu_dialog.dart',
        'lib/features/profile/widgets/account_deletion_dialog.dart',
        'lib/features/profile/widgets/danger_zone_section.dart',
        'lib/features/community/widgets/community_feed_list.dart',
        'lib/core/widgets/not_found_screen.dart',
    ],
    'check_hardcoded_colors': [
        'lib/features/genetics/utils/',
        'lib/features/genetics/widgets/budgie_painter',
        'lib/features/auth/widgets/budgie_login_colors.dart',
    ],
}


def is_whitelisted(checker_name: str, filepath: Path) -> bool:
    """Check if file is whitelisted for a specific checker."""
    patterns = WHITELIST.get(checker_name, [])
    rel = relative_path(filepath)
    return any(rel.startswith(p) or rel == p for p in patterns)


# --- Data Structures ---

@dataclass
class Finding:
    file: str
    line_num: int
    line_text: str
    suggestion: str
    severity: str = "error"  # "error" or "warning"


@dataclass
class Category:
    name: str
    tag: str
    description: str
    severity: str = "error"  # "error" or "warning"
    findings: List[Finding] = field(default_factory=list)


# --- Helper Functions ---

def is_comment_line(line: str) -> bool:
    """Check if line is a comment (ignoring leading whitespace)."""
    stripped = line.strip()
    return stripped.startswith("//") or stripped.startswith("///") or stripped.startswith("/*") or stripped.startswith("*")


def is_in_string_literal(line: str, match_start: int) -> bool:
    """Basic check if match position is inside a string literal."""
    before = line[:match_start]
    single_quotes = before.count("'") - before.count("\\'")
    double_quotes = before.count('"') - before.count('\\"')
    return (single_quotes % 2 == 1) or (double_quotes % 2 == 1)


def get_dart_files() -> List[Path]:
    """Get all Dart files in lib/ excluding generated and test files."""
    if not LIB_DIR.exists():
        print(f"{RED}HATA: lib/ dizini bulunamadi: {LIB_DIR}{RESET}")
        sys.exit(1)

    dart_files = []
    for root, dirs, files in os.walk(LIB_DIR):
        # Skip excluded directories
        dirs[:] = [d for d in dirs if d not in EXCLUDED_DIRS]

        for f in files:
            if not f.endswith(".dart"):
                continue
            if any(f.endswith(suffix) for suffix in EXCLUDED_SUFFIXES):
                continue
            dart_files.append(Path(root) / f)

    return sorted(dart_files)


def relative_path(filepath: Path) -> str:
    """Get path relative to project root."""
    try:
        return str(filepath.relative_to(LIB_DIR.parent))
    except ValueError:
        return str(filepath)


_KNOWN_ENUMS_CACHE: set = set()

def collect_known_enums() -> set:
    """lib/core/enums/ altindaki enum tiplerini topla."""
    enums_dir = LIB_DIR / "core" / "enums"
    known = set()
    if not enums_dir.exists():
        return known
    for f in enums_dir.glob("*.dart"):
        if any(f.name.endswith(s) for s in EXCLUDED_SUFFIXES):
            continue
        try:
            content = f.read_text(encoding="utf-8")
            for m in re.finditer(r'enum\s+(\w+)\s*\{', content):
                known.add(m.group(1))
        except Exception:
            pass
    return known


# --- Anti-Pattern Checkers ---

def check_print_statements(lines: List[str], filepath: Path, cat: Category):
    """1. print( -> AppLogger kullan"""
    for i, line in enumerate(lines, 1):
        if is_comment_line(line):
            continue
        # Match print( but not AppLogger or debugPrint in debug context
        match = re.search(r'\bprint\s*\(', line)
        if match and not is_in_string_literal(line, match.start()):
            # Exclude lines that are part of debugPrint which is acceptable in some contexts
            if "debugPrint" in line:
                continue
            cat.findings.append(Finding(
                file=relative_path(filepath),
                line_num=i,
                line_text=line.rstrip(),
                suggestion="AppLogger.info/error/warning() kullan"
            ))


def check_with_opacity(lines: List[str], filepath: Path, cat: Category):
    """2. .withOpacity( -> .withValues(alpha:) kullan"""
    for i, line in enumerate(lines, 1):
        if is_comment_line(line):
            continue
        match = re.search(r'\.withOpacity\s*\(', line)
        if match and not is_in_string_literal(line, match.start()):
            cat.findings.append(Finding(
                file=relative_path(filepath),
                line_num=i,
                line_text=line.rstrip(),
                suggestion=".withValues(alpha: x) kullan"
            ))


def check_hardcoded_colors(lines: List[str], filepath: Path, cat: Category):
    """3. Colors.xxx (hardcoded) -> Theme.of(context) / AppColors kullan"""
    # Skip app_colors.dart itself and theme files
    fname = filepath.name
    if fname in ("app_colors.dart", "app_theme.dart", "app_typography.dart"):
        return

    # Colors.transparent is a functional constant (absence of color), not a visual hardcoded color
    safe_colors = {"transparent", "white", "black"}

    for i, line in enumerate(lines, 1):
        if is_comment_line(line):
            continue
        # Match Colors.xxx but not in comments or imports
        match = re.search(r'\bColors\.(\w+)', line)
        if match and not is_in_string_literal(line, match.start()):
            if line.strip().startswith("import"):
                continue
            color_name = match.group(1)
            if color_name in safe_colors:
                continue
            cat.findings.append(Finding(
                file=relative_path(filepath),
                line_num=i,
                line_text=line.rstrip(),
                suggestion="Theme.of(context).colorScheme.xxx veya AppColors.xxx kullan"
            ))


def check_icon_icons(lines: List[str], filepath: Path, cat: Category):
    """4. Icon(Icons. (domain icons) -> AppIcon(AppIcons.) kullan"""
    # Skip files that legitimately use Icon(Icons.) for generic UI
    fname = filepath.name
    if fname in ("app_icon.dart", "app_icons.dart"):
        return

    for i, line in enumerate(lines, 1):
        if is_comment_line(line):
            continue
        # Match Icon(Icons. but not LucideIcons which are acceptable
        match = re.search(r'\bIcon\s*\(\s*Icons\.', line)
        if match and not is_in_string_literal(line, match.start()):
            cat.findings.append(Finding(
                file=relative_path(filepath),
                line_num=i,
                line_text=line.rstrip(),
                suggestion="AppIcon(AppIcons.xxx) veya Icon(LucideIcons.xxx) kullan"
            ))


def check_ref_watch_in_callback(lines: List[str], filepath: Path, cat: Category):
    """5. ref.watch( callback icinde -> ref.read() kullan"""
    in_callback = False
    brace_depth = 0

    for i, line in enumerate(lines, 1):
        if is_comment_line(line):
            continue
        stripped = line.strip()

        # Detect callback patterns
        if re.search(r'(onPressed|onTap|onChanged|onSubmitted|onRefresh|onLongPress)\s*:', stripped):
            in_callback = True
            brace_depth = 0

        if in_callback:
            brace_depth += line.count('{') + line.count('(')
            brace_depth -= line.count('}') + line.count(')')

            match = re.search(r'ref\.watch\s*\(', line)
            if match and not is_in_string_literal(line, match.start()):
                cat.findings.append(Finding(
                    file=relative_path(filepath),
                    line_num=i,
                    line_text=line.rstrip(),
                    suggestion="Callback icinde ref.read() kullan (ref.watch() degil)"
                ))

            if brace_depth <= 0:
                in_callback = False


def check_missing_tr(lines: List[str], filepath: Path, cat: Category):
    """6. labelText/hintText/title icinde .tr() eksik"""
    # Only check feature and screen files
    fpath_str = str(filepath)
    if "features" not in fpath_str and "screens" not in fpath_str:
        return

    patterns = [
        (r"labelText\s*:\s*'([^']+)'", "labelText"),
        (r'labelText\s*:\s*"([^"]+)"', "labelText"),
        (r"hintText\s*:\s*'([^']+)'", "hintText"),
        (r'hintText\s*:\s*"([^"]+)"', "hintText"),
    ]

    for i, line in enumerate(lines, 1):
        if is_comment_line(line):
            continue
        for pattern, label in patterns:
            match = re.search(pattern, line)
            if match and ".tr()" not in line:
                value = match.group(1)
                # Skip if it's already a key reference (contains dots like 'birds.name')
                if "." in value:
                    continue
                cat.findings.append(Finding(
                    file=relative_path(filepath),
                    line_num=i,
                    line_text=line.rstrip(),
                    suggestion=f"{label} icin 'key'.tr() localization kullan"
                ))


def check_hardcoded_spacing(lines: List[str], filepath: Path, cat: Category):
    """7. Hardcoded spacing (8.0, 16.0, 24.0) -> AppSpacing kullan"""
    fname = filepath.name
    if fname in ("app_spacing.dart", "app_breakpoints.dart", "app_constants.dart"):
        return

    # Common hardcoded spacing values
    spacing_values = {"4.0", "8.0", "12.0", "16.0", "20.0", "24.0", "32.0"}

    for i, line in enumerate(lines, 1):
        if is_comment_line(line):
            continue
        # Match EdgeInsets or SizedBox with hardcoded values
        for val in spacing_values:
            patterns = [
                rf'EdgeInsets\.[^(]*\([^)]*{re.escape(val)}',
                rf'SizedBox\s*\([^)]*(?:width|height)\s*:\s*{re.escape(val)}',
            ]
            for pattern in patterns:
                match = re.search(pattern, line)
                if match and not is_in_string_literal(line, match.start()):
                    if "AppSpacing" in line:
                        continue
                    cat.findings.append(Finding(
                        file=relative_path(filepath),
                        line_num=i,
                        line_text=line.rstrip(),
                        suggestion=f"AppSpacing sabiti kullan ({val} yerine)"
                    ))
                    break  # One finding per line is enough


def check_dropdown_value(lines: List[str], filepath: Path, cat: Category):
    """8. DropdownButtonFormField + value: -> initialValue kullan"""
    in_dropdown = False

    for i, line in enumerate(lines, 1):
        if is_comment_line(line):
            continue
        if "DropdownButtonFormField" in line:
            in_dropdown = True

        if in_dropdown:
            # Check for deprecated 'value:' parameter
            match = re.search(r'\bvalue\s*:', line)
            if match and "initialValue" not in line:
                # Make sure it's not 'value:' in a DropdownMenuItem
                if "DropdownMenuItem" not in line and "ButtonSegment" not in line:
                    cat.findings.append(Finding(
                        file=relative_path(filepath),
                        line_num=i,
                        line_text=line.rstrip(),
                        suggestion="DropdownButtonFormField icin initialValue kullan (value deprecated)"
                    ))

            # Reset after closing
            if ")," in line or ");" in line:
                in_dropdown = False


def check_drift_equals(lines: List[str], filepath: Path, cat: Category):
    """9. .equals( Drift enum -> .equalsValue() kullan"""
    # Only check DAO files
    if "_dao.dart" not in filepath.name:
        return

    for i, line in enumerate(lines, 1):
        if is_comment_line(line):
            continue
        # Match .gender.equals( or .status.equals( patterns in DAOs
        match = re.search(r'\.\w+\.equals\s*\(', line)
        if match:
            # Skip .userId.equals( and .isDeleted.equals( which are correct (not enums)
            col_match = re.search(r'\.(\w+)\.equals\s*\(', line)
            if col_match:
                col_name = col_match.group(1)
                # These are likely enum columns
                enum_columns = {"gender", "status", "type", "category", "role",
                                "priority", "severity", "stage", "phase"}
                if col_name.lower() in enum_columns:
                    # If .equals() is called with a string literal, it's a plain text column (not enum)
                    if re.search(r"\.equals\s*\(\s*'[^']*'\s*\)", line):
                        continue
                    cat.findings.append(Finding(
                        file=relative_path(filepath),
                        line_num=i,
                        line_text=line.rstrip(),
                        suggestion=f".equalsValue() kullan (.equals() enum icin yanlis)"
                    ))


def check_icondata_param(lines: List[str], filepath: Path, cat: Category):
    """10. IconData shared widget param -> Widget kullan"""
    # Only check shared widget files
    fpath_str = str(filepath)
    if "core/widgets" not in fpath_str.replace("\\", "/"):
        return

    for i, line in enumerate(lines, 1):
        if is_comment_line(line):
            continue
        # Match IconData parameter declarations
        match = re.search(r'\bIconData\b\s+\w*icon', line, re.IGNORECASE)
        if match:
            cat.findings.append(Finding(
                file=relative_path(filepath),
                line_num=i,
                line_text=line.rstrip(),
                suggestion="Widget tipi kullan (IconData yerine, Phase 22 API)"
            ))


def check_freezed3_pattern(lines: List[str], filepath: Path, cat: Category):
    """11. @freezed class -> @freezed abstract class kullan (Freezed 3)"""
    content = "".join(lines)
    if "@freezed" not in content:
        return

    for idx in range(len(lines)):
        line = lines[idx]
        if is_comment_line(line):
            continue
        stripped = line.strip()
        # Check for @freezed annotation (exact match)
        if stripped == "@freezed":
            # Look ahead for class declaration (skip blank/comment lines)
            for j in range(idx + 1, min(idx + 4, len(lines))):
                next_stripped = lines[j].strip()
                if not next_stripped or is_comment_line(lines[j]):
                    continue
                # If class declaration found without 'abstract' keyword -> violation
                if re.match(r'^class\s+\w+', next_stripped) and not re.match(r'^abstract\s+class\s+', next_stripped):
                    cat.findings.append(Finding(
                        file=relative_path(filepath),
                        line_num=j + 1,
                        line_text=lines[j].rstrip(),
                        suggestion="'abstract class' kullan: '@freezed abstract class Model with _$Model' (Freezed 3)"
                    ))
                break


# --- Main ---

def main():
    print(f"\n{BOLD}{CYAN}=== BudgieBreedingTracker - Code Quality Scanner ==={RESET}\n")

    # Parse CLAUDE.md anti-pattern list for coverage report
    claude_patterns = parse_anti_patterns_from_claude_md()
    total_patterns = len(claude_patterns)
    covered_count = len(ANTI_PATTERN_COVERAGE)
    if total_patterns > 0:
        print(f"CLAUDE.md anti-pattern sayisi: {total_patterns}")
        print(f"Otomatik kapsam: {covered_count}/{total_patterns} ({100 * covered_count // total_patterns}%) + {len(EXTRA_CHECKERS)} ek checker")
    print(f"Taranan dizin: {LIB_DIR}\n")

    dart_files = get_dart_files()
    # Cache enum types once (check_json_key_unknown_enum icin)
    global _KNOWN_ENUMS_CACHE
    _KNOWN_ENUMS_CACHE = collect_known_enums()
    print(f"Toplam Dart dosyasi: {len(dart_files)} (generated dosyalar haric)\n")

    # Define categories
    categories = [
        Category("print() Kullanimi", "[Logger]", "print() -> AppLogger kullan"),
        Category("withOpacity() Kullanimi", "[Opacity]", ".withOpacity() -> .withValues(alpha:) kullan"),
        Category("Hardcoded Colors", "[Colors]", "Colors.xxx -> Theme.of(context) / AppColors kullan"),
        Category("Icon(Icons.) Kullanimi", "[Icons]", "Icon(Icons.) -> AppIcon(AppIcons.) kullan"),
        Category("ref.watch() Callback", "[Riverpod]", "Callback icinde ref.watch() -> ref.read() kullan"),
        Category("Eksik .tr() Localization", "[L10n]", "Hardcoded text -> .tr() kullan"),
        Category("Hardcoded Spacing", "[Spacing]", "Sabit degerler -> AppSpacing kullan"),
        Category("DropdownButtonFormField value:", "[Dropdown]", "value: -> initialValue kullan"),
        Category("Drift .equals() Enum", "[Drift]", ".equals() -> .equalsValue() kullan"),
        Category("IconData Param", "[IconData]", "IconData param -> Widget param kullan"),
        Category("Freezed 3 Pattern", "[Freezed3]", "@freezed class -> @freezed abstract class kullan"),
    ]

    checkers = [
        check_print_statements,
        check_with_opacity,
        check_hardcoded_colors,
        check_icon_icons,
        check_ref_watch_in_callback,
        check_missing_tr,
        check_hardcoded_spacing,
        check_dropdown_value,
        check_drift_equals,
        check_icondata_param,
        check_freezed3_pattern,
    ]

    # Run all checkers on all files
    for filepath in dart_files:
        try:
            with open(filepath, "r", encoding="utf-8") as f:
                lines = f.readlines()
        except Exception as e:
            print(f"{YELLOW}UYARI: {filepath} okunamadi: {e}{RESET}")
            continue

        for checker, cat in zip(checkers, categories):
            checker(lines, filepath, cat)

    # Report results
    total_findings = 0
    categories_with_issues = 0

    for cat in categories:
        count = len(cat.findings)
        total_findings += count

        if count == 0:
            print(f"  {GREEN}PASS{RESET}  {cat.tag} {cat.name}: 0 sorun")
        else:
            categories_with_issues += 1
            print(f"  {RED}FAIL{RESET}  {cat.tag} {cat.name}: {count} sorun")

            if VERBOSE:
                for finding in cat.findings:
                    print(f"        {YELLOW}{finding.file}:{finding.line_num}{RESET}")
                    print(f"        {finding.line_text.strip()[:100]}")
                    print(f"        -> {finding.suggestion}")
                    print()
            else:
                # Show first 3 findings as sample
                for finding in cat.findings[:3]:
                    print(f"        {YELLOW}{finding.file}:{finding.line_num}{RESET} -> {finding.suggestion}")
                if count > 3:
                    print(f"        ... ve {count - 3} sorun daha (--verbose ile tumu)")

    # Summary
    print(f"\n{BOLD}--- Ozet ---{RESET}")
    print(f"Taranan dosya:      {len(dart_files)}")
    print(f"Toplam sorun:       {total_findings}")
    print(f"Sorunlu kategori:   {categories_with_issues}/{len(categories)}")
    print(f"Temiz kategori:     {len(categories) - categories_with_issues}/{len(categories)}")

    if total_findings == 0:
        print(f"\n{GREEN}{BOLD}Tum anti-pattern kontrolleri basarili!{RESET}")
    else:
        print(f"\n{YELLOW}Detay icin: python scripts/verify_code_quality.py --verbose{RESET}")

    # Coverage report
    if total_patterns > 0 and VERBOSE:
        uncovered = [i for i in range(1, total_patterns + 1) if i not in ANTI_PATTERN_COVERAGE]
        if uncovered:
            print(f"\n{BOLD}--- Otomatik Kapsam Disi Anti-Pattern'ler ---{RESET}")
            for idx in uncovered:
                if idx <= len(claude_patterns):
                    print(f"  {YELLOW}#{idx}{RESET} {claude_patterns[idx - 1]}")
            print(f"  {CYAN}Bu pattern'ler AST analizi veya context bilgisi gerektirir.{RESET}")

    return 1 if total_findings > 0 else 0


if __name__ == "__main__":
    sys.exit(main())
