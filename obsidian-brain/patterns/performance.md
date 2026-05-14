# Performance

Source: `.claude/rules/performance.md`

## Performance Budgets

| Metric | Target |
|--------|--------|
| Frame time (UI thread) | < 16ms (60fps) |
| Frame time p99 | < 33ms (no dropped frames) |
| Drift query p50 | < 20ms |
| Drift query p99 | < 50ms |
| Cold start (splash→home) | < 2s |
| Warm start (resume→ready) | < 500ms |
| List scroll FPS (1000 items) | sustained 60fps |
| Image decode (list item) | < 50ms |
| Sync (10 entities, online) | < 3s |
| Photo upload (1MB) | < 5s |

## Measurement Pattern

```dart
final sw = Stopwatch()..start();
final result = await operation();
final ms = sw.elapsedMilliseconds;
AppLogger.debug('perf', 'operationName: ${ms}ms');
if (ms > budgetMs) {
  AppLogger.warning('perf', 'operationName exceeded budget: ${ms}ms > ${budgetMs}ms');
}
```

## Drift Queries

- Index frequently filtered columns (gender, species, breeding pair ID)
- Use `.watch()` streams — avoid polling with `Timer.periodic`
- Batch in transactions for bulk writes
- Select only needed columns (avoid `SELECT *` on large tables)

## Riverpod Rebuilds

```dart
// Narrow rebuild scope with .select()
final name = ref.watch(birdProvider.select((b) => b.value?.name));
```

- `ref.keepAlive()` for expensive computations
- Don't keepAlive everything — let ephemeral state dispose

## Widget Performance

- `const` constructors everywhere possible
- `ListView.builder` for long lists (lazy) — never `ListView` with all children
- `RepaintBoundary` around expensive custom painters (budgie painter)
- Break large widgets into smaller `ConsumerWidget` subtrees

## Image Handling

- `CachedNetworkImage` always (never `Image.network`)
- Resize before upload (max 1920px, JPEG q85)
- `memCacheWidth`/`memCacheHeight` in list items
- `flutter_image_compress` in isolate (not UI thread)

## Network & Sync

- Offline-first: never wait for network to show UI
- Debounce sync operations (500ms)
- Exponential backoff on failures

## Startup

- Lazy-initialize heavy services (genetics engine, sync service)
- Defer non-critical work after first frame (analytics, remote config)
- Debug: `--dart-define=DEBUG_START_ROUTE=/birds` to skip splash

## Anti-Patterns

1. `Timer.periodic` polling when streams available
2. Loading all data upfront (paginate/lazy load)
3. Rebuilding entire screen for one widget's state change
4. All providers kept alive indefinitely
5. Synchronous heavy computation on UI thread
6. Uncompressed image uploads
7. Deep provider chains causing cascade rebuilds

## See Also

- [[data-layer/drift]] — query patterns
- [[patterns/providers]] — ref.watch scope
- [[patterns/assets-images]] — image handling
