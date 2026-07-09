#!/usr/bin/env python3
"""Detect Supabase migration drift before it reaches production.

Migration drift has bitten this repo twice (2026-05-29: local files 10 ahead of
prod + a timestamp collision; 2026-07-09: committed files diverging from the
applied SQL). Both were found by hand. This guard automates the parts that need
no live database so they run on every PR.

Offline checks (default — no network, CI-safe):
  * duplicate version prefixes    — two files with the same YYYYMMDDHHmmss would
                                     apply in an undefined order (the 2026-05-29
                                     collision class)
  * malformed filenames           — anything that is not `<version>_<desc>.sql`
                                     will not sort chronologically / apply cleanly

Online check (--online — needs `supabase` CLI + SUPABASE_ACCESS_TOKEN):
  * version parity vs the linked prod ledger (`supabase migration list --linked`)
    — flags never-applied local files and applied-but-missing-from-repo rows.

Content drift (committed file vs the ledger's applied `statements`) is a deeper
check run manually via the Supabase MCP — see
obsidian-brain/data-layer/migrations.md § Supabase SQL Migrations.

Exit code: 0 when clean, 1 when any checked drift is found.
"""

from __future__ import annotations

import argparse
import re
import subprocess
import sys
from pathlib import Path

# `<14-or-8-digit version>_<snake description>.sql`. The repo has one historical
# 8-digit-only version (`20260309_...`); everything newer is a full timestamp.
VERSION_RE = re.compile(r"^(\d{8}|\d{14})_[a-z0-9][a-z0-9_]*\.sql$")

REPO_ROOT = Path(__file__).resolve().parent.parent
DEFAULT_MIGRATIONS_DIR = REPO_ROOT / "supabase" / "migrations"


def list_migration_files(migrations_dir: Path) -> list[str]:
    """Return migration filenames sorted lexicographically (== apply order)."""
    return sorted(p.name for p in Path(migrations_dir).glob("*.sql"))


def parse_version(filename: str) -> str | None:
    """Return the version prefix, or None if the filename is malformed."""
    match = VERSION_RE.match(filename)
    return match.group(1) if match else None


def find_malformed(filenames: list[str]) -> list[str]:
    """Filenames that do not match the `<version>_<desc>.sql` contract."""
    return [name for name in filenames if parse_version(name) is None]


def find_duplicate_versions(filenames: list[str]) -> dict[str, list[str]]:
    """Map each duplicated version prefix to the files that share it."""
    by_version: dict[str, list[str]] = {}
    for name in filenames:
        version = parse_version(name)
        if version is not None:
            by_version.setdefault(version, []).append(name)
    return {version: files for version, files in by_version.items() if len(files) > 1}


def run_supabase_migration_list() -> str:
    """Return stdout of `supabase migration list --linked` (raises on failure)."""
    proc = subprocess.run(
        ["supabase", "migration", "list", "--linked"],
        capture_output=True,
        text=True,
    )
    if proc.returncode != 0:
        raise RuntimeError(proc.stderr.strip() or "supabase migration list failed")
    return proc.stdout


def parse_ledger_versions(text: str) -> set[str]:
    """Extract the remote-applied version column from CLI table output.

    Rows look like `  <local> | <remote> | <time>`; a version is a run of 8-14
    digits. We take every version token present so a version applied remotely is
    counted regardless of which column it lands in.
    """
    versions: set[str] = set()
    for line in text.splitlines():
        for token in re.findall(r"\b(\d{8}|\d{14})\b", line):
            versions.add(token)
    return versions


def compare_versions(local: list[str], remote: set[str]) -> tuple[list[str], list[str]]:
    """Return (local-only versions, remote-only versions)."""
    local_versions = {v for v in (parse_version(name) for name in local) if v}
    local_only = sorted(local_versions - remote)
    remote_only = sorted(remote - local_versions)
    return local_only, remote_only


def check(migrations_dir: Path, online: bool = False) -> list[str]:
    """Run the drift checks; return a list of human-readable problem strings."""
    problems: list[str] = []
    filenames = list_migration_files(migrations_dir)

    malformed = find_malformed(filenames)
    for name in malformed:
        problems.append(f"malformed migration filename: {name}")

    duplicates = find_duplicate_versions(filenames)
    for version, files in sorted(duplicates.items()):
        problems.append(f"duplicate version {version}: {', '.join(files)}")

    if online:
        try:
            remote = parse_ledger_versions(run_supabase_migration_list())
        except (RuntimeError, FileNotFoundError) as exc:
            problems.append(f"online ledger check failed: {exc}")
        else:
            local_only, remote_only = compare_versions(filenames, remote)
            for version in local_only:
                problems.append(f"local migration never applied to prod: {version}")
            for version in remote_only:
                problems.append(f"prod migration missing from repo: {version}")

    return problems


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--dir",
        default=str(DEFAULT_MIGRATIONS_DIR),
        help="migrations directory (default: supabase/migrations)",
    )
    parser.add_argument(
        "--online",
        action="store_true",
        help="also compare versions against the linked prod ledger (needs a token)",
    )
    args = parser.parse_args(argv)

    problems = check(Path(args.dir), online=args.online)
    total = len(list_migration_files(Path(args.dir)))

    if problems:
        print(f"Migration drift check FAILED ({len(problems)} issue(s)):")
        for problem in problems:
            print(f"  - {problem}")
        return 1

    scope = "structure + prod parity" if args.online else "structure"
    print(f"Migration drift check OK — {total} files, {scope} clean.")
    return 0


if __name__ == "__main__":  # pragma: no cover
    sys.exit(main())
