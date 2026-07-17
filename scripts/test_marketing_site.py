"""Regression tests for the static GitHub Pages site."""

from __future__ import annotations

import json
import re
import unittest
from pathlib import Path
from urllib.parse import urlsplit


ROOT = Path(__file__).resolve().parents[1]
DOCS = ROOT / "docs"
PAGE_PATHS = {
    "tr": DOCS / "index.html",
    "en": DOCS / "en" / "index.html",
    "de": DOCS / "de" / "index.html",
}
PAGES = {lang: path.read_text(encoding="utf-8") for lang, path in PAGE_PATHS.items()}
TERMS_PATHS = {
    "tr": DOCS / "terms-of-use.html",
    "en": DOCS / "en" / "terms-of-use.html",
    "de": DOCS / "de" / "terms-of-use.html",
}
ALL_HTML_PATHS = tuple(sorted(DOCS.rglob("*.html")))
USER_GUIDE = (DOCS / "user-guide" / "index.html").read_text(encoding="utf-8")
SECURITY_COPY_PATHS = (
    *PAGE_PATHS.values(),
    DOCS / "blog" / "index.html",
    DOCS / "en" / "blog" / "index.html",
    DOCS / "de" / "blog" / "index.html",
    DOCS / "muhabbet-kusu-genetik-rehberi.html",
    DOCS / "en" / "muhabbet-kusu-genetik-rehberi.html",
    DOCS / "de" / "muhabbet-kusu-genetik-rehberi.html",
    DOCS / "support" / "index.html",
    DOCS / "privacy-policy.html",
    DOCS / "en" / "privacy-policy.html",
    DOCS / "de" / "privacy-policy.html",
)
SECURITY_COPY = "\n".join(
    path.read_text(encoding="utf-8") for path in SECURITY_COPY_PATHS
)
CSS = (DOCS / "style.css").read_text(encoding="utf-8")
I18N = (DOCS / "js" / "i18n.js").read_text(encoding="utf-8")
PRIVACY_I18N = (DOCS / "js" / "privacy-extra-i18n.js").read_text(
    encoding="utf-8"
)


class MarketingSiteContractTest(unittest.TestCase):
    def test_local_assets_and_page_ids_are_valid(self) -> None:
        missing: list[str] = []
        empty: list[str] = []
        i18n_script_refs: list[str] = []
        for path in ALL_HTML_PATHS:
            html = path.read_text(encoding="utf-8")
            page_label = str(path.relative_to(DOCS))
            ids = re.findall(r'\bid="([^"]+)"', html)
            duplicates = sorted({value for value in ids if ids.count(value) > 1})
            self.assertEqual([], duplicates, page_label)
            i18n_script_refs.extend(
                re.findall(r'\bsrc="([^"]*js/i18n\.js[^"]*)"', html)
            )

            for raw in re.findall(r'\b(?:href|src)="([^"]*)"', html):
                if not raw.strip():
                    empty.append(f"{page_label}: empty href/src")
                    continue
                if "${" in raw:
                    continue
                if raw.startswith(
                    ("#", "mailto:", "tel:", "data:", "javascript:")
                ):
                    continue
                parsed = urlsplit(raw)
                if parsed.scheme or parsed.netloc:
                    continue
                relative = parsed.path
                if relative == "/":
                    candidate = DOCS
                elif relative.startswith("/"):
                    candidate = DOCS / relative.lstrip("/")
                else:
                    candidate = path.parent / relative
                if not candidate.exists():
                    missing.append(f"{page_label}:{raw}")
        self.assertEqual([], missing)
        self.assertEqual([], empty)
        self.assertTrue(i18n_script_refs)
        self.assertTrue(
            all(ref.endswith("i18n.js?v=20260717-2") for ref in i18n_script_refs),
            i18n_script_refs,
        )

    def test_json_ld_and_heading_outline_are_valid(self) -> None:
        for path in SECURITY_COPY_PATHS:
            html = path.read_text(encoding="utf-8")
            with self.subTest(json_ld=path.relative_to(ROOT)):
                for block in re.findall(
                    r'<script\s+type="application/ld\+json">(.*?)</script>',
                    html,
                    flags=re.DOTALL,
                ):
                    json.loads(block)

        for lang, html in PAGES.items():
            json_ld_blocks = re.findall(
                r'<script\s+type="application/ld\+json">(.*?)</script>',
                html,
                flags=re.DOTALL,
            )
            self.assertGreaterEqual(len(json_ld_blocks), 1, lang)
            for block in json_ld_blocks:
                json.loads(block)

            levels = [int(level) for level in re.findall(r"<h([1-6])\b", html)]
            self.assertTrue(levels, lang)
            jumps = [
                pair for pair in zip(levels, levels[1:]) if pair[1] > pair[0] + 1
            ]
            self.assertEqual([], jumps, lang)
            self.assertNotRegex(
                html,
                r'<h4\b[^>]*data-i18n="(?:benefit_[123]_title|footer_contact_title)"',
            )
            self.assertRegex(
                html, r'<h2\b[^>]*data-i18n="footer_contact_title"'
            )

    def test_accessibility_and_tablet_navigation_contracts(self) -> None:
        for lang, html in PAGES.items():
            screenshot_sources = re.findall(
                r'src="(?:\.\./)?screenshots/\d+\.png"', html
            )
            hidden_duplicates = re.findall(
                r'class="screenshot-item-3d"\s+aria-hidden="true"', html
            )
            self.assertEqual(20, len(screenshot_sources), lang)
            self.assertEqual(10, len(hidden_duplicates), lang)
            self.assertIn("window.innerWidth >= 1200", html)
            self.assertNotIn("outline: none;\">", html)
            self.assertIn(
                "answer.setAttribute('aria-hidden', String(isOpen));", html
            )
            self.assertIn("openAnswer.setAttribute('aria-hidden', 'true');", html)
            self.assertIn("answer.setAttribute('aria-hidden', 'true');", html)
            self.assertRegex(
                html,
                r"(?s)<noscript>.*?\.faq-answer\s*\{.*?max-height: none !important;",
            )

        self.assertIn("--touch-target-size: 48px", CSS)
        self.assertIn("animation: curtainReveal 0.18s ease-out forwards", CSS)
        self.assertRegex(
            CSS, r"(?s)@media \(max-width: 1199px\).*?site-desktop-nav"
        )
        self.assertRegex(
            CSS, r"(?s)@media \(min-width: 1200px\).*?site-mobile-menu-toggle"
        )
        self.assertIn("#gd-mother:focus-visible", CSS)

    def test_security_copy_matches_implemented_encryption_scope(self) -> None:
        for key in ("trust_1", "stat_4", "faq_a2", "offline_point3_title"):
            self.assertEqual(3, len(re.findall(rf"\b{key}:", I18N)))

        combined = SECURITY_COPY + I18N + PRIVACY_I18N
        rejected_claims = (
            "Verileriniz AES-256 şifreleme ile korunur",
            "Verileriniz AES-256 ile şifrelenir",
            "Your data is protected with AES-256 encryption",
            "Your data is encrypted with AES-256",
            "accessible only through your account",
            "Ihre Daten sind mit AES-256-Verschlüsselung geschützt",
            "Ihre Daten werden mit AES-256 verschlüsselt",
            "nur über Ihr Konto zugänglich",
            "Only you can access your data",
            "Only you can access it",
            "Nur Sie haben Zugriff auf Ihre Daten",
            "Nur Sie haben Zugriff",
            "şifrelenmiş SQLite veritabanında",
            "encrypted SQLite database",
            "verschlüsselten SQLite-Datenbank",
            "yalnızca hesap sahibi tarafından erişilebilir",
            "accessible only by the account owner",
            "only be accessed by the account owner",
            "nur für den Kontoinhaber zugänglich",
            "nur vom Kontoinhaber abgerufen",
            "The photo does not leave your device",
            "deleted after processing",
            "Fotoğraf cihazınızdan çıkmaz",
            "işlem sonrası silinir",
            "Das Foto verlässt Ihr Gerät nicht",
            "nach der Verarbeitung gelöscht",
            "10MB file size limit",
            "10 MB",
        )
        for claim in rejected_claims:
            self.assertNotIn(claim, combined)

        self.assertIn("Hassas kuş alanları cihaz anahtarıyla şifrelenir", combined)
        self.assertIn("Sensitive bird fields are encrypted with a device key", combined)
        self.assertIn("Sensible Vogeldaten werden mit einem Geräteschlüssel", combined)
        self.assertIn("hesap ve rol tabanlı", combined)
        self.assertIn("account- and role-based", combined)
        self.assertIn("konto- und rollenbasierte", combined)

        for path in (
            DOCS / "privacy-policy.html",
            DOCS / "en" / "privacy-policy.html",
            DOCS / "de" / "privacy-policy.html",
        ):
            html = path.read_text(encoding="utf-8")
            self.assertIn('data-i18n-html="supplemental_sections"', html)
            self.assertIn("privacy-extra-i18n.js?v=20260717", html)
            self.assertIn("window.bbtPrivacyExtraTranslations", html)
            self.assertIn("data-i18n-aria-label", html)
            self.assertIn("const pathLocaleMatch", html)
            self.assertNotIn("Wellensittichzuchttracker.online", html)

        english_privacy = (DOCS / "en" / "privacy-policy.html").read_text(
            encoding="utf-8"
        )
        german_privacy = (DOCS / "de" / "privacy-policy.html").read_text(
            encoding="utf-8"
        )
        for leaked_label in (" canonical ", " fonts ", " favicon "):
            self.assertNotIn(f"\n{leaked_label}\n", english_privacy)
        for leaked_label in (
            " Diagramm öffnen ",
            " Twitter-Karte ",
            " kanonisch ",
            " Schriftarten ",
            " Dekorative Hintergrundschichten ",
            " Schwimmende Blattpartikel ",
            " Kopfzeile ",
            " Inhalt ",
            " Fußzeile ",
        ):
            self.assertNotIn(f"\n{leaked_label}\n", german_privacy)

        self.assertEqual(3, PRIVACY_I18N.count("supplemental_sections:"))
        self.assertIn("2 MiB raw-file limit", PRIVACY_I18N)
        self.assertIn("2 MiB ham dosya sınırı", PRIVACY_I18N)
        self.assertIn("Rohdateigrenze von 2 MiB", PRIVACY_I18N)

    def test_genetics_demo_results_and_notes_are_localized(self) -> None:
        note_keys = (
            "genetics_note_lutino",
            "genetics_note_albino",
            "genetics_note_pied",
            "genetics_note_spangle",
            "genetics_note_opaline",
        )
        for key in note_keys:
            self.assertEqual(3, len(re.findall(rf"\b{key}:", I18N)))

        for lang, html in PAGES.items():
            self.assertIn("${getMutationLabel(r.key)}", html, lang)
            self.assertIn("getMutationNote(mother)", html, lang)
            self.assertNotIn(">${m.label}</div>", html, lang)
            self.assertNotIn("const browserLang = (navigator.language", html, lang)
            self.assertIn("duration: 0.4, stagger: 0.06", html, lang)
            self.assertNotIn("duration: 1.2, ease: 'power3.out'", html, lang)

        self.assertIn("const isLocalizedHomepage = /^\\/(en|de)\\/?$/", I18N)
        self.assertIn("const isI18nPath = isLocalizedHomepage ||", I18N)
        self.assertIn("window.setTimeout(() => {", I18N)
        self.assertIn("window.__bbtUserReady = true;", I18N)
        self.assertNotIn("window.addEventListener('load', () => { window.__bbtUserReady", I18N)

    def test_user_guide_interactions_are_localized_and_accessible(self) -> None:
        self.assertNotIn('src=""', USER_GUIDE)
        self.assertNotRegex(USER_GUIDE, r"icon:\s*'&#x[0-9A-F]+;'")
        self.assertIn('<button type="button" class="topic-card', USER_GUIDE)
        self.assertIn('<button type="button" class="screenshot-frame', USER_GUIDE)
        self.assertIn('aria-pressed="${activeCategory === null}"', USER_GUIDE)
        self.assertIn("function openLightbox(event, src)", USER_GUIDE)
        self.assertNotIn("function openLightbox(src)", USER_GUIDE)
        self.assertEqual(1, USER_GUIDE.count("document.addEventListener('keydown'"))
        self.assertRegex(
            USER_GUIDE,
            r"(?s)if \(lightbox\.classList\.contains\('active'\)\) \{\s*"
            r"closeLightbox\(\);\s*return;",
        )
        self.assertIn("_previousLightboxFocus.focus();", USER_GUIDE)
        self.assertIn("scrollTopBtn.setAttribute('aria-hidden'", USER_GUIDE)
        self.assertIn("btn.setAttribute('aria-pressed', String(isActive));", USER_GUIDE)
        self.assertIn("min-width: 48px", USER_GUIDE)
        self.assertIn("min-height: 48px", USER_GUIDE)

        for raw in re.findall(r"\bsrc:\s*'([^']+)'", USER_GUIDE):
            self.assertTrue((DOCS / "user-guide" / raw).resolve().exists(), raw)

        for key in (
            "skip",
            "home_aria",
            "breadcrumb_label",
            "breadcrumb_current",
            "search_label",
            "clear_search",
            "close_detail",
            "scroll_top",
            "screenshot_preview",
            "close_preview",
            "enlarged_screenshot",
            "version_aria",
        ):
            self.assertEqual(3, len(re.findall(rf"\b{key}:", USER_GUIDE)), key)

    def test_terms_pages_preserve_locale_and_mobile_accessibility(self) -> None:
        expected_privacy_paths = {
            "tr": "/privacy-policy.html",
            "en": "/en/privacy-policy.html",
            "de": "/de/privacy-policy.html",
        }
        for lang, path in TERMS_PATHS.items():
            html = path.read_text(encoding="utf-8")
            with self.subTest(lang=lang):
                self.assertIn('data-i18n="skip"', html)
                self.assertIn('data-i18n-aria-label="home_aria"', html)
                self.assertIn('data-i18n-aria-label="language_aria"', html)
                self.assertIn('data-i18n-aria-label="version_aria"', html)
                self.assertIn("el.setAttribute('aria-label', t[key]);", html)
                self.assertIn("btn.setAttribute('aria-pressed', String(isActive));", html)
                self.assertIn("min-width: 48px", html)
                self.assertIn("min-height: 48px", html)
                self.assertIn("flex-wrap: wrap", html)
                self.assertIn("const pathLocaleMatch", html)
                self.assertIn("if (pathLocaleMatch && translations", html)
                self.assertIn("const privacyLink = document.querySelector('[data-privacy-link]');", html)
                self.assertRegex(
                    html,
                    rf'<a\b(?=[^>]*href="{re.escape(expected_privacy_paths[lang])}")'
                    rf'(?=[^>]*\bdata-privacy-link\b)[^>]*>',
                )
                self.assertNotIn("Wellensittichzuchttracker.online", html)

                active_button = re.compile(
                    rf'<button\b(?=[^>]*class="lang-btn active")'
                    rf'(?=[^>]*data-lang="{lang}")(?=[^>]*aria-pressed="true")[^>]*>'
                )
                self.assertRegex(html, active_button)
                for key in ("skip", "home_aria", "language_aria", "version_aria"):
                    self.assertEqual(
                        3, len(re.findall(rf"\b{key}:", html)), (lang, key)
                    )

        leaked_labels = (
            "canonical",
            "favicon",
            "background system",
            "Diagramm öffnen",
            "Twitter-Karte",
            "kanonisch",
            "Hintergrundsystem",
            "Schwimmende Blattpartikel",
            "Kopfzeile",
            "Sprachumschalter",
            "Inhalt",
            "Fußzeile",
        )
        localized_terms = "\n".join(
            path.read_text(encoding="utf-8") for path in TERMS_PATHS.values()
        )
        for leaked_label in leaked_labels:
            self.assertNotRegex(
                localized_terms,
                rf"(?m)^\s*{re.escape(leaked_label)}\s*$",
            )


if __name__ == "__main__":
    unittest.main()
