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

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

import os
import re
from dataclasses import dataclass, field
from typing import List, Tuple

from _rules_utils import Colors

# --- Configuration ---

ROOT_DIR = Path(__file__).resolve().parent.parent
LIB_DIR = ROOT_DIR / "lib"
CLAUDE_MD = ROOT_DIR / "CLAUDE.md"

EXCLUDED_SUFFIXES = (".freezed.dart", ".g.dart")
EXCLUDED_DIRS = {"test", "tests", ".dart_tool"}

# ANSI color aliases (from shared Colors class)
RED = Colors.RED
GREEN = Colors.GREEN
YELLOW = Colors.YELLOW
CYAN = Colors.CYAN
BOLD = Colors.BOLD
RESET = Colors.RESET

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
        if in_section and line.startswith("## ") and "Anti-Patterns" not in line:
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
    8: "check_json_key_unknown_enum",    # Missing @JsonKey(unknownEnumValue)
    9: "check_switch_unknown_case",      # switch without unknown (warning)
    10: "check_context_go_forward_nav",  # context.go() -> context.push()
    11: "check_dao_import_app_database", # Import table via app_database (warning)
    12: "check_route_ordering",          # Route ordering (warning)
    13: "check_hardcoded_colors",       # Hardcoded colors -> Theme/AppColors
    14: "check_controller_dispose",      # Missing controller.dispose() (warning)
    15: "check_freezed3_pattern",       # Missing const Model._() in Freezed
    # 16: Hardcoded SVG paths — low occurrence, covered by AppIcons convention
    17: "check_icondata_param",         # IconData param -> Widget param
}
# Extra checkers not directly numbered in CLAUDE.md list but enforce documented rules
EXTRA_CHECKERS = {
    "check_hardcoded_spacing": "Hardcoded spacing (AppSpacing convention)",
    "check_bare_catch": "Bare catch without logging (coding-standards #17)",
    "check_mounted_async": "setState after async without mounted (coding-standards #18)",
    "check_layer_imports": "Layer hierarchy import violations (architecture.md)",
    "check_freezed_private_constructor": "Missing const Model._() in Freezed (coding-standards #15)",
}

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
    'check_layer_imports': [
        'lib/core/extensions/',  # Extensions may import data/models (documented exception)
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
        except OSError:
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


def check_context_go_forward_nav(lines, filepath, cat):
    """context.go( forward nav -> context.push() kullan"""
    if is_whitelisted('check_context_go_forward_nav', filepath):
        return
    for i, line in enumerate(lines, 1):
        if is_comment_line(line):
            continue
        match = re.search(r'context\.go\s*\(', line)
        if match and not is_in_string_literal(line, match.start()):
            cat.findings.append(Finding(
                file=relative_path(filepath), line_num=i,
                line_text=line.rstrip(),
                suggestion="Forward navigation icin context.push() kullan (context.go() stack'i siler)",
            ))


def check_controller_dispose(lines, filepath, cat):
    """ConsumerStatefulWidget'ta controller dispose eksik"""
    content = "".join(lines)
    if "ConsumerStatefulWidget" not in content:
        return
    controller_pattern = re.compile(r'(?:final|late final)\s+\w*Controller\s+_?\w+\s*=')
    dispose_pattern = re.compile(r'_?\w+\.dispose\(\)')
    controllers = controller_pattern.findall(content)
    disposes = dispose_pattern.findall(content)
    if len(controllers) > len(disposes):
        for i, line in enumerate(lines, 1):
            if controller_pattern.search(line):
                cat.findings.append(Finding(
                    file=relative_path(filepath), line_num=i,
                    line_text=line.rstrip(),
                    suggestion=f"Controller dispose() eksik olabilir ({len(controllers)} tanim, {len(disposes)} dispose)",
                    severity="warning",
                ))
                break


def check_json_key_unknown_enum(lines, filepath, cat):
    """Freezed model enum field'larinda @JsonKey(unknownEnumValue:) eksik"""
    if not filepath.name.endswith("_model.dart"):
        return
    content = "".join(lines)
    if "@freezed" not in content:
        return
    known_enums = _KNOWN_ENUMS_CACHE
    if not known_enums:
        return
    # Only check enum fields inside const factory ... = _ClassName; blocks
    in_factory = False
    paren_depth = 0
    for i, line in enumerate(lines, 1):
        if is_comment_line(line):
            continue
        # Detect factory block start
        if re.search(r'const\s+factory\b', line):
            in_factory = True
            paren_depth = 0
        if in_factory:
            paren_depth += line.count('(') - line.count(')')
            if paren_depth <= 0 and ')' in line:
                in_factory = False
                continue
            for enum_name in known_enums:
                pattern = rf'(?:required\s+)?{re.escape(enum_name)}\??\s+\w+'
                match = re.search(pattern, line)
                # Skip getter declarations (e.g. `DevelopmentStage get foo`) — not a Freezed field
                if match and not re.search(rf'{re.escape(enum_name)}\??\s+get\b', line):
                    context_start = max(0, i - 3)
                    context_lines = "".join(lines[context_start:i])
                    if "unknownEnumValue" not in context_lines and "unknownEnumValue" not in line:
                        cat.findings.append(Finding(
                            file=relative_path(filepath), line_num=i,
                            line_text=line.rstrip(),
                            suggestion=f"@JsonKey(unknownEnumValue: {enum_name}.unknown) ekle",
                        ))


def check_dao_import_app_database(lines, filepath, cat):
    """DAO dosyasinda table dosyasi dogrudan import edilmeli"""
    if "_dao.dart" not in filepath.name:
        return
    content = "".join(lines)
    if "@DriftAccessor" not in content:
        return
    has_direct_table_import = any(
        re.search(r'import\s+.*(?:tables/|_table\.dart)', line)
        for line in lines
    )
    if not has_direct_table_import:
        cat.findings.append(Finding(
            file=relative_path(filepath), line_num=1,
            line_text=lines[0].rstrip() if lines else "",
            suggestion="Table dosyasini dogrudan import et (app_database uzerinden degil)",
            severity="warning",
        ))


def check_switch_unknown_case(lines, filepath, cat):
    """Enum switch'lerinde unknown case eksik (warning)"""
    if not filepath.name.endswith("_model.dart") and "enums" not in str(filepath):
        return
    in_switch = False
    switch_line = 0
    switch_text = ""
    brace_depth = 0
    for i, line in enumerate(lines, 1):
        if is_comment_line(line):
            continue
        if re.search(r'\bswitch\s*\(', line):
            in_switch = True
            switch_line = i
            switch_text = line.rstrip()
            brace_depth = 0
        if in_switch:
            brace_depth += line.count('{')
            brace_depth -= line.count('}')
            if 'unknown' in line.lower():
                in_switch = False
                continue
            if brace_depth <= 0 and switch_line > 0:
                cat.findings.append(Finding(
                    file=relative_path(filepath), line_num=switch_line,
                    line_text=switch_text,
                    suggestion="switch ifadesinde 'unknown' case ekle",
                    severity="warning",
                ))
                in_switch = False


def check_route_ordering(lines, filepath, cat):
    """GoRouter'da parameterized route specific'ten once (warning)"""
    if "app_router" not in filepath.name:
        return
    # Track paths within each GoRoute's routes:[] block by using a stack.
    # Each entry on the stack represents one routes:[] block.
    # We push when we see 'routes: [' and pop when the matching ']' closes.
    routes_stack: list = []  # each element: list of (is_param, line_num, path_val)
    brace_depth = 0
    bracket_depth = 0
    routes_open_brackets: list = []  # bracket depth when each routes:[ was opened

    for i, line in enumerate(lines, 1):
        if is_comment_line(line):
            continue
        brace_depth += line.count('{') - line.count('}')
        opens = line.count('[')
        closes = line.count(']')

        # Detect 'routes: [' opening
        if re.search(r'\broutes\s*:\s*\[', line):
            routes_stack.append([])
            routes_open_brackets.append(bracket_depth + opens - (closes if ']' in line.split('routes')[1] else 0))

        bracket_depth += opens - closes

        # Detect closing of a routes:[] block
        if routes_open_brackets and bracket_depth < routes_open_brackets[-1]:
            routes_stack.pop()
            routes_open_brackets.pop()

        path_match = re.search(r"path:\s*['\"]([^'\"]+)['\"]", line)
        if path_match and routes_stack:
            path_val = path_match.group(1)
            is_param = ':' in path_val
            current_block = routes_stack[-1]
            if current_block and current_block[-1][0] and not is_param and path_val != '/':
                prev_line_num = current_block[-1][1]
                cat.findings.append(Finding(
                    file=relative_path(filepath), line_num=prev_line_num,
                    line_text=f"  path: '{path_val}' parametreli route'tan sonra",
                    suggestion="Specific route'lar parametreli route'lardan ONCE gelmeli",
                    severity="warning",
                ))
            current_block.append((is_param, i, path_val))


def check_bare_catch(lines: List[str], filepath: Path, cat: Category):
    """catch (e) without AppLogger or Sentry logging."""
    for i, line in enumerate(lines, 1):
        if is_comment_line(line):
            continue
        match = re.search(r'\bcatch\s*\(\s*e\b', line)
        if not match:
            continue
        # Look ahead 5 lines for AppLogger, Sentry, or error delegation
        lookahead = "".join(lines[i:min(i + 5, len(lines))])
        if "AppLogger." in lookahead or "Sentry." in lookahead:
            continue
        if "handleError" in lookahead or "markError" in lookahead or "markSyncError" in lookahead:
            continue
        # Skip short rethrow/return/state patterns (common in Notifiers)
        short_body = "".join(lines[i:min(i + 5, len(lines))]).strip()
        if "rethrow" in short_body or "return" in short_body:
            continue
        if "state = state.copyWith(" in short_body or "state =" in short_body:
            continue
        cat.findings.append(Finding(
            file=relative_path(filepath),
            line_num=i,
            line_text=line.rstrip(),
            suggestion="catch blogu icinde AppLogger.error() veya Sentry.captureException() kullan",
            severity="warning",
        ))


def check_mounted_async(lines: List[str], filepath: Path, cat: Category):
    """setState after await without mounted check in ConsumerStatefulWidget."""
    content = "".join(lines)
    if "ConsumerStatefulWidget" not in content:
        return

    saw_await = False
    for i, line in enumerate(lines, 1):
        if is_comment_line(line):
            continue
        stripped = line.strip()
        if re.search(r'\bawait\b', stripped):
            saw_await = True
            continue
        if saw_await and re.search(r'\bsetState\s*\(', stripped):
            # Check if mounted is checked on same line or in previous 3 lines
            if "mounted" in stripped:
                saw_await = False
                continue
            lookback = "".join(lines[max(0, i - 6):i - 1])
            if "mounted" not in lookback:
                cat.findings.append(Finding(
                    file=relative_path(filepath),
                    line_num=i,
                    line_text=line.rstrip(),
                    suggestion="await sonrasi setState oncesinde 'if (mounted)' kontrolu ekle",
                    severity="warning",
                ))
            saw_await = False
        # Reset on method boundaries
        if re.match(r'\s*(void|Future|Widget|@override)', stripped):
            saw_await = False


def check_layer_imports(lines: List[str], filepath: Path, cat: Category):
    """Layer hierarchy import violations: core->data/features, data->features."""
    if is_whitelisted('check_layer_imports', filepath):
        return

    rel = relative_path(filepath).replace("\\", "/")

    # Determine which layer this file is in
    is_core = rel.startswith("lib/core/")
    is_data = rel.startswith("lib/data/")

    if not is_core and not is_data:
        return

    # Package name for matching package-style imports
    pkg = "budgie_breeding_tracker"

    def _imports_layer(stripped: str, layer: str) -> bool:
        """Check if an import line references a specific layer.
        Matches: package:budgie_breeding_tracker/<layer>/ and relative ../<layer>/"""
        return (f"{pkg}/{layer}/" in stripped or
                f"'../" in stripped and f"/{layer}/" in stripped)

    def _imports_sublayer(stripped: str, layer: str, sublayer: str) -> bool:
        """Check if an import line references a specific sublayer (e.g. data/models/)."""
        return (f"{pkg}/{layer}/{sublayer}/" in stripped or
                f"'../" in stripped and f"/{layer}/{sublayer}/" in stripped)

    for i, line in enumerate(lines, 1):
        stripped = line.strip()
        if not stripped.startswith("import"):
            continue

        if is_core:
            # core/ must NOT import from features/ or data/ (except models)
            if _imports_layer(stripped, "features"):
                cat.findings.append(Finding(
                    file=relative_path(filepath),
                    line_num=i,
                    line_text=line.rstrip(),
                    suggestion="core/ katmani features/ katmanindan import edemez",
                ))
            if (_imports_layer(stripped, "data") and
                    not _imports_sublayer(stripped, "data", "models")):
                cat.findings.append(Finding(
                    file=relative_path(filepath),
                    line_num=i,
                    line_text=line.rstrip(),
                    suggestion="core/ katmani data/ katmanindan import edemez (models/ haric)",
                ))
        elif is_data:
            # data/ must NOT import from features/
            if _imports_layer(stripped, "features"):
                cat.findings.append(Finding(
                    file=relative_path(filepath),
                    line_num=i,
                    line_text=line.rstrip(),
                    suggestion="data/ katmani features/ katmanindan import edemez",
                ))


def check_freezed_private_constructor(lines: List[str], filepath: Path, cat: Category):
    """Missing const Model._() private constructor in @freezed abstract class."""
    if not filepath.name.endswith("_model.dart"):
        return
    content = "".join(lines)
    if "@freezed" not in content:
        return

    for idx in range(len(lines)):
        line = lines[idx]
        stripped = line.strip()
        if stripped == "@freezed":
            # Find class name
            for j in range(idx + 1, min(idx + 4, len(lines))):
                class_match = re.match(r'\s*abstract\s+class\s+(\w+)', lines[j])
                if class_match:
                    class_name = class_match.group(1)
                    # Look ahead 8 lines for const ClassName._()
                    lookahead = "".join(lines[j:min(j + 8, len(lines))])
                    private_ctor = f"const {class_name}._();"
                    if private_ctor not in lookahead:
                        cat.findings.append(Finding(
                            file=relative_path(filepath),
                            line_num=j + 1,
                            line_text=lines[j].rstrip(),
                            suggestion=f"'{private_ctor}' private constructor ekle (Freezed 3 gerekliligi)",
                        ))
                    break


# --- Main ---

def check_bare_circular_progress(lines: List[str], filepath: Path, cat: Category):
    """UI/UX: Center(child: CircularProgressIndicator()) -> LoadingState kullan.

    Ad-hoc spinner'lar erisilemez (semanticsLabel eksik) ve tutarsiz. Shared
    LoadingState widget'ini kullanmak: screen reader destegi + optional message.
    """
    fname = filepath.name
    # LoadingState'in kendisi ve legitimate kullanim
    if fname in ("loading_state.dart", "submit_button.dart", "app_bottom_sheet.dart"):
        return

    for i, line in enumerate(lines, 1):
        if is_comment_line(line):
            continue
        if re.search(r'\bCenter\(\s*child:\s*CircularProgressIndicator\(\s*\)', line):
            cat.findings.append(Finding(
                file=relative_path(filepath),
                line_num=i,
                line_text=line.rstrip(),
                suggestion="const LoadingState() kullan"
            ))


def check_iconbutton_constraints(lines: List[str], filepath: Path, cat: Category):
    """UI/UX: IconButton(...) -> AppIconButton kullan (min 48dp tap target).

    WCAG 2.1 AA minimum tap target 44x44 (Apple HIG 44, Material 48). IconButton
    default constraint'i ile 40x40 olabilir. AppIconButton guarantees 48dp +
    required semanticLabel.
    """
    fname = filepath.name
    if fname in ("app_icon_button.dart",):
        return

    for i, line in enumerate(lines, 1):
        if is_comment_line(line):
            continue
        # Raw IconButton( without constraints argument on same or next lines
        m = re.search(r'\bIconButton\s*\(', line)
        if m and not is_in_string_literal(line, m.start()):
            # Quick heuristic: if line contains constraints or AppIconButton, skip
            window = "".join(lines[i - 1:i + 8])
            if "constraints:" in window or "AppIconButton" in window:
                continue
            cat.findings.append(Finding(
                file=relative_path(filepath),
                line_num=i,
                line_text=line.rstrip(),
                suggestion="AppIconButton kullan (48dp min tap target garantisi)"
            ))


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
        Category("context.go() Forward Nav", "[GoRouter]", "context.go() -> context.push() kullan"),
        Category("Controller Dispose Eksik", "[Dispose]", "Controller.dispose() eksik olabilir", severity="warning"),
        Category("@JsonKey unknownEnumValue Eksik", "[JsonKey]", "@JsonKey(unknownEnumValue:) ekle"),
        Category("DAO Table Import", "[DriftDAO]", "Table dosyasini dogrudan import et", severity="warning"),
        Category("Switch Unknown Case", "[Switch]", "switch'te unknown case ekle", severity="warning"),
        Category("Route Ordering", "[Router]", "Specific route parametreliden once gelmeli", severity="warning"),
        Category("Bare Catch (Logging Eksik)", "[Catch]", "catch blogu icinde AppLogger/Sentry kullan", severity="warning"),
        Category("Mounted Check Eksik", "[Mounted]", "await sonrasi setState icin mounted kontrol et", severity="warning"),
        Category("Layer Import Ihlali", "[Layer]", "Katman hiyerarsisi import ihlali"),
        Category("Freezed Private Constructor", "[FreezedCtor]", "const Model._() private constructor eksik"),
        Category("Ad-hoc CircularProgressIndicator", "[Loading]", "Center+CircularProgressIndicator -> LoadingState kullan", severity="warning"),
        Category("IconButton 48dp Constraint Eksik", "[TapTarget]", "IconButton -> AppIconButton kullan (a11y)", severity="warning"),
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
        check_context_go_forward_nav,
        check_controller_dispose,
        check_json_key_unknown_enum,
        check_dao_import_app_database,
        check_switch_unknown_case,
        check_route_ordering,
        check_bare_catch,
        check_mounted_async,
        check_layer_imports,
        check_freezed_private_constructor,
        check_bare_circular_progress,
        check_iconbutton_constraints,
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
    total_errors = 0
    total_warnings = 0
    categories_with_issues = 0

    for cat in categories:
        count = len(cat.findings)
        if count == 0:
            print(f"  {GREEN}PASS{RESET}  {cat.tag} {cat.name}: 0 sorun")
        else:
            categories_with_issues += 1
            if cat.severity == "warning":
                total_warnings += count
                print(f"  {YELLOW}WARN{RESET}  {cat.tag} {cat.name}: {count} uyari")
            else:
                total_errors += count
                print(f"  {RED}FAIL{RESET}  {cat.tag} {cat.name}: {count} sorun")

            if VERBOSE:
                for finding in cat.findings:
                    print(f"        {YELLOW}{finding.file}:{finding.line_num}{RESET}")
                    print(f"        {finding.line_text.strip()[:100]}")
                    print(f"        -> {finding.suggestion}")
                    print()
            else:
                for finding in cat.findings[:3]:
                    print(f"        {YELLOW}{finding.file}:{finding.line_num}{RESET} -> {finding.suggestion}")
                if count > 3:
                    print(f"        ... ve {count - 3} sorun daha (--verbose ile tumu)")

    # Summary
    total_checkers = len(categories)
    covered = len(ANTI_PATTERN_COVERAGE)
    error_checkers = sum(1 for c in categories if c.severity == "error")
    warning_checkers = sum(1 for c in categories if c.severity == "warning")

    print(f"\n{BOLD}=== Code Quality Report ==={RESET}")
    print(f"  Checkers:   {total_checkers} ({error_checkers} error + {warning_checkers} warning)")
    print(f"  Coverage:   {covered}/{total_patterns if total_patterns > 0 else '?'} CLAUDE.md anti-patterns")
    print(f"  Errors:     {total_errors}")
    print(f"  Warnings:   {total_warnings}")

    if total_errors == 0 and total_warnings == 0:
        print(f"  Status:     {GREEN}{BOLD}PASSED{RESET}")
    elif total_errors == 0:
        print(f"  Status:     {YELLOW}{BOLD}PASSED (with warnings){RESET}")
    else:
        print(f"  Status:     {RED}{BOLD}FAILED{RESET}")

    if total_errors > 0 or total_warnings > 0:
        print(f"\n  {YELLOW}Detay icin: python scripts/verify_code_quality.py --verbose{RESET}")

    # Coverage report (verbose only)
    if total_patterns > 0 and VERBOSE:
        uncovered = [i for i in range(1, total_patterns + 1) if i not in ANTI_PATTERN_COVERAGE]
        if uncovered:
            print(f"\n{BOLD}--- Otomatik Kapsam Disi Anti-Pattern'ler ---{RESET}")
            for idx in uncovered:
                if idx <= len(claude_patterns):
                    print(f"  {YELLOW}#{idx}{RESET} {claude_patterns[idx - 1]}")

    # Exit code: 0 for pass/warnings-only, 1 for errors
    return 1 if total_errors > 0 else 0


if __name__ == "__main__":
    sys.exit(main())
