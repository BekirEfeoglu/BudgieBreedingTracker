import json
import os
import re
import subprocess
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
CI_WORKFLOW = ROOT / ".github" / "workflows" / "ci.yml"
RELEASE_READY_WORKFLOW = ROOT / ".github" / "workflows" / "release-ready.yml"
RELEASE_SCRIPT = ROOT / "scripts" / "build_release.sh"
PUBSPEC = ROOT / "pubspec.yaml"
FVMRC = ROOT / ".fvmrc"
XCODE_POST_CLONE = ROOT / "ios" / "ci_scripts" / "ci_post_clone.sh"
LOCAL_QUALITY_GATE = ROOT / "scripts" / "run_local_quality_gate.sh"
BREEDING_EGG_REGRESSION = ROOT / "scripts" / "run_breeding_egg_regression.sh"


def _job_block(workflow: str, job_name: str) -> str:
    marker = f"  {job_name}:\n"
    start = workflow.index(marker)
    remainder = workflow[start + len(marker) :]
    next_job = re.search(r"(?m)^  [a-z0-9-]+:\n", remainder)
    end = len(workflow) if next_job is None else start + len(marker) + next_job.start()
    return workflow[start:end]


def _local_gate_scope(*paths: str) -> dict[str, int]:
    env = os.environ.copy()
    env["LOCAL_QUALITY_GATE_SCOPE_ONLY"] = "1"
    env["LOCAL_QUALITY_GATE_CHANGED_FILES"] = "\n".join(paths)
    result = subprocess.run(
        [str(LOCAL_QUALITY_GATE)],
        cwd=ROOT,
        env=env,
        check=True,
        capture_output=True,
        text=True,
    )
    return {
        key: int(value)
        for key, value in (
            line.split("=", maxsplit=1)
            for line in result.stdout.splitlines()
            if "=" in line
        )
    }


class TestCiWorkflowContract(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.workflow = CI_WORKFLOW.read_text(encoding="utf-8")
        cls.release_ready = RELEASE_READY_WORKFLOW.read_text(encoding="utf-8")
        cls.release_script = RELEASE_SCRIPT.read_text(encoding="utf-8")
        cls.pubspec = PUBSPEC.read_text(encoding="utf-8")
        cls.fvmrc = json.loads(FVMRC.read_text(encoding="utf-8"))
        cls.xcode_post_clone = XCODE_POST_CLONE.read_text(encoding="utf-8")
        cls.local_quality_gate = LOCAL_QUALITY_GATE.read_text(encoding="utf-8")
        cls.breeding_egg_regression = BREEDING_EGG_REGRESSION.read_text(
            encoding="utf-8"
        )

    def test_flutter_toolchain_uses_one_version_manifest(self):
        self.assertEqual("3.41.4", self.fvmrc["flutter"])
        self.assertEqual(
            6,
            self.workflow.count("flutter-version-file: .fvmrc"),
        )
        self.assertNotIn("flutter-version:", self.workflow)
        self.assertEqual(
            1,
            self.release_ready.count("flutter-version-file: .fvmrc"),
        )
        self.assertNotIn("flutter-version:", self.release_ready)
        self.assertIn('open(".fvmrc", encoding="utf-8")', self.xcode_post_clone)
        self.assertIn(
            'flutter-$PINNED_FLUTTER_VERSION',
            self.xcode_post_clone,
        )

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

    def test_local_gate_sees_untracked_files_and_routes_breeding_regressions(self):
        gate = self.local_quality_gate

        self.assertIn("git ls-files --others --exclude-standard", gate)
        self.assertIn("breeding_egg_paths=", gate)
        for lifecycle_path in (
            "lib/features/(breeding|eggs|chicks)/",
            "lib/domain/services/(breeding|eggs|incubation)/",
            "lib/domain/services/notifications/",
            "lib/domain/services/calendar/calendar_event_",
            "lib/data/.*(breeding_pair|incubation|clutch|egg|chick)",
            "test/features/(breeding|eggs|chicks)/",
            ".claude/rules/breeding-eggs\\.md",
        ):
            self.assertIn(lifecycle_path, gate)
        self.assertIn("scripts/run_breeding_egg_regression.sh", gate)

    def test_local_gate_executes_real_scheduler_and_calendar_scope_router(self):
        for path in (
            "lib/domain/services/notifications/notification_scheduler.dart",
            "lib/domain/services/notifications/notification_rescheduler.dart",
            "lib/domain/services/notifications/notification_settings_providers.dart",
            "lib/domain/services/calendar/calendar_event_generator.dart",
            "test/domain/services/calendar/calendar_event_providers_test.dart",
        ):
            with self.subTest(path=path):
                scope = _local_gate_scope(path)
                self.assertEqual(1, scope["breeding-regression"])

        self.assertEqual(
            0,
            _local_gate_scope("docs/index.html")["breeding-regression"],
        )

    def test_breeding_regression_covers_persistence_scheduler_and_calendar(self):
        regression = self.breeding_egg_regression
        required_tests = (
            "test/data/repositories/breeding_creation_persistence_test.dart",
            "test/features/breeding/providers/breeding_form_providers_test.dart",
            "test/features/breeding/providers/breeding_form_actions_test.dart",
            "test/features/eggs/providers/egg_actions_notifier_test.dart",
            "test/domain/services/notifications/notification_ids_test.dart",
            "test/domain/services/notifications/notification_scheduler_test.dart",
            "test/domain/services/notifications/notification_scheduler_cancel_test.dart",
            "test/domain/services/notifications/notification_scheduler_reminders_test.dart",
            "test/domain/services/notifications/notification_rescheduler_test.dart",
            "test/domain/services/notifications/notification_toggle_settings_test.dart",
            "test/domain/services/calendar/calendar_event_generator_test.dart",
            "test/domain/services/calendar/calendar_event_providers_test.dart",
        )
        for test_file in required_tests:
            self.assertEqual(1, regression.count(test_file), test_file)
        self.assertIn("skipped or excluded test detected", regression)

    def test_golden_job_targets_directory_without_global_tag_discovery(self):
        golden = _job_block(self.workflow, "golden-test")

        self.assertEqual(2, golden.count("flutter test --no-pub test/golden"))
        self.assertNotIn("--tags golden", golden)
        self.assertEqual(1, golden.count("--update-goldens"))

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
            "--sentry-define=symbols_path=build/symbols/android",
            release,
        )
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
        self.assertEqual(1, script.count("dart run sentry_dart_plugin"))
        self.assertIn(
            '"--sentry-define=symbols_path=$symbols_path"',
            script,
        )
        self.assertIn("upload_sentry_symbols ios", script)
        self.assertIn("upload_sentry_symbols android", script)
        self.assertIn("build/release-artifacts", script)
        self.assertIn("build/app/outputs", script)
        self.assertIn("build/ios", script)
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
        self.assertIn("symbols_path: build/symbols/android", self.pubspec)
        self.assertIn("commits: false", self.pubspec)


if __name__ == "__main__":
    unittest.main()
