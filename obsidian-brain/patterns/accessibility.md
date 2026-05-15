# Accessibility (a11y)

Source: `.claude/rules/accessibility.md`

**Target**: WCAG 2.1 AA. Accessibility is a release-blocker.

## Touch Targets

Minimum **48×48 dp** for every interactive element:

```dart
// CORRECT
IconButton(
  icon: AppIcon(AppIcons.edit),
  onPressed: _onEdit,
  constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
)

// WRONG — default 32×32
IconButton(icon: AppIcon(AppIcons.edit), onPressed: _onEdit)
```

Enforced by `check_iconbutton_constraints` in `verify_code_quality.py`.

## Semantic Labels

```dart
// Tooltip → automatic semantic label
IconButton(
  icon: AppIcon(AppIcons.delete),
  tooltip: 'common.delete'.tr(),
  onPressed: _onDelete,
)

// Decorative images
Semantics(excludeSemantics: true, child: decorativeImage)
```

## Color & Contrast

- Min contrast 4.5:1 (normal text), 3:1 (large text)
- Never convey information by color alone — pair with icon + text
- Genetics phenotype colors: exempted (biological accuracy)

## Font Scaling

- Honor system text scale: `MediaQuery.textScalerOf(context)`
- No hardcoded `TextStyle(fontSize: 14)` — use `Theme.of(context).textTheme`
- Min font size: 12sp default, 14sp body, 16sp+ heading
- Use flexible layouts, not fixed heights

## RTL Readiness

For future RTL language support:
- `EdgeInsetsDirectional.only(start: 16)` instead of `EdgeInsets.only(left: 16)`
- `AlignmentDirectional.topStart` instead of `Alignment.topLeft`
- `PositionedDirectional(start: 0)` instead of `Positioned(left: 0)`

## Locale Overflow Testing

German compound words overflow — always test:
```dart
testWidgets('button label fits in German locale', (tester) async {
  await pumpWidgetWithLocale(tester, MyButton(label: 'birds.add_breeding_pair'.tr()), 'de');
  final overflow = tester.takeException();
  expect(overflow, isNull);
});
```

## Marketing Site Semantics

The GitHub Pages site in `docs/` also follows WCAG-oriented state rules:

- Language buttons set `aria-pressed` and have language-specific labels.
- Mobile navigation keeps `aria-hidden` on the panel and `aria-expanded` on the hamburger in sync with visual state.
- FAQ toggles expose `aria-expanded` on each question button.
- Form inputs have explicit labels even when the visible design relies on placeholder text.
- Direct anchor links such as `#genetics-demo` must land on visible, active content and not leave reveal/GSAP inline opacity state hiding controls.

See [[infrastructure/marketing-site]] for web-specific QA steps.

## Anti-Patterns

1. `IconButton` without `constraints` (< 48dp)
2. Tooltip-less icon-only button (silent to screen readers)
3. Color as sole information carrier
4. Hardcoded `fontSize` (breaks system scaling)
5. Fixed width on text-containing widgets
6. `excludeSemantics: true` on interactive elements
7. `Container` with `onTap` (no semantic role) — use `InkWell` + `Semantics`
8. `EdgeInsets.only(left:)` when directional alternative exists

## See Also

- [[patterns/anti-patterns]] — A5 (IconButton constraints)
- [[patterns/ui-patterns]] — shared widgets (Widget icon param)
- [[patterns/l10n]] — 3 language overflow testing
