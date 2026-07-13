#!/usr/bin/env python3
"""Detect aspirational-contract drift in .claude/rules/*.md.

A rule that names a Dart symbol as CURRENT behavior when that symbol does not
exist anywhere in the codebase is an "aspirational contract" — the highest-value
doc-drift class (2026-07-13 sweep found whole never-built rule sections presented
as shipped: conflictNotifierProvider, gamificationServiceProvider, etc.).

verify_rules.py / check_obsidian_brain.py only prove counts + structure. This
checker proves that the two HIGHEST-confidence symbol shapes referenced in a rule
actually exist:

  1. Provider tokens  — `xxxProvider` (camelCase, ends in Provider)
  2. Dart file paths  — `foo_bar.dart` or `lib/.../foo.dart`

Both shapes are near-zero false-positive: providers are always defined in lib/
under a stable name, and a `.dart` path in a rule should point at a real file.
Prose words, l10n keys, table/column literals, and PascalCase class names are
NOT checked here (too noisy — those stay in the manual semantic sweep).

Exit 0 always by default (advisory). Pass --strict to exit 1 on any finding
(for wiring into a CI gate once the allowlist has settled).
"""
from __future__ import annotations

import argparse
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
RULES_DIR = ROOT / ".claude" / "rules"

# Illustrative placeholder providers used in generic examples — not real symbols.
PROVIDER_ALLOWLIST: set[str] = {
    "myProvider",
    "fooProvider",
    "xProvider",
    "someProvider",
    "myRepositoryProvider",
    "repositoryProvider",
    "xRepositoryProvider",
    "birdProvider",  # generic example notifier in provider/form skeletons
    "myAsyncProvider",
    "exampleProvider",
    "conflictNotifierProvider",  # documented-as-removed in prose that names the real one
    "commentsForPostProvider",   # community.md: prose documenting its 2026-07-05 removal
    "gamificationServiceProvider",  # documentation-sync.md: prose example of a never-built symbol
}

# Illustrative placeholder / documented-as-removed .dart file names.
DART_PATH_ALLOWLIST: set[str] = {
    "my_form.dart",
    "foo.dart",
    "bar.dart",
    "example.dart",
    "my_screen.dart",
    "_extensions.dart",           # coding-standards.md: generic "dedicated _extensions.dart" example
    "mutation_linkage_data.dart",  # genetics.md: prose documenting the pre-2026-07-10 superseded file
}

PROVIDER_RE = re.compile(r"`([a-z][A-Za-z0-9]*Provider)`")
# Backtick token that ends in .dart; may be a bare basename or a path.
DART_PATH_RE = re.compile(r"`([A-Za-z0-9_./-]+\.dart)`")


def _rg(pattern: str, *paths: str) -> bool:
    """Return True if ripgrep finds `pattern` (fixed-string word) under paths."""
    try:
        res = subprocess.run(
            ["rg", "-l", "--fixed-strings", "--word-regexp", pattern, *paths],
            cwd=ROOT,
            capture_output=True,
            text=True,
        )
        return res.returncode == 0 and bool(res.stdout.strip())
    except FileNotFoundError:
        # Fallback to grep -r if ripgrep is unavailable.
        res = subprocess.run(
            ["grep", "-rlw", "--include=*.dart", pattern, *paths],
            cwd=ROOT,
            capture_output=True,
            text=True,
        )
        return res.returncode == 0 and bool(res.stdout.strip())


def _provider_exists(name: str) -> bool:
    return _rg(name, "lib")


def _dart_path_exists(token: str) -> bool:
    # Generated files — never authored, not a drift signal.
    if token.endswith((".g.dart", ".freezed.dart")):
        return True
    # External SDK / package paths are references, not repo files.
    if token.startswith(("flutter/", "package:", "dart:")) or "/src/" in token:
        return True
    if "/" in token:
        # Full/relative path: check on disk (relative to repo root, or under lib/).
        if (ROOT / token).exists() or (ROOT / "lib" / token).exists():
            return True
        # Rules often cite a partial path (e.g. `buttons/app_icon_button.dart`)
        # whose real location is deeper (lib/core/widgets/buttons/...). Fall back
        # to a basename search so a correct-but-partial path isn't false-flagged.
    basename = token.rsplit("/", 1)[-1]
    for base in ("lib", "supabase", "test"):
        if list((ROOT / base).rglob(basename)):
            return True
    return False


def scan() -> list[tuple[str, str, str]]:
    """Return list of (rule_name, kind, token) findings."""
    findings: list[tuple[str, str, str]] = []
    for rule in sorted(RULES_DIR.glob("*.md")):
        text = rule.read_text(encoding="utf-8")
        seen_prov: set[str] = set()
        for m in PROVIDER_RE.finditer(text):
            name = m.group(1)
            if name in PROVIDER_ALLOWLIST or name in seen_prov:
                continue
            seen_prov.add(name)
            if not _provider_exists(name):
                findings.append((rule.name, "provider", name))
        seen_path: set[str] = set()
        for m in DART_PATH_RE.finditer(text):
            token = m.group(1)
            base = token.rsplit("/", 1)[-1]
            if base in DART_PATH_ALLOWLIST or token in seen_path:
                continue
            seen_path.add(token)
            if not _dart_path_exists(token):
                findings.append((rule.name, "dart-path", token))
    return findings


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--strict",
        action="store_true",
        help="Exit 1 on any finding (CI-gate mode).",
    )
    args = parser.parse_args()

    findings = scan()
    if not findings:
        print("Rule symbol drift check OK — all Provider tokens and .dart paths resolve.")
        return 0

    print("Rule symbol drift — referenced symbols not found in the codebase:")
    current = None
    for rule, kind, token in findings:
        if rule != current:
            print(f"\n  {rule}")
            current = rule
        print(f"    [{kind}] {token}")
    print(
        f"\n  {len(findings)} finding(s). Each is either genuine drift (rename/removed) "
        "or an illustrative placeholder that belongs in the allowlist "
        "(scripts/check_rule_symbol_drift.py)."
    )
    return 1 if args.strict else 0


if __name__ == "__main__":  # pragma: no cover
    sys.exit(main())
