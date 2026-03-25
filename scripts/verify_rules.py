#!/usr/bin/env python3
"""
CLAUDE.md'deki Codebase Stats tablosunu parse eder ve gercek codebase ile karsilastirir.

Tek kaynak ilkesi (Single Source of Truth): Beklenen degerler CLAUDE.md'den okunur,
hardcoded degerler yerine dosyadaki tablo referans alinir.

Kullanim:
  python scripts/verify_rules.py             # Dogrulama modu (CI icin, toleransli)
  python scripts/verify_rules.py --strict    # Toleranssiz exact match (CI icin)
  python scripts/verify_rules.py --fix       # CLAUDE.md + rule dosyalarini otomatik guncelle

Cikti:
  Her kontrol icin PASS/FAIL ve detay bilgisi.
  --fix modunda: CLAUDE.md tablosu + inline referanslar gercek degerlerle guncellenir.
"""

import re
import sys
from pathlib import Path

from _rules_collectors import (
    collect_actual_values,
    count_json_leaf_keys,
    extract_first_number,
)
from _rules_fixers import Colors, build_fix_updates, fix_claude_md

ROOT = Path(__file__).resolve().parent.parent
ASSETS = ROOT / "assets"
CLAUDE_MD = ROOT / "CLAUDE.md"

FIX_MODE = "--fix" in sys.argv
STRICT_MODE = "--strict" in sys.argv


# ── CLAUDE.md Parser ─────────────────────────────────────────────────


def parse_claude_md_stats() -> dict:
    """CLAUDE.md'deki Codebase Stats tablosunu parse et."""
    content = CLAUDE_MD.read_text(encoding="utf-8")

    in_table = False
    stats = {}
    for line in content.splitlines():
        if "| Metric | Value |" in line:
            in_table = True
            continue
        if in_table and line.startswith("| ---"):
            continue
        if in_table and line.startswith("|"):
            parts = [p.strip() for p in line.split("|")[1:-1]]
            if len(parts) == 2:
                stats[parts[0]] = parts[1]
        elif in_table and not line.startswith("|"):
            break

    return stats


# ── Checks ───────────────────────────────────────────────────────────


def check(description: str, expected: int, actual: int, tolerance: int = 0) -> bool:
    passed = abs(actual - expected) <= tolerance
    status = f"{Colors.GREEN}PASS{Colors.RESET}" if passed else f"{Colors.RED}FAIL{Colors.RESET}"
    detail = f"beklenen={expected}, gercek={actual}"
    if not passed:
        detail += f" {Colors.RED}(fark: {actual - expected:+d}){Colors.RESET}"
    print(f"  [{status}] {description}: {detail}")
    return passed


# ── Main ─────────────────────────────────────────────────────────────


def main():
    mode_label = "FIX" if FIX_MODE else "Dogrulama"
    print(f"\n{Colors.BOLD}{Colors.CYAN}=== CLAUDE.md {mode_label} Raporu ==={Colors.RESET}")
    print(f"  Kaynak: {CLAUDE_MD.relative_to(ROOT)}\n")

    stats = parse_claude_md_stats()
    if not stats:
        print(f"  {Colors.RED}HATA: CLAUDE.md'de Codebase Stats tablosu bulunamadi!{Colors.RESET}")
        return 1

    actual = collect_actual_values()

    if FIX_MODE:
        updates = build_fix_updates(actual)
        fix_claude_md(updates, actual)
        return 0

    # ── Verification Mode ──
    results = []

    def track(result):
        results.append(result)

    def tol(default: int) -> int:
        return 0 if STRICT_MODE else default

    if STRICT_MODE:
        print(f"  {Colors.YELLOW}STRICT modu: tum toleranslar 0{Colors.RESET}\n")

    print(f"{Colors.BOLD}1. Data Layer{Colors.RESET}")
    track(check("Freezed model sayisi", extract_first_number(stats.get("Freezed models", "0")), actual["models"]))
    track(check("Enum dosya sayisi", extract_first_number(stats.get("Enum files", "0")), actual["enums"]))
    track(check("Drift table sayisi", extract_first_number(stats.get("Drift tables / DAOs / Mappers", "0")), actual["tables"]))
    track(check("DAO sayisi", extract_first_number(stats.get("Drift tables / DAOs / Mappers", "0")), actual["daos"]))
    track(check("Mapper sayisi", extract_first_number(stats.get("Drift tables / DAOs / Mappers", "0")), actual["mappers"]))

    print(f"\n{Colors.BOLD}2. Remote Sources & Repositories{Colors.RESET}")
    track(check("Entity repository sayisi", extract_first_number(stats.get("Repositories", "0")), actual["repos"], tolerance=tol(1)))
    track(check("Entity remote source sayisi", extract_first_number(stats.get("Remote sources", "0")), actual["remotes"], tolerance=tol(1)))

    print(f"\n{Colors.BOLD}3. Feature Modules & Domain Services{Colors.RESET}")
    track(check("Feature modul sayisi", extract_first_number(stats.get("Feature modules", "0")), actual["features"]))
    track(check("Domain service dizin sayisi", extract_first_number(stats.get("Domain services", "0")), actual["services"]))

    print(f"\n{Colors.BOLD}4. SVG Icons{Colors.RESET}")
    track(check("AppIcons sabit sayisi", extract_first_number(stats.get("Custom SVG icons", "0")), actual["icons"], tolerance=tol(3)))
    track(check("SVG dosya sayisi", extract_first_number(stats.get("Custom SVG icons", "0")), actual["svg_files"], tolerance=tol(3)))

    print(f"\n{Colors.BOLD}5. Router{Colors.RESET}")
    track(check("Route sabiti sayisi", extract_first_number(stats.get("Routes", "0")), actual["routes"], tolerance=tol(2)))

    print(f"\n{Colors.BOLD}6. Database{Colors.RESET}")
    track(check("Schema version", extract_first_number(stats.get("DB schema version", "0")), actual["schema"]))

    print(f"\n{Colors.BOLD}7. Translations{Colors.RESET}")
    expected_keys = extract_first_number(stats.get("L10n keys", "0"))
    en_keys = count_json_leaf_keys(ASSETS / "translations" / "en.json")
    de_keys = count_json_leaf_keys(ASSETS / "translations" / "de.json")
    track(check("TR ceviri anahtar sayisi", expected_keys, actual["tr_keys"], tolerance=tol(50)))
    track(check("EN ceviri anahtar sayisi", expected_keys, en_keys, tolerance=tol(50)))
    track(check("DE ceviri anahtar sayisi", expected_keys, de_keys, tolerance=tol(50)))
    track(check("TR-EN anahtar farki (0 olmali)", 0, abs(actual["tr_keys"] - en_keys), tolerance=tol(5)))
    track(check("TR-DE anahtar farki (0 olmali)", 0, abs(actual["tr_keys"] - de_keys), tolerance=tol(5)))

    print(f"\n{Colors.BOLD}8. Supabase Constants{Colors.RESET}")
    track(check("Supabase sabit sayisi", extract_first_number(stats.get("Supabase constants", "0")), actual["supa"], tolerance=tol(3)))

    print(f"\n{Colors.BOLD}9. Shared Widgets{Colors.RESET}")
    track(check("Toplam widget sayisi", extract_first_number(stats.get("Shared widgets", "0")), actual["widgets_total"], tolerance=tol(2)))

    print(f"\n{Colors.BOLD}10. Cross-References{Colors.RESET}")
    rules_dir = ROOT / ".claude" / "rules"
    ref_pattern = re.compile(r'`(\w[\w-]*\.md)`\s*\u2192\s*["\u201C]([^"\u201D]+)["\u201D]')
    broken_refs = 0
    if rules_dir.exists():
        for rule_file in sorted(rules_dir.glob("*.md")):
            content = rule_file.read_text(encoding="utf-8")
            for match in ref_pattern.finditer(content):
                target_file = rules_dir / match.group(1)
                target_section = match.group(2)
                if not target_file.exists():
                    print(f"  {Colors.YELLOW}WARN{Colors.RESET} {rule_file.name}: kirik referans \u2192 {match.group(1)}")
                    broken_refs += 1
                else:
                    target_content = target_file.read_text(encoding="utf-8")
                    if target_section.lower() not in target_content.lower():
                        print(f"  {Colors.YELLOW}WARN{Colors.RESET} {rule_file.name}: bolum bulunamadi \u2192 {match.group(1)} \u2192 \"{target_section}\"")
                        broken_refs += 1
        if broken_refs == 0:
            print(f"  {Colors.GREEN}PASS{Colors.RESET} Tum cross-reference'lar gecerli")
        else:
            print(f"  {Colors.YELLOW}WARN{Colors.RESET} {broken_refs} kirik referans bulundu")
    else:
        print(f"  {Colors.YELLOW}SKIP{Colors.RESET} .claude/rules/ dizini bulunamadi")

    # ── Summary ──
    pass_count = sum(results)
    fail_count = len(results) - pass_count

    print(f"\n{Colors.BOLD}{Colors.CYAN}=== OZET ==={Colors.RESET}")
    print(f"  Toplam kontrol: {len(results)}")
    print(f"  {Colors.GREEN}Basarili: {pass_count}{Colors.RESET}")
    if fail_count > 0:
        print(f"  {Colors.RED}Basarisiz: {fail_count}{Colors.RESET}")
        print(f"\n  {Colors.YELLOW}Ipucu: 'python scripts/verify_rules.py --fix' ile otomatik duzelt{Colors.RESET}")
    else:
        print(f"  {Colors.GREEN}Tum kontroller basarili!{Colors.RESET}")

    print()
    return 0 if fail_count == 0 else 1


if __name__ == "__main__":
    sys.exit(main())
