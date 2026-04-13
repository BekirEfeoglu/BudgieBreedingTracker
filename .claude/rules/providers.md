# Riverpod Providers

## Provider Types
| Type | Use Case |
|------|----------|
| `Provider<T>` | Immutable singletons (services, router) |
| `NotifierProvider<N, T>` | Mutable state with methods (filters, sort, search) |
| `AsyncNotifierProvider<N, T>` | Async state with methods (config, CRUD) |
| `StreamProvider<T>` | Real-time streams (bird lists, sync status) |
| `StreamProvider.family<T, P>` | Parameterized streams |
| `FutureProvider<T>` | One-shot async (initialization) |

## ref Usage
| Method | Where | Purpose |
|--------|-------|---------|
| `ref.watch()` | `build()` only | Reactive UI rebuilds |
| `ref.read()` | Callbacks, async | One-shot reads, mutations |
| `ref.listen()` | `build()` | Side effects (snackbar, navigation) |
| `ref.invalidate()` | After mutations | Force provider refresh |
| `ref.onDispose()` | Provider body | Cleanup (HTTP clients, subscriptions) |

### Common Mistakes
```dart
// WRONG: ref.watch in callback
onPressed: () {
  final birds = ref.watch(birdsProvider);  // Will rebuild on every tap
}

// CORRECT: ref.read in callback
onPressed: () {
  final birds = ref.read(birdsProvider);
}

// WRONG: ref.read in build
Widget build(BuildContext context, WidgetRef ref) {
  final birds = ref.read(birdsProvider);  // Won't rebuild when data changes
}

// CORRECT: ref.watch in build
Widget build(BuildContext context, WidgetRef ref) {
  final birds = ref.watch(birdsProvider);
}
```

## Dependency Chain
```
UI -> Feature Providers -> Repository Providers -> Service Providers
```
- Repositories injected via `Provider<XRepository>`
- Feature providers consume via `ref.read(xRepositoryProvider)`
- Never create circular provider dependencies
- Keep provider files in `lib/features/<name>/providers/`

## AsyncNotifier Pattern
```dart
class BirdListNotifier extends AsyncNotifier<List<Bird>> {
  @override
  Future<List<Bird>> build() async {
    final repo = ref.read(birdRepositoryProvider);
    return repo.getAll();
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
// Use _requestId pattern for debounced/sequential async operations
int _requestId = 0;

Future<void> search(String query) async {
  final id = ++_requestId;
  final results = await repo.search(query);
  if (id != _requestId) return;  // Stale request, discard
  state = AsyncValue.data(results);
}
```

## Error Handling in Providers
- Use `AsyncValue.guard()` for automatic error/loading state management
- Never catch errors silently in providers — let AsyncValue propagate to UI
- For side-effect errors (save, delete), catch and show via `ref.listen()` in UI

## KeepAlive
- Use `ref.keepAlive()` for providers that should survive widget disposal
- Expensive computation results, auth state, app configuration
- Don't keepAlive everything — let ephemeral UI state dispose naturally

> **Related**: ui-patterns.md (AsyncValue handling), error-handling.md (exception types), architecture.md (dependency chain)
