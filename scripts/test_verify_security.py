#!/usr/bin/env python3
"""Unit tests for verify_security.py."""

import sys
from contextlib import redirect_stdout
from io import StringIO
import subprocess
import tempfile
from datetime import date
import unittest
from pathlib import Path
from types import SimpleNamespace
from unittest.mock import patch

SCRIPTS_DIR = Path(__file__).resolve().parent
sys.path.insert(0, str(SCRIPTS_DIR))


def _write(path: Path, body: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(body, encoding="utf-8")


def _good_release_script() -> str:
    """Minimal stand-in for scripts/build_release.sh.

    Codemagic was removed 2026-07-25; the release-obfuscation contract moved
    to this script, so the fixture models it instead of codemagic.yaml.
    """
    return """
set -euo pipefail
grep -qE '^SENTRY_DSN=.+' "$ENV_FILE" || missing+=("SENTRY_DSN")
[[ -n "${SENTRY_AUTH_TOKEN:-}" ]] || missing+=("SENTRY_AUTH_TOKEN")
echo "ERROR: release build refused, missing:" >&2
exit 1

flutter build ipa --release \\
  --dart-define-from-file="$ENV_FILE" \\
  --obfuscate \\
  --split-debug-info=build/symbols/ios

upload_sentry_symbols() {
  local platform="$1"
  local symbols_path="build/symbols/$platform"
  local stale_paths=(build/release-artifacts build/app/outputs build/ios)
  dart run sentry_dart_plugin \\
    "--sentry-define=symbols_path=$symbols_path"
}

upload_sentry_symbols ios

flutter build appbundle --release \\
  --dart-define-from-file="$ENV_FILE" \\
  --obfuscate \\
  --split-debug-info=build/symbols/android

upload_sentry_symbols android
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
      - name: Upload Android debug symbols to Sentry
        run: |
          dart run sentry_dart_plugin \\
            --sentry-define=symbols_path=build/symbols/android
"""


class TestReleaseObfuscation(unittest.TestCase):
    def test_accepts_android_release_in_release_ready_workflow(self):
        import verify_security as vs

        with tempfile.TemporaryDirectory() as d:
            root = Path(d)
            _write(root / "scripts" / "build_release.sh", _good_release_script())
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
        self.assertIn(
            (
                "release-ready.yml symbols",
                True,
                "Android symbol upload is platform-scoped",
            ),
            results,
        )

    def test_rejects_cross_platform_symbol_discovery(self):
        import verify_security as vs

        with tempfile.TemporaryDirectory() as d:
            root = Path(d)
            broad_script = _good_release_script().replace(
                '"--sentry-define=symbols_path=$symbols_path"',
                "--sentry-define=symbols_path=build",
            )
            _write(root / "scripts" / "build_release.sh", broad_script)
            _write(
                root / ".github" / "workflows" / "release-ready.yml",
                _good_release_ready_yaml(),
            )

            with patch.object(vs, "ROOT", root):
                results = vs.check_release_obfuscation()

        self.assertIn(
            (
                "build_release.sh symbols",
                False,
                "missing platform-scoped sentry_dart_plugin upload",
            ),
            results,
        )

    def test_rejects_release_ready_without_split_debug_info(self):
        import verify_security as vs

        with tempfile.TemporaryDirectory() as d:
            root = Path(d)
            _write(root / "scripts" / "build_release.sh", _good_release_script())
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
            _write(root / "scripts" / "build_release.sh", _good_release_script())

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

    def test_accepts_documented_webhook_exemption(self):
        """Webhook receivers can opt out of JWT with verify_jwt = false."""
        import verify_security as vs

        with tempfile.TemporaryDirectory() as d:
            root = Path(d)
            _write(
                root / "supabase" / "functions" / "send-push" / "index.ts", ""
            )
            _write(
                root
                / "supabase"
                / "functions"
                / "revenuecat-webhook"
                / "index.ts",
                "",
            )
            _write(
                root / "supabase" / "config.toml",
                """
[functions.send-push]
verify_jwt = true

[functions.revenuecat-webhook]
verify_jwt = false
""",
            )
            _write(
                root / ".github" / "workflows" / "deploy.yml",
                "supabase functions deploy revenuecat-webhook --project-ref X --no-verify-jwt",
            )

            with patch.object(vs, "ROOT", root):
                results = vs.check_edge_function_jwt_verification()

        self.assertTrue(all(passed for _, passed, _ in results), results)
        self.assertIn(
            (
                "edge function revenuecat-webhook verify_jwt",
                True,
                "explicit false (webhook receiver)",
            ),
            results,
        )
        self.assertIn(
            ("edge deploy no-verify-jwt", True, "not used"),
            results,
        )

    def test_rejects_webhook_without_explicit_false(self):
        """An exempt webhook missing verify_jwt = false must still fail."""
        import verify_security as vs

        with tempfile.TemporaryDirectory() as d:
            root = Path(d)
            _write(
                root
                / "supabase"
                / "functions"
                / "revenuecat-webhook"
                / "index.ts",
                "",
            )
            # config has the block but verify_jwt is missing
            _write(
                root / "supabase" / "config.toml",
                """
[functions.revenuecat-webhook]
""",
            )

            with patch.object(vs, "ROOT", root):
                results = vs.check_edge_function_jwt_verification()

        self.assertIn(
            (
                "edge function revenuecat-webhook verify_jwt",
                False,
                "webhook receiver must set verify_jwt = false; found missing",
            ),
            results,
        )

    def test_rejects_no_verify_jwt_for_non_exempt_function(self):
        """--no-verify-jwt on a non-exempt function name is still a fail."""
        import verify_security as vs

        with tempfile.TemporaryDirectory() as d:
            root = Path(d)
            _write(root / "supabase" / "functions" / "send-push" / "index.ts", "")
            _write(
                root / "supabase" / "config.toml",
                "[functions.send-push]\nverify_jwt = true\n",
            )
            _write(
                root / ".github" / "workflows" / "deploy.yml",
                "supabase functions deploy send-push --no-verify-jwt",
            )

            with patch.object(vs, "ROOT", root):
                results = vs.check_edge_function_jwt_verification()

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


class TestCertificatePinFreshness(unittest.TestCase):
    """A lapsed pin set takes every client offline, and the only fix is a store
    release — so this is enforced in CI rather than left to a calendar note."""

    PIN_SRC = "lib/core/security/certificate_pinning.dart"

    def _write_pinning(self, root, expiry: str):
        _write(
            root / self.PIN_SRC,
            "// Supabase leaf certificate, valid 2026-06-28 through "
            + expiry
            + "\n// (Google Trust Services CN=WE1).\n"
            "static void install() {}\n",
        )

    def test_passes_while_rotation_lead_time_remains(self):
        import verify_security as vs

        with tempfile.TemporaryDirectory() as d:
            root = Path(d)
            self._write_pinning(root, "2026-09-26")
            with patch.object(vs, "ROOT", root):
                results = vs.check_certificate_pin_freshness(today=date(2026, 7, 25))
            self.assertTrue(all(passed for _, passed, _ in results), results)

    def test_fails_inside_the_rotation_window(self):
        import verify_security as vs

        with tempfile.TemporaryDirectory() as d:
            root = Path(d)
            self._write_pinning(root, "2026-09-26")
            # 14 days out is the documented deadline, so it must already fail.
            with patch.object(vs, "ROOT", root):
                results = vs.check_certificate_pin_freshness(today=date(2026, 9, 12))
            self.assertFalse(any(passed for _, passed, _ in results), results)
            self.assertIn("expires in", results[0][2])

    def test_fails_loudly_once_a_pin_has_expired(self):
        import verify_security as vs

        with tempfile.TemporaryDirectory() as d:
            root = Path(d)
            self._write_pinning(root, "2026-09-26")
            with patch.object(vs, "ROOT", root):
                results = vs.check_certificate_pin_freshness(today=date(2026, 10, 1))
            self.assertFalse(any(passed for _, passed, _ in results), results)
            self.assertIn("EXPIRED", results[0][2])

    def test_fails_when_no_expiry_is_documented(self):
        import verify_security as vs

        with tempfile.TemporaryDirectory() as d:
            root = Path(d)
            _write(root / self.PIN_SRC, "static void install() {}\n")
            with patch.object(vs, "ROOT", root):
                results = vs.check_certificate_pin_freshness(today=date(2026, 7, 25))
            self.assertFalse(any(passed for _, passed, _ in results), results)

    def test_uses_the_earliest_expiry_when_pins_differ(self):
        import verify_security as vs

        with tempfile.TemporaryDirectory() as d:
            root = Path(d)
            _write(
                root / self.PIN_SRC,
                "// leaf A, valid 2026-06-28 through 2027-01-01\n"
                "// leaf B, valid 2026-06-28 through\n// 2026-09-26\n"
                "static void install() {}\n",
            )
            with patch.object(vs, "ROOT", root):
                results = vs.check_certificate_pin_freshness(today=date(2026, 9, 20))
            self.assertFalse(any(passed for _, passed, _ in results), results)


class TestChecksFailClosedOnMissingFiles(unittest.TestCase):
    """Bir kontrolun inceledigi dosya YOKKEN sessizce gecmesi en pahali hata
    bicimidir: dosya tasinir, kontrol hicbir sey bulamaz, `security-audit`
    yesil kalir.

    Ayrim kasitli. Bir dosyanin ICERIGINI iddia eden kontroller (release
    script'i, edge header'lari, JWT config, pin listesi, .gitignore, pgaudit,
    premium dogrulama, auth sertlestirme) dosya yoksa BASARISIZ olmali.
    Bir seyin YOKLUGUNU iddia eden kontrol (client'ta service-role anahtari)
    bos agacta hakli olarak gecer — sizacak kod yoktur.
    """

    CONTENT_CHECKS = (
        "check_release_obfuscation",
        "check_edge_function_security_headers",
        "check_edge_function_jwt_verification",
        "check_certificate_pinning",
        "check_gitignore_secrets",
        "check_no_secrets_committed",
        "check_pgaudit_migration",
        "check_premium_sync_server_verified",
        "check_supabase_auth_hardening",
    )
    ABSENCE_CHECKS = ("check_no_service_role_in_client",)

    def test_content_checks_fail_when_their_subject_is_missing(self):
        import verify_security as vs

        with tempfile.TemporaryDirectory() as d:
            with patch.object(vs, "ROOT", Path(d)):
                for name in self.CONTENT_CHECKS:
                    with self.subTest(check=name):
                        results = getattr(vs, name)()
                        self.assertTrue(results, f"{name} returned no results")
                        self.assertTrue(
                            any(not ok for _, ok, _ in results),
                            f"{name} passed with nothing to inspect",
                        )

    def test_absence_checks_pass_on_an_empty_tree(self):
        import verify_security as vs

        with tempfile.TemporaryDirectory() as d:
            with patch.object(vs, "ROOT", Path(d)):
                for name in self.ABSENCE_CHECKS:
                    with self.subTest(check=name):
                        results = getattr(vs, name)()
                        self.assertTrue(all(ok for _, ok, _ in results))
