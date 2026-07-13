# Forms & Validation

Source: `.claude/rules/forms-validation.md`

## Form Skeleton

```dart
class _BirdFormState extends ConsumerState<BirdFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _nameController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _nameController.dispose();  // ALWAYS dispose controllers
    super.dispose();
  }

  Future<void> _onSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      await ref.read(birdProvider.notifier).save(/* ... */);
      if (!mounted) return;  // ALWAYS check mounted
      context.pop();
    } on ValidationException catch (e) {
      if (!mounted) return;
      _showErrorSnackBar(e.message.tr()); // message is an l10n key — no fieldErrors map
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}
```

## Validator Hierarchy

| Level | When | Source |
|-------|------|--------|
| Sync field validator | `TextFormField.validator` | Empty check, format |
| Form-level validator | Submit, cross-field | "Passwords don't match" |
| Async unique check | onChange debounced | Generic pattern below — no shipped ring-unique check exists ([[known-gaps]]) |
| Server validation | Submit response | `ValidationException(message: l10nKey, code?)` — no per-field error map |

## Async Validator (Race-Safe)

GENERIC pattern — note: a ring-number unique check is NOT shipped
(`ringNumberExists` / `validation.ring_taken` don't exist — [[known-gaps]]):

```dart
int _requestId = 0;
Future<void> _checkUnique(String value) async {
  final id = ++_requestId;
  await Future.delayed(const Duration(milliseconds: 400));
  if (id != _requestId) return;  // Stale request
  final exists = await ref.read(myRepositoryProvider).fieldExists(value);
  if (id != _requestId || !mounted) return;
  setState(() => _fieldError = exists ? 'validation.already_taken'.tr() : null);
}
```

## Submit Button State

```dart
PrimaryButton(
  onPressed: _submitting ? null : _onSubmit,  // null = disabled
  isLoading: _submitting,  // param name is isLoading (primary_button.dart)
  label: 'common.save'.tr(),
)
```

## Specific Field Types

| Type | Widget | Note |
|------|--------|------|
| Email | `TextFormField` + `TextInputType.emailAddress` | Regex validation |
| Date | `showDatePicker` | Check for null return |
| Image | Custom picker | 10MB guard + scan-image-safety |
| Dropdown | `DropdownButtonFormField(initialValue: ...)` | NOT `value:` (anti-pattern #2) |

## Validation L10n Keys

All in `validation.` namespace:

```json
{
  "validation": {
    "required": "Bu alan zorunlu",
    "min_length": "En az {n} karakter",
    "max_length": "En fazla {n} karakter",
    "email_invalid": "Geçerli bir email girin"
  }
}
```

## Anti-Patterns

1. `controller.dispose()` missing (memory leak)
2. Async submit without `mounted` check after await
3. Generic `Exception` instead of `ValidationException`
4. Hardcoded validation messages (use `.tr()`)
5. Double-submit allowed (no disabled state)
6. Async validator without race condition guard
7. `DropdownButtonFormField` with `value:` instead of `initialValue:`

## See Also

- [[patterns/ui-patterns]] — form pattern
- [[patterns/error-handling]] — ValidationException
- [[patterns/anti-patterns]] — #2 (DropdownButtonFormField), #3 (setState/mounted), #20 (dispose)
