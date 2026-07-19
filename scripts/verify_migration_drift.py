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
  * applied-chain baseline        — filename + SHA-256 fixture prevents editing
                                     or removing historical applied SQL

Online check (--online — needs `supabase` CLI + SUPABASE_ACCESS_TOKEN):
  * version parity vs the linked prod ledger (`supabase migration list --linked`)
    — parses only remote versions, resolves documented apply-time aliases, and
      flags never-applied local files / applied-but-missing-from-repo rows.

Content drift (committed file vs the ledger's applied `statements`) is a deeper
check run manually via the Supabase MCP — see
obsidian-brain/data-layer/migrations.md § Supabase SQL Migrations.

Exit code: 0 when clean, 1 when any checked drift is found.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path

# `<14-or-8-digit version>_<snake description>.sql`. The repo has one historical
# 8-digit-only version (`20260309_...`); everything newer is a full timestamp.
VERSION_RE = re.compile(r"^(\d{8}|\d{14})_[a-z0-9][a-z0-9_]*\.sql$")

REPO_ROOT = Path(__file__).resolve().parent.parent
DEFAULT_MIGRATIONS_DIR = REPO_ROOT / "supabase" / "migrations"
DEFAULT_BASELINE_PATH = (
    REPO_ROOT / "scripts" / "fixtures" / "supabase_applied_migration_baseline.txt"
)


@dataclass(frozen=True)
class AppliedMigrationBaselineEntry:
    """Immutable local file plus the version recorded in the prod ledger."""

    filename: str
    sha256: str
    remote_version: str

    @property
    def local_version(self) -> str:
        version = parse_version(self.filename)
        if version is None:  # Validated while loading; keeps the type explicit.
            raise ValueError(f"malformed baseline filename: {self.filename}")
        return version


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


def load_applied_baseline(path: Path) -> list[AppliedMigrationBaselineEntry]:
    """Load the immutable applied-chain fixture.

    Each non-comment line is tab-separated as
    `<sha256> <local filename> <remote ledger version>`. The remote version may
    differ from the canonical local filename only for a documented historical
    apply-time alias.
    """
    entries: list[AppliedMigrationBaselineEntry] = []
    seen_files: set[str] = set()
    seen_local_versions: set[str] = set()
    seen_remote_versions: set[str] = set()

    for line_number, raw_line in enumerate(
        path.read_text(encoding="utf-8").splitlines(),
        start=1,
    ):
        line = raw_line.strip()
        if not line or line.startswith("#"):
            continue

        parts = raw_line.split("\t")
        if len(parts) != 3:
            raise ValueError(
                f"baseline line {line_number} must have 3 tab-separated fields"
            )
        digest, filename, remote_version = (part.strip() for part in parts)
        local_version = parse_version(filename)
        if not re.fullmatch(r"[0-9a-f]{64}", digest):
            raise ValueError(f"baseline line {line_number} has invalid sha256")
        if local_version is None:
            raise ValueError(
                f"baseline line {line_number} has malformed filename: {filename}"
            )
        if not re.fullmatch(r"\d{8}|\d{14}", remote_version):
            raise ValueError(
                f"baseline line {line_number} has invalid remote version"
            )
        if filename in seen_files or local_version in seen_local_versions:
            raise ValueError(
                f"baseline line {line_number} duplicates local migration {filename}"
            )
        if remote_version in seen_remote_versions:
            raise ValueError(
                f"baseline line {line_number} duplicates remote version {remote_version}"
            )

        seen_files.add(filename)
        seen_local_versions.add(local_version)
        seen_remote_versions.add(remote_version)
        entries.append(
            AppliedMigrationBaselineEntry(
                filename=filename,
                sha256=digest,
                remote_version=remote_version,
            )
        )

    return entries


def check_applied_baseline(
    migrations_dir: Path,
    filenames: list[str],
    entries: list[AppliedMigrationBaselineEntry],
) -> list[str]:
    """Return problems when an immutable baseline file was changed or removed."""
    problems: list[str] = []
    available = set(filenames)
    for entry in entries:
        if entry.filename not in available:
            problems.append(f"applied baseline migration missing: {entry.filename}")
            continue

        digest = hashlib.sha256(
            (migrations_dir / entry.filename).read_bytes()
        ).hexdigest()
        if digest != entry.sha256:
            problems.append(f"applied baseline migration changed: {entry.filename}")
    return problems


def version_aliases(
    entries: list[AppliedMigrationBaselineEntry],
) -> dict[str, str]:
    """Map canonical local versions to historical prod ledger aliases."""
    return {
        entry.local_version: entry.remote_version
        for entry in entries
        if entry.local_version != entry.remote_version
    }


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
    """Extract only remote-applied versions from Supabase CLI JSON/table output."""
    stripped = text.strip()
    if stripped.startswith("{"):
        try:
            payload = json.loads(stripped)
        except json.JSONDecodeError:
            pass
        else:
            migrations = payload.get("migrations", [])
            return {
                remote
                for row in migrations
                if isinstance(row, dict)
                and isinstance((remote := row.get("remote")), str)
                and re.fullmatch(r"\d{8}|\d{14}", remote)
            }

    versions: set[str] = set()
    for line in text.splitlines():
        columns = [column.strip() for column in line.split("|")]
        if len(columns) < 2:
            continue
        remote = columns[1]
        if re.fullmatch(r"\d{8}|\d{14}", remote):
            versions.add(remote)
    return versions


def compare_versions(
    local: list[str],
    remote: set[str],
    aliases: dict[str, str] | None = None,
) -> tuple[list[str], list[str]]:
    """Return (local-only versions, remote-only versions)."""
    local_versions = {v for v in (parse_version(name) for name in local) if v}
    reverse_aliases = {
        remote_version: local_version
        for local_version, remote_version in (aliases or {}).items()
    }
    normalized_remote = {
        reverse_aliases.get(remote_version, remote_version)
        for remote_version in remote
    }
    local_only = sorted(local_versions - normalized_remote)
    remote_only = sorted(normalized_remote - local_versions)
    return local_only, remote_only


def check(
    migrations_dir: Path,
    online: bool = False,
    baseline_path: Path | None = None,
) -> list[str]:
    """Run the drift checks; return a list of human-readable problem strings."""
    problems: list[str] = []
    filenames = list_migration_files(migrations_dir)

    malformed = find_malformed(filenames)
    for name in malformed:
        problems.append(f"malformed migration filename: {name}")

    duplicates = find_duplicate_versions(filenames)
    for version, files in sorted(duplicates.items()):
        problems.append(f"duplicate version {version}: {', '.join(files)}")

    aliases: dict[str, str] = {}
    if baseline_path is not None:
        try:
            baseline = load_applied_baseline(baseline_path)
        except (OSError, ValueError) as exc:
            problems.append(f"applied migration baseline invalid: {exc}")
        else:
            problems.extend(
                check_applied_baseline(migrations_dir, filenames, baseline)
            )
            aliases = version_aliases(baseline)

    if online:
        try:
            remote = parse_ledger_versions(run_supabase_migration_list())
        except (RuntimeError, FileNotFoundError) as exc:
            problems.append(f"online ledger check failed: {exc}")
        else:
            for local_version, remote_version in aliases.items():
                if local_version in remote and remote_version in remote:
                    problems.append(
                        "both canonical and aliased migration versions are applied: "
                        f"{local_version}, {remote_version}"
                    )

            local_only, remote_only = compare_versions(
                filenames,
                remote,
                aliases=aliases,
            )
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
        "--baseline",
        help=(
            "applied-chain baseline fixture; defaults to the repository fixture "
            "when --dir is supabase/migrations"
        ),
    )
    parser.add_argument(
        "--online",
        action="store_true",
        help="also compare versions against the linked prod ledger (needs a token)",
    )
    args = parser.parse_args(argv)

    migrations_dir = Path(args.dir)
    if args.baseline:
        baseline_path: Path | None = Path(args.baseline)
    elif migrations_dir.resolve() == DEFAULT_MIGRATIONS_DIR.resolve():
        baseline_path = DEFAULT_BASELINE_PATH
    else:
        baseline_path = None

    problems = check(
        migrations_dir,
        online=args.online,
        baseline_path=baseline_path,
    )
    total = len(list_migration_files(migrations_dir))

    if problems:
        print(f"Migration drift check FAILED ({len(problems)} issue(s)):")
        for problem in problems:
            print(f"  - {problem}")
        return 1

    scope = (
        "structure + applied baseline + prod parity"
        if args.online
        else "structure + applied baseline"
    )
    print(f"Migration drift check OK — {total} files, {scope} clean.")
    return 0


if __name__ == "__main__":  # pragma: no cover
    sys.exit(main())
