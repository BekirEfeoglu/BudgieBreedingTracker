# UI Patterns

Source: `.claude/rules/ui-patterns.md`

## Widget Types

| Type | When |
|------|------|
| `ConsumerWidget` | Read-only UI, no controllers |
| `ConsumerStatefulWidget` | TextEditingController, AnimationController, timers, ScrollController |
| `StatelessWidget` | Rare — private helper widgets only |

## AsyncValue Handling

```dart
asyncValue.when(
  loading: () => LoadingState(),
  error: (e, st) => ErrorState(message: _errorMessage(e)),
  data: (data) => DataWidget(data),
)

// Skip loading on refresh (keep previous data visible)
asyncValue.when(
  skipLoadingOnRefresh: true,
  loading: () => LoadingState(),
  error: (e, st) => ErrorState(message: e.toString().tr()),
  data: (data) => DataWidget(data),
)
```

## GoRouter

- Specific routes BEFORE parameterized: `/birds/form` before `/birds/:id`
- Forward navigation: `context.push()` (NOT `context.go()`)
- Back navigation: `context.pop()`
- Edit mode: query param `?editId=xxx`
- Guards: `AdminGuard`, `PremiumGuard` in `lib/router/guards/`

## Form Pattern

```dart
class _MyFormState extends ConsumerState<MyFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();  // ALWAYS dispose
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
- Alpha: `.withValues(alpha: 0.5)` — never `.withOpacity()`
- Exceptions: genetics phenotype colors, budgie painter

## Shared Widgets (29)

`lib/core/widgets/` — all accept `Widget icon` param, NOT `IconData`:

- Root (15): `EmptyState`, `LoadingState`, `ErrorState`, `SkeletonLoader`, `OfflineBanner`, etc.
- `buttons/` (4)
- `cards/` (2)
- `dialogs/` (2): `ConfirmDialog`, `TypedConfirmDialog`
- `bottom_sheet/` (1)
- `eggs/` (5)

## List Patterns

```dart
// Paginated with refresh
RefreshIndicator(
  onRefresh: () => ref.refresh(myProvider.future),
  child: ListView.builder(
    itemCount: items.length,
    itemBuilder: (context, index) => ItemTile(items[index]),
  ),
)
```

## Dialog & BottomSheet

```dart
// Confirmation
final confirmed = await showDialog<bool>(
  context: context,
  builder: (_) => ConfirmDialog(
    title: 'common.confirm_delete'.tr(),
    message: 'common.delete_warning'.tr(),
  ),
);
if (confirmed != true || !mounted) return;
```

## See Also

- [[patterns/anti-patterns]] — navigation (#17, #18), icons (#12)
- [[patterns/forms-validation]] — form details
- [[patterns/empty-loading-error-states]] — state catalog
- [[patterns/accessibility]] — touch targets
