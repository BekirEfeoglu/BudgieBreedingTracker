#!/usr/bin/env python3
"""Unit tests for verify_security.py."""

import sys
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

SCRIPTS_DIR = Path(__file__).resolve().parent
sys.path.insert(0, str(SCRIPTS_DIR))


class TestReleaseObfuscation(unittest.TestCase):
    def test_accepts_android_release_in_release_ready_workflow(self):
        import verify_security as vs

        with tempfile.TemporaryDirectory() as d:
            root = Path(d)
            (root / ".github" / "workflows").mkdir(parents=True)
            (root / "codemagic.yaml").write_text(
                """
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
""",
                encoding="utf-8",
            )
            (root / ".github" / "workflows" / "ci.yml").write_text(
                "name: CI\njobs:\n  android-build:\n    steps: []\n",
                encoding="utf-8",
            )
            (root / ".github" / "workflows" / "release-ready.yml").write_text(
                """
name: Release Ready
jobs:
  android-release:
    steps:
      - name: Build Android App Bundle (release)
        run: |
          flutter build appbundle --release \\
            --obfuscate \\
            --split-debug-info=build/symbols/android
""",
                encoding="utf-8",
            )

            with patch.object(vs, "ROOT", root):
                results = vs.check_release_obfuscation()

        self.assertTrue(all(passed for _, passed, _ in results), results)
        self.assertIn(
            ("release-ready.yml android-release", True, "obfuscation enabled"),
            results,
        )


if __name__ == "__main__":
    unittest.main()
