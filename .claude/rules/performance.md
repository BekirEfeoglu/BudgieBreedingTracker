# Performance

## Drift (Local Database)
- Index frequently filtered columns (gender, species, breeding pair ID)
- Use `.watch()` streams for reactive UI — avoid polling with timers
- Batch inserts/updates in transactions for bulk operations
- Avoid `SELECT *` on large tables — select only needed columns
- Profile slow queries: `Stopwatch()..start()` + `AppLogger.debug('perf query: ${sw.elapsed}')` (AppLogger takes a SINGLE message — no tag arg, see observability.md)

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
- Push path IS batched: `pushAll` → `SyncableRepository.pushPendingBatched` — pending rows go in chunks of 100 (one `upsertAll` + one metadata cleanup per chunk, poison-row per-item fallback). See background-sync.md § Batch & Batched Push
- `save()` does a best-effort `tryImmediatePush` — there is NO client-side debounce; a failed push simply leaves the row pending for the next batched cycle
- Exponential backoff on transient failures (see error-handling.md)

## Startup Performance
- Lazy-initialize heavy services (genetics engine, sync service)
- Use `FutureProvider` for one-shot initialization
- Defer non-critical work (analytics, remote config) after first frame
- Splash critical path awaits ONLY profile pull + local notification channels + rate limiter; FCM registration, auth-metadata backfill and full data sync run as deferred microtasks after `InitStep.ready` (`appInitializationProvider`)
- Resume: in-app-update check (6h) and premium refresh (5m) are throttled via `ResumeThrottle` (`lib/core/utils/resume_throttle.dart`); presence/realtime/pushChanges stay unthrottled
- Debug startup route: `--dart-define=DEBUG_START_ROUTE=/birds` to skip splash

## Measurement
```dart
// Query timing
final sw = Stopwatch()..start();
final birds = await dao.getAllBirds();
AppLogger.debug('perf getAllBirds: ${sw.elapsed}');

// Frame timing (debug mode)
// Use Flutter DevTools Performance overlay
```

## Performance Budgets (Concrete Targets)
| Metric | Target | Tooling |
|--------|--------|---------|
| Frame time (UI thread) | < 16ms (60fps) | DevTools Performance overlay |
| Frame time p99 | < 33ms (no dropped frames) | Sentry performance trace |
| Drift query p50 | < 20ms | Stopwatch + AppLogger |
| Drift query p99 | < 50ms | Stopwatch + AppLogger |
| Cold start (splash→home) | < 2s | `main.dart` phase log |
| Warm start (resume→ready) | < 500ms | App lifecycle log |
| List scroll FPS (1000 items) | sustained 60fps | DevTools |
| Image decode (list item) | < 50ms | DevTools timeline |
| Sync (10 entities, online) | < 3s | Stopwatch around `SyncOrchestrator.forceFullSync()` |
| Photo upload (1MB) | < 5s | Stopwatch + bytes/sec |

Budget aşıldığında: profile et, optimize et, gerekirse feature scope kıs. Production'da bu metric'lerin regression alert'i Sentry performance veya manuel review ile takip.

### Measurement Pattern
```dart
final sw = Stopwatch()..start();
final result = await operation();
final ms = sw.elapsedMilliseconds;
AppLogger.debug('perf operationName: ${ms}ms');
if (ms > budgetMs) {
  AppLogger.warning('perf operationName exceeded budget: ${ms}ms > ${budgetMs}ms');
}
```

### Regression Detection
- Yeni PR'da heavy operation eklenirse: budget ile karşılaştır
- Code review'da "performans regresyonu" gerekçeli blocker
- Manual profile zorunlu: liste >100 item, image upload, sync flow değiştirildiyse

## Anti-Patterns
1. Polling with `Timer.periodic` when streams are available
2. Loading all data upfront instead of paginating/lazy-loading
3. Rebuilding entire screen when one widget's state changes
4. Keeping all providers alive indefinitely
5. Synchronous heavy computation on UI thread
6. Uncompressed image uploads
7. Deep provider dependency chains causing cascade rebuilds

> **Related**: data-layer.md (Drift queries), providers.md (ref.watch scope), architecture.md (offline-first)
