#!/usr/bin/env python3
"""
verify_code_quality.main() entegrasyon testleri.

Bu dosya test_code_quality.py'den ayrilmistir: main() integration + verbose
dallari ve script entrypoint testi burada, bireysel checker unit testleri
test_code_quality.py'de kalir.

Calistirma:
  python scripts/test_code_quality_main.py
  python -m pytest scripts/test_code_quality_main.py -v
"""

import runpy
import sys
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

SCRIPTS_DIR = Path(__file__).resolve().parent
sys.path.insert(0, str(SCRIPTS_DIR))


# ── main() entegrasyon testleri ───────────────────────────────────────────────


class TestVerifyCodeQualityMain(unittest.TestCase):
    """verify_code_quality.main() icin entegrasyon testleri."""

    def _make_lib(self, tmpdir: Path) -> Path:
        lib = tmpdir / "lib"
        lib.mkdir(parents=True)
        return lib

    def test_exits_with_1_when_lib_dir_missing(self):
        """LIB_DIR mevcut degilse sys.exit(1) calisir (satirlar 169-170)."""
        import verify_code_quality as vcq

        with patch.object(vcq, "LIB_DIR", Path("/nonexistent/lib/dir")), \
             patch.object(vcq, "CLAUDE_MD", Path("/nonexistent_claude.md")):
            with self.assertRaises(SystemExit) as ctx:
                vcq.main()
        self.assertEqual(ctx.exception.code, 1)

    def test_returns_0_when_no_issues(self):
        import verify_code_quality as vcq

        with tempfile.TemporaryDirectory() as d:
            lib = self._make_lib(Path(d))
            (lib / "clean_widget.dart").write_text(
                "class CleanWidget extends StatelessWidget {}\n", encoding="utf-8"
            )
            with patch.object(vcq, "LIB_DIR", lib), patch.object(
                vcq, "CLAUDE_MD", Path("/nonexistent_claude.md")
            ):
                result = vcq.main()
        self.assertEqual(result, 0)

    def test_returns_0_when_no_dart_files(self):
        import verify_code_quality as vcq

        with tempfile.TemporaryDirectory() as d:
            lib = self._make_lib(Path(d))
            with patch.object(vcq, "LIB_DIR", lib), patch.object(
                vcq, "CLAUDE_MD", Path("/nonexistent_claude.md")
            ):
                result = vcq.main()
        self.assertEqual(result, 0)

    def test_returns_1_when_print_detected(self):
        import verify_code_quality as vcq

        with tempfile.TemporaryDirectory() as d:
            lib = self._make_lib(Path(d))
            (lib / "bad.dart").write_text(
                "void fn() {\n  print('debug');\n}\n", encoding="utf-8"
            )
            with patch.object(vcq, "LIB_DIR", lib), patch.object(
                vcq, "CLAUDE_MD", Path("/nonexistent_claude.md")
            ):
                result = vcq.main()
        self.assertEqual(result, 1)

    def test_returns_1_when_with_opacity_detected(self):
        import verify_code_quality as vcq

        with tempfile.TemporaryDirectory() as d:
            lib = self._make_lib(Path(d))
            (lib / "widget.dart").write_text(
                "  color: color.withOpacity(0.5),\n", encoding="utf-8"
            )
            with patch.object(vcq, "LIB_DIR", lib), patch.object(
                vcq, "CLAUDE_MD", Path("/nonexistent_claude.md")
            ):
                result = vcq.main()
        self.assertEqual(result, 1)

    def test_skips_generated_files_in_lib_dir(self):
        """LIB_DIR'deki .g.dart ve .freezed.dart dosyalari atlaniyor (satir 179)."""
        import verify_code_quality as vcq

        with tempfile.TemporaryDirectory() as d:
            lib = self._make_lib(Path(d))
            # Non-.dart dosya: satir 179'u tetikler (continue)
            (lib / "README.md").write_text("# notes", encoding="utf-8")
            # Generated dosya: anti-pattern icerebilir ama sayilmamali (satir 181)
            (lib / "bird_model.g.dart").write_text(
                "void fn() {\n  print('generated debug');\n}\n", encoding="utf-8"
            )
            (lib / "bird_model.freezed.dart").write_text(
                "  color: color.withOpacity(0.5),\n", encoding="utf-8"
            )
            with patch.object(vcq, "LIB_DIR", lib), patch.object(
                vcq, "CLAUDE_MD", Path("/nonexistent_claude.md")
            ):
                result = vcq.main()
        # Non-.dart ve generated dosyalar atlaniyor → no findings → 0
        self.assertEqual(result, 0)

    def test_returns_0_when_all_warnings_no_errors(self):
        import verify_code_quality as vcq

        # Controller without dispose -> warning, not error
        with tempfile.TemporaryDirectory() as d:
            lib = self._make_lib(Path(d))
            (lib / "form.dart").write_text(
                "class _FormState extends ConsumerStatefulWidget {}\n"
                "  final TextEditingController _ctrl = TextEditingController();\n",
                encoding="utf-8",
            )
            with patch.object(vcq, "LIB_DIR", lib), patch.object(
                vcq, "CLAUDE_MD", Path("/nonexistent_claude.md")
            ):
                result = vcq.main()
        self.assertEqual(result, 0)  # warnings only → exit 0


# ── main() kalan branch'ler ───────────────────────────────────────────────────


class TestVerifyCodeQualityMainBranches(unittest.TestCase):
    """main() icerisindeki kalan branch'leri kapsayan entegrasyon testleri."""

    def test_prints_pattern_count_when_claude_md_has_patterns(self):
        """total_patterns > 0 branch'ini calistiriyor (satirlar 839-840)."""
        import io
        import verify_code_quality as vcq

        claude_content = (
            "# CLAUDE.md\n\n"
            "## Critical Anti-Patterns\n\n"
            "1. `withOpacity()` -> use `withValues(alpha: x)`\n"
            "2. `print()` -> use `AppLogger`\n\n"
            "## Other Section\n"
        )
        with tempfile.TemporaryDirectory() as d:
            lib = Path(d) / "lib"
            lib.mkdir()
            claude_md = Path(d) / "CLAUDE.md"
            claude_md.write_text(claude_content, encoding="utf-8")
            with patch.object(vcq, "LIB_DIR", lib), patch.object(
                vcq, "CLAUDE_MD", claude_md
            ):
                captured = io.StringIO()
                import sys as _sys
                old_stdout = _sys.stdout
                _sys.stdout = captured
                try:
                    result = vcq.main()
                finally:
                    _sys.stdout = old_stdout
        output = captured.getvalue()
        self.assertIn("anti-pattern", output)
        self.assertEqual(result, 0)

    def test_handles_unreadable_dart_file_gracefully(self):
        """Okunamayan dart dosyasi except blogu ile atlaniyor (satirlar 903-905)."""
        import verify_code_quality as vcq

        with tempfile.TemporaryDirectory() as d:
            lib = Path(d) / "lib"
            lib.mkdir()
            bad = lib / "bad.dart"
            bad.touch()

            original_open = open

            def _mock_open(file, *args, **kwargs):
                if Path(file) == bad:
                    raise OSError("permission denied")
                return original_open(file, *args, **kwargs)

            with patch.object(vcq, "LIB_DIR", lib), patch.object(
                vcq, "CLAUDE_MD", Path("/nonexistent_claude.md")
            ), patch("builtins.open", side_effect=_mock_open):
                result = vcq.main()
        self.assertEqual(result, 0)


# ── main() VERBOSE=True dallari ───────────────────────────────────────────────


class TestVerifyCodeQualityMainVerbose(unittest.TestCase):
    """VERBOSE=True ile calistirilan main() dallari (satirlar 929-933, 938, 964-969)."""

    def _run_verbose(self, dart_content: str, claude_content: str = "") -> tuple:
        """VERBOSE=True ile main() calistir, (result, output) dondur."""
        import io
        import sys as _sys
        import verify_code_quality as vcq

        with tempfile.TemporaryDirectory() as d:
            lib = Path(d) / "lib"
            lib.mkdir()
            (lib / "widget.dart").write_text(dart_content, encoding="utf-8")

            claude_md = Path(d) / "CLAUDE.md"
            claude_md.write_text(claude_content, encoding="utf-8")

            captured = io.StringIO()
            old_stdout = _sys.stdout
            old_verbose = vcq.VERBOSE
            _sys.stdout = captured
            try:
                with patch.object(vcq, "LIB_DIR", lib), \
                     patch.object(vcq, "CLAUDE_MD", claude_md), \
                     patch.object(vcq, "VERBOSE", True):
                    result = vcq.main()
            finally:
                _sys.stdout = old_stdout
                vcq.VERBOSE = old_verbose
        return result, captured.getvalue()

    def test_verbose_shows_finding_details(self):
        """VERBOSE=True → her finding icin dosya:satir + metin + oneri basilir (929-933)."""
        result, output = self._run_verbose("void fn() {\n  print('debug');\n}\n")
        # VERBOSE modunda tam detay cikisi olmali
        self.assertEqual(result, 1)
        self.assertIn("->", output)

    def test_verbose_truncation_line_for_more_than_3(self):
        """4+ finding varsa '... ve N sorun daha' satiri basilir (satir 938)."""
        # 4 ayri print() satiri → count=4 > 3 → truncation mesaji
        dart = "".join(f"void fn{i}() {{ print('x'); }}\n" for i in range(4))
        result, output = self._run_verbose(dart)
        self.assertEqual(result, 1)
        # VERBOSE=False oldugunda truncation olur, True'da olmaz — VERBOSE=False ile test
        import io
        import sys as _sys
        import verify_code_quality as vcq

        with tempfile.TemporaryDirectory() as d:
            lib = Path(d) / "lib"
            lib.mkdir()
            (lib / "widget.dart").write_text(dart, encoding="utf-8")
            captured = io.StringIO()
            old = _sys.stdout
            _sys.stdout = captured
            try:
                with patch.object(vcq, "LIB_DIR", lib), \
                     patch.object(vcq, "CLAUDE_MD", Path("/nonexistent_claude.md")), \
                     patch.object(vcq, "VERBOSE", False):
                    vcq.main()
            finally:
                _sys.stdout = old
        self.assertIn("sorun daha", captured.getvalue())

    def test_verbose_coverage_report_with_uncovered_patterns(self):
        """VERBOSE=True + total_patterns > 0 + kapsanmayan pattern → rapor basilir (964-969).

        ANTI_PATTERN_COVERAGE {} yapilarak tum pattern'ler 'kapsanmamis' gorulur,
        bu sayede uncovered listesi dolar ve satirlar 965-969 calisir.
        """
        import verify_code_quality as vcq

        claude_content = (
            "# CLAUDE.md\n\n"
            "## Critical Anti-Patterns\n\n"
            "1. `withOpacity()` -> use `withValues(alpha: x)`\n"
            "2. `print()` -> use `AppLogger`\n\n"
            "## Other Section\n"
        )
        import io
        import sys as _sys

        with tempfile.TemporaryDirectory() as d:
            lib = Path(d) / "lib"
            lib.mkdir()
            (lib / "widget.dart").write_text(
                "class CleanWidget extends StatelessWidget {}\n", encoding="utf-8"
            )
            claude_md = Path(d) / "CLAUDE.md"
            claude_md.write_text(claude_content, encoding="utf-8")

            captured = io.StringIO()
            old = _sys.stdout
            _sys.stdout = captured
            try:
                with patch.object(vcq, "LIB_DIR", lib), \
                     patch.object(vcq, "CLAUDE_MD", claude_md), \
                     patch.object(vcq, "VERBOSE", True), \
                     patch.object(vcq, "ANTI_PATTERN_COVERAGE", {}):
                    vcq.main()
            finally:
                _sys.stdout = old

        output = captured.getvalue()
        # satirlar 966-969: "--- Otomatik Kapsam Disi Anti-Pattern'ler ---" basilmali
        self.assertIn("Kapsam Disi", output)


# ── Script entrypoint (satir 976) ─────────────────────────────────────────────


class TestVerifyCodeQualityEntrypoint(unittest.TestCase):
    """if __name__ == '__main__': sys.exit(main()) dalini in-process ile kapsar (satir 976)."""

    def test_script_runs_as_main(self):
        """Script __main__ olarak calistirildiginda sys.exit cagrilir (coverage tracked)."""
        script = str(SCRIPTS_DIR / "verify_code_quality.py")
        with patch.object(sys, "exit"):
            runpy.run_path(script, run_name="__main__")


# ── Runner ────────────────────────────────────────────────────────────────────


if __name__ == "__main__":
    unittest.main(verbosity=2)
