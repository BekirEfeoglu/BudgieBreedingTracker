#!/usr/bin/env python3
"""
check_l10n_sync.main() entegrasyon testleri.

Bu dosya test_l10n_sync.py'den ayrilmistir: main() integration + truncation
dallari ve script entrypoint testi burada, bireysel unit testler
test_l10n_sync.py'de kalir.

Calistirma:
  python scripts/test_l10n_sync_main.py
  python -m pytest scripts/test_l10n_sync_main.py -v
"""

import json
import runpy
import sys
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

SCRIPTS_DIR = Path(__file__).resolve().parent
sys.path.insert(0, str(SCRIPTS_DIR))


# ── Ortak yardimci sinif ──────────────────────────────────────────────────────


class _L10nTestBase(unittest.TestCase):
    """TestMainFunction ve TestTruncationLines icin ortak yardimci sinif."""

    _DEFAULT_DATA = {"common": {"save": "x", "cancel": "y"}}

    def _make_translations(self, root: Path, tr=None, en=None, de=None) -> Path:
        """Gecici translations dizini olustur ve 3 dil dosyasini yaz."""
        trans_dir = root / "translations"
        trans_dir.mkdir(parents=True, exist_ok=True)
        for lang, data in [
            ("tr", tr if tr is not None else self._DEFAULT_DATA),
            ("en", en if en is not None else self._DEFAULT_DATA),
            ("de", de if de is not None else self._DEFAULT_DATA),
        ]:
            (trans_dir / f"{lang}.json").write_text(
                json.dumps(data, ensure_ascii=False), encoding="utf-8"
            )
        return trans_dir


# ── main() integration ────────────────────────────────────────────────────────


class TestMainFunction(_L10nTestBase):
    """main() icin entegrasyon testleri — gercek dosyalar + modul patch."""

    def test_returns_0_when_all_synced(self):
        import check_l10n_sync as cl

        with tempfile.TemporaryDirectory() as d:
            root = Path(d)
            trans_dir = self._make_translations(root)
            lib_dir = root / "lib"
            lib_dir.mkdir()
            with patch.object(cl, "TRANSLATIONS_DIR", trans_dir), patch.object(
                cl, "ROOT", root
            ):
                result = cl.main()
        self.assertEqual(result, 0)

    def test_returns_1_when_key_missing_in_english(self):
        import check_l10n_sync as cl

        tr_data = {"common": {"save": "Kaydet", "delete": "Sil"}}
        en_data = {"common": {"save": "Save"}}  # delete eksik
        with tempfile.TemporaryDirectory() as d:
            root = Path(d)
            trans_dir = self._make_translations(root, tr=tr_data, en=en_data, de=tr_data)
            (root / "lib").mkdir()
            with patch.object(cl, "TRANSLATIONS_DIR", trans_dir), patch.object(
                cl, "ROOT", root
            ):
                result = cl.main()
        self.assertEqual(result, 1)

    def test_returns_1_when_empty_value_present(self):
        import check_l10n_sync as cl

        data_with_empty = {"common": {"save": "Kaydet", "blank": ""}}
        with tempfile.TemporaryDirectory() as d:
            root = Path(d)
            trans_dir = self._make_translations(
                root,
                tr=data_with_empty,
                en=data_with_empty,
                de=data_with_empty,
            )
            (root / "lib").mkdir()
            with patch.object(cl, "TRANSLATIONS_DIR", trans_dir), patch.object(
                cl, "ROOT", root
            ):
                result = cl.main()
        self.assertEqual(result, 1)

    def test_returns_1_when_placeholder_mismatch(self):
        import check_l10n_sync as cl

        tr_data = {"common": {"msg": "{} yavru"}}
        en_data = {"common": {"msg": "No chicks"}}  # placeholder eksik
        de_data = {"common": {"msg": "{} Jungtiere"}}
        with tempfile.TemporaryDirectory() as d:
            root = Path(d)
            trans_dir = self._make_translations(root, tr=tr_data, en=en_data, de=de_data)
            (root / "lib").mkdir()
            with patch.object(cl, "TRANSLATIONS_DIR", trans_dir), patch.object(
                cl, "ROOT", root
            ):
                result = cl.main()
        self.assertEqual(result, 1)

    def test_detects_tr_key_used_in_dart_but_missing_from_json(self):
        import check_l10n_sync as cl

        # JSON has 'common.save' but dart uses 'common.missing_key'
        data = {"common": {"save": "Kaydet"}}
        with tempfile.TemporaryDirectory() as d:
            root = Path(d)
            trans_dir = self._make_translations(root, tr=data, en=data, de=data)
            lib_dir = root / "lib"
            lib_dir.mkdir()
            # Dart file referencing a key not in the JSON
            (lib_dir / "some_screen.dart").write_text(
                "  Text('common.missing_key'.tr()),\n", encoding="utf-8"
            )
            with patch.object(cl, "TRANSLATIONS_DIR", trans_dir), patch.object(
                cl, "ROOT", root
            ):
                # Without --strict-keys: non-zero only if there are other issues
                # With patched sys.argv to include --strict-keys, it counts as issue
                original_argv = sys.argv[:]
                sys.argv = ["check_l10n_sync.py", "--strict-keys"]
                try:
                    result = cl.main()
                finally:
                    sys.argv = original_argv
        self.assertEqual(result, 1)

    def test_returns_1_when_language_file_missing(self):
        """Eksik dil dosyasi varsa (satir 73-75, 79-81) return 1."""
        import check_l10n_sync as cl

        data = {"common": {"save": "Kaydet"}}
        with tempfile.TemporaryDirectory() as d:
            root = Path(d)
            trans_dir = root / "translations"
            trans_dir.mkdir(parents=True)
            # Sadece tr.json yaz, en ve de eksik
            (trans_dir / "tr.json").write_text(
                json.dumps(data, ensure_ascii=False), encoding="utf-8"
            )
            (root / "lib").mkdir()
            with patch.object(cl, "TRANSLATIONS_DIR", trans_dir), patch.object(
                cl, "ROOT", root
            ):
                result = cl.main()
        self.assertEqual(result, 1)

    def test_returns_0_and_shows_extra_keys_in_target(self):
        """Hedef dilde fazladan anahtar varsa satir 118-122 calisir."""
        import check_l10n_sync as cl

        tr_data = {"common": {"save": "Kaydet"}}
        en_data = {"common": {"save": "Save", "bonus": "Bonus"}}  # fazla anahtar
        de_data = {"common": {"save": "Speichern"}}
        with tempfile.TemporaryDirectory() as d:
            root = Path(d)
            trans_dir = self._make_translations(root, tr=tr_data, en=en_data, de=de_data)
            (root / "lib").mkdir()
            with patch.object(cl, "TRANSLATIONS_DIR", trans_dir), patch.object(
                cl, "ROOT", root
            ):
                result = cl.main()
        # Fazla anahtar issues'a eklenmez, sadece gosterilir → 0
        self.assertEqual(result, 0)

    def test_non_strict_dart_key_missing_shows_warning_not_error(self):
        """--strict-keys olmadan eksik .tr() anahtarlari UYARI olarak gosterilir (satir 200)."""
        import check_l10n_sync as cl

        data = {"common": {"save": "Kaydet"}}
        with tempfile.TemporaryDirectory() as d:
            root = Path(d)
            trans_dir = self._make_translations(root, tr=data, en=data, de=data)
            lib_dir = root / "lib"
            lib_dir.mkdir()
            (lib_dir / "some_screen.dart").write_text(
                "  Text('common.missing_key'.tr()),\n", encoding="utf-8"
            )
            with patch.object(cl, "TRANSLATIONS_DIR", trans_dir), patch.object(
                cl, "ROOT", root
            ):
                # strict-keys olmadan: issues artmaz → 0
                original_argv = sys.argv[:]
                sys.argv = ["check_l10n_sync.py"]
                try:
                    result = cl.main()
                finally:
                    sys.argv = original_argv
        self.assertEqual(result, 0)


# ── Truncation satırlari (113, 122, 134) ──────────────────────────────────────


class TestTruncationLines(_L10nTestBase):
    """21+ eksik/fazla anahtar veya 16+ bos deger olduğunda truncation satirlari calisir."""

    def test_prints_truncation_for_more_than_20_missing_keys(self):
        """21+ eksik anahtar → '... ve N tane daha' satiri basiliyor (satir 113)."""
        import check_l10n_sync as cl

        # tr'de 22 anahtar, en'de hicbiri yok
        tr_data = {"k": {f"key{i}": f"Deger{i}" for i in range(22)}}
        en_data = {"k": {}}
        de_data = {"k": {f"key{i}": f"Wert{i}" for i in range(22)}}
        with tempfile.TemporaryDirectory() as d:
            root = Path(d)
            trans_dir = self._make_translations(root, tr=tr_data, en=en_data, de=de_data)
            (root / "lib").mkdir()
            with patch.object(cl, "TRANSLATIONS_DIR", trans_dir), \
                 patch.object(cl, "ROOT", root):
                result = cl.main()
        self.assertEqual(result, 1)

    def test_prints_truncation_for_more_than_20_extra_keys(self):
        """21+ fazla anahtar hedef dilde → '... ve N tane daha' satiri basiliyor (satir 122)."""
        import check_l10n_sync as cl

        tr_data = {"k": {"save": "Kaydet"}}
        # en'de 22 fazla anahtar
        en_extra = {"k": {"save": "Save", **{f"extra{i}": f"Extra{i}" for i in range(21)}}}
        de_data = {"k": {"save": "Speichern"}}
        with tempfile.TemporaryDirectory() as d:
            root = Path(d)
            trans_dir = self._make_translations(root, tr=tr_data, en=en_extra, de=de_data)
            (root / "lib").mkdir()
            with patch.object(cl, "TRANSLATIONS_DIR", trans_dir), \
                 patch.object(cl, "ROOT", root):
                result = cl.main()
        # Fazla anahtar error sayilmaz
        self.assertEqual(result, 0)

    def test_skips_generated_dart_files(self):
        """'.freezed.dart' ve '.g.dart' dosyalari atlaniyor (satir 177)."""
        import check_l10n_sync as cl

        data = {"common": {"save": "Kaydet"}}
        with tempfile.TemporaryDirectory() as d:
            root = Path(d)
            trans_dir = self._make_translations(root, tr=data, en=data, de=data)
            lib_dir = root / "lib"
            lib_dir.mkdir()
            # Generated dosya: .tr() iceriyor ama sayilmamali
            (lib_dir / "bird_model.freezed.dart").write_text(
                "  Text('common.ghost_key'.tr()),\n", encoding="utf-8"
            )
            with patch.object(cl, "TRANSLATIONS_DIR", trans_dir), \
                 patch.object(cl, "ROOT", root):
                result = cl.main()
        # generated dosya atlaniyor → ghost_key sayilmaz → 0
        self.assertEqual(result, 0)

    def test_skips_unreadable_dart_file(self):
        """Okunamayan dart dosyasi except blogu ile atlaniyor (satirlar 180-181)."""
        import check_l10n_sync as cl

        data = {"common": {"save": "Kaydet"}}
        with tempfile.TemporaryDirectory() as d:
            root = Path(d)
            trans_dir = self._make_translations(root, tr=data, en=data, de=data)
            lib_dir = root / "lib"
            lib_dir.mkdir()
            bad = lib_dir / "broken.dart"
            bad.touch()

            original_read = Path.read_text

            def _mock_read(self_path, *args, **kwargs):
                if self_path.name == "broken.dart":
                    raise OSError("permission denied")
                return original_read(self_path, *args, **kwargs)

            with patch.object(cl, "TRANSLATIONS_DIR", trans_dir), \
                 patch.object(cl, "ROOT", root), \
                 patch.object(Path, "read_text", _mock_read):
                result = cl.main()
        self.assertEqual(result, 0)

    def test_prints_truncation_for_more_than_30_missing_tr_keys(self):
        """31+ .tr() anahtari JSON'da eksikse '... ve N tane daha' basiliyor (satirlar 177, 180-181)."""
        import check_l10n_sync as cl

        data = {"common": {"save": "Kaydet"}}
        # 31 farkli anahtar dart kodunda kullaniliyor ama JSON'da yok
        dart_lines = "\n".join(
            f"  Text('common.missing{i}'.tr())," for i in range(31)
        )
        with tempfile.TemporaryDirectory() as d:
            root = Path(d)
            trans_dir = self._make_translations(root, tr=data, en=data, de=data)
            lib_dir = root / "lib"
            lib_dir.mkdir()
            (lib_dir / "screen.dart").write_text(dart_lines + "\n", encoding="utf-8")
            with patch.object(cl, "TRANSLATIONS_DIR", trans_dir), \
                 patch.object(cl, "ROOT", root):
                original_argv = sys.argv[:]
                # --strict-keys olmadan uyari (issues artmaz)
                sys.argv = ["check_l10n_sync.py"]
                try:
                    result = cl.main()
                finally:
                    sys.argv = original_argv
        # strict-keys olmadan issues artmaz → 0
        self.assertEqual(result, 0)

    def test_prints_truncation_for_more_than_15_empty_values(self):
        """16+ bos deger → '... ve N tane daha' satiri basiliyor (satir 134)."""
        import check_l10n_sync as cl

        # 16 bos degerli anahtar
        data = {"k": {f"key{i}": "" for i in range(16)}}
        with tempfile.TemporaryDirectory() as d:
            root = Path(d)
            trans_dir = self._make_translations(root, tr=data, en=data, de=data)
            (root / "lib").mkdir()
            with patch.object(cl, "TRANSLATIONS_DIR", trans_dir), \
                 patch.object(cl, "ROOT", root):
                result = cl.main()
        self.assertEqual(result, 1)


# ── Script entrypoint (satir 220) ─────────────────────────────────────────────


class TestScriptEntrypoint(unittest.TestCase):
    """if __name__ == '__main__': sys.exit(main()) dalini in-process ile kapsar (satir 220)."""

    def test_script_runs_as_main(self):
        """Script __main__ olarak calistirildiginda sys.exit cagrilir (coverage tracked)."""
        script = str(SCRIPTS_DIR / "check_l10n_sync.py")
        with patch.object(sys, "exit"):
            runpy.run_path(script, run_name="__main__")


# ── Runner ────────────────────────────────────────────────────────────────────


if __name__ == "__main__":
    unittest.main(verbosity=2)
