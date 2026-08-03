#!/usr/bin/env python3
"""Render the public release-notes pages from the store-note source files.

`store/release_notes/<semantic-version>/{tr,en,de}.txt` is the single source
for Google Play/App Store copy and the public GitHub Pages release history.
Run with ``--write`` after drafting a release; CI runs ``--check`` so a version
bump cannot publish with stale website notes.
"""

from __future__ import annotations

import argparse
import re
import sys
from dataclasses import dataclass
from html import escape
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SOURCE_DIR = ROOT / "store" / "release_notes"
PUBSPEC_PATH = ROOT / "pubspec.yaml"
DOCS_DIR = ROOT / "docs"
LANGUAGES = ("tr", "en", "de")
VERSION_RE = re.compile(r"^\d+\.\d+\.\d+$")
PUBSPEC_VERSION_RE = re.compile(r"^version:\s*(\d+\.\d+\.\d+)\+\d+\s*$", re.MULTILINE)


@dataclass(frozen=True)
class Release:
    version: str
    notes: dict[str, str]


@dataclass(frozen=True)
class PageCopy:
    html_lang: str
    locale_label: str
    title: str
    description: str
    eyebrow: str
    intro: str
    history_title: str
    source_note: str
    home_label: str
    store_label: str
    footer_label: str


COPY = {
    "tr": PageCopy(
        html_lang="tr",
        locale_label="Türkçe",
        title="Sürüm Notları",
        description="BudgieBreedingTracker sürüm notları ve güncellemeler.",
        eyebrow="BudgieBreedingTracker",
        intro="Uygulamadaki yenilikleri, iyileştirmeleri ve düzeltmeleri sürüm sürüm takip edin.",
        history_title="Sürüm Geçmişi",
        source_note="Bu sayfa, mağaza sürüm notlarının kaynak metninden otomatik oluşturulur.",
        home_label="Ana Sayfa",
        store_label="Google Play'de görüntüle",
        footer_label="Sürüm Notları",
    ),
    "en": PageCopy(
        html_lang="en",
        locale_label="English",
        title="Release Notes",
        description="BudgieBreedingTracker release notes and updates.",
        eyebrow="BudgieBreedingTracker",
        intro="Follow new features, improvements, and fixes for every app release.",
        history_title="Release History",
        source_note="This page is generated automatically from the store release-note source files.",
        home_label="Home",
        store_label="View on Google Play",
        footer_label="Release Notes",
    ),
    "de": PageCopy(
        html_lang="de",
        locale_label="Deutsch",
        title="Versionshinweise",
        description="BudgieBreedingTracker Versionshinweise und Aktualisierungen.",
        eyebrow="BudgieBreedingTracker",
        intro="Verfolgen Sie neue Funktionen, Verbesserungen und Fehlerbehebungen für jede App-Version.",
        history_title="Versionsverlauf",
        source_note="Diese Seite wird automatisch aus den Quelltexten der Store-Versionshinweise erstellt.",
        home_label="Startseite",
        store_label="Bei Google Play ansehen",
        footer_label="Versionshinweise",
    ),
}

PAGE_PATHS = {
    "tr": DOCS_DIR / "release-notes" / "index.html",
    "en": DOCS_DIR / "en" / "release-notes" / "index.html",
    "de": DOCS_DIR / "de" / "release-notes" / "index.html",
}
PUBLIC_PATHS = {
    "tr": "/release-notes/",
    "en": "/en/release-notes/",
    "de": "/de/release-notes/",
}
PLAY_URL = (
    "https://play.google.com/store/apps/details?id="
    "com.budgiebreeding.budgie_breeding_tracker"
)


def semantic_version_key(version: str) -> tuple[int, int, int]:
    """Return a sortable semantic-version tuple."""
    if not VERSION_RE.fullmatch(version):
        raise ValueError(f"invalid release-note version directory: {version}")
    return tuple(int(part) for part in version.split("."))  # type: ignore[return-value]


def read_app_version(pubspec_path: Path = PUBSPEC_PATH) -> str:
    """Read the semantic app version from pubspec.yaml."""
    match = PUBSPEC_VERSION_RE.search(pubspec_path.read_text(encoding="utf-8"))
    if match is None:
        raise ValueError(f"could not read version from {pubspec_path}")
    return match.group(1)


def parse_note_blocks(note: str) -> str:
    """Convert a plain-text store note into safe, semantic HTML blocks."""
    lines = [line.strip() for line in note.splitlines()]
    if not lines or not lines[0]:
        raise ValueError("release note is empty")

    blocks: list[str] = []
    bullets: list[str] = []

    def flush_bullets() -> None:
        if bullets:
            blocks.append("<ul>" + "".join(bullets) + "</ul>")
            bullets.clear()

    for line in lines[1:]:
        if not line:
            flush_bullets()
            continue
        if line.startswith("•"):
            bullets.append(f"<li>{escape(line.removeprefix('•').strip())}</li>")
            continue
        flush_bullets()
        blocks.append(f"<p>{escape(line)}</p>")

    flush_bullets()
    if not blocks:
        raise ValueError("release note has no body")
    return "\n".join(blocks)


def discover_releases(source_dir: Path = SOURCE_DIR) -> list[Release]:
    """Load and validate all localized release-note directories."""
    releases: list[Release] = []
    if not source_dir.is_dir():
        raise ValueError(f"release-note source directory is missing: {source_dir}")

    for release_dir in source_dir.iterdir():
        if not release_dir.is_dir():
            continue
        version = release_dir.name
        semantic_version_key(version)
        notes: dict[str, str] = {}
        for language in LANGUAGES:
            note_path = release_dir / f"{language}.txt"
            if not note_path.is_file():
                raise ValueError(f"missing {language} release note for {version}")
            notes[language] = parse_note_blocks(note_path.read_text(encoding="utf-8"))
        releases.append(Release(version=version, notes=notes))

    if not releases:
        raise ValueError("no release-note directories found")
    return sorted(releases, key=lambda release: semantic_version_key(release.version), reverse=True)


def render_release_cards(language: str, releases: list[Release]) -> str:
    """Render newest-first release cards for one locale."""
    return "\n".join(
        """      <article class=\"release-card\">
        <h2>v{version}</h2>
        <div class=\"release-content\">
{notes}
        </div>
      </article>""".format(version=escape(release.version), notes=release.notes[language])
        for release in releases
    )


def render_page(language: str, releases: list[Release]) -> str:
    """Render one complete, localized, static release-notes page."""
    copy = COPY[language]
    canonical = f"https://budgiebreedingtracker.online{PUBLIC_PATHS[language]}"
    alternate_links = "\n".join(
        "  <link rel=\"alternate\" hreflang=\"{lang}\" href=\"https://budgiebreedingtracker.online{path}\">".format(
            lang=COPY[lang].html_lang,
            path=PUBLIC_PATHS[lang],
        )
        for lang in LANGUAGES
    )
    language_links = "\n".join(
        "        <a href=\"{path}\" lang=\"{lang}\"{current}>{label}</a>".format(
            path=PUBLIC_PATHS[lang],
            lang=COPY[lang].html_lang,
            current=' aria-current="page"' if lang == language else "",
            label=escape(COPY[lang].locale_label),
        )
        for lang in LANGUAGES
    )
    release_cards = render_release_cards(language, releases)
    return f"""<!doctype html>
<!-- Generated by scripts/generate_release_notes_site.py. Do not edit manually. -->
<html lang=\"{copy.html_lang}\">
<head>
  <meta charset=\"utf-8\">
  <meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">
  <title>{escape(copy.title)} | BudgieBreedingTracker</title>
  <meta name=\"description\" content=\"{escape(copy.description)}\">
  <meta name=\"theme-color\" content=\"#0F1B4D\">
  <meta property=\"og:title\" content=\"{escape(copy.title)} | BudgieBreedingTracker\">
  <meta property=\"og:description\" content=\"{escape(copy.description)}\">
  <meta property=\"og:type\" content=\"website\">
  <meta property=\"og:url\" content=\"{canonical}\">
  <meta property=\"og:image\" content=\"https://budgiebreedingtracker.online/og-image.png\">
  <link rel=\"canonical\" href=\"{canonical}\">
{alternate_links}
  <link rel=\"alternate\" hreflang=\"x-default\" href=\"https://budgiebreedingtracker.online/release-notes/\">
  <link rel=\"icon\" type=\"image/png\" href=\"/logo.png\">
  <link rel=\"apple-touch-icon\" href=\"/logo.png\">
  <link rel=\"preconnect\" href=\"https://fonts.googleapis.com\">
  <link rel=\"preconnect\" href=\"https://fonts.gstatic.com\" crossorigin>
  <link href=\"https://fonts.googleapis.com/css2?family=DM+Sans:wght@400;500;600;700&family=Outfit:wght@600;700;800&display=swap\" rel=\"stylesheet\">
  <style>
    :root {{ --navy: #0f1b4d; --navy-mid: #162560; --blue: #3366b8; --blue-light: #5599dd; --text: #e0ebf8; --muted: #b0cfee; --gold: #ffd95a; --border: rgba(160, 200, 240, 0.22); }}
    * {{ box-sizing: border-box; }}
    body {{ margin: 0; color: var(--text); font-family: 'DM Sans', system-ui, sans-serif; line-height: 1.65; background: radial-gradient(ellipse at 15% 0%, rgba(60, 110, 190, 0.38), transparent 42%), linear-gradient(160deg, var(--navy), var(--navy-mid)); min-height: 100vh; }}
    a {{ color: var(--gold); }}
    a:focus-visible {{ outline: 3px solid var(--gold); outline-offset: 4px; border-radius: 6px; }}
    .skip-link {{ position: fixed; top: 12px; left: 12px; z-index: 10; transform: translateY(-150%); padding: 10px 14px; border-radius: 8px; color: var(--navy); background: var(--gold); font-weight: 700; text-decoration: none; }}
    .skip-link:focus {{ transform: translateY(0); }}
    .page {{ width: min(920px, calc(100% - 32px)); margin: 0 auto; padding: 28px 0 56px; }}
    header {{ display: flex; justify-content: space-between; align-items: center; gap: 20px; margin-bottom: 52px; }}
    .brand {{ display: inline-flex; align-items: center; gap: 12px; color: var(--text); font-family: Outfit, sans-serif; font-weight: 800; text-decoration: none; }}
    .brand img {{ width: 44px; height: 44px; border: 1px solid rgba(255, 217, 90, 0.3); border-radius: 12px; }}
    .language-nav {{ display: flex; flex-wrap: wrap; gap: 6px; }}
    .language-nav a {{ min-height: 48px; display: inline-flex; align-items: center; padding: 0 12px; border: 1px solid var(--border); border-radius: 10px; color: var(--muted); font-size: 14px; text-decoration: none; }}
    .language-nav a[aria-current=\"page\"] {{ color: var(--navy); background: var(--gold); border-color: var(--gold); font-weight: 700; }}
    .hero, .release-card {{ border: 1px solid var(--border); border-radius: 20px; background: rgba(8, 20, 62, 0.52); box-shadow: 0 20px 56px rgba(0, 0, 0, 0.18); }}
    .hero {{ padding: clamp(28px, 6vw, 52px); }}
    .eyebrow {{ margin: 0 0 10px; color: var(--gold); font-size: 14px; font-weight: 700; letter-spacing: 0.08em; text-transform: uppercase; }}
    h1, h2 {{ margin: 0; font-family: Outfit, sans-serif; line-height: 1.15; }}
    h1 {{ color: #fff; font-size: clamp(38px, 7vw, 64px); }}
    .intro {{ max-width: 680px; margin: 18px 0 0; color: var(--muted); font-size: 18px; }}
    .source-note {{ margin: 18px 0 0; color: var(--muted); font-size: 14px; }}
    .actions {{ display: flex; flex-wrap: wrap; gap: 12px; margin-top: 26px; }}
    .button {{ min-height: 48px; display: inline-flex; align-items: center; justify-content: center; padding: 0 18px; border: 1px solid rgba(255, 217, 90, 0.4); border-radius: 10px; color: var(--navy); background: var(--gold); font-weight: 700; text-decoration: none; }}
    .section-title {{ margin: 46px 0 18px; color: #fff; font-size: 28px; }}
    .release-list {{ display: grid; gap: 16px; }}
    .release-card {{ padding: 28px; }}
    .release-card h2 {{ color: var(--gold); font-size: 24px; }}
    .release-content {{ margin-top: 16px; color: var(--text); }}
    .release-content p {{ margin: 0 0 12px; }}
    .release-content ul {{ margin: 0; padding-left: 22px; }}
    .release-content li + li {{ margin-top: 10px; }}
    footer {{ display: flex; flex-wrap: wrap; justify-content: space-between; gap: 16px; margin-top: 36px; color: var(--muted); font-size: 14px; }}
    footer a {{ min-height: 48px; display: inline-flex; align-items: center; }}
    @media (max-width: 640px) {{ .page {{ width: min(100% - 24px, 920px); padding-top: 20px; }} header {{ align-items: flex-start; flex-direction: column; margin-bottom: 32px; }} .hero, .release-card {{ padding: 24px; }} .language-nav {{ width: 100%; }} .language-nav a {{ flex: 1; justify-content: center; }} }}
  </style>
</head>
<body>
  <a class=\"skip-link\" href=\"#main-content\">{escape(copy.history_title)}</a>
  <div class=\"page\">
    <header>
      <a class=\"brand\" href=\"/\"><img src=\"/logo.png\" alt=\"BudgieBreedingTracker\">BudgieBreedingTracker</a>
      <nav class=\"language-nav\" aria-label=\"Language\">
{language_links}
      </nav>
    </header>
    <main id=\"main-content\">
      <section class=\"hero\" aria-labelledby=\"page-title\">
        <p class=\"eyebrow\">{escape(copy.eyebrow)}</p>
        <h1 id=\"page-title\">{escape(copy.title)}</h1>
        <p class=\"intro\">{escape(copy.intro)}</p>
        <p class=\"source-note\">{escape(copy.source_note)}</p>
        <div class=\"actions\"><a class=\"button\" href=\"{PLAY_URL}\">{escape(copy.store_label)}</a></div>
      </section>
      <h2 class=\"section-title\">{escape(copy.history_title)}</h2>
      <section class=\"release-list\" aria-label=\"{escape(copy.history_title)}\">
{release_cards}
      </section>
    </main>
    <footer>
      <span>© 2025-2026 BudgieBreedingTracker</span>
      <a href=\"/\">{escape(copy.home_label)}</a>
      <a href=\"{PUBLIC_PATHS[language]}\">{escape(copy.footer_label)}</a>
    </footer>
  </div>
</body>
</html>
"""


def expected_pages(
    source_dir: Path = SOURCE_DIR,
    pubspec_path: Path = PUBSPEC_PATH,
) -> dict[Path, str]:
    """Return every generated page after enforcing current-version coverage."""
    releases = discover_releases(source_dir)
    current_version = read_app_version(pubspec_path)
    versions = {release.version for release in releases}
    if current_version not in versions:
        raise ValueError(
            f"missing release notes for current pubspec version {current_version}"
        )
    return {PAGE_PATHS[language]: render_page(language, releases) for language in LANGUAGES}


def write_pages(pages: dict[Path, str]) -> None:
    """Write every generated page, creating its locale directory when needed."""
    for path, content in pages.items():
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(content, encoding="utf-8")


def stale_pages(pages: dict[Path, str]) -> list[Path]:
    """Return generated pages that are missing or differ from their source."""
    return [
        path
        for path, expected in pages.items()
        if not path.is_file() or path.read_text(encoding="utf-8") != expected
    ]


def parse_args(argv: list[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    mode = parser.add_mutually_exclusive_group(required=True)
    mode.add_argument("--write", action="store_true", help="regenerate pages")
    mode.add_argument("--check", action="store_true", help="fail when pages are stale")
    return parser.parse_args(argv)


def main(argv: list[str] | None = None) -> int:
    args = parse_args(argv)
    try:
        pages = expected_pages()
    except ValueError as error:
        print(f"ERROR: {error}")
        return 1

    if args.write:
        write_pages(pages)
        print(f"Generated {len(pages)} release-notes pages.")
        return 0

    stale = stale_pages(pages)
    if stale:
        for path in stale:
            print(f"ERROR: stale release-notes page: {path.relative_to(ROOT)}")
        print("Run: python3 scripts/generate_release_notes_site.py --write")
        return 1

    print("Release-notes site is current.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
