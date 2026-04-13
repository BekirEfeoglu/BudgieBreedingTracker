# Testing

## Structure
```
test/
├── core/          # Core utility tests
├── data/          # Repository, DAO, mapper, model tests
├── domain/        # Service tests
├── features/      # Screen, widget, provider tests
├── router/        # Route guard tests
├── helpers/       # Mocks, pump helpers, test fixtures
├── golden/        # Visual regression tests
└── e2e/           # End-to-end tests
```

## Stats
- 820 test files, 10,093+ individual tests
- CI excludes golden tests: `--exclude-tags golden`
- CI timeout: 25 minutes

## Patterns

### Unit Tests (Services, Models)
```dart
test('description', () {
  final result = service.method(input);
  expect(result, expectedOutput);
});
```

### Provider Tests
```dart
final container = ProviderContainer(overrides: [
  repositoryProvider.overrideWithValue(mockRepo),
]);
addTearDown(container.dispose);
final notifier = container.read(myProvider.notifier);
```

### Widget Tests
```dart
await pumpWidget(tester, MyWidget(), router: mockRouter);
expect(find.text('Expected'), findsOneWidget);
```

### Repository Tests
```dart
test('should sync local changes to remote', () async {
  when(() => mockDao.getDirtyRecords()).thenAnswer((_) async => [testBird]);
  when(() => mockRemote.upsert(any())).thenAnswer((_) async => {});

  await repository.syncToRemote();

  verify(() => mockRemote.upsert(testBird.toSupabase())).called(1);
  verify(() => mockDao.markClean(testBird.id)).called(1);
});
```

### Async Provider Tests
```dart
test('handles loading and error states', () async {
  when(() => mockRepo.getAll()).thenThrow(NetworkException('offline'));

  final container = ProviderContainer(overrides: [
    repositoryProvider.overrideWithValue(mockRepo),
  ]);
  addTearDown(container.dispose);

  // Initial state is loading
  expect(container.read(myProvider), const AsyncValue<List<Bird>>.loading());

  // After settling, should be error
  await container.read(myProvider.future).catchError((_) {});
  expect(container.read(myProvider), isA<AsyncError<List<Bird>>>());
});
```

## Mocking
- Package: `mocktail`
- ~49 mock classes in `test/helpers/mocks.dart`
- Pattern: `class MockBirdRepository extends Mock implements BirdRepository {}`
- Fixtures: test data builders with named parameters
- Use `registerFallbackValue()` for custom types in `setUpAll`

## Golden Tests
- Separate `test/golden/` directory
- Tagged: `@Tags(['golden'])`
- Linux baseline only
- Excluded from CI with `--exclude-tags golden`
- Update baselines: `flutter test --update-goldens test/golden/`

## Coverage
- CI uploads to Codecov (excludes golden & e2e)
- Focus coverage on business logic (services, repositories, providers)
- Widget tests: verify behavior, not pixel-perfect layout
- Don't chase 100% — test meaningful behavior and edge cases

## Test Naming
```dart
// Pattern: should_[expected]_when_[condition]
test('should return empty list when no birds exist', () { ... });
test('should throw NetworkException when offline', () { ... });
test('should filter by gender when gender filter is active', () { ... });
```

> **Related**: test-stability.md (pump strategy, anti-patterns), coding-standards.md (naming)
