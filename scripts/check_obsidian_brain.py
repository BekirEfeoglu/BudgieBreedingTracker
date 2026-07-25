#!/usr/bin/env python3
"""Lint the obsidian-brain wiki maintenance contract."""

import json
import re
import subprocess
from pathlib import Path
from typing import Optional

ROOT = Path(__file__).resolve().parents[1]
WIKI_DIR = ROOT / "obsidian-brain"
MAX_LINES = 200
MAX_ACTIVE_LOG_ENTRIES = 30
WIKILINK_RE = re.compile(r"\[\[([^\]\|#]+)(?:#[^\]\|]+)?(?:\|[^\]]+)?\]\]")
FENCED_CODE_RE = re.compile(r"```.*?```", re.DOTALL)
INLINE_CODE_RE = re.compile(r"`[^`\n]*`")
FILE_REF_PREFIXES = (
    ".claude/",
    ".github/",
    "android/",
    "assets/",
    "docs/",
    "integration_test/",
    "ios/",
    "lib/",
    "scripts/",
    "supabase/",
    "test/",
)
FILE_REF_SKIP_MARKERS = ("*", "...", "<", ">", "{", "}", "YYYY", "path/")

# Paths that exist at runtime but are deliberately gitignored, so they are
# absent from a fresh checkout. They are worth documenting precisely because
# they are generated and can go stale — ios/Flutter/DartDefines.xcconfig held a
# four-month-old legacy OAuth client ID and no SENTRY_DSN, which is why the
# release docs name it. Rewording the docs to dodge this check would delete the
# warning rather than fix it, so allow the path instead.
GITIGNORED_FILE_REFS = frozenset(
    {
        "ios/Flutter/DartDefines.xcconfig",
        "ios/Flutter/Env.xcconfig",
        "ios/Flutter/Generated.xcconfig",
    }
)
REQUIRED_DECISION_SECTIONS = {
    "features/community.md": (
        "## Current Decisions",
        "## Known Deferred Work",
        "## Do Not Reintroduce",
    ),
    "features/admin.md": (
        "## Current Decisions",
        "## Known Deferred Work",
        "## Do Not Reintroduce",
    ),
    "domain/notification-service.md": (
        "## Current Decisions",
        "## Known Deferred Work",
        "## Do Not Reintroduce",
    ),
    "data-layer/migrations.md": (
        "## Current Decisions",
        "## Known Deferred Work",
        "## Do Not Reintroduce",
    ),
}


def _markdown_files(wiki_dir: Path) -> list[Path]:
    return sorted(path for path in wiki_dir.rglob("*.md") if path.is_file())


def _page_key(path: Path, wiki_dir: Path) -> str:
    return path.relative_to(wiki_dir).as_posix()


def _target_candidates(source: Path, raw_target: str, wiki_dir: Path) -> list[str]:
    target = raw_target.strip().removeprefix("/")
    if not target:
        return []
    if not target.endswith(".md"):
        target = f"{target}.md"

    candidates: list[Path] = []
    if "/" in target:
        candidates.append(wiki_dir / target)
    else:
        candidates.append(source.parent / target)
        candidates.append(wiki_dir / target)

    seen: set[str] = set()
    keys: list[str] = []
    for candidate in candidates:
        try:
            key = candidate.resolve().relative_to(wiki_dir.resolve()).as_posix()
        except ValueError:
            continue
        if key not in seen:
            seen.add(key)
            keys.append(key)
    return keys


def _index_targets(index_md: Path, wiki_dir: Path) -> set[str]:
    if not index_md.exists():
        return set()

    targets: set[str] = set()
    text = index_md.read_text(encoding="utf-8")
    for match in WIKILINK_RE.finditer(text):
        for candidate in _target_candidates(index_md, match.group(1), wiki_dir):
            targets.add(candidate)
    return targets


def _linkable_text(text: str) -> str:
    without_fences = FENCED_CODE_RE.sub("", text)
    return INLINE_CODE_RE.sub("", without_fences)


def _inline_code_values(text: str) -> list[str]:
    without_fences = FENCED_CODE_RE.sub("", text)
    return [match.group(0)[1:-1].strip() for match in INLINE_CODE_RE.finditer(without_fences)]


def _candidate_file_refs(text: str) -> list[str]:
    refs: list[str] = []
    for value in _inline_code_values(text):
        for token in re.split(r"\s+", value):
            token = token.strip(".,;:()[]'\"")
            token = re.sub(r":\d+(?:-\d+)?$", "", token)
            if not token.startswith(FILE_REF_PREFIXES):
                continue
            if any(marker in token for marker in FILE_REF_SKIP_MARKERS):
                continue
            if token in GITIGNORED_FILE_REFS:
                continue
            refs.append(token)
    return refs


def _git_tracked_count(root: Path, pathspecs: list[str]) -> Optional[int]:
    if not (root / ".git").exists():
        return None

    result = subprocess.run(
        ["git", "-C", str(root), "ls-files", *pathspecs],
        capture_output=True,
        check=False,
        text=True,
    )
    if result.returncode != 0:
        return None
    return len([line for line in result.stdout.splitlines() if line.strip()])


def _filesystem_count(root: Path, patterns: list[str]) -> int:
    paths: set[Path] = set()
    for pattern in patterns:
        paths.update(path for path in root.glob(pattern) if path.is_file())
    return len(paths)


def _tracked_or_filesystem_count(root: Path, pathspecs: list[str]) -> int:
    tracked = _git_tracked_count(root, pathspecs)
    if tracked is not None:
        return tracked
    return _filesystem_count(root, pathspecs)


def _count_json_leaf_keys(value: object) -> int:
    if isinstance(value, dict):
        return sum(_count_json_leaf_keys(item) for item in value.values())
    return 1


def _first_int(value: str) -> Optional[int]:
    match = re.search(r"\d[\d,]*", value)
    if not match:
        return None
    return int(match.group(0).replace(",", ""))


def _parse_overview_metrics(overview_md: Path) -> dict[str, str]:
    if not overview_md.exists():
        return {}

    metrics: dict[str, str] = {}
    for line in overview_md.read_text(encoding="utf-8").splitlines():
        match = re.match(r"\|\s*([^|]+?)\s*\|\s*([^|]+?)\s*\|", line)
        if not match:
            continue
        key = match.group(1).strip()
        value = match.group(2).strip()
        if key in {"Metric", "--------"}:
            continue
        metrics[key] = value
    return metrics


def _schema_version(root: Path) -> Optional[int]:
    database = root / "lib/data/local/database/app_database.dart"
    if not database.exists():
        return None
    match = re.search(r"schemaVersion\s*=>\s*(\d+)", database.read_text(encoding="utf-8"))
    return int(match.group(1)) if match else None


def _l10n_key_count(root: Path) -> Optional[int]:
    counts: list[int] = []
    for lang in ("tr", "en", "de"):
        path = root / f"assets/translations/{lang}.json"
        if not path.exists():
            return None
        counts.append(_count_json_leaf_keys(json.loads(path.read_text(encoding="utf-8"))))
    return counts[0] if len(set(counts)) == 1 else None


def _regex_count(path: Path, pattern: str) -> Optional[int]:
    if not path.exists():
        return None
    return len(re.findall(pattern, path.read_text(encoding="utf-8"), flags=re.MULTILINE))


def _edge_function_count(root: Path) -> Optional[int]:
    functions_dir = root / "supabase/functions"
    if not functions_dir.exists():
        return None
    return len(
        [
            path
            for path in functions_dir.iterdir()
            if path.is_dir() and not path.name.startswith("_")
        ]
    )


def _actual_metrics(root: Path) -> dict[str, int]:
    candidates: dict[str, Optional[int]] = {
        "Source files (lib/)": _tracked_or_filesystem_count(root, ["lib/*.dart", "lib/**/*.dart"]),
        "Test files": _tracked_or_filesystem_count(
            root,
            [
                "test/*_test.dart",
                "test/**/*_test.dart",
                "integration_test/*_test.dart",
                "integration_test/**/*_test.dart",
            ],
        ),
        "Remote sources": _filesystem_count(root, ["lib/data/remote/api/*_remote_source.dart"]),
        "Custom SVG icons": _regex_count(
            root / "lib/core/constants/app_icons.dart",
            r"static const [A-Za-z0-9_]+\s*=",
        ),
        "Supabase constants": _regex_count(
            root / "lib/core/constants/supabase_constants.dart",
            r"static const String\s+",
        ),
        "L10n keys": _l10n_key_count(root),
        "DB schema version": _schema_version(root),
        "Supabase migrations": _tracked_or_filesystem_count(
            root,
            ["supabase/migrations/*.sql"],
        ),
        "Edge Functions": _edge_function_count(root),
    }
    return {key: value for key, value in candidates.items() if value is not None}


def _check_overview_metrics(root: Path, wiki_dir: Path) -> list[str]:
    errors: list[str] = []
    overview_metrics = _parse_overview_metrics(wiki_dir / "overview.md")
    if not overview_metrics:
        return errors

    for metric, actual in _actual_metrics(root).items():
        if metric not in overview_metrics:
            continue
        reported = _first_int(overview_metrics[metric])
        if reported != actual:
            errors.append(
                f"overview.md metric '{metric}' reports {reported}, actual {actual}"
            )
    return errors


def check_wiki(wiki_dir: Path = WIKI_DIR) -> list[str]:
    errors: list[str] = []

    if not wiki_dir.exists():
        return [f"obsidian-brain directory missing: {wiki_dir}"]

    files = _markdown_files(wiki_dir)
    pages = {_page_key(path, wiki_dir): path for path in files}

    for path in files:
        line_count = len(path.read_text(encoding="utf-8").splitlines())
        if line_count > MAX_LINES:
            errors.append(
                f"{_page_key(path, wiki_dir)} has {line_count} lines "
                f"(max {MAX_LINES})"
            )

    index_md = wiki_dir / "index.md"
    indexed_pages = _index_targets(index_md, wiki_dir)
    for key in pages:
        if key not in indexed_pages:
            errors.append(f"{key} is missing from obsidian-brain/index.md")

    log_md = wiki_dir / "log.md"
    if not log_md.exists():
        errors.append("log.md is missing")
    else:
        log_text = log_md.read_text(encoding="utf-8")
        active_entries = re.findall(r"^## \[\d{4}-\d{2}-\d{2}\]", log_text, re.MULTILINE)
        if not active_entries:
            errors.append("log.md has no dated session entry")
        elif len(active_entries) > MAX_ACTIVE_LOG_ENTRIES:
            errors.append(
                f"log.md has {len(active_entries)} active entries "
                f"(max {MAX_ACTIVE_LOG_ENTRIES}; archive older entries)"
            )

    for path in files:
        raw_text = path.read_text(encoding="utf-8")
        text = _linkable_text(raw_text)
        for match in WIKILINK_RE.finditer(text):
            candidates = _target_candidates(path, match.group(1), wiki_dir)
            if not any(candidate in pages for candidate in candidates):
                errors.append(
                    f"{_page_key(path, wiki_dir)} links to missing page "
                    f"[[{match.group(1)}]]"
                )

        for file_ref in _candidate_file_refs(raw_text):
            if not (ROOT / file_ref).exists():
                errors.append(
                    f"{_page_key(path, wiki_dir)} references missing file `{file_ref}`"
                )

    for key, sections in REQUIRED_DECISION_SECTIONS.items():
        path = wiki_dir / key
        if not path.exists():
            continue
        text = path.read_text(encoding="utf-8")
        for section in sections:
            if section not in text:
                errors.append(f"{key} is missing required section '{section}'")

    errors.extend(_check_overview_metrics(ROOT, wiki_dir))

    return errors


def main() -> int:
    errors = check_wiki(WIKI_DIR)
    if errors:
        print("Obsidian brain check failed:")
        for error in errors:
            print(f"  - {error}")
        return 1

    print("Obsidian brain check OK.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
