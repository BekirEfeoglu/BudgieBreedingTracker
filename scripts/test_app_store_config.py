#!/usr/bin/env python3
"""
App Store release configuration checks.

Run:
  python scripts/test_app_store_config.py
  python -m pytest scripts/test_app_store_config.py -v
"""

import json
import plistlib
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
IOS_RUNNER = ROOT / "ios" / "Runner"


class TestIOSLocalizationMetadata(unittest.TestCase):
    def test_info_plist_declares_all_supported_locales(self):
        info = plistlib.loads((IOS_RUNNER / "Info.plist").read_bytes())

        self.assertEqual(
            sorted(info["CFBundleLocalizations"]),
            ["de", "en", "tr"],
        )

    def test_native_permission_strings_are_localized(self):
        expected = {
            "en": "This app needs camera access to take photos of your birds and eggs.",
            "tr": "Bu uygulama, kuslarinizin ve yumurtalarinizin fotografini cekmek icin kamera erisimine ihtiyac duyar.",
            "de": "Diese App benötigt Kamerazugriff, um Fotos Ihrer Vögel und Eier aufzunehmen.",
        }

        for locale, camera_text in expected.items():
            strings_path = IOS_RUNNER / f"{locale}.lproj" / "InfoPlist.strings"
            self.assertTrue(strings_path.exists(), f"missing {strings_path}")
            content = strings_path.read_text(encoding="utf-8")
            self.assertIn(f'NSCameraUsageDescription = "{camera_text}";', content)
            self.assertIn("NSPhotoLibraryUsageDescription", content)
            self.assertIn("NSPhotoLibraryAddUsageDescription", content)
            self.assertIn("NSUserTrackingUsageDescription", content)


class TestStoreKitProducts(unittest.TestCase):
    def test_storekit_file_matches_approved_app_store_products(self):
        storekit = json.loads((IOS_RUNNER / "Products.storekit").read_text())

        products = {product["productID"] for product in storekit["products"]}
        subscriptions = {
            subscription["productID"]
            for group in storekit["subscriptionGroups"]
            for subscription in group["subscriptions"]
        }

        self.assertEqual(
            products,
            set(),
        )
        self.assertEqual(
            subscriptions,
            {"budgie_premium_semi_annual", "budgie_premium_yearly"},
        )


class TestPrivacyManifest(unittest.TestCase):
    def test_privacy_manifest_declares_user_and_device_identifiers(self):
        privacy = plistlib.loads((IOS_RUNNER / "PrivacyInfo.xcprivacy").read_bytes())
        collected = {
            item["NSPrivacyCollectedDataType"]: item
            for item in privacy["NSPrivacyCollectedDataTypes"]
        }

        device_id = collected["NSPrivacyCollectedDataTypeDeviceID"]
        self.assertTrue(device_id["NSPrivacyCollectedDataTypeTracking"])
        self.assertFalse(device_id["NSPrivacyCollectedDataTypeLinked"])

        user_id = collected["NSPrivacyCollectedDataTypeUserID"]
        self.assertFalse(user_id["NSPrivacyCollectedDataTypeTracking"])
        self.assertTrue(user_id["NSPrivacyCollectedDataTypeLinked"])
        self.assertEqual(
            sorted(user_id["NSPrivacyCollectedDataTypePurposes"]),
            [
                "NSPrivacyCollectedDataTypePurposeAnalytics",
                "NSPrivacyCollectedDataTypePurposeAppFunctionality",
            ],
        )


if __name__ == "__main__":
    unittest.main()
