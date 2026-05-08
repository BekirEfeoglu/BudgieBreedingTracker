#!/usr/bin/env python3
"""Unit tests for check_remote_status.py."""

import json
import subprocess
import sys
import unittest
from io import StringIO
from pathlib import Path
from unittest.mock import patch

SCRIPTS_DIR = Path(__file__).resolve().parent
sys.path.insert(0, str(SCRIPTS_DIR))


class TestRemoteStatusParsing(unittest.TestCase):
    def test_summarizes_success_status_and_completed_runs(self):
        import check_remote_status as crs

        result = crs.evaluate_remote_state(
            status_payload={
                "state": "success",
                "statuses": [
                    {"context": "BudgieBreedingTracker | Default", "state": "success"}
                ],
            },
            check_runs_payload={
                "check_runs": [
                    {"name": "Flutter Test", "status": "completed", "conclusion": "success"},
                    {
                        "name": "E2E and Community Test",
                        "status": "completed",
                        "conclusion": "skipped",
                    },
                ],
            },
            allowed_skipped={"E2E and Community Test"},
        )

        self.assertTrue(result.is_clean)
        self.assertEqual(result.summary, {"completed:skipped": 1, "completed:success": 1})
        self.assertEqual(result.unfinished, [])
        self.assertEqual(result.failed, [])

    def test_marks_pending_status_as_not_clean(self):
        import check_remote_status as crs

        result = crs.evaluate_remote_state(
            status_payload={"state": "pending", "statuses": []},
            check_runs_payload={"check_runs": []},
            allowed_skipped=set(),
        )

        self.assertFalse(result.is_clean)
        self.assertIn("commit status is pending", result.reasons)

    def test_marks_unexpected_skipped_run_as_failed(self):
        import check_remote_status as crs

        result = crs.evaluate_remote_state(
            status_payload={"state": "success", "statuses": []},
            check_runs_payload={
                "check_runs": [
                    {
                        "name": "Security Audit",
                        "status": "completed",
                        "conclusion": "skipped",
                    }
                ],
            },
            allowed_skipped={"E2E and Community Test"},
        )

        self.assertFalse(result.is_clean)
        self.assertEqual(result.failed[0]["name"], "Security Audit")
        self.assertEqual(result.failed[0]["conclusion"], "skipped")

    def test_marks_failed_and_unfinished_runs_as_not_clean(self):
        import check_remote_status as crs

        result = crs.evaluate_remote_state(
            status_payload={"state": "success", "statuses": []},
            check_runs_payload={
                "check_runs": [
                    {"name": "Flutter Test", "status": "in_progress"},
                    {
                        "name": "Code Quality",
                        "status": "completed",
                        "conclusion": "failure",
                        "html_url": "https://example.test/run",
                    },
                ],
            },
            allowed_skipped=set(),
        )

        self.assertFalse(result.is_clean)
        self.assertEqual(result.unfinished[0]["name"], "Flutter Test")
        self.assertEqual(result.failed[0]["name"], "Code Quality")
        self.assertIn("1 check-run(s) unfinished", result.reasons)
        self.assertIn("1 check-run(s) failed or unexpectedly skipped", result.reasons)


class TestRemoteStatusCommands(unittest.TestCase):
    def test_fetch_json_uses_gh_api_and_decodes_payload(self):
        import check_remote_status as crs

        payload = {"state": "success"}
        completed = subprocess.CompletedProcess(
            args=["gh"],
            returncode=0,
            stdout=json.dumps(payload),
            stderr="",
        )

        with patch.object(crs.subprocess, "run", return_value=completed) as run:
            result = crs.fetch_json("repos/o/r/commits/abc/status")

        self.assertEqual(result, payload)
        run.assert_called_once()
        self.assertIn("gh", run.call_args.args[0][0])

    def test_fetch_json_raises_clear_error_when_gh_fails(self):
        import check_remote_status as crs

        completed = subprocess.CompletedProcess(
            args=["gh"],
            returncode=1,
            stdout="",
            stderr="not logged in",
        )

        with patch.object(crs.subprocess, "run", return_value=completed):
            with self.assertRaisesRegex(RuntimeError, "gh api failed"):
                crs.fetch_json("repos/o/r/commits/abc/status")

    def test_run_command_returns_stdout(self):
        import check_remote_status as crs

        completed = subprocess.CompletedProcess(
            args=["git"],
            returncode=0,
            stdout="abc123\n",
            stderr="",
        )

        with patch.object(crs.subprocess, "run", return_value=completed):
            self.assertEqual(crs.run_command(["git", "rev-parse", "HEAD"]), "abc123")

    def test_run_command_raises_clear_error(self):
        import check_remote_status as crs

        completed = subprocess.CompletedProcess(
            args=["git"],
            returncode=128,
            stdout="",
            stderr="fatal",
        )

        with patch.object(crs.subprocess, "run", return_value=completed):
            with self.assertRaisesRegex(RuntimeError, "git failed"):
                crs.run_command(["git", "rev-parse", "HEAD"])

    def test_current_head_uses_git_rev_parse(self):
        import check_remote_status as crs

        with patch.object(crs, "run_command", return_value="abc123") as run:
            self.assertEqual(crs.current_head(), "abc123")
        run.assert_called_once_with(["git", "rev-parse", "HEAD"])


class TestRemoteStatusCli(unittest.TestCase):
    def test_parse_args_defaults_repo_and_allowed_skipped(self):
        import check_remote_status as crs

        args = crs.parse_args([])

        self.assertEqual(args.repo, crs.DEFAULT_REPO)
        self.assertEqual(args.allow_skipped, ["E2E and Community Test"])

    def test_print_result_includes_clean_message(self):
        import check_remote_status as crs

        result = crs.RemoteStatusResult(
            is_clean=True,
            status_state="success",
            summary={"completed:success": 1},
            unfinished=[],
            failed=[],
            reasons=[],
        )

        output = StringIO()
        with patch("sys.stdout", output):
            crs.print_result(result, sha="abc123")

        self.assertIn("Remote checks clean.", output.getvalue())

    def test_print_result_lists_unfinished_and_failed_runs(self):
        import check_remote_status as crs

        result = crs.RemoteStatusResult(
            is_clean=False,
            status_state="pending",
            summary={"completed:failure": 1, "in_progress:none": 1},
            unfinished=[
                {
                    "name": "Flutter Test",
                    "status": "in_progress",
                    "conclusion": None,
                    "url": "https://example.test/unfinished",
                }
            ],
            failed=[
                {
                    "name": "Code Quality",
                    "status": "completed",
                    "conclusion": "failure",
                    "url": "https://example.test/failed",
                }
            ],
            reasons=["commit status is pending"],
        )

        output = StringIO()
        with patch("sys.stdout", output):
            crs.print_result(result, sha="abc123")

        rendered = output.getvalue()
        self.assertIn("Unfinished:", rendered)
        self.assertIn("Failed or unexpected:", rendered)
        self.assertIn("commit status is pending", rendered)

    def test_main_returns_0_for_clean_remote_state(self):
        import check_remote_status as crs

        def fake_fetch(endpoint):
            if endpoint.endswith("/status"):
                return {"state": "success", "statuses": []}
            return {
                "check_runs": [
                    {
                        "name": "Flutter Test",
                        "status": "completed",
                        "conclusion": "success",
                    }
                ]
            }

        with patch.object(crs, "current_head", return_value="abc123"), \
             patch.object(crs, "fetch_json", side_effect=fake_fetch), \
             patch("sys.stdout", StringIO()):
            self.assertEqual(crs.main([]), 0)

    def test_main_returns_1_for_pending_remote_state(self):
        import check_remote_status as crs

        def fake_fetch(endpoint):
            if endpoint.endswith("/status"):
                return {"state": "pending", "statuses": []}
            return {"check_runs": []}

        with patch.object(crs, "fetch_json", side_effect=fake_fetch), \
             patch("sys.stdout", StringIO()):
            self.assertEqual(crs.main(["--sha", "abc123"]), 1)


if __name__ == "__main__":
    unittest.main()
