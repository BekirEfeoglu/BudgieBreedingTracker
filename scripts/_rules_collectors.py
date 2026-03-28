"""Codebase'den gercek degerleri toplayan fonksiyonlar."""

import json
import re
from pathlib import Path
from typing import Optional

ROOT = Path(__file__).resolve().parent.parent
LIB = ROOT / "lib"
ASSETS = ROOT / "assets"


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


def count_json_top_keys(filepath: Path) -> int:
    """Count top-level keys in a JSON file (l10n categories)."""
    if not filepath.exists():
        return 0
    with open(filepath, "r", encoding="utf-8") as f:
        data = json.load(f)
    return len(data)


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


def extract_first_number(text: str) -> Optional[int]:
    """Bir string'den ilk sayiyi cikar. '~' prefix'ini tolere eder."""
    text = text.replace("~", "").replace(",", "")
    match = re.search(r"\d+", text)
    return int(match.group()) if match else None


def collect_data_layer(lib: Path) -> dict:
    """Model, enum, tablo, DAO, mapper sayilarini topla."""
    return {
        "models": count_files(lib / "data" / "models", "*_model.dart"),
        "enums": count_files(lib / "core" / "enums", "*_enums.dart"),
        "tables": count_files(lib / "data" / "local" / "database" / "tables", "*_table.dart"),
        "daos": count_files(lib / "data" / "local" / "database" / "daos", "*_dao.dart"),
        "mappers": count_files(lib / "data" / "local" / "database" / "mappers", "*_mapper.dart"),
    }


def collect_repos_and_remotes(lib: Path) -> dict:
    """Entity repository ve remote source sayilarini topla (base_ dosyalar haric)."""
    repo_dir = lib / "data" / "repositories"
    repos = (
        len([f for f in repo_dir.glob("*_repository.dart") if "base_" not in f.name])
        if repo_dir.exists()
        else 0
    )
    remote_dir = lib / "data" / "remote" / "api"
    remotes = (
        len([f for f in remote_dir.glob("*_remote_source.dart") if "base_" not in f.name])
        if remote_dir.exists()
        else 0
    )
    return {"repos": repos, "remotes": remotes}


def collect_widgets(lib: Path) -> dict:
    """Shared widget sayilarini (root + alt dizinler) topla."""
    widgets_dir = lib / "core" / "widgets"
    root_w = count_files(widgets_dir)
    sub_w = (
        sum(count_files(d) for d in widgets_dir.iterdir() if d.is_dir())
        if widgets_dir.exists()
        else 0
    )
    buttons = count_files(widgets_dir / "buttons") if (widgets_dir / "buttons").exists() else 0
    cards = count_files(widgets_dir / "cards") if (widgets_dir / "cards").exists() else 0
    dialogs = count_files(widgets_dir / "dialogs") if (widgets_dir / "dialogs").exists() else 0
    return {
        "widgets_total": root_w + sub_w,
        "widgets_root": root_w,
        "widgets_buttons": buttons,
        "widgets_cards": cards,
        "widgets_dialogs": dialogs,
    }


def collect_test_counts(root: Path) -> dict:
    """Test dosyasi sayisini ve bireysel test (test/testWidgets) sayisini topla."""
    test_dir = root / "test"
    test_files = len(list(test_dir.rglob("*_test.dart"))) if test_dir.exists() else 0
    individual_tests = 0
    _test_re = re.compile(r"^\s*(?:test|testWidgets)\(", re.MULTILINE)
    if test_dir.exists():
        for tf in test_dir.rglob("*_test.dart"):
            individual_tests += len(_test_re.findall(tf.read_text(encoding="utf-8")))
    return {"test_files": test_files, "individual_tests": individual_tests}


def collect_source_file_count(lib: Path) -> int:
    """Kaynak Dart dosyasi sayisini topla (*.g.dart ve *.freezed.dart haric)."""
    if not lib.exists():
        return 0
    return len([
        f for f in lib.rglob("*.dart")
        if not f.name.endswith(".g.dart") and not f.name.endswith(".freezed.dart")
    ])


def collect_actual_values() -> dict:
    """Codebase'den gercek degerleri topla."""
    result: dict = {}
    result.update(collect_data_layer(LIB))
    result.update(collect_repos_and_remotes(LIB))
    result["features"] = count_dirs(LIB / "features")
    result["services"] = count_dirs(LIB / "domain" / "services")
    result["icons"] = count_string_consts(LIB / "core" / "constants" / "app_icons.dart")
    result["svg_files"] = count_files_recursive(ASSETS / "icons", "*.svg")
    result["routes"] = count_route_consts(LIB / "router" / "route_names.dart")
    result["schema"] = get_schema_version(LIB / "data" / "local" / "database" / "app_database.dart")
    result["tr_keys"] = count_json_leaf_keys(ASSETS / "translations" / "tr.json")
    result["categories"] = count_json_top_keys(ASSETS / "translations" / "tr.json")
    result["supa"] = count_string_consts(LIB / "core" / "constants" / "supabase_constants.dart")
    result.update(collect_widgets(LIB))
    result.update(collect_test_counts(ROOT))
    result["source_files"] = collect_source_file_count(LIB)
    return result
