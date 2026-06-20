# BudgieBreedingTracker Blog Platform Redesign

**Date:** 2026-06-20
**Status:** Approved design
**Scope:** `docs/blog/`, blog-specific shared assets, content generation, SEO discovery files, and blog verification tooling

## 1. Objective

Redesign and rebuild the BudgieBreedingTracker blog as a trustworthy, fast, accessible editorial product that serves three goals together:

1. Grow organic search traffic with technically correct, substantive content.
2. Build reader trust through sourced and clearly reviewed breeding, health, nutrition, and genetics guidance.
3. Convert relevant readers to App Store and Google Play downloads without interrupting the reading experience.

The selected visual direction is **Editorial Hybrid**: retain the dark blue and gold BudgieBreedingTracker brand shell while using a light, high-contrast editorial surface for discovery and long-form reading.

## 2. Current-State Audit

The live site at `https://budgiebreedingtracker.online/blog/` matches the repository's `docs/blog/index.html` byte-for-byte as of the audit.

### Critical Findings

- The blog index and most articles declare the site root as canonical, preventing correct page-level indexing.
- Blog pages reuse homepage `SoftwareApplication` and `FAQPage` structured data instead of page-specific blog schemas.
- The reused schema contains unverified ratings, rating counts, prices, screenshots, and claims that conflict with the site's own documentation standards.
- Client-side language initialization replaces the blog page title with the homepage title.
- Most articles are about 95 KB and the blog index is about 118 KB because homepage scripts and translations are copied into every page.
- The inherited homepage scripts raise a runtime error and 22 GSAP warnings on the blog index.
- `docs/sitemap.xml` lists only one blog article although the index exposes ten guides.
- Legal, accessibility, support, and user-guide links in blog footers resolve under `/blog/` and return incorrect paths.
- Search and category filters are inconsistent: cards have missing or incorrect category metadata, timed hide/show transitions can race, and there is no empty state or result count.
- Several articles use future publication dates, generic metadata, thin content, unsupported certainty, or medical advice without sufficient sourcing and editorial safeguards.
- The TR/EN/DE controls imply translated blog content even though article content is Turkish-only.

### Visual and UX Findings

- The existing dark brand language is recognizable, but the hero consumes too much vertical space before the first useful content.
- Long-form articles inherit an application landing-page visual system that is not optimized for sustained reading.
- Decorative animation and large inline SVG illustrations outweigh the editorial value they provide.
- Cards added at different times use inconsistent metadata, author, reading-time, and CTA patterns.

## 3. Product Principles

- **Trust before conversion:** content accuracy and transparency are prerequisites for download CTAs.
- **Static by default:** every article must remain readable, navigable, and indexable without JavaScript.
- **One source of truth:** article content and metadata live in Markdown, not duplicated HTML.
- **Progressive enhancement:** search, filters, and mobile navigation enhance a complete server-rendered document.
- **Preserve public URLs:** existing article paths remain stable to avoid link and search equity loss.
- **No unverifiable claims:** ratings, audience size, medical certainty, and guarantees require authoritative evidence or removal.

## 4. Content Architecture

### Source Format

Each guide is stored as Markdown with validated frontmatter:

- `title`
- `description`
- `slug`
- `category`
- `publishedAt`
- `updatedAt`
- `author`
- `reviewedBy` when applicable
- `readingLevel` or guide type where useful
- `featured`
- `relatedSlugs`
- `sources`
- `medicalDisclaimer` or `geneticsDisclaimer` flags
- contextual application feature and CTA metadata

The initial migration covers all ten guides currently linked from the blog index. Existing slugs and public URLs remain unchanged.

### Taxonomy

The primary categories remain:

- Uretim
- Beslenme
- Genetik
- Saglik

Category labels are centralized in the generator rather than repeated in page markup. Articles may have secondary topic tags for internal linking, but the index filter uses one primary category per article.

### Editorial Standard

- All ten guides are rewritten or materially expanded; thin copy is not migrated unchanged.
- Health and genetics claims cite reputable primary or institutional references where available.
- Health articles distinguish observation, first-response record keeping, and veterinary diagnosis. They include a visible avian-veterinarian disclaimer.
- Genetics articles distinguish probability from guaranteed outcome and align with the project's authoritative MUTAVI guidance.
- Each article shows a real editorial identity, publication date, and meaningful update date.
- Future publication dates are rejected unless scheduled publishing is deliberately introduced later.
- Sources are displayed as a readable bibliography, not hidden only in structured data.

## 5. Generation Architecture

### Pipeline

1. Read and validate Markdown frontmatter.
2. Render sanitized article HTML through shared templates.
3. Calculate reading time, breadcrumbs, related content, and topic relationships.
4. Generate the blog index, article pages, sitemap entries, and RSS feed.
5. Validate metadata, internal links, dates, slugs, and structured data.
6. Write static files under `docs/` for the existing GitHub Pages deployment.

The generator is a Python 3 script under `scripts/`, matching the repository's existing verification tooling. It uses pinned, purpose-built Markdown and YAML parser dependencies rather than ad hoc string parsing. Content and templates live outside the published output tree; generated HTML is written to `docs/blog/` and committed because the existing Pages workflow uploads `docs/` without a build step. A reproducibility check fails when committed HTML, sitemap, or RSS output is stale relative to sources. The design does not add a client-side framework, runtime CMS, or server dependency.

### Templates and Assets

The generator owns two primary templates:

- **Blog index:** branded hero, search, category filters, featured article, article grid, topic clusters, trust statement, and restrained store CTA.
- **Article:** breadcrumb, article header, editorial metadata, optional disclaimer, table of contents, content body, sources, contextual application feature, related guides, and final store CTA.

Blog-specific CSS and JavaScript are shared files. Homepage translations, genetic demo code, GSAP, ScrollTrigger, pricing logic, and unrelated landing-page behavior are not loaded on blog pages.

## 6. Experience Design

### Blog Index

- Keep a compact dark branded hero with a clear value statement.
- Place visible, labeled search immediately after the heading.
- Expose topic filters with `aria-pressed`, result count, and keyboard-operable controls.
- Show one featured guide followed by a consistent card system.
- Every card includes category, title, description, reading time, publication/update status, and editorial identity.
- No-results state explains the result, offers a clear reset action, and suggests categories.

### Article Page

- Use a light reading canvas within the branded dark shell.
- Keep line length, typography, and spacing suitable for long-form reading.
- Desktop uses a restrained sticky table of contents; mobile uses a collapsible table of contents.
- Display category, reading time, author/editor, publication date, and update date near the title.
- Place disclaimers before content that could be interpreted as diagnosis or certainty.
- Use contextual product cards only where the app feature directly supports the article task.
- End with related guides and a single clear App Store/Google Play CTA.

### Navigation and Language

- Blog navigation prioritizes Blog, Topics, User Guide, and Download rather than repeating the full marketing navigation.
- Turkish is the only selectable blog language until complete English or German article variants exist.
- If localized articles are added later, language controls must map to real alternate URLs and emit correct `hreflang` links.

## 7. SEO Contract

Every generated page must have:

- unique title and meta description
- self-referencing canonical URL
- accurate Open Graph and Twitter metadata
- correct `og:type`
- page-specific social image or documented fallback
- crawlable headings and internal links
- valid JSON-LD matching visible page content

The index uses `CollectionPage` and `ItemList` where appropriate. Articles use `Article` or `BlogPosting` plus `BreadcrumbList`. `FAQPage` is emitted only when the visible article contains an actual FAQ section that qualifies for the schema.

The build updates:

- `docs/sitemap.xml` with all canonical article URLs and meaningful `lastmod` dates
- a blog RSS feed
- internal related-article links

Unverified aggregate ratings, rating counts, prices, download counts, and unsupported product claims are removed.

## 8. Conversion Design

Conversion elements remain subordinate to editorial intent:

- one download action in the blog navigation
- an optional contextual feature card in an article body
- one final store CTA after the article and related-reading section
- trackable App Store and Google Play links with documented UTM parameters

Health content must not position the app as a diagnostic tool. Genetics content must not claim guaranteed offspring outcomes. CTA copy describes record keeping, reminders, breeding lifecycle tracking, and probability-based planning accurately.

## 9. Accessibility and Resilience

- WCAG AA color contrast for text and interactive controls.
- Minimum 44 px touch targets for primary mobile actions.
- Visible keyboard focus and logical heading order.
- Search has a visible label, status announcement, and result count.
- Filters expose selected state semantically.
- Decorative SVGs are hidden from assistive technology; meaningful images have useful alternative text.
- Reduced-motion preferences disable nonessential transitions.
- Core navigation, article content, source links, related links, and CTAs work without JavaScript.

## 10. Error Handling

The generator fails with an actionable message for:

- missing required frontmatter
- duplicate slugs or output paths
- invalid or future dates
- unknown categories
- missing related articles
- malformed source entries
- broken internal links
- invalid structured-data serialization

Client-side search and filtering do not use delayed hide/show timers. A single synchronous state calculation controls card visibility, result count, selected filter, and the empty state.

If enhancement JavaScript fails, all articles remain visible and all links remain usable.

## 11. Verification Strategy

### Automated Checks

- unit tests for frontmatter validation, slug uniqueness, reading time, related articles, and schema generation
- snapshot or focused output tests for index and article templates
- HTML validation
- internal link and asset checks
- sitemap and RSS completeness checks
- JSON-LD parsing and required-field checks
- checks preventing root canonical URLs on article pages and unverified rating schema

### Browser Checks

Playwright verifies desktop and mobile behavior for:

- page load without console errors
- search, filter, result count, reset, and empty state
- mobile navigation and table of contents
- keyboard navigation and visible focus
- App Store and Google Play CTA destinations
- article-to-related-article navigation
- JavaScript-disabled readability
- reduced-motion behavior

### Performance Targets

- LCP below 2.5 seconds
- CLS below 0.1
- INP below 200 milliseconds
- no GSAP or homepage application scripts on blog pages
- shared cacheable CSS and JavaScript rather than repeated inline bundles

## 12. Rollout and Compatibility

1. Introduce the generator, templates, and validation with fixture content.
2. Migrate all ten existing guides to Markdown while preserving slugs.
3. Generate the index, articles, sitemap, and RSS feed.
4. Run content, accessibility, link, structured-data, and browser checks.
5. Verify generated HTML, sitemap, and RSS are reproducible and commit the generated artifacts with their sources.
6. Compare representative live and generated pages on desktop and mobile.
7. Publish through the existing GitHub Pages workflow without changing its deployment model.
8. Verify canonical URLs, sitemap availability, console cleanliness, and store links after deployment.

No redirect migration is required because existing public article URLs are preserved.

## 13. Out of Scope

- external CMS administration
- comments, user accounts, or dynamic personalization on the blog
- server-side search
- automatic machine translation
- medical diagnosis, treatment prescriptions, or veterinary substitution
- changes to the Flutter application's data or feature architecture

## 14. Acceptance Criteria

The redesign is complete when:

- all ten existing guides are sourced from validated Markdown and generated successfully
- the selected Editorial Hybrid design is responsive and consistent across index and article templates
- every page has correct canonical, social metadata, and visible-content-matching structured data
- sitemap and RSS include all published guides
- all blog footer, legal, support, user-guide, store, and related-article links resolve correctly
- search and filters work accessibly with a clear empty state
- articles contain appropriate sources, editorial identity, dates, and disclaimers
- blog pages load without console errors or inherited homepage warnings
- automated checks and representative desktop/mobile browser checks pass
- pre-existing non-blog worktree changes remain untouched
