# UI Patterns

## Widget Types
| Type | When to Use |
|------|-------------|
| `ConsumerWidget` | Read-only UI, no controllers needed |
| `ConsumerStatefulWidget` | TextEditingController, AnimationController, timers, ScrollController |
| `StatelessWidget` | Rare — only when Riverpod not needed (private helper widgets) |

## AsyncValue Handling
```dart
// Standard pattern
asyncValue.when(
  loading: () => LoadingState(),
  error: (e, st) => ErrorState(message: _errorMessage(e)),
  data: (data) => DataWidget(data),
)

// Pattern matching (compact)
if (asyncValue.asData?.value case final data?) ...

// Skip loading on refresh (keep previous data visible)
asyncValue.when(
  skipLoadingOnRefresh: true,
  loading: () => LoadingState(),
  error: (e, st) => ErrorState(message: _errorMessage(e)),
  data: (data) => DataWidget(data),
)
```

## GoRouter
- Route files: `lib/router/routes/{admin,auth,community,gamification,marketplace,messaging,user}_routes.dart`
- Specific routes BEFORE parameterized: `/birds/form` before `/birds/:id`
- Forward navigation: `context.push()` (NOT `context.go()` which replaces stack)
- Back navigation: `context.pop()` — never `context.go()` for going back
- Primary bottom-nav/rail tabs use `StatefulShellRoute.indexedStack` and
  `StatefulNavigationShell.goBranch`; keep one Navigator per branch so local
  widget/scroll state and nested stacks survive tab switches
- Edit mode: query param `?editId=xxx`
- Guards: `AdminGuard`, `PremiumGuard`, `FounderGuard` in `lib/router/guards/` (security.md § Route Guards). `FounderGuard` soft-launch-gates `/community/*`, `/marketplace/*` and `/ai-predictions`; a UI entry point to a founder-gated route MUST hide itself behind `isFounderProvider` rather than let the redirect dead-end the user
- Deep linking: all routes must be accessible via URI
- `verify_rules.py` § Route Targets (`rules-sync`) rejects two constants sharing a path value, and any `context.push`/`go`/`replace` string target that resolves to no declared route. It deliberately does NOT require every constant to be referenced — detail routes are reached by interpolation

### Route Definition Pattern
```dart
GoRoute(
  path: 'form',              // Specific first
  builder: (context, state) => const BirdFormScreen(),
),
GoRoute(
  path: ':id',               // Parameterized after
  builder: (context, state) => BirdDetailScreen(
    id: state.pathParameters['id']!,
  ),
),
```

## Shared Widgets (35)
`lib/core/widgets/`: 15 root widgets plus `buttons/` (4), `cards/` (2), `dialogs/` (2), `bottom_sheet/` (1), and `eggs/` (5). `OfflineBanner` is NOT in this set — it lives at `lib/shared/widgets/offline_banner.dart`.
- Accept `Widget icon` param, not `IconData`
- Icon-only buttons: use `AppIconButton` (`buttons/app_icon_button.dart`) — guarantees the 48dp touch target and requires `semanticLabel`, instead of hand-rolling `IconButton(constraints: ...)` (accessibility.md)
- Use existing shared widgets before creating new ones

## Form Pattern
```dart
class _MyFormState extends ConsumerState<MyFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();  // ALWAYS dispose controllers
    super.dispose();
  }

  Future<void> _onSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    await ref.read(myProvider.notifier).save(/* ... */);

    if (!mounted) return;  // ALWAYS check mounted after async
    context.pop();
  }
}
```

## Theme & Spacing
- Colors: `Theme.of(context).colorScheme.x`
- Text: `Theme.of(context).textTheme.bodyMedium`
- Spacing: `AppSpacing.xs/sm/md/lg/xl/xxl/xxxl`
- Alpha: `.withValues(alpha: 0.5)` never `.withOpacity()`
- Exceptions: genetics phenotype colors, budgie painter

## List & Loading Patterns
```dart
// Paginated list with refresh
RefreshIndicator(
  onRefresh: () => ref.refresh(myProvider.future),
  child: ListView.builder(
    itemCount: items.length,
    itemBuilder: (context, index) => ItemTile(items[index]),
  ),
)

// Empty state — ikinci metin parametresi subtitle (message DEĞİL)
if (items.isEmpty) EmptyState(
  icon: AppIcon(AppIcons.bird),
  title: 'birds.no_birds_found'.tr(),
)

// Skeleton loading — SkeletonLoader tek shimmer kutusudur (count parametresi YOK)
asyncValue.when(
  loading: () => Column(
    children: List.generate(
      5,
      (_) => const SkeletonLoader(width: double.infinity, height: 72),
    ),
  ),
  // ...
)
```

## Dialog & BottomSheet
```dart
// Confirmation dialog
final confirmed = await showDialog<bool>(
  context: context,
  builder: (_) => ConfirmDialog(
    title: 'common.confirm_delete'.tr(),
    message: 'common.delete_warning'.tr(),
  ),
);
if (confirmed != true || !mounted) return;

// Bottom sheet
showModalBottomSheet(
  context: context,
  isScrollControlled: true,  // For full-height sheets
  builder: (_) => const MyBottomSheet(),
);
```

> **Related**: coding-standards.md (icons, naming), providers.md (ref usage in UI), localization.md (.tr() usage)
