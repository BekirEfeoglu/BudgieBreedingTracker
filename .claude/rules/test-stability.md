# Test Stability

## Pump Helpers
- `pumpWidget(tester, widget, {router?})` — full app wrapper with providers + l10n
- `pumpWidgetSimple(tester, widget)` — minimal wrapper for isolated widgets
- Located in `test/helpers/pump_helpers.dart`

## Pump Strategy
| Method | When to Use |
|--------|-------------|
| `pumpAndSettle()` | After animations, navigation, async UI updates |
| `pump()` | Single frame advance for synchronous state changes |
| `pump(Duration)` | Advance by specific time (timers, debounce) |

- Never use `sleep()` or `Future.delayed()` in tests
- If `pumpAndSettle()` times out, check for infinite animations (e.g., `CircularProgressIndicator`)
- Use `pump()` instead of `pumpAndSettle()` when testing loading states

## Fixture Pattern
```dart
Bird _bird({String? name, BirdGender? gender}) => Bird(
  id: 'test-id',
  name: name ?? 'Test Bird',
  gender: gender ?? BirdGender.male,
  // ... sensible defaults for all required fields
);
```
- Each test file defines its own fixtures as private top-level functions
- Use named parameters with defaults for flexibility
- Shared fixtures in `test/helpers/` for cross-file reuse

## Async Test Patterns
```dart
// Testing streams
test('emits birds when data changes', () async {
  final controller = StreamController<List<Bird>>();
  addTearDown(controller.close);

  when(() => mockDao.watchAll()).thenAnswer((_) => controller.stream);
  // ... assert on stream emissions
});

// Testing timers/debounce
testWidgets('debounces search input', (tester) async {
  await pumpWidget(tester, SearchScreen());
  await tester.enterText(find.byType(TextField), 'budgie');
  await tester.pump(const Duration(milliseconds: 300)); // debounce delay
  // ... assert search was triggered
});
```

## 18 Anti-Patterns to Avoid
1. Hard waits (`sleep`, `Future.delayed` in tests)
2. Shared mutable state between tests
3. Missing `addTearDown(container.dispose)`
4. Not verifying mock interactions
5. Overly broad `find.byType()` without context
6. Missing `pumpAndSettle()` after async operations
7. Testing implementation details instead of behavior
8. Flaky time-dependent assertions
9. Not isolating tests (shared static state)
10. Missing error case tests
11. Ignoring `mounted` check in widget tests
12. Not cleaning up subscriptions in tearDown
13. Hardcoded test data that could drift
14. Testing private methods directly
15. Missing edge case tests (null, empty, boundary)
16. Not testing error messages/states
17. Relying on widget tree structure instead of semantics
18. Not disposing controllers in test tearDown

## Resource Cleanup
```dart
// ProviderContainer — ALWAYS dispose
final container = ProviderContainer(overrides: [...]);
addTearDown(container.dispose);

// StreamController — close in tearDown
final controller = StreamController<List<Bird>>();
addTearDown(controller.close);

// TextEditingController — dispose
final textController = TextEditingController();
addTearDown(textController.dispose);

// Timer — cancel
final timer = Timer.periodic(duration, callback);
addTearDown(timer.cancel);
```

> **Related**: testing.md (test patterns, mocking), providers.md (provider test setup)
