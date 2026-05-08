#!/usr/bin/env python3
"""Check GitHub status and check-runs for an exact commit SHA."""

from __future__ import annotations

import argparse
import json
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[1]
DEFAULT_REPO = "BekirEfeoglu/BudgieBreedingTracker"
DEFAULT_ALLOWED_SKIPPED = {"E2E and Community Test"}


@dataclass(frozen=True)
class RemoteStatusResult:
    is_clean: bool
    status_state: str
    summary: dict[str, int]
    unfinished: list[dict[str, Any]]
    failed: list[dict[str, Any]]
    reasons: list[str]


def run_command(args: list[str], *, cwd: Path = ROOT) -> str:
    completed = subprocess.run(
        args,
        cwd=cwd,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        check=False,
    )
    if completed.returncode != 0:
        raise RuntimeError(
            f"{args[0]} failed with exit {completed.returncode}: "
            f"{completed.stderr.strip()}"
        )
    return completed.stdout.strip()


def fetch_json(endpoint: str) -> dict[str, Any]:
    completed = subprocess.run(
        ["gh", "api", endpoint],
        cwd=ROOT,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        check=False,
    )
    if completed.returncode != 0:
        raise RuntimeError(
            f"gh api failed for {endpoint}: {completed.stderr.strip()}"
        )
    return json.loads(completed.stdout)


def current_head() -> str:
    return run_command(["git", "rev-parse", "HEAD"])


def _run_key(run: dict[str, Any]) -> str:
    return f"{run.get('status')}:{run.get('conclusion') or 'none'}"


def evaluate_remote_state(
    *,
    status_payload: dict[str, Any],
    check_runs_payload: dict[str, Any],
    allowed_skipped: set[str],
) -> RemoteStatusResult:
    status_state = str(status_payload.get("state", "unknown"))
    check_runs = list(check_runs_payload.get("check_runs", []))

    summary: dict[str, int] = {}
    for run in check_runs:
        key = _run_key(run)
        summary[key] = summary.get(key, 0) + 1

    unfinished = [
        {
            "name": run.get("name"),
            "status": run.get("status"),
            "conclusion": run.get("conclusion"),
            "url": run.get("html_url"),
        }
        for run in check_runs
        if run.get("status") != "completed"
    ]
    failed = [
        {
            "name": run.get("name"),
            "status": run.get("status"),
            "conclusion": run.get("conclusion"),
            "url": run.get("html_url"),
        }
        for run in check_runs
        if run.get("status") == "completed"
        and (
            run.get("conclusion") != "success"
            and not (
                run.get("conclusion") == "skipped"
                and run.get("name") in allowed_skipped
            )
        )
    ]

    reasons: list[str] = []
    if status_state != "success":
        reasons.append(f"commit status is {status_state}")
    if unfinished:
        reasons.append(f"{len(unfinished)} check-run(s) unfinished")
    if failed:
        reasons.append(f"{len(failed)} check-run(s) failed or unexpectedly skipped")

    return RemoteStatusResult(
        is_clean=not reasons,
        status_state=status_state,
        summary=dict(sorted(summary.items())),
        unfinished=unfinished,
        failed=failed,
        reasons=reasons,
    )


def print_result(result: RemoteStatusResult, *, sha: str) -> None:
    print(f"Commit: {sha}")
    print(f"Status: {result.status_state}")
    print("Check-run summary:")
    for key, count in result.summary.items():
        print(f"  {key}: {count}")

    if result.unfinished:
        print("\nUnfinished:")
        for run in result.unfinished:
            print(f"  - {run['name']} ({run['status']}) {run.get('url') or ''}".rstrip())

    if result.failed:
        print("\nFailed or unexpected:")
        for run in result.failed:
            print(
                f"  - {run['name']} ({run['status']}:{run['conclusion']}) "
                f"{run.get('url') or ''}".rstrip()
            )

    if result.reasons:
        print("\nNot clean:")
        for reason in result.reasons:
            print(f"  - {reason}")
    else:
        print("\nRemote checks clean.")


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Verify GitHub status/check-runs for an exact commit SHA."
    )
    parser.add_argument("--repo", default=DEFAULT_REPO, help="owner/repo")
    parser.add_argument("--sha", default=None, help="commit SHA, defaults to HEAD")
    parser.add_argument(
        "--allow-skipped",
        action="append",
        default=sorted(DEFAULT_ALLOWED_SKIPPED),
        help="check-run name allowed to be skipped; repeatable",
    )
    return parser.parse_args(argv)


def main(argv: list[str] | None = None) -> int:
    args = parse_args(sys.argv[1:] if argv is None else argv)
    sha = args.sha or current_head()
    status_payload = fetch_json(f"repos/{args.repo}/commits/{sha}/status")
    check_runs_payload = fetch_json(f"repos/{args.repo}/commits/{sha}/check-runs")
    result = evaluate_remote_state(
        status_payload=status_payload,
        check_runs_payload=check_runs_payload,
        allowed_skipped=set(args.allow_skipped),
    )
    print_result(result, sha=sha)
    return 0 if result.is_clean else 1


if __name__ == "__main__":
    raise SystemExit(main())
