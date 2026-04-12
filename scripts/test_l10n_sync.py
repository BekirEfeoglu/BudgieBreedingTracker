#!/usr/bin/env python3
"""
check_l10n_sync.py icin unit testler.

Calistirma:
  python scripts/test_l10n_sync.py
  python -m pytest scripts/test_l10n_sync.py -v
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

from check_l10n_sync import count_placeholders, flatten_keys, load_json


# ── flatten_keys ──────────────────────────────────────────────────────────────


class TestFlattenKeys(unittest.TestCase):
    def test_flat_object(self):
        data = {"a": "1", "b": "2"}
        self.assertEqual(flatten_keys(data), {"a": "1", "b": "2"})

    def test_nested_object(self):
        data = {"outer": {"inner1": "v1", "inner2": "v2"}}
        self.assertEqual(flatten_keys(data), {"outer.inner1": "v1", "outer.inner2": "v2"})

    def test_deeply_nested(self):
        data = {"a": {"b": {"c": "leaf"}}}
        self.assertEqual(flatten_keys(data), {"a.b.c": "leaf"})

    def test_mixed_depth(self):
        data = {"top": "val", "nested": {"k1": "v1", "k2": "v2"}}
        result = flatten_keys(data)
        self.assertEqual(result, {"top": "val", "nested.k1": "v1", "nested.k2": "v2"})

    def test_empty_object(self):
        self.assertEqual(flatten_keys({}), {})

    def test_with_prefix(self):
        data = {"key": "val"}
        result = flatten_keys(data, prefix="prefix")
        self.assertEqual(result, {"prefix.key": "val"})

    def test_prefix_separator_is_dot(self):
        data = {"auth": {"login": {"title": "Giris"}}}
        result = flatten_keys(data)
        self.assertIn("auth.login.title", result)

    def test_sibling_keys_kept_separate(self):
        data = {"common": {"save": "Kaydet", "delete": "Sil", "cancel": "Iptal"}}
        result = flatten_keys(data)
        self.assertEqual(len(result), 3)
        self.assertIn("common.save", result)
        self.assertIn("common.delete", result)
        self.assertIn("common.cancel", result)


# ── count_placeholders ────────────────────────────────────────────────────────


class TestCountPlaceholders(unittest.TestCase):
    def test_no_placeholders(self):
        self.assertEqual(count_placeholders("Hello world"), 0)

    def test_one_placeholder(self):
        self.assertEqual(count_placeholders("{} yavru henuz sutten kesilmedi"), 1)

    def test_multiple_placeholders(self):
        self.assertEqual(count_placeholders("{} ve {} cifti"), 2)

    def test_empty_string(self):
        self.assertEqual(count_placeholders(""), 0)

    def test_non_string_int(self):
        self.assertEqual(count_placeholders(42), 0)

    def test_non_string_none(self):
        self.assertEqual(count_placeholders(None), 0)

    def test_adjacent_placeholders(self):
        self.assertEqual(count_placeholders("{}{}{}"), 3)


# ── load_json ─────────────────────────────────────────────────────────────────


class TestLoadJson(unittest.TestCase):
    def _write_json(self, data: dict) -> Path:
        tmp = tempfile.NamedTemporaryFile(
            mode="w", suffix=".json", delete=False, encoding="utf-8"
        )
        json.dump(data, tmp, ensure_ascii=False)
        tmp.close()
        return Path(tmp.name)

    def test_loads_flat_object(self):
        p = self._write_json({"key": "value"})
        result = load_json(p)
        self.assertEqual(result["key"], "value")

    def test_loads_nested_object(self):
        p = self._write_json({"common": {"save": "Kaydet"}})
        result = load_json(p)
        self.assertEqual(result["common"]["save"], "Kaydet")

    def test_loads_empty_object(self):
        p = self._write_json({})
        result = load_json(p)
        self.assertEqual(result, {})

    def test_loads_unicode_values(self):
        p = self._write_json({"greeting": "Merhaba dünya"})
        result = load_json(p)
        self.assertEqual(result["greeting"], "Merhaba dünya")


# ── Key sync logic ────────────────────────────────────────────────────────────


class TestKeySync(unittest.TestCase):
    """flatten_keys + set operations ile eksik/fazla anahtar ve placeholder tespiti."""

    def _flat(self, data: dict) -> set:
        return set(flatten_keys(data).keys())

    def test_detects_missing_key_in_target(self):
        master = {"common": {"save": "Kaydet", "delete": "Sil"}}
        target = {"common": {"save": "Save"}}
        missing = self._flat(master) - self._flat(target)
        self.assertEqual(missing, {"common.delete"})

    def test_detects_extra_key_in_target(self):
        master = {"common": {"save": "Kaydet"}}
        target = {"common": {"save": "Save", "extra": "Extra"}}
        extra = self._flat(target) - self._flat(master)
        self.assertEqual(extra, {"common.extra"})

    def test_synced_dicts_have_no_diff(self):
        master = {"common": {"save": "Kaydet", "delete": "Sil"}}
        target = {"common": {"save": "Save", "delete": "Delete"}}
        self.assertEqual(self._flat(master) - self._flat(target), set())
        self.assertEqual(self._flat(target) - self._flat(master), set())

    def test_placeholder_mismatch_detected(self):
        tr_val = "{} ve {} çifti"
        en_val = "The bird"
        self.assertNotEqual(count_placeholders(tr_val), count_placeholders(en_val))

    def test_placeholder_match_passes(self):
        tr_val = "{} yavru"
        en_val = "{} chicks"
        self.assertEqual(count_placeholders(tr_val), count_placeholders(en_val))

    def test_empty_value_detected(self):
        data = {"common": {"save": "Kaydet", "empty_key": ""}}
        flat = flatten_keys(data)
        empty = [k for k, v in flat.items() if isinstance(v, str) and v.strip() == ""]
        self.assertEqual(empty, ["common.empty_key"])

    def test_whitespace_only_value_detected(self):
        data = {"common": {"whitespace": "   "}}
        flat = flatten_keys(data)
        empty = [k for k, v in flat.items() if isinstance(v, str) and v.strip() == ""]
        self.assertEqual(empty, ["common.whitespace"])


# ── Shared test base ──────────────────────────────────────────────────────────


# main() integration + truncation + entrypoint testleri test_l10n_sync_main.py dosyasina tasindi.


# ── Runner ────────────────────────────────────────────────────────────────────


if __name__ == "__main__":
    unittest.main(verbosity=2)
