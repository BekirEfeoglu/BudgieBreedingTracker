#!/usr/bin/env python3
"""Detect aspirational-contract drift in doc surfaces (.claude/rules + wiki).

A doc that names a Dart symbol as CURRENT behavior when that symbol does not
exist anywhere in the codebase is an "aspirational contract" — the highest-value
doc-drift class (2026-07-13 sweep found whole never-built rule sections presented
as shipped: conflictNotifierProvider, gamificationServiceProvider, etc.).

verify_rules.py / check_obsidian_brain.py only prove counts + structure. This
checker proves that high-confidence symbol shapes referenced in a doc actually
exist:

  1. Provider tokens  — `xxxProvider` (camelCase, ends in Provider)        [always]
  2. Dart file paths  — `foo_bar.dart` or `lib/.../foo.dart`               [always]
  3. Class names      — Foo{Notifier,Service,Repository,Dao,Mapper,Guard}  [--classes]
                        checked BOTH in backticks and bare in prose (outside
                        fenced code) — measured zero-noise on both surfaces.

Shapes 1-2 are near-zero false-positive and gated in CI. Shape 3 (--classes) is
also gated once measured clean. Other class/method names, l10n keys, and
table/column literals are never checked (too noisy).

--audit-allowlist reports allowlist entries no longer cited by any doc (periodic
cruft check; not gated).

Targets:
  --target rules  (default)  .claude/rules/*.md
  --target wiki              obsidian-brain/**/*.md EXCEPT log.md + log-archive-*
                             (chronological history legitimately names removed symbols)
  --target all               both

Exit 0 by default (advisory). --strict exits 1 on any finding (CI-gate mode).
"""
from __future__ import annotations

import argparse
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
RULES_DIR = ROOT / ".claude" / "rules"
WIKI_DIR = ROOT / "obsidian-brain"

# Illustrative placeholder providers used in generic examples — not real symbols.
PROVIDER_ALLOWLIST: set[str] = {
    "myProvider",
    "fooProvider",
    "xProvider",
    "myRepositoryProvider",
    "repositoryProvider",
    "xRepositoryProvider",
    "birdProvider",  # generic example notifier in provider/form skeletons
    "conflictNotifierProvider",  # documented-as-removed in prose that names the real one
    "commentsForPostProvider",   # community.md: prose documenting its 2026-07-05 removal
    "gamificationServiceProvider",  # documentation-sync.md: prose example of a never-built symbol
    "premiumStatusProvider",   # premium wiki: prose explicitly stating it "does not exist"
    "genealogyTreeProvider",   # genealogy wiki: prose explicitly stating it "does not exist"
}

# Illustrative placeholder / documented-as-removed .dart file names.
DART_PATH_ALLOWLIST: set[str] = {
    "_extensions.dart",           # coding-standards.md: generic "dedicated _extensions.dart" example
    "mutation_linkage_data.dart",  # genetics.md: prose documenting the pre-2026-07-10 superseded file
}

# PascalCase class names cited in prose that are illustrative or documented-removed.
CLASS_ALLOWLIST: set[str] = {
    "MarketplaceListingRepository",  # marketplace.md anti-pattern #1: a FORBIDDEN name, cited as what-not-to-use
    "CalendarService",           # calendar-service wiki: prose stating no such class exists (real: CalendarEventGenerator)
    "IncubationReminderService",  # calendar/notification wiki: prose stating no such class exists (real: NotificationScheduler)
    "ConnectivityService",       # documentation-sync.md: cited as the canonical bare-prose drift example (real: networkStatusProvider)
}

PROVIDER_RE = re.compile(r"`([a-z][A-Za-z0-9]*Provider)`")
# Backtick token that ends in .dart; may be a bare basename or a path.
DART_PATH_RE = re.compile(r"`([A-Za-z0-9_./-]+\.dart)`")
# High-confidence class suffixes — always defined as a `class X` in lib/, stable
# names (measured zero-noise across both doc surfaces 2026-07-14).
_CLASS_SUFFIX = r"(?:Notifier|Service|Repository|Dao|Mapper|Guard)"
CLASS_RE = re.compile(rf"`([A-Z][A-Za-z0-9]*{_CLASS_SUFFIX})`")
# Same shape but BARE (prose, outside backticks) — catches the sibling that a
# backtick-only scan misses (e.g. the ConnectivityService drift in data-flow.md).
BARE_CLASS_RE = re.compile(rf"(?<![`\w])([A-Z][A-Za-z0-9]*{_CLASS_SUFFIX})(?![`\w])")
# Fenced code blocks + inline backtick spans are illustrative / already covered.
_FENCED_RE = re.compile(r"```.*?```", re.S)
_INLINE_BT_RE = re.compile(r"`[^`]*`")


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


def _symbol_exists(name: str) -> bool:
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
        # Docs often cite a partial path (e.g. `buttons/app_icon_button.dart`)
        # whose real location is deeper (lib/core/widgets/buttons/...). Fall back
        # to a basename search so a correct-but-partial path isn't false-flagged.
    basename = token.rsplit("/", 1)[-1]
    for base in ("lib", "supabase", "test"):
        if list((ROOT / base).rglob(basename)):
            return True
    return False


def _target_files(target: str) -> list[tuple[str, Path]]:
    """Return (label, path) markdown files for the given target."""
    files: list[tuple[str, Path]] = []
    if target in ("rules", "all"):
        for p in sorted(RULES_DIR.glob("*.md")):
            files.append((p.name, p))
    if target in ("wiki", "all"):
        for p in sorted(WIKI_DIR.rglob("*.md")):
            # Chronological history legitimately names removed symbols — skip it.
            if p.name == "log.md" or p.name.startswith("log-archive"):
                continue
            files.append((str(p.relative_to(WIKI_DIR)), p))
    return files


def scan(target: str = "rules", check_classes: bool = False) -> list[tuple[str, str, str]]:
    """Return list of (doc_label, kind, token) findings."""
    findings: list[tuple[str, str, str]] = []
    for label, path in _target_files(target):
        text = path.read_text(encoding="utf-8")
        seen: set[str] = set()
        for m in PROVIDER_RE.finditer(text):
            name = m.group(1)
            if name in PROVIDER_ALLOWLIST or name in seen:
                continue
            seen.add(name)
            if not _symbol_exists(name):
                findings.append((label, "provider", name))
        for m in DART_PATH_RE.finditer(text):
            token = m.group(1)
            base = token.rsplit("/", 1)[-1]
            if base in DART_PATH_ALLOWLIST or token in seen:
                continue
            seen.add(token)
            if not _dart_path_exists(token):
                findings.append((label, "dart-path", token))
        if check_classes:
            def _check_class(name: str) -> None:
                if name in CLASS_ALLOWLIST or name in seen:
                    return
                seen.add(name)
                if not _symbol_exists(name):
                    findings.append((label, "class", name))

            for m in CLASS_RE.finditer(text):
                _check_class(m.group(1))
            # Bare prose occurrences (strip fenced code + inline backtick spans).
            prose = _INLINE_BT_RE.sub("", _FENCED_RE.sub("", text))
            for m in BARE_CLASS_RE.finditer(prose):
                _check_class(m.group(1))
    return findings


def audit_allowlist() -> list[tuple[str, str]]:
    """Return (bucket, name) for allowlist entries no longer cited by any doc.

    A stale entry is dead cruft — the prose that justified it was removed. Run
    periodically (not gated) to keep the allowlists from bloating.
    """
    all_text = "\n".join(p.read_text(encoding="utf-8") for _, p in _target_files("all"))
    stale: list[tuple[str, str]] = []
    buckets = [
        ("PROVIDER_ALLOWLIST", PROVIDER_ALLOWLIST),
        ("DART_PATH_ALLOWLIST", DART_PATH_ALLOWLIST),
        ("CLASS_ALLOWLIST", CLASS_ALLOWLIST),
    ]
    for bucket, names in buckets:
        for name in sorted(names):
            # Word-boundary match; citations live inside backticks, so backtick
            # must NOT be excluded from the boundary (it is a non-word char).
            if not re.search(rf"(?<!\w){re.escape(name)}(?!\w)", all_text):
                stale.append((bucket, name))
    return stale


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--target",
        choices=("rules", "wiki", "all"),
        default="rules",
        help="Which doc surface to scan (default: rules).",
    )
    parser.add_argument(
        "--classes",
        action="store_true",
        help="Also check PascalCase *Notifier/*Service/*Repository names (advisory).",
    )
    parser.add_argument(
        "--audit-allowlist",
        action="store_true",
        help="Report allowlist entries no longer cited by any doc (periodic cruft check).",
    )
    parser.add_argument(
        "--strict",
        action="store_true",
        help="Exit 1 on any finding (CI-gate mode).",
    )
    args = parser.parse_args()

    if args.audit_allowlist:
        stale = audit_allowlist()
        if not stale:
            print("Allowlist audit OK — every entry is still cited by a doc.")
            return 0
        print("Stale allowlist entries (no doc cites them — remove from the script):")
        for bucket, name in stale:
            print(f"  [{bucket}] {name}")
        return 1 if args.strict else 0

    findings = scan(target=args.target, check_classes=args.classes)
    if not findings:
        print(f"Rule symbol drift check OK ({args.target}) — all referenced symbols resolve.")
        return 0

    print("Rule symbol drift — referenced symbols not found in the codebase:")
    current = None
    for label, kind, token in findings:
        if label != current:
            print(f"\n  {label}")
            current = label
        print(f"    [{kind}] {token}")
    print(
        f"\n  {len(findings)} finding(s). Each is either genuine drift (rename/removed) "
        "or an illustrative placeholder that belongs in the allowlist "
        "(scripts/check_rule_symbol_drift.py)."
    )
    return 1 if args.strict else 0


if __name__ == "__main__":  # pragma: no cover
    sys.exit(main())
