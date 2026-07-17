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
        self.assertEqual(2, self.codemagic.count('if [ -z "$SENTRY_DSN" ]'))
        self.assertEqual(
            2,
            self.codemagic.count('if [ -z "$SENTRY_AUTH_TOKEN" ]'),
        )
        self.assertEqual(
            2,
            self.codemagic.count('--dart-define=SENTRY_DSN="$SENTRY_DSN"'),
        )
        self.assertEqual(2, self.codemagic.count("dart run sentry_dart_plugin"))
        self.assertEqual(
            2,
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
