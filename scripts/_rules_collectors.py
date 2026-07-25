"""Codebase'den gercek degerleri toplayan fonksiyonlar."""

import ast
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


# ── Release artifact paths ───────────────────────────────────────────
# 2026-07-25: `scripts/build_release.sh ios` was corrected to report
# build/ios/archive/Runner.xcarchive, and release-ops.md + the wiki + the
# store-release skill were updated — but CLAUDE.md kept claiming
# build/ios/ipa/*.ipa. Every count-based check stayed green because none of
# them encodes "these surfaces must name the same artifact". These two
# helpers do.

_ARTIFACT_PATH_RE = re.compile(r"build/[A-Za-z0-9_./*-]+")


def extract_markdown_section(text: str, heading_prefix: str) -> str:
    """Return the body under the first heading starting with `heading_prefix`.

    Stops at the next heading of the same or a higher level, so a `####`
    subsection stays inside a `###` section.
    """
    lines = text.splitlines()
    level = len(heading_prefix) - len(heading_prefix.lstrip("#"))
    body: list[str] = []
    collecting = False
    for line in lines:
        if collecting:
            stripped = line.lstrip("#")
            depth = len(line) - len(stripped)
            if line.startswith("#") and 0 < depth <= level:
                break
            body.append(line)
        elif line.startswith(heading_prefix):
            collecting = True
    return "\n".join(body)


def extract_release_artifact_paths(text: str) -> set:
    """Extract `build/...` artifact paths, stripping markdown/prose trailers."""
    return {match.rstrip("`.,;:)") for match in _ARTIFACT_PATH_RE.findall(text)}


# ── Edge Function names across surfaces ──────────────────────────────
# edge-functions.md: "Function names must match exactly across: workflow,
# function folder, and raw string literal call sites" — there is no
# EdgeFunctionName constants class, so every surface repeats the literal and
# nothing but this check ties them together. A name that drifts fails at
# runtime (404), on deploy (missing function), or silently (a stale entry in
# _rateLimitExempt just stops exempting).


def collect_edge_function_surfaces(root: Path) -> dict:
    """Collect Edge Function names from each surface.

    A value of ``None`` means that surface's file is absent (skip, do not
    report every name as missing).
    """
    functions_dir = root / "supabase" / "functions"
    on_disk = set()
    if functions_dir.exists():
        on_disk = {
            d.name
            for d in functions_dir.iterdir()
            if d.is_dir() and not d.name.startswith("_")
        }

    def _read(path: Path) -> Optional[str]:
        return path.read_text(encoding="utf-8") if path.exists() else None

    config_text = _read(root / "supabase" / "config.toml")
    in_config = (
        set(re.findall(r"^\[functions\.([A-Za-z0-9_-]+)\]", config_text, re.MULTILINE))
        if config_text is not None
        else None
    )

    workflow_text = _read(root / ".github" / "workflows" / "ci.yml")
    in_deploy = (
        set(re.findall(r"supabase functions deploy ([A-Za-z0-9_-]+)", workflow_text))
        if workflow_text is not None
        else None
    )

    client_text = _read(
        root / "lib" / "data" / "remote" / "supabase" / "edge_function_client.dart"
    )
    in_client = None
    if client_text is not None:
        in_client = set(re.findall(r"invoke\(\s*'([a-z0-9-]+)'", client_text))
        exempt = re.search(r"_rateLimitExempt\s*=\s*\{(.*?)\}", client_text, re.DOTALL)
        if exempt:
            in_client |= set(re.findall(r"'([a-z0-9-]+)'", exempt.group(1)))

    return {
        "disk": on_disk,
        "config": in_config,
        "deploy": in_deploy,
        "client": in_client,
    }


# ── Storage bucket names across surfaces ─────────────────────────────
# Third member of the repeated-literal family. A bucket id is written in
# SupabaseConstants, provisioned in a migration, and described in
# assets-images.md; nothing ties the three together. A constant naming an
# unprovisioned bucket fails at upload time, not at build time.


def collect_storage_bucket_surfaces(root: Path) -> dict:
    """Collect storage bucket ids from constants, migrations and the rule doc.

    ``None`` means that surface is absent (skip rather than report drift).
    """
    consts_file = root / "lib" / "core" / "constants" / "supabase_constants.dart"
    in_constants = None
    if consts_file.exists():
        in_constants = set(
            re.findall(
                r"static const String \w*Bucket = '([^']+)'",
                consts_file.read_text(encoding="utf-8"),
            )
        )

    migrations_dir = root / "supabase" / "migrations"
    in_migrations = None
    if migrations_dir.exists():
        in_migrations = set()
        for sql_file in migrations_dir.glob("*.sql"):
            text = sql_file.read_text(encoding="utf-8")
            # storage.objects policies reference the bucket by column...
            in_migrations |= set(
                re.findall(r"bucket_id\s*=\s*'([a-z0-9][a-z0-9-]*)'", text)
            )
            # ...and bucket DDL/DML names it inside a storage.buckets statement.
            for statement in re.findall(r"storage\.buckets[^;]*", text, re.IGNORECASE):
                in_migrations |= set(
                    re.findall(r"'([a-z0-9][a-z0-9-]*)'", statement)
                )

    doc_file = root / ".claude" / "rules" / "assets-images.md"
    doc_text = doc_file.read_text(encoding="utf-8") if doc_file.exists() else None

    return {
        "constants": in_constants,
        "migrations": in_migrations,
        "doc_text": doc_text,
    }


# ── L10n category names across surfaces ──────────────────────────────
# The category COUNT is already verified against tr.json. The category
# NAMES are not: localization.md lists all 41 by name, and a renamed or
# added category keeps the count right while the list silently rots.

_CATEGORY_SECTION_RE = re.compile(
    r"^##\s+\d+\s+Categories\s*$\n(.+?)(?:\n\s*\n|\Z)", re.MULTILINE | re.DOTALL
)


def collect_l10n_category_surfaces(root: Path) -> dict:
    """Collect l10n category names from tr.json and localization.md.

    ``None`` means that surface (or its Categories section) is absent.
    """
    tr_file = root / "assets" / "translations" / "tr.json"
    in_json = None
    if tr_file.exists():
        in_json = set(json.loads(tr_file.read_text(encoding="utf-8")).keys())

    doc_file = root / ".claude" / "rules" / "localization.md"
    in_doc = None
    if doc_file.exists():
        match = _CATEGORY_SECTION_RE.search(doc_file.read_text(encoding="utf-8"))
        if match:
            in_doc = {
                name.strip()
                for name in match.group(1).replace("\n", " ").split(",")
                if name.strip()
            }

    return {"json": in_json, "doc": in_doc}


# ── SVG icon paths across surfaces ───────────────────────────────────
# The COUNT of AppIcons constants and of files on disk is already compared
# (99 == 99). Which constant points at which file is not: a renamed asset or
# a typo'd path keeps both counts right and fails only at runtime, where
# flutter_svg renders nothing rather than throwing.


def collect_icon_surfaces(root: Path) -> dict:
    """Collect SVG asset paths from AppIcons constants and from disk."""
    icons_file = root / "lib" / "core" / "constants" / "app_icons.dart"
    in_constants = None
    if icons_file.exists():
        in_constants = set(
            re.findall(
                r"static const \w+ = '([^']+\.svg)'",
                icons_file.read_text(encoding="utf-8"),
            )
        )

    icons_dir = root / "assets" / "icons"
    on_disk = None
    if icons_dir.exists():
        on_disk = {
            path.relative_to(root).as_posix() for path in icons_dir.rglob("*.svg")
        }

    return {"constants": in_constants, "disk": on_disk}


# ── Route constants vs navigation targets ────────────────────────────
# NOT a bijection like the other families: GoRouter composes nested paths
# from relative literals (`path: ':id'`), so `/chicks/:id` is never written
# as a `path:` value and 12 constants are legitimately never referenced by
# name — they are reached by interpolation, `context.push('/chicks/$id')`.
# Requiring every constant to be referenced would flag all of those.
#
# Two things ARE sound and catch runtime-only failures:
#   1. two constants must not share a path value (ambiguous routing)
#   2. every navigation target written as a string literal must resolve to a
#      declared route — `context.push('/typo')` compiles and 404s.

_NAV_LITERAL_RE = re.compile(r"context\.(?:push|go|replace)\(\s*'(/[^'$]*)'")
_NAV_INTERPOLATED_RE = re.compile(r"context\.(?:push|go|replace)\(\s*'(/[a-z0-9\-/]*)/\$")


def collect_route_surfaces(root: Path) -> dict:
    """Collect route constants and the string navigation targets in lib/."""
    names_file = root / "lib" / "router" / "route_names.dart"
    constants = None
    if names_file.exists():
        constants = dict(
            re.findall(
                r"static const (\w+) = '([^']+)'",
                names_file.read_text(encoding="utf-8"),
            )
        )

    lib_dir = root / "lib"
    literals: set = set()
    prefixes: set = set()
    if lib_dir.exists():
        for dart_file in lib_dir.rglob("*.dart"):
            text = dart_file.read_text(encoding="utf-8", errors="ignore")
            literals |= set(_NAV_LITERAL_RE.findall(text))
            prefixes |= set(_NAV_INTERPOLATED_RE.findall(text))

    return {"constants": constants, "literals": literals, "prefixes": prefixes}


def unresolved_route_targets(surfaces: dict) -> list:
    """Navigation targets that match no declared route."""
    constants = surfaces["constants"] or {}
    values = set(constants.values())
    # A `/foo/$id` target is served by a `/foo/:param` constant.
    parameterized = {
        value.rsplit("/", 1)[0] for value in values if "/:" in value
    }
    unresolved = [target for target in surfaces["literals"] if target not in values]
    unresolved += [
        prefix
        for prefix in surfaces["prefixes"]
        if prefix not in values and prefix not in parameterized
    ]
    return sorted(unresolved)


# ── Supabase table names across surfaces ─────────────────────────────
# Seventh family. A `*Table` constant naming a table no migration creates
# fails at query time with a Postgres error, not at build time. Keyed on the
# constant NAME suffix, not its value: `adminExportAllTablesRpc` holds
# 'admin_export_all_tables', which is an RPC, not a table.


def collect_supabase_table_surfaces(root: Path) -> dict:
    """Collect `*Table` constant values and tables created by migrations."""
    consts_file = root / "lib" / "core" / "constants" / "supabase_constants.dart"
    in_constants = None
    if consts_file.exists():
        in_constants = {
            value
            for _, value in re.findall(
                r"static const String (\w+Table) = '([^']+)'",
                consts_file.read_text(encoding="utf-8"),
            )
        }

    migrations_dir = root / "supabase" / "migrations"
    created = None
    if migrations_dir.exists():
        created = set()
        for sql_file in migrations_dir.glob("*.sql"):
            created |= {
                name.lower()
                for name in re.findall(
                    r"create table (?:if not exists )?(?:public\.)?([a-z_][a-z0-9_]*)",
                    sql_file.read_text(encoding="utf-8", errors="ignore"),
                    re.IGNORECASE,
                )
            }

    return {"constants": in_constants, "created": created}


# ── Local gate vs CI code-quality ────────────────────────────────────
# The pre-commit gate is only useful if it sees what CI sees. It ran four of
# code-quality's five checks for months — verify_migration_drift.py was
# CI-only, so a migration structure problem only surfaced after push. Nothing
# tied the two lists together; this does.

_GATE_SCRIPT_RE = re.compile(r"python3?\s+(scripts/[\w_]+\.py)")


def collect_quality_gate_surfaces(root: Path) -> dict:
    """Collect the scripts run by CI's code-quality job and the local gate."""
    workflow = root / ".github" / "workflows" / "ci.yml"
    in_ci = None
    if workflow.exists():
        text = workflow.read_text(encoding="utf-8")
        match = re.search(
            r"^  code-quality:\n(.*?)(?=\n  [a-z][\w-]*:\n)", text, re.MULTILINE | re.DOTALL
        )
        if match:
            in_ci = set(_GATE_SCRIPT_RE.findall(match.group(1)))

    gate = root / "scripts" / "run_local_quality_gate.sh"
    in_gate = (
        set(_GATE_SCRIPT_RE.findall(gate.read_text(encoding="utf-8")))
        if gate.exists()
        else None
    )

    return {"ci": in_ci, "gate": in_gate}


def gate_parity_gaps(surfaces: dict) -> list:
    """Checks CI runs in code-quality that the local gate does not.

    One-way: the gate legitimately runs more (`verify_rules.py --strict` lives
    in the separate `rules-sync` job, plus conditional l10n/script-test steps).
    """
    ci = surfaces["ci"]
    gate = surfaces["gate"]
    if ci is None or gate is None:
        return []
    return sorted(ci - gate)


def collect_supabase_column_surfaces(root: Path) -> dict:
    """Collect `*Col<Name>` constant values and columns declared by migrations.

    Column names are not table-scoped here: the same `user_id` constant is
    reused across tables, so this only answers "does this column exist
    anywhere". That still catches the typo class, which is the failure that
    reaches production as a Postgres error.
    """
    consts_file = root / "lib" / "core" / "constants" / "supabase_constants.dart"
    in_constants = None
    if consts_file.exists():
        in_constants = {
            value
            for _, value in re.findall(
                r"static const String (\w*[Cc]ol[A-Z]\w*) = '([^']+)'",
                consts_file.read_text(encoding="utf-8"),
            )
        }

    migrations_dir = root / "supabase" / "migrations"
    declared = None
    if migrations_dir.exists():
        declared = set()
        for sql_file in migrations_dir.glob("*.sql"):
            text = sql_file.read_text(encoding="utf-8", errors="ignore")
            for body in re.findall(
                r"create table[^(]*\((.*?)\);", text, re.IGNORECASE | re.DOTALL
            ):
                declared |= {
                    name.lower()
                    for name in re.findall(
                        r'^\s*"?([a-z_][a-z0-9_]*)"?\s+[a-z]',
                        body,
                        re.IGNORECASE | re.MULTILINE,
                    )
                }
            declared |= {
                name.lower()
                for name in re.findall(
                    r'add column (?:if not exists )?"?([a-z_][a-z0-9_]*)',
                    text,
                    re.IGNORECASE,
                )
            }

    return {"constants": in_constants, "declared": declared}


def undeclared_columns(surfaces: dict) -> list:
    """Column constants that no migration declares anywhere."""
    constants = surfaces["constants"] or set()
    declared = surfaces["declared"]
    if declared is None:
        return []
    return sorted(value for value in constants if value.lower() not in declared)


def unprovisioned_tables(surfaces: dict) -> list:
    """Table constants that no migration creates.

    One-way only: migrations legitimately create tables the client never names
    (`private.*` helpers, audit tables written by triggers).
    """
    constants = surfaces["constants"] or set()
    created = surfaces["created"]
    if created is None:
        return []
    return sorted(value for value in constants if value.lower() not in created)


def duplicate_route_values(surfaces: dict) -> list:
    """Path values declared by more than one constant."""
    constants = surfaces["constants"] or {}
    seen: dict = {}
    for name, value in constants.items():
        seen.setdefault(value, []).append(name)
    return sorted(value for value, names in seen.items() if len(names) > 1)


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
    bottom_sheet = (
        count_files(widgets_dir / "bottom_sheet")
        if (widgets_dir / "bottom_sheet").exists()
        else 0
    )
    eggs = count_files(widgets_dir / "eggs") if (widgets_dir / "eggs").exists() else 0
    return {
        "widgets_total": root_w + sub_w,
        "widgets_root": root_w,
        "widgets_buttons": buttons,
        "widgets_cards": cards,
        "widgets_dialogs": dialogs,
        "widgets_bottom_sheet": bottom_sheet,
        "widgets_eggs": eggs,
    }


def _count_indexes(db_dir: Path) -> int:
    """app_database_indexes.dart dosyasindaki CREATE INDEX satirlarini say.

    Only counts uncommented lines to avoid false positives from documentation
    or commented-out SQL statements.
    """
    idx_file = db_dir / "app_database_indexes.dart"
    if not idx_file.exists():
        return 0
    content = idx_file.read_text(encoding="utf-8")
    count = 0
    for line in content.splitlines():
        stripped = line.strip()
        # Skip Dart single-line comments and documentation
        if stripped.startswith("//") or stripped.startswith("///"):
            continue  # pragma: no cover - CPython emits no trace event here
        if re.search(r"CREATE INDEX", stripped, re.IGNORECASE):
            count += 1
    return count


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


def count_migrations(root: Path) -> int:
    """Supabase migration SQL dosyalarini say."""
    migrations_dir = root / "supabase" / "migrations"
    if not migrations_dir.exists():
        return 0
    return len(list(migrations_dir.glob("*.sql")))


def count_edge_functions(root: Path) -> int:
    """Supabase Edge Function sayisini index.ts giris noktalarindan topla."""
    functions_dir = root / "supabase" / "functions"
    if not functions_dir.exists():
        return 0
    return len([
        f
        for f in functions_dir.glob("*/index.ts")
        if not f.parent.name.startswith("_")
    ])


def collect_quality_checker_counts(root: Path) -> dict:
    """verify_code_quality.py checker kapsam sayilarini AST uzerinden topla."""
    scanner = root / "scripts" / "verify_code_quality.py"
    result = {
        "quality_covered": 0,
        "quality_extra": 0,
        "quality_total": 0,
    }
    if not scanner.exists():
        return result

    try:
        tree = ast.parse(scanner.read_text(encoding="utf-8"))
    except (OSError, SyntaxError):
        return result

    counts = {}
    for node in tree.body:
        if not isinstance(node, ast.Assign):
            continue
        for target in node.targets:
            if not isinstance(target, ast.Name):
                continue
            if target.id not in {"ANTI_PATTERN_COVERAGE", "EXTRA_CHECKERS"}:
                continue
            try:
                value = ast.literal_eval(node.value)
            except (ValueError, SyntaxError):
                continue
            if isinstance(value, dict):
                counts[target.id] = len(value)

    result["quality_covered"] = counts.get("ANTI_PATTERN_COVERAGE", 0)
    result["quality_extra"] = counts.get("EXTRA_CHECKERS", 0)
    result["quality_total"] = result["quality_covered"] + result["quality_extra"]
    return result


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
    result["indexes"] = _count_indexes(LIB / "data" / "local" / "database")
    result["tr_keys"] = count_json_leaf_keys(ASSETS / "translations" / "tr.json")
    result["categories"] = count_json_top_keys(ASSETS / "translations" / "tr.json")
    result["supa"] = count_string_consts(LIB / "core" / "constants" / "supabase_constants.dart")
    result.update(collect_widgets(LIB))
    result.update(collect_test_counts(ROOT))
    result["source_files"] = collect_source_file_count(LIB)
    result["migrations"] = count_migrations(ROOT)
    result["edge_functions"] = count_edge_functions(ROOT)
    result.update(collect_quality_checker_counts(ROOT))
    return result
