# Performance

## Drift (Local Database)
- Index frequently filtered columns (gender, species, breeding pair ID)
- Use `.watch()` streams for reactive UI — avoid polling with timers
- Batch inserts/updates in transactions for bulk operations
- Avoid `SELECT *` on large tables — select only needed columns
- Profile slow queries: `Stopwatch()..start()` + `AppLogger.debug('perf', 'query: ${sw.elapsed}')`

## Riverpod Providers
- `ref.watch()` scope: watch specific fields, not entire models
- Use `.select()` to narrow rebuild triggers:
  ```dart
  // Rebuilds only when name changes, not entire bird object
  final name = ref.watch(birdProvider.select((b) => b.value?.name));
  ```
- `ref.keepAlive()` for expensive computations that shouldn't re-run
- Don't chain too many providers — deep chains increase rebuild latency
- Dispose unused providers (don't keepAlive everything)

## Widget Performance
- Use `const` constructors wherever possible
- `ListView.builder` for long lists (lazy rendering) — never `ListView` with all children
- `RepaintBoundary` around expensive custom painters (budgie painter)
- Avoid `setState` on parent widgets when only child state changes
- Break large widgets into smaller `ConsumerWidget` subtrees for targeted rebuilds

## Image Handling
- Use `CachedNetworkImage` for remote photos
- Resize images before upload (max dimension, quality compression)
- Lazy load images in lists — don't prefetch all
- SVG icons via `flutter_svg` (vector, no resolution variants needed)
- Local AI image analysis: 10MB file size guard (see genetics feature)

## Network & Sync
- Offline-first: UI reads from local Drift DB, never waits for network
- Background sync: push changes when connectivity available
- Batch sync operations to minimize network requests
- Exponential backoff on transient failures (see error-handling.md)
- Don't sync on every change — debounce or batch

## Startup Performance
- Lazy-initialize heavy services (genetics engine, sync service)
- Use `FutureProvider` for one-shot initialization
- Defer non-critical work (analytics, remote config) after first frame
- Debug startup route: `--dart-define=DEBUG_START_ROUTE=/birds` to skip splash

## Measurement
```dart
// Query timing
final sw = Stopwatch()..start();
final birds = await dao.getAllBirds();
AppLogger.debug('perf', 'getAllBirds: ${sw.elapsed}');

// Frame timing (debug mode)
// Use Flutter DevTools Performance overlay
```

## Anti-Patterns
1. Polling with `Timer.periodic` when streams are available
2. Loading all data upfront instead of paginating/lazy-loading
3. Rebuilding entire screen when one widget's state changes
4. Keeping all providers alive indefinitely
5. Synchronous heavy computation on UI thread
6. Uncompressed image uploads
7. Deep provider dependency chains causing cascade rebuilds

> **Related**: data-layer.md (Drift queries), providers.md (ref.watch scope), architecture.md (offline-first)
