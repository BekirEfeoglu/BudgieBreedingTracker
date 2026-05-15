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
| `docs/support/`, `docs/user-guide/` | Support and guide landing pages |

## Landing Page Behavior

- Main navigation links to in-page anchors: `#features`, `#genetics-demo`, `#screenshots`, `#pricing`, `#faq`, `#cta`.
- Language switcher is inline JS-backed for `tr`, `en`, `de`; it updates `document.documentElement.lang`, text keys, placeholders, page title, and `aria-pressed` state.
- Mobile menu uses explicit `aria-hidden`, `aria-expanded`, and language-aware open/close labels.
- FAQ buttons use `aria-expanded` and close previously opened items.
- Email signup posts to FormSubmit and has an accessible label for the email input.

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
- App Store CTA points to App ID `6759828211`.

## Performance Notes

- `style.css` is cache-busted from the HTML (`style.css?v=YYYYMMDD`) when deploy-sensitive visual fixes need immediate propagation.
- Mobile disables expensive entrance/float/glow animations for the hero path so first content is readable immediately.
- Keep decorative animations non-blocking; anchor targets and CTAs must remain usable without waiting for GSAP.

## QA Checklist

- Open `https://budgiebreedingtracker.online/` desktop and mobile.
- Open `https://budgiebreedingtracker.online/#genetics-demo` directly; the demo controls and result cards should be visible after load.
- Change mother/father mutation options and verify the result grid updates.
- Open the mobile menu and verify `aria-hidden=false`, hamburger `aria-expanded=true`.
- Toggle an FAQ item and verify `aria-expanded=true`.
- Run `python3 scripts/check_remote_status.py` after push; Pages deploy status must match the exact commit.

## See Also

- [[infrastructure/ci-cd]] — Pages deploy job
- [[infrastructure/release-ops]] — web release channel
- [[patterns/accessibility]] — web semantic state expectations
- [[patterns/performance]] — mobile animation constraints
