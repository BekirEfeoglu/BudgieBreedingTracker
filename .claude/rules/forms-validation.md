# Forms & Validation

Form akışı standart: `GlobalKey<FormState>` + `TextEditingController` + validator function + async submit. Validation hatası kullanıcı dostu, server-side hata `ValidationException` ile yakalanır.

## Form Skeleton
```dart
class _BirdFormState extends ConsumerState<BirdFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _nameController = TextEditingController();
  late final _ringNumberController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _ringNumberController.dispose();
    super.dispose();
  }

  Future<void> _onSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      await ref.read(birdProvider.notifier).save(/* ... */);
      if (!mounted) return;
      context.pop();
    } on ValidationException catch (e) {
      if (!mounted) return;
      _showFieldErrors(e.fieldErrors);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}
```

## Validator Hierarchy
| Seviye | Ne zaman | Hata kaynağı |
|--------|----------|--------------|
| Sync field validator | `TextFormField.validator` | Boş kontrol, format (email, length) |
| Form-level validator | Submit öncesi cross-field | "Şifre eşleşmiyor", "Tarih aralığı" |
| Async unique check | onChange debounced | "Ring number kullanılıyor mu?" (DB query) |
| Server validation | Submit sonrası | `ValidationException` ile döner, field map'le |

```dart
// Sync validator
validator: (value) {
  if (value == null || value.isEmpty) return 'validation.required'.tr();
  if (value.length < 2) return 'validation.min_length'.tr(namedArgs: {'n': '2'});
  return null;
}

// Async (debounced + race-safe)
int _requestId = 0;
Future<void> _checkRingNumberUnique(String value) async {
  final id = ++_requestId;
  await Future.delayed(const Duration(milliseconds: 400));
  if (id != _requestId) return;
  final exists = await ref.read(birdRepositoryProvider).ringNumberExists(value);
  if (id != _requestId || !mounted) return;
  setState(() => _ringNumberError = exists ? 'validation.ring_taken'.tr() : null);
}
```

## ValidationException Mapping
Server `ValidationException` field-bazlı hata döner:
```dart
class ValidationException extends AppException {
  final Map<String, String> fieldErrors;
}
```
UI tarafı `fieldErrors` map'ini ilgili `TextFormField` `errorText`'ine bağlar (controller-based hata göstermek için `InputDecoration.errorText` veya custom state).

## Error Display
- Field-level: `TextFormField.decoration.errorText`
- Form-level (non-field): `SnackBar` veya inline banner (l10n: `errors.<key>`)
- Network hatası: snackbar + retry button
- Asla raw exception message gösterme — her zaman `.tr()` key

## Validation L10n Keys
Tüm validation mesajları `validation.` namespace altında:
```json
{
  "validation": {
    "required": "Bu alan zorunlu",
    "min_length": "En az {n} karakter",
    "max_length": "En fazla {n} karakter",
    "email_invalid": "Geçerli bir email girin",
    "ring_taken": "Bu halka numarası kullanımda",
    "date_in_future": "Tarih gelecekte olmalı",
    "date_in_past": "Tarih geçmişte olmalı"
  }
}
```

## Disabled / Loading State
- Submit sırasında button disable, loading indicator
- `_submitting` state'i ile çift-tıklama önle
- Form field'ları submit sırasında disabled (`enabled: !_submitting`)

```dart
PrimaryButton(
  onPressed: _submitting ? null : _onSubmit,
  loading: _submitting,
  label: 'common.save'.tr(),
)
```

## Multi-Step Form (Wizard)
- Her adım kendi `_formKey` ile validate
- State `Notifier`'da tutulur, adımlar arası kaybolmaz
- Geri tuşu: değişiklikleri kaybetme uyarısı (`WillPopScope` / `PopScope`)
- Adım göstergesi (1/3, 2/3, 3/3) ARIA-label ile erişilebilir

## Specific Field Types
| Tip | Widget | Validator notu |
|-----|--------|----------------|
| Email | `TextFormField` + `TextInputType.emailAddress` | Regex: `RegExp(r'^[^@]+@[^@]+\.[^@]+')` |
| Phone | `TextFormField` + intl_phone_field | E.164 format zorunlu |
| Date | `showDatePicker` | DateTime null check |
| Image | Custom picker + `scan-image-safety` | 10MB guard, NSFW reject |
| Dropdown | `DropdownButtonFormField(initialValue: ...)` | NOT `value:` (deprecated) |

## Form Testing
```dart
testWidgets('shows validation error for empty name', (tester) async {
  await pumpWidget(tester, BirdFormScreen());
  await tester.tap(find.byKey(const Key('save_button')));
  await tester.pumpAndSettle();
  expect(find.text('validation.required'.tr()), findsOneWidget);
});

testWidgets('submits when valid', (tester) async {
  await pumpWidget(tester, BirdFormScreen());
  await tester.enterText(find.byKey(const Key('name_field')), 'Maviş');
  await tester.tap(find.byKey(const Key('save_button')));
  await tester.pumpAndSettle();
  verify(() => mockRepo.insert(any())).called(1);
});
```

## Anti-Patterns
1. Controller `dispose()` unutmak (memory leak)
2. Async submit sonrası `mounted` kontrolü olmadan setState
3. Server hatası için `ValidationException` yerine generic `Exception` fırlatmak
4. Validation mesajını hardcode (her şey `.tr()`)
5. Submit button'unu disable etmeden çift-submit'e izin vermek
6. Async validator'da race condition (request ID pattern eksik)
7. Multi-step form'da `WillPopScope` ile veri kaybı uyarısı vermemek
8. `DropdownButtonFormField` üzerinde `value:` kullanmak (`initialValue:` zorunlu, anti-pattern #2)

> **İlgili**: ui-patterns.md (form pattern), error-handling.md (ValidationException), localization.md (validation keys), coding-standards.md (controller dispose)
