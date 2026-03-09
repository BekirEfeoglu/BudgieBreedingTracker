#!/usr/bin/env python3
"""
Ceviri dosyalarinin (tr.json, en.json, de.json) senkronizasyonunu kontrol eder.

Kullanim:
  python scripts/check_l10n_sync.py

Kontroller:
  1. Her dilde ayni anahtar seti var mi?
  2. Bos degerler var mi?
  3. Parametre tutarliligi ({} placeholder'lar esit mi?)

Cikti:
  Eksik anahtarlar, fazla anahtarlar ve bos degerler listelenir.
  CI'da exit code 0 = senkron, 1 = uyumsuzluk var.
"""

import json
import re
import sys
from pathlib import Path
from collections import defaultdict

ROOT = Path(__file__).resolve().parent.parent
TRANSLATIONS_DIR = ROOT / "assets" / "translations"

LANGUAGES = ["tr", "en", "de"]
MASTER_LANG = "tr"


class Colors:
    GREEN = "\033[92m"
    RED = "\033[91m"
    YELLOW = "\033[93m"
    CYAN = "\033[96m"
    RESET = "\033[0m"
    BOLD = "\033[1m"


def load_json(filepath: Path) -> dict:
    """JSON dosyasini yukle."""
    with open(filepath, "r", encoding="utf-8") as f:
        return json.load(f)


def flatten_keys(obj: dict, prefix: str = "") -> dict:
    """Ic ice JSON'u duz anahtar-deger ciftlerine cevir."""
    items = {}
    for key, value in obj.items():
        full_key = f"{prefix}.{key}" if prefix else key
        if isinstance(value, dict):
            items.update(flatten_keys(value, full_key))
        else:
            items[full_key] = value
    return items


def count_placeholders(text: str) -> int:
    """Metindeki {} placeholder sayisini dondur."""
    if not isinstance(text, str):
        return 0
    return text.count("{}")


def main():
    print(f"\n{Colors.BOLD}{Colors.CYAN}=== L10n Senkronizasyon Kontrolu ==={Colors.RESET}\n")

    issues = 0

    # Dosyalari yukle
    data = {}
    flat = {}
    for lang in LANGUAGES:
        filepath = TRANSLATIONS_DIR / f"{lang}.json"
        if not filepath.exists():
            print(f"  {Colors.RED}HATA: {filepath} bulunamadi!{Colors.RESET}")
            issues += 1
            continue
        data[lang] = load_json(filepath)
        flat[lang] = flatten_keys(data[lang])

    if len(flat) != len(LANGUAGES):
        print(f"\n{Colors.RED}Bazi dil dosyalari eksik, kontrol yapilamiyor.{Colors.RESET}")
        return 1

    # Anahtar sayilari
    print(f"{Colors.BOLD}1. Anahtar Sayilari{Colors.RESET}")
    for lang in LANGUAGES:
        count = len(flat[lang])
        marker = f"{Colors.GREEN}OK{Colors.RESET}" if lang == MASTER_LANG else ""
        if lang != MASTER_LANG:
            diff = len(flat[lang]) - len(flat[MASTER_LANG])
            if diff == 0:
                marker = f"{Colors.GREEN}OK (esit){Colors.RESET}"
            else:
                marker = f"{Colors.YELLOW}fark: {diff:+d}{Colors.RESET}"
        print(f"  {lang.upper()}: {count} anahtar {marker}")

    # Eksik anahtarlar (master'da var, digerlerde yok)
    print(f"\n{Colors.BOLD}2. Eksik Anahtarlar (master={MASTER_LANG.upper()} referans){Colors.RESET}")
    master_keys = set(flat[MASTER_LANG].keys())

    for lang in LANGUAGES:
        if lang == MASTER_LANG:
            continue
        lang_keys = set(flat[lang].keys())
        missing = master_keys - lang_keys
        extra = lang_keys - master_keys

        if missing:
            issues += len(missing)
            print(f"\n  {Colors.RED}{lang.upper()}'de EKSIK ({len(missing)} anahtar):{Colors.RESET}")
            for key in sorted(missing)[:20]:  # İlk 20'yi göster
                print(f"    - {key}")
            if len(missing) > 20:
                print(f"    ... ve {len(missing) - 20} tane daha")
        else:
            print(f"  {Colors.GREEN}{lang.upper()}: Eksik anahtar yok{Colors.RESET}")

        if extra:
            print(f"\n  {Colors.YELLOW}{lang.upper()}'de FAZLA ({len(extra)} anahtar):{Colors.RESET}")
            for key in sorted(extra)[:20]:
                print(f"    - {key}")
            if len(extra) > 20:
                print(f"    ... ve {len(extra) - 20} tane daha")

    # Bos degerler
    print(f"\n{Colors.BOLD}3. Bos Degerler{Colors.RESET}")
    for lang in LANGUAGES:
        empty_keys = [k for k, v in flat[lang].items() if isinstance(v, str) and v.strip() == ""]
        if empty_keys:
            issues += len(empty_keys)
            print(f"\n  {Colors.RED}{lang.upper()}'de BOS ({len(empty_keys)} anahtar):{Colors.RESET}")
            for key in sorted(empty_keys)[:15]:
                print(f"    - {key}")
            if len(empty_keys) > 15:
                print(f"    ... ve {len(empty_keys) - 15} tane daha")
        else:
            print(f"  {Colors.GREEN}{lang.upper()}: Bos deger yok{Colors.RESET}")

    # Placeholder tutarliligi
    print(f"\n{Colors.BOLD}4. Placeholder Tutarliligi ({{}}){Colors.RESET}")
    placeholder_issues = 0
    common_keys = master_keys.copy()
    for lang in LANGUAGES:
        common_keys &= set(flat[lang].keys())

    for key in sorted(common_keys):
        counts = {lang: count_placeholders(flat[lang][key]) for lang in LANGUAGES}
        unique_counts = set(counts.values())
        if len(unique_counts) > 1 and max(unique_counts) > 0:
            placeholder_issues += 1
            issues += 1
            detail = ", ".join(f"{lang.upper()}={c}" for lang, c in counts.items())
            print(f"  {Colors.RED}UYUMSUZ: {key} ({detail}){Colors.RESET}")

    if placeholder_issues == 0:
        print(f"  {Colors.GREEN}Tum placeholder'lar tutarli{Colors.RESET}")

    # Kategori bazli ozet
    print(f"\n{Colors.BOLD}5. Kategori Bazli Anahtar Dagilimi (TR){Colors.RESET}")
    categories = defaultdict(int)
    for key in flat[MASTER_LANG]:
        category = key.split(".")[0] if "." in key else "(root)"
        categories[category] += 1

    for cat, count in sorted(categories.items(), key=lambda x: -x[1]):
        bar = "#" * min(count // 3, 40)
        print(f"  {cat:20s} {count:4d} {Colors.CYAN}{bar}{Colors.RESET}")

    # Ozet
    print(f"\n{Colors.BOLD}{Colors.CYAN}=== OZET ==={Colors.RESET}")
    total_keys = len(flat[MASTER_LANG])
    print(f"  Master ({MASTER_LANG.upper()}): {total_keys} anahtar")
    print(f"  Kategori sayisi: {len(categories)}")

    if issues == 0:
        print(f"  {Colors.GREEN}Tum diller senkron! Sorun yok.{Colors.RESET}")
    else:
        print(f"  {Colors.RED}Toplam sorun: {issues}{Colors.RESET}")

    print()
    return 0 if issues == 0 else 1


if __name__ == "__main__":
    sys.exit(main())
