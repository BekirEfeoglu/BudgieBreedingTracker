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
- 800 test files, 9,697+ individual tests
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

## Mocking
- Package: `mocktail`
- 60+ mock classes in `test/helpers/mocks.dart`
- Pattern: `class MockBirdRepository extends Mock implements BirdRepository {}`
- Fixtures: test data builders with named parameters

## Golden Tests
- Separate `test/golden/` directory
- Tagged: `@Tags(['golden'])`
- Linux baseline only
- Excluded from CI with `--exclude-tags golden`
