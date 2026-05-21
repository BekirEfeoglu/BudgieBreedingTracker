# Riverpod Providers

Source: `.claude/rules/providers.md`

## Provider Types

| Type | Use Case |
|------|---------|
| `Provider<T>` | Immutable singletons (services, router) |
| `NotifierProvider<N, T>` | Mutable state with methods (filters, sort) |
| `AsyncNotifierProvider<N, T>` | Async state with methods (CRUD) |
| `StreamProvider<T>` | Real-time streams (bird lists, sync status) |
| `StreamProvider.family<T, P>` | Parameterized streams |
| `FutureProvider<T>` | One-shot async (initialization) |

## ref Usage

| Method | Where | Purpose |
|--------|-------|---------|
| `ref.watch()` | `build()` only | Reactive rebuilds |
| `ref.read()` | Callbacks, async | One-shot reads, mutations |
| `ref.listen()` | `build()` | Side effects (snackbar, navigation) |
| `ref.invalidate()` | After mutations | Force provider refresh |
| `ref.onDispose()` | Provider body | Cleanup |

## Common Mistakes

```dart
// WRONG: ref.watch in callback
onPressed: () { final birds = ref.watch(birdsProvider); }

// CORRECT: ref.read in callback
onPressed: () { final birds = ref.read(birdsProvider); }

// WRONG: ref.read in build
Widget build(_, WidgetRef ref) { final birds = ref.read(birdsProvider); }

// CORRECT: ref.watch in build
Widget build(_, WidgetRef ref) { final birds = ref.watch(birdsProvider); }
```

## Dependency Chain

```
UI → Feature Providers → Repository Providers → Service Providers
```

## AsyncNotifier Pattern

```dart
class BirdListNotifier extends AsyncNotifier<List<Bird>> {
  @override
  Future<List<Bird>> build() async {
    return ref.read(birdRepositoryProvider).getAll();
  }

  Future<void> addBird(Bird bird) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(birdRepositoryProvider).insert(bird);
      return ref.read(birdRepositoryProvider).getAll();
    });
  }
}
```

## Race Condition Prevention

```dart
int _requestId = 0;

Future<void> search(String query) async {
  final id = ++_requestId;
  final results = await repo.search(query);
  if (id != _requestId) return;  // Stale request, discard
  state = AsyncValue.data(results);
}
```

## Rebuild Minimization

```dart
// Rebuilds only when name changes, not entire bird object
final name = ref.watch(birdProvider.select((b) => b.value?.name));
```

## KeepAlive

- Use `ref.keepAlive()` for expensive computations that shouldn't re-run
- Auth state, app configuration
- Don't keepAlive everything — let ephemeral UI state dispose

## Error Handling

- Use `AsyncValue.guard()` for automatic error/loading state management
- Never catch errors silently in providers
- Side-effect errors: catch and show via `ref.listen()` in UI

## See Also

- [[patterns/anti-patterns]] — #4 (ref.watch in callbacks)
- [[patterns/ui-patterns]] — AsyncValue handling in widgets
