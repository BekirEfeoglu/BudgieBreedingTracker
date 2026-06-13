#!/usr/bin/env python3
"""Lint the obsidian-brain wiki maintenance contract."""

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
WIKI_DIR = ROOT / "obsidian-brain"
MAX_LINES = 200
WIKILINK_RE = re.compile(r"\[\[([^\]\|#]+)(?:#[^\]\|]+)?(?:\|[^\]]+)?\]\]")
FENCED_CODE_RE = re.compile(r"```.*?```", re.DOTALL)
INLINE_CODE_RE = re.compile(r"`[^`\n]*`")


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
    elif "## [" not in log_md.read_text(encoding="utf-8"):
        errors.append("log.md has no dated session entry")

    for path in files:
        text = _linkable_text(path.read_text(encoding="utf-8"))
        for match in WIKILINK_RE.finditer(text):
            candidates = _target_candidates(path, match.group(1), wiki_dir)
            if not any(candidate in pages for candidate in candidates):
                errors.append(
                    f"{_page_key(path, wiki_dir)} links to missing page "
                    f"[[{match.group(1)}]]"
                )

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
