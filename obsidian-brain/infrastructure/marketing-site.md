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

## Landing Page Behavior

- Main navigation links to in-page anchors: `#features`, `#genetics-demo`, `#screenshots`, `#pricing`, `#faq`, `#cta`.
- Language switcher is inline JS-backed for `tr`, `en`, `de`; it updates `document.documentElement.lang`, text keys, placeholders, page title, and `aria-pressed` state.
- Mobile menu uses explicit `aria-hidden`, `aria-expanded`, and language-aware open/close labels.
- Mobile menu behaves as a modal dialog on narrow screens: opening it locks body
  scroll, moves focus to the first link, traps Tab navigation, supports Escape,
  and restores focus to the hamburger button when closed.
- FAQ buttons use `aria-expanded` and close previously opened items.
- Email signup posts to FormSubmit, exposes localized loading/success/error
  status through an `aria-live` region, and never reports success when the
  network request fails.

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

- `style.css` is cache-busted from the HTML (`style.css?v=YYYYMMDD`) when deploy-sensitive visual fixes need immediate propagation.
- Mobile disables expensive entrance/float/glow animations for the hero path so first content is readable immediately.
- Keep decorative animations non-blocking; anchor targets and CTAs must remain usable without waiting for GSAP.

## QA Checklist

- Open `https://budgiebreedingtracker.online/` desktop and mobile.
- Open `https://budgiebreedingtracker.online/#genetics-demo` directly; the demo controls and result cards should be visible after load.
- Change mother/father mutation options and verify the result grid updates.
- Open the mobile menu and verify `aria-hidden=false`, hamburger `aria-expanded=true`.
- While the mobile menu is open, verify focus starts on the first link, Tab is
  trapped, Escape closes it, body scroll unlocks, and focus returns to the
  hamburger button.
- Toggle an FAQ item and verify `aria-expanded=true`.
- Simulate a failed email subscription request and verify the form remains
  available with a localized error instead of a success message.
- Run `python3 scripts/check_remote_status.py` after push; Pages deploy status must match the exact commit.

## See Also

- [[infrastructure/ci-cd]] — Pages deploy job
- [[infrastructure/release-ops]] — web release channel
- [[patterns/accessibility]] — web semantic state expectations
- [[patterns/performance]] — mobile animation constraints
