# Marketing Site

Source: `docs/index.html`, `docs/style.css`, `docs/CNAME`, `docs/sitemap.xml`

GitHub Pages serves the public product site from `docs/` at
`https://budgiebreedingtracker.online/`.

## Key Files

| File | Purpose |
|------|---------|
| `docs/index.html` | Main landing page, sections, inline translations, demo scripts |
| `docs/style.css` | Shared landing-page styles and responsive/performance rules |
| `docs/CNAME` | Custom domain |
| `docs/sitemap.xml` / `docs/robots.txt` | SEO discovery |
| `docs/app-ads.txt` | AdMob authorized-sellers (IAB `app-ads.txt`) verification for the AdMob publisher |
| `docs/support/`, `docs/user-guide/` | Support and guide landing pages |
| `store/release_notes/` | Canonical TR/EN/DE store-note sources; generated into the public release history |
| `scripts/generate_release_notes_site.py` | Renders `docs/release-notes/`, `docs/en/release-notes/`, and `docs/de/release-notes/`; `--check` rejects stale output |

## Landing Page Behavior

- Main navigation links to in-page anchors: `#features`, `#genetics-demo`, `#screenshots`, `#pricing`, `#faq`, `#cta`.
- Language switcher is inline JS-backed for `tr`, `en`, `de`; it updates `document.documentElement.lang`, text keys, placeholders, page title, and `aria-pressed` state.
- Language changes on `/en/` and `/de/` redirect to the matching localized
  homepage root (or `/` for Turkish); the URL, canonical locale, and rendered
  language must not diverge. User-driven switching becomes active immediately
  after the initial DOM locale pass; it must not wait for `window.load` or
  third-party CDN assets. `js/i18n.js` is the only locale initializer; landing
  pages must not add a second browser-language `DOMContentLoaded` pass that can
  bounce an explicit locale URL.
- The localized desktop navigation switches to the hamburger below `1200px`.
  This header-only breakpoint prevents the full German/English labels
  from colliding at tablet widths without changing the page's `768px` content
  layout breakpoint. The JS resize close guard must stay at `1200px`.
- Mobile menu uses explicit `aria-hidden`, `aria-expanded`, and language-aware open/close labels.
- Mobile menu behaves as a modal dialog on narrow screens: opening it locks body
  scroll, moves focus to the first link, traps Tab navigation, supports Escape,
  and restores focus to the hamburger button when closed.
- FAQ buttons keep `aria-expanded` and each answer's `aria-hidden` in sync, and
  close previously opened items. The `<noscript>` fallback expands all answers.
- The second screenshot set exists only for the infinite carousel animation and
  stays `aria-hidden="true"`, so screen readers announce each screenshot once.
- Header, language, demo, pricing, footer, and social controls use the shared
  `48px` touch-target contract from `accessibility.md`.
- Email signup posts to FormSubmit, exposes localized loading/success/error
  status through an `aria-live` region, and never reports success when the
  network request fails.

## User Guide Interaction Contract

`docs/user-guide/index.html` renders category filters, searchable topic cards,
detail dialogs, and screenshot lightboxes from inline TR/EN/DE data.

- Topic cards and screenshot frames are native buttons; do not replace them
  with click-only containers. Category and language buttons expose
  `aria-pressed` state.
- Emoji values are stored as Unicode characters. Entity strings such as
  `&#x1F426;` are escaped by the renderer and therefore leak as visible text.
- Breadcrumbs, search controls, dialog controls, skip links, version labels,
  and lightbox labels switch with the active language.
- Opening a dialog moves focus to its close control. Escape closes the topmost
  layer only: first the screenshot lightbox, then the topic detail. Each close
  restores focus to the control that opened that layer.
- Hidden dialogs and the scroll-to-top control stay out of the accessibility
  tree. Visible interactive targets follow the 48px contract.

## Localized Legal Page Contract

The privacy and terms pages have canonical TR/EN/DE paths. Legal-page language
selection must not silently cross those path boundaries.

- Explicit `/en/` and `/de/` terms URLs take precedence over a stale
  `bbt-lang` value. The root terms page may honor the saved/browser language.
- The terms-to-privacy link follows the active language and uses the matching
  canonical path (`/privacy-policy.html`, `/en/...`, or `/de/...`).
- Language, home, version, and skip-link labels are localized; language buttons
  keep `aria-pressed` synchronized and provide 48px touch targets.
- Translated development annotations belong in HTML comments. Bare labels must
  never appear as visible text or create horizontal overflow.
- Every page that loads shared `js/i18n.js` uses the same dated query version;
  bump all references together when locale routing changes so returning users
  cannot keep stale redirect behavior from the browser cache.

## Anchor Navigation

`#genetics-demo` has a dedicated hash recovery path:

- `window.bbtScrollToCurrentHash` resolves the target element from `location.hash`.
- It activates reveal elements inside the target and clears GSAP inline transform/opacity state.
- It scrolls with a navbar offset so direct links land on the actual section, not behind the fixed nav.
- The function is scheduled after DOMContentLoaded and after GSAP/magnetic button setup to handle late inline styles.

This exists because a direct page load to `/#genetics-demo` can otherwise leave the page at the hero while the URL hash is correct, or keep the demo card invisible due to animation inline styles.

## Genetics Mini Demo

The marketing page includes a visual-only simplified genetics demo:

- Controls: `#gd-mother`, `#gd-father`
- Results container: `#gd-grid`
- Note container: `#gd-note`
- Calculation function: `calcGenetics()`

The demo intentionally does not mirror the full in-app genetics engine. It is a marketing preview with 6 visible mutation options and simplified percentages. Full genetics behavior remains in the Flutter app and domain genetics engine.
Rendered result labels, SVG labels, and mutation notes must resolve through the
active `tr`/`en`/`de` translation table; do not read the Turkish fallback
`MUTATIONS.label`/`note` fields directly in the result renderer.

## SEO And Store Links

- Canonical and OpenGraph URL use the trailing-slash homepage URL.
- JSON-LD `SoftwareApplication.installUrl` must match the visible Google Play CTA package:
  `com.budgiebreeding.budgie_breeding_tracker`.
- JSON-LD offers must match the visible pricing cards. Do not publish an
  `aggregateRating` unless the rating value and count can be verified from a
  public store/source.
- App Store CTA points to App ID `6759828211`.
- `docs/app-ads.txt` publishes the AdMob authorized-seller line
  (`google.com, pub-4121152941965334, DIRECT, f08c47fec0942fa0`) at the domain
  root. AdMob crawls `https://budgiebreedingtracker.online/app-ads.txt` to verify
  both linked apps (Android + iOS) and lift the "limited ad serving" restriction.
  The publisher ID must match `ca-app-pub-4121152941965334` used in
  `lib/domain/services/ads/ad_service.dart`.

## Performance Notes

- `style.css` and `js/i18n.js` are cache-busted from the HTML
  (`?v=YYYYMMDD[-revision]`) when deploy-sensitive visual or copy fixes need
  immediate propagation.
- Mobile disables expensive entrance/float/glow animations for the hero path so first content is readable immediately.
- Desktop keeps the decorative curtain to `180ms` and completes the hero/CTA
  entrance in roughly `700ms`; do not reintroduce a long blank first paint.
- Keep decorative animations non-blocking; anchor targets and CTAs must remain usable without waiting for GSAP.

## QA Checklist

- Run `python3 scripts/test_marketing_site.py` for local asset, JSON-LD,
  heading, carousel, breakpoint, touch-target, FAQ ARIA, user-guide dialog,
  localized legal-page, and security-copy contracts across all public HTML files.
- Run `python3 scripts/generate_release_notes_site.py --check`; every
  `pubspec.yaml` semantic version must have complete TR/EN/DE source notes and
  matching generated pages. Update pages only through `--write`.
- Open `https://budgiebreedingtracker.online/` at `375`, `768`, `1024`, and
  `1200`, and `1440px`; confirm there is no horizontal overflow and the
  hamburger is used below `1200px`.
- Open `https://budgiebreedingtracker.online/#genetics-demo` directly; the demo controls and result cards should be visible after load.
- Change mother/father mutation options and verify the result grid updates.
- Open the mobile menu and verify `aria-hidden=false`, hamburger `aria-expanded=true`.
- While the mobile menu is open, verify focus starts on the first link, Tab is
  trapped, Escape closes it, body scroll unlocks, and focus returns to the
  hamburger button.
- Toggle an FAQ item and verify `aria-expanded=true` plus answer
  `aria-hidden=false`; closing it must restore `aria-hidden=true`.
- Verify the duplicate screenshot track is absent from the accessibility tree,
  heading levels do not skip, and interactive controls are at least `48x48px`.
- Simulate a failed email subscription request and verify the form remains
  available with a localized error instead of a success message.
- In the user guide, open a topic screenshot and press Escape twice; the first
  press must close only the lightbox, the second must close the detail dialog,
  with focus restored after both actions.
- Save a conflicting `bbt-lang`, then open `/en/terms-of-use.html` and
  `/de/terms-of-use.html`; each URL must retain its own locale, link to the
  same-locale privacy page, and fit a 375px viewport without horizontal scroll.
- Run `python3 scripts/check_remote_status.py` after push; Pages deploy status must match the exact commit.

## Security Copy Accuracy

Marketing copy must describe the implemented boundary precisely on every public
page, including homepage JSON-LD, blog/genetics FAQ schema, support, and privacy
policy variants. Selected sensitive bird fields use AES-256-CBC + HMAC through
the device-key encryption service; optional backups can use the same primitive.
The SQLite database as a whole is not encrypted. Do not claim that every synced
field is end-to-end encrypted or that only the account owner can ever access
cloud data: account- and role-based RLS/storage policies are a separate control.
`scripts/test_marketing_site.py` rejects these blanket claims across TR/EN/DE.
The privacy page's post-section-10 blocks are shared through
`docs/js/privacy-extra-i18n.js`; keep community, marketplace, messaging, local
AI, grace-period, compliance, skip-link, and ARIA-label copy synchronized there.
The local-AI disclosure must retain the 2 MiB raw scanned-image limit and must
not promise OpenRouter deletion/training behavior that the app cannot enforce.

## See Also

- [[infrastructure/ci-cd]] — Pages deploy job
- [[infrastructure/release-ops]] — web release channel
- [[patterns/accessibility]] — web semantic state expectations
- [[patterns/performance]] — mobile animation constraints
