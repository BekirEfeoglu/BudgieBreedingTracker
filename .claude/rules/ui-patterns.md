# UI Patterns

## Widget Types
| Type | When to Use |
|------|-------------|
| `ConsumerWidget` | Read-only UI, no controllers needed |
| `ConsumerStatefulWidget` | TextEditingController, AnimationController, timers |
| `StatelessWidget` | Rare — only when Riverpod not needed (private helper widgets) |

## AsyncValue Handling
```dart
asyncValue.when(
  loading: () => LoadingState(),
  error: (e, st) => ErrorState(message: _errorMessage(e)),
  data: (data) => DataWidget(data),
)
```
Or pattern matching: `if (asyncValue.asData?.value case final data?) ...`

## GoRouter (72 routes)
- Route files: `lib/router/routes/{admin,auth,community,gamification,marketplace,messaging,user}_routes.dart`
- Specific routes BEFORE parameterized: `/birds/form` before `/birds/:id`
- Forward navigation: `context.push()` (NOT `context.go()` which replaces stack)
- Edit mode: query param `?editId=xxx`
- Guards: `AdminGuard`, `PremiumGuard` in `lib/router/guards/`

## Shared Widgets (20)
`lib/core/widgets/`: EmptyState, ErrorState, LoadingState, SkeletonLoader, AppScreenTitle, InfoCard, StatCard, buttons/ (2), cards/ (2), dialogs/ (1)
- Accept `Widget icon` param, not `IconData`

## Form Pattern
- Wrap in `Form` with `GlobalKey<FormState>`
- Validate on submit with `_formKey.currentState!.validate()`
- Check `mounted` after every async operation before `setState`

## Theme & Spacing
- Colors: `Theme.of(context).colorScheme.x`
- Spacing: `AppSpacing.xs/sm/md/lg/xl/xxl/xxxl`
- Alpha: `.withValues(alpha: 0.5)` never `.withOpacity()`
- Exceptions: genetics phenotype colors, budgie painter
