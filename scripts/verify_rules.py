#!/usr/bin/env python3
"""
.claude/rules/ dosyalarindaki sayisal iddialari gercek codebase ile karsilastirir.

Kullanim:
  python scripts/verify_rules.py

Cikti:
  Her kontrol icin PASS/FAIL ve detay bilgisi.
"""

import os
import re
import json
import sys
from pathlib import Path
from collections import defaultdict

# Proje kok dizini (scriptin bulundugu yere gore)
ROOT = Path(__file__).resolve().parent.parent
LIB = ROOT / "lib"
ASSETS = ROOT / "assets"
RULES = ROOT / ".claude" / "rules"


class Colors:
    GREEN = "\033[92m"
    RED = "\033[91m"
    YELLOW = "\033[93m"
    CYAN = "\033[96m"
    RESET = "\033[0m"
    BOLD = "\033[1m"


def count_files(directory: Path, pattern: str = "*.dart") -> int:
    """Belirli bir dizindeki dosyalari say (alt dizinler haric)."""
    if not directory.exists():
        return 0
    return len(list(directory.glob(pattern)))


def count_files_recursive(directory: Path, pattern: str = "*.svg") -> int:
    """Belirli bir dizindeki dosyalari alt dizinlerle birlikte say."""
    if not directory.exists():
        return 0
    return len(list(directory.rglob(pattern)))


def count_dirs(directory: Path) -> int:
    """Belirli bir dizindeki alt dizin sayisini dondur."""
    if not directory.exists():
        return 0
    return len([d for d in directory.iterdir() if d.is_dir()])


def count_json_keys(filepath: Path) -> int:
    """JSON dosyasindaki tum iç içe anahtar sayisini say."""
    if not filepath.exists():
        return 0
    with open(filepath, "r", encoding="utf-8") as f:
        data = json.load(f)
    return _count_leaf_keys(data)


def _count_leaf_keys(obj, depth=0) -> int:
    """Yaprak (leaf) anahtar sayisini recursive say."""
    if isinstance(obj, dict):
        count = 0
        for v in obj.values():
            if isinstance(v, dict):
                count += _count_leaf_keys(v, depth + 1)
            else:
                count += 1
        return count
    return 0


def count_string_consts(filepath: Path, pattern: str = r"static const\s+\w+\s*=") -> int:
    """Bir Dart dosyasindaki static const tanimlarini say."""
    if not filepath.exists():
        return 0
    content = filepath.read_text(encoding="utf-8")
    return len(re.findall(pattern, content))


def count_route_consts(filepath: Path) -> int:
    """route_names.dart'taki route sabitlerini say."""
    if not filepath.exists():
        return 0
    content = filepath.read_text(encoding="utf-8")
    return len(re.findall(r"static const \w+ = '/", content))


def get_schema_version(filepath: Path) -> int:
    """app_database.dart'tan schemaVersion degerini oku."""
    if not filepath.exists():
        return 0
    content = filepath.read_text(encoding="utf-8")
    match = re.search(r"int get schemaVersion\s*=>\s*(\d+)", content)
    return int(match.group(1)) if match else 0


def check_rule_claim(description: str, expected, actual, tolerance: int = 0):
    """Bir kural iddiasini kontrol et ve sonucu yazdir."""
    passed = abs(actual - expected) <= tolerance if isinstance(expected, int) else actual == expected
    status = f"{Colors.GREEN}PASS{Colors.RESET}" if passed else f"{Colors.RED}FAIL{Colors.RESET}"
    detail = f"beklenen={expected}, gercek={actual}"
    if not passed:
        detail += f" {Colors.RED}(fark: {actual - expected if isinstance(expected, int) else 'uyumsuz'}){Colors.RESET}"
    print(f"  [{status}] {description}: {detail}")
    return passed


def main():
    print(f"\n{Colors.BOLD}{Colors.CYAN}=== .claude/rules Dogrulama Raporu ==={Colors.RESET}\n")

    pass_count = 0
    fail_count = 0
    total = 0

    def track(result: bool):
        nonlocal pass_count, fail_count, total
        total += 1
        if result:
            pass_count += 1
        else:
            fail_count += 1

    # --- 1. Data Layer Counts ---
    print(f"{Colors.BOLD}1. Data Layer (Models, Enums, Tables, DAOs, Mappers){Colors.RESET}")

    models_dir = LIB / "data" / "models"
    model_files = [f for f in models_dir.glob("*_model.dart")] if models_dir.exists() else []
    freezed_count = len(model_files)
    # statistics_models.dart (model.dart olmayan ama Freezed iceren dosya) ayri sayilmaz
    # architecture.md "20 Freezed model files (incl. statistics_models)" der
    track(check_rule_claim("Freezed model sayisi", 20, freezed_count))

    track(check_rule_claim("Enum dosya sayisi (core/enums/)", 11,
                           count_files(LIB / "core" / "enums", "*_enums.dart")))

    track(check_rule_claim("Drift table sayisi", 19,
                           count_files(LIB / "data" / "local" / "database" / "tables", "*_table.dart")))

    track(check_rule_claim("DAO sayisi", 19,
                           count_files(LIB / "data" / "local" / "database" / "daos", "*_dao.dart")))

    mapper_dir = LIB / "data" / "local" / "database" / "mappers"
    track(check_rule_claim("Mapper sayisi", 19,
                           count_files(mapper_dir, "*_mapper.dart"), tolerance=1))

    # --- 2. Remote & Repository Layer ---
    print(f"\n{Colors.BOLD}2. Remote Sources & Repositories{Colors.RESET}")

    remote_dir = LIB / "data" / "remote" / "api"
    remote_sources = [f for f in remote_dir.glob("*_remote_source.dart")] if remote_dir.exists() else []
    base_remote = [f for f in remote_sources if "base_" in f.name]
    entity_remote = [f for f in remote_sources if "base_" not in f.name]
    track(check_rule_claim("Entity remote source sayisi", 19, len(entity_remote), tolerance=1))

    repo_dir = LIB / "data" / "repositories"
    repo_files = [f for f in repo_dir.glob("*_repository.dart")] if repo_dir.exists() else []
    base_repo = [f for f in repo_files if "base_" in f.name]
    entity_repos = [f for f in repo_files if "base_" not in f.name]
    track(check_rule_claim("Entity repository sayisi", 20, len(entity_repos), tolerance=1))

    # --- 3. Feature Modules ---
    print(f"\n{Colors.BOLD}3. Feature Modules & Domain Services{Colors.RESET}")

    track(check_rule_claim("Feature modul sayisi (features/)", 20,
                           count_dirs(LIB / "features")))

    track(check_rule_claim("Domain service dizin sayisi", 12,
                           count_dirs(LIB / "domain" / "services")))

    # --- 4. Icons ---
    print(f"\n{Colors.BOLD}4. SVG Icons{Colors.RESET}")

    track(check_rule_claim("SVG dosya sayisi (assets/icons/)", 82,
                           count_files_recursive(ASSETS / "icons", "*.svg"), tolerance=3))

    track(check_rule_claim("Icon alt dizin sayisi", 10,
                           count_dirs(ASSETS / "icons")))

    app_icons_file = LIB / "core" / "constants" / "app_icons.dart"
    track(check_rule_claim("AppIcons sabit sayisi", 82,
                           count_string_consts(app_icons_file), tolerance=3))

    # --- 5. Theme & Core ---
    print(f"\n{Colors.BOLD}5. Core Layer{Colors.RESET}")

    track(check_rule_claim("Theme dosya sayisi", 4,
                           count_files(LIB / "core" / "theme"), tolerance=2))

    track(check_rule_claim("Utils dosya sayisi", 2,
                           count_files(LIB / "core" / "utils")))

    track(check_rule_claim("Extensions dosya sayisi", 1,
                           count_files(LIB / "core" / "extensions")))

    track(check_rule_claim("Errors dosya sayisi", 1,
                           count_files(LIB / "core" / "errors")))

    # --- 6. Router ---
    print(f"\n{Colors.BOLD}6. Router{Colors.RESET}")

    route_names = LIB / "router" / "route_names.dart"
    track(check_rule_claim("Route sabiti sayisi", 52,
                           count_route_consts(route_names), tolerance=2))

    track(check_rule_claim("Guard dosya sayisi", 2,
                           count_files(LIB / "router" / "guards"), tolerance=1))

    # --- 7. Database ---
    print(f"\n{Colors.BOLD}7. Database{Colors.RESET}")

    app_db = LIB / "data" / "local" / "database" / "app_database.dart"
    track(check_rule_claim("Schema version", 12, get_schema_version(app_db)))

    # --- 8. Translations ---
    print(f"\n{Colors.BOLD}8. Translations{Colors.RESET}")

    tr_keys = count_json_keys(ASSETS / "translations" / "tr.json")
    en_keys = count_json_keys(ASSETS / "translations" / "en.json")
    de_keys = count_json_keys(ASSETS / "translations" / "de.json")

    track(check_rule_claim("TR ceviri anahtar sayisi (~1732)", 1732, tr_keys, tolerance=50))
    track(check_rule_claim("EN ceviri anahtar sayisi (~1732)", 1732, en_keys, tolerance=50))
    track(check_rule_claim("DE ceviri anahtar sayisi (~1732)", 1732, de_keys, tolerance=50))

    tr_en_diff = abs(tr_keys - en_keys)
    tr_de_diff = abs(tr_keys - de_keys)
    track(check_rule_claim("TR-EN anahtar farki (0 olmali)", 0, tr_en_diff, tolerance=5))
    track(check_rule_claim("TR-DE anahtar farki (0 olmali)", 0, tr_de_diff, tolerance=5))

    # --- 9. Shared Widgets ---
    print(f"\n{Colors.BOLD}9. Shared Widgets{Colors.RESET}")

    widgets_dir = LIB / "core" / "widgets"
    widget_subdirs = count_dirs(widgets_dir)
    track(check_rule_claim("Widget alt dizin sayisi (buttons, cards, dialogs)", 3,
                           widget_subdirs, tolerance=1))

    # --- 10. Skills ---
    print(f"\n{Colors.BOLD}10. Skills (.claude/skills/){Colors.RESET}")

    skills_dir = ROOT / ".claude" / "skills"
    track(check_rule_claim("Skill sayisi (.claude/skills/)", 43,
                           count_dirs(skills_dir), tolerance=3))

    # --- Summary ---
    print(f"\n{Colors.BOLD}{Colors.CYAN}=== OZET ==={Colors.RESET}")
    print(f"  Toplam kontrol: {total}")
    print(f"  {Colors.GREEN}Basarili: {pass_count}{Colors.RESET}")
    if fail_count > 0:
        print(f"  {Colors.RED}Basarisiz: {fail_count}{Colors.RESET}")
    else:
        print(f"  {Colors.GREEN}Tum kontroller basarili!{Colors.RESET}")

    print()
    return 0 if fail_count == 0 else 1


if __name__ == "__main__":
    sys.exit(main())
