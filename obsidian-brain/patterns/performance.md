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
AppLogger.debug('perf operationName: ${ms}ms');
if (ms > budgetMs) {
  AppLogger.warning('perf operationName exceeded budget: ${ms}ms > ${budgetMs}ms');
}
// AppLogger takes a SINGLE message (no tag arg) — see [[patterns/observability]]
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
- Resize/quality at `ImagePicker`; limits are surface-specific (bird/DM 1920×
  1920 q85, community 1200×1200 q85, marketplace width 1200 q80, avatar
  512×512 q80, local AI 1024×1024 q85)
- `memCacheWidth`/`memCacheHeight` in list items
- Apply `ImagePickerGuard` before upload; storage repeats size/extension/magic
  byte validation and image safety scanning

## Network & Sync

- Offline-first: never wait for network to show UI
- Push is batched: `pushPendingBatched` chunks of 100 → one `upsertAll` per chunk (see [[data-layer/sync-strategy]] § Batched Push); `save()` does a best-effort immediate push, NO client-side debounce
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
6. Image upload without surface-specific picker sizing/quality
7. Deep provider chains causing cascade rebuilds

## See Also

- [[data-layer/drift]] — query patterns
- [[patterns/providers]] — ref.watch scope
- [[patterns/assets-images]] — image handling
