import re
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
CI_WORKFLOW = ROOT / ".github" / "workflows" / "ci.yml"
RELEASE_READY_WORKFLOW = ROOT / ".github" / "workflows" / "release-ready.yml"
RELEASE_SCRIPT = ROOT / "scripts" / "build_release.sh"
PUBSPEC = ROOT / "pubspec.yaml"


def _job_block(workflow: str, job_name: str) -> str:
    marker = f"  {job_name}:\n"
    start = workflow.index(marker)
    remainder = workflow[start + len(marker) :]
    next_job = re.search(r"(?m)^  [a-z0-9-]+:\n", remainder)
    end = len(workflow) if next_job is None else start + len(marker) + next_job.start()
    return workflow[start:end]


class TestCiWorkflowContract(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.workflow = CI_WORKFLOW.read_text(encoding="utf-8")
        cls.release_ready = RELEASE_READY_WORKFLOW.read_text(encoding="utf-8")
        cls.release_script = RELEASE_SCRIPT.read_text(encoding="utf-8")
        cls.pubspec = PUBSPEC.read_text(encoding="utf-8")

    def test_edge_change_detector_ignores_documentation_only_pushes(self):
        detector = _job_block(self.workflow, "edge-function-changes")

        self.assertIn("supabase/functions/", detector)
        self.assertIn("supabase/config.toml", detector)
        self.assertIn(".github/workflows/ci.yml", detector)
        self.assertNotIn("docs/", detector)
        self.assertIn('echo "should-deploy=false"', detector)

    def test_edge_deploy_requires_positive_change_detector_output(self):
        deploy = _job_block(self.workflow, "deploy-edge-functions")

        self.assertIn("edge-function-changes", deploy)
        self.assertIn(
            "needs.edge-function-changes.outputs.should-deploy == 'true'",
            deploy,
        )
        self.assertIn("edge-functions-test", deploy)

    def test_release_ready_requires_and_injects_sentry_dsn(self):
        release = _job_block(self.release_ready, "android-release")

        self.assertIn("SENTRY_DSN: ${{ secrets.SENTRY_DSN }}", release)
        self.assertIn(
            "SENTRY_AUTH_TOKEN: ${{ secrets.SENTRY_AUTH_TOKEN }}",
            release,
        )
        self.assertIn('if [ -z "$SENTRY_DSN" ]', release)
        self.assertIn('if [ -z "$SENTRY_AUTH_TOKEN" ]', release)
        self.assertIn('--dart-define=SENTRY_DSN="$SENTRY_DSN"', release)
        self.assertIn("--dart-define=SENTRY_ENVIRONMENT=production", release)
        self.assertIn("--save-obfuscation-map=build/app/obfuscation.map.json", release)
        self.assertIn("dart run sentry_dart_plugin", release)
        self.assertIn(
            "com.budgiebreeding.budgie_breeding_tracker@${APP_VERSION}",
            release,
        )
        self.assertIn('SENTRY_DIST="${APP_VERSION##*+}"', release)

    def test_release_script_refuses_to_build_without_sentry_credentials(self):
        """Codemagic used to fail fast on a missing DSN/auth token.

        It was removed 2026-07-25 and scripts/build_release.sh inherited that
        contract. Both values are silent failures if unchecked: no DSN ships a
        release with no crash reporting, and no auth token ships obfuscated
        stack traces nobody can read.
        """
        script = self.release_script

        self.assertIn("SENTRY_DSN", script)
        self.assertIn("SENTRY_AUTH_TOKEN", script)
        self.assertIn("set -euo pipefail", script)
        self.assertIn("release build refused, missing:", script)
        self.assertIn("exit 1", script)

    def test_release_script_obfuscates_and_uploads_symbols_on_both_platforms(self):
        script = self.release_script

        # Count the actual flag line, not the prose in the header comment.
        self.assertEqual(2, script.count("\n    --obfuscate \\"))
        self.assertIn("--split-debug-info=build/symbols/ios", script)
        self.assertIn("--split-debug-info=build/symbols/android", script)
        self.assertEqual(
            2,
            script.count("--save-obfuscation-map=build/app/obfuscation.map.json"),
        )
        self.assertEqual(2, script.count("dart run sentry_dart_plugin"))
        # SENTRY_RELEASE must match runtime PackageInfo naming, per platform.
        self.assertIn(
            'SENTRY_RELEASE="com.budgiebreeding.tracker@${APP_VERSION}',
            script,
        )
        self.assertIn(
            'SENTRY_RELEASE="com.budgiebreeding.budgie_breeding_tracker@${APP_VERSION}',
            script,
        )
        self.assertIn('SENTRY_DIST="$BUILD_NUMBER"', script)

    def test_release_script_uses_env_file_rather_than_default_dart_defines(self):
        """A raw Xcode Archive reads a stale gitignored DartDefines.xcconfig.

        Going through `flutter build ... --dart-define-from-file` is what
        rewrites that file, so the script must never be reduced to a plain
        build invocation.
        """
        script = self.release_script

        self.assertEqual(2, script.count('--dart-define-from-file="$ENV_FILE"'))
        self.assertIn("generate_ios_env.sh", script)
        self.assertIn("DartDefines.xcconfig", script)

    def test_no_codemagic_configuration_remains(self):
        """Codemagic was removed; a stray config would resurrect a dead path."""
        self.assertFalse((ROOT / "codemagic.yaml").exists())

    def test_sentry_dart_plugin_keeps_source_upload_disabled(self):
        self.assertIn("sentry_dart_plugin: ^3.4.0", self.pubspec)
        self.assertIn("org: budgiebreedingtracker", self.pubspec)
        self.assertIn("project: budgie-breeding-tracker", self.pubspec)
        self.assertIn("upload_debug_symbols: true", self.pubspec)
        self.assertIn("upload_source_maps: false", self.pubspec)
        self.assertIn("upload_sources: false", self.pubspec)
        self.assertIn(
            "dart_symbol_map_path: build/app/obfuscation.map.json",
            self.pubspec,
        )
        self.assertIn("commits: false", self.pubspec)


if __name__ == "__main__":
    unittest.main()
