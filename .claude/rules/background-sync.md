# Background Sync

Offline-first mimari: kullanıcı her zaman local Drift DB'ye yazar, sync service arka planda Supabase ile uzlaştırır. Network kaybı veri kaybı DEĞİL.

## Akış
```
Local write (Drift) -> SyncMetadata dirty flag
  -> ConnectivityService online algılar
  -> SyncService entity tipini sıraya alır
  -> Repository.syncToRemote() -> upsert (idempotent)
  -> SyncMetadata clean flag + lastSyncedAt
  -> Conflict varsa lastPullConflicts'a yaz, UI banner göster
```

## Sync Triggers
| Trigger | Hedef |
|---------|-------|
| App start (online) | Full pull + push pending |
| Connectivity online geldi | Push pending + light pull |
| App resume (foreground) | Last-modified pull |
| Manual refresh (pull-to-refresh) | Entity-spesifik pull |
| Realtime event (Supabase) | Tek entity pull |
| Periodic (15dk timer) | Light pull, sadece online + foreground |

## SyncMetadata Tablosu
Per-entity row:
```dart
class SyncMetadata {
  String entityType;        // 'birds', 'eggs', ...
  DateTime? lastSyncedAt;   // Last successful sync
  DateTime? lastPulledAt;   // Last server pull (for delta sync)
  int dirtyCount;           // # of local unsynced changes
  String? lastError;        // Last sync error code
  int retryCount;           // Current backoff attempt
}
```

## Retry & Backoff
- Transient hata (network): `RetryScheduler` exponential backoff kullanır
  (`45s * 2^retryCount` + %20 jitter, max 10dk)
- Permanent hata (auth, validation): retry yok, error log + Sentry
- Max attempt 7 — sonrasında error state kalır, kullanıcıya global
  `OfflineBanner` içinde retry CTA gösterilir

```dart
final canRetry = RetryScheduler.shouldRetry(metadata.retryCount ?? 0);
final nextDelay = RetryScheduler.getNextRetryDelay(metadata.retryCount ?? 0);
```

Stale cleanup 24 saatlik davranışını korur. UI pre-warning 20 saat üstü
ve `retryCount >= RetryScheduler.maxRetries` kayıtlar için
`pendingDeletionSyncErrorsProvider` üzerinden gösterilir.

## Idempotency
- Tüm remote write `.upsert()` (NEVER `.insert()`)
- Primary key client-generated `Uuid().v4()` — server-assigned değil
- Retry replay duplicate oluşturmaz
- Detay: data-layer.md § Write Safety

## ValidatedSyncMixin
FK parent'lı entity'ler (egg → breeding_pair, chick → egg) push öncesi parent var mı kontrol eder. Parent silinmişse orphan push engellenir, local row da silinir.

**Zorunlu kullanım:**
- `egg_repository.dart`
- `chick_repository.dart`
- `health_record_repository.dart`
- `breeding_pair_repository.dart`
- `event_reminder_repository.dart`

Bird repository root entity, mixin'e gerek yok.

```dart
class EggRepository extends BaseRepository<Egg>
    with ValidatedSyncMixin<Egg> {
  @override
  Future<bool> validateParents(Egg entity) async {
    final pair = await breedingPairDao.findById(entity.breedingPairId);
    return pair != null;
  }
}
```

## Conflict Resolution
- Last-write-wins via `updated_at` timestamp (server klock)
- Conflict tespiti: local `dirty=true` + remote `updated_at > localPullTimestamp`
- Server kazanır, local edit `lastPullConflicts` listesine eklenir
- Provider `conflictNotifierProvider` UI banner gösterir, kullanıcı edit'i geri yükleyebilir
- Sessiz overwrite YOK — her conflict kullanıcıya bildirilir

```dart
if (remote.updatedAt.isAfter(local.lastPullAt) && local.dirty) {
  await _conflictStore.addConflict(local, remote);
  await dao.upsertFromRemote(remote);
  ref.read(conflictNotifierProvider.notifier).notify(entityType);
}
```

## Connectivity-Aware
- `ConnectivityService` `connectivity_plus` üzerine wrap
- Online geldiğinde otomatik sync kick
- Offline modda global `OfflineBanner` gösterilir; banner
  `syncStatusProvider`, `pendingSyncCountProvider`,
  `pendingDeletionSyncErrorsProvider` ve retry için
  `syncOrchestratorProvider.forceFullSync()` kullanır
- Sync sadece foreground + online — background sync iOS'ta sınırlı

```dart
child: AppUpdatePrompt(
  child: OfflineBanner(child: routedChild),
)
```

## Batch & Debounce
- Aynı saniyede 5 bird ekleme: tek batch upsert (Supabase batch endpoint)
- Debounce: dirty entity 500ms bekle, sonra push (rapid edit'leri grupla)
- Drift `batch()` ile toplu local write — tek transaction

## Sync UI Indicators
| Durum | Gösterim |
|-------|----------|
| Idle | Görünür değil |
| Syncing | Header'da spinner + "Senkronize ediliyor" |
| Conflict | Banner + "Çakışmaları gör" CTA |
| Failed (after retries) | Error banner + retry button |
| Offline | "Çevrimdışı — değişiklikleriniz kaydedildi" |
| Stale pre-warning | 20h+ failed records için cleanup öncesi retry banner |

## Background Sync (iOS / Android)
- iOS: `BGTaskScheduler` short tasks (30 saniye) — sınırlı, opportunistic
- Android: WorkManager periodic (15dk min interval)
- Foreground sync güvenilir, background sadece "best effort"
- Kritik veri için kullanıcı app'i açtığında sync güvence

## Testing
```dart
test('retries network failure with backoff', () async {
  var attempts = 0;
  when(() => mockRemote.upsert(any())).thenAnswer((_) async {
    attempts++;
    if (attempts < 3) throw NetworkException('flaky');
    return;
  });

  await syncService.syncEntity('birds');
  expect(attempts, 3);
});

test('marks conflict when remote newer than local edit', () async {
  // ... fixture: local dirty bird with updatedAt = T1
  //              remote bird with updatedAt = T2 > T1
  await syncService.pull('birds');
  final conflicts = container.read(conflictNotifierProvider);
  expect(conflicts, contains('birds'));
});
```

## Anti-Patterns
1. `.insert()` kullanmak (anti-pattern: idempotency kaybı)
2. ValidatedSyncMixin olmadan FK parent'lı entity push (orphan)
3. Sessiz conflict overwrite (kullanıcı veri kaybını fark etmez)
4. Retry'da auth hatasını sonsuza dek denemek (5xx vs 4xx ayırt et)
5. Background sync'e kritik veri güvenmek (iOS engelleyebilir)
6. Sync state'i UI'a göstermemek (kullanıcı belirsizlikte)
7. Periodic sync timer'ı offline'da çalıştırmak (battery drain)
8. Local timestamp ile sunucu timestamp karşılaştırması (clock skew — server `updated_at` zorunlu)

> **İlgili**: data-layer.md (Drift + Supabase), error-handling.md (NetworkException, retry), observability.md (sync logging), performance.md (batch)
