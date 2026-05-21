# Testing

Source: `.claude/rules/testing.md`, `.claude/rules/test-stability.md`

## Stats

- 901 test files, 11,017+ individual tests
- CI timeout: 25 minutes
- Golden tests excluded from main CI (`--exclude-tags golden`)

## Structure

```
test/
├── core/       core utility tests
├── data/       repo, DAO, mapper, model tests
├── domain/     service tests
├── features/   screen, widget, provider tests
├── router/     route guard tests
├── helpers/    mocks.dart, pump_helpers.dart, fixtures
├── golden/     visual regression
└── e2e/        end-to-end
```

Mirrors `lib/` structure.

## Pump Helpers

```dart
// Full app wrapper with providers + l10n
pumpWidget(tester, widget, {router?})

// Minimal wrapper for isolated widgets
pumpWidgetSimple(tester, widget)
```

Located in `test/helpers/pump_helpers.dart`.

## Pump Strategy

| Method | When |
|--------|------|
| `pumpAndSettle()` | After animations, navigation, async updates |
| `pump()` | Single frame for sync state changes |
| `pump(Duration)` | Advance timers/debounce |

Never use `sleep()` or `Future.delayed()` in tests.

## Resource Cleanup (Critical)

```dart
// ProviderContainer — ALWAYS dispose
final container = ProviderContainer(overrides: [...]);
addTearDown(container.dispose);

// StreamController
final controller = StreamController<List<Bird>>();
addTearDown(controller.close);
```

**Rule**: Every `ProviderContainer(...)` MUST be followed by `addTearDown(container.dispose)`. Enforced by `check_provider_container_dispose` checker. 644+ leaks fixed 2026-04-17.

## Mocking

- Package: `mocktail`
- ~49 mock classes in `test/helpers/mocks.dart`
- Pattern: `class MockBirdRepository extends Mock implements BirdRepository {}`
- `registerFallbackValue()` for custom types in `setUpAll`

## Test Naming

```dart
// should_[expected]_when_[condition]
test('should return empty list when no birds exist', () { ... });
test('should throw NetworkException when offline', () { ... });
```

## Golden Tests

- `test/golden/` — tagged `@Tags(['golden'])`
- Linux baseline only
- Update: `flutter test --update-goldens test/golden/`
- Multi-locale: test all 3 languages (tr/en/de) — catches German overflow bugs

## 18 Test Anti-Patterns

1. Hard waits (`sleep`, `Future.delayed`)
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

## Flaky Test Triage

1. Hard wait present? → replace with `pump`/`pumpAndSettle`
2. Race condition? → request ID pattern
3. Time-dependent? → fake clock or fixed time inject
4. Shared state? → `setUp`/`tearDown` isolation
5. Resource leak? → `addTearDown`
6. `CircularProgressIndicator` with `pumpAndSettle`? → timeout
7. Platform-specific? → `@TestOn('linux')` pin

If unresolvable: `skip: 'flaky — see issue #X'`. Never delete without finding root cause.

## See Also

- [[patterns/providers]] — provider test setup
- [[patterns/anti-patterns]] — A1 (ProviderContainer teardown)
