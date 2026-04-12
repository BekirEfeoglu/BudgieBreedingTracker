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
- `ref.watch()` — ONLY in `build()` method for reactive UI
- `ref.read()` — in callbacks, event handlers, async operations
- `ref.listen()` — for side effects (snackbars, navigation) in `build()`
- `ref.invalidate()` — manual refresh after mutations
- `ref.onDispose()` — cleanup (close HTTP clients, cancel subscriptions)

## Dependency Chain
```
UI → Feature Providers → Repository Providers → Service Providers
```
- Repositories injected via `Provider<XRepository>`
- Feature providers consume repositories via `ref.read(xRepositoryProvider)`
- Never create circular provider dependencies

## Race Condition Prevention
- Use `_requestId` pattern: increment on each call, check before state update
- Provider-level `AsyncValue.guard()` for error handling
