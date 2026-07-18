import re
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
CI_WORKFLOW = ROOT / ".github" / "workflows" / "ci.yml"
RELEASE_READY_WORKFLOW = ROOT / ".github" / "workflows" / "release-ready.yml"
CODEMAGIC_CONFIG = ROOT / "codemagic.yaml"
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
        cls.codemagic = CODEMAGIC_CONFIG.read_text(encoding="utf-8")
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

    def test_codemagic_releases_fail_fast_without_sentry_dsn(self):
        verify_only = _job_block(self.codemagic, "android-verify-only")

        self.assertEqual(2, self.codemagic.count('if [ -z "$SENTRY_DSN" ]'))
        self.assertIn(
            "for VAR_NAME in SUPABASE_URL SUPABASE_ANON_KEY SENTRY_DSN "
            "SENTRY_AUTH_TOKEN REVENUECAT_API_KEY_ANDROID",
            verify_only,
        )
        self.assertEqual(
            2,
            self.codemagic.count('if [ -z "$SENTRY_AUTH_TOKEN" ]'),
        )
        self.assertEqual(
            3,
            self.codemagic.count('--dart-define=SENTRY_DSN="$SENTRY_DSN"'),
        )
        self.assertEqual(3, self.codemagic.count("dart run sentry_dart_plugin"))
        self.assertEqual(
            3,
            self.codemagic.count(
                "--save-obfuscation-map=build/app/obfuscation.map.json"
            ),
        )
        self.assertIn(
            "com.budgiebreeding.budgie_breeding_tracker@${APP_VERSION}+${ANDROID_BUILD_NUMBER}",
            self.codemagic,
        )
        self.assertIn(
            "com.budgiebreeding.tracker@${APP_VERSION}+${IOS_BUILD_NUMBER}",
            self.codemagic,
        )
        self.assertIn('export SENTRY_DIST="$ANDROID_BUILD_NUMBER"', self.codemagic)
        self.assertIn('export SENTRY_DIST="$IOS_BUILD_NUMBER"', self.codemagic)
        self.assertNotIn("${SENTRY_DSN:-}", self.codemagic)

    def test_codemagic_android_verify_only_cannot_publish_to_store(self):
        verify_only = _job_block(self.codemagic, "android-verify-only")

        self.assertIn(
            "name: Android Verify Only (No Store Publishing)",
            verify_only,
        )
        self.assertNotIn("publishing:", verify_only)
        self.assertNotIn("google_play", verify_only)
        self.assertNotIn("google-play", verify_only)
        self.assertNotIn("GOOGLE_PLAY_SERVICE_ACCOUNT_CREDENTIALS", verify_only)
        self.assertIn(
            "VERSION_LINE=\"$(sed -n 's/^version: //p' pubspec.yaml | head -1)\"",
            verify_only,
        )
        self.assertIn("ANDROID_BUILD_NUMBER=\"${VERSION_LINE##*+}\"", verify_only)
        self.assertIn("''|*[!0-9]*)", verify_only)
        self.assertIn(
            'echo "ANDROID_BUILD_NUMBER=$ANDROID_BUILD_NUMBER" >> "$CM_ENV"',
            verify_only,
        )
        self.assertIn("--build-name=\"$APP_VERSION\"", verify_only)
        self.assertIn("--build-number=\"$ANDROID_BUILD_NUMBER\"", verify_only)
        self.assertIn("--obfuscate", verify_only)
        self.assertIn("--split-debug-info=build/symbols/android", verify_only)
        self.assertIn("dart run sentry_dart_plugin", verify_only)
        self.assertIn("build/**/outputs/**/*.aab", verify_only)
        self.assertIn("build/symbols/android/**", verify_only)

    def test_codemagic_android_release_uses_package_wide_build_number(self):
        release = _job_block(self.codemagic, "android-release")
        resolver_start = release.index("- name: Resolve Android build number")
        resolver_end = release.index("- name: Build Android App Bundle")
        resolver = release[resolver_start:resolver_end]

        self.assertIn("google-play get-latest-build-number", resolver)
        self.assertIn('--package-name "$GOOGLE_PLAY_PACKAGE_NAME"', resolver)
        self.assertNotIn("--tracks=", resolver)
        self.assertIn("ANDROID_BUILD_NUMBER=$((LATEST_BUILD_NUMBER + 1))", resolver)
        self.assertIn("track: $GOOGLE_PLAY_TRACK", release)

    def test_codemagic_release_builders_pin_the_verified_flutter_sdk(self):
        expected_version = "3.41.4"

        self.assertNotIn("flutter: stable", self.codemagic)
        self.assertEqual(
            3,
            self.codemagic.count(f"flutter: {expected_version}"),
        )
        self.assertIn(
            f"flutter-version: {expected_version}",
            self.release_ready,
        )
        self.assertIn(
            f"flutter-version: {expected_version}",
            self.workflow,
        )

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
