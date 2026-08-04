import subprocess
import tempfile
import unittest
from pathlib import Path
from typing import Optional


ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / "scripts" / "generate_ios_env.sh"


class GenerateIosEnvTest(unittest.TestCase):
    def run_generator(self, env_contents: Optional[str]) -> str:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            (root / "scripts").mkdir()
            (root / "ios" / "Flutter").mkdir(parents=True)
            (root / "scripts" / SCRIPT.name).write_text(
                SCRIPT.read_text(encoding="utf-8"),
                encoding="utf-8",
            )
            if env_contents is not None:
                (root / ".env").write_text(env_contents, encoding="utf-8")

            subprocess.run(
                ["bash", f"scripts/{SCRIPT.name}"],
                cwd=root,
                check=True,
                capture_output=True,
                text=True,
            )
            return (root / "ios" / "Flutter" / "Env.xcconfig").read_text(
                encoding="utf-8"
            )

    def test_escapes_double_slash_for_xcconfig_urls(self) -> None:
        output = self.run_generator(
            "SUPABASE_URL=https://project.supabase.co\n"
            "SUPABASE_PUBLISHABLE_KEY=sb_publishable_example\n"
            "SENTRY_DSN=https://public@example.ingest.sentry.io/1\n"
        )

        self.assertIn("BBT_EMPTY=", output)
        self.assertIn(
            "SUPABASE_URL=https:/$(BBT_EMPTY)/project.supabase.co", output
        )
        self.assertIn(
            "SENTRY_DSN=https:/$(BBT_EMPTY)/public@example.ingest.sentry.io/1",
            output,
        )
        self.assertNotIn("SUPABASE_URL=https://", output)

    def test_promotes_legacy_anon_key_to_publishable_key(self) -> None:
        output = self.run_generator(
            "SUPABASE_URL=https://project.supabase.co\n"
            "SUPABASE_ANON_KEY=legacy_client_key\n"
        )

        self.assertIn("SUPABASE_PUBLISHABLE_KEY=legacy_client_key", output)
        self.assertIn("SUPABASE_ANON_KEY=legacy_client_key", output)

    def test_missing_env_writes_safe_fallback_comment(self) -> None:
        output = self.run_generator(None)

        self.assertIn("No .env file found", output)
        self.assertNotIn("SUPABASE_URL=", output)


if __name__ == "__main__":
    unittest.main()
