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
    collect_edge_function_surfaces,
    collect_storage_bucket_surfaces,
    count_json_leaf_keys,
    extract_first_number,
    extract_markdown_section,
    extract_release_artifact_paths,
)
from _rules_fixers import _apply_inline_fixes, build_fix_updates, fix_claude_md
from _rules_utils import Colors, check, section_factory

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
        # Patch'lenebilir verify_rules ROOT/CLAUDE_MD'sini ileterek test'lerin
        # gercek CLAUDE.md'yi modifiye etmesini engelle.
        fix_claude_md(updates, actual, root=ROOT, claude_md=CLAUDE_MD)
        return 0

    # ── Verification Mode ──
    results = []
    manual_results = []
    section, _section = section_factory()

    def track(result):
        """Track a check that `--fix` can repair (CLAUDE.md stats, inline refs)."""
        results.append(result)

    def track_manual(result):
        """Track a check `--fix` does NOT repair — the summary hint must say so."""
        results.append(result)
        manual_results.append(result)

    def tol(default: int) -> int:
        return 0 if STRICT_MODE else default

    if STRICT_MODE:
        print(f"  {Colors.YELLOW}STRICT modu: tum toleranslar 0{Colors.RESET}\n")

    print(f"{Colors.BOLD}{next(_section)}. Data Layer{Colors.RESET}")
    track(check("Freezed model sayisi", extract_first_number(stats.get("Freezed models", "0")), actual["models"]))
    track(check("Enum dosya sayisi", extract_first_number(stats.get("Enum files", "0")), actual["enums"]))
    track(check("Drift table sayisi", extract_first_number(stats.get("Drift tables / DAOs / Mappers", "0")), actual["tables"]))
    track(check("DAO sayisi", extract_first_number(stats.get("Drift tables / DAOs / Mappers", "0")), actual["daos"]))
    track(check("Mapper sayisi", extract_first_number(stats.get("Drift tables / DAOs / Mappers", "0")), actual["mappers"]))

    print(section("Remote Sources & Repositories"))
    track(check("Entity repository sayisi", extract_first_number(stats.get("Repositories", "0")), actual["repos"]))
    track(check("Entity remote source sayisi", extract_first_number(stats.get("Remote sources", "0")), actual["remotes"]))

    print(section("Feature Modules & Domain Services"))
    track(check("Feature modul sayisi", extract_first_number(stats.get("Feature modules", "0")), actual["features"]))
    track(check("Domain service dizin sayisi", extract_first_number(stats.get("Domain services", "0")), actual["services"]))

    print(section("SVG Icons"))
    track(check("AppIcons sabit sayisi", extract_first_number(stats.get("Custom SVG icons", "0")), actual["icons"], tolerance=tol(1)))
    track(check("SVG dosya sayisi", extract_first_number(stats.get("Custom SVG icons", "0")), actual["svg_files"], tolerance=tol(1)))

    print(section("Router"))
    track(check("Route sabiti sayisi", extract_first_number(stats.get("Routes", "0")), actual["routes"]))

    print(section("Database"))
    track(check("Schema version", extract_first_number(stats.get("DB schema version", "0")), actual["schema"]))

    print(section("Supabase Migrations"))
    # Migration count: CLAUDE.md prose'dan parse et (tablo disinda, inline metin)
    claude_content = CLAUDE_MD.read_text(encoding="utf-8")
    migration_match = re.search(r"(\d+) SQL migration files? in", claude_content)
    expected_migrations = int(migration_match.group(1)) if migration_match else 0
    track(check("SQL migration dosya sayisi", expected_migrations, actual["migrations"], tolerance=tol(2)))

    print(section("Translations"))
    expected_keys = extract_first_number(stats.get("L10n keys", "0"))
    en_keys = count_json_leaf_keys(ASSETS / "translations" / "en.json")
    de_keys = count_json_leaf_keys(ASSETS / "translations" / "de.json")
    track(check("TR ceviri anahtar sayisi", expected_keys, actual["tr_keys"], tolerance=tol(20)))
    track(check("EN ceviri anahtar sayisi", expected_keys, en_keys, tolerance=tol(20)))
    track(check("DE ceviri anahtar sayisi", expected_keys, de_keys, tolerance=tol(20)))
    track(check("TR-EN anahtar farki (0 olmali)", 0, abs(actual["tr_keys"] - en_keys)))
    track(check("TR-DE anahtar farki (0 olmali)", 0, abs(actual["tr_keys"] - de_keys)))

    print(section("Supabase Constants"))
    track(check("Supabase sabit sayisi", extract_first_number(stats.get("Supabase constants", "0")), actual["supa"], tolerance=tol(1)))

    print(section("Shared Widgets"))
    track(check("Toplam widget sayisi", extract_first_number(stats.get("Shared widgets", "0")), actual["widgets_total"]))

    print(section("Test Suite"))
    track(check("Test dosya sayisi", extract_first_number(stats.get("Test files (test/)", "0")), actual["test_files"], tolerance=tol(10)))
    test_stat = stats.get("Test files (test/)", "0")
    individual_match = re.search(r"([\d,]+)\+?\s*individual", test_stat)
    expected_individual = int(individual_match.group(1).replace(",", "")) if individual_match else 0
    track(check("Bireysel test sayisi", expected_individual, actual["individual_tests"], tolerance=tol(100)))
    track(check("Kaynak dosya sayisi (lib/)", extract_first_number(stats.get("Source files (lib/)", "0")), actual["source_files"], tolerance=tol(10)))

    print(section("Inline Drift"))
    inline_targets = [CLAUDE_MD]
    rules_dir = ROOT / ".claude" / "rules"
    if rules_dir.exists():
        for rule_file in sorted(rules_dir.glob("*.md")):
            inline_targets.append(rule_file)

    from _rules_fixers import _file_label
    inline_drift = 0
    for filepath in inline_targets:
        content = filepath.read_text(encoding="utf-8")
        fixed, messages = _apply_inline_fixes(content, actual)
        if fixed != content:
            label = _file_label(filepath)
            for msg in messages:
                print(f"  {Colors.YELLOW}WARN{Colors.RESET} [{label}] {msg} (calistir: --fix)")
            inline_drift += len(messages)
    if inline_drift == 0:
        print(f"  {Colors.GREEN}PASS{Colors.RESET} Tum inline referanslar guncel")

    print(section("Cross-References"))
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

    print(section("Release Artifacts"))
    # documentation-sync.md: release/deploy changes must land the owning rule
    # AND CLAUDE.md together. Counts cannot catch a half-landed update, so
    # compare the artifact paths CLAUDE.md claims against release-ops.md and
    # against the scripts/workflows that actually emit them.
    release_ops = ROOT / ".claude" / "rules" / "release-ops.md"
    producers = [
        ROOT / "scripts" / "build_release.sh",
        ROOT / ".github" / "workflows" / "release-ready.yml",
    ]
    claimed_paths = extract_release_artifact_paths(
        extract_markdown_section(claude_content, "### Release Builds")
    )
    existing_producers = [p for p in producers if p.exists()]
    if not claimed_paths:
        print(f"  {Colors.YELLOW}SKIP{Colors.RESET} CLAUDE.md § Release Builds icinde build/ yolu yok")
    else:
        if release_ops.exists():
            ops_text = release_ops.read_text(encoding="utf-8")
            undocumented = sorted(p for p in claimed_paths if p not in ops_text)
            for path in undocumented:
                print(f"  {Colors.YELLOW}WARN{Colors.RESET} {path}: CLAUDE.md'de var, release-ops.md'de yok")
            track_manual(check("Artefakt yollari release-ops.md ile ayni", 0, len(undocumented)))
        else:
            print(f"  {Colors.YELLOW}SKIP{Colors.RESET} release-ops.md bulunamadi")

        if existing_producers:
            producer_text = "\n".join(p.read_text(encoding="utf-8") for p in existing_producers)
            unproduced = sorted(p for p in claimed_paths if p not in producer_text)
            for path in unproduced:
                print(f"  {Colors.YELLOW}WARN{Colors.RESET} {path}: hicbir release script/workflow bu yolu uretmiyor")
            track_manual(check("Artefakt yollari gercek ureticiyle eslesiyor", 0, len(unproduced)))
        else:
            print(f"  {Colors.YELLOW}SKIP{Colors.RESET} release script/workflow bulunamadi")

    print(section("Edge Functions"))
    # edge-functions.md: no EdgeFunctionName constants class exists, so the
    # function name is a repeated literal on four surfaces. A drifted name
    # fails at runtime (404), on deploy, or silently (stale _rateLimitExempt).
    surfaces = collect_edge_function_surfaces(ROOT)
    on_disk = surfaces["disk"]
    if not on_disk:
        print(f"  {Colors.YELLOW}SKIP{Colors.RESET} supabase/functions/ bulunamadi")
    else:
        def _compare(label: str, names, description: str):
            """Two-way set comparison against the function directories."""
            if names is None:
                print(f"  {Colors.YELLOW}SKIP{Colors.RESET} {label} bulunamadi")
                return
            for name in sorted(on_disk - names):
                print(f"  {Colors.YELLOW}WARN{Colors.RESET} {name}: dizin var, {label} icinde yok")
            for name in sorted(names - on_disk):
                print(f"  {Colors.YELLOW}WARN{Colors.RESET} {name}: {label} icinde var, dizin yok")
            track_manual(check(description, 0, len(on_disk ^ names)))

        _compare("supabase/config.toml", surfaces["config"], "config.toml adlari dizinlerle ayni")
        _compare("ci.yml deploy listesi", surfaces["deploy"], "Deploy listesi dizinlerle ayni")

        # One-way only: a function may legitimately be invoked by a webhook,
        # DB trigger or cron instead of the client (edge-functions.md
        # § Invocation Completeness), so absence from the client is not drift.
        if surfaces["client"] is None:
            print(f"  {Colors.YELLOW}SKIP{Colors.RESET} edge_function_client.dart bulunamadi")
        else:
            unknown = sorted(surfaces["client"] - on_disk)
            for name in unknown:
                print(f"  {Colors.YELLOW}WARN{Colors.RESET} {name}: client literali, boyle bir fonksiyon yok")
            track_manual(check("Client literalleri gercek fonksiyona isaret ediyor", 0, len(unknown)))

    print(section("Storage Buckets"))
    # Third repeated-literal surface: a bucket id lives in SupabaseConstants,
    # is provisioned by a migration, and is described in assets-images.md.
    # A constant naming an unprovisioned bucket fails at upload, not at build.
    buckets = collect_storage_bucket_surfaces(ROOT)
    constants = buckets["constants"]
    if not constants:
        print(f"  {Colors.YELLOW}SKIP{Colors.RESET} SupabaseConstants bucket sabiti bulunamadi")
    else:
        if buckets["migrations"] is None:
            print(f"  {Colors.YELLOW}SKIP{Colors.RESET} supabase/migrations/ bulunamadi")
        else:
            for name in sorted(constants - buckets["migrations"]):
                print(f"  {Colors.YELLOW}WARN{Colors.RESET} {name}: sabit var, hicbir migration provision etmiyor")
            for name in sorted(buckets["migrations"] - constants):
                print(f"  {Colors.YELLOW}WARN{Colors.RESET} {name}: migration'da var, SupabaseConstants'ta sabiti yok")
            track_manual(check(
                "Bucket sabitleri migration'larla ayni", 0,
                len(constants ^ buckets["migrations"]),
            ))

        # One-way only: the rule deliberately names buckets that do NOT exist
        # (`chat-attachments`, `health-records`) to stop them being invented.
        if buckets["doc_text"] is None:
            print(f"  {Colors.YELLOW}SKIP{Colors.RESET} assets-images.md bulunamadi")
        else:
            undocumented = sorted(n for n in constants if f"`{n}`" not in buckets["doc_text"])
            for name in undocumented:
                print(f"  {Colors.YELLOW}WARN{Colors.RESET} {name}: assets-images.md'de belgelenmemis")
            track_manual(check("Bucket sabitleri assets-images.md'de belgeli", 0, len(undocumented)))

    # ── Summary ──
    pass_count = sum(results)
    fail_count = len(results) - pass_count

    print(f"\n{Colors.BOLD}{Colors.CYAN}=== OZET ==={Colors.RESET}")
    print(f"  Toplam kontrol: {len(results)}")
    print(f"  {Colors.GREEN}Basarili: {pass_count}{Colors.RESET}")
    manual_fail = len(manual_results) - sum(manual_results)
    fixable_fail = fail_count - manual_fail

    if fail_count > 0:
        print(f"  {Colors.RED}Basarisiz: {fail_count}{Colors.RESET}")
        # Cross-surface checks are not auto-fixable; pointing at --fix for
        # those sends the reader to a command that changes nothing.
        if fixable_fail > 0:
            print(f"\n  {Colors.YELLOW}Ipucu: 'python scripts/verify_rules.py --fix' ile otomatik duzelt{Colors.RESET}")
        if manual_fail > 0:
            print(f"\n  {Colors.YELLOW}Ipucu: {manual_fail} capraz-yuzey hatasi --fix ile duzelmez; "
                  f"yukaridaki WARN satirlarindaki yuzeyleri elle esitle{Colors.RESET}")
    else:
        print(f"  {Colors.GREEN}Tum kontroller basarili!{Colors.RESET}")

    print()
    return 0 if fail_count == 0 else 1


if __name__ == "__main__":
    sys.exit(main())
