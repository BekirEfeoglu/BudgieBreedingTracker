#!/usr/bin/env python3
"""
CLAUDE.md'deki Codebase Stats tablosunu parse eder ve gercek codebase ile karsilastirir.

Tek kaynak ilkesi (Single Source of Truth): Beklenen degerler CLAUDE.md'den okunur,
hardcoded degerler yerine dosyadaki tablo referans alinir.

Kullanim:
  python scripts/verify_rules.py          # Dogrulama modu (CI icin)
  python scripts/verify_rules.py --fix    # CLAUDE.md'yi otomatik guncelle

Cikti:
  Her kontrol icin PASS/FAIL ve detay bilgisi.
  --fix modunda: CLAUDE.md tablosu gercek degerlerle guncellenir.
"""

import json
import re
import sys
from pathlib import Path
from typing import Optional

ROOT = Path(__file__).resolve().parent.parent
LIB = ROOT / "lib"
ASSETS = ROOT / "assets"
CLAUDE_MD = ROOT / "CLAUDE.md"

FIX_MODE = "--fix" in sys.argv


class Colors:
    GREEN = "\033[92m"
    RED = "\033[91m"
    YELLOW = "\033[93m"
    CYAN = "\033[96m"
    RESET = "\033[0m"
    BOLD = "\033[1m"


# ── Helpers ──────────────────────────────────────────────────────────


def count_files(directory: Path, pattern: str = "*.dart") -> int:
    if not directory.exists():
        return 0
    return len(list(directory.glob(pattern)))


def count_files_recursive(directory: Path, pattern: str = "*.svg") -> int:
    if not directory.exists():
        return 0
    return len(list(directory.rglob(pattern)))


def count_dirs(directory: Path) -> int:
    if not directory.exists():
        return 0
    return len([d for d in directory.iterdir() if d.is_dir()])


def count_json_leaf_keys(filepath: Path) -> int:
    if not filepath.exists():
        return 0
    with open(filepath, "r", encoding="utf-8") as f:
        data = json.load(f)

    def _leaves(obj):
        count = 0
        for v in obj.values():
            count += _leaves(v) if isinstance(v, dict) else 1
        return count

    return _leaves(data)


def count_string_consts(filepath: Path) -> int:
    if not filepath.exists():
        return 0
    content = filepath.read_text(encoding="utf-8")
    return len(re.findall(r"static const\s+", content))


def count_route_consts(filepath: Path) -> int:
    if not filepath.exists():
        return 0
    content = filepath.read_text(encoding="utf-8")
    return len(re.findall(r"static const \w+ = '/", content))


def get_schema_version(filepath: Path) -> int:
    if not filepath.exists():
        return 0
    content = filepath.read_text(encoding="utf-8")
    match = re.search(r"int get schemaVersion\s*=>\s*(\d+)", content)
    return int(match.group(1)) if match else 0


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


def extract_first_number(text: str) -> Optional[int]:
    """Bir string'den ilk sayiyi cikar. '~' prefix'ini tolere eder."""
    text = text.replace("~", "").replace(",", "")
    match = re.search(r"\d+", text)
    return int(match.group()) if match else None


# ── Fix Mode ─────────────────────────────────────────────────────────


def fix_claude_md(updates: dict):
    """CLAUDE.md'deki Codebase Stats tablosundaki degerleri guncelle."""
    content = CLAUDE_MD.read_text(encoding="utf-8")
    lines = content.splitlines()
    changed = False

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
                print(f"  {Colors.YELLOW}FIX{Colors.RESET}  {metric}: {old_value} -> {new_value}")

    if changed:
        CLAUDE_MD.write_text("\n".join(lines) + "\n", encoding="utf-8")
        print(f"\n  {Colors.GREEN}CLAUDE.md guncellendi!{Colors.RESET}")
    else:
        print(f"\n  {Colors.GREEN}CLAUDE.md zaten guncel, degisiklik yok.{Colors.RESET}")


# ── Checks ───────────────────────────────────────────────────────────


def check(description: str, expected: int, actual: int, tolerance: int = 0) -> bool:
    passed = abs(actual - expected) <= tolerance
    status = f"{Colors.GREEN}PASS{Colors.RESET}" if passed else f"{Colors.RED}FAIL{Colors.RESET}"
    detail = f"beklenen={expected}, gercek={actual}"
    if not passed:
        detail += f" {Colors.RED}(fark: {actual - expected:+d}){Colors.RESET}"
    print(f"  [{status}] {description}: {detail}")
    return passed


# ── Actual Value Collectors ──────────────────────────────────────────


def collect_actual_values() -> dict:
    """Codebase'den gercek degerleri topla."""
    models = count_files(LIB / "data" / "models", "*_model.dart")
    enums = count_files(LIB / "core" / "enums", "*_enums.dart")
    tables = count_files(LIB / "data" / "local" / "database" / "tables", "*_table.dart")
    daos = count_files(LIB / "data" / "local" / "database" / "daos", "*_dao.dart")
    mappers = count_files(LIB / "data" / "local" / "database" / "mappers", "*_mapper.dart")

    repo_dir = LIB / "data" / "repositories"
    repos = len([f for f in repo_dir.glob("*_repository.dart") if "base_" not in f.name]) if repo_dir.exists() else 0

    remote_dir = LIB / "data" / "remote" / "api"
    remotes = len([f for f in remote_dir.glob("*_remote_source.dart") if "base_" not in f.name]) if remote_dir.exists() else 0

    features = count_dirs(LIB / "features")
    services = count_dirs(LIB / "domain" / "services")
    icons = count_string_consts(LIB / "core" / "constants" / "app_icons.dart")
    svg_files = count_files_recursive(ASSETS / "icons", "*.svg")
    routes = count_route_consts(LIB / "router" / "route_names.dart")
    schema = get_schema_version(LIB / "data" / "local" / "database" / "app_database.dart")
    tr_keys = count_json_leaf_keys(ASSETS / "translations" / "tr.json")
    supa = count_string_consts(LIB / "core" / "constants" / "supabase_constants.dart")

    widgets_dir = LIB / "core" / "widgets"
    root_w = count_files(widgets_dir)
    sub_w = sum(count_files(d) for d in widgets_dir.iterdir() if d.is_dir()) if widgets_dir.exists() else 0

    # Count sub-widget details for display
    buttons = count_files(widgets_dir / "buttons") if (widgets_dir / "buttons").exists() else 0
    cards = count_files(widgets_dir / "cards") if (widgets_dir / "cards").exists() else 0
    dialogs = count_files(widgets_dir / "dialogs") if (widgets_dir / "dialogs").exists() else 0

    return {
        "models": models,
        "enums": enums,
        "tables": tables,
        "daos": daos,
        "mappers": mappers,
        "repos": repos,
        "remotes": remotes,
        "features": features,
        "services": services,
        "icons": icons,
        "svg_files": svg_files,
        "routes": routes,
        "schema": schema,
        "tr_keys": tr_keys,
        "supa": supa,
        "widgets_total": root_w + sub_w,
        "widgets_root": root_w,
        "widgets_buttons": buttons,
        "widgets_cards": cards,
        "widgets_dialogs": dialogs,
    }


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
        "L10n keys": f"~{a['tr_keys']:,} per language, 35 categories",
        "Supabase constants": f"{a['supa']} (tables + buckets + columns)",
        "Shared widgets": f"{a['widgets_total']} ({a['widgets_root']} root + {a['widgets_buttons']} buttons + {a['widgets_cards']} cards + {a['widgets_dialogs']} dialog)",
    }


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
        fix_claude_md(updates)
        return 0

    # ── Verification Mode ──
    results = []

    def track(result):
        results.append(result)

    print(f"{Colors.BOLD}1. Data Layer{Colors.RESET}")
    track(check("Freezed model sayisi", extract_first_number(stats.get("Freezed models", "0")), actual["models"]))
    track(check("Enum dosya sayisi", extract_first_number(stats.get("Enum files", "0")), actual["enums"]))
    track(check("Drift table sayisi", extract_first_number(stats.get("Drift tables / DAOs / Mappers", "0")), actual["tables"]))
    track(check("DAO sayisi", extract_first_number(stats.get("Drift tables / DAOs / Mappers", "0")), actual["daos"]))
    track(check("Mapper sayisi", extract_first_number(stats.get("Drift tables / DAOs / Mappers", "0")), actual["mappers"]))

    print(f"\n{Colors.BOLD}2. Remote Sources & Repositories{Colors.RESET}")
    track(check("Entity repository sayisi", extract_first_number(stats.get("Repositories", "0")), actual["repos"], tolerance=1))
    track(check("Entity remote source sayisi", extract_first_number(stats.get("Remote sources", "0")), actual["remotes"], tolerance=1))

    print(f"\n{Colors.BOLD}3. Feature Modules & Domain Services{Colors.RESET}")
    track(check("Feature modul sayisi", extract_first_number(stats.get("Feature modules", "0")), actual["features"]))
    track(check("Domain service dizin sayisi", extract_first_number(stats.get("Domain services", "0")), actual["services"]))

    print(f"\n{Colors.BOLD}4. SVG Icons{Colors.RESET}")
    track(check("AppIcons sabit sayisi", extract_first_number(stats.get("Custom SVG icons", "0")), actual["icons"], tolerance=3))
    track(check("SVG dosya sayisi", extract_first_number(stats.get("Custom SVG icons", "0")), actual["svg_files"], tolerance=3))

    print(f"\n{Colors.BOLD}5. Router{Colors.RESET}")
    track(check("Route sabiti sayisi", extract_first_number(stats.get("Routes", "0")), actual["routes"], tolerance=2))

    print(f"\n{Colors.BOLD}6. Database{Colors.RESET}")
    track(check("Schema version", extract_first_number(stats.get("DB schema version", "0")), actual["schema"]))

    print(f"\n{Colors.BOLD}7. Translations{Colors.RESET}")
    expected_keys = extract_first_number(stats.get("L10n keys", "0"))
    en_keys = count_json_leaf_keys(ASSETS / "translations" / "en.json")
    de_keys = count_json_leaf_keys(ASSETS / "translations" / "de.json")
    track(check("TR ceviri anahtar sayisi", expected_keys, actual["tr_keys"], tolerance=50))
    track(check("EN ceviri anahtar sayisi", expected_keys, en_keys, tolerance=50))
    track(check("DE ceviri anahtar sayisi", expected_keys, de_keys, tolerance=50))
    track(check("TR-EN anahtar farki (0 olmali)", 0, abs(actual["tr_keys"] - en_keys), tolerance=5))
    track(check("TR-DE anahtar farki (0 olmali)", 0, abs(actual["tr_keys"] - de_keys), tolerance=5))

    print(f"\n{Colors.BOLD}8. Supabase Constants{Colors.RESET}")
    track(check("Supabase sabit sayisi", extract_first_number(stats.get("Supabase constants", "0")), actual["supa"], tolerance=3))

    print(f"\n{Colors.BOLD}9. Shared Widgets{Colors.RESET}")
    track(check("Toplam widget sayisi", extract_first_number(stats.get("Shared widgets", "0")), actual["widgets_total"], tolerance=2))

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
