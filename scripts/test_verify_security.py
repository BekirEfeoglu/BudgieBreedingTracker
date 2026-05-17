#!/usr/bin/env python3
"""Unit tests for verify_security.py."""

import sys
from contextlib import redirect_stdout
from io import StringIO
import subprocess
import tempfile
import unittest
from pathlib import Path
from types import SimpleNamespace
from unittest.mock import patch

SCRIPTS_DIR = Path(__file__).resolve().parent
sys.path.insert(0, str(SCRIPTS_DIR))


def _write(path: Path, body: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(body, encoding="utf-8")


def _good_codemagic_yaml() -> str:
    return """
workflows:
  android-release:
    scripts:
      - name: Build Android
        script: |
          flutter build appbundle --release \\
            --obfuscate \\
            --split-debug-info=build/symbols/android
  ios-release:
    scripts:
      - name: Build iOS
        script: |
          flutter build ipa --release \\
            --obfuscate \\
            --split-debug-info=build/symbols/ios
"""


def _good_release_ready_yaml() -> str:
    return """
name: Release Ready
jobs:
  android-release:
    steps:
      - name: Build Android App Bundle (release)
        run: |
          flutter build appbundle --release \\
            --obfuscate \\
            --split-debug-info=build/symbols/android
"""


class TestReleaseObfuscation(unittest.TestCase):
    def test_accepts_android_release_in_release_ready_workflow(self):
        import verify_security as vs

        with tempfile.TemporaryDirectory() as d:
            root = Path(d)
            _write(root / "codemagic.yaml", _good_codemagic_yaml())
            _write(
                root / ".github" / "workflows" / "ci.yml",
                "name: CI\njobs:\n  android-build:\n    steps: []\n",
            )
            _write(
                root / ".github" / "workflows" / "release-ready.yml",
                _good_release_ready_yaml(),
            )

            with patch.object(vs, "ROOT", root):
                results = vs.check_release_obfuscation()

        self.assertTrue(all(passed for _, passed, _ in results), results)
        self.assertIn(
            ("release-ready.yml android-release", True, "obfuscation enabled"),
            results,
        )

    def test_rejects_release_ready_without_split_debug_info(self):
        import verify_security as vs

        with tempfile.TemporaryDirectory() as d:
            root = Path(d)
            _write(root / "codemagic.yaml", _good_codemagic_yaml())
            _write(
                root / ".github" / "workflows" / "release-ready.yml",
                """
name: Release Ready
jobs:
  android-release:
    steps:
      - name: Build Android App Bundle (release)
        run: flutter build appbundle --release --obfuscate
""",
            )

            with patch.object(vs, "ROOT", root):
                results = vs.check_release_obfuscation()

        self.assertIn(
            (
                "release-ready.yml android-release",
                False,
                "missing --obfuscate or --split-debug-info "
                "(obfuscate=True, split=False)",
            ),
            results,
        )

    def test_reports_missing_release_ready_workflow(self):
        import verify_security as vs

        with tempfile.TemporaryDirectory() as d:
            root = Path(d)
            _write(root / "codemagic.yaml", _good_codemagic_yaml())

            with patch.object(vs, "ROOT", root):
                results = vs.check_release_obfuscation()

        self.assertIn(
            (
                ".github/workflows/release-ready.yml",
                False,
                "file missing",
            ),
            results,
        )


class TestEdgeFunctionSecurityHeaders(unittest.TestCase):
    def test_accepts_all_required_headers(self):
        import verify_security as vs

        with tempfile.TemporaryDirectory() as d:
            root = Path(d)
            _write(
                root / "supabase" / "functions" / "_shared" / "cors.ts",
                """
export const securityHeaders = {
  "Strict-Transport-Security": "max-age=63072000",
  "X-Content-Type-Options": "nosniff",
  "X-Frame-Options": "DENY",
  "Referrer-Policy": "no-referrer",
  "Content-Security-Policy": "default-src 'none'",
};
""",
            )

            with patch.object(vs, "ROOT", root):
                results = vs.check_edge_function_security_headers()

        self.assertTrue(all(passed for _, passed, _ in results), results)
        self.assertEqual(5, len(results))

    def test_reports_missing_header(self):
        import verify_security as vs

        with tempfile.TemporaryDirectory() as d:
            root = Path(d)
            _write(
                root / "supabase" / "functions" / "_shared" / "cors.ts",
                '"Strict-Transport-Security": "max-age=63072000"',
            )

            with patch.object(vs, "ROOT", root):
                results = vs.check_edge_function_security_headers()

        self.assertIn(
            (
                "edge X-Content-Type-Options",
                False,
                "missing (MIME sniff protection)",
            ),
            results,
        )


class TestEdgeFunctionJwtVerification(unittest.TestCase):
    def test_accepts_functions_with_explicit_verify_jwt_true(self):
        import verify_security as vs

        with tempfile.TemporaryDirectory() as d:
            root = Path(d)
            _write(root / "supabase" / "functions" / "send-push" / "index.ts", "")
            _write(
                root
                / "supabase"
                / "functions"
                / "sync-premium-status"
                / "index.ts",
                "",
            )
            _write(
                root / "supabase" / "config.toml",
                """
[functions.send-push]
verify_jwt = true

[functions.sync-premium-status]
verify_jwt = true
""",
            )

            with patch.object(vs, "ROOT", root):
                results = vs.check_edge_function_jwt_verification()

        self.assertTrue(all(passed for _, passed, _ in results), results)
        self.assertIn(
            ("edge function send-push verify_jwt", True, "explicit true"),
            results,
        )
        self.assertIn(
            ("edge deploy no-verify-jwt", True, "not used"),
            results,
        )

    def test_rejects_missing_or_disabled_verify_jwt_and_deploy_bypass(self):
        import verify_security as vs

        with tempfile.TemporaryDirectory() as d:
            root = Path(d)
            _write(root / "supabase" / "functions" / "public-fn" / "index.ts", "")
            _write(root / "supabase" / "functions" / "unsafe-fn" / "index.ts", "")
            _write(
                root / "supabase" / "config.toml",
                """
[functions.unsafe-fn]
verify_jwt = false
""",
            )
            _write(
                root / ".github" / "workflows" / "deploy.yml",
                "supabase functions deploy unsafe-fn --no-verify-jwt",
            )

            with patch.object(vs, "ROOT", root):
                results = vs.check_edge_function_jwt_verification()

        self.assertIn(
            (
                "edge function public-fn verify_jwt",
                False,
                "missing [functions.public-fn] verify_jwt = true",
            ),
            results,
        )
        self.assertIn(
            (
                "edge function unsafe-fn verify_jwt",
                False,
                "expected true, found false",
            ),
            results,
        )
        self.assertEqual("edge deploy no-verify-jwt", results[-1][0])
        self.assertFalse(results[-1][1])


class TestCertificatePinning(unittest.TestCase):
    def test_accepts_pinning_module_wired_into_bootstrap(self):
        import verify_security as vs

        with tempfile.TemporaryDirectory() as d:
            root = Path(d)
            _write(
                root / "lib" / "core" / "security" / "certificate_pinning.dart",
                "class CertificatePinning { static void install() {} }",
            )
            _write(
                root / "lib" / "bootstrap.dart",
                "void bootstrap() { CertificatePinning.install(); }",
            )

            with patch.object(vs, "ROOT", root):
                results = vs.check_certificate_pinning()

        self.assertEqual(
            [("certificate pinning", True, "installed in bootstrap")],
            results,
        )

    def test_rejects_unwired_pinning_module(self):
        import verify_security as vs

        with tempfile.TemporaryDirectory() as d:
            root = Path(d)
            _write(
                root / "lib" / "core" / "security" / "certificate_pinning.dart",
                "class CertificatePinning { static void install() {} }",
            )

            with patch.object(vs, "ROOT", root):
                results = vs.check_certificate_pinning()

        self.assertEqual(
            [
                (
                    "certificate pinning",
                    False,
                    "module exists but not wired into bootstrap/main",
                )
            ],
            results,
        )


class TestServiceRoleIsolation(unittest.TestCase):
    def test_ignores_service_role_mentions_in_comments(self):
        import verify_security as vs

        with tempfile.TemporaryDirectory() as d:
            root = Path(d)
            _write(
                root / "lib" / "safe.dart",
                "/// SUPABASE_SERVICE_ROLE_KEY must never be used here.\n",
            )

            with patch.object(vs, "ROOT", root):
                results = vs.check_no_service_role_in_client()

        self.assertEqual(
            [("service role key", True, "not present in client code")],
            results,
        )

    def test_flags_service_role_usage_in_client_code(self):
        import verify_security as vs

        with tempfile.TemporaryDirectory() as d:
            root = Path(d)
            _write(
                root / "lib" / "unsafe.dart",
                'const key = "SUPABASE_SERVICE_ROLE_KEY";\n',
            )

            with patch.object(vs, "ROOT", root):
                results = vs.check_no_service_role_in_client()

        self.assertEqual("service role key", results[0][0])
        self.assertFalse(results[0][1])
        self.assertIn("lib/unsafe.dart:1", results[0][2])


class TestSecretFileChecks(unittest.TestCase):
    def test_reports_missing_gitignore_secret_patterns(self):
        import verify_security as vs

        with tempfile.TemporaryDirectory() as d:
            root = Path(d)
            _write(root / ".gitignore", ".env\n*.jks\n")

            with patch.object(vs, "ROOT", root):
                results = vs.check_gitignore_secrets()

        self.assertIn((".gitignore .env", True, "ignored"), results)
        self.assertIn(
            (".gitignore *.keystore", False, "secret pattern not ignored"),
            results,
        )
        self.assertIn(
            (".gitignore key.properties", False, "secret pattern not ignored"),
            results,
        )

    def test_flags_tracked_secret_files_but_allows_examples(self):
        import verify_security as vs

        run_result = SimpleNamespace(
            stdout="\n".join(
                [
                    "lib/main.dart",
                    ".env",
                    ".env.example",
                    "android/key.properties",
                    "android/key.properties.example",
                ]
            )
        )

        with patch.object(vs.subprocess, "run", return_value=run_result):
            results = vs.check_no_secrets_committed()

        self.assertEqual("committed secrets", results[0][0])
        self.assertFalse(results[0][1])
        self.assertIn(".env", results[0][2])
        self.assertIn("android/key.properties", results[0][2])
        self.assertNotIn(".env.example", results[0][2])
        self.assertNotIn("android/key.properties.example", results[0][2])

    def test_reports_when_git_ls_files_is_unavailable(self):
        import verify_security as vs

        with patch.object(
            vs.subprocess,
            "run",
            side_effect=subprocess.CalledProcessError(1, "git"),
        ):
            results = vs.check_no_secrets_committed()

        self.assertEqual(
            [("git ls-files", False, "git unavailable; cannot verify")],
            results,
        )


class TestAuditLogging(unittest.TestCase):
    def test_accepts_pgaudit_and_audit_logs_migration(self):
        import verify_security as vs

        with tempfile.TemporaryDirectory() as d:
            root = Path(d)
            _write(
                root / "supabase" / "migrations" / "001_audit.sql",
                "create extension pgaudit; create table audit_logs(id uuid);",
            )

            with patch.object(vs, "ROOT", root):
                results = vs.check_pgaudit_migration()

        self.assertEqual(
            [("audit logging", True, "pgaudit + audit_logs both present")],
            results,
        )

    def test_rejects_audit_logs_without_pgaudit(self):
        import verify_security as vs

        with tempfile.TemporaryDirectory() as d:
            root = Path(d)
            _write(
                root / "supabase" / "migrations" / "001_audit.sql",
                "create table audit_logs(id uuid);",
            )

            with patch.object(vs, "ROOT", root):
                results = vs.check_pgaudit_migration()

        self.assertEqual(
            [
                (
                    "audit logging",
                    False,
                    "audit_logs table present, pgaudit migration missing",
                )
            ],
            results,
        )


class TestPremiumSyncAuthorization(unittest.TestCase):
    def test_accepts_edge_function_sync_and_fail_closed_rpc(self):
        import verify_security as vs

        with tempfile.TemporaryDirectory() as d:
            root = Path(d)
            _write(
                root / "lib" / "domain" / "services" / "premium" / "premium.dart",
                '"sync-premium-status";',
            )
            _write(
                root / "supabase" / "migrations" / "001_premium.sql",
                "premium_sync_requires_server_verification\n"
                "sync-premium-status Edge Function",
            )

            with patch.object(vs, "ROOT", root):
                results = vs.check_premium_sync_server_verified()

        self.assertEqual(
            [
                ("premium sync client path", True, "uses Edge Function verification"),
                ("premium sync RPC", True, "legacy RPC is fail-closed"),
            ],
            results,
        )

    def test_rejects_direct_client_rpc_premium_sync(self):
        import verify_security as vs

        with tempfile.TemporaryDirectory() as d:
            root = Path(d)
            _write(
                root / "lib" / "domain" / "services" / "premium" / "premium.dart",
                'client.rpc("sync_premium_status");',
            )

            with patch.object(vs, "ROOT", root):
                results = vs.check_premium_sync_server_verified()

        self.assertEqual("premium sync client path", results[0][0])
        self.assertFalse(results[0][1])


class TestSupabaseAuthHardening(unittest.TestCase):
    def test_accepts_hardened_supabase_auth_config(self):
        import verify_security as vs

        with tempfile.TemporaryDirectory() as d:
            root = Path(d)
            _write(
                root / "supabase" / "config.toml",
                """
[auth]
jwt_expiry = 900
enable_anonymous_sign_ins = false
enable_confirmations = true

[auth.mfa.totp]
enroll_enabled = true
verify_enabled = true
""",
            )

            with patch.object(vs, "ROOT", root):
                results = vs.check_supabase_auth_hardening()

        self.assertEqual(
            [
                ("auth jwt expiry", True, "900s"),
                ("auth anonymous sign-ins", True, "disabled"),
                ("auth email confirmations", True, "enabled"),
                ("auth totp mfa", True, "enroll+verify enabled"),
            ],
            results,
        )

    def test_rejects_weak_supabase_auth_config(self):
        import verify_security as vs

        with tempfile.TemporaryDirectory() as d:
            root = Path(d)
            _write(
                root / "supabase" / "config.toml",
                """
[auth]
jwt_expiry = 3600
enable_anonymous_sign_ins = true
enable_confirmations = false

[auth.mfa.totp]
enroll_enabled = false
verify_enabled = false
""",
            )

            with patch.object(vs, "ROOT", root):
                results = vs.check_supabase_auth_hardening()

        self.assertIn(
            ("auth jwt expiry", False, "expected <=900s, found 3600"),
            results,
        )
        self.assertIn(
            ("auth anonymous sign-ins", False, "expected false, found true"),
            results,
        )
        self.assertIn(
            ("auth email confirmations", False, "expected true, found false"),
            results,
        )
        self.assertIn(
            (
                "auth totp mfa",
                False,
                "expected enroll_enabled=true and verify_enabled=true, "
                "found enroll=false verify=false",
            ),
            results,
        )


class TestMain(unittest.TestCase):
    def test_main_returns_failure_when_any_control_fails(self):
        import verify_security as vs

        def failing_check():
            return [("bad control", False, "broken")]

        with patch.object(vs, "CHECKS", [("Broken", failing_check)]):
            with redirect_stdout(StringIO()):
                result = vs.main()

        self.assertEqual(1, result)


if __name__ == "__main__":
    unittest.main()
