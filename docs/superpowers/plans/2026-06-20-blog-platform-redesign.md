# Blog Platform Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the duplicated static blog pages with a Markdown-driven, accessible editorial platform that generates correct SEO output, rewrites every existing guide, and supports measurable app-download conversion.

**Architecture:** A Python 3 generator loads validated YAML frontmatter and CommonMark content from `site/blog/content/`, renders Jinja templates, and commits reproducible output under `docs/`. Shared blog CSS and JavaScript progressively enhance fully readable static HTML; Python unit tests, output audits, and Playwright browser tests protect the generation contract.

**Tech Stack:** Python 3, `markdown-it-py`, PyYAML, Jinja2, Beautiful Soup, `unittest`, static HTML/CSS/JavaScript, Playwright 1.61, GitHub Pages.

---

## Scope and Working-Tree Contract

- Preserve the existing public URLs for the ten guides currently shown on `/blog/`.
- Also migrate the two live standalone guide URLs, `/blog/kulucka-rehberi.html` and `/blog/mutasyon-rehberi.html`, so no legacy blog page keeps the broken shell.
- Keep `/muhabbet-kusu-genetik-rehberi.html` as the authoritative genetics pillar URL and generate it from the same content system.
- Do not stage, rewrite, or revert the pre-existing `ios/Runner.xcodeproj/project.pbxproj` change.
- Generated HTML, `sitemap.xml`, RSS, and copied blog assets are committed, but never edited manually.
- After every generator, dependency, formatting, test, or build command, re-run `git status --short --branch` and classify new files before continuing.

## File Map

### Generator and Verification

- `scripts/requirements_blog.txt`: pinned Python dependencies.
- `scripts/blog_models.py`: typed article/config models and invariant validation.
- `scripts/blog_content.py`: frontmatter parsing, heading IDs, Markdown rendering, and reading-time calculation.
- `scripts/blog_render.py`: Jinja setup, page context, JSON-LD, sitemap, and RSS rendering.
- `scripts/blog_validate.py`: generated HTML, link, metadata, schema, and output-drift checks.
- `scripts/build_blog.py`: CLI orchestration for build and `--check` modes.
- `scripts/test_blog_*.py`: focused `unittest` coverage for each module.

### Authored Site Source

- `site/blog/config.yaml`: site URLs, category labels, store links, static sitemap pages, and publisher data.
- `site/blog/content/*.md`: twelve canonical content sources.
- `site/blog/templates/base.html.j2`: shared document shell, head, navigation, and footer.
- `site/blog/templates/index.html.j2`: collection/featured/search/filter layout.
- `site/blog/templates/article.html.j2`: article, TOC, disclaimer, sources, related content, and CTA layout.
- `site/blog/assets/blog.css`: Editorial Hybrid visual system.
- `site/blog/assets/blog.js`: navigation, search, filters, result status, and mobile TOC enhancement.

### Browser Tests and Generated Output

- `site/blog/package.json`, `site/blog/package-lock.json`: pinned Playwright test dependency.
- `site/blog/playwright.config.mjs`: local static-server browser configuration.
- `site/blog/tests/blog.spec.mjs`: desktop, mobile, no-JS, accessibility-state, metadata, and console tests.
- `docs/blog/index.html`, `docs/blog/*.html`: generated collection and article pages.
- `docs/muhabbet-kusu-genetik-rehberi.html`: generated genetics pillar page.
- `docs/blog/assets/blog.css`, `docs/blog/assets/blog.js`: generated copies of authored assets.
- `docs/blog/feed.xml`, `docs/sitemap.xml`: generated discovery files.
- `docs/blog/.generated-files.json`: generated ownership manifest used to remove only stale blog outputs.

### Workflow Documentation

- `.github/workflows/ci.yml`: install generator dependencies, run reproducibility audit, and run Playwright blog tests.
- `.claude/rules/ci-actions.md`: document the new blog gates.
- `.github/pull_request_template.md`: expose the blog generation/browser checklist.

---

### Task 1: Add Typed Blog Metadata and Validation

**Files:**
- Create: `scripts/requirements_blog.txt`
- Create: `scripts/blog_models.py`
- Create: `scripts/test_blog_models.py`

- [ ] **Step 1: Write failing metadata validation tests**

```python
# scripts/test_blog_models.py
import sys
import unittest
from datetime import date
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from blog_models import ArticleMeta, ContentError, SourceRef


class TestArticleMeta(unittest.TestCase):
    def valid_meta(self, **overrides):
        values = {
            "title": "Kuluçka Rehberi",
            "description": "Muhabbet kuşu kuluçka sürecini gün gün açıklayan rehber.",
            "slug": "kulucka-rehberi",
            "output_path": "blog/kulucka-rehberi.html",
            "category": "uretim",
            "published_at": date(2026, 5, 15),
            "updated_at": date(2026, 6, 20),
            "author": "BudgieBreedingTracker Editör Ekibi",
            "reviewed_by": None,
            "featured": False,
            "listed": True,
            "related_slugs": ("yavru-gelisimi",),
            "sources": (SourceRef("LafeberVet parakeet sheet", "https://lafeber.com/vet/basic-information-sheet-for-the-parakeet/"),),
            "disclaimer": None,
            "app_feature": "Kuluçka ve yumurta takibi",
        }
        values.update(overrides)
        return ArticleMeta(**values)

    def test_accepts_valid_metadata(self):
        self.valid_meta().validate(today=date(2026, 6, 20))

    def test_rejects_future_publication_date(self):
        meta = self.valid_meta(published_at=date(2026, 6, 21))
        with self.assertRaisesRegex(ContentError, "future publication date"):
            meta.validate(today=date(2026, 6, 20))

    def test_rejects_path_traversal(self):
        meta = self.valid_meta(output_path="../index.html")
        with self.assertRaisesRegex(ContentError, "output_path"):
            meta.validate(today=date(2026, 6, 20))

    def test_health_article_requires_disclaimer_and_sources(self):
        meta = self.valid_meta(category="saglik", disclaimer=None, sources=())
        with self.assertRaisesRegex(ContentError, "health article"):
            meta.validate(today=date(2026, 6, 20))


if __name__ == "__main__":
    unittest.main(verbosity=2)
```

- [ ] **Step 2: Run the test and verify the expected failure**

Run: `python3 scripts/test_blog_models.py`

Expected: `ModuleNotFoundError: No module named 'blog_models'`.

- [ ] **Step 3: Pin parser/template dependencies**

```text
# scripts/requirements_blog.txt
beautifulsoup4==4.15.0
Jinja2==3.1.6
markdown-it-py==3.0.0
PyYAML==6.0.3
```

Run: `python3 -m pip install -r scripts/requirements_blog.txt`

Expected: all four direct dependencies install successfully.

- [ ] **Step 4: Implement the typed models and invariants**

```python
# scripts/blog_models.py
from dataclasses import dataclass
from datetime import date
from pathlib import PurePosixPath

VALID_CATEGORIES = frozenset({"uretim", "beslenme", "genetik", "saglik"})


class ContentError(ValueError):
    pass


@dataclass(frozen=True)
class SourceRef:
    label: str
    url: str


@dataclass(frozen=True)
class Heading:
    level: int
    text: str
    anchor: str


@dataclass(frozen=True)
class ArticleMeta:
    title: str
    description: str
    slug: str
    output_path: str
    category: str
    published_at: date
    updated_at: date
    author: str
    reviewed_by: str | None
    featured: bool
    listed: bool
    related_slugs: tuple[str, ...]
    sources: tuple[SourceRef, ...]
    disclaimer: str | None
    app_feature: str | None

    def validate(self, *, today: date) -> None:
        if self.category not in VALID_CATEGORIES:
            raise ContentError(f"unknown category: {self.category}")
        if self.published_at > today:
            raise ContentError(f"future publication date: {self.published_at}")
        if self.updated_at < self.published_at:
            raise ContentError("updated_at cannot precede published_at")
        path = PurePosixPath(self.output_path)
        if path.is_absolute() or ".." in path.parts or path.suffix != ".html":
            raise ContentError(f"invalid output_path: {self.output_path}")
        if not self.title.strip() or not self.description.strip() or not self.author.strip():
            raise ContentError("title, description, and author are required")
        if self.category == "saglik" and (not self.disclaimer or not self.sources):
            raise ContentError("health article requires disclaimer and sources")


@dataclass(frozen=True)
class Article:
    meta: ArticleMeta
    body_html: str
    plain_text: str
    headings: tuple[Heading, ...]
    reading_minutes: int
```

- [ ] **Step 5: Run tests and inspect the worktree**

Run: `python3 scripts/test_blog_models.py && git status --short --branch`

Expected: four tests pass; only Task 1 files plus the pre-existing iOS change appear.

- [ ] **Step 6: Commit Task 1**

```bash
git add scripts/requirements_blog.txt scripts/blog_models.py scripts/test_blog_models.py
git commit -m "feat(blog): add typed content metadata"
```

---

### Task 2: Parse and Render Markdown Safely

**Files:**
- Create: `scripts/blog_content.py`
- Create: `scripts/test_blog_content.py`

- [ ] **Step 1: Write failing loader tests**

```python
# scripts/test_blog_content.py
import sys
import tempfile
import unittest
from datetime import date
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from blog_content import load_article
from blog_models import ContentError

SAMPLE = """---
title: Kuluçka Rehberi
description: Muhabbet kuşu kuluçka sürecini açıklayan güvenilir rehber.
slug: kulucka-rehberi
output_path: blog/kulucka-rehberi.html
category: uretim
published_at: 2026-05-15
updated_at: 2026-06-20
author: BudgieBreedingTracker Editör Ekibi
reviewed_by:
featured: false
listed: true
related_slugs: [yavru-gelisimi]
sources:
  - label: LafeberVet parakeet sheet
    url: https://lafeber.com/vet/basic-information-sheet-for-the-parakeet/
disclaimer:
app_feature: Kuluçka ve yumurta takibi
---
# Gizli sayfa başlığı

## Kuluçka öncesi hazırlık

Bu metin **kaynaklıdır** ve yaklaşık iki yüz kelimelik okuma hesabına katılır.
"""


class TestLoadArticle(unittest.TestCase):
    def write(self, content=SAMPLE):
        temp = tempfile.NamedTemporaryFile("w", suffix=".md", delete=False, encoding="utf-8")
        temp.write(content)
        temp.close()
        return Path(temp.name)

    def test_loads_frontmatter_markdown_and_heading_anchor(self):
        article = load_article(self.write(), today=date(2026, 6, 20))
        self.assertEqual(article.meta.slug, "kulucka-rehberi")
        self.assertIn('<h2 id="kulucka-oncesi-hazirlik">', article.body_html)
        self.assertEqual(article.headings[0].anchor, "kulucka-oncesi-hazirlik")
        self.assertGreaterEqual(article.reading_minutes, 1)

    def test_escapes_raw_html(self):
        article = load_article(self.write(SAMPLE + "\n<script>alert(1)</script>"), today=date(2026, 6, 20))
        self.assertNotIn("<script>", article.body_html)

    def test_rejects_missing_frontmatter(self):
        with self.assertRaisesRegex(ContentError, "frontmatter"):
            load_article(self.write("# Başlık"), today=date(2026, 6, 20))


if __name__ == "__main__":
    unittest.main(verbosity=2)
```

- [ ] **Step 2: Run the test and verify failure**

Run: `python3 scripts/test_blog_content.py`

Expected: `ModuleNotFoundError: No module named 'blog_content'`.

- [ ] **Step 3: Implement structured frontmatter and CommonMark rendering**

Create `scripts/blog_content.py` with these public functions and behavior:

```python
from datetime import date, datetime
from pathlib import Path
import re
import unicodedata

from markdown_it import MarkdownIt
import yaml

from blog_models import Article, ArticleMeta, ContentError, Heading, SourceRef

FRONTMATTER = re.compile(r"\A---\s*\n(.*?)\n---\s*\n(.*)\Z", re.DOTALL)
TURKISH_MAP = str.maketrans({"ı": "i", "İ": "I", "ş": "s", "Ş": "S", "ğ": "g", "Ğ": "G", "ü": "u", "Ü": "U", "ö": "o", "Ö": "O", "ç": "c", "Ç": "C"})


def _date(value, field):
    if isinstance(value, datetime):
        return value.date()
    if isinstance(value, date):
        return value
    try:
        return date.fromisoformat(str(value))
    except ValueError as error:
        raise ContentError(f"invalid {field}: {value}") from error


def slugify_heading(value: str) -> str:
    ascii_value = unicodedata.normalize("NFKD", value.translate(TURKISH_MAP)).encode("ascii", "ignore").decode()
    return re.sub(r"[^a-z0-9]+", "-", ascii_value.lower()).strip("-")


def _metadata(data: dict) -> ArticleMeta:
    sources = tuple(SourceRef(str(item["label"]), str(item["url"])) for item in data.get("sources", []))
    return ArticleMeta(
        title=str(data["title"]), description=str(data["description"]), slug=str(data["slug"]),
        output_path=str(data["output_path"]), category=str(data["category"]),
        published_at=_date(data["published_at"], "published_at"), updated_at=_date(data["updated_at"], "updated_at"),
        author=str(data["author"]), reviewed_by=data.get("reviewed_by"), featured=bool(data.get("featured", False)),
        listed=bool(data.get("listed", True)), related_slugs=tuple(data.get("related_slugs", [])), sources=sources,
        disclaimer=data.get("disclaimer"), app_feature=data.get("app_feature"),
    )


def load_article(path: Path, *, today: date) -> Article:
    match = FRONTMATTER.match(path.read_text(encoding="utf-8"))
    if not match:
        raise ContentError(f"missing frontmatter: {path}")
    data = yaml.safe_load(match.group(1))
    if not isinstance(data, dict):
        raise ContentError(f"frontmatter must be a mapping: {path}")
    meta = _metadata(data)
    meta.validate(today=today)
    markdown = MarkdownIt("commonmark", {"html": False}).enable("table")
    tokens = markdown.parse(match.group(2))
    headings = []
    for index, token in enumerate(tokens):
        if token.type == "heading_open" and index + 1 < len(tokens):
            text = tokens[index + 1].content
            anchor = slugify_heading(text)
            token.attrSet("id", anchor)
            headings.append(Heading(int(token.tag[1]), text, anchor))
    body_html = markdown.renderer.render(tokens, markdown.options, {})
    plain_text = re.sub(r"\s+", " ", re.sub(r"<[^>]+>", " ", body_html)).strip()
    reading_minutes = max(1, (len(plain_text.split()) + 199) // 200)
    return Article(meta, body_html, plain_text, tuple(headings), reading_minutes)
```

- [ ] **Step 4: Run loader and model tests**

Run: `python3 -m unittest scripts.test_blog_models scripts.test_blog_content -v`

Expected: all tests pass.

- [ ] **Step 5: Commit Task 2**

```bash
git add scripts/blog_content.py scripts/test_blog_content.py
git commit -m "feat(blog): parse validated markdown guides"
```

---

### Task 3: Generate Page Metadata, JSON-LD, Sitemap, and RSS

**Files:**
- Create: `site/blog/config.yaml`
- Create: `scripts/blog_render.py`
- Create: `scripts/test_blog_render.py`

- [ ] **Step 1: Write failing SEO/discovery tests**

```python
# scripts/test_blog_render.py
import json
import sys
import unittest
from datetime import date
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from blog_models import Article, ArticleMeta, Heading, SourceRef
from blog_render import article_schema, breadcrumb_schema, render_feed, render_sitemap


def article():
    meta = ArticleMeta(
        "Kuluçka Rehberi", "Gün gün kuluçka rehberi.", "kulucka-rehberi", "blog/kulucka-rehberi.html", "uretim",
        date(2026, 5, 15), date(2026, 6, 20), "BudgieBreedingTracker Editör Ekibi", None, True, True,
        (), (SourceRef("LafeberVet", "https://lafeber.com/vet/basic-information-sheet-for-the-parakeet/"),), None,
        "Kuluçka ve yumurta takibi",
    )
    return Article(meta, "<p>İçerik</p>", "İçerik", (Heading(2, "Hazırlık", "hazirlik"),), 1)


class TestSeoRendering(unittest.TestCase):
    def test_article_schema_matches_visible_metadata(self):
        data = article_schema(article(), "https://budgiebreedingtracker.online")
        self.assertEqual(data["@type"], "BlogPosting")
        self.assertEqual(data["url"], "https://budgiebreedingtracker.online/blog/kulucka-rehberi.html")
        self.assertNotIn("aggregateRating", json.dumps(data))

    def test_breadcrumbs_end_at_article(self):
        crumbs = breadcrumb_schema(article(), "https://budgiebreedingtracker.online")
        self.assertEqual(crumbs["itemListElement"][-1]["name"], "Kuluçka Rehberi")

    def test_sitemap_and_feed_include_canonical_url(self):
        url = "https://budgiebreedingtracker.online/blog/kulucka-rehberi.html"
        self.assertIn(url, render_sitemap([article()], [], "https://budgiebreedingtracker.online"))
        self.assertIn(url, render_feed([article()], "https://budgiebreedingtracker.online"))


if __name__ == "__main__":
    unittest.main(verbosity=2)
```

- [ ] **Step 2: Run and verify failure**

Run: `python3 scripts/test_blog_render.py`

Expected: `ModuleNotFoundError: No module named 'blog_render'`.

- [ ] **Step 3: Add explicit site configuration**

```yaml
# site/blog/config.yaml
site_name: BudgieBreedingTracker Rehberler
base_url: https://budgiebreedingtracker.online
publisher: BudgieBreedingTracker
publisher_logo: /logo.png
default_social_image: /og-image.png
app_store_url: https://apps.apple.com/app/id6759828211
google_play_url: https://play.google.com/store/apps/details?id=com.budgiebreeding.budgie_breeding_tracker
categories:
  uretim: Üretim
  beslenme: Beslenme
  genetik: Genetik
  saglik: Sağlık
static_pages:
  - {path: /, lastmod: 2026-06-20, priority: "1.0"}
  - {path: /user-guide/, lastmod: 2026-06-20, priority: "0.7"}
  - {path: /support/, lastmod: 2026-06-20, priority: "0.6"}
  - {path: /privacy-policy.html, lastmod: 2026-06-20, priority: "0.5"}
  - {path: /terms-of-use.html, lastmod: 2026-06-20, priority: "0.5"}
  - {path: /accessibility.html, lastmod: 2026-06-20, priority: "0.5"}
  - {path: /community-guidelines.html, lastmod: 2026-06-20, priority: "0.5"}
```

- [ ] **Step 4: Implement deterministic schema and XML renderers**

Implement the renderer with this exact data contract:

```python
import json
from pathlib import Path
import xml.etree.ElementTree as ET

from jinja2 import Environment, FileSystemLoader, select_autoescape

SITEMAP_NS = "http://www.sitemaps.org/schemas/sitemap/0.9"


def canonical_url(article, base_url):
    return f"{base_url.rstrip('/')}/{article.meta.output_path}"


def _jsonld(value):
    return json.dumps(value, ensure_ascii=False, separators=(",", ":")).replace("</", "<\\/")


def article_schema(article, base_url):
    return {
        "@context": "https://schema.org",
        "@type": "BlogPosting",
        "headline": article.meta.title,
        "description": article.meta.description,
        "datePublished": article.meta.published_at.isoformat(),
        "dateModified": article.meta.updated_at.isoformat(),
        "author": {"@type": "Organization", "name": article.meta.author},
        "publisher": {"@type": "Organization", "name": "BudgieBreedingTracker", "logo": {"@type": "ImageObject", "url": f"{base_url}/logo.png"}},
        "mainEntityOfPage": canonical_url(article, base_url),
        "url": canonical_url(article, base_url),
        "inLanguage": "tr",
    }


def breadcrumb_schema(article, base_url):
    items = [("Ana Sayfa", f"{base_url}/"), ("Rehberler", f"{base_url}/blog/"), (article.meta.title, canonical_url(article, base_url))]
    return {"@context": "https://schema.org", "@type": "BreadcrumbList", "itemListElement": [
        {"@type": "ListItem", "position": index, "name": name, "item": url}
        for index, (name, url) in enumerate(items, start=1)
    ]}


def collection_schema(articles, base_url):
    return {"@context": "https://schema.org", "@type": "CollectionPage", "name": "BudgieBreedingTracker Rehberler", "url": f"{base_url}/blog/", "mainEntity": {
        "@type": "ItemList", "itemListElement": [
            {"@type": "ListItem", "position": index, "url": canonical_url(article, base_url), "name": article.meta.title}
            for index, article in enumerate(articles, start=1)
        ]
    }}


def render_sitemap(articles, static_pages, base_url):
    ET.register_namespace("", SITEMAP_NS)
    root = ET.Element(f"{{{SITEMAP_NS}}}urlset")
    entries = [(item["path"], str(item["lastmod"]), item["priority"]) for item in static_pages]
    entries.append(("/blog/", max(article.meta.updated_at for article in articles).isoformat(), "0.9"))
    entries.extend((f"/{article.meta.output_path}", article.meta.updated_at.isoformat(), "0.8") for article in articles)
    for path, lastmod, priority in entries:
        node = ET.SubElement(root, f"{{{SITEMAP_NS}}}url")
        ET.SubElement(node, f"{{{SITEMAP_NS}}}loc").text = f"{base_url.rstrip('/')}{path}"
        ET.SubElement(node, f"{{{SITEMAP_NS}}}lastmod").text = lastmod
        ET.SubElement(node, f"{{{SITEMAP_NS}}}priority").text = priority
    return ET.tostring(root, encoding="unicode", xml_declaration=True)


def render_feed(articles, base_url):
    rss = ET.Element("rss", version="2.0")
    channel = ET.SubElement(rss, "channel")
    ET.SubElement(channel, "title").text = "BudgieBreedingTracker Rehberler"
    ET.SubElement(channel, "link").text = f"{base_url}/blog/"
    ET.SubElement(channel, "description").text = "Muhabbet kuşu üretimi, sağlığı, beslenmesi ve genetiği rehberleri."
    for article in sorted(articles, key=lambda item: item.meta.published_at, reverse=True):
        item = ET.SubElement(channel, "item")
        ET.SubElement(item, "title").text = article.meta.title
        ET.SubElement(item, "link").text = canonical_url(article, base_url)
        ET.SubElement(item, "guid", isPermaLink="true").text = canonical_url(article, base_url)
        ET.SubElement(item, "description").text = article.meta.description
    return ET.tostring(rss, encoding="unicode", xml_declaration=True)


def create_environment(template_dir):
    return Environment(loader=FileSystemLoader(template_dir), autoescape=select_autoescape(["html", "xml"]), trim_blocks=True, lstrip_blocks=True)


def render_article_page(environment, article, related, config):
    base_url = config["base_url"].rstrip("/")
    return environment.get_template("article.html.j2").render(
        article=article, related=related, config=config, page_title=f"{article.meta.title} — BudgieBreedingTracker",
        page_description=article.meta.description, canonical_url=canonical_url(article, base_url), og_type="article",
        social_image=f"{base_url}{config['default_social_image']}",
        schemas=[_jsonld(article_schema(article, base_url)), _jsonld(breadcrumb_schema(article, base_url))],
    )


def render_index_page(environment, articles, config):
    base_url = config["base_url"].rstrip("/")
    listed = [article for article in articles if article.meta.listed]
    return environment.get_template("index.html.j2").render(
        articles=listed, featured=next((item for item in listed if item.meta.featured), listed[0]), config=config,
        page_title="Blog ve Rehberler — BudgieBreedingTracker",
        page_description="Muhabbet kuşu üretimi, sağlığı, beslenmesi ve genetiği için kaynaklı rehberler.",
        canonical_url=f"{base_url}/blog/", og_type="website", social_image=f"{base_url}{config['default_social_image']}",
        schemas=[_jsonld(collection_schema(listed, base_url))],
    )
```

Schemas contain only visible fields and never emit `aggregateRating`, `offers`, or invented review data.

- [ ] **Step 5: Run renderer tests**

Run: `python3 -m unittest scripts.test_blog_render -v`

Expected: all schema, breadcrumb, sitemap, and RSS tests pass.

- [ ] **Step 6: Commit Task 3**

```bash
git add site/blog/config.yaml scripts/blog_render.py scripts/test_blog_render.py
git commit -m "feat(blog): generate metadata and discovery feeds"
```

---

### Task 4: Build the Editorial Hybrid Templates and Progressive Enhancement

**Files:**
- Create: `site/blog/templates/base.html.j2`
- Create: `site/blog/templates/index.html.j2`
- Create: `site/blog/templates/article.html.j2`
- Create: `site/blog/assets/blog.css`
- Create: `site/blog/assets/blog.js`
- Create: `scripts/test_blog_templates.py`

- [ ] **Step 1: Write failing template-contract tests**

Test a rendered fixture and assert all of the following in `scripts/test_blog_templates.py`:

```python
self.assertIn('<link rel="canonical" href="https://budgiebreedingtracker.online/blog/kulucka-rehberi.html">', html)
self.assertIn('class="article-disclaimer"', html)
self.assertIn('id="article-sources"', html)
self.assertIn('aria-label="İçindekiler"', html)
self.assertIn('href="/privacy-policy.html"', html)
self.assertIn('href="/support/"', html)
self.assertNotIn("gsap", html.lower())
self.assertNotIn("aggregateRating", html)
self.assertNotIn("setLanguage", html)
```

For the index fixture assert a visible search label, `aria-pressed` category controls, an `aria-live="polite"` result status, an initially hidden no-results panel, one featured guide, and all listed article links.

- [ ] **Step 2: Run the tests and verify template-not-found failures**

Run: `python3 scripts/test_blog_templates.py`

Expected: FAIL because the three Jinja templates do not exist.

- [ ] **Step 3: Implement the shared document shell**

`base.html.j2` must include this structural contract:

```html
<!doctype html>
<html lang="tr">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>{{ page_title }}</title>
  <meta name="description" content="{{ page_description }}">
  <link rel="canonical" href="{{ canonical_url }}">
  <meta property="og:type" content="{{ og_type }}">
  <meta property="og:title" content="{{ page_title }}">
  <meta property="og:description" content="{{ page_description }}">
  <meta property="og:url" content="{{ canonical_url }}">
  <meta property="og:image" content="{{ social_image }}">
  <meta name="twitter:card" content="summary_large_image">
  <link rel="alternate" type="application/rss+xml" title="BudgieBreedingTracker Rehberler" href="/blog/feed.xml">
  <link rel="stylesheet" href="/blog/assets/blog.css">
  {% for schema in schemas %}<script type="application/ld+json">{{ schema | safe }}</script>{% endfor %}
</head>
<body>
  <a class="skip-link" href="#main-content">İçeriğe geç</a>
  <header class="site-header">
    <a class="brand" href="/">BudgieBreedingTracker</a>
    <nav aria-label="Ana navigasyon">
      <a href="/blog/">Blog</a><a href="/blog/#topics">Konular</a><a href="/user-guide/">Kullanım Kılavuzu</a><a class="nav-cta" href="/#cta">Uygulamayı indir</a>
    </nav>
  </header>
  <main id="main-content">{% block content %}{% endblock %}</main>
  <footer class="site-footer">
    <nav aria-label="Yasal ve destek bağlantıları"><a href="/privacy-policy.html">Gizlilik</a><a href="/terms-of-use.html">Kullanım Koşulları</a><a href="/accessibility.html">Erişilebilirlik</a><a href="/community-guidelines.html">Topluluk Kuralları</a><a href="/support/">Destek</a></nav>
    <p>© 2025-2026 BudgieBreedingTracker</p>
  </footer>
  <script src="/blog/assets/blog.js" defer></script>
</body>
</html>
```

Do not render TR/EN/DE controls until real alternate-language article URLs exist.

- [ ] **Step 4: Implement index and article templates**

The index template renders: compact branded hero, labeled search, category button group, live result count, featured article, consistent article grid, no-results reset, trust statement, and store CTA. Every `.article-card` gets `data-title`, `data-description`, and `data-category` generated from typed metadata.

The article template renders: breadcrumbs, editorial metadata, disclaimer before high-stakes content, desktop/mobile TOC, body HTML, readable sources, contextual app feature, related guides, and final App Store/Google Play CTA. Use `<time datetime="YYYY-MM-DD">` for dates and real `<article>`/`<aside>`/`<nav>` landmarks.

- [ ] **Step 5: Implement the Editorial Hybrid CSS**

Define the selected visual system in `site/blog/assets/blog.css`:

```css
:root {
  --brand-950: #0d1c4a;
  --brand-800: #173b78;
  --brand-600: #315da8;
  --gold-400: #f5c842;
  --paper: #f7f9fc;
  --surface: #ffffff;
  --ink: #17244a;
  --muted: #65728a;
  --line: #dce4ef;
  --warning-bg: #fff8d9;
  --warning-line: #d8a51f;
  --focus: #f5c842;
}

body { margin: 0; color: var(--ink); background: var(--paper); font-family: system-ui, -apple-system, sans-serif; }
.reading-column { max-width: 72ch; }
:focus-visible { outline: 3px solid var(--focus); outline-offset: 3px; }
@media (prefers-reduced-motion: reduce) {
  *, *::before, *::after { scroll-behavior: auto !important; transition-duration: .01ms !important; animation-duration: .01ms !important; }
}
```

Keep all tap targets at least 44 px, body copy at least 16 px, and long-form line height between 1.65 and 1.8. Do not add glass blur, continuously floating elements, or hover-only information.

- [ ] **Step 6: Implement synchronous search/filter state**

```javascript
// site/blog/assets/blog.js
(() => {
  const cards = [...document.querySelectorAll('.article-card')];
  const search = document.querySelector('#guide-search');
  const filters = [...document.querySelectorAll('[data-category-filter]')];
  const status = document.querySelector('#guide-results-status');
  const empty = document.querySelector('#guide-empty');
  let category = 'all';

  const normalize = (value) => value.toLocaleLowerCase('tr-TR').trim();
  const apply = () => {
    const query = normalize(search?.value || '');
    let visible = 0;
    cards.forEach((card) => {
      const matchesCategory = category === 'all' || card.dataset.category === category;
      const haystack = normalize(`${card.dataset.title} ${card.dataset.description}`);
      const show = matchesCategory && (!query || haystack.includes(query));
      card.hidden = !show;
      if (show) visible += 1;
    });
    if (status) status.textContent = `${visible} rehber gösteriliyor`;
    if (empty) empty.hidden = visible !== 0;
  };

  search?.addEventListener('input', apply);
  filters.forEach((button) => button.addEventListener('click', () => {
    category = button.dataset.categoryFilter;
    filters.forEach((item) => item.setAttribute('aria-pressed', String(item === button)));
    apply();
  }));
  document.querySelector('#guide-reset')?.addEventListener('click', () => {
    if (search) search.value = '';
    category = 'all';
    filters.forEach((item) => item.setAttribute('aria-pressed', String(item.dataset.categoryFilter === 'all')));
    apply();
    search?.focus();
  });
  apply();
})();
```

Add similarly small handlers for the mobile menu and mobile TOC, preserving correct `aria-expanded` values.

- [ ] **Step 7: Run template tests and commit**

Run: `python3 scripts/test_blog_templates.py`

Expected: all template contract tests pass.

```bash
git add site/blog/templates site/blog/assets scripts/test_blog_templates.py
git commit -m "feat(blog): add editorial templates and interactions"
```

---

### Task 5: Add the Deterministic Builder and Output Audit

**Files:**
- Create: `scripts/build_blog.py`
- Create: `scripts/blog_validate.py`
- Create: `scripts/test_build_blog.py`
- Create: `scripts/test_blog_validate.py`

- [ ] **Step 1: Write failing builder and audit tests**

Use `tempfile.TemporaryDirectory()` fixtures to prove:

- duplicate slugs fail with both source paths in the message;
- missing related slugs fail;
- `build_site()` writes index, article, RSS, sitemap, CSS, and JavaScript;
- `--check` returns nonzero when a generated file differs;
- every article has a self-referencing canonical and exactly one H1;
- all root-relative internal links resolve within the output tree;
- JSON-LD parses and contains no `aggregateRating`;
- all listed articles appear in sitemap and RSS.

Include this drift assertion:

```python
result = compare_output(expected_dir, committed_dir)
self.assertEqual(result, ["blog/index.html differs"])
```

- [ ] **Step 2: Run tests and verify missing-module failures**

Run: `python3 -m unittest scripts.test_build_blog scripts.test_blog_validate -v`

Expected: FAIL because builder and validator modules do not exist.

- [ ] **Step 3: Implement the builder CLI**

Implement this orchestration in `scripts/build_blog.py`:

```python
import argparse
from datetime import date
import json
from pathlib import Path
import shutil
import tempfile

import yaml

from blog_content import load_article
from blog_models import ContentError
from blog_render import create_environment, render_article_page, render_feed, render_index_page, render_sitemap
from blog_validate import validate_generated_site

REPO_ROOT = Path(__file__).resolve().parents[1]


def discover_articles(content_dir, *, today):
    return [load_article(path, today=today) for path in sorted(content_dir.glob("*.md"))]


def validate_relationships(articles):
    by_slug = {}
    by_output = {}
    for article in articles:
        if article.meta.slug in by_slug:
            raise ContentError(f"duplicate slug: {article.meta.slug}")
        if article.meta.output_path in by_output:
            raise ContentError(f"duplicate output_path: {article.meta.output_path}")
        by_slug[article.meta.slug] = article
        by_output[article.meta.output_path] = article
    missing = sorted({slug for article in articles for slug in article.meta.related_slugs if slug not in by_slug})
    if missing:
        raise ContentError(f"missing related slugs: {', '.join(missing)}")


def _write(path, content):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content, encoding="utf-8")


def build_site(repo_root, output_root, *, today):
    source = repo_root / "site" / "blog"
    config = yaml.safe_load((source / "config.yaml").read_text(encoding="utf-8"))
    articles = discover_articles(source / "content", today=today)
    validate_relationships(articles)
    by_slug = {article.meta.slug: article for article in articles}
    environment = create_environment(source / "templates")
    owned = []
    for article in articles:
        related = [by_slug[slug] for slug in article.meta.related_slugs]
        path = output_root / article.meta.output_path
        _write(path, render_article_page(environment, article, related, config))
        owned.append(path)
    index = output_root / "blog" / "index.html"
    feed = output_root / "blog" / "feed.xml"
    sitemap = output_root / "sitemap.xml"
    _write(index, render_index_page(environment, articles, config))
    _write(feed, render_feed(articles, config["base_url"]))
    _write(sitemap, render_sitemap(articles, config["static_pages"], config["base_url"]))
    owned.extend([index, feed, sitemap])
    for name in ("blog.css", "blog.js"):
        target = output_root / "blog" / "assets" / name
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(source / "assets" / name, target)
        owned.append(target)
    manifest = output_root / "blog" / ".generated-files.json"
    previous = json.loads(manifest.read_text(encoding="utf-8")) if manifest.exists() else []
    current = sorted({path.relative_to(output_root).as_posix() for path in owned} | {"blog/.generated-files.json"})
    for stale in sorted(set(previous) - set(current)):
        stale_path = output_root / stale
        if stale_path.exists() and stale_path.is_file():
            stale_path.unlink()
    _write(manifest, json.dumps(current, ensure_ascii=False, indent=2) + "\n")
    owned.append(manifest)
    validate_generated_site(owned, output_root, articles, config["base_url"])
    return sorted(owned)


def compare_output(generated_root, committed_root):
    differences = []
    for generated in sorted(path for path in generated_root.rglob("*") if path.is_file()):
        relative = generated.relative_to(generated_root)
        committed = committed_root / relative
        if not committed.exists() or generated.read_bytes() != committed.read_bytes():
            differences.append(f"{relative.as_posix()} differs")
    return differences


def main(argv=None):
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args(argv)
    if not args.check:
        build_site(REPO_ROOT, REPO_ROOT / "docs", today=date.today())
        return 0
    with tempfile.TemporaryDirectory() as temp:
        generated = Path(temp) / "docs"
        shutil.copytree(REPO_ROOT / "docs", generated)
        build_site(REPO_ROOT, generated, today=date.today())
        differences = compare_output(generated, REPO_ROOT / "docs")
    if differences:
        print("\n".join(differences))
        return 1
    print("Blog output is up to date.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
```

The explicit returned path list is the ownership manifest, so the generator never deletes unrelated `docs/` files.

- [ ] **Step 4: Implement semantic output validation**

`scripts/blog_validate.py` uses Beautiful Soup and structured parsers, not regex, for HTML checks. Implement these checks:

```python
import json
from pathlib import Path
from urllib.parse import urlparse
import xml.etree.ElementTree as ET

from bs4 import BeautifulSoup

from blog_models import ContentError


def validate_html_file(path, output_root, base_url):
    soup = BeautifulSoup(path.read_text(encoding="utf-8"), "html.parser")
    errors = []
    canonicals = soup.select('link[rel="canonical"]')
    if len(canonicals) != 1:
        errors.append(f"{path}: expected one canonical")
    if len(soup.find_all("h1")) != 1:
        errors.append(f"{path}: expected one h1")
    for node in soup.select('script[type="application/ld+json"]'):
        try:
            data = json.loads(node.string or "")
        except json.JSONDecodeError as error:
            errors.append(f"{path}: invalid JSON-LD: {error}")
            continue
        serialized = json.dumps(data)
        if "aggregateRating" in serialized:
            errors.append(f"{path}: aggregateRating is not allowed")
    return errors


def validate_internal_links(paths, output_root):
    errors = []
    for path in paths:
        if path.suffix != ".html":
            continue
        soup = BeautifulSoup(path.read_text(encoding="utf-8"), "html.parser")
        for link in soup.select("a[href]"):
            href = link["href"]
            parsed = urlparse(href)
            if parsed.scheme or href.startswith(("mailto:", "tel:", "#")):
                continue
            target_path = parsed.path
            target = output_root / target_path.lstrip("/") if target_path.startswith("/") else path.parent / target_path
            target = target / "index.html" if target.suffix == "" else target
            if not target.resolve().is_relative_to(output_root.resolve()) or not target.exists():
                errors.append(f"{path}: broken internal link {href}")
    return errors


def validate_discovery_files(articles, sitemap, feed, base_url):
    sitemap_text = sitemap.read_text(encoding="utf-8")
    feed_text = feed.read_text(encoding="utf-8")
    ET.fromstring(sitemap_text)
    ET.fromstring(feed_text)
    errors = []
    for article in articles:
        url = f"{base_url.rstrip('/')}/{article.meta.output_path}"
        if url not in sitemap_text:
            errors.append(f"sitemap missing {url}")
        if url not in feed_text:
            errors.append(f"feed missing {url}")
    return errors


def validate_generated_site(paths, output_root, articles, base_url):
    errors = []
    for path in paths:
        if path.suffix == ".html":
            errors.extend(validate_html_file(path, output_root, base_url))
    errors.extend(validate_internal_links(paths, output_root))
    errors.extend(validate_discovery_files(articles, output_root / "sitemap.xml", output_root / "blog" / "feed.xml", base_url))
    if errors:
        raise ContentError("Generated blog validation failed:\n" + "\n".join(sorted(errors)))
```

If the deployed Python minimum lacks `Path.is_relative_to`, replace only that containment check with `target.resolve().relative_to(output_root.resolve())` inside `try/except ValueError`; keep the external behavior identical.

- [ ] **Step 5: Run unit tests and a fixture build**

Run: `python3 -m unittest scripts.test_build_blog scripts.test_blog_validate -v`

Expected: all tests pass and temporary directories are cleaned up.

- [ ] **Step 6: Commit Task 5**

```bash
git add scripts/build_blog.py scripts/blog_validate.py scripts/test_build_blog.py scripts/test_blog_validate.py
git commit -m "feat(blog): add deterministic site generator"
```

---

### Task 6: Migrate Production and Husbandry Guides

**Files:**
- Create: `site/blog/content/kulucka-sureci.md`
- Create: `site/blog/content/kulucka-rehberi.md`
- Create: `site/blog/content/yavru-gelisimi.md`
- Create: `site/blog/content/es-secimi.md`
- Create: `site/blog/content/kafes-secimi.md`
- Create: `scripts/test_blog_content_inventory.py`

- [ ] **Step 1: Write the failing inventory test**

Assert the five slugs exist, output paths match existing URLs, dates are not future-dated, each guide has at least three H2 sections, at least one source, and reciprocal related links resolve.

- [ ] **Step 2: Run and verify the missing-content failure**

Run: `python3 scripts/test_blog_content_inventory.py`

Expected: FAIL listing the five missing production/husbandry slugs.

- [ ] **Step 3: Author exact frontmatter and distinct search intent**

Use these titles and output paths:

| Slug | Output | Editorial intent |
| --- | --- | --- |
| `kulucka-sureci` | `blog/kulucka-sureci.html` | practical record-keeping workflow from laying through hatch |
| `kulucka-rehberi` | `blog/kulucka-rehberi.html` | detailed 18-day reference timeline |
| `yavru-gelisimi` | `blog/yavru-gelisimi.html` | observation milestones without rigid guarantees |
| `es-secimi` | `blog/es-secimi.html` | welfare-first readiness and compatible pairing |
| `kafes-secimi` | `blog/kafes-secimi.html` | cage dimensions, bar spacing, perches, and nest layout |

Every guide cites `https://lafeber.com/vet/basic-information-sheet-for-the-parakeet/`. Do not present 18 days, clutch size, development milestones, or cage dimensions as universal guarantees. Add the relevant app feature: breeding pair, incubation, egg, chick, reminder, or record tracking.

- [ ] **Step 4: Run inventory and content tests**

Run: `python3 -m unittest scripts.test_blog_content_inventory scripts.test_blog_content -v`

Expected: all five production/husbandry entries pass.

- [ ] **Step 5: Commit Task 6**

```bash
git add site/blog/content scripts/test_blog_content_inventory.py
git commit -m "content(blog): rewrite breeding and husbandry guides"
```

---

### Task 7: Migrate Nutrition and Health Guides

**Files:**
- Create: `site/blog/content/beslenme-programi.md`
- Create: `site/blog/content/kalsiyum-ve-kum.md`
- Create: `site/blog/content/tuy-dokumu.md`
- Create: `site/blog/content/hastalik-belirtileri.md`
- Modify: `scripts/test_blog_content_inventory.py`

- [ ] **Step 1: Extend the inventory test and verify failure**

Add assertions that all four slugs exist, health content has a disclaimer, every claim-bearing guide has at least two sources, and no content includes `hata payını sıfıra`, prescriptive drug doses, or a claim that grit is universally required. `reviewed_by` may be populated only with a real, verifiable qualified reviewer; otherwise it remains null and the template omits the reviewer line.

Run: `python3 scripts/test_blog_content_inventory.py`

Expected: FAIL listing the four missing slugs.

- [ ] **Step 2: Rewrite nutrition content from authoritative sources**

Use these sources:

- Merck Veterinary Manual, nutritional disorders: `https://www.merckvetmanual.com/bird-owners/disorders-and-diseases-of-birds/nutritional-disorders-of-pet-birds`
- LafeberVet parakeet sheet: `https://lafeber.com/vet/basic-information-sheet-for-the-parakeet/`

`kalsiyum-ve-kum.md` must explicitly correct the old claim: budgerigars hull seeds and generally do not require insoluble grit; excessive grit can create impaction risk. Explain calcium/phosphorus/vitamin D balance without prescribing supplements outside veterinary guidance.

- [ ] **Step 3: Rewrite illness and feather content with visible safeguards**

Use these sources:

- Merck, illness in pet birds: `https://www.merckvetmanual.com/bird-owners/routine-care-and-safety-of-birds/illness-in-pet-birds`
- Association of Avian Veterinarians signs-of-illness PDF: `https://www.aav.org/resource/resmgr/pdf_2019/AAV_Signs-of-Illness-in-Comp.pdf`
- Merck, skin and feather disorders: `https://www.merckvetmanual.com/bird-owners/disorders-and-diseases-of-birds/skin-and-feather-disorders-of-pet-birds`

Use this disclaimer verbatim in health frontmatter:

```yaml
disclaimer: Bu rehber tanı veya tedavi önerisi değildir. Solunum güçlüğü, kanama, nöbet, denge kaybı, yem yememe ya da kafes tabanında hareketsizlik gibi belirtilerde kuş hekimliği deneyimi olan bir veterinere gecikmeden başvurun.
```

Do not repeat the old unsourced instruction to heat every sick bird to a fixed temperature.

- [ ] **Step 4: Run inventory tests and commit**

Run: `python3 scripts/test_blog_content_inventory.py`

Expected: all nine migrated non-genetics guides pass.

```bash
git add site/blog/content scripts/test_blog_content_inventory.py
git commit -m "content(blog): rewrite nutrition and health guides"
```

---

### Task 8: Migrate Genetics Guides and the Authoritative Pillar

**Files:**
- Create: `site/blog/content/cinsiyet-ayrimi.md`
- Create: `site/blog/content/mutasyon-rehberi.md`
- Create: `site/blog/content/muhabbet-kusu-genetik-rehberi.md`
- Modify: `scripts/test_blog_content_inventory.py`
- Remove after migration: `docs/muhabbet-kusu-genetik-rehberi.md`

- [ ] **Step 1: Extend the inventory test and verify failure**

Require all three genetics slugs, genetics disclaimer text, correct output paths, and at least one WBO or MUTAVI source for each guide. Require the pillar output path to be `muhabbet-kusu-genetik-rehberi.html`.

Run: `python3 scripts/test_blog_content_inventory.py`

Expected: FAIL listing three missing genetics sources.

- [ ] **Step 2: Migrate the authoritative genetics source without losing citations**

Move the substantive body and all `[K1]` through `[K15]` references from `docs/muhabbet-kusu-genetik-rehberi.md` into the new frontmatter-backed source. Preserve WBO, MUTAVI, and OMIA URLs. Use this disclaimer:

```yaml
disclaimer: Genetik sonuçlar ebeveyn kayıtlarına dayalı olasılıklardır; yavru fenotipini garanti etmez. Tartışmalı veya hat bazında değişebilen mutasyonlar metinde ayrıca işaretlenir.
```

- [ ] **Step 3: Differentiate the supporting genetics guides**

- `mutasyon-rehberi.md`: beginner explanation of autosomal dominant, autosomal recessive, incomplete dominant, and sex-linked inheritance; link to the pillar for allele-series detail.
- `cinsiyet-ayrimi.md`: age, mutation, lighting, and individual variation caveats; never claim cere color is always definitive; direct ambiguous cases to an avian veterinarian or DNA sexing.

Primary references:

- WBO colour standards: `https://www.world-budgerigar.org/colourstds.htm`
- MUTAVI revised genes: `https://www.mutavi.info/index.php?art=symbols`
- MUTAVI sex chromosome: `https://www.mutavi.info/index.php?art=sexchrom`

- [ ] **Step 4: Run complete inventory tests and commit**

Run: `python3 scripts/test_blog_content_inventory.py`

Expected: twelve content sources pass; all related slugs resolve; no future dates exist.

```bash
git add site/blog/content scripts/test_blog_content_inventory.py
git rm docs/muhabbet-kusu-genetik-rehberi.md
git commit -m "content(blog): migrate genetics guides"
```

---

### Task 9: Generate and Audit the Complete Static Site

**Files:**
- Modify generated: `docs/blog/index.html`
- Modify generated: `docs/blog/*.html`
- Modify generated: `docs/muhabbet-kusu-genetik-rehberi.html`
- Create generated: `docs/blog/assets/blog.css`
- Create generated: `docs/blog/assets/blog.js`
- Create generated: `docs/blog/feed.xml`
- Create generated: `docs/blog/.generated-files.json`
- Modify generated: `docs/sitemap.xml`

- [ ] **Step 1: Run a check build and verify stale output is detected**

Run: `python3 scripts/build_blog.py --check`

Expected: exit `1` with stale/missing paths including `blog/index.html`, blog assets, RSS, sitemap, and article outputs.

- [ ] **Step 2: Generate the committed output**

Run: `python3 scripts/build_blog.py`

Expected: twelve article outputs, the blog index, two assets, RSS, and sitemap are written; no unrelated `docs/` file changes.

- [ ] **Step 3: Inspect generated-file buckets immediately**

Run: `git status --short --branch && git diff --name-status`

Expected: only owned blog outputs, sitemap, Task 9 source changes if any, and the preserved iOS change.

- [ ] **Step 4: Prove reproducibility and semantic validity**

Run: `python3 scripts/build_blog.py --check`

Expected: exit `0` with `Blog output is up to date.`

Run: `python3 -m unittest discover -s scripts -p "test_blog_*.py" -v`

Expected: all blog tests pass.

- [ ] **Step 5: Commit generated output separately**

```bash
git add docs/blog docs/muhabbet-kusu-genetik-rehberi.html docs/sitemap.xml
git commit -m "build(blog): regenerate editorial site"
```

---

### Task 10: Add Automated Desktop, Mobile, and No-JavaScript Browser Coverage

**Files:**
- Create: `site/blog/package.json`
- Create: `site/blog/package-lock.json`
- Create: `site/blog/playwright.config.mjs`
- Create: `site/blog/tests/blog.spec.mjs`

- [ ] **Step 1: Create the Playwright package and lockfile**

```json
{
  "name": "budgie-breeding-tracker-blog-tests",
  "private": true,
  "type": "module",
  "scripts": {"test": "playwright test"},
  "devDependencies": {"@playwright/test": "1.61.0"}
}
```

Run: `npm install --prefix site/blog`

Expected: `site/blog/package-lock.json` pins Playwright 1.61.0.

- [ ] **Step 2: Write browser tests before browser refinements**

```javascript
// site/blog/tests/blog.spec.mjs
import { test, expect } from '@playwright/test';

test('index search, filter, empty state, metadata, and console are clean', async ({ page }) => {
  const errors = [];
  page.on('console', (message) => { if (message.type() === 'error') errors.push(message.text()); });
  await page.goto('/blog/');
  await expect(page).toHaveTitle(/Blog|Rehber/);
  await expect(page.locator('link[rel="canonical"]')).toHaveAttribute('href', 'https://budgiebreedingtracker.online/blog/');
  await expect(page.locator('.article-card')).toHaveCount(12);
  await page.getByLabel('Rehberlerde ara').fill('kalsiyum');
  await expect(page.locator('.article-card:visible')).toHaveCount(1);
  await page.getByLabel('Rehberlerde ara').fill('bulunmayan ifade');
  await expect(page.getByRole('status')).toContainText('0 rehber');
  await expect(page.getByText('Sonuç bulunamadı')).toBeVisible();
  await page.getByRole('button', { name: 'Aramayı temizle' }).click();
  await page.getByRole('button', { name: 'Genetik' }).click();
  await expect(page.locator('.article-card:visible')).toHaveCount(3);
  expect(errors).toEqual([]);
});

test('health article exposes disclaimer, sources, self canonical, and no fake rating', async ({ page }) => {
  await page.goto('/blog/hastalik-belirtileri.html');
  await expect(page.getByRole('heading', { level: 1 })).toBeVisible();
  await expect(page.locator('.article-disclaimer')).toBeVisible();
  await expect(page.locator('#article-sources')).toBeVisible();
  await expect(page.locator('link[rel="canonical"]')).toHaveAttribute('href', 'https://budgiebreedingtracker.online/blog/hastalik-belirtileri.html');
  await expect(page.locator('script[type="application/ld+json"]')).not.toContainText('aggregateRating');
});

test('mobile navigation and table of contents preserve expanded state', async ({ page }) => {
  await page.setViewportSize({ width: 390, height: 844 });
  await page.goto('/blog/kulucka-rehberi.html');
  const menu = page.getByRole('button', { name: 'Menüyü aç' });
  await menu.click();
  await expect(menu).toHaveAttribute('aria-expanded', 'true');
  const toc = page.getByRole('button', { name: 'İçindekileri aç' });
  await toc.click();
  await expect(toc).toHaveAttribute('aria-expanded', 'true');
});

test('core content remains available without JavaScript', async ({ browser }) => {
  const context = await browser.newContext({ javaScriptEnabled: false });
  const page = await context.newPage();
  await page.goto('/blog/');
  await expect(page.locator('.article-card')).toHaveCount(12);
  await page.goto('/blog/hastalik-belirtileri.html');
  await expect(page.locator('article')).toContainText('veteriner');
  await context.close();
});
```

- [ ] **Step 3: Add deterministic browser configuration**

```javascript
// site/blog/playwright.config.mjs
import { defineConfig, devices } from '@playwright/test';

export default defineConfig({
  testDir: './tests',
  fullyParallel: false,
  retries: 0,
  reporter: 'line',
  use: { baseURL: 'http://127.0.0.1:4173', trace: 'retain-on-failure' },
  webServer: {
    command: 'python3 -m http.server 4173 --directory ../../docs',
    url: 'http://127.0.0.1:4173/blog/',
    reuseExistingServer: true,
  },
  projects: [
    { name: 'chromium', use: { ...devices['Desktop Chrome'] } },
  ],
});
```

- [ ] **Step 4: Install Chromium and run browser tests**

Run: `npx --prefix site/blog playwright install chromium`

Run: `npm test --prefix site/blog -- --config=playwright.config.mjs`

Expected: all four tests pass with no console errors.

- [ ] **Step 5: Commit Task 10**

```bash
git add site/blog/package.json site/blog/package-lock.json site/blog/playwright.config.mjs site/blog/tests/blog.spec.mjs
git commit -m "test(blog): cover editorial browser flows"
```

---

### Task 11: Wire CI Gates and Update the Required Rule Contract

**Files:**
- Modify: `.github/workflows/ci.yml`
- Modify: `.claude/rules/ci-actions.md`
- Modify: `.github/pull_request_template.md`

- [ ] **Step 1: Add Python dependency and reproducibility gates to `scripts-test`**

Replace the coverage-only install step with:

```yaml
- name: Install script dependencies
  run: python -m pip install coverage -r scripts/requirements_blog.txt
```

After the coverage step add:

```yaml
- name: Verify generated blog output
  run: python scripts/build_blog.py --check
```

- [ ] **Step 2: Add a dedicated browser job**

```yaml
blog-browser-test:
  name: Blog Browser Test
  runs-on: ubuntu-24.04
  timeout-minutes: 15
  steps:
    - uses: actions/checkout@de0fac2e4500dabe0009e67214ff5f5447ce83dd # v6
    - uses: actions/setup-node@48b55a011bda9f5d6aeb4c2d9c7362e8dae4041e # v6
      with:
        node-version: "24"
        cache: npm
        cache-dependency-path: site/blog/package-lock.json
    - name: Install browser test dependencies
      run: npm ci --prefix site/blog
    - name: Install Chromium
      run: npx --prefix site/blog playwright install --with-deps chromium
    - name: Run blog browser tests
      run: npm test --prefix site/blog -- --config=playwright.config.mjs
```

The pinned SHA above resolves to upstream `actions/setup-node` tag `v6`; do not substitute a floating version tag.

- [ ] **Step 3: Update rule and PR documentation in the same change**

Add `blog-browser-test` and blog reproducibility to the CI job table in `.claude/rules/ci-actions.md`. Add these checklist lines to `.github/pull_request_template.md`:

```markdown
- [ ] Blog kaynakları/şablonları değiştiyse `python3 scripts/build_blog.py --check` başarılı
- [ ] Blog UI değiştiyse `npm test --prefix site/blog -- --config=playwright.config.mjs` başarılı
```

- [ ] **Step 4: Validate YAML and run the affected gates**

Run: `ruby -e 'require "yaml"; YAML.load_file(ARGV.fetch(0))' .github/workflows/ci.yml`

Expected: exit `0` and no YAML exception.

Run: `python3 -m unittest discover -s scripts -p "test_*.py" --failfast`

Expected: all script tests pass with no skip.

Run: `python3 scripts/build_blog.py --check`

Expected: output is current.

- [ ] **Step 5: Commit Task 11**

```bash
git add .github/workflows/ci.yml .claude/rules/ci-actions.md .github/pull_request_template.md
git commit -m "ci(blog): verify generated site and browser flows"
```

---

### Task 12: Run Full Verification and Prepare the Handoff

**Files:**
- No planned source changes; only fix failures directly caused by this work.

- [ ] **Step 1: Inspect unstaged and staged scope before verification**

Run: `git status --short --branch && git diff --name-status && git diff --cached --name-status`

Expected: the pre-existing iOS file may remain modified; no task-owned file is unintentionally unstaged.

- [ ] **Step 2: Run generator and Python gates**

Run: `python3 scripts/build_blog.py --check`

Run: `python3 -m unittest discover -s scripts -p "test_*.py" -v --failfast`

Run: `python3 scripts/verify_code_quality.py`

Run: `python3 scripts/check_l10n_sync.py`

Expected: every command exits `0`; no tests are skipped.

- [ ] **Step 3: Run browser and visual checks**

Run: `npm test --prefix site/blog -- --config=playwright.config.mjs`

Expected: all Chromium tests pass.

Run a local server in terminal A:

```bash
python3 -m http.server 4173 --directory docs
```

While it is running, run Lighthouse in terminal B:

```bash
npx --yes lighthouse@13.4.0 http://127.0.0.1:4173/blog/ --only-categories=performance,accessibility,seo --chrome-flags="--headless" --output=json --output-path=output/playwright/blog-lighthouse.json
```

Expected: LCP is below 2500 ms and CLS below 0.1. Record Lighthouse's lab responsiveness metric and separately use the Playwright search/filter interactions to confirm no visible input delay; INP remains a field target and must not be claimed as laboratory-measured.

Use the in-app Browser first for final visual QA at desktop `1440x900` and mobile `390x844`. Verify index hero density, filter visibility, article reading width, mobile menu, mobile TOC, disclaimer prominence, source links, and store CTAs. Capture screenshots under `output/playwright/` only when evidence is useful.

- [ ] **Step 4: Run repository-wide gates required for substantial changes**

Run: `flutter analyze --no-fatal-infos`

Run: `flutter test`

Run: `scripts/run_local_quality_gate.sh`

Expected: all commands pass. If any pre-existing failure is unrelated, record the exact command, failure, and evidence instead of modifying unrelated Flutter code.

- [ ] **Step 5: Audit skips and generated drift**

Run: `rg -n "skip:|@Skip|pytest.mark.skip|test.skip" scripts site/blog`

Expected: no task-introduced skipped tests.

Run: `python3 scripts/build_blog.py --check && git diff --check`

Expected: generated output is current and no whitespace errors exist.

- [ ] **Step 6: Inspect final scope and commit only necessary fixes**

Run: `git diff --name-status && git diff --cached --name-status && git status --short --branch`

If verification required task-owned fixes, stage only those explicit paths and commit:

```bash
git commit -m "fix(blog): resolve final verification findings"
```

Do not stage `ios/Runner.xcodeproj/project.pbxproj`.

- [ ] **Step 7: Handoff evidence**

Report current branch and commit, the preserved iOS dirty state, every command run, browser viewport coverage, generated-output status, and any intentionally pending or skipped check. Do not push unless the user explicitly requests it.
