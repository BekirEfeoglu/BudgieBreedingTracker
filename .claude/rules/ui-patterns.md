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
- Edit mode: query param `?editId=xxx`
- Guards: `AdminGuard`, `PremiumGuard` in `lib/router/guards/`
- Deep linking: all routes must be accessible via URI

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

## Shared Widgets (20)
`lib/core/widgets/`: EmptyState, ErrorState, LoadingState, SkeletonLoader, AppScreenTitle, InfoCard, StatCard, buttons/ (2), cards/ (2), dialogs/ (1)
- Accept `Widget icon` param, not `IconData`
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

// Empty state
if (items.isEmpty) EmptyState(
  icon: AppIcon(AppIcons.bird),
  message: 'birds.no_birds_found'.tr(),
)

// Skeleton loading
asyncValue.when(
  loading: () => SkeletonLoader(count: 5),
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
