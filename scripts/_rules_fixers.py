"""CLAUDE.md tablo ve inline referans guncelleme fonksiyonlari."""

import re
from pathlib import Path
from typing import Optional

from _rules_utils import Colors

ROOT = Path(__file__).resolve().parent.parent
CLAUDE_MD = ROOT / "CLAUDE.md"
RULES_CLAUDE_MD = ROOT / ".claude" / "rules" / "CLAUDE.md"


def build_fix_updates(actual: dict) -> dict:
    """Gercek degerlerden CLAUDE.md tablo satir guncellemeleri olustur."""
    a = actual
    return {
        "Freezed models": f"{a['models']} model files + statistics_models + supabase_extensions",
        "Enum files": str(a["enums"]),
        "Drift tables / DAOs / Mappers": f"{a['tables']} each",
        "Repositories": f"{a['repos']} entity + base + sync_metadata",
        "Remote sources": f"{a['remotes']} entity + base + 2 caches + providers",
        "Feature modules": str(a["features"]),
        "Domain services": f"{a['services']} directories",
        "Custom SVG icons": f"{a['icons']} constants, {a['svg_files']} files on disk",
        "Routes": str(a["routes"]),
        "DB schema version": str(a["schema"]),
        "L10n keys": f"~{a['tr_keys']:,} per language, {a['categories']} categories",
        "Supabase constants": f"{a['supa']} (tables + buckets + columns)",
        "Shared widgets": f"{a['widgets_total']} ({a['widgets_root']} root + {a['widgets_buttons']} buttons + {a['widgets_cards']} cards + {a['widgets_dialogs']} dialog)",
        "Source files (lib/)": f"{a['source_files']} Dart files",
        "Test files (test/)": f"{a['test_files']} test files, {a['individual_tests']:,}+ individual tests",
    }


def _apply_inline_fixes(content: str, actual: dict) -> tuple[str, list[str]]:
    """Inline referanslari guncelle. (updated_content, fix_messages) tuple'i dondurur."""
    updated = content
    messages = []

    # L10n key referanslari: "~X,XXX (leaf )keys per language"
    l10n_pattern = re.compile(r"~[\d,]+ (leaf )?keys? per language")

    def _replace_l10n(m):
        if "leaf" in m.group():
            return f"~{actual['tr_keys']:,} leaf keys per language"
        return f"~{actual['tr_keys']:,} keys per language"

    fixed = l10n_pattern.sub(_replace_l10n, updated)
    fixed = re.sub(r"~[\d,]+ leaf keys\)", f"~{actual['tr_keys']:,} leaf keys)", fixed)
    if fixed != updated:
        updated = fixed
        messages.append("Inline L10n key references updated")

    # Shared UI widget count: "(N widgets: X root + Y buttons + Z cards + W dialog)"
    w = actual
    new_widget_inline = (
        f"({w['widgets_total']} widgets: {w['widgets_root']} root"
        f" + {w['widgets_buttons']} buttons + {w['widgets_cards']} cards"
        f" + {w['widgets_dialogs']} dialog)"
    )
    fixed = re.sub(
        r"\(\d+ widgets: \d+ root \+ \d+ buttons \+ \d+ cards \+ \d+ dialog\)",
        new_widget_inline,
        updated,
    )
    if fixed != updated:
        updated = fixed
        messages.append("Inline Shared UI widget count updated")

    # schemaVersion inline
    fixed = re.sub(r"schemaVersion \d+", f"schemaVersion {w['schema']}", updated)
    if fixed != updated:
        updated = fixed
        messages.append("Inline schemaVersion updated")

    # SVG icon count: "NN custom SVG icons in"
    fixed = re.sub(
        r"\d+ custom SVG icons in",
        f"{actual['icons']} custom SVG icons in",
        updated,
    )
    if fixed != updated:
        updated = fixed
        messages.append("Inline SVG icon count updated")

    # Composite indexes: "NN+ composite indexes" or "NN composite indexes"
    idx_count = actual.get("indexes")
    if idx_count is None:
        raise KeyError("'indexes' key missing from actual values — _count_indexes may have failed")
    fixed = re.sub(
        r"\d+\+? (?:composite |performance )indexes",
        f"{idx_count} composite indexes",
        updated,
    )
    if fixed != updated:
        updated = fixed
        messages.append("Inline composite index count updated")

    # SupabaseConstants count: "— NN constants"
    fixed = re.sub(
        r"\u2014 \d+ constants",
        f"\u2014 {actual['supa']} constants",
        updated,
    )
    if fixed != updated:
        updated = fixed
        messages.append("Inline SupabaseConstants count updated")

    # Migration file count: "NNN SQL migration files in"
    migrations = actual.get("migrations")
    if migrations is not None:
        fixed = re.sub(
            r"\d+ SQL migration files? in",
            f"{migrations} SQL migration files in",
            updated,
        )
        if fixed != updated:
            updated = fixed
            messages.append("Inline migration file count updated")

        # Key File Locations: "supabase/migrations/ (NNN files)"
        fixed = re.sub(
            r"supabase/migrations/ \(\d+ files\)",
            f"supabase/migrations/ ({migrations} files)",
            updated,
        )
        if fixed != updated:
            updated = fixed
            messages.append("Inline migrations key location updated")

    return updated, messages


def _file_label(filepath: Path) -> str:
    """Dosya icin anlasilir etiket uret (ayni adli dosyalari ayirt eder)."""
    try:
        parts = filepath.relative_to(ROOT).parts
        # .claude/rules/CLAUDE.md  →  "CLAUDE.md (rules)"
        # CLAUDE.md                →  "CLAUDE.md (root)"
        if len(parts) >= 2 and parts[-2] == "rules":
            return f"{filepath.name} (rules)"
        if len(parts) == 1:
            return f"{filepath.name} (root)"
    except ValueError:
        pass
    return filepath.name


def _fix_file(
    filepath: Path,
    updates: dict,
    actual: dict,
    *,
    apply_table_fixes: bool = True,
) -> bool:
    """Verilen dosyada tablo satirlarini ve inline referanslari guncelle.

    Args:
        apply_table_fixes: If False, only inline references are updated.
            Table row fixes (Codebase Stats) are restricted to CLAUDE.md (root)
            to prevent accidental rewrites of rule-file tables.
    """
    label = _file_label(filepath)
    content = filepath.read_text(encoding="utf-8")
    lines = content.splitlines()
    changed = False

    if apply_table_fixes:
        for i, line in enumerate(lines):
            if not line.startswith("|") or "---" in line or "Metric" in line:
                continue
            parts = [p.strip() for p in line.split("|")[1:-1]]
            if len(parts) != 2:
                continue
            metric = parts[0]
            if metric in updates:
                old_value = parts[1]
                new_value = updates[metric]
                if old_value != new_value:
                    lines[i] = f"| {metric} | {new_value} |"
                    changed = True
                    print(f"  {Colors.YELLOW}FIX{Colors.RESET}  [{label}] {metric}: {old_value} -> {new_value}")

    new_content = "\n".join(lines)
    updated, messages = _apply_inline_fixes(new_content, actual)
    for msg in messages:
        print(f"  {Colors.YELLOW}FIX{Colors.RESET}  [{label}] {msg}")
    if updated != new_content:
        changed = True
        new_content = updated

    if changed:
        filepath.write_text(
            new_content + "\n" if not new_content.endswith("\n") else new_content,
            encoding="utf-8",
        )
    return changed


def fix_claude_md(
    updates: dict,
    actual: dict,
    *,
    root: Optional[Path] = None,
    claude_md: Optional[Path] = None,
):
    """CLAUDE.md ve .claude/rules/*.md'deki tablo + inline referanslari guncelle.

    Args:
        updates: Codebase Stats tablo satirlari icin guncelleme dict'i.
        actual: Kaynak kodtan toplanan gercek degerler.
        root: Repo kok dizini. Verilmezse modul-seviyesi ROOT kullanilir.
        claude_md: Kok CLAUDE.md dosyasi. Verilmezse modul-seviyesi CLAUDE_MD kullanilir.

    Test izolasyonu: argumanlari acikca alarak cagrici (verify_rules.main)
    kendi patch edilmis ROOT/CLAUDE_MD'sini iletebilir; boylece test'lerde
    yanlislikla unit test fixture'lariyla gercek CLAUDE.md uzerine yazilmaz.
    """
    if root is None:
        root = ROOT
    if claude_md is None:
        claude_md = CLAUDE_MD

    rules_dir = root / ".claude" / "rules"
    targets = [claude_md]
    if rules_dir.exists():
        for rule_file in sorted(rules_dir.glob("*.md")):
            targets.append(rule_file)

    any_changed = False
    for fp in targets:
        # Table row fixes (Codebase Stats) only apply to root CLAUDE.md.
        # Rule files only get inline reference updates to avoid rewriting
        # unrelated tables (e.g., schema version in data-layer.md).
        is_root = fp == claude_md
        if _fix_file(fp, updates, actual, apply_table_fixes=is_root):
            any_changed = True

    if any_changed:
        print(f"\n  {Colors.GREEN}Dosyalar guncellendi!{Colors.RESET}")
    else:
        print(f"\n  {Colors.GREEN}Tum dosyalar zaten guncel, degisiklik yok.{Colors.RESET}")
