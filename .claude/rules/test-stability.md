# Test Stability

## Pump Helpers
- `pumpWidget(tester, widget, {router?})` — full app wrapper with providers
- `pumpWidgetSimple(tester, widget)` — minimal wrapper for isolated widgets
- Located in `test/helpers/pump_helpers.dart`

## Pump Strategy
- `pumpAndSettle()` — after animations, navigation, async UI updates
- `pump()` — single frame advance for synchronous state changes
- `pump(Duration)` — advance by specific time (timers, debounce)
- Never use `sleep()` in tests

## Fixture Pattern
```dart
Bird _bird({String? name, BirdGender? gender}) => Bird(
  id: 'test-id',
  name: name ?? 'Test Bird',
  gender: gender ?? BirdGender.male,
  // ... sensible defaults
);
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
- Always `addTearDown(container.dispose)` for ProviderContainer
- Close StreamControllers in tearDown
- Dispose TextEditingControllers
- Cancel timers
