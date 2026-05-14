# Empty, Loading & Error States

Source: `.claude/rules/empty-loading-error-states.md`

**Rule**: Never show a white screen. Every async state needs a UI.

## Shared Widget Catalog (`lib/core/widgets/`)

| Widget | Usage |
|--------|-------|
| `EmptyState` | No results, no error (empty list, filter mismatch) |
| `LoadingState` | Initial fetch, manual refresh |
| `SkeletonLoader` | List item placeholder (matches real layout) |
| `ErrorState` | Network/server error + retry CTA |
| `OfflineBanner` | App-wide offline indicator |

All accept `Widget icon` param, never `IconData`.

## AsyncValue Mapping

```dart
asyncValue.when(
  loading: () => const SkeletonLoader(count: 5),
  error: (e, st) => ErrorState(
    icon: AppIcon(AppIcons.errorCloud),
    message: _errorMessage(e).tr(),
    onRetry: () => ref.invalidate(myProvider),
  ),
  data: (items) => items.isEmpty
      ? EmptyState(
          icon: AppIcon(AppIcons.bird),
          title: 'birds.no_birds_title'.tr(),
          message: 'birds.no_birds_hint'.tr(),
          cta: PrimaryButton(
            label: 'birds.add_first'.tr(),
            onPressed: () => context.push(AppRoutes.birdForm),
          ),
        )
      : BirdList(items),
)
```

## Loading Duration Guidance

| Duration | Pattern |
|---------|---------|
| 0–100ms | Show nothing (prevent flicker) |
| 100–500ms | `LoadingState` spinner |
| 500ms+ | `SkeletonLoader` (layout confidence) |
| 5s+ | Skeleton + cancel option |

**Refresh**: keep old data visible (`skipLoadingOnRefresh: true`).

## Empty State Anatomy

- **Icon**: SVG related to content type
- **Title**: short, descriptive ("Henüz kuşunuz yok")
- **Message**: 1–2 sentence hint
- **CTA**: primary action button ("İlk kuşunuzu ekleyin")

### Filter Empty vs Data Empty

"No results" (filter active) → "Sonuç bulunamadı" + "Filtreleri temizle"
"No data" (no records) → "No birds yet" + "Add first bird"

## Error State by Type

| Type | Message | CTA |
|------|---------|-----|
| `NetworkException` | "İnternet bağlantısı yok" | Retry |
| `AuthException` | "Oturum sona erdi" | "Giriş Yap" |
| `ServerException` | "Sunucuya ulaşılamadı" | Retry + Support |
| `FreeTierLimitException` | "Ücretsiz limit doldu" | Premium upgrade |

## Anti-Patterns

1. White screen loading (user thinks app frozen)
2. Raw `CircularProgressIndicator` with no context
3. Empty state without CTA
4. Error state with raw `e.toString()` message
5. Showing skeleton on refresh (use `skipLoadingOnRefresh`)
6. Filter empty confused with data empty
7. Skeleton size doesn't match real item (jank transition)
8. Per-screen OfflineBanner (use global Scaffold wrapper)
9. Spinner for < 100ms operations (flicker)

## See Also

- [[patterns/ui-patterns]] — AsyncValue
- [[patterns/error-handling]] — exception to message mapping
- [[patterns/l10n]] — state key naming conventions
- [[patterns/accessibility]] — semantic labels for states
