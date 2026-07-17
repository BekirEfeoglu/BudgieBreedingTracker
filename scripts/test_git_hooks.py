import os
import stat
import subprocess
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
PRE_COMMIT_HOOK = ROOT / ".githooks" / "pre-commit"
HOOK_INSTALLER = ROOT / "scripts" / "install_git_hooks.sh"


class TestGitHooks(unittest.TestCase):
    def test_pre_commit_removes_repo_git_environment_before_flutter(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            repository = Path(temp_dir)
            self._run(["git", "init", "--quiet"], cwd=repository)

            dart_file = repository / "example.dart"
            dart_file.write_text("void main() {}\n", encoding="utf-8")
            self._run(["git", "add", dart_file.name], cwd=repository)

            fake_bin = repository / "fake-bin"
            fake_bin.mkdir()
            fake_flutter = fake_bin / "flutter"
            fake_flutter.write_text(
                "#!/usr/bin/env bash\n"
                "set -euo pipefail\n"
                "if [[ -n \"${GIT_DIR:-}\" || -n \"${GIT_WORK_TREE:-}\" "
                "|| -n \"${GIT_INDEX_FILE:-}\" ]]; then\n"
                "  echo \"repository Git environment leaked into Flutter\" >&2\n"
                "  exit 97\n"
                "fi\n"
                "case \"${1:-}\" in\n"
                "  --version) echo \"Flutter test-sdk\" ;;\n"
                "  analyze) exit 0 ;;\n"
                "  *) exit 98 ;;\n"
                "esac\n",
                encoding="utf-8",
            )
            fake_flutter.chmod(
                fake_flutter.stat().st_mode | stat.S_IXUSR | stat.S_IXGRP | stat.S_IXOTH
            )

            environment = os.environ.copy()
            environment.update(
                {
                    "PATH": f"{fake_bin}{os.pathsep}{environment['PATH']}",
                    "GIT_DIR": str(repository / ".git"),
                    "GIT_WORK_TREE": str(repository),
                    "GIT_INDEX_FILE": str(repository / ".git" / "index"),
                }
            )

            result = subprocess.run(
                [str(PRE_COMMIT_HOOK)],
                cwd=repository,
                env=environment,
                check=False,
                capture_output=True,
                text=True,
            )

            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            self.assertIn("Flutter analyze basarili", result.stdout)

    def test_installer_uses_worktree_relative_tracked_hooks(self):
        installer = HOOK_INSTALLER.read_text(encoding="utf-8")

        self.assertIn("git config core.hooksPath .githooks", installer)
        self.assertIn(".githooks/pre-commit", installer)
        self.assertIn(".githooks/pre-push", installer)

    @staticmethod
    def _run(command, *, cwd):
        environment = os.environ.copy()
        local_git_variables = subprocess.run(
            ["git", "rev-parse", "--local-env-vars"],
            cwd=ROOT,
            check=True,
            capture_output=True,
            text=True,
        ).stdout.splitlines()
        for variable in local_git_variables:
            environment.pop(variable, None)

        subprocess.run(
            command,
            cwd=cwd,
            env=environment,
            check=True,
            capture_output=True,
            text=True,
        )


if __name__ == "__main__":
    unittest.main()
