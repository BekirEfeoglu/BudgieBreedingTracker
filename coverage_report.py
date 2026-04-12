#!/usr/bin/env python3
"""Parse lcov.info and generate a coverage summary report."""

import os
import re
from collections import defaultdict

LCOV_FILE = "coverage/lcov.info"
OUTPUT_FILE = "coverage/coverage_report.txt"

# Files excluded from coverage metrics (generated code, untestable Drift schema files)
EXCLUDED_SUFFIXES = (".g.dart", ".freezed.dart")
EXCLUDED_PATHS = (
    "lib/data/local/database/tables/",  # Drift table schema definitions (generated-like)
)
# Files tracked separately as "integration test required"
INTEGRATION_ONLY_FILES = {"lib/app.dart", "lib/bootstrap.dart"}


def is_excluded(path):
    """Return True if the file should be excluded from coverage metrics."""
    fname = os.path.basename(path)
    if any(fname.endswith(suffix) for suffix in EXCLUDED_SUFFIXES):
        return True
    for excluded_path in EXCLUDED_PATHS:
        if path.startswith(excluded_path) and path.endswith("_table.dart"):
            return True
    return False


def parse_lcov(path):
    files = {}
    current = None

    with open(path, encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if line.startswith("SF:"):
                current = line[3:].replace("\\", "/")
                # Normalize to relative path
                idx = current.find("lib/")
                if idx == -1:
                    idx = current.find("test/")
                if idx != -1:
                    current = current[idx:]
                # Skip excluded files immediately
                if is_excluded(current):
                    current = None
                    continue
                files[current] = {"lf": 0, "lh": 0}
            elif line.startswith("LF:") and current:
                files[current]["lf"] = int(line[3:])
            elif line.startswith("LH:") and current:
                files[current]["lh"] = int(line[3:])
            elif line == "end_of_record":
                current = None

    return files

def group_by_feature(files):
    groups = defaultdict(list)
    for path, data in sorted(files.items()):
        lf = data["lf"]
        lh = data["lh"]
        pct = (lh / lf * 100) if lf > 0 else 0.0

        # Integration-only files go to a separate bucket
        if path in INTEGRATION_ONLY_FILES:
            groups["[integration-only]"].append((path, lf, lh, pct))
            continue

        # Determine group
        if path.startswith("lib/features/"):
            parts = path.split("/")
            group = "features/" + parts[2] if len(parts) > 2 else "features"
        elif path.startswith("lib/core/"):
            group = "core"
        elif path.startswith("lib/data/"):
            group = "data"
        elif path.startswith("lib/domain/"):
            group = "domain"
        elif path.startswith("lib/router/"):
            group = "router"
        elif path.startswith("test/"):
            continue  # Skip test files themselves
        else:
            group = "other"

        groups[group].append((path, lf, lh, pct))

    return groups

def render(files):
    groups = group_by_feature(files)

    # Exclude integration-only files from totals
    integration_files = set(INTEGRATION_ONLY_FILES)
    effective_files = {p: d for p, d in files.items() if p not in integration_files}
    total_lf = sum(d["lf"] for d in effective_files.values())
    total_lh = sum(d["lh"] for d in effective_files.values())
    total_pct = (total_lh / total_lf * 100) if total_lf > 0 else 0.0

    lines = []
    lines.append("=" * 72)
    lines.append("FLUTTER CODE COVERAGE REPORT")
    lines.append("(Excludes: *.g.dart, *.freezed.dart, data/local/database/tables/*_table.dart)")
    lines.append("=" * 72)
    lines.append(f"Total: {total_lh}/{total_lf} lines covered ({total_pct:.1f}%)")
    lines.append("")

    # Sort groups: put [integration-only] last
    sorted_groups = sorted(
        groups.keys(),
        key=lambda g: (1 if g == "[integration-only]" else 0, g),
    )

    for group in sorted_groups:
        entries = groups[group]
        g_lf = sum(e[1] for e in entries)
        g_lh = sum(e[2] for e in entries)
        g_pct = (g_lh / g_lf * 100) if g_lf > 0 else 0.0

        lines.append("-" * 72)
        if group == "[integration-only]":
            lines.append(f"[integration-only — excluded from total]  {g_lh}/{g_lf} ({g_pct:.1f}%)")
        else:
            lines.append(f"[{group}]  {g_lh}/{g_lf} ({g_pct:.1f}%)")
        lines.append("-" * 72)

        for (path, lf, lh, pct) in sorted(entries, key=lambda x: x[3]):
            bar_len = int(pct / 5)  # 0-20 chars
            bar = "#" * bar_len + "." * (20 - bar_len)
            fname = os.path.basename(path)
            lines.append(f"  {pct:5.1f}% [{bar}] {lh:4}/{lf:4}  {fname}")

        lines.append("")

    return "\n".join(lines)

def main():
    if not os.path.exists(LCOV_FILE):
        print(f"ERROR: {LCOV_FILE} not found. Run: flutter test --coverage")
        return

    files = parse_lcov(LCOV_FILE)
    report = render(files)

    os.makedirs("coverage", exist_ok=True)
    with open(OUTPUT_FILE, "w", encoding="utf-8") as f:
        f.write(report)

    print(report)
    print(f"\nReport saved to: {OUTPUT_FILE}")

if __name__ == "__main__":
    main()
